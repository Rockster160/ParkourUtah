var ready = function() {
  /* smooth scrolling for scroll to top */
  $('.scroll-link').click(function(e){
    if (window.location.pathname == "/") {
      e.preventDefault();
      $href = e.target.hash
      $('body,html').animate({scrollTop:$($href).offset().top},500);
    }
  });

  $(window).scroll(function() {
    var $bgobj = $('.callout-background');
    var yPos = -($(window).scrollTop() / $bgobj.data('speed'));
    var coords = '50% '+ yPos + 'px';
    $bgobj.css({ backgroundPosition: coords });
  });

  /* highlight the top nav as scrolling occurs */
  $('body').scrollspy({ target: '#navbar' });
  $('.navbar-fixed-top').affix({
    offset: {
      top: $('.header-container').height()
    }
  });
};

$(document).ready(ready);
$(document).on('page:load', ready);
