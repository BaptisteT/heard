class Api::V1::MessagesController < Api::V1::ApiController
  include ApplicationHelper
  def create
    Rails.logger.debug "TRUCHOV create message"
    if params[:is_group] and params[:is_group]=="1"
      receiver_ids = Group.find(params[:receiver_id]).member_ids - [current_user.id]
    else
      receiver_ids = [params[:receiver_id]]
    end
    receiver_ids.each {|receiver_id|
      message = Message.new(message_params)
      message.sender_id = current_user.id
      message.opened = false
      message.receiver_id = receiver_id
      group_text = ''
      if params[:is_group] and params[:is_group]=="1"
        message.group_id = params[:receiver_id]
        group_text = ' in ' + Group.find(message.group_id).name
      end
      if message.save
        begin
        receiver = User.find(receiver_id)
        if (receiver.push_token and not current_user.blocked_by_user(receiver_id))
          #notif params
          message_type = message.record_file_name == 'Picture' ? 'photo ' : 'message '
          text = 'New ' + message_type +'from ' + current_user.first_name + group_text
          badge_number = receiver.unread_messages.count

          response_message = ""
          if receiver.is_beta_tester
            pusher = Grocer.pusher(certificate: 'app/assets/cert.pem', passphrase:  "djibril", gateway: "gateway.push.apple.com")
          else
            pusher = Grocer.pusher(certificate: 'app/assets/WavedProdCert&Key.pem', passphrase: ENV['CERT_PASS'], gateway: "gateway.push.apple.com")
            if is_below_threshold(receiver.app_version,"1.1.4")
              response_message = message.response_message
            end
          end

          if (params[:is_group] and params[:is_group]=="1" and receiver.unread_messages.where(:group_id => params[:receiver_id]).count <= 3) or 
            receiver.unread_messages.where(:sender_id => current_user.id).count <= 3
            notification = Grocer::Notification.new(
              device_token:      receiver.push_token,
              alert:             text,
              badge:             badge_number,   
              sound:             'received_sound.aif',
              expiry:            Time.now + 60*600,
              custom: { message: response_message})
          else
            notification = Grocer::Notification.new(
              device_token:      receiver.push_token,
              alert:             text,
              badge:             badge_number,
              expiry:            Time.now + 60*600,  
              custom: { message: response_message})
          end

          pusher.push(notification)
        end

        rescue Exception => e
          Airbrake.notify(e)
        end
      else 
        render json: { errors: { internal: message.errors } }, :status => 500
      end
    }
    render json: { result: { message: ["Message successfully saved"] } }, status: 201
  end

  def create_for_all
    if current_user.id != 1
      render json: { errors: { unauthorized: "Not authorized" } }, :status => 401
    end

    message = Message.new
    message.record = params[:record]
    message.receiver_id = 1
    message.sender_id = 1
    message.opened = false

    if message.save

      # MessageToAllWorker.perform_async(message.id)

      render json: { result: { message: ["Message successfully saved"] } }, status: 201
    else
      render json: { errors: { internal: message.errors } }, :status => 500
    end
  end

  def create_future_messages
    future_record = FutureRecord.new
    future_record.recording = params[:record]

    if future_record.save
      params[:future_contact_phones].each do |future_contact_phone|
        future_message = FutureMessage.new
        future_message.sender_id = current_user.id
        future_message.receiver_number = future_contact_phone
        future_message.future_record_id = future_record.id 
        future_message.save!

        if params[:receiver_first_name]
          # alert receiver
          sum = FutureMessage.where(sender_id:current_user.id, receiver_number:future_contact_phone).count
          if sum == 1
            if future_message.receiver_number[0,3]="+33"
              message = params[:receiver_first_name] + ", vous venez de recevoir un message vocal de " + current_user.first_name + " " + current_user.last_name + " sur Waved ! Téléchargez l'appli depuis www.waved.io pour l'écouter."
            else
              message = "Hey " + params[:receiver_first_name] + ", your friend " + current_user.first_name + " " + current_user.last_name + " just left you a voice message on Waved! Download the app at www.waved.io to hear it."
            end
          elsif sum == 2
            if future_message.receiver_number[0,3]="+33"
              message = current_user.first_name + " " + current_user.last_name + " vous a envoyé plusieurs messages sur Waved ! Téléchargez l'appli depuis www.waved.io pour les écouter."
            else
              message = params[:receiver_first_name] + ", your friend " + current_user.first_name + " " + current_user.last_name + " sent you multiple messages on Waved! Download the app at www.waved.io to listen to them."
            end
          end

          if message
            begin
              client = Twilio::REST::Client.new(TWILIO_SID, TWILIO_TOKEN)
              client.account.messages.create(
                from: TWILIO_PHONE_NUMBER,
                to:   future_contact_phone,
                body: message
              )
            rescue Twilio::REST::RequestError => e
              Airbrake.notify(e)
              render json: { errors: { twilio: e.message } }, :status => 500 and return
            end
            future_message.update_attributes(:text_sent => true)
          end
        end
      end 

      render json: { result: { message: ["Messages successfully saved"] } }, status: 201
    else
      render json: { errors: { internal: future_record.errors } }, :status => 500 
    end
  end

  def admin_messages
    if current_user.id != 1
      render json: { errors: { unauthorized: "Not authorized" } }, :status => 401
    end

    per_page = params[:page_size] ? params[:page_size] : 20
    page = params[:page] ? params[:page] : 1

    messages = Message.where("receiver_id = 1").order('created_at DESC').paginate(page: page, per_page: per_page)

    render json: { result: { messages: messages } }, status: 200
  end

  def mark_as_opened
    message = Message.find(params[:message_id])
    message.update_attributes(:opened => true)

    if !message.group_id or message.group_id == 0
      # if this is last message unread from this user, send silent notif
      receiver = User.find(message.receiver_id)
      sender = User.find(message.sender_id)
      if (sender.push_token && receiver.unread_messages.where(sender_id: sender.id).count == 0)
        if sender.is_beta_tester
          pusher = Grocer.pusher(certificate: 'app/assets/cert.pem', passphrase:  "djibril")
        else
          pusher = Grocer.pusher(certificate: 'app/assets/WavedProdCert&Key.pem', passphrase: ENV['CERT_PASS'], gateway: "gateway.push.apple.com")
        end
        notification = Grocer::Notification.new(
              device_token:      sender.push_token,
              custom: {:message_id => message.id, :receiver_id => receiver.id})
        pusher.push(notification)
      else
        logger.debug "DID NOT SEND A NOTIF" 
      end
    end

    render json: { result: { message: ["Message successfully updated"] } }, status: 201
  end

  def unread_messages
    if current_user.retrieve_contacts
      retrieve = true
      current_user.update_attributes(:retrieve_contacts => false)
    else
      retrieve = false
    end

    # Get contacts who did not read his messages
    unread_users = Message.where(sender_id:current_user.id, opened:false, group_id:nil).pluck(:receiver_id).uniq

    render json: { result: { messages: Message.response_messages(current_user.unread_messages), 
                                retrieve_contacts:retrieve,
                                unread_users:unread_users} }, status: 201
  end

  def last_message
    last_message = Message.where(sender_id: params[:sender_id], receiver_id: current_user.id).order('id DESC').limit(1)
    render json: { result: { message: Message.response_message(last_message)} }, status: 201
  end

  def retrieve_conversation
    messages = Message.where("((sender_id = ? and receiver_id = ?) or (sender_id = ? and receiver_id = ?)) and group_id IS NULL",
      params[:first_user_id],params[:second_user_id],params[:second_user_id],params[:first_user_id])
    render json: { result: { messages: Message.response_messages(messages)} }, status: 201
  end

  def is_recording
    receiver = User.find(params[:receiver_id])
    if receiver.push_token
      if receiver.is_beta_tester
        pusher = Grocer.pusher(certificate: 'app/assets/cert.pem', passphrase:  "djibril")
      else
        pusher = Grocer.pusher(certificate: 'app/assets/WavedProdCert&Key.pem', passphrase: ENV['CERT_PASS'], gateway: "gateway.push.apple.com")
      end

      notification = Grocer::Notification.new(
        device_token:     receiver.push_token,
        custom:           {:recorder_id => current_user.id, :is_recording => params[:is_recording]})
      pusher.push(notification)
    end
    render json:{ result: { message: ["Message successfully saved"]} }, status: 201
  end

  private

    def message_params
      params.permit(:record, :creation_date, :text)
    end 
end