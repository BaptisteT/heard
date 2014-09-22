class FutureRecord < ActiveRecord::Base
  has_many :future_messages

  #Interpolation 
  Paperclip.interpolates :file_name do |attachment, style|
    attachment.instance.id.to_s + "_" + attachment.name.to_s
  end

  has_attached_file :recording, path: ":file_name", bucket: proc { |attachment| Rails.env.production? ? MESSAGE_BUCKET : MESSAGE_BUCKET_STAGING}
  validates_attachment_content_type :recording,
    :content_type => [ 'audio/mpeg', 'audio/x-mpeg', 'audio/mp3', 'audio/x-mp3', 'audio/mpeg3', 'audio/x-mpeg3', 'audio/mpg', 'audio/x-mpg', 'audio/x-mpegaudio', 'audio/m4a' ]
end
