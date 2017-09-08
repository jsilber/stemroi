function generateChart(data, chart_id, y_title, pre_chart_title, selected_id, post_chart_title) {
    //Clear SVG canvas before drawing (in case user reselects )
    //https://stackoverflow.com/questions/29758385/clear-d3-js-charts-before-loading-new-chart

    d3.select(chart_id).selectAll("svg").remove();

    // set the dimensions and margins of the graph
    var margin = {top: 50, right: 20, bottom: 10, left: 80},
        width = $("#d3chartstable").width()-30 - margin.left - margin.right,
        height = 200 - margin.top - margin.bottom;

    // set the ranges
    var x = d3.scaleBand()
              .range([0, width])
              .padding(0.1);
    var y = d3.scaleLinear()
              .range([height, 0]);

    //Create custom tooltips based on this example: http://bl.ocks.org/Caged/6476579
    //Wrap text: https://groups.google.com/forum/?fromgroups=#!topic/d3-js/GgFTf24ltjc
    var tip = d3.tip()
        .attr('class', 'd3-tip')
        .offset([-10, 0])
        .html(function(d) {
            // If chart_id == "#jobs_chart" or chart_id == "#tuition_chart"
            if (chart_id == "#tuition_chart") {
                return "<strong>University:</strong> <span style='color:white'>" + d.university_name + "</span><br>" +
                    "<strong>Tuition: </strong> <span style='color:lightblue'>" + "$" + d.tuition + "</span><br>" +
                    "<strong>Estimated: </strong> <span style='color:white'>" + d.estimate + "</span>";
            } else if (chart_id == "#jobs_chart") {
                return "<strong>State:</strong> <span style='color:white'>" + d.area_name + "</span><br>" +
                    "<strong>Projected Job Openings (2014): </strong> <span style='color:lightblue'>" + d.jobs + "</span>";
            }
        });

    // append the svg object to the body of the page
    // append a 'group' element to 'svg'
    // moves the 'group' element to the top left margin
    var svg = d3.select(chart_id).append("svg")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
      .append("g")
        .attr("transform",
              "translate(" + margin.left + "," + margin.top + ")");

    svg.call(tip);

    // Scale the range of the data in the domains based on chart_id
    if (chart_id == "#tuition_chart") {
        x.domain(data.map(function(d) { return d.university_name; }));
        y.domain([0, d3.max(data, function(d) { return d.tuition; })]);
        // append the rectangles for the bar chart
        svg.selectAll(".bar")
            .data(data)
            .enter().append("rect")
              .attr("class", "bar")
              .attr("x", function(d) { return x(d.university_name); })
              .attr("width", x.bandwidth())
              .attr("y", function(d) { return y(d.tuition); })
              .attr("height", function(d) { return height - y(d.tuition); })
              .on('mouseover', tip.show)
              .on('mouseout', tip.hide);
    } else if (chart_id == "#jobs_chart") {
        x.domain(data.map(function(d) { return d.area_name; }));
        y.domain([0, d3.max(data, function(d) { return d.jobs; })]);
        // append the rectangles for the bar chart
        svg.selectAll(".bar")
            .data(data)
            .enter().append("rect")
              .attr("class", "bar")
              .attr("x", function(d) { return x(d.area_name); })
              .attr("width", x.bandwidth())
              .attr("y", function(d) { return y(d.jobs); })
              .attr("height", function(d) { return height - y(d.jobs); })
              .on('mouseover', tip.show)
              .on('mouseout', tip.hide);
    }

    // add the x Axis
    svg.append("g")
        .attr("transform", "translate(0," + height + ")")
        .call(d3.axisBottom(x))
        //Removes the university name text on x-axis after axis is created. //https://stackoverflow.com/questions/19787925/create-a-d3-axis-without-tick-labels
        .selectAll("text").remove();

    // add the y Axis
    svg.append("g")
        .call(d3.axisLeft(y));
    svg.append("text")
        .attr("transform", "rotate(-90)")
        .attr("y", 0 - margin.left)
        .attr("x",0 - (height / 2))
        .attr("dy", "2em")
        .style("text-anchor", "middle")
        .text(y_title);
    svg.append("text")
        .attr("x", (width / 2))
        .attr("y", 0 - (margin.top / 2))
        .attr("text-anchor", "middle")
        .style("font-size", "16px")
        .style("font-weight", "bold")
        // Build title from 3 provided function parameters
        .text(pre_chart_title + $(selected_id).text() + post_chart_title);
}
