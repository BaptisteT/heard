namespace :launch_namespace do
  desc "Text all beta testers which did not download last version"
  task text_beta_testers: :environment do
    User.all.each { |user|
      if user.app_version != "1.1.2" and user.app_version != "1.1.3" 
        begin
          client = Twilio::REST::Client.new(TWILIO_SID, TWILIO_TOKEN)
          client.account.messages.create(
            from: TWILIO_PHONE_NUMBER,
            to:   user.phone_number,
            body: "Waved is now available on the App Store! Download it at " + DOWNLOAD_LINK + "."
          )
        rescue Twilio::REST::RequestError => e
        end
      end
    }
  end
end