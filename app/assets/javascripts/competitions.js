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

    // $("#waiver-submit").click(function() {
    //   if ($(this).hasClass("disabled")) { return }
    //   // $("form").submit()
    // })

  }
})
