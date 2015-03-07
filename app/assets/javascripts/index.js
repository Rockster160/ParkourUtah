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

  } else {
    $('body').scrollspy({ target: '#navbar' });
    $('.navbar-fixed-top').affix({
      offset: {
        top: 0
      }
    });
  }
};

$('.delayed-load').ready(function() {
  $('.delayed-load').css('display', 'block');
});

$(document).ready(ready);
$(document).on('page:load', ready);
