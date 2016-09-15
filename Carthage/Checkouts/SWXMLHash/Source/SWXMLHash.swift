//
//  SWXMLHash.swift
//
//  Copyright (c) 2014 David Mohundro
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

let rootElementName = "SWXMLHash_Root_Element"

/// Parser options
public class SWXMLHashOptions {
    internal init() {}

    /// determines whether to parse the XML with lazy parsing or not
    public var shouldProcessLazily = false

    /// determines whether to parse XML namespaces or not (forwards to `NSXMLParser.shouldProcessNamespaces`)
    public var shouldProcessNamespaces = false
}

/// Simple XML parser
public class SWXMLHash {
    let options: SWXMLHashOptions

    private init(_ options: SWXMLHashOptions = SWXMLHashOptions()) {
        self.options = options
    }

    class public func config(configAction: (SWXMLHashOptions) -> ()) -> SWXMLHash {
        let opts = SWXMLHashOptions()
        configAction(opts)
        return SWXMLHash(opts)
    }

    public func parse(xml: String) -> XMLIndexer {
        return parse((xml as NSString).dataUsingEncoding(NSUTF8StringEncoding)!)
    }

    public func parse(data: NSData) -> XMLIndexer {
        let parser: SimpleXmlParser = options.shouldProcessLazily ? LazyXMLParser(options) : XMLParser(options)
        return parser.parse(data)
    }

    /**
    Method to parse XML passed in as a string.

    - parameter xml: The XML to be parsed
    - returns: An XMLIndexer instance that is used to look up elements in the XML
    */
    class public func parse(xml: String) -> XMLIndexer {
        return SWXMLHash().parse(xml)
    }

    /**
    Method to parse XML passed in as an NSData instance.

    - parameter xml: The XML to be parsed
    - returns: An XMLIndexer instance that is used to look up elements in the XML
    */
    class public func parse(data: NSData) -> XMLIndexer {
        return SWXMLHash().parse(data)
    }

    /**
    Method to lazily parse XML passed in as a string.

    - parameter xml: The XML to be parsed
    - returns: An XMLIndexer instance that is used to look up elements in the XML
    */
    class public func lazy(xml: String) -> XMLIndexer {
        return config { conf in conf.shouldProcessLazily = true }.parse(xml)
    }

    /**
    Method to lazily parse XML passed in as an NSData instance.

    - parameter xml: The XML to be parsed
    - returns: An XMLIndexer instance that is used to look up elements in the XML
    */
    class public func lazy(data: NSData) -> XMLIndexer {
        return config { conf in conf.shouldProcessLazily = true }.parse(data)
    }
}

struct Stack<T> {
    var items = [T]()
    mutating func push(item: T) {
        items.append(item)
    }
    mutating func pop() -> T {
        return items.removeLast()
    }
    mutating func removeAll() {
        items.removeAll(keepCapacity: false)
    }
    func top() -> T {
        return items[items.count - 1]
    }
}

protocol SimpleXmlParser {
    init(_ options: SWXMLHashOptions)
    func parse(data: NSData) -> XMLIndexer
}

/// The implementation of NSXMLParserDelegate and where the lazy parsing actually happens.
class LazyXMLParser: NSObject, SimpleXmlParser, NSXMLParserDelegate {
    required init(_ options: SWXMLHashOptions) {
        self.options = options
        super.init()
    }

    var root = XMLElement(name: rootElementName)
    var parentStack = Stack<XMLElement>()
    var elementStack = Stack<String>()

    var data: NSData?
    var ops: [IndexOp] = []
    let options: SWXMLHashOptions

    func parse(data: NSData) -> XMLIndexer {
        self.data = data
        return XMLIndexer(self)
    }

    func startParsing(ops: [IndexOp]) {
        // clear any prior runs of parse... expected that this won't be necessary, but you never know
        parentStack.removeAll()
        root = XMLElement(name: rootElementName)
        parentStack.push(root)

        self.ops = ops
        let parser = NSXMLParser(data: data!)
        parser.shouldProcessNamespaces = options.shouldProcessNamespaces
        parser.delegate = self
        parser.parse()
    }

    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {

        elementStack.push(elementName)

        if !onMatch() {
            return
        }
        let currentNode = parentStack.top().addElement(elementName, withAttributes: attributeDict)
        parentStack.push(currentNode)
    }

    func parser(parser: NSXMLParser, foundCharacters string: String) {
        if !onMatch() {
            return
        }

        let current = parentStack.top()

        current.addText(string)
    }

    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let match = onMatch()

        elementStack.pop()

        if match {
            parentStack.pop()
        }
    }

    func onMatch() -> Bool {
        // we typically want to compare against the elementStack to see if it matches ops, *but*
        // if we're on the first element, we'll instead compare the other direction.
        if elementStack.items.count > ops.count {
            return elementStack.items.startsWith(ops.map { $0.key })
        }
        else {
            return ops.map { $0.key }.startsWith(elementStack.items)
        }
    }
}

/// The implementation of NSXMLParserDelegate and where the parsing actually happens.
class XMLParser: NSObject, SimpleXmlParser, NSXMLParserDelegate {
    required init(_ options: SWXMLHashOptions) {
        self.options = options
        super.init()
    }

    var root = XMLElement(name: rootElementName)
    var parentStack = Stack<XMLElement>()
    let options: SWXMLHashOptions

    func parse(data: NSData) -> XMLIndexer {
        // clear any prior runs of parse... expected that this won't be necessary, but you never know
        parentStack.removeAll()

        parentStack.push(root)

        let parser = NSXMLParser(data: data)
        parser.shouldProcessNamespaces = options.shouldProcessNamespaces
        parser.delegate = self
        parser.parse()

        return XMLIndexer(root)
    }

    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {

        let currentNode = parentStack.top().addElement(elementName, withAttributes: attributeDict)
        parentStack.push(currentNode)
    }

    func parser(parser: NSXMLParser, foundCharacters string: String) {
        let current = parentStack.top()

        current.addText(string)
    }

    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        parentStack.pop()
    }
}

public class IndexOp {
    var index: Int
    let key: String

    init(_ key: String) {
        self.key = key
        self.index = -1
    }

    func toString() -> String {
        if index >= 0 {
            return key + " " + index.description
        }

        return key
    }
}

public class IndexOps {
    var ops: [IndexOp] = []

    let parser: LazyXMLParser

    init(parser: LazyXMLParser) {
        self.parser = parser
    }

    func findElements() -> XMLIndexer {
        parser.startParsing(ops)
        let indexer = XMLIndexer(parser.root)
        var childIndex = indexer
        for op in ops {
            childIndex = childIndex[op.key]
            if op.index >= 0 {
                childIndex = childIndex[op.index]
            }
        }
        ops.removeAll(keepCapacity: false)
        return childIndex
    }

    func stringify() -> String {
        var s = ""
        for op in ops {
            s += "[" + op.toString() + "]"
        }
        return s
    }
}

/// Returned from SWXMLHash, allows easy element lookup into XML data.
public enum XMLIndexer: SequenceType {
    case Element(XMLElement)
    case List([XMLElement])
    case Stream(IndexOps)
    case XMLError(Error)

    public enum Error: ErrorType {
        case Attribute(attr: String)
        case AttributeValue(attr: String, value: String)
        case Key(key: String)
        case Index(idx: Int)
        case Init(instance: AnyObject)
        case Error
    }

    /// The underlying XMLElement at the currently indexed level of XML.
    public var element: XMLElement? {
        switch self {
        case .Element(let elem):
            return elem
        case .Stream(let ops):
            let list = ops.findElements()
            return list.element
        default:
            return nil
        }
    }

    /// All elements at the currently indexed level
    public var all: [XMLIndexer] {
        switch self {
        case .List(let list):
            var xmlList = [XMLIndexer]()
            for elem in list {
                xmlList.append(XMLIndexer(elem))
            }
            return xmlList
        case .Element(let elem):
            return [XMLIndexer(elem)]
        case .Stream(let ops):
            let list = ops.findElements()
            return list.all
        default:
            return []
        }
    }

    /// All child elements from the currently indexed level
    public var children: [XMLIndexer] {
        var list = [XMLIndexer]()
        for elem in all.map({ $0.element! }).flatMap({ $0 }) {
            for elem in elem.xmlChildren {
                list.append(XMLIndexer(elem))
            }
        }
        return list
    }

    /**
    Allows for element lookup by matching attribute values.

    - parameter attr: should the name of the attribute to match on
    - parameter value: should be the value of the attribute to match on
    - returns: instance of XMLIndexer
    */
    public func withAttr(attr: String, _ value: String) throws -> XMLIndexer {
        switch self {
        case .Stream(let opStream):
            opStream.stringify()
            let match = opStream.findElements()
            return try match.withAttr(attr, value)
        case .List(let list):
            if let elem = list.filter({$0.attributes[attr] == value}).first {
                return .Element(elem)
            }
            throw Error.AttributeValue(attr: attr, value: value)
        case .Element(let elem):
            if let attr = elem.attributes[attr] {
                if attr == value {
                    return .Element(elem)
                }
                throw Error.AttributeValue(attr: attr, value: value)
            }
            fallthrough
        default:
            throw Error.Attribute(attr: attr)
        }
    }

    /**
    Initializes the XMLIndexer

    - parameter _: should be an instance of XMLElement, but supports other values for error handling
    - returns: instance of XMLIndexer
    */
    public init(_ rawObject: AnyObject) throws {
        switch rawObject {
        case let value as XMLElement:
            self = .Element(value)
        case let value as LazyXMLParser:
            self = .Stream(IndexOps(parser: value))
        default:
            throw Error.Init(instance: rawObject)
        }
    }

    public init(_ el: XMLElement) {
        self = .Element(el)
    }

    init(_ stream: LazyXMLParser) {
        self = .Stream(IndexOps(parser: stream))
    }

    /**
    Find an XML element at the current level by element name

    - parameter key: The element name to index by
    - returns: instance of XMLIndexer to match the element (or elements) found by key
    - throws: Throws an XMLIndexerError.Key if no element was found
    - TODO: Change to throwing subscripts if available in futher releases
    */
    public func byKey(key: String) throws -> XMLIndexer {
        switch self {
        case .Stream(let opStream):
            let op = IndexOp(key)
            opStream.ops.append(op)
            return .Stream(opStream)
        case .Element(let elem):
            let match = elem.xmlChildren.filter({ $0.name == key })
            if match.count > 0 {
                if match.count == 1 {
                    return .Element(match[0])
                }
                else {
                    return .List(match)
                }
            }
            fallthrough
        default:
            throw Error.Key(key: key)
        }
    }

    /**
    Find an XML element at the current level by element name

    - parameter key: The element name to index by
    - returns: instance of XMLIndexer to match the element (or elements) found by
    */
    public subscript(key: String) -> XMLIndexer {
        do {
           return try self.byKey(key)
        } catch let error as Error {
            return .XMLError(error)
        } catch {
            return .XMLError(.Key(key: key))
        }
    }

    /**
    Find an XML element by index within a list of XML Elements at the current level

    - parameter index: The 0-based index to index by
    - returns: instance of XMLIndexer to match the element (or elements) found by key
    - TODO: Change to throwing subscripts if available in futher releases
    */
    public func byIndex(index: Int) throws -> XMLIndexer {
        switch self {
        case .Stream(let opStream):
            opStream.ops[opStream.ops.count - 1].index = index
            return .Stream(opStream)
        case .List(let list):
            if index <= list.count {
                return .Element(list[index])
            }
            return .XMLError(.Index(idx: index))
        case .Element(let elem):
            if index == 0 {
                return .Element(elem)
            }
            fallthrough
        default:
            return .XMLError(.Index(idx: index))
        }
    }

    public subscript(index: Int) -> XMLIndexer {
        do {
            return try byIndex(index)
        }  catch let error as Error {
            return .XMLError(error)
        } catch {
            return .XMLError(.Index(idx: index))
        }
    }

    typealias GeneratorType = XMLIndexer

    public func generate() -> IndexingGenerator<[XMLIndexer]> {
        return all.generate()
    }
}

/// XMLIndexer extensions
extension XMLIndexer: BooleanType {
    /// True if a valid XMLIndexer, false if an error type
    public var boolValue: Bool {
        switch self {
        case .XMLError:
            return false
        default:
            return true
        }
    }
}

extension XMLIndexer: CustomStringConvertible {
    public var description: String {
        switch self {
        case .List(let list):
            return list.map { $0.description }.joinWithSeparator("")
        case .Element(let elem):
            if elem.name == rootElementName {
                return elem.children.map { $0.description }.joinWithSeparator("")
            }

            return elem.description
        default:
            return ""
        }
    }
}

extension XMLIndexer.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .Attribute(let attr):
            return "XML Attribute Error: Missing attribute [\"\(attr)\"]"
        case .AttributeValue(let attr, let value):
            return "XML Attribute Error: Missing attribute [\"\(attr)\"] with value [\"\(value)\"]"
        case .Key(let key):
            return "XML Element Error: Incorrect key [\"\(key)\"]"
        case .Index(let index):
            return "XML Element Error: Incorrect index [\"\(index)\"]"
        case .Init(let instance):
            return "XML Indexer Error: initialization with Object [\"\(instance)\"]"
        case .Error:
            return "Unknown Error"
        }
    }
}

/// Models content for an XML doc, whether it is text or XML
public protocol XMLContent: CustomStringConvertible {
}

/// Models a text element
public class TextElement: XMLContent {
    public let text: String
    init(text: String) {
        self.text = text
    }
}

/// Models an XML element, including name, text and attributes
public class XMLElement: XMLContent {
    /// The name of the element
    public let name: String
    /// The attributes of the element
    public var attributes = [String:String]()

    /// The inner text of the element, if it exists
    public var text: String? {
        return children.map({ $0 as? TextElement }).flatMap({ $0 }).reduce("", combine: { $0 + $1!.text })
    }

    var children = [XMLContent]()
    var count: Int = 0
    var index: Int

    var xmlChildren: [XMLElement] {
        return children.map { $0 as? XMLElement }.flatMap { $0 }
    }

    /**
    Initialize an XMLElement instance

    -parameter name: The name of the element to be initialized
    -returns: a new instance of XMLElement
    */
    init(name: String, index: Int = 0) {
        self.name = name
        self.index = index
    }

    /**
    Adds a new XMLElement underneath this instance of XMLElement

    - parameter name: The name of the new element to be added
    - parameter withAttributes: The attributes dictionary for the element being added
    - returns: The XMLElement that has now been added
    */
    func addElement(name: String, withAttributes attributes: NSDictionary) -> XMLElement {
        let element = XMLElement(name: name, index: count)
        count += 1

        children.append(element)

        for (keyAny,valueAny) in attributes {
            if let key = keyAny as? String,
                let value = valueAny as? String {
                element.attributes[key] = value
            }
        }

        return element
    }

    func addText(text: String) {
        let elem = TextElement(text: text)

        children.append(elem)
    }
}

extension TextElement: CustomStringConvertible {
    public var description: String {
        return text
    }
}

extension XMLElement: CustomStringConvertible {
    public var description: String {
        var attributesStringList = [String]()
        if !attributes.isEmpty {
            for (key, val) in attributes {
                attributesStringList.append("\(key)=\"\(val)\"")
            }
        }

        var attributesString = attributesStringList.joinWithSeparator(" ")
        if !attributesString.isEmpty {
            attributesString = " " + attributesString
        }

        if children.count > 0 {
            var xmlReturn = [String]()
            xmlReturn.append("<\(name)\(attributesString)>")
            for child in children {
                xmlReturn.append(child.description)
            }
            xmlReturn.append("</\(name)>")
            return xmlReturn.joinWithSeparator("")
        }

        if text != nil {
            return "<\(name)\(attributesString)>\(text!)</\(name)>"
        }
        else {
            return "<\(name)\(attributesString)/>"
        }
    }
}
