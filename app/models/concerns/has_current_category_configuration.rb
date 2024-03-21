module HasCurrentCategoryConfiguration
  def current_category_configuration
    @current_category_configuration ||= category_configurations.find { |c| c.motif_category == motif_category }
  end
end
