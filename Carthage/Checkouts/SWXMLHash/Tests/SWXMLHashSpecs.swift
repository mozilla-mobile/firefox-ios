//
//  SWXMLHashTests.swift
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

import SWXMLHash
import Quick
import Nimble

class SWXMLHashTests: QuickSpec {
    override func spec() {
        let xmlToParse = "<root><header>header mixed content<title>Test Title Header</title>more mixed content</header><catalog><book id=\"bk101\"><author>Gambardella, Matthew</author><title>XML Developer's Guide</title><genre>Computer</genre><price>44.95</price><publish_date>2000-10-01</publish_date><description>An in-depth look at creating applications with XML.</description></book><book id=\"bk102\"><author>Ralls, Kim</author><title>Midnight Rain</title><genre>Fantasy</genre><price>5.95</price><publish_date>2000-12-16</publish_date><description>A former architect battles corporate zombies, an evil sorceress, and her own childhood to become queen of the world.</description></book><book id=\"bk103\"><author>Corets, Eva</author><title>Maeve Ascendant</title><genre>Fantasy</genre><price>5.95</price><publish_date>2000-11-17</publish_date><description>After the collapse of a nanotechnology society in England, the young survivors lay the foundation for a new society.</description></book></catalog></root>"

        var xml = XMLIndexer("to be set")

        beforeEach {
            xml = SWXMLHash.parse(xmlToParse)
        }

        describe("xml parsing") {
            it("should be able to parse individual elements") {
                expect(xml["root"]["header"]["title"].element?.text).to(equal("Test Title Header"))
            }

            it("should be able to parse element groups") {
                expect(xml["root"]["catalog"]["book"][1]["author"].element?.text).to(equal("Ralls, Kim"))
            }

            it("should be able to parse attributes") {
                expect(xml["root"]["catalog"]["book"][1].element?.attributes["id"]).to(equal("bk102"))
            }

            it("should be able to look up elements by name and attribute") {
                expect(xml["root"]["catalog"]["book"].withAttr("id", "bk102")["author"].element?.text).to(equal("Ralls, Kim"))
            }

            it("should be able to iterate element groups") {
                let result = xml["root"]["catalog"]["book"].all.map({ $0["genre"].element!.text! }).joinWithSeparator(", ")
                expect(result).to(equal("Computer, Fantasy, Fantasy"))
            }

            it("should be able to iterate element groups even if only one element is found") {
                expect(xml["root"]["header"]["title"].all.count).to(equal(1))
            }

            it("should be able to index element groups even if only one element is found") {
                expect(xml["root"]["header"]["title"][0].element?.text).to(equal("Test Title Header"))
            }

            it("should be able to iterate using for-in") {
                var count = 0
                for _ in xml["root"]["catalog"]["book"] {
                    count++
                }

                expect(count).to(equal(3))
            }

            it("should be able to enumerate children") {
                let result = xml["root"]["catalog"]["book"][0].children.map({ $0.element!.name }).joinWithSeparator(", ")
                expect(result).to(equal("author, title, genre, price, publish_date, description"))
            }

            it("should be able to handle mixed content") {
                expect(xml["root"]["header"].element?.text).to(equal("header mixed contentmore mixed content"))
            }

            it("should handle interleaving XML elements") {
                let interleavedXml = "<html><body><p>one</p><div>two</div><p>three</p><div>four</div></body></html>"
                let parsed = SWXMLHash.parse(interleavedXml)

                let result = parsed["html"]["body"].children.map({ $0.element!.text! }).joinWithSeparator(", ")
                expect(result).to(equal("one, two, three, four"))
            }

            it("should be able to provide a description for the document") {
                let descriptionXml = "<root><foo><what id=\"myId\">puppies</what></foo></root>"
                let parsed = SWXMLHash.parse(descriptionXml)

                expect(parsed.description).to(equal("<root>\n<foo>\n<what id=\"myId\">puppies</what>\n</foo>\n</root>"))
            }
        }

        describe("white space parsing") {
            var xml = XMLIndexer("to be set")

            beforeEach {
                let bundle = NSBundle(forClass: SWXMLHashTests.self)
                let path = bundle.pathForResource("test", ofType: "xml")
                let data = NSData(contentsOfFile: path!)
                xml = SWXMLHash.parse(data!)
            }

            it("should be able to pull text between elements without whitespace (issue #6)") {
                expect(xml["niotemplate"]["section"][0]["constraint"][1].element?.text).to(equal("H:|-15-[title]-15-|"))
            }

            it("should be able to correctly parse CDATA sections *with* whitespace") {
                expect(xml["niotemplate"]["other"].element?.text).to(equal("\n        \n  this\n  has\n  white\n  space\n        \n    "))
            }
        }

        describe("xml parsing error scenarios") {
            it("should return nil when keys don't match") {
                expect(xml["root"]["what"]["header"]["foo"].element?.name).to(beNil())
            }

            it("should provide an error object when keys don't match") {
                var err: NSError? = nil
                switch xml["root"]["what"]["header"]["foo"] {
                case .Error(let error):
                    err = error
                default:
                    err = nil
                }
                expect(err).toNot(beNil())
            }

            it("should provide an error element when indexers don't match") {
                var err: NSError? = nil
                switch xml["what"]["subelement"][5]["nomatch"] {
                case .Error(let error):
                    err = error
                default:
                    err = nil
                }
                expect(err).toNot(beNil())
            }
        }
    }
}

class SWXMLHashLazyTests: QuickSpec {
    override func spec() {
        let xmlToParse = "<root><header>header mixed content<title>Test Title Header</title>more mixed content</header><catalog><book id=\"bk101\"><author>Gambardella, Matthew</author><title>XML Developer's Guide</title><genre>Computer</genre><price>44.95</price><publish_date>2000-10-01</publish_date><description>An in-depth look at creating applications with XML.</description></book><book id=\"bk102\"><author>Ralls, Kim</author><title>Midnight Rain</title><genre>Fantasy</genre><price>5.95</price><publish_date>2000-12-16</publish_date><description>A former architect battles corporate zombies, an evil sorceress, and her own childhood to become queen of the world.</description></book><book id=\"bk103\"><author>Corets, Eva</author><title>Maeve Ascendant</title><genre>Fantasy</genre><price>5.95</price><publish_date>2000-11-17</publish_date><description>After the collapse of a nanotechnology society in England, the young survivors lay the foundation for a new society.</description></book></catalog></root>"

        var xml = XMLIndexer("to be set")

        beforeEach {
            xml = SWXMLHash.config { config in config.shouldProcessLazily = true }.parse(xmlToParse)
        }

        describe("lazy xml parsing") {
            it("should be able to parse individual elements") {
                expect(xml["root"]["header"]["title"].element?.text).to(equal("Test Title Header"))
            }

            it("should be able to parse element groups") {
                expect(xml["root"]["catalog"]["book"][1]["author"].element?.text).to(equal("Ralls, Kim"))
            }

            it("should be able to parse attributes") {
                expect(xml["root"]["catalog"]["book"][1].element?.attributes["id"]).to(equal("bk102"))
            }

            it("should be able to look up elements by name and attribute") {
                expect(xml["root"]["catalog"]["book"].withAttr("id", "bk102")["author"].element?.text).to(equal("Ralls, Kim"))
            }

            it("should be able to iterate element groups") {
                let result = xml["root"]["catalog"]["book"].all.map({ $0["genre"].element?.text ?? "" }).joinWithSeparator(", ")
                expect(result).to(equal("Computer, Fantasy, Fantasy"))
            }

            it("should be able to iterate element groups even if only one element is found") {
                expect(xml["root"]["header"]["title"].all.count).to(equal(1))
            }

            it("should be able to index element groups even if only one element is found") {
                expect(xml["root"]["header"]["title"][0].element?.text).to(equal("Test Title Header"))
            }

            it("should be able to iterate using for-in") {
                var count = 0
                for _ in xml["root"]["catalog"]["book"] {
                    count++
                }

                expect(count).to(equal(3))
            }

            it("should be able to enumerate children") {
                let result = xml["root"]["catalog"]["book"][0].children.map({ $0.element?.name ?? "" }).joinWithSeparator(", ")
                expect(result).to(equal("author, title, genre, price, publish_date, description"))
            }

            it("should be able to handle mixed content") {
                expect(xml["root"]["header"].element?.text).to(equal("header mixed contentmore mixed content"))
            }

            it("should handle interleaving XML elements") {
                let interleavedXml = "<html><body><p>one</p><div>two</div><p>three</p><div>four</div></body></html>"
                let parsed = SWXMLHash.lazy(interleavedXml)

                let result = parsed["html"]["body"].children.map({ $0.element?.text ?? "" }).joinWithSeparator(", ")
                expect(result).to(equal("one, two, three, four"))
            }
        }

        describe("white space parsing") {
            var xml = XMLIndexer("to be set")

            beforeEach {
                let bundle = NSBundle(forClass: SWXMLHashTests.self)
                let path = bundle.pathForResource("test", ofType: "xml")
                let data = NSData(contentsOfFile: path!)
                xml = SWXMLHash.lazy(data!)
            }

            it("should be able to pull text between elements without whitespace (issue #6)") {
                expect(xml["niotemplate"]["section"][0]["constraint"][1].element?.text).to(equal("H:|-15-[title]-15-|"))
            }

            it("should be able to correctly parse CDATA sections *with* whitespace") {
                expect(xml["niotemplate"]["other"].element?.text).to(equal("\n        \n  this\n  has\n  white\n  space\n        \n    "))
            }
        }

        describe("xml parsing error scenarios") {
            it("should return nil when keys don't match") {
                expect(xml["root"]["what"]["header"]["foo"].element?.name).to(beNil())
            }
        }
    }
}

class SWXMLHashConfigSpecs: QuickSpec {
    override func spec() {
        describe("optional configuration options for NSXMLParser") {
            var parser = XMLIndexer("not set")
            let xmlWithNamespace = "<root xmlns:h=\"http://www.w3.org/TR/html4/\"" +
                "  xmlns:f=\"http://www.w3schools.com/furniture\">" +
                "  <h:table>" +
                "    <h:tr>" +
                "      <h:td>Apples</h:td>" +
                "      <h:td>Bananas</h:td>" +
                "    </h:tr>" +
                "  </h:table>" +
            "</root>"

            beforeEach {
                parser = SWXMLHash.config { conf in
                    conf.shouldProcessNamespaces = true
                }.parse(xmlWithNamespace)
            }

            it("should allow processing namespaces or not") {
                expect(parser["root"]["table"]["tr"]["td"][0].element?.text).to(equal("Apples"))
            }
        }
    }
}
