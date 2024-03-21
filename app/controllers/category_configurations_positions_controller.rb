class CategoryConfigurationsPositionsController < ApplicationController
  def update
    params.require(:category_configuration_ids_and_positions).each do |_configuration_id_and_position|
      # We update all category_configurations with similar motif_category because updating only the given one would
      # break department level ordering (since we have multiple category_configurations with the same motif_category)
      category_configurations
        .where(motif_category: category_configurations.find(category_configuration_id_and_position[:id]).motif_category)
        .update_all(column_to_update => category_configuration_id_and_position[:position].to_i)
    end

    head :ok
  end

  private

  def column_to_update
    department_level? ? :department_position : :position
  end

  def category_configurations
    @category_configurations ||= current_structure.category_configurations
                                                  .includes([:motif_category])
                                                  .order(position: :asc)
  end
end
