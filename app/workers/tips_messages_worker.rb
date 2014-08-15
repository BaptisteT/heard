class TipsMessagesWorker
  include Sidekiq::Worker

  def perform(receiver,tips_id)

    message = Message.new
    message.receiver_id = receiver.id
    message.sender_id = 1
    message.opened = false
    message.record = open(URI.parse(process_uri("https://s3.amazonaws.com/heard_resources/tips_message_"+tips_id)))
    message.record_content_type = "audio/m4a"

    if message.save
      if receiver.push_token
          #notif params
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