#!/usr/bin/env ruby

require "json"
require_relative "../config/environment"

organisations_data = Organisation.all.map do |organisation|
  {
    rdv_solidarites_organisation_id: organisation.rdv_solidarites_organisation_id
  }
end

json_data = JSON.pretty_generate(organisations_data)
file_path = Rails.root.join("rdvsp_organisations_ids.json")
File.write(file_path, json_data)

puts "Le fichier JSON a été généré et sauvegardé à l'emplacement suivant : #{file_path}"
