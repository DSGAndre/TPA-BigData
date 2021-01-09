var dataclient = [{ "Var1": "BMW", "Freq": 294455 }, { "Var1": "Audi", "Freq": 291922 }, { "Var1": "Renault", "Freq": 251612 }, { "Var1": "Jaguar", "Freq": 189012 }, { "Var1": "Volkswagen", "Freq": 155974 }, { "Var1": "Mercedes", "Freq": 150183 }, { "Var1": "Volvo", "Freq": 123848 }, { "Var1": "Peugeot", "Freq": 96186 }, { "Var1": "Saab", "Freq": 84536 }, { "Var1": "Fiat", "Freq": 76609 }]

var data = [{
    date: "2014-01-01",
    amount: 10
},
{
    date: "2014-02-01",
    amount: 20
},
{
    date: "2014-03-01",
    amount: 40
},
{
    date: "2014-04-01",
    amount: 80
}
]

var margin,
    width,
    height;

var svg;

var chartGroup;

// define the y scale using the extent of amount values in the data
var yScale;

// define the x scale from january to april 2014
var xScale;

// define the y axis and the number of ticks
var yAxis;

// define the x axis and the number and format of ticks
var xAxis;

var lineGenerator

window.onload = () => {
    console.log(dataclient);



    margin = {
        left: 20,
        top: 10,
        bottom: 20,
        right: 10
    }, // the margins of the chart
        width = 360, // the width of the svg
        height = 160; // the height of the svg

    svg = d3.select("svg")
        .attr('width', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)

    chartGroup = svg.append("g")
        .attr('transform', "translate(" + margin.left + "," + margin.top + ")")

    // define the y scale using the extent of amount values in the data
    yScale = d3.scaleLinear()
        .domain(d3.extent(data, d => d.amount))
        .range([height, 0])

    // define the x scale from january to april 2014
    xScale = d3.scaleTime()
        .domain([
            new Date("2014-01-01"),
            new Date("2014-04-01")
        ])
        .range([0, width])

    // define the y axis and the number of ticks
    yAxis = d3.axisLeft(yScale)
        .ticks(4);

    // define the x axis and the number and format of ticks
    xAxis = d3.axisBottom(xScale)
        .tickFormat(d3.timeFormat("%b"))
        .ticks(4);

    // draws the y axis on the screen
    chartGroup.append("g")
        .attr('transform', "translate(0, 0)")
        .classed('y-axis', true)
        .call(yAxis)

    // draws the x axis on the screen
    chartGroup.append("g")
        .attr('transform', "translate(0," + height + ")")
        .classed('x-axis', true)
        .call(xAxis)

    lineGenerator = d3.line()
        .x(function (d) {
            return xScale(new Date(d.date))
        })
        .y(function (d) {
            return yScale(d.amount)
        })

    // Add the line
    chartGroup.append("path")
        .datum(data)
        .attr('class', 'line')
        .attr("fill", "none")
        .attr("stroke", "steelblue")
        .attr("stroke-width", 1.5)

    update()





}

function update() {
    chartGroup.selectAll("circle")
        .data(data)
        .join(
            enter => enter.append("circle")
                .attr("r", 5)
                .style("fill", "steelblue"),
            update => update,
            exit => exit.remove()
        )
        .transition()
        .duration(500)
        .attr("cx", d => xScale(new Date(d.date)))
        .attr("cy", d => yScale(d.amount))

    chartGroup.selectAll("path.line")
        .transition()
        .duration(500)
        .attr("d", lineGenerator(data))
}
function changeData() {
    data.pop()
    update()
}