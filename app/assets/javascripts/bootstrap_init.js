jQuery(function() {
  $("a[rel~=popover], .has-popover").popover();
  $("a[rel~=tooltip], .has-tooltip").tooltip();
});

$(document).ready(function() {
  $("[data-modal]").click(function() {
    $($(this).attr("data-modal")).modal("show")
  })
})
