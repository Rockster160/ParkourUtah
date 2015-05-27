var ready = function() {

  $(':submit').click(function(e) {
    var form = $(this).closest('form')[0];
    var invalid = [];
    if ($(this).hasClass('delete-user-btn')) {
      var $field = $(form).find('.delete-user-field:first');
      if ($field.val() == "DELETE") {

      } else {
        e.preventDefault;
        return false
      }
    }
    $(form).find('.customRequired').each(function(e) {
      if ($(this).attr('type') == "checkbox") {
        if (!(this.checked)) {
          invalid.push(false);
          $(this).css({"border-color": "red"})
        }
      } else {
        if (!($(this).val().length > 0)) {
          invalid.push(false);
          $(this).css({"border-color": "red"})
        }
      }
    });
    if (invalid.length > 0) {
      $('.modal').modal('hide');
      if (invalid.length == 1) {$('#number_of_errors_container').html("field.")}
      if (invalid.length > 1) {$('#number_of_errors_container').html(invalid.length + " fields.")}
      $('#incomplete_error_modal').modal('show');
      e.preventDefault;
      return false
    }
  })

  $('.formatPin, .formatDOB, .formatPhoneNumber').keypress(function(e) {
    $(this).attr('title', "Please use numeric digits only.");
    $(this).data('toggle', 'tooltip');
    $(this).data('placement', 'top');
    $(this).data('trigger', 'manual');
    if (e.which >= 48 && e.which <= 57) {
      $(this).tooltip('hide');
      return e
    } else {
      $(this).tooltip('show');
      e.preventDefault();
    }
  });
  $('.formatPin, .formatDOB, .formatPhoneNumber').focusout(function() {
    $(this).tooltip('hide');
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
