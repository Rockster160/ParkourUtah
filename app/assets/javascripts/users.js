$(document).ready(function() {

  if ($(".user-dashboard-page").length > 0) {
    // Hash-based tab targeting: /account#subscriptions
    if (window.location.hash.length > 0) {
      $(window.location.hash + "-tab").prop("checked", true);
    }
    // Query-string tab targeting: /account?tab=subscriptions (survives
    // sign-in redirects that strip URL fragments).
    var tabParam = new URLSearchParams(window.location.search).get("tab");
    if (tabParam) {
      $("#" + tabParam + "-tab").prop("checked", true);
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
