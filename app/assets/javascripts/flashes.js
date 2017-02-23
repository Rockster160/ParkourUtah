dismissFlash = function() {
  $('body .flash-banner').animate({'top': '-500px'}, 500, function() {
    $(this).remove()
  })
}
$(document).on('click touchstart', '.dismiss-flash', dismissFlash)
$(window).scroll(dismissFlash)

addFlash = function(message, type) {
  $.get('/flash_message', {message: message, flash_type: type}, function(data) {
    dismissFlash();
    var flashMessageDiv = $(data);
    flashMessageDiv.addClass('hidden');
    $('body').append(flashMessageDiv);
    flashMessageDiv.css({'top': '-500px'});
    flashMessageDiv.removeClass('hidden');
    flashMessageDiv.animate({'top': '70px'}, 400);
  })
}

addFlashNotice = function(message) {
  addFlash(message, 'notice')
}

addFlashAlert = function(message) {
  addFlash(message, 'alert')
}
