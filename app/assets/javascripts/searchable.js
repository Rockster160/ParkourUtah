(function ( $ ) {
  var unique_searchable_id = 0;
  var dropdownMaxValues = 10, keyEventUp = 38, keyEventDown = 40, keyEventEnter = 13, keyEventEsc = 27;

  $(document).on('mousedown', function(e) {
    // Delegate clicks on the Dropdown Options since they are generated elements
    // Selects the current option.
    $target = $(e.target);
    $option = $target.hasClass('searchable-dropdown-option-wrapper') ? $target : $(e.target).parents('.searchable-dropdown-option-wrapper');
    if ($option.length > 0) {
      $('[data-uniq-searchable-id=' + $option.attr("data-option-for") + ']').trigger('selected-option', $option.attr('data-selected-value'));
    }
  }).on('mouseenter', '.searchable-dropdown-option-wrapper', function() {
    // Delegate hover over Dropdown Options
    // Add a class while being hover to only the object being hovered.
    $('.searchable-dropdown-option-wrapper').removeClass('searchable-toSelect');
    $(this).addClass('searchable-toSelect');
  }).on('keyup', function() {
    $('.searchable-dropdown-menu').remove();
  })

  $.fn.searchable = function(options) {
    options = options || {}
    var max_dropdown_values = options["max_dropdown_values"] || dropdownMaxValues,
        optionsList = options["optionsList"] || {},
        inputHasChanged = true,
        getOptionsFromUrl = options["getOptionsFromUrl"] || null,
        storeUrlOptions = options["storeUrlOptions"] || false,
        arrayOfOptionsFromUrlResponse = options["arrayOfOptionsFromUrlResponse"] || function(data) { throw "Must define how to retrieve the array of options from the endpoint with `arrayOfOptionsFromUrlResponse`" },
        valueFromOption = options["valueFromOption"] || function(option) { throw "Must define how to retrieve the desired return value with `valueFromOption`" },
        buildInnerOptionFromTemplate = options["templateFromOption"] || function(option) { throw "Must define a template to display each option with `templateFromOption`" },
        optionSelectedCallback = options["optionSelected"] || function(field, option, option_value) { console.log("Option Selected, but no callback has been defined. Define as: `function(field, option, option_value)`"); },
        afterSelectedCallback = options["afterSelected"] || function(field, option, option_value) {};

    $(this).each(function() {
      var $searchableField = $(this), current_uniq_id = unique_searchable_id, paramKey = options["paramKey"] || $searchableField.attr("name") || "q";
      unique_searchable_id += 1;

      $searchableField.attr("data-uniq-searchable-id", current_uniq_id);
      $searchableField.attr("autocorrect", "false");
      $searchableField.attr("autocomplete", "false");
      $searchableField.attr("autocapitalize", "false");

      $searchableField.on('keydown', function(e) {
        // Have to use `keydown` to detect arrow keys properly
        // User Navigation using arrow keys
        if (e.which === keyEventUp || e.which === keyEventDown) {
          e.preventDefault();
          if (e.which === keyEventUp) { // up
            var next_option = $('.searchable-dropdown-option-wrapper.searchable-toSelect').prev();
          } else { // down
            var next_option = $('.searchable-dropdown-option-wrapper.searchable-toSelect + .searchable-dropdown-option-wrapper');
          }
          if (next_option.length > 0) {
            $('.searchable-dropdown-option-wrapper.searchable-toSelect').removeClass('searchable-toSelect');
            next_option.addClass('searchable-toSelect');
          }
        }
        // Select the option if the Enter key is pressed.
        if (e.which === keyEventEnter) {
          e.preventDefault();
          var first_option = $('.searchable-dropdown-option-wrapper.searchable-toSelect').first();
          selectOption(first_option);
          return false;
        }
      }).on('keyup', function(e) {
        // If a user clicks any key, update the dropdown options with the new entered value.
        if (e.which != keyEventEsc) {
          if ($.inArray(e.which, [keyEventUp, keyEventDown, keyEventEnter]) == -1) {
            inputHasChanged = true;
          }
          if (!(e.which === keyEventUp || e.which === keyEventDown)) {
            populateDropdownFromInput();
          }
        }
      }).on('focus', function() {
        // Automatically populate the dropdown when it is focused.
        populateDropdownFromInput();
      }).on('blur', function() {
        // When the dropdown loses focus, get rid of the dropdown.
        hideDropdowns();
      }).on('selected-option', function(evt, optionVal) {
        var option = $('.searchable-dropdown-option-wrapper[data-selected-value="' + optionVal + '"]');
        selectOption(option);
      })

      var hideDropdowns = function() {
        $('.searchable-dropdown-menu').remove();
      }

      var findOptionsFromSearchString = function(search_string)  {
        var validOptions = optionsList;

        if (getOptionsFromUrl) {
          if ((storeUrlOptions || !inputHasChanged) && Object.keys(validOptions).length > 0) {
            populateDropdownWithOptions(validOptions);
          } else {
            findOptionsByFuzzyTextUrl($searchableField.val());
          }
        } else {
          var foundOptions = [], foundCount = 0;

          search_string = search_string.toLowerCase();
          $(validOptions).each(function(idx, ele) {
            if (!$.isEmptyObject(ele)) {
              var optionText = ele.text, optionVal = ele.value.toLowerCase(), string_valid = true;
              if (foundCount < dropdownMaxValues) {
                $(search_string.split('')).each(function() {
                  var char_index = optionText.indexOf(ele);
                  if (char_index < 0 || !string_valid) {
                    string_valid = false;
                  }
                })
                if (string_valid) {
                  foundCount += 1;
                  foundOptions.push(ele);
                }
              }
            }
          })
          populateDropdownWithOptions(foundOptions);
        }
      }

      var showOptionsInSearchableDropdown = function(options) {
        hideDropdowns();
        var drop_down = $('<div/>').addClass("searchable-dropdown-menu").attr('data-searching-for', $searchableField.attr("data-uniq-searchable-id"));
        $(options).each(function(idx, ele) {
          var optionVal = valueFromOption(ele).toString().toLowerCase();
          var dropdown_option = $(
            '<div class="searchable-dropdown-option-wrapper" data-selected-value="' + optionVal + '" data-option-for=' + $searchableField.attr("data-uniq-searchable-id") + '>' +
            buildInnerOptionFromTemplate(ele) +
            '</div>'
          );
          drop_down.append(dropdown_option);
        });

        var offset = $searchableField.offset();
        var posY = offset.top - $(window).scrollTop() + $searchableField.outerHeight(true);
        var posX = offset.left - $(window).scrollLeft();
        drop_down.css({'top':  posY, 'left': posX, 'width': $searchableField.outerWidth(true)})
        if (Object.keys(options).length > 0) { $('body').append(drop_down); }
      }

      var populateDropdownFromInput = function() {
        findOptionsFromSearchString($searchableField.val());
      }

      var populateDropdownWithOptions = function(options) {
        options = options || [];
        inputHasChanged = false;
        showOptionsInSearchableDropdown(options);
        $('.searchable-dropdown-option-wrapper').first().addClass('searchable-toSelect');
      }

      var selectOption = function(searchable_dropdown_element) {
        var option_value = $(searchable_dropdown_element).attr("data-selected-value");
        optionSelectedCallback($searchableField, searchable_dropdown_element.html(), option_value);
        afterSelectedCallback($searchableField, searchable_dropdown_element.html(), option_value);
        $searchableField.blur();
      }

      var findOptionsByFuzzyTextUrl = function() {
        var params = {}
        params[paramKey] = $searchableField.val();

        displayLoadingContainerForDropdown();

        $.get(getOptionsFromUrl, params).success(function(data) {
          hideDropdowns();
          var arrayResponse = arrayOfOptionsFromUrlResponse(data) || [];
          optionsList = arrayResponse.slice(0, max_dropdown_values);
          populateDropdownWithOptions(optionsList)
        })
      }

      var displayLoadingContainerForDropdown = function() {
        var drop_down = $('<div/>').addClass("searchable-dropdown-menu").attr('data-searching-for', $searchableField.attr("data-uniq-searchable-id"));
        var loading_container = $('<div/>', {style: "text-align: center;", class: "searchable-loading-container"}).html("Loading...")
        drop_down.append(loading_container);
        var offset = $searchableField.offset();
        var posY = offset.top - $(window).scrollTop() + $searchableField.outerHeight(true);
        var posX = offset.left - $(window).scrollLeft();
        drop_down.css({'top':  posY, 'left': posX, 'width': $searchableField.outerWidth(true)})
        $('body').append(drop_down);
      }
    })
  }

  $.fn.searchableFromSelect = function(options) {
    options = options || {}
    var placeholder = options["placeholder"] || "Search"

    $(this).each(function() {

      var dropdown = this, dropdown_uniq_searchable_id = unique_searchable_id;

      var search_field = $('<input>', {
        type: "text",
        name: "dropdown-searchable-field-" + dropdown_uniq_searchable_id,
        "data-uniq-searchable-id": dropdown_uniq_searchable_id,
        placeholder: placeholder,
        class: "dropdown-searchable-generated-text-field dropdown-searchable-field-" + dropdown_uniq_searchable_id + ' ' + options["additional_classes"]
      })
      search_field.insertAfter(dropdown);

      var getOptionsFromSelect = function() {
        var options_to_return = []
        $(dropdown).children('option').each(function() {
          if ($(this).html().length > 0 && $(this).val().length > 0 && !$(this).disabled) {
            options_to_return.push({
              text: $(this).html(),
              value: $(this).val()
            })
          }
        })
        return options_to_return
      }

      search_field.searchable({
        optionsList: getOptionsFromSelect(),
        valueFromOption: function(option) {
          return option.value;
        },
        templateFromOption: function(option) {
          return '<div class="searchable-dropdown-option">' + option.text + '</div>';
        },
        optionSelected: function(field, option, option_value) {
          if (option_value) {
            var option = $(dropdown).find('option[value=' + option_value + ']');
            $(option).prop('selected', true);
            $(option).parents('select').change();
            search_field.val('');
          }
        }
      })
    })
  }
}( jQuery ));
