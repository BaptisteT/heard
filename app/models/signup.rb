class Signup < ActiveRecord::Base
  validates :phone_number, presence: true
  validates :code, presence: true
end
