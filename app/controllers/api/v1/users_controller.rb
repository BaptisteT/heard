class Api::V1::UsersController < Api::V1::ApiController
  include ApplicationHelper
  skip_before_action :authenticate_user, only: :create

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

      #Create welcome message
      message = Message.new
      message.receiver_id = user.id
      message.sender_id = 1
      message.opened = false
      message.record = open(URI.parse(process_uri("https://s3.amazonaws.com/heard_resources/welcome_message")))
      message.save 

      render json: { result: { auth_token: user.auth_token, user_id: user.id, user: user.contact_info } }, status: 201
    else 
      render json: { errors: { internal: user.errors } }, :status => 500
    end
  end

  def update_push_token
    current_user.update_attributes(:push_token => params[:push_token])
    render json: { result: { message: ["Push token successfully updated"] } }, status: 201
  end

  def get_my_contact
    #Android sends a String that we have to parse
    if params[:contact_numbers].is_a? String
      params[:contact_numbers] = friend_ids[1..-2].split(", ")
    end

    #include Waved contact
    users = User.where(phone_number: params[:contact_numbers])
                  .reject { |user| user.blocked_by_user(current_user.id) || user.id == current_user.id}

    users << User.find(1)

    # If sign up, then update other users :retrieve_contacts
    if params[:sign_up] and params[:sign_up]=="1"
      users.each { |user| user.update_attributes(:retrieve_contacts => true) }
    end

    render json: { result: { contacts: User.contact_info(users) } }, status: 201
  end

  def get_user_info
    user = User.find(params[:user_id])
    render json: { result: { contact: user.contact_info } }, status: 201
  end
end