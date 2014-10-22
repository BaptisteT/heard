class Group < ActiveRecord::Base
  has_many :group_memberships, :class_name => 'GroupMembership'
  has_many :users, through: :group_memberships
  validates :name, presence: true

  def member_ids
    self.users.pluck(:id)
  end

  def group_info
    { id: self.id,
      group_name: self.name,
      member_ids: self.member_ids }
  end

  def self.group_info(groups)
    groups.map { |group| group.group_info }
  end
end