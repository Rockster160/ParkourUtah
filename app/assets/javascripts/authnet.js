var ready = function() {
  if ($('.authnet-token').val() == "") {
    $('.authnet-btn').val('Sorry, Authorize.Net is not available at this time.');
    $('.authnet-btn').addClass('disabled');
  }

  $('.authnet-btn').click(function(e) {
    e.preventDefault();
  })
}

$(document).ready(ready);
$(document).on('page:load', ready);
