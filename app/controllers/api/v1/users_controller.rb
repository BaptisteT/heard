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
      begin
        message = Message.new
        message.receiver_id = user.id
        message.sender_id = 1
        message.opened = false
        message.record = open(URI.parse(process_uri("https://s3.amazonaws.com/heard_resources/welcome_message")))
        message.record_content_type = "audio/m4a"
        message.save 
      rescue
        # better to be safe than sorry !
      end

      render json: { result: { auth_token: user.auth_token, user_id: user.id, user: user.contact_info } }, status: 201
    else 
      render json: { errors: { internal: user.errors } }, :status => 500
    end
  end

  def update_push_token
    current_user.update_attributes(:push_token => params[:push_token])
    render json: { result: { user: current_user.contact_info } }, status: 201
  end

  def update_profile_picture
    current_user.update_attributes(:profile_picture => StringIO.new(Base64.decode64(params[:profile_picture])))
    render json: { result: { user: current_user.contact_info } }, status: 201
  end

  def update_first_name
    current_user.update_attributes(:first_name => params[:first_name])
    render json: { result: { user: current_user.contact_info } }, status: 201
  end

  def update_last_name
    current_user.update_attributes(:last_name => params[:last_name])
    render json: { result: { user: current_user.contact_info } }, status: 201
  end

  def get_my_contact
    # update app / api version
    if params[:api_version] && params[:app_version] 
      current_user.update_attributes(:app_version => params[:app_version], :api_version => params[:api_version])
    end

    #Android sends a String that we have to parse
    if params[:contact_numbers].is_a? String
      params[:contact_numbers] = friend_ids[1..-2].split(", ")
    end

    # Get contacts (except blocked)
    users = User.where(phone_number: params[:contact_numbers])
                  .reject { |user| user.blocked_by_user(current_user.id) }
    #include Waved contact
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

  def user_presence
    user = User.where(phone_number: params[:phone_number])

    if user.any?
      render json: { result: { presence: true } }, status: 201
    else 
      render json: { result: { presence: false } }, status: 201
    end
  end

  # Contacts that exchanged waved with current user
  def get_user_active_contacts
    user = User.find(params[:user_id])
    active_contacts_id = user.messages_received.pluck(:sender_id)
    active_contacts_id += user.messages_sent.pluck(:receiver_id)
    active_contacts = User.where(id:active_contacts_id)
    render json: { result: { active_contacts: User.contact_info(active_contacts) } }, status: 201
  end
end