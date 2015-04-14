var ready = function() {
  $('.add-athlete-btn').click(function() {
    $('.athletes-holder').append('<input type="text" class="fancy-textbox" placeholder="Sam Smith" name="athletes[]" required="true" autocomplete="off"/><br/>');
  });
}

$(document).ready(ready);
$(document).on('page:load', ready);
