class Approval < ApplicationRecord
  belongs_to :approval_kind
  has_many :approval_approvers, dependent: :delete_all

  accepts_nested_attributes_for :approval_approvers

  def created_at_ms
    self.created_at.to_f * 1000
  end

  def approval_status
    if !self.approved && !self.denied
      "Awaiting Responses"
    elsif self.approved && !self.denied
      "Approved"
    elsif !self.approved && self.denied
      "Denied"
    else # ie they are both true o_0
      "Out of Range"
    end
  end

  def approval_source
    #this will need to be updated if/when new requests are created
    if self.approval_kind_id == 1 #role_request
      RoleRequest.find_by approval_id: self.id
    elsif self.approval_kind_id == 3
      AwardRequest.find_by approval_id: self.id
    elsif self.approval_kind_id == 6
      EventCertificationRequest.find_by approval_id: self.id
    elsif self.approval_kind_id == 7
      OffenderReportApprovalRequest.find_by approval_id: self.id
    elsif self.approval_kind_id == 11
      OrganizationShipRequest.find_by approval_id: self.id
    elsif self.approval_kind_id == 12
      RoleRemovalRequest.find_by approval_id: self.id
    elsif self.approval_kind_id == 16
      OwnedShipCrewRequest.find_by approval_id: self.id
    elsif self.approval_kind_id == 17
      JobChangeRequest.find_by approval_id: self.id
    elsif self.approval_kind_id == 18
      JobBoardMissionCompletionRequest.find_by approval_id: self.id
    elsif self.approval_kind_id == 19
      JobBoardMissionCreationRequest.find_by approval_id: self.id
    elsif self.approval_kind_id == 20
      AddSystemMapItemRequest.find_by approval_id: self.id
    elsif self.approval_kind_id == 21
      ReportApprovalRequest.find_by approval_id: self.id
    elsif self.approval_kind_id == 22
      PositionChangeRequest.find_by approval_id: self.id
    elsif self.approval_kind_id == 23
      ApplicantApprovalRequest.find_by approval_id: self.id
    end
  end

  def approval_source_character_name
    self.approval_source.user.main_character.full_name
  end

  def approval_source_on_behalf_of
    if defined?(self.approval_source.on_behalf_of)
      self.approval_source.on_behalf_of.full_name
    end
  end

  def approval_workflow
    #this will need to be updated if/when new requests are created
    if self.approval_kind_id == 1 #role_request
      1
    elsif self.approval_kind_id == 3
      1
    elsif self.approval_kind_id == 6
      1
    elsif self.approval_kind_id == 7
      1
    elsif self.approval_kind_id == 11
      1
    elsif self.approval_kind_id == 12
      1
    elsif self.approval_kind_id == 16
      1
    elsif self.approval_kind_id == 17
      1
    elsif self.approval_kind_id == 18
      1
    elsif self.approval_kind_id == 19
      1
    elsif self.approval_kind_id == 20
      1
    elsif self.approval_kind_id == 21
      1
    elsif self.approval_kind_id == 22
      1
    elsif self.approval_kind_id == 23
      2
    end
  end

  def approval_source_requested_item
    #this will need to be updated if/when new requests are created
    if self.approval_kind_id == 1 #role_request
      r = RoleRequest.find_by approval_id: self.id
      "#{r.role.name} (Role)"
    elsif self.approval_kind_id == 3
      e = AwardRequest.find_by approval_id: self.id
      "#{e.award.name} (Award Request)"
    elsif self.approval_kind_id == 6
      e = EventCertificationRequest.find_by approval_id: self.id
      "For event ID ##{e.event.id} #{e.event.name} (Event Certification)"
    elsif self.approval_kind_id == 7
      e = OffenderReportApprovalRequest.find_by approval_id: self.id
      "New Offender Report (Offender Report Approval)"
    elsif self.approval_kind_id == 11
      e = OrganizationShipRequest.find_by approval_id: self.id
      "#{e.owned_ship.title} (Organization Ship)"
    elsif self.approval_kind_id == 12
      e = RoleRemovalRequest.find_by approval_id: self.id
      "#{e.role.name} (Role Removal)"
    elsif self.approval_kind_id == 16
      e = OwnedShipCrewRequest.find_by approval_id: self.id
      "#{e.character.full_name} requesting to join #{e.crew.owned_ship.title} (Crew Request)"
    elsif self.approval_kind_id == 17
      e = OwnedShipCrewRequest.find_by approval_id: self.id
      "#{e.user.main_character.full_name} job change to #{e.job.title} (Job Change Request)"
    elsif self.approval_kind_id == 18
      e = JobBoardMissionCompletionRequest.find_by approval_id: self.id
      "#{e.job_board_mission.title} #(#{e.job_board_mission.id}) (Mission Completion)"
    elsif self.approval_kind_id == 19
      e = JobBoardMissionCreationRequest.find_by approval_id: self.id
      "#{e.job_board_mission.title} #(#{e.job_board_mission.id}) (Mission Creation)"
    elsif self.approval_kind_id == 20
      e = AddSystemMapItemRequest.find_by approval_id: self.id
      "#{e.object_title} (#{e.object_kind}) (System Object Item Creation)"
    elsif self.approval_kind_id == 21
      e = ReportApprovalRequest.find_by approval_id: self.id
      "For report id ##{e.report.id} #{e.report.title} (#{e.report.report_type.title}) (Report Approval)"
    elsif self.approval_kind_id == 22
      e = PositionChangeRequest.find_by approval_id: self.id
      "#{e.character.full_name} to #{e.job.title} (Position Change Request)"
    elsif self.approval_kind_id == 23
      e = ApplicantApprovalRequest.find_by approval_id: self.id
      "Application for #{e.application.character.full_name} (Applicant Approval Request)"
    end
  end

  # used when roles are not used for an approval - directs you to the owner of something (ie a ship <== pretty much the only example at the moment)
  def approval_owner
    if self.approval_kind_id == 16
      e = OwnedShipCrewRequest.find_by approval_id: self.id
      "#{e.character.full_name} requesting to join #{e.crew.owned_ship.title} (Crew Request)"
    end
  end

  def approval_link
    if self.approval_kind_id == 6
      e = EventCertificationRequest.find_by approval_id: self.id
      "/events/#{e.event.id}"
    elsif self.approval_kind_id == 7
      e = OffenderReportApprovalRequest.find_by approval_id: self.id
      "/offender-reports/report-#{e.offender_report.id}"
    elsif self.approval_kind_id == 18
      e = JobBoardMissionCompletionRequest.find_by approval_id: self.id
      puts
      puts self.id
      puts e.inspect
      "/job-board/#{e.job_board_mission.id}"
    elsif self.approval_kind_id == 21
      e = ReportApprovalRequest.find_by approval_id: self.id
      "/reports/#{e.report.id}" # url_title_string
    elsif self.approval_kind_id == 23
      e = ApplicantApprovalRequest.find_by approval_id: self.id
      puts 'debug'
      puts self.id
      puts e.inspect
      "/profiles/#{e.application.character.first_name.downcase}-#{e.application.character.last_name.downcase}-#{e.application.character.id}"
    end
  end
end
