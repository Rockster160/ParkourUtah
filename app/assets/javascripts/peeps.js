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
      var url = $(this).children('.sortable-url').html() + ".json", new_position = e + 1;
      var params = {};
      params[resource] = {}
      params[resource][position_attribute] = new_position;
      params["_method"] = "put";
      $.post(url, params);
    });
  };

  $("#instructor-table").sortable({
      helper: sortableTablesHelper,
      items: "tr:not(.not-sortable)",
      stop: function() {updatePositionNumbers("instructor", "instructor_position")}
  }).disableSelection();

// For store items
  // $("#survey-question-answers-table").sortable({
  //     helper: sortableTablesHelper,
  //     items: "tr:not(.not-sortable)",
  //     stop: function() {updatePositionNumbers("survey_question_answer", "answer_position_number")}
  // }).disableSelection();

};

$(document).ready(ready);
$(document).on('page:load', ready);
