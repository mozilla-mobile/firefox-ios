/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/// Render the graph to a string.
public protocol GraphRepresentation {
    var fileExtension: String { get }
    func begin()
    func renderScreenStateNode(name: String, isDismissedOnUse: Bool)
    func renderScreenActionNode(name: String)
    func renderEdgeToScreenState(src: String, dest: String, label: String?, isBackable: Bool)
    func renderEdgeToScreenAction(src: String, dest: String, label: String?)
    func end()
    func stringValue() -> String
}

public extension MMScreenGraph {
    func stringRepresentation(_ renderer: GraphRepresentation = DotRepresentation()) -> String {
        buildGraph()
        renderer.begin()
        namedScenes.forEach { (name, node) in
            if let node = node as? MMScreenStateNode {
                renderer.renderScreenStateNode(name: name, isDismissedOnUse: node.dismissOnUse)
            } else if let _ = node as? MMActionNode {
                renderer.renderScreenActionNode(name: name)
            }
        }

        namedScenes.forEach { (src, node) in
            if let node = node as? MMScreenStateNode {
                node.edges.values.forEach { edge in
                    guard let dest = namedScenes[edge.destinationName] else { return }
                    if let dest = dest as? MMScreenStateNode {
                        let directed = !dest.hasBack
                        renderer.renderEdgeToScreenState(src: src,
                                                         dest: dest.name,
                                                         label: edge.predicate?.predicateFormat,
                                                         isBackable: directed)
                    } else if let _ = dest as? MMActionNode {
                        renderer.renderEdgeToScreenAction(
                            src: src,
                            dest: dest.name,
                            label: edge.predicate?.predicateFormat)
                    } else {
                        return
                    }


                }
            } else if let node = node as? MMScreenActionNode {
                if let destName = node.nextNodeName {
                    renderer.renderEdgeToScreenState(src: src, dest: destName, label: nil, isBackable: true)
                }
            }
        }

        renderer.end()
        return renderer.stringValue()
    }
}

/// The default implementation
public class DotRepresentation {
    /////////////////////////////////////////////////////////////////////////
    // Style your graph here.
    let graphStyle = [
        "fontsize": "15",
        "font": "Helvetica",
        "labelloc": "t",
        "label": "",
        "splines": "true",
        "overlap": "false",
        "rankdir": "LR",
        "ratio": "auto",
        "nodesep": "0.5",
        "ordering": "in",
        "maxiter": "1000",
    ]

    let actionColor = "lightBlue"
    lazy var actionStyle: [String: String] = {
        let color = self.actionColor
        let fontColor = "white"

        return [
            "shape": "egg",
            "style": "filled",
            "color": color,
            "fillColor": color,
            "fontColor": fontColor,
            "fontSize": "10"
        ]
    }()

    lazy var screenStyle: [String: String] = {
        let color = "black"
        let fontColor = "black"
        return [
            "shape": "box",
            "color": color,
            "fontColor": fontColor,
        ]
    }()

    lazy var dismissOnUseStyle: [String: String] = {
        let color = "lightgray"
        let fontColor = "gray"
        return [
            "fillcolor": color,
            "color": color,
            "fontColor": fontColor,
            "style": "filled",
            "shape": "box",
        ]
    }()

    let backableEdgeStyle = [
        "dir": "both",
        "arrowtail": "obox",
        "arrowhead": "normal"
    ]

    let conditionalEdgeStyle = [
        "style": "dashed",
    ]

    let unconditionalEdgeStyle = [
        "style": "solid"
    ]

    lazy var actionEdgeStyle: [String: String] = {
        return [
            "color": self.actionColor
        ]
    }()

    lazy var screenEdgeStyle: [String: String] = {
        return [:]
    }()
    // end styling.
    /////////////////////////////////////////////////////////////////////////

    var lines: [String] = []

    var namedIDs: [String: String] = [:]
    var idGenerator = 0

    public init() {
    }
}

extension DotRepresentation: GraphRepresentation {
    public var fileExtension: String { return "dot" }

    public func begin() {
        lines = []

        append("digraph G {",
            styleString(from: graphStyle, includeBrackets: false)
        )

        renderLegend()
    }

    public func stringValue() -> String {
        return lines.joined(separator: "\n")
    }

    public func renderScreenStateNode(name: String, isDismissedOnUse dismissOnUse: Bool) {
        let id = self.id(for: name)
        var style = ["label": name]

        if dismissOnUse {
            styleAppend(to: &style, dismissOnUseStyle)
        } else {
            styleAppend(to: &style, screenStyle)
        }
        let styleCode = styleString(from: style)
        append("\(id) \(styleCode);")
    }

    public func renderScreenActionNode(name: String) {
        let id = self.id(for: name)
        var style = [
            "label": name,
        ]
        styleAppend(to: &style, actionStyle)

        let styleCode = styleString(from: style)
        append("\(id) \(styleCode)")
    }

    public func renderEdgeToScreenState(src: String, dest: String, label: String?, isBackable: Bool) {
        var style = [String: String]()
        if let label = label {
            styleAppend(to: &style, ["label": label])
            styleAppend(to: &style, conditionalEdgeStyle)
        } else {
            styleAppend(to: &style, unconditionalEdgeStyle)
        }

        if isBackable {
            styleAppend(to: &style, backableEdgeStyle)
        } 

        styleAppend(to: &style, screenEdgeStyle)

        let styleCode = styleString(from: style)
        let srcID = id(for: src)
        let destID = id(for: dest)

        let edgeCode = "->"

        append("\(srcID) \(edgeCode) \(destID)\(styleCode);")
    }

    public func renderEdgeToScreenAction(src: String, dest: String, label: String?) {
        var style = [String: String]()
        if let label = label {
            styleAppend(to: &style, ["label": label])
            styleAppend(to: &style, conditionalEdgeStyle)
        } else {
            styleAppend(to: &style, unconditionalEdgeStyle)
        }

        styleAppend(to: &style, actionEdgeStyle)
        let labelCode = styleString(from: style)
        let srcID = id(for: src)
        let destID = id(for: dest)

        let edgeCode = "->"

        append("\(srcID) \(edgeCode) \(destID)\(labelCode);")
    }

    public func end() {
        append("}")
    }

}

/// Rendering the legend.
fileprivate extension DotRepresentation {
    // This uses the existing methods, so should be conform to whichever style changes are made.
    func renderLegend() {
        var i = 1;
        var labels = [String]()
        func label(_ string: String) {
            labels += [("k\(i) [label=\"\(string)\\r\"];")]
            i += 1
        }

        append("subgraph cluster_legend {",
               "fontsize=15;",
               "label=\"Legend\";")

        namedIDs = [:]
        renderScreenStateNode(name: "Screen1", isDismissedOnUse: false)
        renderScreenStateNode(name: "Screen2", isDismissedOnUse: false)
        renderEdgeToScreenState(src: "Screen1", dest: "Screen2", label: nil, isBackable: false)
        label("Transition between two screens")

        namedIDs = [:]
        renderScreenStateNode(name: "Screen1", isDismissedOnUse: false)
        renderScreenStateNode(name: "Screen2", isDismissedOnUse: false)
        renderEdgeToScreenState(src: "Screen1", dest: "Screen2", label: "loggedIn == true", isBackable: false)
        label("Transition between two screens\\rconditional on user state")

        namedIDs = [:]
        renderScreenStateNode(name: "Screen1", isDismissedOnUse: false)
        renderScreenStateNode(name: "Screen2", isDismissedOnUse: false)
        renderScreenStateNode(name: "Screen3", isDismissedOnUse: false)
        renderEdgeToScreenState(src: "Screen1", dest: "Screen3", label: nil, isBackable: true)
        renderEdgeToScreenState(src: "Screen2", dest: "Screen3", label: nil, isBackable: true)
        label("Screen3 has a back action\\rto get back to where it came from")

        namedIDs = [:]
        renderScreenStateNode(name: "Screen1", isDismissedOnUse: false)
        renderScreenStateNode(name: "MenuVisible", isDismissedOnUse: true)
        renderScreenStateNode(name: "Screen2", isDismissedOnUse: false)
        renderEdgeToScreenState(src: "Screen1", dest: "MenuVisible", label: nil, isBackable: true)
        renderEdgeToScreenState(src: "MenuVisible", dest: "Screen2", label: nil, isBackable: true)
        label("MenuVisible is dismissed on use.\\rGoing back from Screen2 goes to Screen1")

        namedIDs = [:]
        renderScreenStateNode(name: "Screen", isDismissedOnUse: false)
        renderScreenActionNode(name: "Named Action")
        renderEdgeToScreenAction(src: "Screen", dest: "Named Action", label: nil)
        label("Named Action can be performed from Screen")

        namedIDs = [:]
        renderScreenActionNode(name: "Menu-NewTab")
        renderScreenActionNode(name: "TabTray-NewTab")
        renderScreenActionNode(name: "NewTab")
        renderScreenStateNode(name: "NewTabScreen", isDismissedOnUse: false)
        renderEdgeToScreenAction(src: "Menu-NewTab", dest: "NewTab", label: nil)
        renderEdgeToScreenAction(src: "TabTray-NewTab", dest: "NewTab", label: nil)
        renderEdgeToScreenState(src: "NewTab", dest: "NewTabScreen", label: nil, isBackable: false)
        label("NewTab action can be accessed —\\rand tested — from multiple places.\\rBoth lead to the NewTabScreen.")

        append("{",
            "rank=source",
            "node [shape=plaintext, style=solid, width=3.5];")

        lines += labels

        append("}")

        append("}")

        namedIDs = [:]
    }
}

fileprivate extension DotRepresentation {
    func append(_ additional: String...) {
        lines = lines + additional
    }

    func id(for name: String) -> String {
        if let id = namedIDs[name] {
            return id
        }

        let id = "_\(idGenerator)"
        idGenerator += 1
        namedIDs[name] = id
        return id
    }

    func styleString(from dict: [String: String], includeBrackets: Bool = true) -> String {
        guard dict.count > 0 else {
            return ""
        }

        let pairs = dict.map { (key, value) -> String in
            return "\(key)=\"\(value)\""
        }

        let joined = pairs.joined(separator: "; ")

        return includeBrackets ? "[" + joined + "]" : joined
    }

    func styleAppend(to style: inout [String: String], _ extras: [String: String]) {
        extras.forEach { (key, value) in
            style[key] = value
        }
    }
}
