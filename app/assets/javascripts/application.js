// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require jquery-tablesorter
//= require select2
//= require twitter/bootstrap
//= require maskedinput
//= require_tree .

ready = function() {

  if ($('.flash').length == 0) {
    killFlashes();
  }

  killFlashAfterDelay = function() {
    setTimeout(function() {
      killFlashes();
    }, 6000);
  }

  killFlashAfterDelay();

  $('body').delegate('.close-flash', 'click', function() {
    killFlashes();
  });

};

reFlash = function(type, msg) {
  killFlashes();
  showFlash(type, msg);
  killFlashAfterDelay();
}

killFlashes = function() {
  slideOut($('.flash-container'));
  slideOut($('.flash'));
}

slideOut = function(obj) {
  obj.slideUp(600);
}

showFlash = function(type, msg) {
  killFlashes();
  $('.flash-holder').append('<div class="flash-container"><div class="flash ' +
  type + '"><span class="flash-text">' +
  msg + '</span></div></div>');
  killFlashAfterDelay();
}

$(document).ready(ready);
$(document).on('page:load', ready);
