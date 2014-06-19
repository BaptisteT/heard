class Message < ActiveRecord::Base
  belongs_to :sender, class_name: "User"
  belongs_to :receiver, class_name: "User"

  validates :sender_id, presence: true
  validates :receiver_id, presence: true
  validates :url, presence: true

  # Paperclip.interpolates :file_name do |attachment, style|
  #   attachment.instance.id.to_s + "_" + attachment.name.to_s
  # end

  # has_attached_file :url, path: ":style/:file_name", bucket: MESSAGE_BUCKET
  # validates_attachment_content_type :record, :content_type => /\Aimage\/.*\Z/
end
