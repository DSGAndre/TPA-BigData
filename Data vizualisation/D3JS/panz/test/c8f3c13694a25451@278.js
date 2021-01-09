// https://observablehq.com/@d3/brushable-parallel-coordinates@278
import define1 from "./a33468b95d0b15b0@699.js";

export default function define(runtime, observer) {
  const main = runtime.module();
  const fileAttachments = new Map([["cars.csv",new URL("./files/4cb40b94ee98c9296d28913c84e041a1bba5e6821131116b506dcbbfa383592985d94310ad25deb564b61d14ed20fd17c014ed38ab465d0a717dd81e4ea5759e",import.meta.url)]]);
  main.builtin("FileAttachment", runtime.fileAttachments(name => fileAttachments.get(name)));
  main.variable(observer()).define(["md"], function(md){return(
md`# Brushable Parallel Coordinates`
)});
  main.variable(observer()).define(["selection"], function(selection){return(
selection
)});
  main.variable(observer("viewof keyz")).define("viewof keyz", ["html","keys"], function(html,keys)
{
  const form = html`<form>${Object.assign(html`<select name=select>${keys.map(key => Object.assign(html`<option>`, {value: key, textContent: key}))}</select>`, {value: "weight (lb)"})} <i style="font-size:smaller;">color encoding</i>`;
  form.select.onchange = () => (form.value = form.select.value, form.dispatchEvent(new CustomEvent("input")));
  form.select.onchange();
  return form;
}
);
  main.variable(observer("keyz")).define("keyz", ["Generators", "viewof keyz"], (G, _) => G.input(_));
  main.variable(observer()).define(["legend","z","keyz"], function(legend,z,keyz){return(
legend({color: z, title: keyz})
)});
  main.variable(observer("viewof selection")).define("viewof selection", ["d3","width","height","margin","brushHeight","data","keyz","z","line","keys","label","y","x","deselectedColor"], function(d3,width,height,margin,brushHeight,data,keyz,z,line,keys,label,y,x,deselectedColor)
{
  const svg = d3.create("svg")
      .attr("viewBox", [0, 0, width, height]);

  const brush = d3.brushX()
      .extent([
        [margin.left, -(brushHeight / 2)],
        [width - margin.right, brushHeight / 2]
      ])
      .on("start brush end", brushed);

  const path = svg.append("g")
      .attr("fill", "none")
      .attr("stroke-width", 1.5)
      .attr("stroke-opacity", 0.4)
    .selectAll("path")
    .data(data.slice().sort((a, b) => d3.ascending(a[keyz], b[keyz])))
    .join("path")
      .attr("stroke", d => z(d[keyz]))
      .attr("d", d => line(d3.cross(keys, [d], (key, d) => [key, d[key]])));

  path.append("title")
      .text(label);

  svg.append("g")
    .selectAll("g")
    .data(keys)
    .join("g")
      .attr("transform", d => `translate(0,${y(d)})`)
      .each(function(d) { d3.select(this).call(d3.axisBottom(x.get(d))); })
      .call(g => g.append("text")
        .attr("x", margin.left)
        .attr("y", -6)
        .attr("text-anchor", "start")
        .attr("fill", "currentColor")
        .text(d => d))
      .call(g => g.selectAll("text")
        .clone(true).lower()
        .attr("fill", "none")
        .attr("stroke-width", 5)
        .attr("stroke-linejoin", "round")
        .attr("stroke", "white"))
      .call(brush);

  const selections = new Map();

  function brushed({selection}, key) {
    if (selection === null) selections.delete(key);
    else selections.set(key, selection.map(x.get(key).invert));
    const selected = [];
    path.each(function(d) {
      const active = Array.from(selections).every(([key, [min, max]]) => d[key] >= min && d[key] <= max);
      d3.select(this).style("stroke", active ? z(d[keyz]) : deselectedColor);
      if (active) {
        d3.select(this).raise();
        selected.push(d);
      }
    });
    svg.property("value", selected).dispatch("input");
  }

  return svg.property("value", data).node();
}
);
  main.variable(observer("selection")).define("selection", ["Generators", "viewof selection"], (G, _) => G.input(_));
  main.variable(observer("data")).define("data", ["FileAttachment"], function(FileAttachment){return(
FileAttachment("cars.csv").csv({typed: true})
)});
  main.variable(observer("keys")).define("keys", ["data"], function(data){return(
data.columns.slice(1)
)});
  main.variable(observer("x")).define("x", ["keys","d3","data","margin","width"], function(keys,d3,data,margin,width){return(
new Map(Array.from(keys, key => [key, d3.scaleLinear(d3.extent(data, d => d[key]), [margin.left, width - margin.right])]))
)});
  main.variable(observer("y")).define("y", ["d3","keys","margin","height"], function(d3,keys,margin,height){return(
d3.scalePoint(keys, [margin.top, height - margin.bottom])
)});
  main.variable(observer("z")).define("z", ["d3","x","keyz","colors"], function(d3,x,keyz,colors){return(
d3.scaleSequential(x.get(keyz).domain().reverse(), colors)
)});
  main.variable(observer("line")).define("line", ["d3","x","y"], function(d3,x,y){return(
d3.line()
    .defined(([, value]) => value != null)
    .x(([key, value]) => x.get(key)(value))
    .y(([key]) => y(key))
)});
  main.variable(observer("label")).define("label", function(){return(
d => d.name
)});
  main.variable(observer("colors")).define("colors", ["d3"], function(d3){return(
d3.interpolateBrBG
)});
  main.variable(observer("deselectedColor")).define("deselectedColor", function(){return(
"#ddd"
)});
  main.variable(observer("brushHeight")).define("brushHeight", function(){return(
50
)});
  main.variable(observer("margin")).define("margin", function(){return(
{top: 30, right: 10, bottom: 30, left: 10}
)});
  main.variable(observer("height")).define("height", ["keys"], function(keys){return(
keys.length * 120
)});
  main.variable(observer("d3")).define("d3", ["require"], function(require){return(
require("d3@6")
)});
  const child1 = runtime.module(define1);
  main.import("legend", child1);
  return main;
}
