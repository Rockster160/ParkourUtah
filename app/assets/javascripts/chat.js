var last_message_timestamp = 0;

$(document).ready(function() {
  if ($('.messages-container').length > 0) {

    var params = parseParams();
    var room_id = "room_" + $('.messages-container').attr('data-room-id');
    var user_id = "user_" + $('.messages-container').attr('data-current-user-id');
    var currently_typing = {};

    App.global_chat = App.cable.subscriptions.create({
      channel: "ChatChannel",
      chat_room_id: room_id
    }, {
      connected: function() {
      },
      disconnected: function() {
      },
      received: function(data) {
        if (data["is_typing"] != undefined) {
          var typing_user_id = data["typing_user_id"];
          if (typing_user_id != $('.messages-container').attr('data-current-user-id')) {
            currently_typing[typing_user_id] = currently_typing[typing_user_id] || {};
            currently_typing[typing_user_id].name = data["is_typing"];
            clearTimeout(currently_typing[typing_user_id].timeout);
            currently_typing[typing_user_id].timeout = setTimeout(function() {
              currently_typing[typing_user_id] = {};
              refreshTypingContainer();
            }, 3000)
            refreshTypingContainer();
          }
        } else if (data["error"] != undefined) {
          var error = data["error"]
          $('.chat-message[data-read-id=' + error["message_id"] + '] > .message-body').append('<div class="text-error-message">Error: ' + error["message"] + '</div>')
          scrollBottomOfMessages();
          refreshTimeago();
        } else if (data["message"] != undefined) {
          $('.messages-container').append(data["message"]);
          $('.messages-container').append($('.typing-container'));
          var current_user_id = $('.messages-container').attr('data-current-user-id') || 'none';
          $('.chat-message[data-sent-by-id=' + current_user_id + ']').removeClass('received').addClass('sent');
          scrollBottomOfMessages();
          refreshTimeago();
          last_message_timestamp = $('time.timeago').map(function() { return $(this).attr("datetime"); }).sort(function(a, b) { return a-b; }).last()[0];
          var read_ids = $('.chat-message').map(function() { return $(this).attr("data-read-id"); });
          // FIXME: Only read messages I receive
          // var read_ids = $('.chat-message.received').map(function() { return $(this).attr("data-read-id"); });
          if (read_ids.length > 0) {
            var url = $('.message-form').attr('data-messages-url') + '/mark_messages_as_read';
            $.post(url, {ids: read_ids.toArray()})
          }
        } else {
          console.log("Unknown error: " + data);
        }
      },
      send_message: function(message) {
        return this.perform('send_message', {
          message: message,
          chat_room_id: room_id
        });
      },
      user_is_typing: function() {
        return this.perform('user_is_typing', {
          user_id: user_id,
          chat_room_id: room_id
        });
      }
    });

    $('.messages-form .new-message-field').keypress(function(evt) {
      var $form = $('.messages-form');
      if (evt.keyCode == KEY_EVENT_ENTER && !evt.shiftKey) {
        $form.submit();
      } else if (evt.keyCode != KEY_EVENT_BACKSPACE && evt.keyCode != KEY_EVENT_DELETE) {
        App.global_chat.user_is_typing();
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
      App.global_chat.send_message(message);

      return false;
    })

    typingNames = function(name_list) {
      if (name_list.length == 0) {
        return "";
      } else if (name_list.length == 1) {
        return name_list[0] + " is typing...";
      } else if (name_list.length == 2) {
        return name_list[0] + " and " + name_list[1] + " are typing...";
      } else if (name_list.length >= 3) {
        return name_list.reduce(function(prev, curr, i) {
          return prev + curr + ((i === name_list.length - 2) ? ', and ' : ', ')
        }, '').slice(0, -2);
      }
    }

    refreshTypingContainer = function() {
      var old_height = $('.typing-container').height();
      var names = [];
      for (user_key in currently_typing) {
        var user = currently_typing[user_key];
        if (user.name != undefined) {
          names.push(user.name);
        }
      }

      $('.typing-container').html(typingNames(names));
      var new_height = $('.typing-container').height();
      if (new_height > old_height) {
        $('.messages-container').animate({scrollTop: $('.messages-container')[0].scrollTop + (new_height - old_height)}, 300);
      }
    }

    scrollBottomOfMessages = function() {
      $('.important-alert-message').appendTo('.messages-container')
      $('.typing-container').appendTo('.messages-container')
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
      var url = $('.message-form').attr('data-messages-url');
      $.get(url, params).success(function(data) {
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
