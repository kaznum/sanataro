global = this
toggleColorPicker = (account_id) ->
  if $("#use_bgcolor_" + account_id + ":checked").val() == '1'
    $("#colorpicker_" + account_id).show()
  else
    $("#colorpicker_" + account_id).hide()

  $("#use_bgcolor_" + account_id).bind "change", () ->
    toggleColorPicker account_id
global.toggleColorPicker = toggleColorPicker



