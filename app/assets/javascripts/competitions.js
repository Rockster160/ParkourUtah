$(document).ready(function() {
  if ($(".competition-wrapper").length > 0) {
    $("#competitor_athlete_id").change(function() {
      var selected = $(this).find("option:selected")
      $(".waiver-athletes").text(selected.text())

      if ($(this).val() != "") {
        $("#form-submit").removeClass("disabled")
      } else {
        $("#form-submit").addClass("disabled")
      }

      hideElement($("[data-reveal]"))
      revealElement($("[data-reveal=" + selected.attr("data-age-group") + "]"))
    })

    $("#signed").change(function() {
      if ($(this).is(":checked")) {
        $("#waiver-submit").removeClass("disabled")
      } else {
        $("#waiver-submit").addClass("disabled")
      }
    })

    hideElement($("[data-reveal]"))
  }


  $(".tableSorter").tableSort()

  $("#competition_judgement_category_score").change(function() {
    $("#category_score").text($(this).val() || "00")
  }).change()
  $("#competition_judgement_overall_impression").change(function() {
    $("#overall_impression").text($(this).val() || "00")
  }).change()
})
