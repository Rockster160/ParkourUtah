$(document).ready(function() {

  $('li').click(function() {
    var $location = $(this).attr('href');
    if ($location) {
      window.location.href = $location;
    }
  });

  $('.select-dropbox').select2()
  .on('change', function() {
    console.log('Changed.');
  });
});
