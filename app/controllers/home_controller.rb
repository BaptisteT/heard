class HomeController < ApplicationController
  include ApplicationHelper

  def beta
  end

  def index
  end

  def text_link
    # todo BT check number is valid ?
    invited_number = InvitedNumber.new
    invited_number.phone_number = params[:phone_number]
    
    if invited_number.save
      begin
        client = Twilio::REST::Client.new(TWILIO_SID, TWILIO_TOKEN)
        client.account.messages.create(
          from: TWILIO_PHONE_NUMBER,
          to:   params[:number],
          body: "Download Waved at " + DOWNLOAD_LINK
        )
      rescue Twilio::REST::RequestError => e
        
      end
    end

    redirect_to action:index
  end
end