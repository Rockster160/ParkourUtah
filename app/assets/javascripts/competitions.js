$(document).ready(function() {
  if ($(".competition-wrapper").length > 0) {
    $("#selected-athlete").change(function() {
      $(".waiver-athletes").text($(this).find("option:selected").text())
      if ($(this).val() != "") {
        $("#form-submit").removeClass("disabled")
      } else {
        $("#form-submit").addClass("disabled")
      }
    })

    $("#signed").change(function() {
      if ($(this).is(":checked")) {
        $("#waiver-submit").removeClass("disabled")
      } else {
        $("#waiver-submit").addClass("disabled")
      }
    })
  }

  $(".tableSorter").tableSort()

  $("#competition_judgement_category_score").change(function() {
    $("#category_score").text($(this).val() || "00")
  }).change()
  $("#competition_judgement_overall_impression").change(function() {
    $("#overall_impression").text($(this).val() || "00")
  }).change()
})
