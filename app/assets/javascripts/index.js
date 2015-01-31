$(document).ready(function(){
  /* smooth scrolling for scroll to top */
  $('.scroll-link').click(function(e){
    if (window.location.pathname == "/") {
      e.preventDefault();
      $href = e.target.hash
      $('body,html').animate({scrollTop:$($href).offset().top},500);
    }
  })

  /* highlight the top nav as scrolling occurs */
  $('body').scrollspy({ target: '#navbar' })
});
