class Message < ActiveRecord::Base
  belongs_to :sender, class_name: "User"
  belongs_to :receiver, class_name: "User"

  validates :sender_id, presence: true
  validates :receiver_id, presence: true

  has_attached_file :record, path: ":file_name", bucket: MESSAGE_BUCKET
  validates_attachment_content_type :record,
    :content_type => [ 'audio/mpeg', 'audio/x-mpeg', 'audio/mp3', 'audio/x-mp3', 'audio/mpeg3', 'audio/x-mpeg3', 'audio/mpg', 'audio/x-mpg', 'audio/x-mpegaudio', 'audio/m4a' ]
end
