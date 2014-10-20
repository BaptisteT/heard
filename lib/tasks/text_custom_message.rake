namespace :custom_message do
  desc "Text custom message to perticular users who experience bugs"
  task text_custom_message: :environment do
    message = "This is a message from Waved. We are really sorry, a critical bug is currently preventing you from using Waved. This bug will be fixed in the next release. To use Waved before that, you can delete the current version and download the beta at www.waved.io/beta. Thanks for your support. The Waved team."
    if Rails.env.production?
      phone_numbers = ["+33651270873","+8615821924825","+15129929388"]
    else 
      phone_numbers = ["+33651270873"]
    end
    phone_numbers.each { |number|
      begin
        client = Twilio::REST::Client.new(TWILIO_SID, TWILIO_TOKEN)
        client.account.messages.create(
          from: TWILIO_PHONE_NUMBER,
          to:   number,
          body: message
        )
      rescue Twilio::REST::RequestError => e
        Airbrake.notify(e)
      end
    }
  end
end