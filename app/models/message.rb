class Message < ActiveRecord::Base
  belongs_to :sender, class_name: "User"
  belongs_to :receiver, class_name: "User"

  validates :sender_id, presence: true
  validates :receiver_id, presence: true

  #Interpolation 
  Paperclip.interpolates :file_name do |attachment, style|
    attachment.instance.id.to_s + "_" + attachment.name.to_s
  end

  has_attached_file :record, path: ":file_name", bucket: proc { |attachment| Rails.env.production? ? MESSAGE_BUCKET : MESSAGE_BUCKET_STAGING}
  validates_attachment_content_type :record,
    :content_type => ['image/jpeg', 'audio/m4a' ]
  
  def response_message
    { id: self.id,
      receiver_id: self.receiver_id,
      sender_id: self.sender_id,
      group_id: self.group_id,
      message_type: self.record_file_name,
      text: self.text,
      date: self.creation_date == 0 ? self.created_at.to_time.to_i : self.creation_date,
      opened: self.opened }
  end

  def self.response_messages(messages)
    messages.map { |message| message.response_message }
  end
end
