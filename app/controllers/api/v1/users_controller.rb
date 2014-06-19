class Api::V1::UsersController < Api::V1::ApiController

  def create
    user = User.new

    user.phone_number = params[:phone_number]
    user.first_name = params[:first_name]
    user.last_name = params[:last_name]

    if params[:profile_picture]
      user.profile_picture = StringIO.new(Base64.decode64(params[:profile_picture]))
    end

    if user.save
      render json: { result: { user: user } }, status: 201
    else 
      render json: { errors: { internal: user.errors } }, :status => 500
    end
  end
end