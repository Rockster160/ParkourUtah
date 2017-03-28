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
    $('body .flash-banner:not(.flash-announcement)').animate({'right': '-350px'}, 500, function() {
      $(this).remove()
    })
  } else {
    $('body .flash-banner').animate({'right': '-350px'}, 500, function() {
      $(this).remove()
    })
  }
}
$(document).on('click touchstart', '.dismiss-flash', function() {
  if ($(this).parents('.flash-banner').hasClass("flash-announcement")) {
    dismissFlash()
  } else {
    dismissFlash(true)
  }
})
$(window).scroll(function() { dismissFlash(true) })

addFlash = function(message, type) {
  $.get('/flash_message', {message: message, flash_type: type}, function(data) {
    dismissFlash();
    var flashMessageDiv = $(data);
    flashMessageDiv.addClass('hidden');
    $('body').append(flashMessageDiv);
    flashMessageDiv.css({'right': '-350px'});
    flashMessageDiv.removeClass('hidden');
    flashMessageDiv.animate({'right': '20px'}, 400);
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
    $('.flash-announcement').css({right: '-350px'});

    setTimeout(function() {
      dismissFlash(true);
      $('body .flash-announcement').animate({'right': '20px'}, 500);
    }, 2000)

  }
})
