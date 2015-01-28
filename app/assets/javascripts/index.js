
$(document).ready(function(){/* smooth scrolling for scroll to top */
  $('.scroll-top').click(function(){
    $('body,html').animate({scrollTop:0},800);
  })
  /* smooth scrolling for scroll down */
  $('.scroll-down').click(function(){
    $('body,html').animate({scrollTop:$(window).scrollTop()+800},1000);
  })

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
