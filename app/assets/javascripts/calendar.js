var ready = function () {

  window.mobilecheck = function() {
    var check = false;
    (function(a){if(/(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino/i.test(a)||/1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(a.substr(0,4)))check = true})(navigator.userAgent||navigator.vendor||window.opera);
    return check;
  };

  if ($('.days-container').length > 0) {

    var loading = false;

    getOffsets = function() {
      var offsets = []
      $('.days-container').find('.a-single-date').each(function() {
        offsets.push(this.offsetLeft);
      });
      return arrUniq(offsets).sort(function(a, b){return a-b});
    };
    currentOffset = function() {
      var scroll_left = $('.view-container').scrollLeft() + 1, current_offset = 0;
      getOffsets().sort(function(a,b){return a-b}).forEach(function(number, index, array) {
        if (scroll_left > number) { current_offset = number; }
      });
      return current_offset;
    };

    getContainerOffset = function(amount) {
      amount = amount || 1;
      var offsets = getOffsets(), offset_index = offsets.indexOf(currentOffset()) + amount;

      offset_index = (offset_index < 0 ? 0 : offset_index);
      offset_index = (offset_index >= offsets.length ? offsets.length - 1 : offset_index);

      if (offset_index < 35 && loading == false) {
        setLoading(true);
        var date = $('.a-single-date').first().data('date'),
          width = $('.a-single-date').first().width(),
          month_url = $('.view-container').data('month-url') + '?date=' + date + '&direction=' + 'past';
        $('.loading-container').load(month_url, function() {
          var day_count = $('.loading-container').find('.a-single-date').length,
            container_width = day_count * $(window).width(),
            current_scroll = $('.view-container').scrollLeft();
          $('.days-container').prepend($('.loading-container').html());
          $('.loading-container').html('');
          $('.month-container').last().remove();
          $('.view-container').scrollLeft(current_scroll + container_width);
          setLoading(false);
        })
      }
      if (offset_index > offsets.length - 35 && loading == false) {
        setLoading(true);
        var date = $('.a-single-date').last().data('date'),
          month_url = $('.view-container').data('month-url') + '?date=' + date + '&direction=' + 'future';
        $('.loading-container').load(month_url, function() {
          var new_scroll = $('.view-container').scrollLeft(),
            day_count = $('.month-container').first().children().length,
            month_width = day_count * $(window).width();
          $('.month-container').first().remove();
          $('.days-container').append($('.loading-container').html());
          $('.loading-container').html('');
          $('.view-container').scrollLeft(new_scroll - month_width);
          setLoading(false);
        })
      }

      return offsets[offset_index];
    };

    $('.mobile-control-btn').click(function() {
      if (!$(this).hasClass('disabled')) {
        if ($(this).attr('id') == 'next-week') {
          sideScroll(7);
        }
        if ($(this).attr('id') == 'previous-week') {
          sideScroll(-7);
        }
      }
    });

    setLoading = function(bool) {
      loading = bool;
      if (bool) {
        $('.mobile-control-btn').addClass('disabled');
      } else {
        $('.mobile-control-btn').removeClass('disabled');
      }
    }

    sideScroll = function(amount, speed) {
      amount = amount || 1;
      speed = speed || 200;

      $('.view-container').animate( {scrollLeft: getContainerOffset(amount)}, speed );
    }

    var last_touch_x = 0;
    var last_touch_y = 0;
    var last_touch_time = 0;
    $('.view-container')
      .on('touchstart mousedown', '.a-single-date', function(e) {
        last_touch_x = e.pageX || e.originalEvent.changedTouches[0].pageX;
        last_touch_y = e.pageY || e.originalEvent.changedTouches[0].pageY;
        if (last_touch_x > ($('.view-container').width()-20)) {
          sideScroll(1);
          last_touch_time = new Date().getTime() - 1000;
        } else if (last_touch_x < 20) {
          sideScroll(-1);
          last_touch_time = new Date().getTime() - 1000;
        } else {
          last_touch_time = new Date().getTime();
        }
        e.preventDefault();
      })
      .on('touchend mouseup', '.a-single-date', function(e) {
        var touch_x = e.pageX || e.originalEvent.changedTouches[0].pageX,
          touch_y = e.pageY || e.originalEvent.changedTouches[0].pageY,
          difference_x = last_touch_x - touch_x,
          difference_y = last_touch_y - touch_y,
          scroll_horz = Math.abs(difference_x) >= Math.abs(difference_y);
        if (new Date().getTime() - 1000 < last_touch_time) {
          e.preventDefault();
          // if (scroll_horz) {
            if (difference_x > 10) {
              sideScroll(1);
            } else if (difference_x < -10) {
              sideScroll(-1);
            }
          // } else {
          //   if (difference_y > 10) {
          //     sideScroll(7);
          //   } else if (difference_y < -10) {
          //     sideScroll(-7);
          //   }
          // }
        }
      });

    $('.view-container').scroll(function(e) {
      $.doTimeout( 'scroll', 40, function() {
        var x = $('.view-container').width()/2, y = $('.view-container').height()/2, x_offset = document.elementFromPoint(x, y).offsetLeft;
        if ($('.view-container').scrollLeft() != x_offset) {
          $('.view-container').animate( {scrollLeft: x_offset}, 100 );
        } else {
          $('.view-container').stop();
        }
      });
    });

    $('.view-container').scrollLeft($('.date').position().left)
  }

  if ($('.date-picker').length > 0) {
    $('.date-picker').datepicker({
      onSelect: function(dateText, inst) {
        $('.datepicker-placeholder').val(dateText);
        $('.date-placeholder').text(dateText);
      }
    });
  }
  if ($('.mobile-date-picker').length > 0) {
    $('.mobile-date-picker').datepicker({
      onSelect: function(dateText, inst) {
        window.location.href = window.location.href.split('?')[0] + "?date=" + dateText.replace(/\//g, '-') ;
      }
    });
  }

  update = function() {
    var classes = [], cities = [];
    select_class = $('.class-name-search').select2('data');
    select_city = $('.city-name-search').select2('data');
    for (i=0;i<select_class.length;i++) {
      classes.push(select_class[i].id);
    }
    for (i=0;i<select_city.length;i++) {
      cities.push(select_city[i].id);
    }
    if (window.location.pathname.indexOf("/schedule") > -1) {
      $.get('/calendar/draw', {
        classes: classes,
        cities: cities,
        date: set_date
      });
    }
  }

  $('.cities-container').delegate('.calendar-legend', 'click', function() {
    city = $(this).attr("href");
    $('.select-dropbox').select2("val", city);
    $('.show-tooltip').hide();
    update();
  });

  $('.back-month, .forward-month').click(function(e) {
    e.preventDefault();
    set_date = $(this).attr('href');
    update();
  })

  loadJS();
  update();
};


loadJS = function() {
  var url = window.location.pathname.split("/");
  var city = unescape(url[url.length - 1]);

  $('.select-dropbox').select2()
  .select2("val", city)
  .on('change', function(e) {
    update();
  });
}

arrUniq = function(arr) {
  return arr.reduce(function(p, c) {
    if (p.indexOf(c) < 0) { p.push(c) };
    return p;
  }, []);
};

$(document).ready(ready);
$(document).on('page:load', ready);
