
namespace :notification do
  desc "Send a notification to all users."
  task to_all: :environment do
    User.all.each do |user|
      begin
        if user.push_token  
          text = ""
          pusher = nil

          if user.phone_number.include?"+33"
            text = 'Les groupes d\'amis sont disponibles sur Waved!'
          else
            text = 'Group chat is now available on Waved!'
          end

          if user.is_beta_tester
            pusher = Grocer.pusher(certificate: 'app/assets/cert.pem', passphrase:  "djibril", gateway: "gateway.push.apple.com")
          else
            pusher = Grocer.pusher(certificate: 'app/assets/WavedProdCert&Key.pem', passphrase: ENV['CERT_PASS'], gateway: "gateway.push.apple.com")
          end

          notification = Grocer::Notification.new(
            device_token:      user.push_token,
            alert:             text,  
            sound:             'received_sound.aif',
            expiry:            Time.now + 60*600)

          pusher.push(notification)
        end
      rescue Exception => e
        Airbrake.notify(e)
      end
    end
  end
end