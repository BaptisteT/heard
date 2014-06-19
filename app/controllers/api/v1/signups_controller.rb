class Api::V1::SignupsController < Api::V1::ApiController

  def create
    signup = Signup.new

    signup.phone_number = params[:phone_number]
    signup.code = (rand(9) + 1)*10**(SIGNUP_CODE_DIGITS-1) + rand(10**(SIGNUP_CODE_DIGITS-1))

    begin
      client = Twilio::REST::Client.new account_sid, auth_token
      client.account.messages.create(
        from: TWILIO_PHONE_NUMBER,
        to:   signup.phone_number,
        body: "Heard code #{signup.code}"
      )
    rescue Twilio::REST::RequestError => e
      render json: { errors: { twilio: e.message } }, :status => 500 and return
    end

    if signup.save
      render json: { result: { code: signup.code } }, status: 201
    else 
      render json: { errors: { internal: signup.errors } }, :status => 500
    end
  end
end