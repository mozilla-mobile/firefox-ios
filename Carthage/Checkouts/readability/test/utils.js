var path = require("path");
var fs = require("fs");
var prettyPrint = require("js-beautify").html;

function readFile(path) {
  return fs.readFileSync(path, {encoding: "utf-8"}).trim();
}

function readJSON(path) {
  return JSON.parse(readFile(path));
}

var testPageRoot = path.join(__dirname, "test-pages");

exports.getTestPages = function() {
  return fs.readdirSync(testPageRoot).map(function(dir) {
    return {
      dir: dir,
      source: readFile(path.join(testPageRoot, dir, "source.html")),
      expectedContent: readFile(path.join(testPageRoot, dir, "expected.html")),
      expectedMetadata: readJSON(path.join(testPageRoot, dir, "expected-metadata.json")),
    };
  });
};

exports.prettyPrint = function(html) {
  return prettyPrint(html, {
    "indent_size": 4,
    "indent_char": " ",
    "indent_level": 0,
    "indent_with_tabs": false,
    "preserve_newlines": false,
    "break_chained_methods": false,
    "eval_code": false,
    "unescape_strings": false,
    "wrap_line_length": 0,
    "wrap_attributes": "auto",
    "wrap_attributes_indent_size": 4
  });
}
