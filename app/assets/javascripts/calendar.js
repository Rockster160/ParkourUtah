$(document).ready(function() {
  loadJS();

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

    $.get('calendar/draw', {
      classes: classes,
      cities: cities,
      date: set_date
    }, function() {
      new loadJS;
    });
  }
});


loadJS = function() {
  $('li').click(function() {
    var $location = $(this).attr('href');
    if ($location) {
      window.location.href = $location;
    }
  });

  $('.select-dropbox').select2()
  .on('change', function(e) {
    update();
  });
}
