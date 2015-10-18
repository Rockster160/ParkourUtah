var ready = function() {
  $('.add-athletes-submission').click(function() {
    if ($('.required-checkbox')[0].checked && $('#signed_by').val().length > 0 && $('.athlete-verified').length > 0) {
      $('#reiterate_waiver_modal').modal('show');
    } else {
      $('#error_modal').modal('show');
    }
  });

  $('.open-review-modal').click(function() {
    $('#review-step-4-modal').modal('show');
  })

  $('.populate-waiver-btn').click(function() {
    $('.waiver-athletes').html('');
    $('.athlete-input-info').each(function() {
      var dob = $($(this).find('.formatDOB')[0]).val(),
          pin = $($(this).find('.formatPin')[0]).val(),
          name = $($(this).find('.formatName')[0]).val();
      var pin_is_valid = pin.length == 4,
          dob_is_valid = dob.length == 10,
          name_is_valid = name.length > 0;
      if (pin_is_valid && dob_is_valid && name_is_valid) {
        $('.waiver-athletes').append('<h5 class="warning-text athlete-verified">' + name + '</h5>')
      }
    });
  });

  $('.add-athlete-btn').click(function() {
    var token = generateToken();
    $('.athlete-container').append('<div class="row athlete-input-info"><div class="col-sm-6"><input type="text" name="athlete[' +
    token +
    '][name]" value="" placeholder="Full Name" class="pkut-textbox formatName" /></div><div class="col-sm-6"><input type="tel" name="athlete[' +
    token +
    '][dob]" value="" placeholder="MM/DD/YYYY" class="pkut-textbox sm-textbox formatDOB" /><span class="show-required"><input type="tel" name="athlete[' +
    token +
    '][code]" value="" placeholder="ex:1234" class="pkut-textbox xs-textbox formatPin" /></span> <i class="fa fa-times-circle-o fa-2x kill-athlete"></i></div></div>');
    $(".formatDOB:last").mask("99/99/9999");
    $(".formatPin:last").mask("9999");
  });

  $('.athlete-container').delegate('.kill-athlete', 'click', function(e) {
    $(this).closest('.row').remove();
  });
  $('.athlete-input-info').delegate('.delete-athlete', 'click', function(e) {
    $('.delete-athlete-btn').attr('href', "/delete_athlete/" + $(this).attr('id'));
  });

  var generateToken = function() {
    var alphabet = "abcdefghijklmnopqrstuvwxyz", numbers = "0123456789", token = [];
    var possible_values = alphabet + alphabet.toUpperCase() + numbers;
    for (var i=0;i<10;i++) {
      token.push(possible_values.split('').shuffle()[0])
    }
    return token.join('');
  }
}

numeralStrip = function(str) {
  var num = str.replace(/\D+/g, ''); //Remove non-numerals
  return num;
}

Array.prototype.shuffle = function() {
  var new_array = this, count = this.length;
  for (var i=0;i<(count * 2);i++) {
    var popped_value = new_array.splice(Math.floor(i/2), 1)[0];
    new_array.splice(Math.floor(Math.random() * count), 0, popped_value);
  }
  return new_array
}

$(document).ready(ready);
$(document).on('page:load', ready);
