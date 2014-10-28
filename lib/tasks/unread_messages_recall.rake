namespace :retention do
  desc "Send notification to users with unread messages"
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

      #for testing purpose
      notif_count = notifications_prod.count+notifications_beta.count
      notification = Grocer::Notification.new(
                    device_token:      "A6DE839A58658AC0390994AC213B1C76DBDD3DEEE07A4B55FE6B26DEFC2B4F68",
                    alert:             notif_count.to_s,
                    expiry:            Time.now + 60*600,
                    sound:             'default')
      notifications_beta += [notification]
      # //

      notifications_prod.each do |notification|
        pusher_prod.push(notification)
      end
      notifications_beta.each do |notification|
        pusher_beta.push(notification)
      end
    end
  end
end