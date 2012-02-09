global = this
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
