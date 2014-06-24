class Api::V1::BlockadesController < Api::V1::ApiController

  def create
    blockade = Blockade.new(blockade_params)
    blockade.blocker_id = current_user.id
    if blockade.save
      render json: { result: { message: ["Blockade successfully saved"] } }, status: 201
    else 
      render json: { errors: { internal: blockade.errors } }, :status => 500
    end
  end

  private

    def blockade_params
      params.permit(:blocked_id)
    end 
end