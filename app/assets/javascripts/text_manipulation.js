var ready = function() {

  $('.restrictNumeric').keypress(function(e) {
    if (e.which >= 48 && e.which <= 57) {
      return e
    } else {
      e.preventDefault();
    }
  });

  $('.formatPhoneNumber').keypress(function(e) {
    var value = $(this).val();
    var add = "";
    if (value.length == 0) { add = "(" }
    if (value.length == 4) { add = ") " }
    if (value.length == 9) { add = "-" }
    if (value.length > 12) { value = value.substring(0, 13) }
    $(this).val(value + add);
  });

  $('.pin-entry').keypress(function(e) {
    var value = $(this).val();
    if (value.length >= 4) {
      $(this).val(value.substring(0, 4));
      e.preventDefault();
    }
  });

  $('.athleteVerify').click(function(e) {
    if ($('.formatPin').val().length != 4) {
      showError('Please input a valid pin.');
      e.preventDefault();
    }
    if ($('.formatPhoneNumber').val().length != 14) {
      showError('Please input a valid phone number.');
      e.preventDefault();
    }
  });
};

$(document).ready(ready);
$(document).on('page:load', ready);
