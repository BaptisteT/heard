class User < ActiveRecord::Base
  has_many :messages

  validates :phone_number, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true

  # This method associates the attribute ":avatar" with a file attachment
  has_attached_file :avatar, styles: { thumb: '100x100#' }, path: ":style/:file_name"
  validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/

end
