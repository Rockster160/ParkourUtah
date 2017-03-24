module ParamsHelper

  def sort_order
    params[:order] == "desc" ? "desc" : "asc"
  end

  def toggled_sort_order
    params[:order] == "desc" ? "asc" : "desc"
  end

  def sortable(link_text, param_string, options={})
    current_order = sort_order
    default_order = 'asc'
    if params[:sort] == param_string
      current_order = toggled_sort_order
      default_order = toggled_sort_order
    end
    hash_location = (options[:additional_params] || {}).merge({ sort: param_string, order: default_order })
    link_to "#{link_text} #{default_order}", hash_location, class: "pkut-btn #{options[:additional_classes]}"
  end

  def groupable(link_text, param_string, options={})
    hash_location = (options[:additional_params] || {}).merge({ group: param_string })
    link_to "#{link_text}", hash_location, class: "pkut-btn #{options[:additional_classes]}"
  end

  def toggleable(link_text, param_string, options={})
    current_toggle = params[param_string] == "hide" ? params[param_string] : "show"
    toggled_toggle = current_toggle == "hide" ? "show" : "hide"
    hash_location = (options[:additional_params] || {}).merge({ param_string => toggled_toggle })
    link_to "#{toggled_toggle.capitalize} #{link_text}", hash_location, class: "pkut-btn #{options[:additional_classes]}"
  end

end
