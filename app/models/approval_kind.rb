class ApprovalKind < ApplicationRecord
  has_many :approver_roles
  has_many :roles, through: :approver_roles
end
