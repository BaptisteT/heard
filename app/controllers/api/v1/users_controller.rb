class Api::V1::UsersController < Api::V1::ApiController

  def create
    code_request = CodeRequest.find_by(phone_number: params[:phone_number])

    if code_request.nil?
      render json: { errors: { unauthorized: "No code has been sent for this phone number" } }, :status => 401 and return 
    end

    if code_request.code.to_i != params[:code].to_i
      render json: { errors: { unauthorized: "Wrong SMS code" } }, :status => 401 and return 
    end

    user = User.new

    user.phone_number = params[:phone_number]
    user.first_name = params[:first_name]
    user.last_name = params[:last_name]

    if params[:profile_picture]
      user.profile_picture = StringIO.new(Base64.decode64(params[:profile_picture]))
    end

    if user.save
      code_request.destroy
      render json: { result: { auth_token: user.auth_token, user_id: user.id } }, status: 201
    else 
      render json: { errors: { internal: user.errors } }, :status => 500
    end
  end

  def update_push_token
    user = User.find(params[:user_id])
    user.update_attributes(:push_token => params[:push_token])
  end

  def unread_messages
    user = User.find(params[:user_id])
    render json: { result: { messages: user.unread_messages } }, status: 201
  end
end