class Api::V1::GroupsController < Api::V1::ApiController

  def create
    group = Group.new
    group.name = params[:group_name]
    group.members_number = params[:members].count
    pusher_beta = Grocer.pusher(certificate: 'app/assets/cert.pem', passphrase:  "djibril", gateway: "gateway.push.apple.com")
    pusher_prod = Grocer.pusher(certificate: 'app/assets/WavedProdCert&Key.pem', passphrase: ENV['CERT_PASS'], gateway: "gateway.push.apple.com")
    notifications_beta = []
    notifications_prod = []
    text = current_user.first_name + " just added you to the group " + group.name
    if group.members_number > 2 and group.save
      params[:members].each { |user_id|
        membership = GroupMembership.new
        membership.user_id = user_id
        membership.group_id = group.id
        membership.save!
        #todo BT send notif to other members
        user = User.find(user_id)
        user.update_attributes(:retrieve_contacts => true)
        if !user.push_token.blank? and user_id != current_user.id
          notification = Grocer::Notification.new(
                            device_token:      user.push_token,
                            alert:             text,
                            expiry:            Time.now + 60*600,
                            sound:             'default')
          if user.is_beta_tester
            notifications_beta += [notification]
          else
            notifications_prod += [notification]
          end
        end
      }
      notifications_prod.each do |notification|
        pusher_prod.push(notification)
      end
      notifications_beta.each do |notification|
        pusher_beta.push(notification)
      end
      render json: { result: { group_id: group.id } }, status: 201
    else 
      render json: { errors: { internal: group.errors } }, :status => 500
    end
  end

  def get_group_info
    group = Group.find(params[:group_id])
    render json: { result: { group: group.group_info } }, status: 201
  end

  def leave_group
    #destroy membership
    GroupMembership.destroy_all(user_id:current_user.id, group_id:params[:group_id])
    # destroy messages
    Message.destroy_all(group_id:params[:group_id], receiver_id:current_user.id, opened:false)
    #update members number
    group = Group.find(params[:group_id])
    new_members_number = GroupMembership.where(group_id:params[:group_id]).count
    group.update_attributes(members_number:new_members_number)
    render json: { result: {message:["Group successfully left"]} }, status: 201
  end

  def add_member
    group = Group.find(params[:group_id])

    # check not already a member
    if group.member_ids.include?(params[:new_member_id].to_i)
      render json: { errors: {message:["Already a member"]} }, status: 500
    else
      membership = GroupMembership.new
      membership.user_id = params[:new_member_id]
      membership.group_id = params[:group_id]
      membership.save!
      new_members_number = GroupMembership.where(group_id:group.id).count
      group.update_attributes(members_number:new_members_number)
      #send notification
      pusher_beta = Grocer.pusher(certificate: 'app/assets/cert.pem', passphrase:  "djibril", gateway: "gateway.push.apple.com")
      pusher_prod = Grocer.pusher(certificate: 'app/assets/WavedProdCert&Key.pem', passphrase: ENV['CERT_PASS'], gateway: "gateway.push.apple.com")
      notifications_beta = []
      notifications_prod = []

      group.users(true).each { |user|
        if user.id == membership.user_id
          text = current_user.first_name + " just added you to the group " + group.name
        else
          text = current_user.first_name + " just added " + User.find(params[:new_member_id]).first_name + " to the group " + group.name
        end 
        if !user.push_token.blank? and user.id != current_user.id
          user.update_attributes(:retrieve_contacts => true)
          notification = Grocer::Notification.new(
                            device_token:      user.push_token,
                            alert:             text,
                            expiry:            Time.now + 60*600,
                            sound:             'default')
          if user.is_beta_tester
            notifications_beta += [notification]
          else
            notifications_prod += [notification]
          end
        end
      }
      notifications_prod.each do |notification|
        pusher_prod.push(notification)
      end
      notifications_beta.each do |notification|
        pusher_beta.push(notification)
      end
      render json: { result: {is_full:false, group:group.group_info} }, status: 201
    end
  end

  def retrieve_group_conversation
    # imperfect implementation (goal: avoid n times the same messages)
    creator_id = Group.find(params[:group_id]).member_ids[0]
    first_added_id = Group.find(params[:group_id]).member_ids[1]
    messages = Message.where("group_id = ? and ((sender_id = ? and receiver_id = ?) or receiver_id = ?)", 
      params[:group_id],creator_id,first_added_id,creator_id)
    render json: { result: { messages: Message.response_messages(messages)} }, status: 201
  end
end