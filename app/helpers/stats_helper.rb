module StatsHelper
  def options_for_department_select(departments)
    departments.map { |d| ["#{d.number} - #{d.name}", d.id] }
               .unshift(["Tous les départements", "0"])
  end

  def options_for_organisation_select(department)
    department.organisations
              .map { |o| [o.name.to_s, o.id] }
              .unshift(["Toutes les organisations", "0"])
  end

  def exclude_current_month(stat)
    stat&.delete_if { |key, _value| key == Time.zone.now.strftime("%m/%Y") }
  end

  def structure_name_and_department_number(organisation, departement)
    "#{(organisation || department).name} (#{departement.number})"
  end
end
