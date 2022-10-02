$(document).ready(function() {

  let cloneTemplate = function(wrapper) {
    let template_node = wrapper.querySelector("template")
    let new_row = template_node.content.cloneNode(true)

    wrapper.querySelector(".infinite-rows").appendChild(new_row)
  }

  // On load, add a blank row
  $(".infinite-wrapper").each(function() {
    cloneTemplate(this)
  })

  $(document).on("keyup", ".infinite-wrapper .infinite-rows input", function() {
    let row = $(this)
    let wrapper = row.parents(".infinite-wrapper")
    let rows = wrapper.find(".infinite-row")
    let found_empty = rows.toArray().some(function(row) {
      // ANY row
      return Array.from(row.querySelectorAll("input")).every(function(input) {
        // Has ALL empty fields
        return input.value.trim() == ""
      })
    })

    if (found_empty) { return }

    cloneTemplate(wrapper[0])
  })
})
