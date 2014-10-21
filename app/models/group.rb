class Group < ActiveRecord::Base
  has_many :group_memberships, :class_name => 'GroupMembership'
  has_many :users, through: :group_memberships
  validates :name, presence: true

  def member_ids
    self.users.pluck(:id)
  end
end