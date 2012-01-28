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

