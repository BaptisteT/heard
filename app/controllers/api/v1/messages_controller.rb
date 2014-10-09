class Api::V1::MessagesController < Api::V1::ApiController
  include ApplicationHelper
  def create
    Rails.logger.debug "TRUCHOV create message"

    message = Message.new(message_params)
    message.sender_id = current_user.id
    message.opened = false

    if message.save
      begin
      receiver = User.find(params[:receiver_id])
      if (receiver.push_token and not current_user.blocked_by_user(params[:receiver_id]))
        #notif params
        text = 'New message from ' + current_user.first_name
        badge_number = receiver.unread_messages.count

        if is_below_threshold(receiver.app_version,FIRST_PRODUCTION_VERSION)
          pusher = Grocer.pusher(certificate: 'app/assets/cert.pem', passphrase:  "djibril")
        else
          pusher = Grocer.pusher(certificate: 'app/assets/WavedProdCert&Key.pem', passphrase: ENV['CERT_PASS'], gateway: "gateway.push.apple.com")
        end

        if is_below_threshold(receiver.app_version,"1.1.4")
          response_message = message.response_message
        else
          response_message = ""
        end

        if receiver.unread_messages.where(:sender_id => current_user.id).count == 1
          notification = Grocer::Notification.new(
            device_token:      receiver.push_token,
            alert:             text,
            badge:             badge_number,   
            sound:             'received_sound.aif',
            custom: { message: response_message})
        else
          notification = Grocer::Notification.new(
            device_token:      receiver.push_token,
            alert:             text,
            badge:             badge_number,       
            custom: { message: response_message})
        end
        pusher.push(notification)
      end

      rescue Exception => e
        Airbrake.notify(e)
      end

      render json: { result: { message: ["Message successfully saved"] } }, status: 201
    else 
      render json: { errors: { internal: message.errors } }, :status => 500
    end
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

      MessageToAllWorker.perform_async(message.id)

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
            message = "Hey " + params[:receiver_first_name] + ", " + current_user.first_name + " " +current_user.last_name + " just left you a message on Telepath. Go to www.telepath.me to hear it!"
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

    # if this is last message unread from this user, send silent notif
    receiver = User.find(message.receiver_id)
    sender = User.find(message.sender_id)
    if (sender.push_token && ! is_below_threshold(sender.app_version,"1.1.1.9") && receiver.unread_messages.where(sender_id: sender.id).count == 0)
      logger.debug "SHOULD SEND A NOTIF"
      if is_below_threshold(sender.app_version,FIRST_PRODUCTION_VERSION)
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
    unread_users = Message.where(sender_id:current_user.id, opened:false).pluck(:receiver_id).uniq

    render json: { result: { messages: Message.response_messages(current_user.unread_messages), 
                                retrieve_contacts:retrieve,
                                unread_users:unread_users} }, status: 201
  end

  def last_message
    last_message = Message.where(sender_id: params[:sender_id], receiver_id: current_user.id).order('id DESC').limit(1)

    render json: { result: { message: Message.response_message(last_message)} }, status: 201
  end

  def retrieve_conversation
    messages = Message.where("(sender_id = ? and receiver_id = ?) or (sender_id = ? and receiver_id = ?)",
      params[:first_user_id],params[:second_user_id],params[:second_user_id],params[:first_user_id])
    render json: { result: { messages: Message.response_messages(messages)} }, status: 201
  end

  def is_recording
    receiver = User.find(params[:receiver_id])
    if receiver.push_token
      pusher = Grocer.pusher(certificate: 'app/assets/WavedProdCert&Key.pem', passphrase: ENV['CERT_PASS'], gateway: "gateway.push.apple.com")
      notification = Grocer::Notification.new(
        device_token:     receiver.push_token,
        custom:           {:recorder_id => current_user.id, :is_recording => params[:is_recording]})
      pusher.push(notification)
    end
    render json:{ result: { message: ["Message successfully saved"]} }, status: 201
  end

  private

    def message_params
      params.permit(:receiver_id, :record)
    end 
end