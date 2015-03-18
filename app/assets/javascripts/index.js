var ready = function() {

  if (window.location.pathname == "/") {
    $('.full-site-container').css('background','none');
    /* smooth scrolling for scroll to top */
    $('.scroll-link').click(function(e){
      e.preventDefault();
      $href = e.target.hash
      $('body,html').animate({scrollTop:$($href).offset().top},500);
    });
    /* Remove buffer for Navbar. */
    $('.navbar-offset').hide();
    /* highlight the top nav as scrolling occurs */
    $('body').scrollspy({ target: '#navbar' });
    $('.navbar-fixed-top').affix({
      offset: {
        top: $('.header-container').height()
      }
    });
    $('.callout-container').ready(function() {
      $('.callout-background').append(
        $('.callout-container').css('visibility', 'visible').show()
      );
    });

  } else {
    
    $('body').scrollspy({ target: '#navbar' });
    $('.navbar-fixed-top').affix({
      offset: {
        top: -1
      }
    });
    $('.full-site-container').css({
      "margin": "0 auto",
      "max-width": "1200px"
    });
  }
};

$('.delayed-load').ready(function() {
  $('.delayed-load').css('display', 'block');
});

$(document).ready(ready);
$(document).on('page:load', ready);
