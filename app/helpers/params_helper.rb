module ParamsHelper

  def sort_order
    params[:order] == "desc" ? "desc" : "asc"
  end

  def toggled_sort_order
    params[:order] == "desc" ? "asc" : "desc"
  end

  def sortable(link_text, param_string, options={})
    if params[:sort] == param_string
      sorted_class = "sorted sortable-#{toggled_sort_order}"
      default_order = toggled_sort_order
    end
    link_to link_text, { sort: param_string, order: default_order || "asc" }.merge(options[:additional_params] || {}), class: "sortable #{sorted_class} #{options[:class]}"
  end

end
