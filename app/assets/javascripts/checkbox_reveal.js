$(document).ready(function() {
  $("[data-reveal] input").change(function() {
    var container = $(this).parents('[data-reveal]');
    if (container.find('[data-show]').is(':checked')) {
      $(container.attr('data-reveal')).removeClass('hidden');
    } else {
      $(container.attr('data-reveal')).addClass('hidden');
    }
  })
  $("input[data-reveal]").change(function() {
    var $reveal = $($(this).attr("data-reveal"));
    if ($(this).is(':checked')) {
      $reveal.removeClass('hidden');
    } else {
      $reveal.addClass('hidden');
    }
  })
  $("[data-reveal] input, input[data-reveal]").change();
})