(function(window) {
    var selectedPlot = function(plot_id, choices_id, datasets) {
	var i = 0;
	jQuery.each(datasets, function(key, val) {
            val.color = i;
           ++i;
	});
	
	var choiceContainer = jQuery(choices_id);
	jQuery.each(datasets, function(key, val) {
            choiceContainer.append('<input type="checkbox" name="' + key +
				   '" checked="checked" id="id' + key + '">' +
				   '<label for="id' + key + '">'
                                   + val.label + '</label> ');
	});
	choiceContainer.find("input").click(plotAccordingToChoices);

	function plotAccordingToChoices() {
            var data = [];

            choiceContainer.find("input:checked").each(function () {
		var key = jQuery(this).attr("name");
		if (key && datasets[key])
                    data.push(datasets[key]);
            });

            if (data.length > 0) {
		jQuery.plot(jQuery(plot_id), data, {
                    xaxis: {
			mode: "time",
			timeformat: "%y/%m",
			tickSize: [1, "month"],
		    }
		});
	    }
	}

	plotAccordingToChoices();
    };

    var lineChart = function(plot_id, choices_id, data) {
	selectedPlot(plot_id, choices_id, data);
    };
    window.lineChart = lineChart;
})(window);


