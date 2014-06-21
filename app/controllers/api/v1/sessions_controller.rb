class Api::V1::SessionsController < Api::V1::ApiController
  skip_before_action :authenticate_user, only: [:create, :confirm_sms_code]

  def create
    code_request = CodeRequest.find_by(phone_number: params[:phone_number])

    if code_request.nil?
      code_request = CodeRequest.new
      code_request.phone_number = params[:phone_number]
    end
    
    code_request.code = (rand(9) + 1)*10**(SESSION_CODE_DIGITS-1) + rand(10**(SESSION_CODE_DIGITS-1))

    if !code_request.save
      render json: { errors: { internal: code_request.errors } }, :status => 500 and return
    end  

    begin
      client = Twilio::REST::Client.new(TWILIO_SID, TWILIO_TOKEN)
      client.account.messages.create(
        from: TWILIO_PHONE_NUMBER,
        to:   code_request.phone_number,
        body: "Heard code #{code_request.code}"
      )
    rescue Twilio::REST::RequestError => e
      render json: { errors: { twilio: e.message } }, :status => 500 and return
    end

    render json: { result: { } }, status: 201
  end

  def confirm_sms_code
    code_request = CodeRequest.find_by(phone_number: params[:phone_number])

    if code_request.nil?
      render json: { errors: { unauthorized: "No SMS code has been sent to this number" } }, :status => 401 and return 
    end

    if (params[:code].to_i == code_request.code.to_i)
      existing_user = User.find_by(phone_number: params[:phone_number])

      if existing_user.nil?
        render json: { result: {} }, status: 201  
      else 
        existing_user.generate_token
        existing_user.save
        
        code_request.destroy

        render json: { result: { auth_token: existing_user.auth_token } }, status: 201 
      end
    else
      render json: { errors: { unauthorized: "Wrong SMS code" } }, :status => 401
    end
  end
end