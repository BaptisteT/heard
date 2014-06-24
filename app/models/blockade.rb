class Blockade < ActiveRecord::Base

  validates :blocked_id, presence: true
  validates :blocker_id, presence: true

end