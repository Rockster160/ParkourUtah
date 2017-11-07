$(document).ready(function() {

  if ($('.cart-btn').length > 0) {
    $('.navigation').addClass('store-nav');
  }

  updateCartItems();
})

updateCartItems = function() {
  $('.shopping-cart-line-item-quantity-input').each(function(){
    var $container = $(this).parents('.shopping-cart-cell');
    if ($(this).val() == "0" || $(this).val() == "" || $(this).val() == 0) {
      $container.remove();
      $(this).remove();
    }
  });
  $("[data-bundle-amount]").each(function() {
    var bundleAmount = parseInt($(this).attr("data-bundle-amount")), currentAmount = parseInt($(this).find("input").val()), $parent = $(this).parent();
    if (currentAmount >= bundleAmount && bundleAmount > 0) {
      $parent.find(".normal-price").addClass("strike");
      $parent.find(".bundle-price").removeClass("hidden");
    } else {
      $parent.find(".normal-price").removeClass("strike");
      $parent.find(".bundle-price").addClass("hidden");
    }
  });
}
