$(document).ready(function() {
  $('.show-referral-text-box').change(function() {
    if (this.value == "Word of Mouth") {
      $('.referral-text-field').removeClass('hidden');
    } else {
      $('.referral-text-field').addClass('hidden');
    }
  })
})
