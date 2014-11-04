/*
 * Copyright (c) 2010 Arc90 Inc
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * This code is heavily based on Arc90's readability.js (1.7.1) script
 * available at: http://code.google.com/p/arc90labs-readability
 */

var Readability = function(uri, doc) {
  const ENABLE_LOGGING = false;

  this._uri = uri;
  this._doc = doc;
  this._biggestFrame = false;
  this._articleByline = null;
  this._articleDir = null;

  // Start with all flags set
  this._flags = this.FLAG_STRIP_UNLIKELYS |
                this.FLAG_WEIGHT_CLASSES |
                this.FLAG_CLEAN_CONDITIONALLY;

  // The list of pages we've parsed in this call of readability,
  // for autopaging. As a key store for easier searching.
  this._parsedPages = {};

  // A list of the ETag headers of pages we've parsed, in case they happen to match,
  // we'll know it's a duplicate.
  this._pageETags = {};

  // Make an AJAX request for each page and append it to the document.
  this._curPageNum = 1;

  // Control whether log messages are sent to the console
  if (ENABLE_LOGGING) {
    this.log = function (msg) {
      dump("Reader: (Readability) " + msg);
    };
  } else {
    this.log = function () {};
  }
}

Readability.prototype = {
  FLAG_STRIP_UNLIKELYS: 0x1,
  FLAG_WEIGHT_CLASSES: 0x2,
  FLAG_CLEAN_CONDITIONALLY: 0x4,

  // The number of top candidates to consider when analysing how
  // tight the competition is among candidates.
  N_TOP_CANDIDATES: 5,

  // The maximum number of pages to loop through before we call
  // it quits and just show a link.
  MAX_PAGES: 5,

  // All of the regular expressions in use within readability.
  // Defined up here so we don't instantiate them repeatedly in loops.
  REGEXPS: {
    unlikelyCandidates: /combx|comment|community|disqus|extra|foot|header|menu|remark|rss|shoutbox|sidebar|sponsor|ad-break|agegate|pagination|pager|popup|tweet|twitter/i,
    okMaybeItsACandidate: /and|article|body|column|main|shadow/i,
    positive: /article|body|content|entry|hentry|main|page|pagination|post|text|blog|story/i,
    negative: /hidden|combx|comment|com-|contact|foot|footer|footnote|masthead|media|meta|outbrain|promo|related|scroll|shoutbox|sidebar|sponsor|shopping|tags|tool|widget/i,
    extraneous: /print|archive|comment|discuss|e[\-]?mail|share|reply|all|login|sign|single|utility/i,
    byline: /byline|author|dateline|writtenby/i,
    replaceFonts: /<(\/?)font[^>]*>/gi,
    trim: /^\s+|\s+$/g,
    normalize: /\s{2,}/g,
    videos: /http:\/\/(www\.)?(youtube|vimeo)\.com/i,
    nextLink: /(next|weiter|continue|>([^\|]|$)|»([^\|]|$))/i,
    prevLink: /(prev|earl|old|new|<|«)/i,
    whitespace: /^\s*$/
  },

  DIV_TO_P_ELEMS: [ "A", "BLOCKQUOTE", "DL", "DIV", "IMG", "OL", "P", "PRE", "TABLE", "UL", "SELECT" ],

  /**
   * Run any post-process modifications to article content as necessary.
   *
   * @param Element
   * @return void
  **/
  _postProcessContent: function(articleContent) {
    // Readability cannot open relative uris so we convert them to absolute uris.
    this._fixRelativeUris(articleContent);
  },

  /**
   * Converts each <a> and <img> uri in the given element to an absolute URI.
   *
   * @param Element
   * @return void
   */
  _fixRelativeUris: function(articleContent) {
    var scheme = this._uri.scheme;
    var prePath = this._uri.prePath;
    var pathBase = this._uri.pathBase;

    function toAbsoluteURI(uri) {
      // If this is already an absolute URI, return it.
      if (/^[a-zA-Z][a-zA-Z0-9\+\-\.]*:/.test(uri))
        return uri;

      // Scheme-rooted relative URI.
      if (uri.substr(0, 2) == "//")
        return scheme + "://" + uri.substr(2);

      // Prepath-rooted relative URI.
      if (uri[0] == "/")
        return prePath + uri;

      // Standard relative URI; add entire path. pathBase already includes a
      // trailing "/".
      return pathBase + uri;
    }

    function convertRelativeURIs(tagName, propName) {
      var elems = articleContent.getElementsByTagName(tagName);
      for (var i = elems.length; --i >= 0;) {
        var elem = elems[i];
        var relativeURI = elem.getAttribute(propName);
        if (relativeURI != null)
          elems[i].setAttribute(propName, toAbsoluteURI(relativeURI));
      }
    }

     // Fix links.
    convertRelativeURIs("a", "href");

     // Fix images.
    convertRelativeURIs("img", "src");
  },

  /**
   * Get the article title as an H1.
   *
   * @return void
   **/
  _getArticleTitle: function() {
    var doc = this._doc;
    var curTitle = "";
    var origTitle = "";

    try {
      curTitle = origTitle = doc.title;

      // If they had an element with id "title" in their HTML
      if (typeof curTitle !== "string")
        curTitle = origTitle = this._getInnerText(doc.getElementsByTagName('title')[0]);
    } catch(e) {}

    if (curTitle.match(/ [\|\-] /)) {
      curTitle = origTitle.replace(/(.*)[\|\-] .*/gi,'$1');

      if (curTitle.split(' ').length < 3)
        curTitle = origTitle.replace(/[^\|\-]*[\|\-](.*)/gi,'$1');
    } else if (curTitle.indexOf(': ') !== -1) {
      curTitle = origTitle.replace(/.*:(.*)/gi, '$1');

      if (curTitle.split(' ').length < 3)
        curTitle = origTitle.replace(/[^:]*[:](.*)/gi,'$1');
    } else if (curTitle.length > 150 || curTitle.length < 15) {
      var hOnes = doc.getElementsByTagName('h1');

      if (hOnes.length === 1)
        curTitle = this._getInnerText(hOnes[0]);
    }

    curTitle = curTitle.replace(this.REGEXPS.trim, "");

    if (curTitle.split(' ').length <= 4)
      curTitle = origTitle;

    return curTitle;
  },

  /**
   * Prepare the HTML document for readability to scrape it.
   * This includes things like stripping javascript, CSS, and handling terrible markup.
   *
   * @return void
   **/
  _prepDocument: function() {
    var doc = this._doc;

    // In some cases a body element can't be found (if the HTML is
    // totally hosed for example) so we create a new body node and
    // append it to the document.
    if (doc.body === null) {
      var body = doc.createElement("body");

      try {
        doc.body = body;
      } catch(e) {
        doc.documentElement.appendChild(body);
        this.log(e);
      }
    }

    // Remove all style tags in head
    var styleTags = doc.getElementsByTagName("style");
    for (var st = 0; st < styleTags.length; st += 1) {
      styleTags[st].textContent = "";
    }

    this._replaceBrs(doc.body);

    var fonts = doc.getElementsByTagName("FONT");
    for (var i = fonts.length; --i >=0;) {
      this._setNodeTag(fonts[i], "SPAN");
    }
  },

  /**
   * Finds the next element, starting from the given node, and ignoring
   * whitespace in between. If the given node is an element, the same node is
   * returned.
   */
  _nextElement: function (node) {
    var next = node;
    while (next
        && (next.nodeType != Node.ELEMENT_NODE)
        && this.REGEXPS.whitespace.test(next.textContent)) {
      next = next.nextSibling;
    }
    return next;
  },

  /**
   * Replaces 2 or more successive <br> elements with a single <p>.
   * Whitespace between <br> elements are ignored. For example:
   *   <div>foo<br>bar<br> <br><br>abc</div>
   * will become:
   *   <div>foo<br>bar<p>abc</p></div>
   */
  _replaceBrs: function (elem) {
    var brs = elem.getElementsByTagName("br");
    for (var i = 0; i < brs.length; i++) {
      var br = brs[i];
      var next = br.nextSibling;

      // Whether 2 or more <br> elements have been found and replaced with a
      // <p> block.
      var replaced = false;

      // If we find a <br> chain, remove the <br>s until we hit another element
      // or non-whitespace. This leaves behind the first <br> in the chain
      // (which will be replaced with a <p> later).
      while ((next = this._nextElement(next)) && (next.tagName == "BR")) {
        replaced = true;
        var sibling = next.nextSibling;
        next.parentNode.removeChild(next);
        next = sibling;
      }

      // If we removed a <br> chain, replace the remaining <br> with a <p>. Add
      // all sibling nodes as children of the <p> until we hit another <br>
      // chain.
      if (replaced) {
        var p = this._doc.createElement("p");
        br.parentNode.replaceChild(p, br);

        next = p.nextSibling;
        while (next) {
          // If we've hit another <br><br>, we're done adding children to this <p>.
          if (next.tagName == "BR") {
            var nextElem = this._nextElement(next);
            if (nextElem && nextElem.tagName == "BR")
              break;
          }

          // Otherwise, make this node a child of the new <p>.
          var sibling = next.nextSibling;
          p.appendChild(next);
          next = sibling;
        }
      }
    }
  },

  _setNodeTag: function (node, tag) {
    node.localName = tag.toLowerCase();
    node.tagName = tag.toUpperCase();
  },

  /**
   * Prepare the article node for display. Clean out any inline styles,
   * iframes, forms, strip extraneous <p> tags, etc.
   *
   * @param Element
   * @return void
   **/
  _prepArticle: function(articleContent) {
    this._cleanStyles(articleContent);

    // Clean out junk from the article content
    this._cleanConditionally(articleContent, "form");
    this._clean(articleContent, "object");
    this._clean(articleContent, "h1");

    // If there is only one h2, they are probably using it as a header
    // and not a subheader, so remove it since we already have a header.
    if (articleContent.getElementsByTagName('h2').length === 1)
      this._clean(articleContent, "h2");

    this._clean(articleContent, "iframe");
    this._cleanHeaders(articleContent);

    // Do these last as the previous stuff may have removed junk
    // that will affect these
    this._cleanConditionally(articleContent, "table");
    this._cleanConditionally(articleContent, "ul");
    this._cleanConditionally(articleContent, "div");

    // Remove extra paragraphs
    var articleParagraphs = articleContent.getElementsByTagName('p');
    for (var i = articleParagraphs.length - 1; i >= 0; i -= 1) {
      var imgCount = articleParagraphs[i].getElementsByTagName('img').length;
      var embedCount = articleParagraphs[i].getElementsByTagName('embed').length;
      var objectCount = articleParagraphs[i].getElementsByTagName('object').length;

      if (imgCount === 0 &&
        embedCount === 0 &&
        objectCount === 0 &&
        this._getInnerText(articleParagraphs[i], false) === '')
        articleParagraphs[i].parentNode.removeChild(articleParagraphs[i]);
    }

    var brs = articleContent.getElementsByTagName("BR");
    for (var i = brs.length; --i >= 0;) {
      var br = brs[i];
      var next = this._nextElement(br.nextSibling);
      if (next && next.tagName == "P")
        br.parentNode.removeChild(br);
    }
  },

  /**
   * Initialize a node with the readability object. Also checks the
   * className/id for special names to add to its score.
   *
   * @param Element
   * @return void
  **/
  _initializeNode: function(node) {
    node.readability = {"contentScore": 0};

    switch(node.tagName) {
      case 'DIV':
        node.readability.contentScore += 5;
        break;

      case 'PRE':
      case 'TD':
      case 'BLOCKQUOTE':
        node.readability.contentScore += 3;
        break;

      case 'ADDRESS':
      case 'OL':
      case 'UL':
      case 'DL':
      case 'DD':
      case 'DT':
      case 'LI':
      case 'FORM':
        node.readability.contentScore -= 3;
        break;

      case 'H1':
      case 'H2':
      case 'H3':
      case 'H4':
      case 'H5':
      case 'H6':
      case 'TH':
        node.readability.contentScore -= 5;
        break;
    }

    node.readability.contentScore += this._getClassWeight(node);
  },

  /***
   * grabArticle - Using a variety of metrics (content score, classname, element types), find the content that is
   *         most likely to be the stuff a user wants to read. Then return it wrapped up in a div.
   *
   * @param page a document to run upon. Needs to be a full document, complete with body.
   * @return Element
  **/
  _grabArticle: function (page) {
    var doc = this._doc;
    var isPaging = (page !== null ? true: false);
    page = page ? page : this._doc.body;
    var pageCacheHtml = page.innerHTML;

    // Check if any "dir" is set on the toplevel document element
    this._articleDir = doc.documentElement.getAttribute("dir");

    while (true) {
      var stripUnlikelyCandidates = this._flagIsActive(this.FLAG_STRIP_UNLIKELYS);
      var allElements = page.getElementsByTagName('*');

      // First, node prepping. Trash nodes that look cruddy (like ones with the
      // class name "comment", etc), and turn divs into P tags where they have been
      // used inappropriately (as in, where they contain no other block level elements.)
      //
      // Note: Assignment from index for performance. See http://www.peachpit.com/articles/article.aspx?p=31567&seqNum=5
      // TODO: Shouldn't this be a reverse traversal?
      var node = null;
      var nodesToScore = [];

      // var each node know its index in the allElements array.
      for (var i = allElements.length; --i >= 0;) {
        allElements[i]._index = i;
      }

      /**
       * JSDOMParser returns static node lists, not live ones. When we remove
       * an element from the document, we need to manually remove it - and all
       * of its children - from the allElements array.
       */
      function purgeNode(node) {
        for (var i = node.childNodes.length; --i >= 0;) {
          purgeNode(node.childNodes[i]);
        }
        if (node._index !== undefined && allElements[node._index] == node)
          delete allElements[node._index];
      }

      for (var nodeIndex = 0; nodeIndex < allElements.length; nodeIndex++) {
        if (!(node = allElements[nodeIndex]))
          continue;

        var matchString = node.className + node.id;
        if (matchString.search(this.REGEXPS.byline) !== -1 && !this._articleByline) {
          if (this._isValidByline(node.textContent)) {
            this._articleByline = node.textContent.trim();
            node.parentNode.removeChild(node);
            purgeNode(node);
            continue;
          }
        }

        // Remove unlikely candidates
        if (stripUnlikelyCandidates) {
          if (matchString.search(this.REGEXPS.unlikelyCandidates) !== -1 &&
            matchString.search(this.REGEXPS.okMaybeItsACandidate) === -1 &&
            node.tagName !== "BODY") {
            this.log("Removing unlikely candidate - " + matchString);
            node.parentNode.removeChild(node);
            purgeNode(node);
            continue;
          }
        }

        if (node.tagName === "P" || node.tagName === "TD" || node.tagName === "PRE")
          nodesToScore[nodesToScore.length] = node;

        // Turn all divs that don't have children block level elements into p's
        if (node.tagName === "DIV") {
          // Sites like http://mobile.slate.com encloses each paragraph with a DIV
          // element. DIVs with only a P element inside and no text content can be
          // safely converted into plain P elements to avoid confusing the scoring
          // algorithm with DIVs with are, in practice, paragraphs.
          var pIndex = this._getSinglePIndexInsideDiv(node);

          if (pIndex >= 0 || !this._hasChildBlockElement(node)) {
            if (pIndex >= 0) {
              var newNode = node.childNodes[pIndex];
              node.parentNode.replaceChild(newNode, node);
              purgeNode(node);
            } else {
              this._setNodeTag(node, "P");
              nodesToScore[nodesToScore.length] = node;
            }
          } else {
            // EXPERIMENTAL
            for (var i = 0, il = node.childNodes.length; i < il; i += 1) {
              var childNode = node.childNodes[i];
              if (!childNode)
                continue;

              if (childNode.nodeType === 3) { // Node.TEXT_NODE
                var p = doc.createElement('p');
                p.textContent = childNode.textContent;
                p.style.display = 'inline';
                p.className = 'readability-styled';
                childNode.parentNode.replaceChild(p, childNode);
              }
            }
          }
        }
      }

      /**
       * Loop through all paragraphs, and assign a score to them based on how content-y they look.
       * Then add their score to their parent node.
       *
       * A score is determined by things like number of commas, class names, etc. Maybe eventually link density.
      **/
      var candidates = [];
      for (var pt = 0; pt < nodesToScore.length; pt += 1) {
        var parentNode = nodesToScore[pt].parentNode;
        var grandParentNode = parentNode ? parentNode.parentNode : null;
        var innerText = this._getInnerText(nodesToScore[pt]);

        if (!parentNode || typeof(parentNode.tagName) === 'undefined')
          continue;

        // If this paragraph is less than 25 characters, don't even count it.
        if (innerText.length < 25)
          continue;

        // Initialize readability data for the parent.
        if (typeof parentNode.readability === 'undefined') {
          this._initializeNode(parentNode);
          candidates.push(parentNode);
        }

        // Initialize readability data for the grandparent.
        if (grandParentNode &&
          typeof(grandParentNode.readability) === 'undefined' &&
          typeof(grandParentNode.tagName) !== 'undefined') {
          this._initializeNode(grandParentNode);
          candidates.push(grandParentNode);
        }

        var contentScore = 0;

        // Add a point for the paragraph itself as a base.
        contentScore += 1;

        // Add points for any commas within this paragraph.
        contentScore += innerText.split(',').length;

        // For every 100 characters in this paragraph, add another point. Up to 3 points.
        contentScore += Math.min(Math.floor(innerText.length / 100), 3);

        // Add the score to the parent. The grandparent gets half.
        parentNode.readability.contentScore += contentScore;

        if (grandParentNode)
          grandParentNode.readability.contentScore += contentScore / 2;
      }

      // After we've calculated scores, loop through all of the possible
      // candidate nodes we found and find the one with the highest score.
      var topCandidates = [];
      for (var c = 0, cl = candidates.length; c < cl; c += 1) {
        var candidate = candidates[c];

        // Scale the final candidates score based on link density. Good content
        // should have a relatively small link density (5% or less) and be mostly
        // unaffected by this operation.
        var candidateScore = candidate.readability.contentScore * (1 - this._getLinkDensity(candidate));
        candidate.readability.contentScore = candidateScore;

        this.log('Candidate: ' + candidate + " (" + candidate.className + ":" +
          candidate.id + ") with score " + candidateScore);

        for (var t = 0; t < this.N_TOP_CANDIDATES; t++) {
          var aTopCandidate = topCandidates[t];

          if (!aTopCandidate || candidateScore > aTopCandidate.readability.contentScore) {
            topCandidates.splice(t, 0, candidate);
            if (topCandidates.length > this.N_TOP_CANDIDATES)
              topCandidates.pop();
            break;
          }
        }
      }

      var topCandidate = topCandidates[0] || null;
      var lastTopCandidate = (topCandidates.length > 3 ? topCandidates[topCandidates.length - 1] : null);

      // If we still have no top candidate, just use the body as a last resort.
      // We also have to copy the body node so it is something we can modify.
      if (topCandidate === null || topCandidate.tagName === "BODY") {
        // Move all of the page's children into topCandidate
        topCandidate = doc.createElement("DIV");
        var children = page.childNodes;
        for (var i = 0; i < children.length; ++i) {
          topCandidate.appendChild(children[i]);
        }

        page.appendChild(topCandidate);

        this._initializeNode(topCandidate);
      }

      // Now that we have the top candidate, look through its siblings for content
      // that might also be related. Things like preambles, content split by ads
      // that we removed, etc.
      var articleContent = doc.createElement("DIV");
      if (isPaging)
        articleContent.id = "readability-content";

      var siblingScoreThreshold = Math.max(10, topCandidate.readability.contentScore * 0.2);
      var siblingNodes = topCandidate.parentNode.childNodes;

      for (var s = 0, sl = siblingNodes.length; s < sl; s += 1) {
        var siblingNode = siblingNodes[s];
        var append = false;

        this.log("Looking at sibling node: " + siblingNode + " (" + siblingNode.className + ":" + siblingNode.id + ")" + ((typeof siblingNode.readability !== 'undefined') ? (" with score " + siblingNode.readability.contentScore) : ''));
        this.log("Sibling has score " + (siblingNode.readability ? siblingNode.readability.contentScore : 'Unknown'));

        if (siblingNode === topCandidate)
          append = true;

        var contentBonus = 0;

        // Give a bonus if sibling nodes and top candidates have the example same classname
        if (siblingNode.className === topCandidate.className && topCandidate.className !== "")
          contentBonus += topCandidate.readability.contentScore * 0.2;

        if (typeof siblingNode.readability !== 'undefined' &&
          (siblingNode.readability.contentScore+contentBonus) >= siblingScoreThreshold)
          append = true;

        if (siblingNode.nodeName === "P") {
          var linkDensity = this._getLinkDensity(siblingNode);
          var nodeContent = this._getInnerText(siblingNode);
          var nodeLength = nodeContent.length;

          if (nodeLength > 80 && linkDensity < 0.25) {
            append = true;
          } else if (nodeLength < 80 && linkDensity === 0 && nodeContent.search(/\.( |$)/) !== -1) {
            append = true;
          }
        }

        if (append) {
          this.log("Appending node: " + siblingNode);

          // siblingNodes is a reference to the childNodes array, and
          // siblingNode is removed from the array when we call appendChild()
          // below. As a result, we must revisit this index since the nodes
          // have been shifted.
          s -= 1;
          sl -= 1;

          if (siblingNode.nodeName !== "DIV" && siblingNode.nodeName !== "P") {
            // We have a node that isn't a common block level element, like a form or td tag.
            // Turn it into a div so it doesn't get filtered out later by accident. */
            this.log("Altering siblingNode of " + siblingNode.nodeName + ' to div.');

            this._setNodeTag(siblingNode, "DIV");
          }

          // To ensure a node does not interfere with readability styles,
          // remove its classnames.
          siblingNode.className = "";

          // Append sibling and subtract from our list because it removes
          // the node when you append to another node.
          articleContent.appendChild(siblingNode);
        }
      }

      // So we have all of the content that we need. Now we clean it up for presentation.
      this._prepArticle(articleContent);

      if (this._curPageNum === 1) {
        var div = doc.createElement("DIV");
        div.id = "readability-page-1";
        div.className = "page";
        var children = articleContent.childNodes;
        for (var i = 0; i < children.length; ++i) {
          div.appendChild(children[i]);
        }
        articleContent.appendChild(div);
      }

      // Now that we've gone through the full algorithm, check to see if
      // we got any meaningful content. If we didn't, we may need to re-run
      // grabArticle with different flags set. This gives us a higher likelihood of
      // finding the content, and the sieve approach gives us a higher likelihood of
      // finding the -right- content.
      if (this._getInnerText(articleContent, true).length < 500) {
        page.innerHTML = pageCacheHtml;

        if (this._flagIsActive(this.FLAG_STRIP_UNLIKELYS)) {
          this._removeFlag(this.FLAG_STRIP_UNLIKELYS);
        } else if (this._flagIsActive(this.FLAG_WEIGHT_CLASSES)) {
          this._removeFlag(this.FLAG_WEIGHT_CLASSES);
        } else if (this._flagIsActive(this.FLAG_CLEAN_CONDITIONALLY)) {
          this._removeFlag(this.FLAG_CLEAN_CONDITIONALLY);
        } else {
          return null;
        }
      } else {
        if (lastTopCandidate !== null) {
          // EXPERIMENTAL: Contrast ratio is how we measure the level of competition between candidates in the
          // readability algorithm. This is to avoid offering reader mode on pages that are more like
          // a list or directory of links with summaries. It takes the score of the last top candidate
          // (see N_TOP_CANDIDATES) and checks how it compares to the top candidate's. On pages that are not
          // actual articles, there will likely be many candidates with similar score (i.e. higher contrast ratio).
          var contrastRatio = lastTopCandidate.readability.contentScore / topCandidate.readability.contentScore;
          if (contrastRatio > 0.45)
            return null;
        }

        return articleContent;
      }
    }
  },

  /**
   * Check whether the input string could be a byline.
   * This verifies that the input is a string, and that the length
   * is less than 100 chars.
   *
   * @param possibleByline {string} - a string to check whether its a byline.
   * @return Boolean - whether the input string is a byline.
   */
  _isValidByline: function(byline) {
    if (typeof byline == 'string' || byline instanceof String) {
      byline = byline.trim();
      return (byline.length > 0) && (byline.length < 100);
    }
    return false;
  },

  /**
   * Attempts to get the excerpt from these
   * sources in the following order:
   * - meta description tag
   * - open-graph description
   * - twitter cards description
   * - article's first paragraph
   * If no excerpt is found, an empty string will be
   * returned.
   *
   * @param Element - root element of the processed version page
   * @return String - excerpt of the article
  **/
  _getExcerpt: function(articleContent) {
    var values = {};
    var metaElements = this._doc.getElementsByTagName("meta");

    // Match "description", or Twitter's "twitter:description" (Cards)
    // in name attribute.
    var namePattern = /^\s*((twitter)\s*:\s*)?description\s*$/gi;

    // Match Facebook's og:description (Open Graph) in property attribute.
    var propertyPattern = /^\s*og\s*:\s*description\s*$/gi;

    // Find description tags.
    for (var i = 0; i < metaElements.length; i++) {
      var element = metaElements[i];
      var elementName = element.getAttribute("name");
      var elementProperty = element.getAttribute("property");

      var name;
      if (namePattern.test(elementName)) {
        name = elementName;
      } else if (propertyPattern.test(elementProperty)) {
        name = elementProperty;
      }

      if (name) {
        var content = element.getAttribute("content");
        if (content) {
          // Convert to lowercase and remove any whitespace
          // so we can match below.
          name = name.toLowerCase().replace(/\s/g, '');
          values[name] = content.trim();
        }
      }
    }

    if ("description" in values) {
      return values["description"];
    }

    if ("og:description" in values) {
      // Use facebook open graph description.
      return values["og:description"];
    }

    if ("twitter:description" in values) {
      // Use twitter cards description.
      return values["twitter:description"];
    }

    // No description meta tags, use the article's first paragraph.
    var paragraphs = articleContent.getElementsByTagName("p");
    if (paragraphs.length > 0) {
      return paragraphs[0].textContent;
    }

    return "";
  },

  /**
   * Removes script tags from the document.
   *
   * @param Element
  **/
  _removeScripts: function(doc) {
    var scripts = doc.getElementsByTagName('script');
    for (var i = scripts.length - 1; i >= 0; i -= 1) {
      scripts[i].nodeValue="";
      scripts[i].removeAttribute('src');

      if (scripts[i].parentNode)
          scripts[i].parentNode.removeChild(scripts[i]);
    }
  },

  /**
   * Get child index of the only P element inside a DIV with no
   * text content. Returns -1 if the DIV node contains non-empty
   * text nodes or if it contains other element nodes.
   *
   * @param Element
  **/
  _getSinglePIndexInsideDiv: function(e) {
    var childNodes = e.childNodes;
    var pIndex = -1;

    for (var i = childNodes.length; --i >= 0;) {
      var node = childNodes[i];

      if (node.nodeType === Node.ELEMENT_NODE) {
        if (node.tagName !== "P")
          return -1;

        if (pIndex >= 0)
          return -1;

        pIndex = i;
      } else if (node.nodeType == Node.TEXT_NODE && this._getInnerText(node, false)) {
        return -1;
      }
    }

    return pIndex;
  },

  /**
   * Determine whether element has any children block level elements.
   *
   * @param Element
   */
  _hasChildBlockElement: function (e) {
    var length = e.childNodes.length;
    for (var i = 0; i < length; i++) {
      var child = e.childNodes[i];
      if (child.nodeType != 1)
        continue;

      if (this.DIV_TO_P_ELEMS.indexOf(child.tagName) !== -1 || this._hasChildBlockElement(child))
        return true;
    }
    return false;
  },

  /**
   * Get the inner text of a node - cross browser compatibly.
   * This also strips out any excess whitespace to be found.
   *
   * @param Element
   * @return string
  **/
  _getInnerText: function(e, normalizeSpaces) {
    var textContent = e.textContent.replace(this.REGEXPS.trim, "");
    normalizeSpaces = (typeof normalizeSpaces === 'undefined') ? true : normalizeSpaces;

    if (normalizeSpaces) {
      return textContent.replace(this.REGEXPS.normalize, " ");
    } else {
      return textContent;
    }
  },

  /**
   * Get the number of times a string s appears in the node e.
   *
   * @param Element
   * @param string - what to split on. Default is ","
   * @return number (integer)
  **/
  _getCharCount: function(e,s) {
    s = s || ",";
    return this._getInnerText(e).split(s).length - 1;
  },

  /**
   * Remove the style attribute on every e and under.
   * TODO: Test if getElementsByTagName(*) is faster.
   *
   * @param Element
   * @return void
  **/
  _cleanStyles: function(e) {
    e = e || this._doc;
    var cur = e.firstChild;

    if (!e)
      return;

    // Remove any root styles, if we're able.
    if (typeof e.removeAttribute === 'function' && e.className !== 'readability-styled')
      e.removeAttribute('style');

    // Go until there are no more child nodes
    while (cur !== null) {
      if (cur.nodeType === 1) {
        // Remove style attribute(s) :
        if (cur.className !== "readability-styled")
          cur.removeAttribute("style");

        this._cleanStyles(cur);
      }

      cur = cur.nextSibling;
    }
  },

  /**
   * Get the density of links as a percentage of the content
   * This is the amount of text that is inside a link divided by the total text in the node.
   *
   * @param Element
   * @return number (float)
  **/
  _getLinkDensity: function(e) {
    var links = e.getElementsByTagName("a");
    var textLength = this._getInnerText(e).length;
    var linkLength = 0;

    for (var i = 0, il = links.length; i < il; i += 1) {
      linkLength += this._getInnerText(links[i]).length;
    }

    return linkLength / textLength;
  },

  /**
   * Find a cleaned up version of the current URL, to use for comparing links for possible next-pageyness.
   *
   * @author Dan Lacy
   * @return string the base url
  **/
  _findBaseUrl: function() {
    var uri = this._uri;
    var noUrlParams = uri.path.split("?")[0];
    var urlSlashes = noUrlParams.split("/").reverse();
    var cleanedSegments = [];
    var possibleType = "";

    for (var i = 0, slashLen = urlSlashes.length; i < slashLen; i += 1) {
      var segment = urlSlashes[i];

      // Split off and save anything that looks like a file type.
      if (segment.indexOf(".") !== -1) {
        possibleType = segment.split(".")[1];

        // If the type isn't alpha-only, it's probably not actually a file extension.
        if (!possibleType.match(/[^a-zA-Z]/))
          segment = segment.split(".")[0];
      }

      // EW-CMS specific segment replacement. Ugly.
      // Example: http://www.ew.com/ew/article/0,,20313460_20369436,00.html
      if (segment.indexOf(',00') !== -1)
        segment = segment.replace(',00', '');

      // If our first or second segment has anything looking like a page number, remove it.
      if (segment.match(/((_|-)?p[a-z]*|(_|-))[0-9]{1,2}$/i) && ((i === 1) || (i === 0)))
        segment = segment.replace(/((_|-)?p[a-z]*|(_|-))[0-9]{1,2}$/i, "");

      var del = false;

      // If this is purely a number, and it's the first or second segment,
      // it's probably a page number. Remove it.
      if (i < 2 && segment.match(/^\d{1,2}$/))
        del = true;

      // If this is the first segment and it's just "index", remove it.
      if (i === 0 && segment.toLowerCase() === "index")
        del = true;

      // If our first or second segment is smaller than 3 characters,
      // and the first segment was purely alphas, remove it.
      if (i < 2 && segment.length < 3 && !urlSlashes[0].match(/[a-z]/i))
        del = true;

      // If it's not marked for deletion, push it to cleanedSegments.
      if (!del)
        cleanedSegments.push(segment);
    }

    // This is our final, cleaned, base article URL.
    return uri.scheme + "://" + uri.host + cleanedSegments.reverse().join("/");
  },

  /**
   * Look for any paging links that may occur within the document.
   *
   * @param body
   * @return object (array)
  **/
  _findNextPageLink: function(elem) {
    var uri = this._uri;
    var possiblePages = {};
    var allLinks = elem.getElementsByTagName('a');
    var articleBaseUrl = this._findBaseUrl();

    // Loop through all links, looking for hints that they may be next-page links.
    // Things like having "page" in their textContent, className or id, or being a child
    // of a node with a page-y className or id.
    //
    // Also possible: levenshtein distance? longest common subsequence?
    //
    // After we do that, assign each page a score, and
    for (var i = 0, il = allLinks.length; i < il; i += 1) {
      var link = allLinks[i];
      var linkHref = allLinks[i].href.replace(/#.*$/, '').replace(/\/$/, '');

      // If we've already seen this page, ignore it.
      if (linkHref === "" ||
        linkHref === articleBaseUrl ||
        linkHref === uri.spec ||
        linkHref in this._parsedPages) {
        continue;
      }

      // If it's on a different domain, skip it.
      if (uri.host !== linkHref.split(/\/+/g)[1])
        continue;

      var linkText = this._getInnerText(link);

      // If the linkText looks like it's not the next page, skip it.
      if (linkText.match(this.REGEXPS.extraneous) || linkText.length > 25)
        continue;

      // If the leftovers of the URL after removing the base URL don't contain
      // any digits, it's certainly not a next page link.
      var linkHrefLeftover = linkHref.replace(articleBaseUrl, '');
      if (!linkHrefLeftover.match(/\d/))
        continue;

      if (!(linkHref in possiblePages)) {
        possiblePages[linkHref] = {"score": 0, "linkText": linkText, "href": linkHref};
      } else {
        possiblePages[linkHref].linkText += ' | ' + linkText;
      }

      var linkObj = possiblePages[linkHref];

      // If the articleBaseUrl isn't part of this URL, penalize this link. It could
      // still be the link, but the odds are lower.
      // Example: http://www.actionscript.org/resources/articles/745/1/JavaScript-and-VBScript-Injection-in-ActionScript-3/Page1.html
      if (linkHref.indexOf(articleBaseUrl) !== 0)
        linkObj.score -= 25;

      var linkData = linkText + ' ' + link.className + ' ' + link.id;
      if (linkData.match(this.REGEXPS.nextLink))
        linkObj.score += 50;

      if (linkData.match(/pag(e|ing|inat)/i))
        linkObj.score += 25;

      if (linkData.match(/(first|last)/i)) {
        // -65 is enough to negate any bonuses gotten from a > or » in the text,
        // If we already matched on "next", last is probably fine.
        // If we didn't, then it's bad. Penalize.
        if (!linkObj.linkText.match(this.REGEXPS.nextLink))
          linkObj.score -= 65;
      }

      if (linkData.match(this.REGEXPS.negative) || linkData.match(this.REGEXPS.extraneous))
        linkObj.score -= 50;

      if (linkData.match(this.REGEXPS.prevLink))
        linkObj.score -= 200;

      // If a parentNode contains page or paging or paginat
      var parentNode = link.parentNode;
      var positiveNodeMatch = false;
      var negativeNodeMatch = false;

      while (parentNode) {
        var parentNodeClassAndId = parentNode.className + ' ' + parentNode.id;

        if (!positiveNodeMatch && parentNodeClassAndId && parentNodeClassAndId.match(/pag(e|ing|inat)/i)) {
          positiveNodeMatch = true;
          linkObj.score += 25;
        }

        if (!negativeNodeMatch && parentNodeClassAndId && parentNodeClassAndId.match(this.REGEXPS.negative)) {
          // If this is just something like "footer", give it a negative.
          // If it's something like "body-and-footer", leave it be.
          if (!parentNodeClassAndId.match(this.REGEXPS.positive)) {
            linkObj.score -= 25;
            negativeNodeMatch = true;
          }
        }

        parentNode = parentNode.parentNode;
      }

      // If the URL looks like it has paging in it, add to the score.
      // Things like /page/2/, /pagenum/2, ?p=3, ?page=11, ?pagination=34
      if (linkHref.match(/p(a|g|ag)?(e|ing|ination)?(=|\/)[0-9]{1,2}/i) || linkHref.match(/(page|paging)/i))
        linkObj.score += 25;

      // If the URL contains negative values, give a slight decrease.
      if (linkHref.match(this.REGEXPS.extraneous))
        linkObj.score -= 15;

      /**
       * Minor punishment to anything that doesn't match our current URL.
       * NOTE: I'm finding this to cause more harm than good where something is exactly 50 points.
       *     Dan, can you show me a counterexample where this is necessary?
       * if (linkHref.indexOf(window.location.href) !== 0) {
       *  linkObj.score -= 1;
       * }
      **/

      // If the link text can be parsed as a number, give it a minor bonus, with a slight
      // bias towards lower numbered pages. This is so that pages that might not have 'next'
      // in their text can still get scored, and sorted properly by score.
      var linkTextAsNumber = parseInt(linkText, 10);
      if (linkTextAsNumber) {
        // Punish 1 since we're either already there, or it's probably
        // before what we want anyways.
        if (linkTextAsNumber === 1) {
          linkObj.score -= 10;
        } else {
          linkObj.score += Math.max(0, 10 - linkTextAsNumber);
        }
      }
    }

    // Loop thrugh all of our possible pages from above and find our top
    // candidate for the next page URL. Require at least a score of 50, which
    // is a relatively high confidence that this page is the next link.
    var topPage = null;
    for (var page in possiblePages) {
      if (possiblePages.hasOwnProperty(page)) {
        if (possiblePages[page].score >= 50 &&
          (!topPage || topPage.score < possiblePages[page].score))
          topPage = possiblePages[page];
      }
    }

    if (topPage) {
      var nextHref = topPage.href.replace(/\/$/,'');

      this.log('NEXT PAGE IS ' + nextHref);
      this._parsedPages[nextHref] = true;
      return nextHref;
    } else {
      return null;
    }
  },

  _successfulRequest: function(request) {
    return (request.status >= 200 && request.status < 300) ||
        request.status === 304 ||
         (request.status === 0 && request.responseText);
  },

  _ajax: function(url, options) {
    var request = new XMLHttpRequest();

    function respondToReadyState(readyState) {
      if (request.readyState === 4) {
        if (this._successfulRequest(request)) {
          if (options.success)
            options.success(request);
        } else {
          if (options.error)
            options.error(request);
        }
      }
    }

    if (typeof options === 'undefined')
      options = {};

    request.onreadystatechange = respondToReadyState;

    request.open('get', url, true);
    request.setRequestHeader('Accept', 'text/html');

    try {
      request.send(options.postBody);
    } catch (e) {
      if (options.error)
        options.error();
    }

    return request;
  },

  _appendNextPage: function(nextPageLink) {
    var doc = this._doc;
    this._curPageNum += 1;

    var articlePage = doc.createElement("DIV");
    articlePage.id = 'readability-page-' + this._curPageNum;
    articlePage.className = 'page';
    articlePage.innerHTML = '<p class="page-separator" title="Page ' + this._curPageNum + '">&sect;</p>';

    doc.getElementById("readability-content").appendChild(articlePage);

    if (this._curPageNum > this.MAX_PAGES) {
      var nextPageMarkup = "<div style='text-align: center'><a href='" + nextPageLink + "'>View Next Page</a></div>";
      articlePage.innerHTML = articlePage.innerHTML + nextPageMarkup;
      return;
    }

    // Now that we've built the article page DOM element, get the page content
    // asynchronously and load the cleaned content into the div we created for it.
    (function(pageUrl, thisPage) {
      this._ajax(pageUrl, {
        success: function(r) {

          // First, check to see if we have a matching ETag in headers - if we do, this is a duplicate page.
          var eTag = r.getResponseHeader('ETag');
          if (eTag) {
            if (eTag in this._pageETags) {
              this.log("Exact duplicate page found via ETag. Aborting.");
              articlePage.style.display = 'none';
              return;
            } else {
              this._pageETags[eTag] = 1;
            }
          }

          // TODO: this ends up doubling up page numbers on NYTimes articles. Need to generically parse those away.
          var page = doc.createElement("DIV");

          // Do some preprocessing to our HTML to make it ready for appending.
          // - Remove any script tags. Swap and reswap newlines with a unicode
          //   character because multiline regex doesn't work in javascript.
          // - Turn any noscript tags into divs so that we can parse them. This
          //   allows us to find any next page links hidden via javascript.
          // - Turn all double br's into p's - was handled by prepDocument in the original view.
          //   Maybe in the future abstract out prepDocument to work for both the original document
          //   and AJAX-added pages.
          var responseHtml = r.responseText.replace(/\n/g,'\uffff').replace(/<script.*?>.*?<\/script>/gi, '');
          responseHtml = responseHtml.replace(/\n/g,'\uffff').replace(/<script.*?>.*?<\/script>/gi, '');
          responseHtml = responseHtml.replace(/\uffff/g,'\n').replace(/<(\/?)noscript/gi, '<$1div');
          responseHtml = responseHtml.replace(this.REGEXPS.replaceFonts, '<$1span>');

          page.innerHTML = responseHtml;
          this._replaceBrs(page);

          // Reset all flags for the next page, as they will search through it and
          // disable as necessary at the end of grabArticle.
          this._flags = 0x1 | 0x2 | 0x4;

          var nextPageLink = this._findNextPageLink(page);

          // NOTE: if we end up supporting _appendNextPage(), we'll need to
          // change this call to be async
          var content = this._grabArticle(page);

          if (!content) {
            this.log("No content found in page to append. Aborting.");
            return;
          }

          // Anti-duplicate mechanism. Essentially, get the first paragraph of our new page.
          // Compare it against all of the the previous document's we've gotten. If the previous
          // document contains exactly the innerHTML of this first paragraph, it's probably a duplicate.
          var firstP = content.getElementsByTagName("P").length ? content.getElementsByTagName("P")[0] : null;
          if (firstP && firstP.innerHTML.length > 100) {
            for (var i = 1; i <= this._curPageNum; i += 1) {
              var rPage = doc.getElementById('readability-page-' + i);
              if (rPage && rPage.innerHTML.indexOf(firstP.innerHTML) !== -1) {
                this.log('Duplicate of page ' + i + ' - skipping.');
                articlePage.style.display = 'none';
                this._parsedPages[pageUrl] = true;
                return;
              }
            }
          }

          this._removeScripts(content);

          thisPage.innerHTML = thisPage.innerHTML + content.innerHTML;

          // After the page has rendered, post process the content. This delay is necessary because,
          // in webkit at least, offsetWidth is not set in time to determine image width. We have to
          // wait a little bit for reflow to finish before we can fix floating images.
          setTimeout((function() {
            this._postProcessContent(thisPage);
          }).bind(this), 500);


          if (nextPageLink)
            this._appendNextPage(nextPageLink);
        }
      });
    }).bind(this)(nextPageLink, articlePage);
  },

  /**
   * Get an elements class/id weight. Uses regular expressions to tell if this
   * element looks good or bad.
   *
   * @param Element
   * @return number (Integer)
  **/
  _getClassWeight: function(e) {
    if (!this._flagIsActive(this.FLAG_WEIGHT_CLASSES))
      return 0;

    var weight = 0;

    // Look for a special classname
    if (typeof(e.className) === 'string' && e.className !== '') {
      if (e.className.search(this.REGEXPS.negative) !== -1)
        weight -= 25;

      if (e.className.search(this.REGEXPS.positive) !== -1)
        weight += 25;
    }

    // Look for a special ID
    if (typeof(e.id) === 'string' && e.id !== '') {
      if (e.id.search(this.REGEXPS.negative) !== -1)
        weight -= 25;

      if (e.id.search(this.REGEXPS.positive) !== -1)
        weight += 25;
    }

    return weight;
  },

  /**
   * Clean a node of all elements of type "tag".
   * (Unless it's a youtube/vimeo video. People love movies.)
   *
   * @param Element
   * @param string tag to clean
   * @return void
   **/
  _clean: function(e, tag) {
    var targetList = e.getElementsByTagName(tag);
    var isEmbed = (tag === 'object' || tag === 'embed');

    for (var y = targetList.length - 1; y >= 0; y -= 1) {
      // Allow youtube and vimeo videos through as people usually want to see those.
      if (isEmbed) {
        var attributeValues = "";
        for (var i = 0, il = targetList[y].attributes.length; i < il; i += 1) {
          attributeValues += targetList[y].attributes[i].value + '|';
        }

        // First, check the elements attributes to see if any of them contain youtube or vimeo
        if (attributeValues.search(this.REGEXPS.videos) !== -1)
          continue;

        // Then check the elements inside this element for the same.
        if (targetList[y].innerHTML.search(this.REGEXPS.videos) !== -1)
          continue;
      }

      targetList[y].parentNode.removeChild(targetList[y]);
    }
  },

  /**
   * Clean an element of all tags of type "tag" if they look fishy.
   * "Fishy" is an algorithm based on content length, classnames, link density, number of images & embeds, etc.
   *
   * @return void
   **/
  _cleanConditionally: function(e, tag) {
    if (!this._flagIsActive(this.FLAG_CLEAN_CONDITIONALLY))
      return;

    var tagsList = e.getElementsByTagName(tag);
    var curTagsLength = tagsList.length;

    // Gather counts for other typical elements embedded within.
    // Traverse backwards so we can remove nodes at the same time
    // without effecting the traversal.
    //
    // TODO: Consider taking into account original contentScore here.
    for (var i = curTagsLength-1; i >= 0; i -= 1) {
      var weight = this._getClassWeight(tagsList[i]);
      var contentScore = 0;

      this.log("Cleaning Conditionally " + tagsList[i] + " (" + tagsList[i].className + ":" + tagsList[i].id + ")");

      if (weight + contentScore < 0) {
        tagsList[i].parentNode.removeChild(tagsList[i]);
      } else if (this._getCharCount(tagsList[i],',') < 10) {
        // If there are not very many commas, and the number of
        // non-paragraph elements is more than paragraphs or other
        // ominous signs, remove the element.
        var p = tagsList[i].getElementsByTagName("p").length;
        var img = tagsList[i].getElementsByTagName("img").length;
        var li = tagsList[i].getElementsByTagName("li").length-100;
        var input = tagsList[i].getElementsByTagName("input").length;

        var embedCount = 0;
        var embeds = tagsList[i].getElementsByTagName("embed");
        for (var ei = 0, il = embeds.length; ei < il; ei += 1) {
          if (embeds[ei].src.search(this.REGEXPS.videos) === -1)
            embedCount += 1;
        }

        var linkDensity = this._getLinkDensity(tagsList[i]);
        var contentLength = this._getInnerText(tagsList[i]).length;
        var toRemove = false;

        if (img > p) {
          toRemove = true;
        } else if (li > p && tag !== "ul" && tag !== "ol") {
          toRemove = true;
        } else if ( input > Math.floor(p/3) ) {
          toRemove = true;
        } else if (contentLength < 25 && (img === 0 || img > 2) ) {
          toRemove = true;
        } else if (weight < 25 && linkDensity > 0.2) {
          toRemove = true;
        } else if (weight >= 25 && linkDensity > 0.5) {
          toRemove = true;
        } else if ((embedCount === 1 && contentLength < 75) || embedCount > 1) {
          toRemove = true;
        }

        if (toRemove)
          tagsList[i].parentNode.removeChild(tagsList[i]);
      }
    }
  },

  /**
   * Clean out spurious headers from an Element. Checks things like classnames and link density.
   *
   * @param Element
   * @return void
  **/
  _cleanHeaders: function(e) {
    for (var headerIndex = 1; headerIndex < 3; headerIndex += 1) {
      var headers = e.getElementsByTagName('h' + headerIndex);
      for (var i = headers.length - 1; i >= 0; i -= 1) {
        if (this._getClassWeight(headers[i]) < 0 || this._getLinkDensity(headers[i]) > 0.33)
          headers[i].parentNode.removeChild(headers[i]);
      }
    }
  },

  _flagIsActive: function(flag) {
    return (this._flags & flag) > 0;
  },

  _addFlag: function(flag) {
    this._flags = this._flags | flag;
  },

  _removeFlag: function(flag) {
    this._flags = this._flags & ~flag;
  },

  /**
   * Runs readability.
   *
   * Workflow:
   *  1. Prep the document by removing script tags, css, etc.
   *  2. Build readability's DOM tree.
   *  3. Grab the article content from the current dom tree.
   *  4. Replace the current DOM tree with the new one.
   *  5. Read peacefully.
   *
   * @return void
   **/
  parse: function () {
    // Remove script tags from the document.
    this._removeScripts(this._doc);

    // FIXME: Disabled multi-page article support for now as it
    // needs more work on infrastructure.

    // Make sure this document is added to the list of parsed pages first,
    // so we don't double up on the first page.
    // this._parsedPages[uri.spec.replace(/\/$/, '')] = true;

    // Pull out any possible next page link first.
    // var nextPageLink = this._findNextPageLink(doc.body);

    this._prepDocument();

    var articleTitle = this._getArticleTitle();
    var articleContent = this._grabArticle();
    if (!articleContent)
      return null;

    this._postProcessContent(articleContent);

    // if (nextPageLink) {
    //   // Append any additional pages after a small timeout so that people
    //   // can start reading without having to wait for this to finish processing.
    //   setTimeout((function() {
    //     this._appendNextPage(nextPageLink);
    //   }).bind(this), 500);
    // }

    var excerpt = this._getExcerpt(articleContent);

    return { title: articleTitle,
             byline: this._articleByline,
             dir: this._articleDir,
             content: articleContent.innerHTML,
             length: articleContent.textContent.length,
             excerpt: excerpt };
  }
};
