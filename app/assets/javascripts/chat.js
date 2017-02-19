var last_message_timestamp = 0;

$(document).ready(function() {
  if ($('.messages-container').length > 0) {

    refreshTimeago = function() {
      $('time.timeago').each(function() {
        timeago(this);
      })
    }

    refreshTimeago();
    setInterval(refreshTimeago, 10000);

    $('.messages-form').submit(function(e) {
      e.preventDefault()

      var form = this, $form = $(this),
          $message_field = $form.find('.new-message-field'),
          message = $message_field.val(),
          form_data = $form.serialize();

      if (message.length == 0) {
        return false;
      }

      $message_field.val("");
      $.post(form.action, form_data).done(function() {
        queryNewMessages();
      })

      return false;
    })

    scrollBottomOfMessages = function() {
      $('.messages-container').animate({scrollTop: $('.messages-container')[0].scrollHeight}, 300);
    }

    calculateHeightOfMessages = function() {
      var totalHeight = 0;
      $('.messages-container').children().each(function() {
        totalHeight += $(this).outerHeight(true);
      });
      return totalHeight;
    }

    queryNewMessages = function() {
      var params = parseParams();
      params["last_sync"] = parseInt(last_message_timestamp) + 1;

      $.get('messages', params).success(function(data) {
        var previous_height = calculateHeightOfMessages();
        $('.messages-container').append(data);
        var new_height = calculateHeightOfMessages();
        var new_messages_received = new_height > previous_height;
        if (new_messages_received) {
          scrollBottomOfMessages()
        }
        refreshTimeago();
        // Mark messages as read
        last_message_timestamp = $('time.timeago').map(function() { return $(this).attr("datetime"); }).sort(function(a, b) { return a-b; }).last()[0];
      })
    }
    queryNewMessages();
    setInterval(queryNewMessages, 5000);
  }
})

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
