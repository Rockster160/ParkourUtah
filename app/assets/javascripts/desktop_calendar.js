var desktop_calendar = function () {
  desktop_can_load = true;
  $('.calendar-partial').on('click', '.calendar-scroll', function() {
    if (!desktop_can_load) { return false };
    if ($(this).hasClass('calendar-left')) {
      loadDesktopWeek('previous');
    } else {
      loadDesktopWeek('next');
    }
  });

  loadDesktopWeek = function(period, date) {
    desktop_can_load = false;

    var date = date || $('.day-container').first().data('date');
    date_params = dateParamsFromSelect();

    if ($('.week-container').children().length > 0) { $('.holding-container').html($('.week-container').html()) }
    $('.week-container').html('<div class="center-spinner-container"><i class="fa fa-spinner fa-spin fa-3x"/></div>');

    var week_url = $('.week-container').data('week-url') + '?date=' + date + '&direction=' + period + date_params;
    $('.loading-container').load(week_url, function() {
      $('.week-container').html($('.loading-container').html());
      $('.loading-container').html('');
      if ($('.week-container').children().length == 0) { $('.week-container').html($('.holding-container').html()) }
      $('.month-container > h3').html($('.day-container').first().data('month'));
      desktop_can_load = true;
    })

  }

  dateParamsFromSelect = function() {
    var classes = [], cities = [];
    select_class = $('.class-name-search').select2('data');
    select_city = $('.city-name-search').select2('data');
    for (i=0;i<select_class.length;i++) {
      classes.push(select_class[i].id);
    }
    for (i=0;i<select_city.length;i++) {
      cities.push(select_city[i].id);
    }
    date_param = '';
    if (cities.length > 0) { date_param += '&cities=' + cities };
    if (classes.length > 0) { date_param += '&classes=' + classes };
    return date_param
  }

  tryLoad = function() {
    if (desktop_can_load) {
      loadDesktopWeek('now');
    } else {
      setTimeout(tryLoad, 50);
    }
  }

  if ($('.calendar-date-picker').length > 0) {
    $('.calendar-date-picker').datepicker({
      onSelect: function(dateText, inst) {
        loadDesktopWeek('now', dateText.replace(/\//g, '-'));
      }
    });
  }

  if ($('.desktop-view-container').length > 0) {
    var city = '';
    $(window.location.href.split(/[\&, \?]+/)).each(function() {
      if (this.indexOf('city=') > -1) { city = this.split('city=')[1].replace(/(%20)/g, ' ') }
    });
    $('.select-dropbox').select2().on('change', function(e) {
      tryLoad();
      setTimeout(function() {
        $('.city-name-search').next(".select2-container").find('.select2-search__field').css({width: '100%'}).attr("placeholder", $('.city-name-search').attr("placeholder"))
        $('.class-name-search').next(".select2-container").find('.select2-search__field').css({width: '100%'}).attr("placeholder", $('.class-name-search').attr("placeholder"))
      }, 1)
    });
    $('.select-dropbox').select2()
    $('.city-name-search').val([city.parameterize]).trigger("change")
    $('.select-dropbox').trigger("change")

    loadDesktopWeek('now');
  }
};

String.prototype.parameterize = function () {
   return this.replace(/[^a-zA-Z0-9-\s]/g, '').replace(/[^a-zA-Z0-9-]/g, '-').toLowerCase();
}

$(document).ready(desktop_calendar);
$(document).on('page:load', desktop_calendar);
