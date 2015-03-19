var ready = function() {

  $('.restrictNumeric').keypress(function(e) {
    if (e.which >= 48 && e.which <= 57) {
      return e
    } else {
      e.preventDefault();
    }
  });

  $('.formatPhoneNumber').keypress(function(e) {
    formatPhone($(this));
    if (!(e.which >= 48 && e.which <= 57)) {e.preventDefault()};
    if ($(this).val().length > 13) { $(this).val($(this).val().substring(0, 13)) }
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
      e.preventDefault();
      showError('Please input a valid pin.');
    }
    if ($('#dependent_emergency_contact').val().length != 14) {
      e.preventDefault();
      showError('Please input a valid phone number.');
    }
  });

  $('.waiverVerify').click(function(e) {
    // e.preventDefault();
    // showError('Verify that all fields are completed and accepted.');
  });

  $('.formatPhoneNumber').each(function() {
    formatPhone($(this));
  })
};

var formatPhone = function(field) {
  var value = field.val().replace( /\D+/g, '');
  if (value.length > 0) {
    value = "("  + value
  }
  if (value.length > 4) {
    value = value.substr(0, 4) + ") "  + value.substr(4)
  }
  if (value.length > 9) {
    value = value.substr(0, 9) + "-"  + value.substr(9)
  }
  if (value.length > 13) { value = value.substring(0, 14) }
  field.val(value);
};

$(document).ready(ready);
$(document).on('page:load', ready);
