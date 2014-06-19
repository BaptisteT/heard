class Api::V1::MessagesController < Api::V1::ApiController

  def create
    Rails.logger.debug "TRUCHOV create message"

    message = Message.new(message_params)

    message.opened = false

    if message.save
      receiver = User.find(params[:receiver_id])
      if (receiver.push_token)
        #send notif
        sender  = User.find(params[:sender_id])
        message = 'New message from @' + sender.first_name
        APNS.send_notification(receiver.push_token, , :alert => message, :badge => 1)
      end

      render json: { result: { message: ["Record successfully saved"] } }, status: 201
    else 
      render json: { errors: { internal: message.errors } }, :status => 500
    end
  end

  private

    def message_params
      params.permit(:sender_id, :receiver_id, :record)
    end 
end