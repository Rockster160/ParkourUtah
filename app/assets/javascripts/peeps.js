var ready = function() {

  var sortableTablesHelper = function(e, tr) {
    var $originals = tr.children();
    var $helper = tr.clone();
    $helper.children().each(function(index) {
        $(this).width($originals.eq(index).width())
    });
    return $helper;
  };

  function updatePositionNumbers(resource, position_attribute) {
    $('.sortable-row').each(function(e) {
      var path = $(this).children('.sortable-url').html();
      var paths = window.location
      var new_position = e + 1;
      var url = paths.protocol + "//" + paths.host + path;
      var params = {};
      params[resource] = {}
      params[resource][position_attribute] = new_position;
      $.post(url, params);
    });
  };

  $("#instructor-table").sortable({
      helper: sortableTablesHelper,
      items: "tr:not(.not-sortable)",
      stop: function() {updatePositionNumbers("instructor", "instructor_position")}
  }).disableSelection();

  $("#line-item-table").sortable({
      helper: sortableTablesHelper,
      items: "tr:not(.not-sortable)",
      stop: function() {updatePositionNumbers("line_item", "line_item_position")}
  }).disableSelection();

};

$(document).ready(ready);
$(document).on('page:load', ready);
