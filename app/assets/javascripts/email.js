timer_until_refresh = null;
$(document).ready(function() {

  if ($('#mkdown-preview').length > 0) {
    updateMailer()

    $('#body').on('input propertychange change keyup', function() {
      reloadMailer()
    })

    $('.reload-mailer').click(function(e) {
      e.preventDefault()
      $('#mkdown-preview').attr('src', '');
      reloadMailer()
      return false;
    })

    text_box = $('.js-markdown');

    wrap = function(beginning, end) {
      var sel = text_box.getSelection(), txt_body = text_box.val();
      text_box.val([txt_body.slice(0, sel.start), beginning, txt_body.slice(sel.start, sel.end), end, txt_body.slice(sel.end)].join(''));
      text_box.selectRange(sel.start + beginning.length, sel.start + beginning.length + sel.length)
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

reloadMailer = function() {
  clearTimeout(timer_until_refresh);
  timer_until_refresh = setTimeout(function() {updateMailer()}, 500)
}

updateMailer = function() {
  clearTimeout(timer_until_refresh);
  var iframe = $('#mkdown-preview');
  $.get(iframe.attr('data-load-url'), formObjectForBody()).success(function(data) {
    if (data.email_body.length > 0) {
      iframe.attr('src', '');
      setTimeout(function() {
        iframe.attr('src', 'data:text/html;charset=utf-8,' + encodeURI(data.email_body));
      }, 10)
    }
  }).error(function() {
    iframe.attr('src', '');
    setTimeout(function() {
      error_html = "<h1>Invalid parsed HTML</h1>"
      iframe.attr('src', 'data:text/html;charset=utf-8,' + encodeURI(error_html));
    }, 10)
  })
}

formObjectForBody = function() {
  var paramObj = {};
  $.each($('#body').serializeArray(), function(_, kv) {
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
