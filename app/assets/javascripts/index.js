var ready = function() {

  if (window.location.pathname == "/") {
    $('.full-site-container').css('background','none');
    /* smooth scrolling for scroll to top */
    $('.scroll-link').click(function(e){
      e.preventDefault();
      $href = $(e.target.hash).offset().top;
      $('body,html').animate({scrollTop:$($href)},500);
    });
    /* Remove buffer for Navbar. */
    $('.navbar-offset').hide();
    /* highlight the top nav as scrolling occurs */
    $('body').scroll(function() {
      if (inViewport($('.header-container'))) {
        if ($('.navbar-fixed-top').hasClass('affix')) {
          $('.navbar-fixed-top').removeClass('affix');
        }
      } else {
        if (!($('.navbar-fixed-top').hasClass('affix'))) {
          $('.navbar-fixed-top').addClass('affix');
        }
      }
    })
    $('.navbar-fixed-top').removeClass('affix');

  } else {

    if (!($('.navbar-fixed-top').hasClass())) {
      $('.navbar-fixed-top').addClass('affix');
    }
    $('.full-site-container').css({
      "margin": "0 auto",
      "max-width": "1200px"
    });
  }
  
  $('.callout-container').ready(function() {
    $('.callout-background').append(
      $('.callout-container').css('visibility', 'visible').show()
    );
  });

  function inViewport($ele) {
    var lBound = $(window).scrollTop(),
        uBound = lBound + $(window).height(),
        top = $ele.offset().top,
        bottom = top + $ele.outerHeight(true);

    return (top > lBound && top < uBound)
        || (bottom > lBound && bottom < uBound)
        || (lBound >= top && lBound <= bottom)
        || (uBound >= top && uBound <= bottom);
  }
};

$('.delayed-load').ready(function() {
  $('.delayed-load').css('display', 'block');
});



$(document).ready(ready);
$(document).on('page:load', ready);
