global = this
global.itemNameObserver = (url) ->
  $("#do_add_item #item_name").delayedObserver ->
    $.ajax {
      url: url,
      data: { item_name : $("#do_add_item #item_name").val() },
      type: "get",
      success: (data) ->
        $("#candidates").html(data) }, 0.3

