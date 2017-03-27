flashRemoverTimer = null;

function resetFlashTimer() {
  clearTimeout(flashRemoverTimer);
  flashRemoverTimer = setTimeout(function() {
    dismissFlash()
  }, 8000)
}

dismissFlash = function(exclude_announcement) {
  exclude_announcement = exclude_announcement || false
  if (exclude_announcement) {
    $('body .flash-banner:not(.flash-announcement)').animate({'top': '-500px'}, 500, function() {
      $(this).remove()
    })
  } else {
    $('body .flash-banner').animate({'top': '-500px'}, 500, function() {
      $(this).remove()
    })
  }
}
$(document).on('click touchstart', '.dismiss-flash', dismissFlash)
$(window).scroll(function() { dismissFlash(true) })

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
  resetFlashTimer();
}

addFlashNotice = function(message) {
  addFlash(message, 'notice');
}

addFlashAlert = function(message) {
  addFlash(message, 'alert');
}

$(document).ready(function() {
  if ($('.flash-banner:not(.flash-announcement)').length > 0) { resetFlashTimer(); }

  if ($('.flash-banner.flash-announcement').length > 0 && $('.inline-flash.flash-announcement').length == 0) {
    clearTimeout(flashRemoverTimer);
    $('.flash-announcement').css({top: '-' + ($('.flash-announcement').outerHeight() + 50) + 'px'})

    setTimeout(function() {
      dismissFlash(true);

      $('body .flash-announcement').animate({'top': '70px'}, 500, function() {
        setTimeout(function() {
          $.post("/announcements/view");
        }, 2000)
      })

    }, 2000)

  }
})
