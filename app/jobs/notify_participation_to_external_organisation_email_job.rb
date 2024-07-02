class NotifyParticipationToExternalOrganisationEmailJob < ApplicationJob
  def perform(participation_id, event)
    @participation = Participation.find(participation_id)
    @category_configuration = @participation.category_configurations.find_by!(
      motif_category_id: @participation.follow_up.motif_category_id
    )
    @event = event

    return if !@category_configuration.notify_rdv_changes? || already_notified?

    OrganisationMailer.notify_rdv_changes(
      to: @category_configuration.notify_rdv_changes_email,
      organisation: @participation.organisation,
      participation: @participation,
      event:
    ).deliver_now
  end

  private

  def already_notified?
    cache_key = "notify_rdv_changes_#{@participation.id}_#{@event}"
    return true if Rails.cache.read(cache_key)

    Rails.cache.write(cache_key, true, expires_in: 1.hour)
    false
  end
end
