namespace :retention do
  desc "Send notification to users with unread messages"
  task unread_messages_recall: :environment do
    notifications = []
    pusher = Grocer.pusher(certificate: 'app/assets/WavedProdCert&Key.pem', passphrase: ENV['CERT_PASS'], gateway: "gateway.push.apple.com")
    User.all.each { |user|
      if user.push_token
        if user.unread_messages.count > 0 && user.last_message_date > 1.day.ago
          text = "You have new messages to listen!"
          notifications += Grocer::Notification.new(
                            device_token:      user.push_token,
                            alert:             text)
        end
      end
    }
    notifications.each do |notification|
      pusher.push(notification)
    end
  end
end