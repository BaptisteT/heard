namespace :retention do
  desc "Send notification to users with unread messages"
  task unread_messages_recall: :environment do
    notifications_prod = []
    notifications_beta = []
    pusher_beta = Grocer.pusher(certificate: 'app/assets/cert.pem', passphrase:  "djibril", gateway: "gateway.push.apple.com")
    pusher_prod = Grocer.pusher(certificate: 'app/assets/WavedProdCert&Key.pem', passphrase: ENV['CERT_PASS'], gateway: "gateway.push.apple.com")
    User.all.each { |user|
      if user.push_token
        if user.unread_messages.count > 0 and user.last_message_date < 1.day.ago
          text = "You have new messages to listen!"
          notification = Grocer::Notification.new(
                            device_token:      user.push_token,
                            alert:             text,
                            sound:             'default')

          if user.is_beta_tester
            notifications_beta += [notification]
          else
            notifications_prod += [notification]
          end
        end
      end
    }
    notifications_prod.each do |notification|
      pusher_prod.push(notification)
    end
    notifications_beta.each do |notification|
      pusher_beta.push(notification)
    end
  end
end