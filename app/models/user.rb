class User < ActiveRecord::Base
  before_create :generate_token

  has_many :messages_received, class_name: "Message", foreign_key: "receiver_id"
  has_many :messages_sent, class_name: "Message", foreign_key: "sender_id"

  validates :phone_number, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true

  #Interpolation 
  Paperclip.interpolates :file_name do |attachment, style|
    attachment.instance.id.to_s + "_" + attachment.name.to_s
  end

  has_attached_file :profile_picture, path: ":style/:file_name", bucket: PROFILE_PICTURE_BUCKET
  validates_attachment_content_type :profile_picture, :content_type => /\Aimage\/.*\Z/

  def generate_token
    self.auth_token = loop do
      random_token = SecureRandom.urlsafe_base64(nil, false)
      break random_token unless self.class.exists?(auth_token: random_token)
    end
  end

  def unread_messages
    self.messages_received.where(opened: false)
  end
end
