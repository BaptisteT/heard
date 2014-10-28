desc "This task is called by the Heroku scheduler add-on"

task unread_messages_recall: :environment do
  if Time.now.tuesday?
    notifications_prod = []
    notifications_beta = []
    pusher_beta = Grocer.pusher(certificate: 'app/assets/cert.pem', passphrase:  "djibril", gateway: "gateway.push.apple.com")
    pusher_prod = Grocer.pusher(certificate: 'app/assets/WavedProdCert&Key.pem', passphrase: ENV['CERT_PASS'], gateway: "gateway.push.apple.com")
    User.all.each { |user|
      if ! user.push_token.blank?
        if user.unread_messages.count > 0 and user.last_message_date < 1.day.ago
          senders = User.find(user.unread_messages.uniq.pluck(:sender_id))
          if senders.count == 1
            names = senders[0].first_name + "!"
          else
            names = senders[0].first_name + " and other friends!"
          end
          text = "Hey " + user.first_name + ", you have unread messages from " + names
          notification = Grocer::Notification.new(
                            device_token:      user.push_token,
                            badge:             user.unread_messages.count,
                            alert:             text,
                            expiry:            Time.now + 60*600,
                            sound:             'default')

          if user.is_beta_tester
            notifications_beta += [notification]
          else
            notifications_prod += [notification]
          end
        end
      end
    }

    # Alert me
    notif_count = notifications_prod.count+notifications_beta.count
    begin
      client = Twilio::REST::Client.new(TWILIO_SID, TWILIO_TOKEN)
      client.account.messages.create(
        from: TWILIO_PHONE_NUMBER,
        to:   User.find(10).phone_number,
        body: "Just sent unread messages notif to " + notif_count + " people"
      )
    rescue Twilio::REST::RequestError => e
      Airbrake.notify(e)
    end

    notifications_prod.each do |notification|
      pusher_prod.push(notification)
    end
    notifications_beta.each do |notification|
      pusher_beta.push(notification)
    end
  end
end