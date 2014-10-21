class Api::V1::GroupsController < Api::V1::ApiController

  def create
    group = Group.new
    group.name = params[:group_name]
    group.members_number = params[:members].count
    if group.members_number > 2 and group.save
      params[:members].each { |user_id|
        membership = GroupMembership.new
        membership.user_id = user_id
        membership.group_id = group.id
        membership.save!
        #todo BT send notif to other members
      }
      render json: { result: { group_id: group.id } }, status: 201
    else 
      render json: { errors: { internal: group.errors } }, :status => 500
    end
  end

  def get_group_info
    group = Group.find(params[:group_id])
    render json: { result: { group: group.group_info } }, status: 201
  end
end