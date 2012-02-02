(function(window) {
    var elementId, chartData;
    
    var pieChart = function(id, data) {
        $(function () {
            var series = data.length;
            $.plot($(id), data, {
                series: {
                    pie: { 
                        show: true,
			innerRadius: 1/4,
                        radius: 1,
                        label: {
                            show: true,
                            radius: 2/3,
                            formatter: function(label, series){
				return '<div style="font-size:8pt;text-align:center;padding:1px;color:white;">'+label+'<br/>'+Math.round(series.percent)+'%</div>';
                            },
			    threshold: 0.05
                        }
                    }
                },
                legend: { show: true },
		grid: { hoverable: true }
            });
	    $(id).bind("plothover", function(event, pos, obj) {
		
		if (!obj) { return; }
		var percent = parseFloat(obj.series.percent).toFixed(0);
		$(id + "_hover").html('<span style="font-weight: bold; color: '+obj.series.color+'">'+obj.series.label+' ('+percent+'%)</span>');
	    });
        });
    }
    
    window.pieChart = pieChart;
})(window);
