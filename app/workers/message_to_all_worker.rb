class MessageToAllWorker
  include Sidekiq::Worker

  def perform(message_id)

    message_for_all = Message.find(message_id)

    User.where("id != 1").each do |receiver|
      message = Message.new
      message.record = message_for_all.record
      message.receiver_id = receiver.id
      message.sender_id = 1
      message.opened = false

      if message.save
        if receiver.push_token
          pusher = Grocer.pusher(certificate: 'app/assets/WavedProdCert&Key.pem', passphrase: ENV['CERT_PASS'], gateway: "gateway.push.apple.com")
          text = 'New message from Waved'
          badge_number = receiver.unread_messages.count
          notification = Grocer::Notification.new(
            device_token:      receiver.push_token,
            alert:             text,
            badge:             badge_number,
            sound:             'default',
            custom: { message: message.response_message})   
          pusher.push(notification)
        end
      end
    end
  end
end