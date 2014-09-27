module ApplicationHelper
  def process_uri(uri)
    require 'open-uri'
    require 'open_uri_redirections'
    open(uri, :allow_redirections => :safe) do |r|
      r.base_uri.to_s
    end
  end

  def send_tips_message(receiver,tips_id)
    begin 
      message = Message.new
      message.receiver_id = receiver.id
      message.sender_id = 1
      message.opened = false
      message.record = open(URI.parse(process_uri("https://s3.amazonaws.com/heard_resources/tips_message_"+tips_id.to_s)))
      message.record_content_type = "audio/m4a"

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
    rescue Exception => e
      Airbrake.notify(e)
    end
  end
end
