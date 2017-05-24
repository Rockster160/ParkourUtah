/*
Instructions for use:

$('.selector').searchable({
  getOptionsFromUrl: "/scoped/my_objects", // URL in which to send query string to retrieve results
  arrayOfOptionsFromUrlResponse: function(data) {
    return data; // Any data manipulation or unwrapping to return the ARRAY of object to be used from the API call
  },
  templateFromOption: function(selected_obj) {
      // An HTML-safe template built from the data
    return '<div><strong>' +
    selected_obj.name +
    '</strong><span class="pull-right">' +
    selected_obj.id +
    '</span></br>' +
    selected_obj.parent.name +
    '</div>';
  }
}).on("searchable:selected", function(evt, selected_obj) {
    // Callback to handle the clicked action
  window.location.href = "/scoped/my_objects/" + selected_obj.id;
});

$('.selector').searchableFromSelect()

*/

(function ( $ ) {
  var unique_searchable_id = 0, current_searchable_request = undefined;
  var dropdownMaxValues = 10, keyEventUp = 38, keyEventDown = 40, keyEventEnter = 13, keyEventEsc = 27;

  var encodeObjToStr = function(obj) {
    return encodeURIComponent(JSON.stringify(obj));
  }

  var decodeStrToObj = function(str) {
    return JSON.parse(decodeURIComponent(str));
  }

  var repositionSearchableMenu = function(dropdown) {
    if (dropdown == undefined) {
      $('.js-searchable-menu').each(function() {
        repositionSearchableMenu(this)
      })
    } else {
      $menu = $(dropdown);
      var searchable_id = $menu.attr("data-searching-for");
      $searchableField = $('[data-uniq-searchable-id=' + searchable_id + ']');

      var offset = $searchableField.position();
      var posY = offset.top + $searchableField.outerHeight(true);
      var posX = offset.left;
      if (!isUsingiOSDevice() && $searchableField.is(":focus")) {
        posY -= $(window).scrollTop();
        posX -= $(window).scrollLeft();
      }
      $menu.css({'top':  posY, 'left': posX, 'width': $searchableField.outerWidth(true)})
    }
  }

  var isUsingiOSDevice = function() {
    var user_agent = (navigator.userAgent||navigator.vendor||window.opera);
    return user_agent.match(/(ip(hone|od|ad))/i)
  }
  var isUsingMobileDevice = function() {
    var user_agent = (navigator.userAgent||navigator.vendor||window.opera);
    var mobile_user_agent_regexp = /(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino/i
    var mobile_vendor_regexp = /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i;
    return mobile_user_agent_regexp.test(user_agent) || mobile_vendor_regexp.test(user_agent.substr(0,4));
  };

  $(window).on("scroll resize", function() {
    repositionSearchableMenu();
  })

  $(document).on('mousedown touchend', function(e) {
    // Delegate clicks on the Dropdown Options since they are generated elements
    // Selects the current option.
    $target = $(e.target);
    $option = $target.hasClass('js-searchable-option-wrapper') ? $target : $(e.target).parents('.js-searchable-option-wrapper');
    if ($option.length > 0) {
      var option_obj = decodeStrToObj($option.attr('data-json'));
      $('[data-uniq-searchable-id=' + $option.attr("data-option-for") + ']').trigger('selected-option', option_obj);
    }
  }).on('mouseenter touchstart', '.js-searchable-option-wrapper', function() {
    // Delegate hover over Dropdown Options
    // Add a class while being hover to only the object being hovered.
    $('.js-searchable-option-wrapper').removeClass('searchable-toSelect');
    $(this).addClass('searchable-toSelect');
  })

  $.fn.searchable = function(options) {
    options = options || {}
    var max_dropdown_values = options["max_dropdown_values"] || dropdownMaxValues,
        optionsList = options["optionsList"] || {},
        inputHasChanged = true,
        getOptionsFromUrl = options["getOptionsFromUrl"] || null,
        storeUrlOptions = options["storeUrlOptions"] || false,
        arrayOfOptionsFromUrlResponse = options["arrayOfOptionsFromUrlResponse"] || function(data) { throw "Must define how to retrieve the array of options from the endpoint with `arrayOfOptionsFromUrlResponse`" },
        buildInnerOptionFromTemplate = options["templateFromOption"] || function(option) { throw "Must define a template to display each option with `templateFromOption`" };

    $(this).each(function() {
      var $searchableField = $(this), current_uniq_id = unique_searchable_id, paramKey = options["paramKey"] || $searchableField.attr("name") || "q";
      unique_searchable_id += 1;

      $searchableField.attr("data-uniq-searchable-id", current_uniq_id);
      $searchableField.attr("autocorrect", "off");
      $searchableField.attr("autocomplete", "off");
      $searchableField.attr("autocapitalize", "off");

      $searchableField.on('keydown', function(e) {
        // Have to use `keydown` to detect arrow keys properly
        // User Navigation using arrow keys
        if (e.which === keyEventUp || e.which === keyEventDown) {
          e.preventDefault();
          if (e.which === keyEventUp) { // up
            var next_option = $('.js-searchable-option-wrapper.searchable-toSelect').prev();
          } else { // down
            var next_option = $('.js-searchable-option-wrapper.searchable-toSelect + .js-searchable-option-wrapper');
          }
          if (next_option.length > 0) {
            $('.js-searchable-option-wrapper.searchable-toSelect').removeClass('searchable-toSelect');
            next_option.addClass('searchable-toSelect');
          }
        }
        // Select the option if the Enter key is pressed.
        if (e.which === keyEventEnter) {
          e.preventDefault();
          var first_option = $('.js-searchable-option-wrapper.searchable-toSelect').first();
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
        if (current_searchable_request) {
          current_searchable_request.abort();
          current_searchable_request = undefined;
        }
        hideDropdowns();
      }).on('selected-option', function(evt, optionVal) {
        var option_str = encodeObjToStr(optionVal);
        var $option = $('.js-searchable-option-wrapper[data-json="' + option_str + '"]');
        $('.js-searchable-option-wrapper').removeClass('searchable-toSelect');
        $($option).addClass('searchable-toSelect');
        setTimeout(function() {
          selectOption($option);
        }, 10);
      })

      var hideDropdowns = function() {
        $('.fix-virtual-keyboard-position-offset').removeClass('.fix-virtual-keyboard-position-offset');
        $('.js-searchable-menu').remove();
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
              var optionText = ele.text.toLowerCase(), optionVal = ele.value.toLowerCase(), string_valid = true;
              if (foundCount < dropdownMaxValues) {
                $(search_string.split('')).each(function() {
                  var char_index = optionText.indexOf(this);
                  if (char_index < 0) {
                    string_valid = false;
                  } else {
                    optionText = optionText.substr(char_index + 1);
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
        var drop_down = $('<div/>').addClass("js-searchable-menu").attr('data-searching-for', $searchableField.attr("data-uniq-searchable-id"));
        $(options).each(function(idx, ele) {
          var dropdown_option = $(
            '<div class="js-searchable-option-wrapper" data-option-for=' + $searchableField.attr("data-uniq-searchable-id") + '>' +
            buildInnerOptionFromTemplate(ele) +
            '</div>'
          );
          dropdown_option.attr("data-json", encodeObjToStr(ele));
          drop_down.append(dropdown_option);
        });

        repositionSearchableMenu(drop_down);
        if (Object.keys(options).length > 0) { $('body').append(drop_down); }
      }

      var populateDropdownFromInput = function() {
        findOptionsFromSearchString($searchableField.val());
      }

      var populateDropdownWithOptions = function(options) {
        options = options || [];
        inputHasChanged = false;
        showOptionsInSearchableDropdown(options);
        $('.js-searchable-option-wrapper').first().addClass('searchable-toSelect');
      }

      var equalValues = function(obj, other_obj) {
        var obj_type = $.type(obj), other_obj_type = $.type(other_obj);
        if (obj_type != other_obj_type) { return false; }

        var does_match = true;
        if (obj_type == "object") {
          if (!equalDictionary(obj, other_obj)) {
            return does_match = false;
          }
        } else if (obj_type == "array") {
          if (!equalArray(obj, other_obj)) {
            return does_match = false;
          }
        } else {
          if (obj != other_obj) {
            return does_match = false;
          }
        }
        return does_match;
      }

      var equalArray = function(obj, other_obj) {
        if (obj.length != other_obj.length) { return false; }

        var does_match = true;
        $(obj).each(function(idx) {
          if (!equalValues(obj[idx], other_obj[idx])) {
            does_match = false;
          }
        })
        return does_match;
      }

      var equalDictionary = function(obj, other_obj) {
        var obj_keys = Object.keys(obj), other_obj_keys = Object.keys(other_obj);
        if (obj_keys.length != other_obj_keys.length) { return false; }

        var does_match = true;
        $(obj_keys).each(function() {
          if (!equalValues(obj[this], other_obj[this])) {
            return does_match = false;
          }
        })
        return does_match;
      }

      var selectOption = function(searchable_dropdown_element) {
        var option_value = $(searchable_dropdown_element).attr("data-json"), selected_option;
        $(optionsList).each(function() {
          if (equalValues(this, decodeStrToObj(option_value))) {
            selected_option = this;
            return;
          }
        })
        $searchableField.trigger('searchable:selected', selected_option);
        $searchableField.blur();
      }

      var findOptionsByFuzzyTextUrl = function() {
        var params = {}
        params[paramKey] = $searchableField.val();

        displayLoadingContainerForDropdown();

        if (current_searchable_request != undefined) {
          current_searchable_request.abort();
        }
        current_searchable_request = $.get(getOptionsFromUrl, params).success(function(data) {
          hideDropdowns();
          var arrayResponse = arrayOfOptionsFromUrlResponse(data) || [];
          optionsList = arrayResponse.slice(0, max_dropdown_values);
          populateDropdownWithOptions(optionsList)
        }).complete(function() {
          current_searchable_request = undefined;
        })
      }

      var displayLoadingContainerForDropdown = function() {
        hideDropdowns();
        var drop_down = $('<div/>').addClass("js-searchable-menu").attr('data-searching-for', $searchableField.attr("data-uniq-searchable-id"));
        var loading_container = $('<div/>', {style: "text-align: center;", class: "searchable-loading-container"}).html("Loading...")
        drop_down.append(loading_container);
        repositionSearchableMenu(drop_down);
        $('body').append(drop_down);
      }
    })
    return this;
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
        class: "dropdown-searchable-generated-text-field dropdown-searchable-field-" + dropdown_uniq_searchable_id + ' ' + options["additional_classes"],
        width: $(this).outerWidth()
      })
      search_field.insertAfter(dropdown);

      var getOptionsFromSelect = function() {
        var options_to_return = []
        $(dropdown).children('option').each(function() {
          if ($(this).html().length > 0 && $(this).val().length > 0 && !this.disabled) {
            options_to_return.push(Object.assign({
              text: $(this).html(),
              value: $(this).val()
            }, $(this).data()));
          }
        })
        return options_to_return
      }

      search_field.searchable({
        optionsList: getOptionsFromSelect(),
        templateFromOption: function(option) {
          return options.templateFromOption(option) || '<div>' + option.text + '</div>';
        }
      }).on("searchable:selected", function(evt, selected_option) {
        if (selected_option.value) {
          var option = $(dropdown).find('option[value=' + selected_option.value + ']');
          $(option).prop('selected', true);
          $(option).parents('select').change();
          if (!options.retainFieldValueAfterSelect) {
            search_field.val('');
          }
        }
      })
    })
    return this;
  }
}( jQuery ));
