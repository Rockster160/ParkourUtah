$(document).ready(function() {
  if ($('.chat-rooms-container').length > 0) {

    var params = parseParams();
    var user_id = $('.chat-rooms-container').attr('data-current-user-id');
    var channel_id = "chat_rooms_for_user_" + $('.chat-rooms-container').attr('data-current-user-id');
    var currently_typing = {};
    var unread_count = 0;

    App.chat_rooms = App.cable.subscriptions.create({
      channel: "ChatRoomChannel",
      channel_id: channel_id
    }, {
      connected: function() {},
      disconnected: function() {},
      received: function(data) {
        if (data["chat_boxes"] != undefined) {
          updateChatRooms(data["chat_boxes"])
        } else {
          console.log("Unknown error: " + data);
        }
      }
    });

    updateChatRooms = function(updated_chat_rooms) {
      $(updated_chat_rooms).each(function() {
        $('.chat-room-box[data-chat-room-id=' + $(this).attr("data-chat-room-id") + ']').remove();
        $('.chat-rooms-container').append(this);
      });
      refreshTimeago();
      reorderChatRooms();
    };

    reorderChatRooms = function() {
      var chat_rooms = $('.chat-room-box');
      chat_rooms.sort(function(a, b) {
        return parseInt($(b).find('time.timeago').attr("datetime")) - parseInt($(a).find('time.timeago').attr("datetime"));
      });
      $('.chat-rooms-container').html(chat_rooms);
    };

    // updatePageTitleWithUnreads = function() {
    //   if (unread_count == 0) {
    //     document.title = "ParkourUtah"
    //   } else if (unread_count == 1) {
    //     document.title = "PKUT (1 unread message)"
    //   } else {
    //     document.title = "PKUT (" + unread_count + " unread messages)"
    //   }
    // }

  }
})
