module HasParticipationsToRdvs
  extend ActiveSupport::Concern

  def last_created_participation
    participations.max_by(&:created_at)
  end

  def seen_participations
    participations.to_a.select(&:seen?)
  end

  def seen_rdvs
    seen_participations.map(&:rdv).uniq
  end

  def first_seen_rdv
    seen_rdvs.min_by(&:starts_at)
  end

  def first_seen_rdv_starts_at
    first_seen_rdv&.starts_at
  end

  def first_rdv_creation_date
    rdvs.min_by(&:created_at).created_at
  end

  def first_participation_creation_date
    participations.min_by(&:created_at).created_at
  end

  def last_rdv
    rdvs.to_a.max_by(&:starts_at)
  end

  def last_rdv_starts_at
    last_rdv&.starts_at
  end

  def rdvs?
    !rdvs.empty?
  end

  def rdv_seen_delay_in_days
    return if first_seen_rdv_starts_at.blank?

    first_seen_rdv_starts_at.to_datetime.mjd - created_at.to_datetime.mjd
  end
end
