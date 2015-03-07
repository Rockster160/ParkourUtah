var ready = function() {
  if ($('.authnet-token').val() == "") {
    $('.authnet-btn').val('Sorry, Authorize.Net is not available at this time.');
  }
}

$(document).ready(ready);
$(document).on('page:load', ready);
