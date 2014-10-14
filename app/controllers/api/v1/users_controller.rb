class Api::V1::UsersController < Api::V1::ApiController
  include ApplicationHelper
  skip_before_action :authenticate_user, only: [:create, :fb_create]

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
      after_create_user(user, code_request)

      render json: { result: { auth_token: user.auth_token, user_id: user.id, user: user.contact_info } }, status: 201
    else 
      render json: { errors: { internal: user.errors } }, :status => 500
    end
  end

  def fb_create
    code_request = CodeRequest.find_by(phone_number: params[:phone_number])

    if code_request.nil?
      render json: { errors: { unauthorized: "No code has been sent for this phone number" } }, :status => 401 and return 
    end

    if code_request.code.to_i != params[:code].to_i
      render json: { errors: { unauthorized: "Wrong SMS code" } }, :status => 401 and return 
    end

    user = User.new

    user.phone_number = params[:phone_number]
    user.first_name = params[:fb_first_name]
    user.last_name = params[:fb_last_name]
    user.fb_first_name = params[:fb_first_name]
    user.fb_last_name =  params[:fb_last_name]
    user.fb_id = params[:fb_id]
    user.fb_gender = params[:fb_gender] 
    user.fb_locale = params[:fb_locale]

    user.profile_picture = open(URI.parse(process_uri("http://graph.facebook.com/#{user.fb_id}/picture?type=large")))

    if user.save
      after_create_user(user, code_request)

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

    # If sign up, then update other users :retrieve_contacts
    if params[:sign_up] and params[:sign_up]=="1" 
      users.each { |user| 
        user.update_attributes(:retrieve_contacts => true)

        #send notif
        if (user.push_token)
          if user.is_beta_tester
            pusher = Grocer.pusher(certificate: 'app/assets/cert.pem', passphrase:  "djibril")
          else
            pusher = Grocer.pusher(certificate: 'app/assets/WavedProdCert&Key.pem', passphrase: ENV['CERT_PASS'], gateway: "gateway.push.apple.com")
          end
          text = current_user.first_name + " " + current_user.last_name + " is now on Waved!"
          notification = Grocer::Notification.new(
            device_token:      user.push_token,
            alert:             text,
            expiry:            Time.now + 60*600,
            sound:             'received_sound.aif')  
          pusher.push(notification)
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
    current_user.push_auth = params[:push_auth]
    current_user.micro_auth = params[:micro_auth]
    current_user.save!
    render json: { result: { user: current_user.contact_info } }, status: 201
  end

  def get_contacts_and_futures
    contact_numbers = []
    params["contact_infos"].each { |phone_number,info|
      contact_numbers += [phone_number]
    }

    # Get contacts
    users = User.where(phone_number: contact_numbers).reject { |user| user.blocked_by_user(current_user.id) }
    current_user.update_attributes(:contact_auth => true, :nb_contacts_users => users.count)

    # Remove users from contacts
    contact_numbers -= users.map(&:phone_number)
    params["contact_infos"].except!(*users.map(&:phone_number))
    
    future_contacts = []
    if params[:sign_up] and params[:sign_up]=="1" or (current_user.id <= 1100 and current_user.id > 0 and MappedContact.where(user_id: current_user.id).length == 0)

      mapped_contact = MappedContact.new
      mapped_contact.user_id = current_user.id
      mapped_contact.save!
      
      # Tell his contacts to :retrieve_contacts and send them notif
      users.each { |user| 
        user.update_attributes(:retrieve_contacts => true)
        if (user.push_token && current_user.unread_messages.where(:sender_id => user.id).blank?)
          if user.is_beta_tester
            pusher = Grocer.pusher(certificate: 'app/assets/cert.pem', passphrase:  "djibril")
          else
            pusher = Grocer.pusher(certificate: 'app/assets/WavedProdCert&Key.pem', passphrase: ENV['CERT_PASS'], gateway: "gateway.push.apple.com")
          end
          
          text = current_user.first_name + " " + current_user.last_name + " is now on Waved!"
          notification = Grocer::Notification.new(
            device_token:      user.push_token,
            alert:             text,
            expiry:            Time.now + 60*600,
            sound:             'received_sound.aif')  
          pusher.push(notification)
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
          prospect = Prospect.where(phone_number: phone_number).first
          if prospect and !prospect.facebook_id.blank?
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
      current_user.update_attributes(:futures => future_contacts.count, :favorites => favorite_contacts.count)
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

  private

    def after_create_user(user, code_request)
      #delete code
      code_request.destroy
      #delete prospects
      prospect = Prospect.find_by(phone_number: user.phone_number)
      if prospect
        prospect.destroy
      end

      #convert received messages
      future_messages = FutureMessage.where(receiver_number: user.phone_number)
      text_received_nb = 0
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

          text_received_nb += future_message.text_sent ? 1 : 0
          future_message.converted = true
          future_message.save
        rescue Exception => e
          Airbrake.notify(e)
        end
      end

      user.initial_messages_nb = future_messages.count
      user.text_received_nb = text_received_nb
      user.save
    end
end