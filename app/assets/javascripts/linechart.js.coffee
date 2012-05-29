$ ->
  ((global) ->
    selectedPlot = (plot_id, choices_id, datasets) ->
  	  i = 0
  	  $.each datasets, (key, val) ->
        val.color = i
        ++i

  	  plotAccordingToChoices = ->
        data = []
        choiceContainer.find("input:checked[rel!=all]").each ->
          key = $(this).attr "name"
          if key && datasets[key]
            data.push datasets[key]

        $.plot $(plot_id), data, {
          xaxis: {
            mode: "time",
            timeformat: "%y/%m",
            tickSize: [1, "month"]}}

      choiceContainer = $(choices_id).attr("class", "form-inline")
      all_check_id = "all_" + choices_id.replace(/#/gi,'')
      check_prefix = "id" + choices_id.replace(/#/gi,'')
      choiceContainer.append '<label class="checkbox" for="' + all_check_id + '"><input type="checkbox" id="' + all_check_id + '" checked="checked" rel="all">ALL</label> '

      $.each datasets, (key, val) ->
        id = check_prefix + key
        choiceContainer.append '<label class="checkbox" for="' + id + '"><input type="checkbox" name="' + key + '" checked="checked" id="' + id + '">' + val.label + '</label> '

  	  choiceContainer.find("input[rel!=all]").bind "change", plotAccordingToChoices
  	  choiceContainer.find("input[rel=all]").bind "change", ->
        checked = $(this).attr("checked")
        choiceContainer.find("input[rel!=all]").each ->
          if checked == "checked"
            $(this).attr "checked", true
          else
            $(this).removeAttr "checked"
        plotAccordingToChoices()

    	plotAccordingToChoices()

    lineChart = (plot_id, choices_id, data) ->
      selectedPlot plot_id, choices_id, data

    global.lineChart = lineChart
  ) window

