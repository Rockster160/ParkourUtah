var ready = function() {

  $('.restrictNumeric').keypress(function(e) {
    if (e.which >= 48 && e.which <= 57) {
      return e
    } else {
      e.preventDefault();
    }
  });

  $(function() {
    $('.formatPhoneNumber').mask("(999) 999-9999");
    $('.formatPin').mask("9999");
    $('.formatDOB').mask("99/99/9999");
  });

  $(".disableEnterSubmit").on("keypress", function (e) {
    if (e.keyCode == 13) {
      return false;
    }
  });
};

$(document).ready(ready);
$(document).on('page:load', ready);
