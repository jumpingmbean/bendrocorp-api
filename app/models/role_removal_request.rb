class RoleRemovalRequest < ApplicationRecord
  belongs_to :user #required field/fk
  belongs_to :role
  belongs_to :approval #required field/fk

  belongs_to :on_behalf_of, :class_name => 'Character', :foreign_key => 'on_behalf_of_id'

  accepts_nested_attributes_for :approval

  def approval_completion #required for approval
    if !self.on_behalf_of.user.roles.delete(self.role)
      error #throw an error :)
    end
  end

  def approval_denied
      #do nothing (nothing needs to be done here)
  end
end
