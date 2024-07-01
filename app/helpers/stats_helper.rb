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
    exclude_months(stat, [Time.zone.now.strftime("%m/%Y")])
  end

  def exclude_current_and_previous_month(stat)
    exclude_months(stat, [1.month.ago.strftime("%m/%Y"), Time.zone.now.strftime("%m/%Y")])
  end

  def exclude_months(stat, months)
    stat&.delete_if { |key, _value| months.include?(key) }
  end
end
