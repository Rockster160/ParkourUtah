var revealElement = function(element) {
  element.removeClass("hidden").prop("disabled", false)
  element.find(":not(:hidden) select:not(.hidden), :not(:hidden) input:not(.hidden), :not(:hidden) textarea:not(.hidden)").prop("disabled", false)
  element.children("select:not(.hidden), input:not(.hidden), textarea:not(.hidden)").prop("disabled", false)
}

var hideElement = function(element) {
  element.addClass("hidden").find("select, input, textarea").andSelf().prop("disabled", true)
}
