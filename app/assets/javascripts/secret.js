var ready = function() {
  if (window.location.href.split('/').pop() == "secret") {
    $('.navbar').hide();

    $('.secret-input-field').val("");
    $('.secret-input-btn').click(function(e) {
      e.preventDefault();
      var $value = $(this).html();
      var old_value = $('.secret-input-field').val();
      if ($value == "&lt;") {
        var new_value = old_value.substring(0, old_value.length - 1);
      } else {
        var new_value = $('.secret-input-field').val() + $value;
      };
      $('.secret-input-field').val(new_value);

      (function($) {
        var IS_IOS = /iphone|ipad/i.test(navigator.userAgent);
        $.fn.nodoubletapzoom = function() {
          if (IS_IOS)
            $(this).bind('touchstart', function preventZoom(e) {
              var t2 = e.timeStamp
              , t1 = $(this).data('lastTouch') || t2
              , dt = t2 - t1
              , fingers = e.originalEvent.touches.length;
              $(this).data('lastTouch', t2);
              if (!dt || dt > 500 || fingers > 1) return; // not double-tap

                e.preventDefault(); // double tap - prevent the zoom
                // also synthesize click events we just swallowed up
                $(this).trigger('click').trigger('click');
              });
            };
          })(jQuery);
    });
    $('.no-zoom').nodoubletapzoom();
  }
}

$(document).ready(ready);
$(document).on('page:load', ready);
