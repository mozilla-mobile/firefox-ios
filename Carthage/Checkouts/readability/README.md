# Readability.js

[![Build Status](https://travis-ci.org/mozilla/readability.svg?branch=master)](https://travis-ci.org/mozilla/readability)

A standalone version of the readability library used for Firefox Reader View. Any changes to Readability.js itself should be reviewed by an appropriate Firefox/toolkit peer, such as [@leibovic](https://github.com/leibovic) or [@thebnich](https://github.com/thebnich), since these changes will be automatically merged to mozilla-central.

## Contributing

For outstanding issues, see the issue list in this repo, as well as this bug list: https://bugzilla.mozilla.org/show_bug.cgi?id=1102450

To test local changes to Readability.js, you can run your own instance of [readable-proxy](https://github.com/n1k0/readable-proxy/) to compare an original test page to its reader-ized content.

## Usage

To parse a document, you must create a new `Readability` object from a URI object and a document, and then call `parse()`. Here's an example:

```javascript
var location = document.location;
var uri = {
  spec: location.href,
  host: location.host,
  prePath: location.protocol + "//" + location.host,
  scheme: location.protocol.substr(0, location.protocol.indexOf(":")),
  pathBase: location.protocol + "//" + location.host + location.pathname.substr(0, location.pathname.lastIndexOf("/") + 1)
};
var article = new Readability(uri, document).parse();
```

This `article` object will contain the following properties:

* `uri`: original `uri` object that was passed to constructor
* `title`: article title
* `content`: HTML string of processed article content
* `length`: length of article, in characters
* `excerpt`: article description, or short excerpt from content
* `byline`: author metadata
* `dir`: content direction

### Optional

Readability's `parse()` works by modifying the DOM. This removes some elements in the web page. You could avoid this by passing the clone of the `document` object while creating a `Readability` object.


```
var documentClone = document.cloneNode(true); 
var article = new Readability(uri, documentClone).parse();   
```

## Tests

To run the test suite:

    $ mocha test/test-*.js

To run a specific test page by its name:

    $ mocha test/test-*.js -g 001

To run the test suite in TDD mode:

    $ mocha test/test-*.js -w

Combo time:

    $ mocha test/test-*.js -w -g 001

## Benchmarks

Benchmarks for all test pages:

    $ npm run perf

Reference benchmark:

    $ npm run perf-reference

## License

    Copyright (c) 2010 Arc90 Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
