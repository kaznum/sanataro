$ ->
  bindAccountFilter = (global) ->
    $("#filter_account_id").bind "change", ->
      $.ajax {
        url: global.urls["entries"],
        type: "get",
        data: { filter_account_id: $("#filter_account_id > option:selected").val() }}
  bindAccountFilter(document)

