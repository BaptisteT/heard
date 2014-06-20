class CodeRequest < ActiveRecord::Base
  validates :phone_number, presence: true, uniqueness: true
  validates :code, presence: true
end
