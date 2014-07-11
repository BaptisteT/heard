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

            #notif params
            sender  = current_user
            text = 'New message from Waved'
            badge_number = receiver.unread_messages.count

            #notif config
            APNS.pem = 'app/assets/cert.pem'
            APNS.port = 2195
            APNS.pass = "djibril"
            APNS.host = 'gateway.push.apple.com' 

            APNS.send_notification(receiver.push_token , :alert => text, :badge => badge_number, :sound => 'default',
                                                         :content_available => 1,
                                                         :other => {:message => message.response_message})
        end
      end
    end
  end
end