var ready = function() {

  if (window.location.pathname == "/") {
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
  }
};

var all_loaded = function () {
  alert('All is loaded!');
  console.log('All is loaded!');
  ready();
}

$(document).ready(ready);
$(document).on('page:load', all_loaded);
