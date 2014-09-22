class HomeController < ApplicationController
  include ApplicationHelper

  def beta
    redirect_to action:index
  end

  def index
  end

  def text_link
    invited_number = InvitedNumber.new
    invited_number.phone_number = params[:number]
    
    if invited_number.save
      begin
        client = Twilio::REST::Client.new(TWILIO_SID, TWILIO_TOKEN)
        client.account.messages.create(
          from: TWILIO_PHONE_NUMBER,
          to:   params[:number],
          body: "Download Waved for iPhone at " + DOWNLOAD_LINK + "."
        )
        @result_message = "Thanks. We sent a download link to your phone."
      rescue Twilio::REST::RequestError => e
        Airbrake.notify(e)
        @result_message = "Sorry, an error occured."
      end
    end

    render :index
  end

  def privacy
  end
end