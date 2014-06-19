class User < ActiveRecord::Base
  has_many :messages

  validates :phone_number, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true

  #Interpolation 
  Paperclip.interpolates :file_name do |attachment, style|
    attachment.instance.id.to_s + "_" + attachment.name.to_s
  end

  has_attached_file :profile_picture, path: ":style/:file_name", bucket: PROFILE_PICTURE_BUCKET
  validates_attachment_content_type :profile_picture, :content_type => /\Aimage\/.*\Z/
end
