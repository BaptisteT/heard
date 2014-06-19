class Message < ActiveRecord::Base
  belongs_to :sender, class_name: "User"
  belongs_to :receiver, class_name: "User"

  validates :sender_id, presence: true
  validates :receiver_id, presence: true

  Paperclip.interpolates :file_name do |attachment, style|
    "record_#{attachment.instance.id.to_s}"
  end

  has_attached_file :record, path: ":style/:file_name", bucket: MESSAGE_BUCKET
  validates_attachment_content_type :record,
    :content_type => [ 'record/mpeg', 'record/x-mpeg', 'record/mp3', 'record/x-mp3', 'record/mpeg3', 'record/x-mpeg3', 'record/mpg', 'record/x-mpg', 'record/x-mpegaudio' ]
end
