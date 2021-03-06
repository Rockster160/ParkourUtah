var mobile_calendar = function () {

  window.mobilecheck = function() {
    var check = false;
    (function(a){if(/(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino/i.test(a)||/1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(a.substr(0,4)))check = true})(navigator.userAgent||navigator.vendor||window.opera);
    return check;
  };

  $('.mobile-view-container, .calendar-container').on('click tap', '.event-detail-btn', function(e) {
    $('.event-detail-container').html('<div class="text-center"><i class="fa fa-spinner fa-spin fa-3x"/></div>');
    var url = $(this).attr('data-event-url')
    $.get(url, {}).success(function(data) {
      $('.event-detail-container').html(data);
      setTimeout(initializeGmaps, 1000)
    })
    $('#event-detail-modal').modal('show');
  })

  if ($('.mobile-view-container').length > 0) {
    is_loading = true, load_period = 'next', can_update = true, scroll_timer = 0;

    setTimeout(function() {
      $('body').animate({scrollTop: $('.chosen-day').offset().top - 120}, 0, 'swing', function() {
        is_loading = false;
      })
    }, 100)

    $(window).scroll(function() {
      can_update = false;
      if (scroll_timer) { clearTimeout(scroll_timer) };
      scroll_timer = setTimeout(function() {can_update = true}, 100);
      if (is_loading == false) {
        if (isScrolledIntoView($('.load-next'))) {
          load_period = 'next';
          loadMobileWeek();
        } else if (isScrolledIntoView($('.load-previous'))) {
          load_period = 'previous';
          loadMobileWeek();
        }
      }
    });

    setLoading = function(bool) {
      if(bool) {
        is_loading = true;
        $('.load-previous').html('<i class="fa fa-spinner fa-spin fa-3x"/>');
        $('.load-next').html('<i class="fa fa-spinner fa-spin fa-3x"/>');
      } else {
        is_loading = false;
        $('.load-previous').html('');
        $('.load-next').html('');
      }
    }

    loadMobileWeek = function(period) {
      if (is_loading == false) {
        setLoading(true);

        if (load_period == 'previous') {
          var date = $('.day-container').first().data('date');
        } else {
          var date = $('.day-container').last().data('date');
        }

        var week_url = $('.mobile-view-container').data('week-url').replace(/\/m/, '') + '?date=' + date + '&direction=' + load_period + '&size=mobile';
        $('.loading-container').load(week_url, function() {
          mobileLoadWhenReady();
        })
      }
    }

    mobileLoadWhenReady = function() {
      if (can_update) {
        if (load_period == 'previous') {
          var old_height = $('body').height();
          $('.weeks-container').prepend($('.loading-container').html());
          var new_height = $('body').height(),
              scroll_offset = new_height - old_height,
              current_scroll = $('body').scrollTop();
          $('body').scrollTop(current_scroll + scroll_offset);
          var days_count = $('.day-container').length;
          while (days_count > 70) {
            $('.day-container').last().remove();
            days_count = $('.day-container').length;
          }
        } else {
          $('.weeks-container').append($('.loading-container').html());
          var days_count = $('.day-container').length;
          while (days_count > 70) {
            var day_to_remove = $('.day-container').first(),
                unscroll = day_to_remove.height(),
                current_scroll = $('body').scrollTop();
            $('body').scrollTop(current_scroll - unscroll);
            day_to_remove.remove();
            days_count = $('.day-container').length;
          }
        }
        setLoading(false);
        $('.loading-container').html('');
      } else {
        setTimeout(mobileLoadWhenReady, 50);
      }
    }
  }

  if ($('.date-picker').length > 0) {
    $('.date-picker').datepicker({
      onSelect: function(dateText, inst) {
        $('.datepicker-placeholder').val(dateText);
        $('.date-placeholder').text(dateText);
      }
    });
  }
  if ($('.mobile-calendar-date-picker').length > 0) {
    $('.mobile-calendar-date-picker').datepicker({
      onSelect: function(dateText, inst) {
        window.location.href = window.location.href.split('?')[0] + "?date=" + dateText.replace(/\//g, '-') ;
      }
    });
  }
};

function isScrolledIntoView(elem) {
  var $elem = $(elem), $window = $(window);
  var docViewTop = $window.scrollTop(), docViewBottom = docViewTop + $window.height();
  var elemTop = $elem.offset().top, elemBottom = elemTop + $elem.height();

  return ((elemBottom - 200 <= docViewBottom) && (elemTop + 200 >= docViewTop));
}

arrUniq = function(arr) {
  return arr.reduce(function(p, c) {
    if (p.indexOf(c) < 0) { p.push(c) };
    return p;
  }, []);
};

$(document).ready(mobile_calendar);
$(document).on('page:load', mobile_calendar);
