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
//= require turbolinks
//= require maskedinput
//= require_tree .

ready = function() {
  timeout = setTimeout(function() {
    killFlashes();
  }, 6000);

  $('body').delegate('.flash', 'click', function() {
    killFlashes();
  });
};

killFlashes = function() {
  if ($('.flash-container').length > 0) {
    slideOut($('.flash-container'));
    clearTimeout(timeout);
    timeout = setTimeout(function() {
      killFlashes();
    }, 6000);
  }
}

slideOut = function(obj) {
  obj.slideUp(600);
}

showError = function(msg) {
  killFlashes();
  $('.flash-holder').append('<div class="flash-container"><div class="flash alert"><span class="flash-text">' +
  msg + '</span></div></div>');
}

$(document).ready(ready);
$(document).on('page:load', ready);
