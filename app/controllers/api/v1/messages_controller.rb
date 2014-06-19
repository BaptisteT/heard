class Api::V1::MessagesController < Api::V1::ApiController

  def create
    message = Message.new(message_params)

    #j'ai fait une gourde, j'ai fait une migration ou j'ai mis url (pour l'url du record). Mais si tu te sers de Paperclip, il faut refaire une migration et supprimer url.
    message.record = StringIO.new(params[:record])
    message.opened = false

    if message.save
      render json: { result: { message: message } }, status: 201
    else 
      render json: { errors: { internal: message.errors } }, :status => 500
    end
  end

  private

    def message_params
      params.permit(:sender_id, :receiver_id)
    end 
end