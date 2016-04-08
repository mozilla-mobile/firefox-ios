var prettyPrint = require("./utils").prettyPrint;
var jsdom = require("jsdom").jsdom;
var chai = require("chai");
chai.config.includeStack = true;
var expect = chai.expect;

var readability = require("../index");
var Readability = readability.Readability;
var JSDOMParser = readability.JSDOMParser;

var testPages = require("./utils").getTestPages();

function reformatError(err) {
  var formattedError = new Error(err.message);
  formattedError.stack = err.stack;
  return formattedError;
}

function inOrderTraverse(fromNode) {
  if (fromNode.firstChild) {
    return fromNode.firstChild;
  }
  while (fromNode && !fromNode.nextSibling) {
    fromNode = fromNode.parentNode;
  }
  return fromNode ? fromNode.nextSibling : null;
}

function inOrderIgnoreEmptyTextNodes(fromNode) {
  do {
    fromNode = inOrderTraverse(fromNode);
  } while (fromNode && fromNode.nodeType == 3 && !fromNode.textContent.trim());
  return fromNode;
}

function traverseDOM(callback, expectedDOM, actualDOM) {
  var actualNode = actualDOM.documentElement || actualDOM.childNodes[0];
  var expectedNode = expectedDOM.documentElement || expectedDOM.childNodes[0];
  while (actualNode) {
    if (!callback(actualNode, expectedNode)) {
      break;
    }
    actualNode = inOrderIgnoreEmptyTextNodes(actualNode);
    expectedNode = inOrderIgnoreEmptyTextNodes(expectedNode);
  }
}

// Collapse subsequent whitespace like HTML:
function htmlTransform(str) {
  return str.replace(/\s+/g, " ");
}

function runTestsWithItems(label, domGenerationFn, uri, source, expectedContent, expectedMetadata) {
  describe(label, function() {
    this.timeout(5000);

    var result;

    before(function() {
      try {
        var doc = domGenerationFn(source);
        var readability = new Readability(uri, doc);
        var readerable = readability.isProbablyReaderable();
        result = readability.parse();
        result.readerable = readerable;
      } catch(err) {
        throw reformatError(err);
      }
    });

    it("should return a result object", function() {
      expect(result).to.include.keys("content", "title", "excerpt", "byline");
    });

    it("should extract expected content", function() {
      function nodeStr(n) {
        if (n.nodeType == 3) {
          return "#text(" + htmlTransform(n.textContent) + ")";
        }
        var rv = n.localName;
        if (n.id) {
          rv += "#" + n.id;
        }
        if (n.className) {
          rv += ".(" + n.className + ")";
        }
        return rv;
      }
      var actualDOM = domGenerationFn(result.content);
      var expectedDOM = domGenerationFn(expectedContent);
      traverseDOM(function(actualNode, expectedNode) {
        expect(!!actualNode).eql(!!expectedNode);
        if (actualNode && expectedNode) {
          var actualDesc = nodeStr(actualNode);
          var expectedDesc = nodeStr(expectedNode);
          if (actualDesc != expectedDesc) {
            expect(actualDesc).eql(expectedDesc);
            return false;
          }
          // Compare text for text nodes:
          if (actualNode.nodeType == 3) {
            var actualText = htmlTransform(actualNode.textContent);
            var expectedText = htmlTransform(expectedNode.textContent);
            expect(actualText).eql(expectedText);
            if (actualText != expectedText) {
              return false;
            }
          // Compare attributes for element nodes:
          } else if (actualNode.nodeType == 1) {
            expect(actualNode.attributes.length).eql(expectedNode.attributes.length);
            for (var i = 0; i < actualNode.attributes.length; i++) {
              var attr = actualNode.attributes[i].name;
              var actualValue = actualNode.getAttribute(attr);
              var expectedValue = expectedNode.getAttribute(attr);
              expect(expectedValue, "node '" + actualDesc + "' attribute " + attr + " should match").eql(actualValue);
            }
          }
        } else {
          return false;
        }
        return true;
      }, actualDOM, expectedDOM);
    });

    it("should extract expected title", function() {
      expect(expectedMetadata.title).eql(result.title);
    });

    it("should extract expected byline", function() {
      expect(expectedMetadata.byline).eql(result.byline);
    });

    it("should extract expected excerpt", function() {
      expect(expectedMetadata.excerpt).eql(result.excerpt);
    });

    it("should probably be readerable", function() {
      expect(expectedMetadata.readerable).eql(result.readerable);
    });
  });
}

function removeCommentNodesRecursively(node) {
  [].forEach.call(node.childNodes, function(child) {
    if (child.nodeType === child.COMMENT_NODE) {
      node.removeChild(child);
    } else if (child.nodeType === child.ELEMENT_NODE) {
      removeCommentNodesRecursively(child);
    }
  });
}

describe("Readability API", function() {
  describe("#constructor", function() {
    it("should accept a debug option", function() {
      expect(new Readability({}, {})._debug).eql(false);
      expect(new Readability({}, {}, {debug: true})._debug).eql(true);
    });

    it("should accept a nbTopCandidates option", function() {
      expect(new Readability({}, {})._nbTopCandidates).eql(5);
      expect(new Readability({}, {}, {nbTopCandidates: 42})._nbTopCandidates).eql(42);
    });

    it("should accept a maxPages option", function() {
      expect(new Readability({}, {})._maxPages).eql(5);
      expect(new Readability({}, {}, {maxPages: 42})._maxPages).eql(42);
    });

    it("should accept a maxElemsToParse option", function() {
      expect(new Readability({}, {})._maxElemsToParse).eql(0);
      expect(new Readability({}, {}, {maxElemsToParse: 42})._maxElemsToParse).eql(42);
    });
  });

  describe("#parse", function() {
    it("shouldn't parse oversized documents as per configuration", function() {
      var doc = new JSDOMParser().parse("<html><div>yo</div></html>");
      expect(function() {
        new Readability({}, doc, {maxElemsToParse: 1}).parse();
      }).to.Throw("Aborting parsing document; 2 elements found");
    });
  });
});

describe("Test pages", function() {
  testPages.forEach(function(testPage) {
    describe(testPage.dir, function() {
      var uri = {
        spec: "http://fakehost/test/page.html",
        host: "fakehost",
        prePath: "http://fakehost",
        scheme: "http",
        pathBase: "http://fakehost/test/"
      };

      runTestsWithItems("jsdom", function(source) {
        var doc = jsdom(source, {
          features: {
            FetchExternalResources: false,
            ProcessExternalResources: false
          }
        });
        removeCommentNodesRecursively(doc);
        return doc;
      }, uri, testPage.source, testPage.expectedContent, testPage.expectedMetadata);

      runTestsWithItems("JSDOMParser", function(source) {
        var parser = new JSDOMParser();
        var doc = parser.parse(source);
        if (parser.errorState) {
          console.error("Parsing this DOM caused errors:", parser.errorState);
          return null;
        }
        return doc;
      }, uri, testPage.source, testPage.expectedContent, testPage.expectedMetadata);
    });
  });
});
