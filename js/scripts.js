$(document).ready(function(){
	
	$(".filename").click(function(){
		oneFile($(this).closest('tr').attr("id"));
	});
	
	$("input[type=checkbox]").on( "click", function(){
		var filenames = [];
		$("input:checked").each(function(){
			filenames.push($(this).closest('tr').attr("id"));
		});
		someFiles(filenames);
	});
	
});

function oneFile(filename){
	
	$.getJSON('./json/' + filename, function(json) {
		
        	var tps = document.getElementById("tps").getContext("2d");
		var rt = document.getElementById("rt").getContext("2d");
		var rds = document.getElementById("rds").getContext("2d");
		var wrs = document.getElementById("wrs").getContext("2d");
		
		if(json.info.name){
			label = json.info.name
		}else{
			label = json.info.filename
		}
		
		var dataset_red = {
			fillColor: "rgba(255,168,168,0.2)",
			strokeColor: "rgba(255,168,168,1)",
			pointColor: "rgba(255,91,91,1)",
			pointStrokeColor: "#fff",
			pointHighlightFill: "#fff",
			pointHighlightStroke: "rgba(255,66,66,1)"
		};
		var dataset_blue = {
			fillColor: "rgba(142,199,255,0.2)",
			strokeColor: "rgba(142,199,255,1)",
			pointColor: "rgba(91,173,255,1)",
			pointStrokeColor: "#fff",
			pointHighlightFill: "#fff",
			pointHighlightStroke: "rgba(40,148,255,1)"
		};
		var dataset_green = {
			fillColor: "rgba(75,215,134,0.2)",
			strokeColor: "rgba(75,215,134,1)",
			pointColor: "rgba(39,174,96,1)",
			pointStrokeColor: "#fff",
			pointHighlightFill: "#fff",
			pointHighlightStroke: "rgba(30,132,173,1)"
		};
		var dataset_yellow = {
			fillColor: "rgba(252,215,95,0.2)",
			strokeColor: "rgba(252,215,95,1)",
			pointColor: "rgba(250,196,20,1)",
			pointStrokeColor: "#fff",
			pointHighlightFill: "#fff",
			pointHighlightStroke: "rgba(214,165,5,1)"
		};
		
		var data = {
			labels: json.info.threads,
			datasets: [ ]
		};
		
		var options = { }
		
		data.datasets[0] = dataset_red;
		data.datasets[0].label = label;
		data.datasets[0].data = json.bench.tps;
		var myLineChart_tps = new Chart(tps).Line(data, options);
		
		data.datasets[0] = dataset_blue;
		data.datasets[0].label = label;
		data.datasets[0].data = json.bench.rt;
		var myLineChart_rt = new Chart(rt).Line(data, options);
		
		data.datasets[0] = dataset_green;
		data.datasets[0].label = label;
		data.datasets[0].data = json.bench.rds;
		var myLineChart_rds = new Chart(rds).Line(data, options);
		
		data.datasets[0] = dataset_yellow;
		data.datasets[0].label = label;
		data.datasets[0].data = json.bench.wrs;
		var myLineChart_wrs = new Chart(wrs).Line(data, options);
		
		$("#charts").show();
        });
	
}
