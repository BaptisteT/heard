class Api::V1::MessagesController < Api::V1::ApiController

  def create
    Rails.logger.debug "TRUCHOV create message"

    message = Message.new(message_params)

    message.opened = false

    if message.save
      receiver = User.find(params[:receiver_id])
      if (receiver.push_token)
        #notif params
        sender  = User.find(params[:sender_id])
        message = 'New message from @' + sender.first_name
        badge_number = receiver.unread_messages.count

        #notif config
        APNS.pem = 'app/assets/cert.pem'
        APNS.port = 2195
        APNS.pass = "djibril"
        APNS.host = 'gateway.push.apple.com' 

        APNS.send_notification(receiver.push_token , :alert => message, :badge => badge_number)
      end

      render json: { result: { message: ["Message successfully saved"] } }, status: 201
    else 
      render json: { errors: { internal: message.errors } }, :status => 500
    end
  end

  def mark_as_opened
    message = Message.find(params[:message_id])
    message.update_attributes(:opened => true)
    render json: { result: { message: ["Message successfully updated"] } }, status: 201
  end

  private

    def message_params
      params.permit(:sender_id, :receiver_id, :record)
    end 
end