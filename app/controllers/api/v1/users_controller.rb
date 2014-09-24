class Api::V1::UsersController < Api::V1::ApiController
  include ApplicationHelper
  skip_before_action :authenticate_user, only: :create

  def create
    code_request = CodeRequest.find_by(phone_number: params[:phone_number])

    if code_request.nil?
      render json: { errors: { unauthorized: "No code has been sent for this phone number" } }, :status => 401 and return 
    end

    if code_request.code.to_i != params[:code].to_i
      render json: { errors: { unauthorized: "Wrong SMS code" } }, :status => 401 and return 
    end

    user = User.new

    user.phone_number = params[:phone_number]
    user.first_name = params[:first_name]
    user.last_name = params[:last_name]

    if params[:profile_picture]
      user.profile_picture = StringIO.new(Base64.decode64(params[:profile_picture]))
    end

    if user.save
      #delete code
      code_request.destroy
      #delete prospects
      prospect = Prospect.find_by(phone_number: params[:phone_number])
      if prospect
        prospect.destroy
      end

      #convert received messages
      future_messages = FutureMessage.where(receiver_number: params[:phone_number])

      future_messages.each do |future_message|

        begin
          message = Message.new
          message.receiver_id = user.id
          message.sender_id = future_message.sender_id
          message.opened = false
          message.future = true
          message.record = future_message.future_record.recording
          message.record_content_type = "audio/m4a"
          message.save 

          future_message.destroy
        rescue Exception => e
          Airbrake.notify(e)
        end
        
      end

      render json: { result: { auth_token: user.auth_token, user_id: user.id, user: user.contact_info } }, status: 201
    else 
      render json: { errors: { internal: user.errors } }, :status => 500
    end
  end

  def update_push_token
    current_user.update_attributes(:push_token => params[:push_token])
    render json: { result: { user: current_user.contact_info } }, status: 201
  end

  def update_profile_picture
    current_user.update_attributes(:profile_picture => StringIO.new(Base64.decode64(params[:profile_picture])))
    render json: { result: { user: current_user.contact_info } }, status: 201
  end

  def update_first_name
    current_user.update_attributes(:first_name => params[:first_name])
    render json: { result: { user: current_user.contact_info } }, status: 201
  end

  def update_last_name
    current_user.update_attributes(:last_name => params[:last_name])
    render json: { result: { user: current_user.contact_info } }, status: 201
  end

  def update_micro_auth
    current_user.update_attributes(:micro_auth => params[:micro_auth])
    render json: { result: { user: current_user.contact_info } }, status: 201
  end

  # for backward compatibility (<= 1.1.4)
  # now get_contacts_and_relatives
  def get_my_contact
    if params[:api_version] && params[:app_version] 
      current_user.update_attributes(:app_version => params[:app_version], :api_version => params[:api_version], :contact_auth => true)
    end
    if params[:os_version]
      current_user.update_attributes(:os_version => params[:os_version])
    end

    # Get contacts (except blocked)
    users = User.where(phone_number: params[:contact_numbers])
                  .reject { |user| user.blocked_by_user(current_user.id) }
    #include Waved contact
    users << User.find(1)

    # Map prospect users
    if (params[:sign_up] and params[:sign_up] == "1") or (current_user.id < 1617 and MappedContact.where(user_id: current_user.id).length == 0)
      if current_user.id < 1598
        mapped_contact = MappedContact.new
        mapped_contact.user_id = current_user.id
        mapped_contact.save
      end

      begin
        MapContactsWorker.perform_async(params[:contact_numbers], current_user.id)
      rescue Exception => e
        Airbrake.notify(e)
      end
    end

    # If sign up, then update other users :retrieve_contacts
    if params[:sign_up] and params[:sign_up]=="1" 
      users.each { |user| 
        user.update_attributes(:retrieve_contacts => true)

        #send notif
        if (user.push_token)
          text = current_user.first_name + " " + current_user.last_name + " is now on Waved!"
          APNS.pem = 'app/assets/WavedProdCert&Key.pem'
          APNS.pass = ENV['CERT_PASS']
          APNS.send_notification(user.push_token , :alert => text, :sound => 'received_sound.aif')
        end
      }
    end

    render json: { result: { contacts: User.contact_info(users) } }, status: 201
  end

  def get_user_info
    user = User.find(params[:user_id])
    render json: { result: { contact: user.contact_info } }, status: 201
  end

  def user_presence
    user = User.where(phone_number: params[:phone_number])

    if user.any?
      render json: { result: { presence: true } }, status: 201
    else 
      render json: { result: { presence: false } }, status: 201
    end
  end

  # Contacts that exchanged waved with current user
  def get_user_active_contacts
    user = User.find(params[:user_id])
    active_contacts_id = user.messages_received.pluck(:sender_id)
    active_contacts_id += user.messages_sent.pluck(:receiver_id)
    active_contacts = User.where(id:active_contacts_id)
    render json: { result: { active_contacts: User.contact_info(active_contacts) } }, status: 201
  end

  def update_app_info
    current_user.app_version = params[:app_version]
    current_user.api_version = params[:api_version]
    current_user.os_version = params[:os_version]
    current_user.save
    render json: { result: { user: current_user.contact_info } }, status: 201
  end

  def get_contacts_and_futures
    contact_numbers = []
    params["contact_infos"].each { |phone_number,info|
      contact_numbers += [phone_number]
    }

    # Get contacts
    users = User.where(phone_number: contact_numbers).reject { |user| user.blocked_by_user(current_user.id) }
    current_user.update_attributes(:nb_contacts_users => users.count)

    # Remove users from contacts
    contact_numbers -= users.map(&:phone_number)
    params["contact_infos"].except!(*users.map(&:phone_number))
    
    future_contacts = []
    if params[:sign_up] and params[:sign_up]=="1"
      # Tell his contacts to :retrieve_contacts and send them notif
      users.each { |user| 
        user.update_attributes(:retrieve_contacts => true)
        if (user.push_token && current_user.unread_messages.where(:sender_id => user.id).blank?)
          text = current_user.first_name + " " + current_user.last_name + " is now on Waved!"
          APNS.pem = 'app/assets/WavedProdCert&Key.pem'
          APNS.pass = ENV['CERT_PASS']
          APNS.send_notification(user.push_token , :alert => text, :sound => 'received_sound.aif')
        end
      }

      # Map prospect users
      begin
        MapContactsWorker.perform_async(contact_numbers,params["contact_infos"],current_user.id)
      rescue
        Airbrake.notify(e)
      end

      # Future contacts
      picture_contacts = []
      favorite_contacts = []
      params["contact_infos"].each { |phone_number,info|
        if info[1] == "1"
          if info[2] == "1"
            favorite_contacts += [{facebook_id: info[0],phone_number: phone_number}]
          else
            picture_contacts +=[{facebook_id: info[0],phone_number: phone_number}]
          end
        # for favorites without photo, check in prospects if we have one
        elsif info[2] == "1"
          prospect = Prospect.where(phone_number: phone_number)
          if prospect and prospect.facebook_id
            favorite_contacts += [{facebook_id: prospect.facebook_id,phone_number: phone_number}]
          end
        end
      }
      if favorite_contacts.count >= NUMBER_FUTURES_CONTACT
        future_contacts = favorite_contacts.shuffle[0..NUMBER_FUTURES_CONTACT-1]
      else
        future_contacts = favorite_contacts
        if picture_contacts.count + favorite_contacts.count >= NUMBER_FUTURES_CONTACT
          int = NUMBER_FUTURES_CONTACT - favorite_contacts.count - 1
          future_contacts += picture_contacts.shuffle[0..int]
        else
          future_contacts += picture_contacts
        end
      end
      current_user.update_attributes(:nb_contacts => , :futures => future_contacts.count, :favorites => favorite_contacts.count)
    end

    render json: { result: { contacts: User.contact_info(users) , future_contacts: future_contacts} }, status: 201
  end

  def update_address_book_stats
    current_user.nb_contacts = params[:nb_contacts]
    current_user.nb_contacts_photos = params[:nb_contacts_photos]
    current_user.nb_contacts_favorites = params[:nb_contacts_favorites]
    current_user.nb_contacts_facebook = params[:nb_contacts_facebook]
    current_user.nb_contacts_photo_only = params[:nb_contacts_photo_only]
    current_user.nb_contacts_family = params[:nb_contacts_family]
    current_user.nb_contacts_related = params[:nb_contacts_related]
    current_user.nb_contacts_linked = params[:nb_contacts_linked]
    current_user.save
    render json: { result: { user: current_user.contact_info } }, status: 201
  end
end