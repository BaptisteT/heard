class HomeController < ApplicationController
  include ApplicationHelper

  def beta
  end

  def index
  end

  def text_link
    # todo BT check number is valid ?
    invited_number = InvitedNumber.new
    invited_number.phone_number = params[:number]
    
    if invited_number.save
      begin
        client = Twilio::REST::Client.new(TWILIO_SID, TWILIO_TOKEN)
        client.account.messages.create(
          from: TWILIO_PHONE_NUMBER,
          to:   params[:number],
          body: "Hey. To download Waved for iPhone, tap here: " + DOWNLOAD_LINK
        )
        @result_message = "Thanks. We sent a download link to your phone."
      rescue Twilio::REST::RequestError => e
        @result_message = "Sorry, an error occured."
      end
    end

    render :index
  end
end