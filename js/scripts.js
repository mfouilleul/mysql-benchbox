$(document).ready(function(){
	
	$("#searchInput").keyup(function() {
		$("#context").hide();
		$("#charts").hide();
		var rows = $("#files tbody").find("tr").hide();
		var data = this.value.split(" ");
		$.each(data, function(i, v) {
			rows.filter(":contains('" + v + "')").show();
		});
        });

	$(".filename").click(function(){
		getCharts($(this).closest('tr').attr("id"));
	});
});

function getCharts(filename){
	
	$.getJSON('./json/' + filename, function(json) {
		
		$("#context").show();
		
		$("#context_table > tbody").empty();
		$("#context_table > tbody").append("<tr><td>Name</td><td>" + json.info.name + "</td></tr>");
		$("#context_table > tbody").append("<tr><td>JSON</td><td>" + json.info.filename + "</td></tr>");
		$("#context_table > tbody").append("<tr><td>SysBench Version</td><td>" + json.info.sysbench + "</td></tr>");
		$("#context_table > tbody").append("<tr><td>Date</td><td>" + json.info.datetime + "</td></tr>");
		$("#context_table > tbody").append("<tr><td>Hostname</td><td>" + json.info.hostname + "</td></tr>");
		$("#context_table > tbody").append("<tr><td>Port</td><td>" + json.info.port + "</td></tr>");
		$("#context_table > tbody").append("<tr><td>Threads</td><td>" + json.info.threads.toString() + "</td></tr>");
		$("#context_table > tbody").append("<tr><td>Read Only</td><td>" + json.info.read_only + "</td></tr>");
		$("#context_table > tbody").append("<tr><td>Report Interval (in sec)</td><td>" + json.info.report_interval + "</td></tr>");
		$("#context_table > tbody").append("<tr><td>Max Time (in sec)</td><td>" + json.info.max_time + "</td></tr>");
		
        	var tps = document.getElementById("tps").getContext("2d");
		var rt = document.getElementById("rt").getContext("2d");
		var rds = document.getElementById("rds").getContext("2d");
		var wrs = document.getElementById("wrs").getContext("2d");
		
		var options = {
			pointDot : false,
		}
		
		// TPS
		var data_tps = {
			labels: json.info.threads,
			datasets: [ ]
		};
		
		// RDS
		var data_rds = {
			labels: json.info.threads,
			datasets: [ ]
		};
		
		// WRS
		var data_wrs = {
			labels: json.info.threads,
			datasets: [ ]
		};
		
		// RT
		var data_rt = {
			labels: json.info.threads,
			datasets: [ ]
		};
		
		// FULL
		for (v = 0; v < json.info.ckpts; v++) {
			// TPS
			data_tps.datasets[v] = {
				fillColor: "rgba(255,168,168,0.1)",
				strokeColor: "rgba(255,168,168,0.2)",
				pointStrokeColor: "#fff",
				pointHighlightFill: "#fff",
				pointHighlightStroke: "rgba(255,66,66,1)"
			};
			data_tps.datasets[v].label = v + 1;
			data_tps.datasets[v].data = [];
			$.each(json.info.threads, function( i, threads_value ) {
				var value = json.bench.tps[json.info.threads[i]].full[v];
				data_tps.datasets[v].data.push(value);
			});
			
			// RDS
			data_rds.datasets[v] = {
				fillColor: "rgba(142,199,255,0.1)",
				strokeColor: "rgba(142,199,255,0.2)",
				pointStrokeColor: "#fff",
				pointHighlightFill: "#fff",
				pointHighlightStroke: "rgba(40,148,255,1)"
			};
			data_rds.datasets[v].label = v + 1;
			data_rds.datasets[v].data = [];
			$.each(json.info.threads, function( i, threads_value ) {
				var value = json.bench.rds[json.info.threads[i]].full[v];
				data_rds.datasets[v].data.push(value);
			});
			
			// WRS
			data_wrs.datasets[v] = {
				fillColor: "rgba(75,215,134,0.1)",
				strokeColor: "rgba(75,215,134,0.2)",
				pointStrokeColor: "#fff",
				pointHighlightFill: "#fff",
				pointHighlightStroke: "rgba(30,132,173,1)"
			};
			data_wrs.datasets[v].label = v + 1;
			data_wrs.datasets[v].data = [];
			$.each(json.info.threads, function( i, threads_value ) {
				var value = json.bench.wrs[json.info.threads[i]].full[v];
				data_wrs.datasets[v].data.push(value);
			});
			// RT
			data_rt.datasets[v] = {
				fillColor: "rgba(252,215,95,0.1)",
				strokeColor: "rgba(252,215,95,0.2)",
				pointStrokeColor: "#fff",
				pointHighlightFill: "#fff",
				pointHighlightStroke: "rgba(214,165,5,1)"
			};
			data_rt.datasets[v].label = v + 1;
			data_rt.datasets[v].data = [];
			$.each(json.info.threads, function( i, threads_value ) {
				var value = json.bench.rt[json.info.threads[i]].full[v];
				data_rt.datasets[v].data.push(value);
			});
		}
		
		// AVG
		// TPS
		data_tps.datasets[v] = {
			fillColor: "rgba(255,168,168,0)",
			strokeColor: "rgba(255,168,168,1)",
			pointStrokeColor: "#fff",
			pointHighlightFill: "#fff",
			pointHighlightStroke: "rgba(255,66,66,1)"
		};
		data_tps.datasets[v].label = v + 1;
		data_tps.datasets[v].data = [];
		$.each(json.info.threads, function( i, threads_value ) {
			var value = json.bench.tps[json.info.threads[i]].avg;
			data_tps.datasets[v].data.push(value);
		});
		
		// RDS
		data_rds.datasets[v] = {
			fillColor: "rgba(142,199,255,0)",
			strokeColor: "rgba(142,199,255,1)",
			pointStrokeColor: "#fff",
			pointHighlightFill: "#fff",
			pointHighlightStroke: "rgba(40,148,255,1)"
		};
		data_rds.datasets[v].label = v + 1;
		data_rds.datasets[v].data = [];
		$.each(json.info.threads, function( i, threads_value ) {
			var value = json.bench.rds[json.info.threads[i]].avg;
			data_rds.datasets[v].data.push(value);
		});
		
		// WRS
		data_wrs.datasets[v] = {
			fillColor: "rgba(75,215,134,0)",
			strokeColor: "rgba(75,215,134,1)",
			pointStrokeColor: "#fff",
			pointHighlightFill: "#fff",
			pointHighlightStroke: "rgba(30,132,173,1)"
		};
		data_wrs.datasets[v].label = v + 1;
		data_wrs.datasets[v].data = [];
		$.each(json.info.threads, function( i, threads_value ) {
			var value = json.bench.wrs[json.info.threads[i]].avg;
			data_wrs.datasets[v].data.push(value);
		});
		// RT
		data_rt.datasets[v] = {
			fillColor: "rgba(252,215,95,0)",
			strokeColor: "rgba(252,215,95,1)",
			pointStrokeColor: "#fff",
			pointHighlightFill: "#fff",
			pointHighlightStroke: "rgba(214,165,5,1)"
		};
		data_rt.datasets[v].label = v + 1;
		data_rt.datasets[v].data = [];
		$.each(json.info.threads, function( i, threads_value ) {
			var value = json.bench.rt[json.info.threads[i]].avg;
			data_rt.datasets[v].data.push(value);
		});
			
		var myLineChart_tps = new Chart(tps).Line(data_tps, options);
		var myLineChart_rds = new Chart(rds).Line(data_rds, options);
		var myLineChart_wrs = new Chart(wrs).Line(data_wrs, options);
		var myLineChart_rt = new Chart(rt).Line(data_rt, options);
		
		$("#charts").show();
        });
	
}
