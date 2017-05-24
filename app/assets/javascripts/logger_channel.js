$(document).ready(function() {
  if ($('.log-tracker-table').length > 0) {

    var params = parseParams();
    var user_id = $('.messages-container').attr('data-current-user-id');
    var room_id = $('.messages-container').attr('data-room-id');
    var channel_id = "room_" + room_id;
    var currently_typing = {};
    var unread_count = 0;

    App.logger = App.cable.subscriptions.create({
      channel: "LoggerChannel"
    }, {
      connected: function() {},
      disconnected: function() {},
      received: function(data) {
        $('.log-tracker-table .tbody').prepend(data.message);
      }
    });

  }
})
