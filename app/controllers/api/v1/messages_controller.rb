class Api::V1::MessagesController < Api::V1::ApiController

  def create
    Rails.logger.debug "TRUCHOV create message"

    message = Message.new(message_params)
    message.sender_id = current_user.id
    message.opened = false

    if message.save
      receiver = User.find(params[:receiver_id])
      if (receiver.push_token and not current_user.blocked_by_user(params[:receiver_id]))
        #notif params
        sender  = current_user
        text = 'New message from ' + sender.first_name
        badge_number = receiver.unread_messages.count

        #notif config
        APNS.pem = 'app/assets/cert.pem'
        APNS.port = 2195
        APNS.pass = "djibril"
        APNS.host = 'gateway.push.apple.com' 

        if receiver.unread_messages.where(:sender_id => current_user.id).count == 1
          APNS.send_notification(receiver.push_token , :alert => text, :badge => badge_number, :sound => 'default',
                                                       :other => {:message => message.response_message})
        else
          #no sound
          APNS.send_notification(receiver.push_token , :alert => text, :badge => badge_number,
                                                       :other => {:message => message.response_message})
        end
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

    #todo BT
    # if last message unread from this user (can be a param of the request), send silent notif
    # Send this notif only to new versions

    # receiver = User.find(message.sender_id)
    # if (receiver.push_token)
    #   #notif config
    #   APNS.pem = 'app/assets/cert.pem'
    #   APNS.port = 2195
    #   APNS.pass = "djibril"
    #   APNS.host = 'gateway.push.apple.com' 
    #   APNS.send_notification(receiver.push_token , :other => {:message => message.response_message})
    # end

    render json: { result: { message: ["Message successfully updated"] } }, status: 201
  end

  def unread_messages
    if current_user.retrieve_contacts
      retrieve = true
      current_user.update_attributes(:retrieve_contacts => false)
    else
      retrieve = false
    end

    #todo BT put this somewhere else
    unread_users = Message.where(sender_id:current_user.id, opened:false).select(:receiver_id)
    render json: { result: { messages: Message.response_messages(current_user.unread_messages), 
                                retrieve_contacts:retrieve,
                                unread_users:unread_users} }, status: 201
  end

  def last_message
    last_message = Message.where(sender_id: params[:sender_id], receiver_id: current_user.id).order('id DESC').limit(1)

    render json: { result: { message: Message.response_message(last_message)} }, status: 201
  end

  private

    def message_params
      params.permit(:receiver_id, :record)
    end 
end