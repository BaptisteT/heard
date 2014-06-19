class Api::V1::MessagesController < Api::V1::ApiController

  def create
    Rails.logger.debug "TRUCHOV create message"

    message = Message.new(message_params)

    message.record = StringIO.new(params[:record])
    message.opened = false

    if message.save
      render json: { result: { message: ["Record successfully saved"] } }, status: 201
    else 
      render json: { errors: { internal: message.errors } }, :status => 500
    end
  end

  private

    def message_params
      params.permit(:sender_id, :receiver_id)
    end 
end