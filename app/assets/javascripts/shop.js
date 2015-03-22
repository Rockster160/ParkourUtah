var ready = function() {

  $('.cart-container').delegate('.shopping-cart-line-item-quantity-input', 'focusin', function() {
    amount_holder = $(this).val();
  });

  $('.cart-container').delegate('.delete-x', 'click', function() {
    $(this).siblings().children('.shopping-cart-line-item-quantity').children().val(0)
    sendUpdatedAmount($(this).attr('id'), 0);
  });

  $('.cart-container').delegate('.shopping-cart-line-item-quantity-input', 'focusout', function() {
    if ($(this).val() != amount_holder) {
      sendUpdatedAmount($(this).attr('id'), $(this).val());
    }
  });

};

sendUpdatedAmount = function(item_id, new_amount) {
  $.post('/cart/update', {item_id: item_id, new_amount: new_amount});
}

$(document).ready(ready);
$(document).on('page:load', ready);
