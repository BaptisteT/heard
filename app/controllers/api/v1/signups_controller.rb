class Api::V1::SignupsController < Api::V1::ApiController

  def create
    code = (rand(9) + 1)*10**(SIGNUP_CODE_DIGITS-1) + rand(10**(SIGNUP_CODE_DIGITS-1))

    begin
      client = Twilio::REST::Client.new(TWILIO_SID, TWILIO_TOKEN)
      client.account.messages.create(
        from: TWILIO_PHONE_NUMBER,
        to:   params[:phone_number],
        body: "Heard code #{code}"
      )
    rescue Twilio::REST::RequestError => e
      render json: { errors: { twilio: e.message } }, :status => 500 and return
    end

    render json: { result: { code: code } }, status: 201
  end
end