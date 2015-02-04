$(document).ready(function() {
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

    $.get('/calendar/draw', {
      classes: classes,
      cities: cities,
      date: set_date
    });
  }

  $('.back-month, .forward-month').click(function(e) {
    e.preventDefault();
    set_date = $(this).attr('href');
    update();
  })

  loadJS();
  update();
});


loadJS = function() {
  $('li').click(function() {
    var $event_details = $(this).attr('href');
    if ($event_details) {
      window.location.href = $event_details;
    }
  });

  $('.select-dropbox').select2({

  })
  .on('change', function(e) {
    update();
  });
}
