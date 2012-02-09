global = this
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
    $(label_selector).text("★").attr "class", "item_confirmation_required"
    $(field_selector).attr "value", "true"
  else
    $(label_selector).text("☆").attr "class", "item_confirmation_not_required"
    $(field_selector).attr "value", "false"
