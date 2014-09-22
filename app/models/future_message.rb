class FutureMessage < ActiveRecord::Base
  has_one :future_record

  validates :sender_id, presence: true
  validates :receiver_number, presence: true
  validates :future_record_id, presence: true
end
