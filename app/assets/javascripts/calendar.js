var ready = function () {

  if ($('.date-picker').length > 0) {
    $('.date-picker').datepicker({
      onSelect: function(dateText, inst) {
        $('.datepicker-placeholder').val(dateText);
        $('.date-placeholder').text(dateText);
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
    update();
  });
  $('.calendar-container').delegate('.calendar-event', 'click', function() {
    $('.calendar-tooltip').hide();
    $(this).children('.calendar-tooltip').show()
  });
  $('.calendar-container').delegate('.close-tooltip', 'mousedown', function() {
    $('.calendar-tooltip').hide();
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

$(document).ready(ready);
$(document).on('page:load', ready);
