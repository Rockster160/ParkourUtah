var last_message_timestamp = 0;

$(document).ready(function() {
  if ($('.messages-container').length > 0) {

    var params = parseParams();
    var room_id = ''
    if (params["phone_number"] != undefined) {
      room_id = "phone_" + params["phone_number"];
    } else if (params["user_id"] != undefined) {
      room_id = "user_" + params["user_id"];
    }

    App.global_chat = App.cable.subscriptions.create({
      channel: "ChatChannel",
      chat_room_id: room_id
    }, {
      connected: function() {
        console.log("step: connected");
      },
      disconnected: function() {
        console.log("step: disconnected");
      },
      received: function(data) {
        console.log("step: received");
        if (data["message"] != undefined) {
          $('.messages-container').append(data["message"]);
          scrollBottomOfMessages();
          refreshTimeago();
          last_message_timestamp = $('time.timeago').map(function() { return $(this).attr("datetime"); }).sort(function(a, b) { return a-b; }).last()[0];
          var read_ids = $('.text-message').map(function() { return $(this).attr("data-read-id"); });
          // FIXME: Only read messages I receive
          // var read_ids = $('.text-message.received').map(function() { return $(this).attr("data-read-id"); });
          if (read_ids.length > 0) {
            $.post('/messages/mark_messages_as_read', {ids: read_ids.toArray()})
          }
        } else if (data["error"] != undefined) {
          var error = data["error"]
          $('.text-message[data-read-id=' + error["message_id"] + '] > .message-body').append('<div class="text-error-message">Error: ' + error["message"] + '</div>')
          scrollBottomOfMessages();
          refreshTimeago();
        } else {
          console.log("Unknown error: " + data);
        }
        // Mark messages as read
      },
      send_message: function(message) {
        console.log("step: send_message");
        return this.perform('send_message', {
          message: message,
          chat_room_id: room_id
        });
      }
    });

    refreshTimeago = function() {
      $('time.timeago').each(function() {
        timeago(this);
      })
      $('.important-alert-message').appendTo('.messages-container');
    }

    refreshTimeago();
    setInterval(refreshTimeago, 10000);

    $('.messages-form .new-message-field').keypress(function(evt) {
      var $form = $('.messages-form');
      if (evt.keyCode == KEY_EVENT_ENTER && !evt.shiftKey) {
        $form.submit();
      }
    })

    $('.messages-form').submit(function(e) {
      e.preventDefault()

      var form = this, $form = $(this),
          $message_field = $form.find('.new-message-field'),
          message = $.trim($message_field.val()),
          form_data = $form.serialize();

      if (message.length == 0) {
        return false;
      }

      $message_field.val("");
      App.global_chat.send_message(message, room_id);

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
          scrollBottomOfMessages();
        }
        refreshTimeago();
        last_message_timestamp = $('time.timeago').map(function() { return $(this).attr("datetime"); }).sort(function(a, b) { return a-b; }).last()[0];
      })
    }
    queryNewMessages();
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
