var ready = function() {
  var url = window.location.pathname;
  if (url == "/athlete" || url == "/password") {
    $('.navbar').hide();

    $('.secret-input-field').val("");
    $('.secret-input-btn').click(function(e) {
      e.preventDefault();
      var $value = $(this).html();
      append_to_field($value);
    });

    $('.no-zoom').bind('touchstart', function(e) {
      e.preventDefault();
    });
    $('.no-zoom').bind('touchend', function(e) {
      e.preventDefault();
      var $value = $(this).html();
      append_to_field($value);
    })

    function append_to_field($value) {
      var field_value = $('.secret-input-field').val();
      if (field_value.length == 4 && $value != "&lt;") { $value = ""; }
      // if (field_value.length == 9 && $value != "&lt;") { $value = ""; }
      var old_value = field_value;

      if ($value == "&lt;") {
        var lose = 1
        // if (field_value.length == 6) { lose = 2; }
        var new_value = old_value.substring(0, old_value.length - lose);
      } else {
        var add = ""
        // if (field_value.length == 4) { add = "-"; }
        var new_value = field_value + add + $value;
      };
      $('.secret-input-field').val(new_value);
    }
  }
}

$(document).ready(ready);
$(document).on('page:load', ready);
