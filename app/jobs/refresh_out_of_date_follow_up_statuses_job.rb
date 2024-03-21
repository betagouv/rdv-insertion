class RefreshOutOfDateFollowUpStatusesJob < ApplicationJob
  def perform
    @follow_up_ids = []
    FollowUp.find_each do |follow_up|
      @follow_up_ids << follow_up.id if follow_up.status != follow_up.set_status.to_s
    end

    notify_on_mattermost if production_env?
    RefreshFollowUpStatusesJob.perform_async(@follow_up_ids)
  end

  private

  def notify_on_mattermost
    MattermostClient.send_to_notif_channel(
      "✨ Rafraîchit les statuts pour: #{@follow_up_ids}"
    )
  end
end
