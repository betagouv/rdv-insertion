# Preview all emails at http://localhost:3000/rails/mailers/invitation
class InvitationPreview < ActionMailer::Preview
  def first_invitation
    InvitationMailer.first_invitation(Invitation.last, Applicant.last)
  end
end
