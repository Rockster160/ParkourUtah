var ready = function() {
  var url = window.location.pathname.split("/")[1];
  if (url == "class" || url == "password" || url == "secret") {
    $('.navbar').hide();

    $('.secret-input-field').val("");
    $('.secret-input-btn').click(function(e) {
      e.preventDefault();
      var $value = $(this).html();
      append_to_field($value);
    });

    function append_to_field($value) {
      var field_value = $('.secret-input-field').val();
      if (field_value.length == 6 && $value != "&lt;") { $value = ""; }
      var old_value = field_value;

      if ($value == "&lt;") {
        var lose = 1
        var new_value = old_value.substring(0, old_value.length - lose);
      } else {
        var add = ""
        var new_value = field_value + add + $value;
      };
      $('.secret-input-field').val(new_value);
    }
  }

  $('.falsify-image-click').click(function() {
    $('.upload-image-btn').click();
  });
  $('.upload-image-btn').change(function(e) {
    if ($(this).val() == "") {
      $('.upload-image-icon').html("Click here to take a photo");
      $('.upload-image-icon').css("font-size", "2em");
    } else {
      $('.upload-image-icon').html("√");
      $('.upload-image-icon').css("font-size", "5em");
    };
  });

  $('.no-zoom').bind('touchstart', function(e) {
    e.preventDefault();
  });
  $('.no-zoom').bind('touchend', function(e) {
    e.preventDefault();
    var $value = $(this).html();
    append_to_field($value);
  });
}

$(document).ready(ready);
$(document).on('page:load', ready);
