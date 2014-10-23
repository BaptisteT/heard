class Group < ActiveRecord::Base
  has_many :group_memberships, :class_name => 'GroupMembership'
  has_many :users, through: :group_memberships
  validates :name, presence: true

  def member_ids
    self.users.pluck(:id)
  end

  def member_first_names
    self.users.pluck(:first_name)
  end

  def member_last_names
    self.users.pluck(:last_name)
  end

  def group_info
    { id: self.id,
      group_name: self.name,
      member_ids: self.member_ids,
      member_first_names: self.member_first_names,
      member_last_names: self.member_last_names}
  end

  def self.group_info(groups)
    groups.map { |group| group.group_info }
  end
end