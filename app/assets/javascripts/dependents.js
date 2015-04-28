var ready = function() {
  $('.add-athlete-btn').click(function() {
    var token = generateToken();
    $('.athletes-holder').append('<label>Athlete\'s full name</label></br><input type="text" class="pkut-textbox" name="athletes[' +
    token +
    '][name]" placeholder="Sam Smith" required="true", autocomplete="off"/><br/><label>Athlete\'s Birthdate</label></br><input type="text" class="pkut-textbox maskDOB" name="athletes[' +
    token +
    '][dob]" placeholder="dd/mm/yyyy" required="true", autocomplete="off"/><br/>');
    $(".maskDOB:last").mask("99/99/9999");
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
