global = exports ? this
jQuery ($) ->
  $ ->
    $("#filter_account_id").bind "change", ->
      $.ajax {
        url: global.urls["entries_path"],
        type: "get",
        data: { filter_account_id: $("#filter_account_id > option:selected").val() }}

