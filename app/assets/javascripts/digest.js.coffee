(($) ->
  $ ->
   $(".digest_link").click ->
      $.ajax({
        url: $(this).attr("href"),
        cache: false,
        success: ->
          $("#digest_modal").removeAttr("style").modal()})
      false
) jQuery