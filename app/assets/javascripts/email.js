const KEY_EVENT_TAB = 9;
email_template_preview_timer = null;
$(document).ready(function() {

  if ($('#mkdown-preview').length > 0 && $('.js-markdown').length > 0) {
    var text_box = $('.js-markdown');

    reloadPreview = function() {
      clearTimeout(email_template_preview_timer);
      email_template_preview_timer = setTimeout(function() {updatePreview()}, 500)
    }

    updatePreview = function() {
      clearTimeout(email_template_preview_timer);
      var iframe = $('#mkdown-preview');
      $.get(iframe.attr('data-load-url'), formObjectForBody()).success(function(data) {
        iframe.attr('src', '');
        setTimeout(function() {
          iframe.attr('src', 'data:text/html;charset=utf-8,' + encodeURI(data.preview_html));
        }, 10)
      }).error(function(data) {
        iframe.attr('src', '');
        setTimeout(function() {
          error_html = "<h1>Invalid parsed HTML</h1>";
          error_html += "<ul>";
          $(data.responseJSON.errors).each(function() {
            error_html += "<li>" + this + "</li>";
          })
          error_html += "</ul>";
          iframe.attr('src', 'data:text/html;charset=utf-8,' + encodeURI(error_html));
        }, 10)
      })
    }

    formObjectForBody = function() {
      var paramObj = {};
      $.each($('.js-markdown').serializeArray(), function(_, kv) {
        if (paramObj.hasOwnProperty(kv.name)) {
          paramObj[kv.name] = $.makeArray(paramObj[kv.name]);
          paramObj[kv.name].push(kv.value);
        }
        else {
          paramObj[kv.name] = kv.value;
        }
      });
      return paramObj;
    }

    updatePreview();

    $('.js-markdown').on('keydown', function(e) {
      if (e.which == KEY_EVENT_TAB) {
        e.preventDefault();
        attemptTabCommand();
        return false;
      }
    }).on('input propertychange change keyup', function(e) {
      reloadPreview();
    })

    $('.reload-preview').click(function(e) {
      e.preventDefault();
      $('#mkdown-preview').attr('src', '');
      reloadPreview();
      return false;
    })

    wrap = function(beginning, end) {
      var sel = text_box.getSelection(), txt_body = text_box.val();
      text_box.val([txt_body.slice(0, sel.start), beginning, txt_body.slice(sel.start, sel.end), end, txt_body.slice(sel.end)].join(''));
      text_box.selectRange(sel.start + beginning.length, sel.start + beginning.length + sel.length)
    }

    removeCharsAtIndex = function(char_count, idx) {
      text_box.val(function(i, t) {
        return t.slice(0, idx - char_count) + t.slice(idx + char_count + 1);
      })
    }

    attemptTabCommand = function() {
      var sel = text_box.getSelection(), txt_body = text_box.val();
      if (sel.length == 0) {
        var command_word = getWordAt(txt_body, sel.start - 1);
        if (command_word == "center") {
          removeCharsAtIndex(command_word.length, sel.start);
          wrap('[center]', '[/center]');
        }
        if (command_word == "link") {
          removeCharsAtIndex(command_word.length, sel.start);
          wrap('[link url="<url>"]', '[/link]');
        }
        if (command_word == "html") {
          removeCharsAtIndex(command_word.length, sel.start);
          wrap('[html]', '[/html]');
        }
        if (command_word == "hr") {
          removeCharsAtIndex(command_word.length, sel.start);
          wrap('---', '');
        }
      }
    }

    function getWordAt(str, pos) {
      // Perform type conversions.
      str = String(str);
      pos = Number(pos) >>> 0;

      // Search for the word's beginning and end.
      var left = str.slice(0, pos + 1).search(/\S+$/),
      right = str.slice(pos).search(/\s/);

      // The last word in the string is a special case.
      if (right < 0) {
        return str.slice(left);
      }

      // Return the word, using the located bounds to extract it from the string.
      return str.slice(left, right + pos);
    }

    $('.js-append').click(function(e) {
      e.preventDefault();
      if ($(this).attr('data-append') == 'text') {
        var color = $('.js-mm-picker[name="color"]').val(), size = $('.js-mm-picker[name="size"]').val();
        wrap('[text color="#' + color + '" size="' + size + '" font="Verdana, Geneva, sans-serif"]', "[/text]")
      }
      if ($(this).attr('data-append') == 'center') { wrap('[center]', '[/center]') }
      if ($(this).attr('data-append') == 'link') { wrap('[link url="<url>"]', '[/link]') }
      if ($(this).attr('data-append') == 'html') { wrap('[html]', '[/html]') }
      if ($(this).attr('data-append') == 'hr') { wrap('---', '') }
      return false;
    })

    $('.js-mm-picker').change(function() {
      $('.js-preview').css({'font-size': $('.js-mm-picker[name="size"]').val() + 'px', 'color': '#' + $('.js-mm-picker[name="color"]').val()})
    })
    $('.js-shortcut').click(function(e) {
      e.preventDefault();
      if ($(this).attr('data-color')) {
        $('.jscolor')[0].jscolor.fromString($(this).attr('data-color'))
      }
      if ($(this).attr('data-font-size')) {
        $('.js-mm-picker[name="size"]').val($(this).attr('data-font-size'))
      }
      $('.js-mm-picker').change();
      return false;
    })
  }

})
