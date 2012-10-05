(($) ->
  $ ->
    $(".monthlist .years a").click ->
      year = $(this).attr("href").replace("#", "")
      $(this).siblings().attr("class", "unselected")
      $(this).attr("class", "selected")
      parent_monthlist = $(this).parents(".monthlist")
      parent_monthlist.children("div[class^='year_']").hide()
      parent_monthlist.children("div[class=#{year}]").show()
      false
) jQuery
