$ ->
  $("#monthlist #years a").click ->
    year = $(this).attr("href").replace("#", "")
    $(this).siblings().attr("class", "unselected")
    $(this).attr("class", "selected")
    $("#monthlist").children("div[id^='year_']").hide()
    $("#monthlist").children("div#" + year).show()
    false
