class Api::V1::MessagesController < Api::V1::ApiController

  def create
    message = Message.new

    message.record = StringIO.new(params[:record])

    if message.save
      render json: { result: { message: message } }, status: 201
    else 
      render json: { errors: { internal: message.errors } }, :status => 500
    end
  end


end