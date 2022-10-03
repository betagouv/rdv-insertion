class AddAttributesToNotifications < ActiveRecord::Migration[7.0]
  def change
    add_column :notifications, :format, :integer
    add_column :notifications, :convocation, :boolean, default: false
    add_reference :notifications, :rdv, foreign_key: true
    up_only do
      # linking to rdvs
      Notification.find_each do |notification|
        if notification.applicant.rdvs.empty?
          # No need to keep such notifications
          notification.destroy!
        else
          notification.update!(
            rdv_id: notification.applicant.rdvs.first.id,
            convocation: notification.event == "rdv_created"
          )
        end
      end
    end
  end
end
