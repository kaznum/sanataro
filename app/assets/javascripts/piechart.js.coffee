(($, that) ->
  $ ->
    pieChart = (id, data) ->
      series = data.length
      $.plot $(id), data, {
        legend: { show: true },
        grid: { hoverable: true },
        series: {
          pie: {
            show: true,
            innerRadius: 1/4,
            radius: 1,
            threshold: 0.05,
            label: {
              show: true,
              radius: 2/3,
              formatter: (label, series) ->
                '<div style="font-size:8pt;text-align:center;padding:1px;color:white;">'+label+'<br/>'+Math.round(series.percent)+'%</div>' }}}}
      $(id).bind "plothover", (event, pos, obj) ->
        if !obj
          return
        percent = parseFloat(obj.series.percent).toFixed(0)
        $(id + "_hover").html '<span style="font-weight: bold; color: '+obj.series.color+'">'+obj.series.label+' ('+percent+'%)</span>'

    that.pieChart = pieChart
)(jQuery, this)
