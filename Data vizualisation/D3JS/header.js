window.onload = () => {
    console.log("header init")
    var bodyEle = document.getElementsByTagName("body")[0]
    bodyEle.style = "margin: 0px"
    // document.body.innerHTML = "<div id='header'></div>" + document.body.innerHTML;
    // bodyEle.append(document.createElement("div").id = "header")
    var head = [
        { titre: "Bubble", href: "../bubble_clients_car" },
        { titre: "Parallel", href: "../parallel_clients_car" },
        { titre: "Pie", href: "../pie_repartition_car" },
        { titre: "Pie 2", href: "../pie_multi" },
    ]

    var doc = document.getElementById("header");
    head.forEach(element => {
        let a = document.createElement("a");
        a.href = element.href;
        let textnode = document.createTextNode(element.titre);          // Create a text node
        a.appendChild(textnode);
        doc.append(a)
    });

    doc.style = "justify-content: space-around; align-items: center;"
    doc.style.background = "lightgray"
    doc.style.height = "50px"
    doc.style.display = "flex"


}