include SendGrid # required to access the helper methods
class ApplicationController < ActionController::API
  # Capture and handle any errors
  include Error::ErrorHandler
  before_action :add_allow_credentials_headers

  # Handle CORS requests
  def add_allow_credentials_headers
  	# https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS#section_5
  	#
  	# Because we want our front-end to send cookies to allow the API to be authenticated
  	# (using 'withCredentials' in the XMLHttpRequest), we need to add some headers so
  	# the browser will not reject the response
  	# https://stackoverflow.com/questions/17858178/allow-anything-through-cors-policy

  	# TODO: Need to add an allowed origins table - not totally sure on this still
  	response.headers['Access-Control-Allow-Origin'] = '*' # this eventually needs to be restricted
  	response.headers['Access-Control-Allow-Methods'] = 'POST, PATCH, PUT, DELETE, GET, OPTIONS'
  	response.headers['Access-Control-Request-Method'] = '*'
  	response.headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization, HTTP_AUTHORIZATION, HTTP_X_AUTHORIZATION'
  end

	# https://stackoverflow.com/questions/32500073/request-header-field-access-control-allow-headers-is-not-allowed-by-itself-in-pr
  def options
	   render :status => 200, :'Access-Control-Allow-Headers' => 'accept, content-type, authorization, HTTP_AUTHORIZATION, HTTP_X_AUTHORIZATION'
  end

  def true?(obj)
    obj.to_s == "true"
  end

  def make_token(length = 50)
    o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
    Digest::SHA256.hexdigest (0...50).map { o[rand(o.length)] }.join
  end

  def current_user
    # TODO: All of this needs to be handled better. Need to consider JWT Token feasability and refresh tokens

    if bearer_token
      if /^[a-z0-9]+$/.match bearer_token
        @token = UserToken.find_by token: bearer_token
        if @token != nil && !@token.is_expired?
          @current_user = @token.user
          @current_user
        else
          # if we dont find it check to see if this token is OAuth
          @oauth_token = OauthToken.find_by access_token: bearer_token
          if @oauth_token # eventually check for expiration currently they are perpetual and can be cleared by the user
            @current_user = @oauth_token.user
            @current_user
          end
          # then do nothing so this just returns nil
        end
      end
    end
  end

  # checks to make sure that a user is "logged in"
  def require_user
    render status: 401, json: { message: 'You are not logged in/authorization required/you are not authorized to use this application.' }  unless current_user != nil
  end

  # make sure that the current user in the member role
  def require_member
    render status: 403, json: { message: 'You are not authorized to use this endpoint.' } unless current_user.isinrole(0) #current_user.is_member?
  end

  # before_action
  # do not use this without first using require_user
  def require_role(roleId)
    if !(current_user && current_user.isinrole(roleId))
      # Email if this is a logged in user trying to access part of the api they shouldn't be in
      if ENV["RAILS_ENV"] != nil && ENV["RAILS_ENV"] == 'production' && current_user
        vMessage = "#{current_user} tried to access an endpoint which they do not have access to: #{request.original_url}. Please take appropriate action."
        send_email('dale@daleslab.com', 'Unauthorized Endpoint Use', vMessage)
      end

      # TODO: Always a log access violations

      # return to the user
      render status: 403, json: { message: 'You are not authorized to use this endpoint.' }
    end
  end

  def require_one_role(roleIdArray)
    isInRole = false
    roleIdArray.each do |roleId|
      isInRole = true if (current_user && current_user.isinrole(roleId))
    end

    if !isInRole
      render status: 403, json: { message: 'You are not authorized to use this endpoint.' }
    end
  end

  def create_activity
    # TODO:
  end

  def new_approval approval_k_id, owner_id = 0, approval_group = 0, approverIdList = []
    @approval_kind = ApprovalKind.find(approval_k_id.to_i);
    if @approval_kind != nil
      new_approval = Approval.new(approval_kind_id: @approval_kind.id) #approval kind id
      new_approval.full_consent = true #eventually this should be passed in logic

      usersArray = Array.new
      approvalKindRoles = @approval_kind.roles
      if approvalKindRoles.count > 0
        approvalKindRoles.each do |role|
          User.where("is_member = ?", true).each do |user|
            usersArray << user if user.isinrole(role.id)
          end
        end
      else
        # if we can't find roles then we need to get the owner object
        # somehow we need to get the ship owner user here when that object is no available yet
        # some kinds of requests might not have roles - it might be an object with an owner who gets to manage what happens
        if owner_id != 0 && approval_group == 0 && approverIdList.count == 0
          owner = User.find_by_id(owner_id.to_i)
          if owner != nil
            usersArray << owner
          else
            raise 'Cannot create the approval request. The selected approval kind has no roles assigned to it and no valid owner user id was supplied.'
          end
        elsif owner_id == 0 && approval_group != 0 && approverIdList.count == 0
          role = Role.find_by_id(approval_group.to_i)
          if role != nil
            User.where("is_member = ?", true).each do |user|
              usersArray << user if user.isinrole(role.id)
            end
          else
            raise 'Cannot not create approval request. The selected approval kind has no assigned roles and the provided group value could not be found.'
          end
        elsif owner_id == 0 && approval_group == 0 && approverIdList.count != 0
          usersArray.concat User.where('id IN (?) AND is_member = ?', approverIdList, true)
        else
          raise 'Cannot create the approval request. The selected approval kind has no roles assigned to it.'
        end
      end


      usersArray.uniq!{|x| x} # get uniq users

      if usersArray.count > 0
        # add all of the approvers to the approval and email them
        usersArray.each do |user|
          new_approval.approval_approvers << ApprovalApprover.new(user_id: user.id, approval_type_id: 1)
          send_email(user.email, "New Approval Request",
          "<p>Hello #{user.username}!</p><p>You have a new request which requires your approval. Please see <a href=\'http://localhost:4200/requests/approvals\'>your requests</a> for more information.</p>"
          ) #to, subject, message
        end

        new_approval.save #save approval so we can get the id since this is disconnected somewhat

        #return the object id
        new_approval.id
      else
        raise 'Cannot create the approval request. The provided request type has no roles with users.'
        #cannot create approval...there has to be approvers
      end
    else

    end
  end

  # remove an existing approval. This is usually done if some kind of error occurs in the process
  def cancel_approval approvalId
    @approval = Approval.find_by_id(approvalId)
    if @approval
      # Email all of the approvers
      @approval.approval_approvers do |approver|
        send_email(approver.user.email, "Approval Cancelled", "<p>Hello #{user.username}!</p><p>A recent approval that was created for you was cancelled and removed. This is likely because there was an error creating the final request.</p>")
      end

      # Get rid of it
      @approval.destroy
    end
  end

  def email_members(subject, message)
    users = User.all #.where("is_member = ?", true)
    users.each do |user|
      send_email(user.email, subject, message) if user.isinrole(0)
    end
  end

  #eventually this goes into a background process
  def email_groups(roleIdArray, subject, message)
    emailsArray = Array.new
    roleIdArray.each do |roleId|
      role = Role.find_by id: roleId
      if role != nil
        #role.users.where("is_member = ?", true).each do |user|
        User.all.each do |user|
          emailsArray << user.email if user.isinrole(roleId) && user.isinrole(0)
          #
        end #loop to get user emails
      end #check to make sure role exists
    end #group loop

    uniqueEmails = emailsArray.uniq{|x| x} #this could give us duplicates...elim them

    #actually send the emails
    uniqueEmails.each do |emaily|
      send_email(emaily, subject, message)
    end
  end

  def send_email(to_in, subject_in, message_in)
    begin
      puts ''
      puts 'Sending email to ' + to_in
      # used for debugging purposes. All emails should be sent with
      message_trimmed = message_in
      message_trimmed = message_in.gsub('localhost:4200', 'my.bendrocorp.com') if ENV["RAILS_ENV"] != nil && ENV["RAILS_ENV"] == 'production'
      # the piece that goes on the end of all of the emails
      outro = "<p><b><strong>Please do not reply to this email.</strong></b><p/><p>Sincerely,</p><p>Kaden Aayhan<br />Assistant to the CEO<br />BendroCorp, Inc.</p><p>Corp Plaza 11, Platform R3Q<br />Crusader, Stanton</p>"
      outro = outro + "<p><small>#{ ENV['RAILS_ENV']}</small></p>"
      outro = outro + "<p>#{Digest::SHA256.hexdigest message_in}</p>" if ENV['RAILS_ENV'] == 'development'

      # the actual email itself
      from = Email.new(email: 'no-reply@bendrocorp.com')
      to = Email.new(email: to_in)
      subject = subject_in
      content = Content.new(type: 'text/html', value: "#{message_trimmed}#{outro}")
      mail = SendGrid::Mail.new(from, subject, to, content) # https://github.com/sendgrid/sendgrid-ruby/issues/67

      queue_email mail.to_json

    rescue SocketError => e
      puts e.message_in
    end
  end

  def queue_email sg_email_json
    # actually send the email or just log the contents
    sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY']) if ENV['SENDGRID_API_KEY'] != nil
    # send the email through SendGrid if the API key is set
    response = sg.client.mail._("send").post(request_body: sg_email_json)  if ENV['SENDGRID_API_KEY'] != nil

    if ENV['SENDGRID_API_KEY'] == nil
      puts
      puts "The email that would have been sent to..."
      puts sg_email_json
      puts
    else
      puts "SendGrid response code:"
      puts response.status_code
      puts
      if response.status_code == 200 || response.status_code == 201 || response.status_code == 202
        return true
      else
        puts response.body
        return false
      end
    end
  end

  private
  def bearer_token
    pattern =  /^(Bearer|Basic|bearer|basic) / #
    header = request.env["HTTP_AUTHORIZATION"] #
    header ||= request.env["HTTP_X_AUTHORIZATION"] #
    header = header.gsub(pattern, '') if header && header.match(pattern)
    return header
  end
end
