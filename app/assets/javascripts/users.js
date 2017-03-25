$(document).ready(function() {

  if ($(".user-dashboard-page").length > 0) {
    if (window.location.hash.length > 0) {
      $(window.location.hash + "-tab").prop("checked", true);
    }

    $("[data-tab-target]").click(function(e) {
      e.preventDefault();
      var hash_value = $("[data-tab-target]").attr("data-tab-target");
      window.location.hash = hash_value;
      $("#" + hash_value + "-tab").prop("checked", true);
      return false;
    })

    $(".user-dashboard-page .tab").click(function() {
      window.location.hash = $(this).parents("label").attr("id").substring(6);
    })
  }

})
