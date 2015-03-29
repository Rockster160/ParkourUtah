var ready = function() {
  if ($('.authnet-token').val() == "") {
    $('.authnet-btn').val('Sorry, Authorize.Net is down.');
    $('.authnet-btn').addClass('disabled');
  }

  $('.authnet-btn').click(function(e) {
    if ($(this).hasClass('disabled')) {
      e.preventDefault();
    }
  })
}

$(document).ready(ready);
$(document).on('page:load', ready);
