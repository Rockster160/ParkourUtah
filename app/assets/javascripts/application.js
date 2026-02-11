// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require jquery.tablesorter
//= require select2
//= require dotimeout
//= require bootstrap
//= require bootstrap5_jquery_shim
//= require typeahead
//= require underscore
//= require maskedinput
//= require_tree .
//= require_tree ./channels


const KEY_EVENT_ENTER = 13,
      KEY_EVENT_TAB = 9,
      KEY_EVENT_UP = 38,
      KEY_EVENT_DOWN = 40,
      KEY_EVENT_LEFT = 37,
      KEY_EVENT_RIGHT = 39,
      KEY_EVENT_BACKSPACE = 8,
      KEY_EVENT_DELETE = 46;

parseParams = function(paramString) {
  paramString = paramString || window.location.href;
  if (paramString.indexOf('?') == -1) { return {} };
  var params = {}, items = paramString.split('?')[1].split("&");
  $(items).each(function() {
    var item = this.split('=');
    params[item[0]] = item[1];
  })
  return params
}
