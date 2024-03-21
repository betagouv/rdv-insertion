module FollowUps
  class Close < BaseService
    def initialize(follow_up:)
      @follow_up = follow_up
    end

    def call
      FollowUp.transaction do
        @follow_up.closed_at = Time.zone.now
        save_record!(@follow_up)
        @follow_up.invalidate_invitations
      end
    end
  end
end
