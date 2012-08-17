(($, doc) ->
  $ ->
    $("#filter_account_id").bind "change", ->
      $.ajax {
        url: doc.urls["entries"],
        type: "get",
        data: { filter_account_id: $("#filter_account_id > option:selected").val() }}
) jQuery, document
