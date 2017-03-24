$(document).ready(function() {

  $("#user_index_search_field").searchable({
    getOptionsFromUrl: $("#user_index_search_field").attr("data-index-url"),
    paramKey: "by_fuzzy_text",
    arrayOfOptionsFromUrlResponse: function(data) {
      return data;
    },
    templateFromOption: function(user) {
      var athletes = '';
      $(user.athletes).each(function(e) {
        athletes += ('<span class="dropdown-athlete">' + this.full_name.substring(0, 30) + ' - ' + this.fast_pass_id + '</span><br/>')
      })
      return '<div class="dropdown-option"><span class="dropdown-email">' +
      user.email +
      '</span><span class="dropdown-id">' +
      user.id +
      '</span><br/>' +
      athletes
      '</div>';
    }
  }).on("searchable:selected", function(evt, user) {
    window.location.href = "/admin/users/" + user.id;
  });

  $("#athlete_index_search_field").searchable({
    getOptionsFromUrl: $("#athlete_index_search_field").attr("data-index-url"),
    paramKey: "by_fuzzy_text",
    arrayOfOptionsFromUrlResponse: function(data) {
      return data;
    },
    templateFromOption: function(option) {
      return '<div class="dropdown-option">' + option.id + ' - ' + option.full_name + '</div>';
    }
  }).on("searchable:selected", function(evt, athlete) {
    $('#athlete_index_search_field').val(athlete.id + ' - ' + athlete.full_name);
  });

  // $('.searchable-dropdown').searchableFromSelect({
  //   additional_classes: "pkut-textbox"
  // })

})
