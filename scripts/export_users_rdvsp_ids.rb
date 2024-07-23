#!/usr/bin/env ruby

require "json"
require_relative "../config/environment"

# .active n'est pas suffisant car vérifie uniquement le champ deleted_at
# Or on a des usagers qui n'ont pas de deleted_at et qui n'ont pas de rdv_solidarites_user_id Pourquoi ?
# Il faudrait ajouter d'autres scopes si nécessaire
# On a aussi 30 users avec un rdv_solidarites_user_id mais qui n'ont pas d'organisation en prod ? (on les skip ligne 13)

users_data = User.active.where.not(rdv_solidarites_user_id: nil).includes(:organisations).map do |user|
  rdv_solidarites_organisation_ids = user.organisations.pluck(:rdv_solidarites_organisation_id)
  next if rdv_solidarites_organisation_ids.empty?

  {
    rdv_solidarites_user_id: user.rdv_solidarites_user_id,
    rdv_solidarites_organisation_ids: rdv_solidarites_organisation_ids
  }
end.compact

json_data = JSON.pretty_generate(users_data)
file_path = Rails.root.join("rdvsp_users_ids.json")
File.write(file_path, json_data)

puts "Le fichier JSON a été généré et sauvegardé à l'emplacement suivant : #{file_path}"
