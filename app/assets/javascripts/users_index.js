$(document).ready(function() {

  $("#user_index_search_field").searchable({
    getOptionsFromUrl: $("#user_index_search_field").attr("data-index-url"),
    paramKey: "by_fuzzy_text",
    arrayOfOptionsFromUrlResponse: function(data) {
      return data;
    },
    valueFromOption: function(option) {
      return option.id;
    },
    templateFromOption: function(option) {
      var athletes = '';
      $(option.athletes).each(function(e) {
        athletes += ('<span class="dropdown-athlete">' + this.full_name.substring(0, 30) + ' - ' + this.fast_pass_id + '</span><br/>')
      })
      return '<div class="dropdown-option"><span class="dropdown-email">' +
      option.email +
      '</span><span class="dropdown-id">' +
      option.id +
      '</span><br/>' +
      athletes
      '</div>';
    },
    optionSelected: function(selected_value) {
      window.location.href = "/admin/users/" + selected_value;
    }
  });

  $("#athlete_index_search_field").searchable({
    getOptionsFromUrl: $("#athlete_index_search_field").attr("data-index-url"),
    paramKey: "by_fuzzy_text",
    arrayOfOptionsFromUrlResponse: function(data) {
      return data;
    },
    valueFromOption: function(option) {
      return option.id;
    },
    templateFromOption: function(option) {
      return '<div class="dropdown-option">' + option.id + ' - ' + option.full_name + '</div>';
    },
    optionSelected: function(field, option, selected_value) {
      $('#athlete_index_search_field').val($(option).html());
    }
  });

  $('.searchable-dropdown').searchableFromSelect({
    additional_classes: "pkut-textbox"
  })

})
