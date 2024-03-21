class ChangeInvitationFormatInConfig < ActiveRecord::Migration[6.1]
  def up
    add_column :configurations, :invitation_formats, :string, array: true, null: false, default: %w[sms email postal]

    CategoryConfiguration.find_each do |config|
      case config.invitation_format
      when 0
        config.invitation_formats = %w[sms]
      when 1
        config.invitation_formats = %w[email]
      when 2
        config.invitation_formats = %w[sms email]
      when 3
        config.invitation_formats = %w[postal]
      when 4
        config.invitation_formats = []
      end

      config.save!
    end

    remove_column :configurations, :invitation_format
  end

  def down
    add_column :configurations, :invitation_format, :integer

    CategoryConfiguration.find_each do |config|
      case config.invitation_formats
      when ["sms"]
        config.invitation_format = 0
      when ["email"]
        config.invitation_format = 1
      when %w[sms email] || %w[sms email postal]
        config.invitation_format = 2
      when %w[postal]
        config.invitation_format = 3
      when []
        config.invitation_format = 4
      end

      config.save!
    end

    remove_column :configurations, :invitation_formats, :string, array: true, null: false, default: %w[sms email postal]
  end
end
