module NavigationHelper
  def structure_id_param
    department_level? ? { department_id: current_department_id } : { organisation_id: current_organisation_id }
  end

  #
  # Will catch routes methods calls containing "structure"
  #
  # When method ends with "_with_structure" => it will add the current structure id as a query param
  # When method contains "structure"        => it will replace structure with the current structure name
  #
  # Example : current structure is a Department with id 1
  #
  # structure_foo_path will generate a path scoped to the current structure
  #        executes => department_foo_path(department_id: 1)
  #        returns  => /departments/1/foo
  #
  # foo_path_with_structure will generate an unscoped path with the current structure id as a query parameter
  #       executes => foo_path(department_id: 1)
  #       returns  => /foo?department_id=1
  #
  def method_missing(method_name, params = {}, additional_params = {})
    return super unless method_name.to_s.match(/^(?=.*structure)(?=.*(path|url))/)

    params = { id: params } if params.is_a?(Integer)
    params_with_structure = { **params, **structure_id_param, **additional_params }
    route_name = method_name.to_s.gsub("_with_structure", "").gsub("structure", current_structure_type)

    send(route_name, params_with_structure)
  end

  def respond_to_missing?(method_name, include_private = false)
    method_name.to_s.match(/^(?=.*structure)(?=.*(path|url))/) || super
  end
end
