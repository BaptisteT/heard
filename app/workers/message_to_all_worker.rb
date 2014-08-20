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
          text = 'New message from Waved'
          badge_number = receiver.unread_messages.count

          if is_below_threshold(receiver.app_version,FIRST_PRODUCTION_VERSION)
            APNS.pem = 'app/assets/cert.pem'
            APNS.pass = "djibril"
          else
            APNS.pem = 'app/assets/WavedProdCert&Key.pem'
            APNS.pass = ENV['CERT_PASS']
          end
          
          APNS.send_notification(receiver.push_token , :alert => text, :badge => badge_number, :sound => 'default',
                                                         :other => {:message => message.response_message})
        end
      end
    end
  end
end