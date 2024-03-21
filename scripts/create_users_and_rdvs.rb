# rails runner scripts/create_users_and_rdvs.rb
# Ce script est hors seeds car les records créés ainsi ne sont pas liés à rdv-solidarités
# Il crée 350 bénéficiaires sur un an, un par jour
# Pour chacun, un follow_up d'orientation, une invitation et un rdv est créé
# 90% des rdvs sont marqués comme honorés, 10% comme noshow ; les délais de rdv sont aléatoires
# Peut être utile pour tester des fonctionnalités, par exemple les statistiques

date = 1.year.ago
350.times do |i|
  user = User.create!(
    created_at: date,
    updated_at: date,
    first_name: "first_name_#{i}",
    last_name: "last_name_#{i}",
    email: "email_#{i}@test.com",
    phone_number: (format "+336%08d", i),
    affiliation_number: "123#{i}",
    role: "demandeur",
    address: "8 rue du test 75001 Paris",
    rights_opening_date: date,
    title: "monsieur",
    department_id: 1
  )
  user.organisation_ids = [1]
  user.save!
  rc = FollowUp.create!(
    context: "rsa_orientation",
    created_at: date,
    updated_at: date,
    user_id: user.id
  )
  invitation = Invitation.new(
    format: "sms",
    user_id: user.id,
    created_at: date,
    updated_at: date,
    help_phone_number: "0102030405",
    rdv_solidarites_token: "sometoken#{i}",
    link: "http://www.test.com/test&id=#{i}",
    department_id: 1,
    follow_up_id: rc.id
  )
  invitation.organisation_ids = [1]
  invitation.save!
  rdv = Rdv.new(
    starts_at: date + Random.new.rand(7).days,
    duration_in_min: 30,
    created_at: date,
    updated_at: date,
    rdv_solidarites_motif_id: 18,
    rdv_solidarites_lieu_id: 6,
    created_by: "user",
    organisation_id: 1,
    rdv_solidarites_rdv_id: "1500#{i}".to_i
  )
  rdv.status = i.to_s.ends_with?("1") ? "noshow" : "seen"
  rdv.user_ids = [user.id]
  rdv.follow_up_ids = [rc.id]
  rdv.save!
  date += 1.day
end
