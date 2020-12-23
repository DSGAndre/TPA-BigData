var dataclient =[{"Var1":"BMW","Freq":294455},{"Var1":"Audi","Freq":291922},{"Var1":"Renault","Freq":251612},{"Var1":"Jaguar","Freq":189012},{"Var1":"Volkswagen","Freq":155974},{"Var1":"Mercedes","Freq":150183},{"Var1":"Volvo","Freq":123848},{"Var1":"Peugeot","Freq":96186},{"Var1":"Saab","Freq":84536},{"Var1":"Fiat","Freq":76609}]

window.onload = () => {
    console.log(dataclient);
    // var dataClient = readJSON("localhost:5500/assets/data_client.json")
    // bar chart

    // the data
    var data = [{ "product": "rice", "value": 10, "displayed": true }, { "product": "beans", "value": 20, "displayed": true }, { "product": "meat", "value": 100, "displayed": true }]


    // the selection list for filtering the data
    var div = d3.select('body')
        .append('div')
        .style('position', 'relative')
        .style('left', '10px')
        .style('top', '30px')

    var ul = div.append('ul')

    var items = ul.selectAll('li')
        .data(dataclient)
        .enter()
        .append('li')

    items.append('input')
        .attr('type', 'checkbox')
        .property('checked', true)
        .on('click', function (d) {
            var checked = this.checked;
            var value = d3.select(this).datum()

            dataclient.forEach(function (d) {
                if (d.Var1 == value.Var1 && d.Freq == value.Freq) {
                    console.log('found')
                    // d.displayed = checked;
                }
            })

            updateChart()
        })

    items.append('text')
        .text(d => d.Var1)

    //// chart svg and groups

    var margin = { left: 50, right: 10, top: 10, bottom: 20 },
        width = 500,
        height = 300;

    var svg = d3.select('svg')
        .attr('width', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)

    var chartGroup = svg.append('g')
        .attr('transform', 'translate(' + margin.left + ', ' + margin.top + ')')

    var yScale = d3.scaleBand()
        .domain(data.map(d => d.Var1))
        .range([height, 0])

    var yAxis = d3.axisLeft(yScale)

    var xScale = d3.scaleLinear()
        .domain([0, d3.max(dataclient, function (d) { return d.Freq; })])
        .range([0, width])

    var xAxis = d3.axisBottom(xScale)

    chartGroup.append('g')
        .attr('class', 'y-axis')
        .attr('transform', 'translate(0,0)')
        .call(yAxis)

    chartGroup.append('g')
        .attr('class', 'x-axis')
        .attr('transform', 'translate(0,' + height + ')')
        .call(xAxis)


    updateChart()


    function updateChart() {
        // var validData = data.filter(d => d.displayed)
        var validData = dataclient
        yScale.domain(validData.map(d => d.Var1))
            .range([height, 0])

        chartGroup.select('.y-axis')
            .transition()
            .duration(500)
            .call(yAxis)

        chartGroup
            .selectAll('rect')
            .data(validData)
            .join(
                enter => enter.append('rect')
                    .attr('x', 0)
                    .attr('class', 'rectangle'),
                update => update,
                exit => exit.remove()
            )
            .on('mouseenter', function (d) {
                var x = d3.event.pageX,
                    y = d3.event.pageY;

                d3.selectAll('.tooltip')
                    .style('display', 'block')
                    .style('left', x + 'px')
                    .style('top', y + 'px')
                    .html('Product: ' + d.Var1 + '<br> Price: $' + d.Freq)
            })
            .on('mouseleave', function (d) {
                d3.select('.tooltip').transition().duration(500).style('display', 'none')
            })
            .transition()
            .duration(500)
            .attr('y', function (d, i) { return yScale(d.Var1); })
            .attr('height', yScale.bandwidth())
            .attr('width', function (d) { return xScale(d.Freq); })

    }
}