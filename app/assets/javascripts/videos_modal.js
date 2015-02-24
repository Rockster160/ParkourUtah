ready = function() {
  var $frame_1 = $('iframe#video_1');
  var $frame_2 = $('iframe#video_2');
  var $frame_3 = $('iframe#video_3');
  var $frame_4 = $('iframe#video_4');
  var $frame_5 = $('iframe#video_5');
  var $frame_6 = $('iframe#video_6');

  var vidsrc_1 = $frame_1.attr('src');
  var vidsrc_2 = $frame_2.attr('src');
  var vidsrc_3 = $frame_3.attr('src');
  var vidsrc_4 = $frame_4.attr('src');
  var vidsrc_5 = $frame_5.attr('src');
  var vidsrc_6 = $frame_6.attr('src');

  function source_for(id) {
    if (id == 1) { return vidsrc_1; };
    if (id == 2) { return vidsrc_2; };
    if (id == 3) { return vidsrc_3; };
    if (id == 4) { return vidsrc_4; };
    if (id == 5) { return vidsrc_5; };
    if (id == 6) { return vidsrc_6; };
  };

  function frame_for(id) {
    if (id == 1) { return $frame_1; };
    if (id == 2) { return $frame_2; };
    if (id == 3) { return $frame_3; };
    if (id == 4) { return $frame_4; };
    if (id == 5) { return $frame_5; };
    if (id == 6) { return $frame_6; };
  };

  $('#modal_1').on('shown.bs.modal', function(e) {
    frame_for(1).attr('src', source_for(1));
  });
  $('#modal_1').on('hide.bs.modal', function(e) {
    frame_for(1).attr('src','');
  });
  $('#modal_2').on('shown.bs.modal', function(e) {
    frame_for(2).attr('src', source_for(2));
  });
  $('#modal_2').on('hide.bs.modal', function(e) {
    frame_for(2).attr('src','');
  });
  $('#modal_3').on('shown.bs.modal', function(e) {
    frame_for(3).attr('src', source_for(3));
  });
  $('#modal_3').on('hide.bs.modal', function(e) {
    frame_for(3).attr('src','');
  });
  $('#modal_4').on('shown.bs.modal', function(e) {
    frame_for(4).attr('src', source_for(4));
  });
  $('#modal_4').on('hide.bs.modal', function(e) {
    frame_for(4).attr('src','');
  });
  $('#modal_5').on('shown.bs.modal', function(e) {
    frame_for(5).attr('src', source_for(5));
  });
  $('#modal_5').on('hide.bs.modal', function(e) {
    frame_for(5).attr('src','');
  });
  $('#modal_6').on('shown.bs.modal', function(e) {
    frame_for(6).attr('src', source_for(6));
  });
  $('#modal_6').on('hide.bs.modal', function(e) {
    frame_for(6).attr('src','');
  });

};

$(document).ready(ready);
$(document).on('page:load', ready);
