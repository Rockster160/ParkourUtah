var ready = function() {

  var sortableTablesHelper = function(e, tr) {
    var $originals = tr.children();
    var $helper = tr.clone();
    $helper.children().each(function(index) {
        $(this).width($originals.eq(index).width())
    });
    return $helper;
  };

  function updatePositionNumbers(resource, position_attribute, method) {
    $('.sortable-row').each(function(e) {
      var path = $(this).children('.sortable-url').html();
      var paths = window.location
      var new_position = e + 1;
      var url = paths.protocol + "//" + paths.host + path;
      var params = {};
      params[resource] = {}
      params[resource][position_attribute] = new_position;
      $.ajax({ url: url, method: method, data: params, headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') } });
    });
  };

  $("#instructor-table").sortable({
      helper: sortableTablesHelper,
      items: "tr:not(.not-sortable)",
      stop: function() {updatePositionNumbers("instructor", "instructor_position", "POST")}
  }).disableSelection();

  $("#line-item-table").sortable({
      helper: sortableTablesHelper,
      items: "tr:not(.not-sortable)",
      stop: function() {updatePositionNumbers("line_item", "line_item_position", "PUT")}
  }).disableSelection();

};

$(document).ready(ready);
