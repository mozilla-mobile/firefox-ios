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

function runTestsWithItems(label, beforeFn, expectedContent, expectedMetadata) {
  describe(label, function() {
    this.timeout(5000);

    var result;

    before(function() {
      try {
        result = beforeFn();
      } catch(err) {
        throw reformatError(err);
      }
    });

    it("should return a result object", function() {
      expect(result).to.include.keys("content", "title", "excerpt", "byline");
    });

    it("should extract expected content", function() {
      expect(expectedContent.split("\n")).eql(prettyPrint(result.content).split("\n"));
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

      runTestsWithItems("jsdom", function() {
        var doc = jsdom(testPage.source, {
          features: {
            FetchExternalResources: false,
            ProcessExternalResources: false
          }
        });
        removeCommentNodesRecursively(doc);
        var readability = new Readability(uri, doc);
        var readerable = readability.isProbablyReaderable();
        var result = readability.parse();
        result.readerable = readerable;
        return result;
      }, testPage.expectedContent, testPage.expectedMetadata);

      runTestsWithItems("JSDOMParser", function() {
        var doc = new JSDOMParser().parse(testPage.source);
        var readability = new Readability(uri, doc);
        var readerable = readability.isProbablyReaderable();
        var result = readability.parse();
        result.readerable = readerable;
        return result;
      }, testPage.expectedContent, testPage.expectedMetadata);
    });
  });
});
