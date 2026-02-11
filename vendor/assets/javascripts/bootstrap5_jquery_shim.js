// Shim: Bridge Bootstrap 3/4 jQuery API to Bootstrap 5 vanilla JS API
// 1. Restores $.fn.modal(), $.fn.tooltip(), $.fn.popover(), $.fn.collapse(), $.fn.dropdown(), $.fn.tab()
// 2. Maps data-toggle/data-target/data-dismiss/data-parent/data-slide/data-ride to data-bs-* equivalents
(function($) {
  if (typeof bootstrap === 'undefined') return;

  // jQuery plugin shims — handle both initialization ($el.tooltip()) and actions ($el.tooltip('show'))
  $.fn.modal = function(action) {
    return this.each(function() {
      var opts = (typeof action === 'object') ? action : {};
      var instance = bootstrap.Modal.getOrCreateInstance(this, opts);
      if (action === 'show') instance.show();
      else if (action === 'hide') instance.hide();
      else if (action === 'toggle') instance.toggle();
      else if (action === 'handleUpdate') instance.handleUpdate();
    });
  };

  $.fn.tooltip = function(action) {
    return this.each(function() {
      var opts = (typeof action === 'object') ? action : {};
      var instance = bootstrap.Tooltip.getOrCreateInstance(this, opts);
      if (action === 'show') instance.show();
      else if (action === 'hide') instance.hide();
      else if (action === 'toggle') instance.toggle();
      else if (action === 'dispose') instance.dispose();
    });
  };

  $.fn.popover = function(action) {
    return this.each(function() {
      var opts = (typeof action === 'object') ? action : {};
      var instance = bootstrap.Popover.getOrCreateInstance(this, opts);
      if (action === 'show') instance.show();
      else if (action === 'hide') instance.hide();
      else if (action === 'toggle') instance.toggle();
      else if (action === 'dispose') instance.dispose();
    });
  };

  $.fn.collapse = function(action) {
    return this.each(function() {
      var opts = (typeof action === 'object') ? action : {};
      var instance = bootstrap.Collapse.getOrCreateInstance(this, opts);
      if (action === 'show') instance.show();
      else if (action === 'hide') instance.hide();
      else if (action === 'toggle') instance.toggle();
    });
  };

  $.fn.dropdown = function(action) {
    return this.each(function() {
      var instance = bootstrap.Dropdown.getOrCreateInstance(this);
      if (action === 'show') instance.show();
      else if (action === 'hide') instance.hide();
      else if (action === 'toggle') instance.toggle();
    });
  };

  $.fn.tab = function(action) {
    return this.each(function() {
      var instance = bootstrap.Tab.getOrCreateInstance(this);
      if (action === 'show') instance.show();
    });
  };

  // Map legacy data-* attributes to data-bs-* equivalents on DOM ready
  $(function() {
    var attrs = ['toggle', 'target', 'dismiss', 'parent', 'slide', 'slide-to', 'ride', 'backdrop', 'keyboard', 'focus'];
    $.each(attrs, function(_, attr) {
      $('[data-' + attr + ']').each(function() {
        if (!this.hasAttribute('data-bs-' + attr)) {
          this.setAttribute('data-bs-' + attr, this.getAttribute('data-' + attr));
        }
      });
    });
  });
})(jQuery);
