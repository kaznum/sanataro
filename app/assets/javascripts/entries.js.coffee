//= require toggle_confirmation_required
//= require_self

((global) ->
  global.itemNameObserver = (url) ->
    $("#do_add_item #item_name").delayedObserver ->
      $.ajax {
        url: url,
        data: { item_name : $("#do_add_item #item_name").val() },
        type: "get",
        success: (data) ->
          $("#candidates").html(data) }, 0.3

  global.bindSubmitInNewSimple = () ->
    $(() ->
      $("#do_add_item").bind("submit", () ->
        $('#new_add_button').attr('disabled', 'disabled')
        $.ajax({
          url:'/entries',
          type:'post',
          success: (data) -> $('#new_add_button').removeAttr('disabled'),
          data: $("#do_add_item").serialize()})
        false))

  global.toggleConfirmationRequired = (isRequired, item_id = null) ->
    if item_id
      label_selector = "#confirmation_required_label_" + item_id
      field_selector = "#confirmation_required_" + item_id
    else
      label_selector = "#confirmation_required_label"
      field_selector = "#confirmation_required"
    if isRequired
      $(label_selector).html("<i class='icon-star'></i>").attr "class", "item_confirmation_required"
      $(field_selector).attr "value", "true"
    else
      $(label_selector).html("<i class='icon-star-empty'></i>").attr "class", "item_confirmation_not_required"
      $(field_selector).attr "value", "false"
) this

jQuery ($) ->
  trim = (str) ->
    str.replace /^\s+|\s+$/g, ""
  $("form.navbar-search").submit ->
    action = $(this).attr("action")
    queryElement = $(this).find(".search-query")

    return false if queryElement.val().match(/^[.\s]*$/)

    encKeyword = trim queryElement.val()
    # if "." exists, replaced with a space and trim again.
    encKeyword = trim encodeURIComponent(encKeyword).replace(/\./g, " ")
    return false if encKeyword == ""

    location.href = action.replace("KEYWORD_PLACEHOLDER", encKeyword)
    return false

  $("form.navbar-search .icon-search").click ->
    $(this).parent("form.navbar-search").submit()

  $("#items").on "click", ".item_date, .item_name, .item_from, .item_to, .item_amount", ->
    edit_link = $(this).parent(".item").find("a.edit_link")
    show_link = $(this).parent(".item").find("a.show_link")
    if edit_link.length > 0
      url = edit_link.attr("href")
      $.ajax({ url: url, method: "get" })
    else if show_link.length > 0
      url = show_link.attr("href")
      location.href = url

