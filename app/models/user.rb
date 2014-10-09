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

  has_attached_file :profile_picture, path: ":style/:file_name", bucket: proc { |attachment| Rails.env.production? ? PROFILE_PICTURE_BUCKET : PROFILE_PICTURE_BUCKET_STAGING}
  validates_attachment_content_type :profile_picture, :content_type => /\Aimage\/.*\Z/

  def generate_token
    self.auth_token = loop do
      random_token = SecureRandom.urlsafe_base64(nil, false)
      break random_token unless self.class.exists?(auth_token: random_token)
    end
  end

  def unread_messages
    blocked_ids = Blockade.where(blocker_id: self.id).select(:blocked_id)
    self.messages_received.where(opened: false).where.not(sender_id: blocked_ids)
  end

  def blocked_by_user(blocker_id)
    Blockade.where(:blocker_id => blocker_id, :blocked_id => self.id).exists?
  end

  def contact_info
    { id: self.id,
      phone_number: self.phone_number,
      first_name: self.first_name,
      last_name: self.last_name }
  end

  def self.contact_info(users)
    users.map { |user| user.contact_info }
  end

  def last_message_date #read or sent
    last_read_date = 0
    last_sent_date = 0
    if self.messages_received.count > 0
      last_read_date = self.messages_received.last.updated_at
    end
    if self.messages_sent.count > 0
      last_sent_date = self.messages_sent.last.created_at
    end
    max(last_sent_date,last_read_date)
  end
end
