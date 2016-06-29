// Playground - noun: a place where people can play

import SWXMLHash
import Foundation

let xmlWithNamespace = "<root xmlns:h=\"http://www.w3.org/TR/html4/\"" +
"  xmlns:f=\"http://www.w3schools.com/furniture\">" +
"  <h:table>" +
"    <h:tr>" +
"      <h:td>Apples</h:td>" +
"      <h:td>Bananas</h:td>" +
"    </h:tr>" +
"  </h:table>" +
"  <f:table>" +
"    <f:name>African Coffee Table</f:name>" +
"    <f:width>80</f:width>" +
"    <f:length>120</f:length>" +
"  </f:table>" +
"</root>"

var xml = SWXMLHash.parse(xmlWithNamespace)

// one root element
let count = xml["root"].all.count

// "Apples"
xml["root"]["h:table"]["h:tr"]["h:td"][0].element!.text!


// enumerate all child elements (procedurally)
func enumerate(indexer: XMLIndexer, level: Int) {
    for child in indexer.children {
        let name = child.element!.name
        print("\(level) \(name)")

        enumerate(child, level: level + 1)
    }
}

enumerate(xml, level: 0)


// enumerate all child elements (functionally)
func reduceName(names: String, elem: XMLIndexer) -> String {
    return names + elem.element!.name + elem.children.reduce(", ", combine: reduceName)
}

xml.children.reduce("elements: ", combine: reduceName)
