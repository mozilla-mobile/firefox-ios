/*
DO NOT TOUCH fathom.jsm DIRECTLY. See the README for instructions.
*/

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * A :func:`rule` depends on another rule which itself depends on the first
 * rule again, either directly or indirectly.
 */
class CycleError extends Error {
}

/**
  * An examined element was not contained in a browser ``window`` object, but
  * something needed it to be.
  */
class NoWindowError extends Error {
}

var exceptions = /*#__PURE__*/Object.freeze({
  __proto__: null,
  CycleError: CycleError,
  NoWindowError: NoWindowError
});

/**
 * Return the passed-in arg. Useful as a default.
 */
function identity(x) {
    return x;
}

/*eslint-env browser*/

/**
 * From an iterable return the best item, according to an arbitrary comparator
 * function. In case of a tie, the first item wins.
 *
 * @arg by {function} Given an item of the iterable, return a value to compare
 * @arg isBetter {function} Return whether its first arg is better than its
 *     second
 */
function best(iterable, by, isBetter) {
    let bestSoFar, bestKeySoFar;
    let isFirst = true;
    forEach(
        function (item) {
            const key = by(item);
            if (isBetter(key, bestKeySoFar) || isFirst) {
                bestSoFar = item;
                bestKeySoFar = key;
                isFirst = false;
            }
        },
        iterable);
    if (isFirst) {
        throw new Error('Tried to call best() on empty iterable');
    }
    return bestSoFar;
}

/**
 * Return the maximum item from an iterable, as defined by >.
 *
 * Works with any type that works with >. If multiple items are equally great,
 * return the first.
 *
 * @arg by {function} Given an item of the iterable, returns a value to
 *     compare
 */
function max(iterable, by = identity) {
    return best(iterable, by, (a, b) => a > b);
}

/**
 * Return an Array of maximum items from an iterable, as defined by > and ===.
 *
 * If an empty iterable is passed in, return [].
 */
function maxes(iterable, by = identity) {
    let bests = [];
    let bestKeySoFar;
    let isFirst = true;
    forEach(
        function (item) {
            const key = by(item);
            if (key > bestKeySoFar || isFirst) {
                bests = [item];
                bestKeySoFar = key;
                isFirst = false;
            } else if (key === bestKeySoFar) {
                bests.push(item);
            }
        },
        iterable);
    return bests;
}

/**
 * Return the minimum item from an iterable, as defined by <.
 *
 * If multiple items are equally great, return the first.
 */
function min(iterable, by = identity) {
    return best(iterable, by, (a, b) => a < b);
}

/**
 * Return the sum of an iterable, as defined by the + operator.
 */
function sum(iterable) {
    let total;
    let isFirst = true;
    forEach(
        function assignOrAdd(addend) {
            if (isFirst) {
                total = addend;
                isFirst = false;
            } else {
                total += addend;
            }
        },
        iterable);
    return total;
}

/**
 * Return the number of items in an iterable, consuming it as a side effect.
 */
function length(iterable) {
    let num = 0;
    // eslint-disable-next-line no-unused-vars
    for (let item of iterable) {
        num++;
    }
    return num;
}

/**
 * Iterate, depth first, over a DOM node. Return the original node first.
 *
 * @arg shouldTraverse {function} Given a node, say whether we should
 *     include it and its children. Default: always true.
 */
function *walk(element, shouldTraverse = element => true) {
    yield element;
    for (let child of element.childNodes) {
        if (shouldTraverse(child)) {
            for (let w of walk(child, shouldTraverse)) {
                yield w;
            }
        }
    }
}

const blockTags = new Set(
    ['ADDRESS', 'BLOCKQUOTE', 'BODY', 'CENTER', 'DIR', 'DIV', 'DL',
     'FIELDSET', 'FORM', 'H1', 'H2', 'H3', 'H4', 'H5', 'H6', 'HR',
     'ISINDEX', 'MENU', 'NOFRAMES', 'NOSCRIPT', 'OL', 'P', 'PRE',
     'TABLE', 'UL', 'DD', 'DT', 'FRAMESET', 'LI', 'TBODY', 'TD',
     'TFOOT', 'TH', 'THEAD', 'TR', 'HTML']);
/**
 * Return whether a DOM element is a block element by default (rather than by
 * styling).
 */
function isBlock(element) {
    return blockTags.has(element.tagName);
}

/**
 * Yield strings of text nodes within a normalized DOM node and its children,
 * without venturing into any contained block elements.
 *
 * @arg shouldTraverse {function} Specify additional elements to exclude by
 *     returning false
 */
function *inlineTexts(element, shouldTraverse = element => true) {
    // TODO: Could we just use querySelectorAll() with a really long
    // selector rather than walk(), for speed?
    for (let child of walk(element,
                           element => !(isBlock(element) ||
                                        element.tagName === 'SCRIPT' &&
                                        element.tagName === 'STYLE')
                                      && shouldTraverse(element))) {
        if (child.nodeType === child.TEXT_NODE) {
            // wholeText() is not implemented by jsdom, so we use
            // textContent(). The result should be the same, since
            // we're calling it on only text nodes, but it may be
            // slower. On the positive side, it means we don't need to
            // normalize the DOM tree first.
            yield child.textContent;
        }
    }
}

/**
 * Return the total length of the inline text within an element, with
 * whitespace collapsed.
 *
 * @arg shouldTraverse {function} Specify additional elements to exclude by
 *     returning false
 */
function inlineTextLength(element, shouldTraverse = element => true) {
    return sum(map(text => collapseWhitespace(text).length,
                   inlineTexts(element, shouldTraverse)));
}

/**
 * Return a string with each run of whitespace collapsed to a single space.
 */
function collapseWhitespace(str) {
    return str.replace(/\s{2,}/g, ' ');
}

/**
 * Return the ratio of the inline text length of the links in an element to the
 * inline text length of the entire element.
 *
 * @arg inlineLength {number} Optionally, the precalculated inline
 *     length of the fnode. If omitted, we will calculate it ourselves.
 */
function linkDensity(fnode, inlineLength) {
    if (inlineLength === undefined) {
        inlineLength = inlineTextLength(fnode.element);
    }
    const lengthWithoutLinks = inlineTextLength(fnode.element,
                                                element => element.tagName !== 'A');
    return (inlineLength - lengthWithoutLinks) / inlineLength;
}

/**
 * Return whether an element is a text node that consist wholly of whitespace.
 */
function isWhitespace(element) {
    return (element.nodeType === element.TEXT_NODE &&
            element.textContent.trim().length === 0);
}

/**
 * Get a key of a map, first setting it to a default value if it's missing.
 */
function setDefault(map, key, defaultMaker) {
    if (map.has(key)) {
        return map.get(key);
    }
    const defaultValue = defaultMaker();
    map.set(key, defaultValue);
    return defaultValue;
}

/**
 * Get a key of a map or, if it's missing, a default value.
 */
function getDefault(map, key, defaultMaker) {
    if (map.has(key)) {
        return map.get(key);
    }
    return defaultMaker();
}

/**
 * Return an Array, the reverse topological sort of the given nodes.
 *
 * @arg nodes An iterable of arbitrary things
 * @arg nodesThatNeed {function} Take a node and returns an Array of nodes
 *     that depend on it
 */
function toposort(nodes, nodesThatNeed) {
    const ret = [];
    const todo = new Set(nodes);
    const inProgress = new Set();

    function visit(node) {
        if (inProgress.has(node)) {
            throw new CycleError('The graph has a cycle.');
        }
        if (todo.has(node)) {
            inProgress.add(node);
            for (let needer of nodesThatNeed(node)) {
                visit(needer);
            }
            inProgress.delete(node);
            todo.delete(node);
            ret.push(node);
        }
    }

    while (todo.size > 0) {
        visit(first(todo));
    }
    return ret;
}

/**
 * A Set with the additional methods it ought to have had
 */
class NiceSet extends Set {
    /**
     * Remove and return an arbitrary item. Throw an Error if I am empty.
     */
    pop() {
        for (let v of this.values()) {
            this.delete(v);
            return v;
        }
        throw new Error('Tried to pop from an empty NiceSet.');
    }

    /**
     * Union another set or other iterable into myself.
     *
     * @return myself, for chaining
     */
    extend(otherSet) {
        for (let item of otherSet) {
            this.add(item);
        }
        return this;
    }

    /**
     * Subtract another set from a copy of me.
     *
     * @return a copy of myself excluding the elements in ``otherSet``.
     */
    minus(otherSet) {
        const ret = new NiceSet(this);
        for (const item of otherSet) {
            ret.delete(item);
        }
        return ret;
    }

    /**
     * Actually show the items in me.
     */
    toString() {
        return '{' + Array.from(this).join(', ') + '}';
    }
}

/**
 * Return the first item of an iterable.
 */
function first(iterable) {
    for (let i of iterable) {
        return i;
    }
}

/**
 * Given any node in a DOM tree, return the root element of the tree, generally
 * an HTML element.
 */
function rootElement(element) {
    return element.ownerDocument.documentElement;
}

/**
 * Return the number of times a regex occurs within the string `haystack`.
 *
 * Caller must make sure `regex` has the 'g' option set.
 */
function numberOfMatches(regex, haystack) {
    return (haystack.match(regex) || []).length;
}

/**
 * Wrap a scoring callback, and set its element to the page root iff a score is
 * returned.
 *
 * This is used to build rulesets which classify entire pages rather than
 * picking out specific elements.
 *
 * For example, these rules might classify a page as a "login page", influenced
 * by whether they have login buttons or username fields:
 *
 * ``rule(type('loginPage'), score(page(pageContainsLoginButton))),``
 * ``rule(type('loginPage'), score(page(pageContainsUsernameField)))``
 */
function page(scoringFunction) {
    function wrapper(fnode) {
        const scoreAndTypeAndNote = scoringFunction(fnode);
        if (scoreAndTypeAndNote.score !== undefined) {
            scoreAndTypeAndNote.element = rootElement(fnode.element);
        }
        return scoreAndTypeAndNote;
    }
    return wrapper;
}

/**
 * Sort the elements by their position in the DOM.
 *
 * @arg fnodes {iterable} fnodes to sort
 * @return {Array} sorted fnodes
 */
function domSort(fnodes) {
    function compare(a, b) {
        const element = a.element;
        const position = element.compareDocumentPosition(b.element);
        if (position & element.DOCUMENT_POSITION_FOLLOWING) {
            return -1;
        } else if (position & element.DOCUMENT_POSITION_PRECEDING) {
            return 1;
        } else {
            return 0;
        }
    }
    return Array.from(fnodes).sort(compare);
}

/* istanbul ignore next */
/**
 * Return the DOM element contained in a passed-in fnode. Return passed-in DOM
 * elements verbatim.
 *
 * @arg fnodeOrElement {Node|Fnode}
 */
function toDomElement(fnodeOrElement) {
    return isDomElement(fnodeOrElement) ? fnodeOrElement : fnodeOrElement.element;
}

/**
 * Checks whether any of the element's attribute values satisfy some condition.
 *
 * Example::
 *
 *     rule(type('foo'),
 *          score(attributesMatch(element,
 *                                attr => attr.includes('good'),
 *                                ['id', 'alt']) ? 2 : 1))
 *
 * @arg element {Node} Element whose attributes you want to search
 * @arg predicate {function} A condition to check. Take a string and
 *     return a boolean. If an attribute has multiple values (e.g. the class
 *     attribute), attributesMatch will check each one.
 * @arg attrs {string[]} An Array of attributes you want to search. If none are
 *     provided, search all.
 * @return Whether any of the attribute values satisfy the predicate function
 */
function attributesMatch(element, predicate, attrs = []) {
    const attributes = attrs.length === 0 ? Array.from(element.attributes).map(a => a.name) : attrs;
    for (let i = 0; i < attributes.length; i++) {
        const attr = element.getAttribute(attributes[i]);
        // If the attribute is an array, apply the scoring function to each element
        if (attr && ((Array.isArray(attr) && attr.some(predicate)) || predicate(attr))) {
            return true;
        }
    }
    return false;
}

/* istanbul ignore next */
/**
 * Yield an element and each of its ancestors.
 */
function *ancestors(element) {
    yield element;
    let parent;
    while ((parent = element.parentNode) !== null && parent.nodeType === parent.ELEMENT_NODE) {
        yield parent;
        element = parent;
    }
}

/**
 * Return the sigmoid of the argument: 1 / (1 + exp(-x)). This is useful for
 * crunching a feature value that may have a wide range into the range (0, 1)
 * without a hard ceiling: the sigmoid of even a very large number will be a
 * little larger than that of a slightly smaller one.
 *
 * @arg x {Number} a number to be compressed into the range (0, 1)
 */
function sigmoid(x) {
    return 1 / (1 + Math.exp(-x));
}

/* istanbul ignore next */
/**
 * Return whether an element is practically visible, considering things like 0
 * size or opacity, ``visibility: hidden`` and ``overflow: hidden``.
 *
 * Merely being scrolled off the page in either horizontally or vertically
 * doesn't count as invisible; the result of this function is meant to be
 * independent of viewport size.
 *
 * @throws {NoWindowError} The element (or perhaps one of its ancestors) is not
 *     in a window, so we can't find the `getComputedStyle()` routine to call.
 *     That routine is the source of most of the information we use, so you
 *     should pick a different strategy for non-window contexts.
 */
function isVisible(fnodeOrElement) {
    // This could be 5x more efficient if https://github.com/w3c/csswg-drafts/issues/4122 happens.
    const element = toDomElement(fnodeOrElement);
    const elementWindow = windowForElement(element);
    const elementRect = element.getBoundingClientRect();
    const elementStyle = elementWindow.getComputedStyle(element);
    // Alternative to reading ``display: none`` due to Bug 1381071.
    if (elementRect.width === 0 && elementRect.height === 0 && elementStyle.overflow !== 'hidden') {
        return false;
    }
    if (elementStyle.visibility === 'hidden') {
        return false;
    }
    // Check if the element is irrevocably off-screen:
    if (elementRect.x + elementRect.width < 0 ||
        elementRect.y + elementRect.height < 0
    ) {
        return false;
    }
    for (const ancestor of ancestors(element)) {
        const isElement = ancestor === element;
        const style = isElement ? elementStyle : elementWindow.getComputedStyle(ancestor);
        if (style.opacity === '0') {
            return false;
        }
        if (style.display === 'contents') {
            // ``display: contents`` elements have no box themselves, but children are
            // still rendered.
            continue;
        }
        const rect = isElement ? elementRect : ancestor.getBoundingClientRect();
        if ((rect.width === 0 || rect.height === 0) && elementStyle.overflow === 'hidden') {
            // Zero-sized ancestors don’t make descendants hidden unless the descendant
            // has ``overflow: hidden``.
            return false;
        }
    }
    return true;
}

/**
 * Return the extracted [r, g, b, a] values from a string like "rgba(0, 5, 255, 0.8)",
 * and scale them to 0..1. If no alpha is specified, return undefined for it.
 */
function rgbaFromString(str) {
    const m = str.match(/^rgba?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*(\d+(?:\.\d+)?)\s*)?\)$/i);
    if (m) {
        return [m[1] / 255, m[2] / 255, m[3] / 255, m[4] === undefined ? undefined : parseFloat(m[4])];
    } else {
        throw new Error('Color ' + str + ' did not match pattern rgb[a](r, g, b[, a]).');
    }
}

/**
 * Return the saturation 0..1 of a color defined by RGB values 0..1.
 */
function saturation(r, g, b) {
    const cMax = Math.max(r, g, b);
    const cMin = Math.min(r, g, b);
    const delta = cMax - cMin;
    const lightness = (cMax + cMin) / 2;
    const denom = (1 - (Math.abs(2 * lightness - 1)));
    // Return 0 if it's black (R, G, and B all 0).
    return (denom === 0) ? 0 : delta / denom;
}

/**
 * Scale a number to the range [0, 1] using a linear slope.
 *
 * For a rising line, the result is 0 until the input reaches zeroAt, then
 * increases linearly until oneAt, at which it becomes 1. To make a falling
 * line, where the result is 1 to the left and 0 to the right, use a zeroAt
 * greater than oneAt.
 */
function linearScale(number, zeroAt, oneAt) {
    const isRising = zeroAt < oneAt;
    if (isRising) {
        if (number <= zeroAt) {
            return 0;
        } else if (number >= oneAt) {
            return 1;
        }
    } else {
        if (number >= zeroAt) {
            return 0;
        } else if (number <= oneAt) {
            return 1;
        }
    }
    const slope = 1 / (oneAt - zeroAt);
    return slope * (number - zeroAt);
}

// -------- Routines below this point are private to the framework. --------

/**
 * Flatten out an iterable of iterables into a single iterable of non-
 * iterables. Does not consider strings to be iterable.
 */
function *flatten(iterable) {
    for (const i of iterable) {
        if (typeof i !== 'string' && isIterable(i)) {
            yield *(flatten(i));
        } else {
            yield i;
        }
    }
}

/**
 * A lazy, top-level ``Array.map()`` workalike that works on anything iterable
 */
function *map(fn, iterable) {
    for (const i of iterable) {
        yield fn(i);
    }
}

/**
 * A lazy, top-level ``Array.forEach()`` workalike that works on anything
 * iterable
 */
function forEach(fn, iterable) {
    for (const i of iterable) {
        fn(i);
    }
}

/* istanbul ignore next */
/**
 * @return whether a thing appears to be a DOM element.
 */
function isDomElement(thing) {
    return thing.nodeName !== undefined;
}

function isIterable(thing) {
    return thing && typeof thing[Symbol.iterator] === 'function';
}

/**
 * Return an backward iterator over an Array without reversing it in place.
 */
function *reversed(array) {
    for (let i = array.length - 1; i >= 0; i--) {
        yield array[i];
    }
}

/* istanbul ignore next */
/*
 * Return the window an element is in.
 *
 * @throws {NoWindowError} There isn't such a window.
 */
function windowForElement(element) {
    let doc = element.ownerDocument;
    if (doc === null) {
        // The element itself was a document.
        doc = element;
    }
    const win = doc.defaultView;
    if (win === null) {
        throw new NoWindowError();
    }
    return win;
}

var utilsForFrontend = /*#__PURE__*/Object.freeze({
  __proto__: null,
  identity: identity,
  best: best,
  max: max,
  maxes: maxes,
  min: min,
  sum: sum,
  length: length,
  walk: walk,
  isBlock: isBlock,
  inlineTexts: inlineTexts,
  inlineTextLength: inlineTextLength,
  collapseWhitespace: collapseWhitespace,
  linkDensity: linkDensity,
  isWhitespace: isWhitespace,
  setDefault: setDefault,
  getDefault: getDefault,
  toposort: toposort,
  NiceSet: NiceSet,
  first: first,
  rootElement: rootElement,
  numberOfMatches: numberOfMatches,
  page: page,
  domSort: domSort,
  toDomElement: toDomElement,
  attributesMatch: attributesMatch,
  ancestors: ancestors,
  sigmoid: sigmoid,
  isVisible: isVisible,
  rgbaFromString: rgbaFromString,
  saturation: saturation,
  linearScale: linearScale,
  flatten: flatten,
  map: map,
  forEach: forEach,
  isDomElement: isDomElement,
  reversed: reversed,
  windowForElement: windowForElement
});

/**
 * Return the number of stride nodes between 2 DOM nodes *at the same
 * level of the tree*, without going up or down the tree.
 *
 * ``left`` xor ``right`` may also be undefined.
 */
function numStrides(left, right) {
    let num = 0;

    // Walk right from left node until we hit the right node or run out:
    let sibling = left;
    let shouldContinue = sibling && sibling !== right;
    while (shouldContinue) {
        sibling = sibling.nextSibling;
        if ((shouldContinue = sibling && sibling !== right) &&
            !isWhitespace(sibling)) {
            num += 1;
        }
    }
    if (sibling !== right) {  // Don't double-punish if left and right are siblings.
        // Walk left from right node:
        sibling = right;
        while (sibling) {
            sibling = sibling.previousSibling;
            if (sibling && !isWhitespace(sibling)) {
                num += 1;
            }
        }
    }
    return num;
}

/**
 * Return a topological distance between 2 DOM nodes or :term:`fnodes<fnode>`
 * weighted according to the similarity of their ancestry in the DOM. For
 * instance, if one node is situated inside ``<div><span><b><theNode>`` and the
 * other node is at ``<differentDiv><span><b><otherNode>``, they are considered
 * close to each other for clustering purposes. This is useful for picking out
 * nodes which have similar purposes.
 *
 * Return ``Number.MAX_VALUE`` if one of the nodes contains the other.
 *
 * This is largely an implementation detail of :func:`clusters`, but you can
 * call it yourself if you wish to implement your own clustering. Takes O(n log
 * n) time.
 *
 * Note that the default costs may change; pass them in explicitly if they are
 * important to you.
 *
 * @arg fnodeA {Node|Fnode}
 * @arg fnodeB {Node|Fnode}
 * @arg differentDepthCost {number} Cost for each level deeper one node is than
 *    the other below their common ancestor
 * @arg differentTagCost {number} Cost for a level below the common ancestor
 *    where tagNames differ
 * @arg sameTagCost {number} Cost for a level below the common ancestor where
 *    tagNames are the same
 * @arg strideCost {number} Cost for each stride node between A and B. Stride
 *     nodes are siblings or siblings-of-ancestors that lie between the 2
 *     nodes. These interposed nodes make it less likely that the 2 nodes
 *     should be together in a cluster.
 * @arg additionalCost {function} Return an additional cost, given 2 fnodes or
 *    nodes.
 *
 */
function distance(fnodeA,
                         fnodeB,
                         {differentDepthCost = 2,
                          differentTagCost = 2,
                          sameTagCost = 1,
                          strideCost = 1,
                          additionalCost = (fnodeA, fnodeB) => 0} = {}) {
    // I was thinking of something that adds little cost for siblings. Up
    // should probably be more expensive than down (see middle example in the
    // Nokia paper).

    // TODO: Test and tune default costs. They're off the cuff at the moment.

    if (fnodeA === fnodeB) {
        return 0;
    }

    const elementA = isDomElement(fnodeA) ? fnodeA : fnodeA.element;
    const elementB = isDomElement(fnodeB) ? fnodeB : fnodeB.element;

    // Stacks that go from the common ancestor all the way to A and B:
    const aAncestors = [elementA];
    const bAncestors = [elementB];

    let aAncestor = elementA;
    let bAncestor = elementB;

    // Ascend to common parent, stacking them up for later reference:
    while (!aAncestor.contains(elementB)) {  // Note: an element does contain() itself.
        aAncestor = aAncestor.parentNode;
        aAncestors.push(aAncestor); //aAncestors = [a, b]. aAncestor = b // if a is outer: no loop here; aAncestors = [a]. aAncestor = a.
    }

    // In compareDocumentPosition()'s opinion, inside implies after. Basically,
    // before and after pertain to opening tags.
    const comparison = elementA.compareDocumentPosition(elementB);

    // If either contains the other, abort. We'd either return a misleading
    // number or else walk upward right out of the document while trying to
    // make the ancestor stack.
    if (comparison & (elementA.DOCUMENT_POSITION_CONTAINS | elementA.DOCUMENT_POSITION_CONTAINED_BY)) {
        return Number.MAX_VALUE;
    }
    // Make an ancestor stack for the right node too so we can walk
    // efficiently down to it:
    do {
        bAncestor = bAncestor.parentNode;  // Assumes we've early-returned above if A === B. This walks upward from the outer node and up out of the tree. It STARTS OUT with aAncestor === bAncestor!
        bAncestors.push(bAncestor);
    } while (bAncestor !== aAncestor);

    // Figure out which node is left and which is right, so we can follow
    // sibling links in the appropriate directions when looking for stride
    // nodes:
    let left = aAncestors;
    let right = bAncestors;
    let cost = 0;
    if (comparison & elementA.DOCUMENT_POSITION_FOLLOWING) {
        // A is before, so it could contain the other node. What did I mean to do if one contained the other?
        left = aAncestors;
        right = bAncestors;
    } else if (comparison & elementA.DOCUMENT_POSITION_PRECEDING) {
        // A is after, so it might be contained by the other node.
        left = bAncestors;
        right = aAncestors;
    }

    // Descend to both nodes in parallel, discounting the traversal
    // cost iff the nodes we hit look similar, implying the nodes dwell
    // within similar structures.
    while (left.length || right.length) {
        const l = left.pop();
        const r = right.pop();
        if (l === undefined || r === undefined) {
            // Punishment for being at different depths: same as ordinary
            // dissimilarity punishment for now
            cost += differentDepthCost;
        } else {
            // TODO: Consider similarity of classList.
            cost += l.tagName === r.tagName ? sameTagCost : differentTagCost;
        }
        // Optimization: strides might be a good dimension to eliminate.
        if (strideCost !== 0) {
            cost += numStrides(l, r) * strideCost;
        }
    }

    return cost + additionalCost(fnodeA, fnodeB);
}

/**
 * Return the spatial distance between 2 fnodes or elements, assuming a
 * rendered page.
 *
 * Specifically, return the distance in pixels between the centers of
 * ``fnodeA.element.getBoundingClientRect()`` and
 * ``fnodeB.element.getBoundingClientRect()``.
 */
function euclidean(fnodeA, fnodeB) {
    /**
     * Return the horizontal distance from the left edge of the viewport to the
     * center of an element, given a DOMRect object for it. It doesn't matter
     * that the distance is affected by the page's scroll offset, since the 2
     * elements have the same offset.
     */
    function xCenter(domRect) {
        return domRect.left + domRect.width / 2;
    }
    function yCenter(domRect) {
        return domRect.top + domRect.height / 2;
    }

    const elementA = toDomElement(fnodeA);
    const elementB = toDomElement(fnodeB);
    const aRect = elementA.getBoundingClientRect();
    const bRect = elementB.getBoundingClientRect();
    return Math.sqrt((xCenter(aRect) - xCenter(bRect)) ** 2 +
                     (yCenter(aRect) - yCenter(bRect)) ** 2);
}

/** A lower-triangular matrix of inter-cluster distances */
class DistanceMatrix {
    /**
     * @arg distance {function} Some notion of distance between 2 given nodes
     */
    constructor(elements, distance) {
        // A sparse adjacency matrix:
        // {A => {},
        //  B => {A => 4},
        //  C => {A => 4, B => 4},
        //  D => {A => 4, B => 4, C => 4}
        //  E => {A => 4, B => 4, C => 4, D => 4}}
        //
        // A, B, etc. are arrays of [arrays of arrays of...] nodes, each
        // array being a cluster. In this way, they not only accumulate a
        // cluster but retain the steps along the way.
        //
        // This is an efficient data structure in terms of CPU and memory, in
        // that we don't have to slide a lot of memory around when we delete a
        // row or column from the middle of the matrix while merging. Of
        // course, we lose some practical efficiency by using hash tables, and
        // maps in particular are slow in their early implementations.
        this._matrix = new Map();

        // Convert elements to clusters:
        const clusters = elements.map(el => [el]);

        // Init matrix:
        for (let outerCluster of clusters) {
            const innerMap = new Map();
            for (let innerCluster of this._matrix.keys()) {
                innerMap.set(innerCluster, distance(outerCluster[0],
                                                    innerCluster[0]));
            }
            this._matrix.set(outerCluster, innerMap);
        }
        this._numClusters = clusters.length;
    }

    // Return (distance, a: clusterA, b: clusterB) of closest-together clusters.
    // Replace this to change linkage criterion.
    closest() {
        const self = this;

        if (this._numClusters < 2) {
            throw new Error('There must be at least 2 clusters in order to return the closest() ones.');
        }

        // Return the distances between every pair of clusters.
        function clustersAndDistances() {
            const ret = [];
            for (let [outerKey, row] of self._matrix.entries()) {
                for (let [innerKey, storedDistance] of row.entries()) {
                    ret.push({a: outerKey, b: innerKey, distance: storedDistance});
                }
            }
            return ret;
        }
        // Optimizing this by inlining the loop and writing it less
        // functionally doesn't help:
        return min(clustersAndDistances(), x => x.distance);
    }

    // Look up the distance between 2 clusters in me. Try the lookup in the
    // other direction if the first one falls in the nonexistent half of the
    // triangle.
    _cachedDistance(clusterA, clusterB) {
        let ret = this._matrix.get(clusterA).get(clusterB);
        if (ret === undefined) {
            ret = this._matrix.get(clusterB).get(clusterA);
        }
        return ret;
    }

    // Merge two clusters.
    merge(clusterA, clusterB) {
        // An example showing how rows merge:
        //  A: {}
        //  B: {A: 1}
        //  C: {A: 4, B: 4},
        //  D: {A: 4, B: 4, C: 4}
        //  E: {A: 4, B: 4, C: 2, D: 4}}
        //
        // Step 2:
        //  C: {}
        //  D: {C: 4}
        //  E: {C: 2, D: 4}}
        //  AB: {C: 4, D: 4, E: 4}
        //
        // Step 3:
        //  D:  {}
        //  AB: {D: 4}
        //  CE: {D: 4, AB: 4}

        // Construct new row, finding min distances from either subcluster of
        // the new cluster to old clusters.
        //
        // There will be no repetition in the matrix because, after all,
        // nothing pointed to this new cluster before it existed.
        const newRow = new Map();
        for (let outerKey of this._matrix.keys()) {
            if (outerKey !== clusterA && outerKey !== clusterB) {
                newRow.set(outerKey, Math.min(this._cachedDistance(clusterA, outerKey),
                                              this._cachedDistance(clusterB, outerKey)));
            }
        }

        // Delete the rows of the clusters we're merging.
        this._matrix.delete(clusterA);
        this._matrix.delete(clusterB);

        // Remove inner refs to the clusters we're merging.
        for (let inner of this._matrix.values()) {
            inner.delete(clusterA);
            inner.delete(clusterB);
        }

        // Attach new row.
        this._matrix.set([clusterA, clusterB], newRow);

        // There is a net decrease of 1 cluster:
        this._numClusters -= 1;
    }

    numClusters() {
        return this._numClusters;
    }

    // Return an Array of nodes for each cluster in me.
    clusters() {
        // TODO: Can't get map to work here. Don't know why.
        return Array.from(this._matrix.keys()).map(e => Array.from(flatten(e)));
    }
}

/**
 * Partition the given nodes into one or more clusters by position in the DOM
 * tree.
 *
 * This implements an agglomerative clustering. It uses single linkage, since
 * we're talking about adjacency here more than Euclidean proximity: the
 * clusters we're talking about in the DOM will tend to be adjacent, not
 * overlapping. We haven't tried other linkage criteria yet.
 *
 * In a later release, we may consider score or notes.
 *
 * @arg {Fnode[]|Node[]} fnodes :term:`fnodes<fnode>` or DOM nodes to group
 *     into clusters
 * @arg {number} splittingDistance The closest-nodes :func:`distance` beyond
 *     which we will not attempt to unify 2 clusters. Make this larger to make
 *     larger clusters.
 * @arg getDistance {function} A function that returns some notion of numerical
 *    distance between 2 nodes. Default: :func:`distance`
 * @return {Array} An Array of Arrays, with each Array containing all the
 *     nodes in one cluster. Note that neither the clusters nor the nodes are
 *     in any particular order. You may find :func:`domSort` helpful to remedy
 *     the latter.
 */
function clusters(fnodes, splittingDistance, getDistance = distance) {
    const matrix = new DistanceMatrix(fnodes, getDistance);
    let closest;

    while (matrix.numClusters() > 1 && (closest = matrix.closest()).distance < splittingDistance) {
        matrix.merge(closest.a, closest.b);
    }

    return matrix.clusters();
}

var clusters$1 = /*#__PURE__*/Object.freeze({
  __proto__: null,
  distance: distance,
  euclidean: euclidean,
  clusters: clusters
});

// The left-hand side of a rule


/**
 * Take nodes that match a given DOM selector. Example:
 * ``dom('meta[property="og:title"]')``
 *
 * Every ruleset has at least one ``dom`` or :func:`element` rule, as that is
 * where nodes begin to flow into the system. If run against a subtree of a
 * document, the root of the subtree is not considered as a possible match.
 */
function dom(selector) {
    return new DomLhs(selector);
}

/**
 * Take a single given node if it matches a given DOM selector, without looking
 * through its descendents or ancestors. Otherwise, take no nodes. Example:
 * ``element('input')``
 *
 * This is useful for applications in which you want Fathom to classify an
 * element the user has selected, rather than scanning the whole page for
 * candidates.
 */
function element(selector) {
    return new ElementLhs(selector);
}

/**
 * Rules and the LHSs and RHSs that comprise them have no mutable state. This
 * lets us make BoundRulesets from Rulesets without duplicating the rules. It
 * also lets us share a common cache among rules: multiple ones might care
 * about a cached type(), for instance; there isn't a one-to-one relationship
 * of storing with caring. There would also, because of the interdependencies
 * of rules in a ruleset, be little use in segmenting the caches: if you do
 * something that causes one to need to be cleared, you'll need to clear many
 * more as well.
 *
 * Lhses are responsible for maintaining ruleset.maxCache.
 *
 * Lhs and its subclasses are private to the Fathom framework.
 */
class Lhs {
    constructor() {
        this._predicate = () => true;
    }

    /** Return a new Lhs of the appropriate kind, given its first call. */
    static fromFirstCall(firstCall) {
        // firstCall is never 'dom', because dom() directly returns a DomLhs.
        if (firstCall.method === 'type') {
            return new TypeLhs(...firstCall.args);
        } else if (firstCall.method === 'and') {
            return new AndLhs(firstCall.args);
        } else if (firstCall.method === 'nearest') {
            return new NearestLhs(firstCall.args);
        } else {
            throw new Error('The left-hand side of a rule() must start with dom(), type(), and(), or nearest().');
        }
    }

    /**
     * Prune nodes from consideration early in run execution, before scoring is
     * done.
     *
     * Reserve this for where you are sure it is always correct or when
     * performance demands it. It is generally preferable to use :func:`score`
     * and let the :doc:`trainer<training>` determine the relative significance
     * of each rule. Human intuition as to what is important is often wrong:
     * for example, one might assume that a music player website would include
     * the word "play", but this does not hold once you include sites in other
     * languages.
     *
     * Can be chained after :func:`type` or :func:`dom`.
     *
     * Example: ``dom('p').when(isVisible)``
     *
     * @arg {function} predicate Accepts a fnode and returns a boolean
     */
    when(predicate) {
        let lhs = this.clone();
        lhs._predicate = predicate;
        return lhs;
    }

    /**
     * Of all the dom nodes selected by type() or dom(), return only
     * the fnodes that satisfy all the predicates imposed by calls to
     * when()
     */
    fnodesSatisfyingWhen(fnodes) {
        return Array.from(fnodes).filter(this._predicate);
    }

    /**
     * Return an iterable of output fnodes selected by this left-hand-side
     * expression.
     *
     * Pre: The rules I depend on have already been run, and their results are
     * in ruleset.typeCache.
     *
     * @arg ruleset {BoundRuleset}
     */
    // fnodes (ruleset) {}

    /**
     * Check that a RHS-emitted fact is legal for this kind of LHS, and throw
     * an error if it isn't.
     */
    checkFact(fact) {}

    /**
     * Return the single type the output of the LHS is guaranteed to have.
     * Return undefined if there is no such single type we can ascertain.
     */
    guaranteedType() {}

    /**
     * Return the type I aggregate if I am an aggregate LHS; return undefined
     * otherwise.
     */
    aggregatedType() {}

    /**
     * Return each combination of types my selected nodes could be locally (that
     * is, by this rule only) constrained to have.
     *
     * For example, type(A) would return [A]. and(A, or(B, C)) would return
     * [AB, AC, ABC]. More examples:
     *
     * or(A, B) → typeIn(A, B, C)  # Finalizes A, B.   combos A, B, AB: finalizes AB. Optimization: there's no point in returning the last combo in ors. Compilation into 2 rules with identical RHSs will inherently implement this optimization.
     * or(A, B) → typeIn(A, B)  # Finalizes A, B
     * or(A, B) → A  # Finalizes B
     * and(A) -> A  # Finalizes nothing
     * and(A, B) -> A  # Finalizes nothing.   AB: Ø
     * and(A) -> typeIn(A, B)  # Finalizes A.   A
     * and(A, B) -> typeIn(A, B)  # Finalizes nothing.   AB
     * and(A, B) -> typeIn(A, B, C)  # Finalizes A, B.   AB
     * and(A, or(B, C)) -> D  # Finalizes A, B, C.   AB, AC, ABC: ABC
     * and(A, or(B, C)) -> B  # Finalizes A, C.   AB, AC, ABC: AC
     * type(A).not(and(A, B)) ->
     *
     * @return {NiceSet[]}
     */
    // possibleTypeCombinations() {}

    /**
     * Types mentioned in this LHS.
     *
     * In other words, the types I need to know the assignment status of before
     * I can make my selections
     *
     * @return NiceSet of strings
     */
    // typesMentioned() {}
}

class DomLhs extends Lhs {
    constructor(selector) {
        super();
        if (selector === undefined) {
            throw new Error('A querySelector()-style selector is required as the argument to ' + this._callName() + '().');
        }
        this.selector = selector;
    }

    /**
     * Return the name of this kind of LHS, for use in error messages.
     */
    _callName() {
        return 'dom';
    }

    clone() {
        return new this.constructor(this.selector);
    }

    fnodes(ruleset) {
        return this._domNodesToFilteredFnodes(
            ruleset,
            ruleset.doc.querySelectorAll(this.selector));
    }

    /**
     * Turn a NodeList of DOM nodes into an array of fnodes, and filter out
     * those that don't match the :func:`when()` clause.
     */
    _domNodesToFilteredFnodes(ruleset, domNodes) {
        let ret = [];
        for (let i = 0; i < domNodes.length; i++) {
            ret.push(ruleset.fnodeForElement(domNodes[i]));
        }
        return this.fnodesSatisfyingWhen(ret);
    }

    checkFact(fact) {
        if (fact.type === undefined) {
            throw new Error(`The right-hand side of a ${this._callName()}() rule failed to specify a type. This means there is no way for its output to be used by later rules. All it specified was ${fact}.`);
        }
    }

    asLhs() {
        return this;
    }

    possibleTypeCombinations() {
        return [];
    }

    typesMentioned() {
        return new NiceSet();
    }
}

class ElementLhs extends DomLhs {
    _callName() {
        return 'element';
    }

    fnodes(ruleset) {
        return this._domNodesToFilteredFnodes(
            ruleset,
            ruleset.doc.matches(this.selector) ? [ruleset.doc] : []);
    }
}

/** Internal representation of a LHS constrained by type but not by max() */
class TypeLhs extends Lhs {
    constructor(type) {
        super();
        if (type === undefined) {
            throw new Error('A type name is required when calling type().');
        }
        this._type = type;  // the input type
    }

    clone() {
        return new this.constructor(this._type);
    }

    fnodes(ruleset) {
        const cached = getDefault(ruleset.typeCache, this._type, () => []);
        return this.fnodesSatisfyingWhen(cached);
    }

    /** Override the type previously specified by this constraint. */
    type(inputType) {
        // Preserve the class in case this is a TypeMaxLhs.
        return new this.constructor(inputType);
    }

    /**
     * Of the nodes selected by a ``type`` call to the left, constrain the LHS
     * to return only the max-scoring one. If there is a tie, more than 1 node
     * will be returned. Example: ``type('titley').max()``
     */
    max() {
        return new TypeMaxLhs(this._type);
    }

    /**
     * Take the nodes selected by a ``type`` call to the left, group them into
     * clusters, and return the nodes in the cluster that has the highest total
     * score (on the relevant type).
     *
     * Nodes come out in arbitrary order, so, if you plan to emit them,
     * consider using ``.out('whatever').allThrough(domSort)``. See
     * :func:`domSort`.
     *
     * If multiple clusters have equally high scores, return an arbitrary one,
     * because Fathom has no way to represent arrays of arrays in rulesets.
     *
     * @arg options {Object} The same depth costs taken by :func:`distance`,
     *     plus ``splittingDistance``, which is the distance beyond which 2
     *     clusters will be considered separate. ``splittingDistance``, if
     *     omitted, defaults to 3.
     */
    bestCluster(options) {
        return new BestClusterLhs(this._type, options);
    }

    // Other clustering calls could be called biggestCluster() (having the most
    // nodes) and bestAverageCluster() (having the highest average score).

    guaranteedType() {
        return this._type;
    }

    possibleTypeCombinations() {
        return [this.typesMentioned()];
    }

    typesMentioned() {
        return new NiceSet([this._type]);
    }
}

/**
 * Abstract LHS that is an aggregate function taken across all fnodes of a type
 *
 * The main point here is that any aggregate function over a (typed) set of
 * nodes depends on first computing all the rules that could emit those nodes
 * (nodes of that type).
 */
class AggregateTypeLhs extends TypeLhs {
    aggregatedType() {
        return this._type;
    }
}

/**
 * Internal representation of a LHS that has both type and max([NUMBER])
 * constraints. max(NUMBER != 1) support is not yet implemented.
 */
class TypeMaxLhs extends AggregateTypeLhs {
    /**
     * Return the max-scoring node (or nodes if there is a tie) of the given
     * type.
     */
    fnodes(ruleset) {
        // TODO: Optimize better. Walk the dependency tree, and run only the
        // rules that could possibly lead to a max result. As part of this,
        // make RHSs expose their max potential scores.
        const self = this;
        // Work around V8 bug:
        // https://stackoverflow.com/questions/32943776/using-super-within-an-
        // arrow-function-within-an-arrow-function-within-a-method
        const getSuperFnodes = () => super.fnodes(ruleset);
        return setDefault(
            ruleset.maxCache,
            this._type,
            function maxFnodesOfType() {
                return maxes(getSuperFnodes(), fnode => ruleset.weightedScore(fnode.scoresSoFarFor(self._type)));
            });
    }
}

class BestClusterLhs extends AggregateTypeLhs {
    constructor(type, options) {
        super(type);
        this._options = options || {splittingDistance: 3};
    }

    /**
     * Group the nodes of my type into clusters, and return the cluster with
     * the highest total score for that type.
     */
    fnodes(ruleset) {
        // Get the nodes of the type:
        const fnodesOfType = Array.from(super.fnodes(ruleset));
        if (fnodesOfType.length === 0) {
            return [];
        }
        // Cluster them:
        const clusts = clusters(
            fnodesOfType,
            this._options.splittingDistance,
            (a, b) => distance(a, b, this._options));
        // Tag each cluster with the total of its nodes' scores:
        const clustsAndSums = clusts.map(
            clust => [clust,
                      sum(clust.map(fnode => fnode.scoreFor(this._type)))]);
        // Return the highest-scoring cluster:
        return max(clustsAndSums, clustAndSum => clustAndSum[1])[0];
    }
}

class AndLhs extends Lhs {
    constructor(lhss) {
        super();

        // For the moment, we accept only type()s as args. TODO: Generalize to
        // type().max() and such later.
        this._args = lhss.map(sideToTypeLhs);
    }

    *fnodes(ruleset) {
        // Take an arbitrary one for starters. Optimization: we could always
        // choose the pickiest one to start with.
        const fnodes = this._args[0].fnodes(ruleset);
        // Then keep only the fnodes that have the type of every other arg:
        fnodeLoop: for (let fnode of fnodes) {
            for (let otherLhs of this._args.slice(1)) {
                // Optimization: could use a .hasTypeSoFar() below
                if (!fnode.hasType(otherLhs.guaranteedType())) {
                    // TODO: This is n^2. Why is there no set intersection in JS?!
                    continue fnodeLoop;
                }
            }
            yield fnode;
        }
    }

    possibleTypeCombinations() {
        return [this.typesMentioned()];
    }

    typesMentioned() {
        return new NiceSet(this._args.map(arg => arg.guaranteedType()));
    }
}

function sideToTypeLhs(side) {
    const lhs = side.asLhs();
    if (!(lhs.constructor === TypeLhs)) {
        throw new Error('and() and nearest() support only simple type() calls as arguments for now.');
        // TODO: Though we could solve this with a compilation step: and(type(A), type(B).max()) is equivalent to type(B).max() -> type(Bmax); and(type(A), type(Bmax)).
        // In fact, we should be able to compile most (any?) arbitrary and()s, including nested ands and and(type(...).max(), ...) constructions into several and(type(A), type(B), ...) rules.
    }
    return lhs;
}

class NearestLhs extends Lhs {
    constructor([a, b, distance]) {
        super();
        this._a = sideToTypeLhs(a);
        this._b = sideToTypeLhs(b);
        this._distance = distance;
    }

    /**
     * Return an iterable of {fnodes, transformer} pairs.
     */
    *fnodes(ruleset) {
        // Go through all the left arg's nodes. For each one, find the closest
        // right-arg's node. O(a * b). Once a right-arg's node is used, we
        // don't eliminate it from consideration, because then order of left-
        // args' nodes would matter.

        // TODO: Still not sure how to get the distance to factor into the
        // score unless we hard-code nearest() to do that. It's a
        // matter of not being able to bind on the RHS to the output of the
        // distance function on the LHS. Perhaps we could at least make
        // distance part of the note and read it in a props() callback.

        // We're assuming here that simple type() calls return just plain
        // fnodes, not {fnode, rhsTransformer} pairs:
        const as_ = this._a.fnodes(ruleset);
        const bs = Array.from(this._b.fnodes(ruleset));
        if (bs.length > 0) {
            // If bs is empty, there can be no nearest nodes, so don't emit any.
            for (const a of as_) {
                const nearest = min(bs, b => this._distance(a, b));
                yield {fnode: a,
                       rhsTransformer: function setNoteIfEmpty(fact) {
                           // If note is explicitly set by the RHS, let it take
                           // precedence, even though that makes this entire LHS
                           // pointless.
                           if (fact.note === undefined) {
                               fact.note = nearest;  // TODO: Wrap this in an object to make room to return distance later.
                           }
                           return fact;
                       }};
            }
        }
    }

    checkFact(fact) {
        // Barf if the fact doesn't set a type at least. It should be a *new* type or at least one that doesn't result in cycles, but we can't deduce that.
    }

    possibleTypeCombinations() {
        return [new NiceSet([this._a.guaranteedType()])];
    }

    typesMentioned() {
        return new NiceSet([this._a.guaranteedType(),
                            this._b.guaranteedType()]);
    }

    guaranteedType() {
        return this._a.guaranteedType();
    }
}

// The right-hand side of a rule


const TYPE = 1;
const NOTE = 2;
const SCORE = 4;
const ELEMENT = 8;
const SUBFACTS = {
    type: TYPE,
    note: NOTE,
    score: SCORE,
    element: ELEMENT
};

/**
 * Expose the output of this rule's LHS as a "final result" to the surrounding
 * program. It will be available by calling :func:`~BoundRuleset.get` on the
 * ruleset and passing the key. You can run each node through a callback
 * function first by adding :func:`through()`, or you can run the entire set of
 * nodes through a callback function by adding :func:`allThrough()`.
 */
function out(key) {
    return new OutwardRhs(key);
}

class InwardRhs {
    constructor(calls = [], max = Infinity, types) {
        this._calls = calls.slice();
        this._max = max;  // max score
        this._types = new NiceSet(types);  // empty set if unconstrained
    }

    /**
     * Declare that the maximum returned subscore is such and such,
     * which helps the optimizer plan efficiently. This doesn't force it to be
     * true; it merely throws an error at runtime if it isn't. To lift an
     * ``atMost`` constraint, call ``atMost()`` (with no args). The reason
     * ``atMost`` and ``typeIn`` apply until explicitly cleared is so that, if
     * someone used them for safety reasons on a lexically distant rule you are
     * extending, you won't stomp on their constraint and break their
     * invariants accidentally.
     */
    atMost(score) {
        return new this.constructor(this._calls, score, this._types);
    }

    _checkAtMost(fact) {
        if (fact.score !== undefined && fact.score > this._max) {
            throw new Error(`Score of ${fact.score} exceeds the declared atMost(${this._max}).`);
        }
    }

    /**
      * Determine any of type, note, score, and element using a callback. This
      * overrides any previous call to `props` and, depending on what
      * properties of the callback's return value are filled out, may override
      * the effects of other previous calls as well.
      *
      * The callback should return...
      *
      * * An optional :term:`subscore`
      * * A type (required on ``dom(...)`` rules, defaulting to the input one on
      *   ``type(...)`` rules)
      * * Optional notes
      * * An element, defaulting to the input one. Overriding the default
      *   enables a callback to walk around the tree and say things about nodes
      *   other than the input one.
      */
    props(callback) {
        function getSubfacts(fnode) {
            const subfacts = callback(fnode);
            // Filter the raw result down to okayed properties so callbacks
            // can't insert arbitrary keys (like conserveScore, which might
            // mess up the optimizer).
            for (let subfact in subfacts) {
                if (!SUBFACTS.hasOwnProperty(subfact) || !(SUBFACTS[subfact] & getSubfacts.possibleSubfacts)) {
                    // The ES5.1 spec says in 12.6.4 that it's fine to delete
                    // as we iterate.
                    delete subfacts[subfact];
                }
            }
            return subfacts;
        }
        // Thse are the subfacts this call could affect:
        getSubfacts.possibleSubfacts = TYPE | NOTE | SCORE | ELEMENT;
        getSubfacts.kind = 'props';
        return new this.constructor(this._calls.concat(getSubfacts),
                                    this._max,
                                    this._types);
    }

    /**
     * Set the type applied to fnodes processed by this RHS.
     */
    type(theType) {
        // In the future, we might also support providing a callback that receives
        // the fnode and returns a type. We couldn't reason based on these, but the
        // use would be rather a consise way to to override part of what a previous
        // .props() call provides.

        // Actually emit a given type.
        function getSubfacts() {
            return {type: theType};
        }
        getSubfacts.possibleSubfacts = TYPE;
        getSubfacts.type = theType;
        getSubfacts.kind = 'type';
        return new this.constructor(this._calls.concat(getSubfacts),
                                    this._max,
                                    this._types);
    }

    /**
     * Constrain this rule to emit 1 of a set of given types. Pass no args to lift
     * a previous ``typeIn`` constraint, as you might do when basing a LHS on a
     * common value to factor out repetition.
     *
     * ``typeIn`` is mostly a hint for the query planner when you're emitting types
     * dynamically from ``props`` calls—in fact, an error will be raised if
     * ``props`` is used without a ``typeIn`` or ``type`` to constrain it—but it
     * also checks conformance at runtime to ensure validity.
     */
    typeIn(...types) {
        // Rationale: If we used the spelling "type('a', 'b', ...)" instead of
        // this, one might expect type('a', 'b').type(fn) to have the latter
        // call override, while expecting type(fn).type('a', 'b') to keep both
        // in effect. Then different calls to type() don't consistently
        // override each other, and the rules get complicated. Plus you can't
        // inherit a type constraint and then sub in another type-returning
        // function that still gets the constraint applied.
        return new this.constructor(this._calls,
                                    this._max,
                                    types);
    }

    /**
     * Check a fact for conformance with any typeIn() call.
     *
     * @arg leftType the type of the LHS, which becomes my emitted type if the
     *    fact doesn't specify one
     */
    _checkTypeIn(result, leftType) {
        if (this._types.size > 0) {
            if (result.type === undefined) {
                if (!this._types.has(leftType)) {
                    throw new Error(`A right-hand side claimed, via typeIn(...) to emit one of the types ${this._types} but actually inherited ${leftType} from the left-hand side.`);
                }
            } else if (!this._types.has(result.type)) {
                throw new Error(`A right-hand side claimed, via typeIn(...) to emit one of the types ${this._types} but actually emitted ${result.type}.`);
            }
        }
    }

    /**
     * Whatever the callback returns (even ``undefined``) becomes the note of
     * the fact. This overrides any previous call to ``note``.
     */
    note(callback) {
        function getSubfacts(fnode) {
            return {note: callback(fnode)};
        }
        getSubfacts.possibleSubfacts = NOTE;
        getSubfacts.kind = 'note';
        return new this.constructor(this._calls.concat(getSubfacts),
                                    this._max,
                                    this._types);
    }

    /**
     * Affect the confidence with which the input node should be considered a
     * member of a type.
     *
     * The parameter is generally between 0 and 1 (inclusive), with 0 meaning
     * the node does not have the "smell" this rule checks for and 1 meaning it
     * does. The range between 0 and 1 is available to represent "fuzzy"
     * confidences. If you have an unbounded range to compress down to [0, 1],
     * consider using :func:`sigmoid` or a scaling thereof.
     *
     * Since every node can have multiple, independent scores (one for each
     * type), this applies to the type explicitly set by the RHS or, if none,
     * to the type named by the ``type`` call on the LHS. If the LHS has none
     * because it's a ``dom(...)`` LHS, an error is raised.
     *
     * @arg {number|function} scoreOrCallback Can either be a static number,
     *     generally 0 to 1 inclusive, or else a callback which takes the fnode
     *     and returns such a number. If the callback returns a boolean, it is
     *     cast to a number.
     */
    score(scoreOrCallback) {
        let getSubfacts;

        function getSubfactsFromNumber(fnode) {
            return {score: scoreOrCallback};
        }

        function getSubfactsFromFunction(fnode) {
            let result = scoreOrCallback(fnode);
            if (typeof result === 'boolean') {
                // Case bools to numbers for convenience. Boolean features are
                // common. Don't cast other things, as it frustrates ruleset
                // debugging.
                result = Number(result);
            }
            return {score: result};
        }

        if (typeof scoreOrCallback === 'number') {
            getSubfacts = getSubfactsFromNumber;
        } else {
            getSubfacts = getSubfactsFromFunction;
        }
        getSubfacts.possibleSubfacts = SCORE;
        getSubfacts.kind = 'score';

        return new this.constructor(this._calls.concat(getSubfacts),
                                    this._max,
                                    this._types);
    }

    // Future: why not have an .element() method for completeness?

    // -------- Methods below this point are private to the framework. --------

    /**
     * Run all my props().type().note().score() stuff across a given fnode,
     * enforce my max() stuff, and return a fact ({element, type, score,
     * notes}) for incorporation into that fnode (or a different one, if
     * element is specified). Any of the 4 fact properties can be missing;
     * filling in defaults is a job for the caller.
     *
     * @arg leftType The type the LHS takes in
     */
    fact(fnode, leftType) {
        const doneKinds = new Set();
        const result = {};
        let haveSubfacts = 0;
        for (let call of reversed(this._calls)) {
            // If we've already called a call of this kind, then forget it.
            if (!doneKinds.has(call.kind)) {
                doneKinds.add(call.kind);

                if (~haveSubfacts & call.possibleSubfacts) {
                    // This call might provide a subfact we are missing.
                    const newSubfacts = call(fnode);

                    // We start with an empty object, so we're okay here.
                    // eslint-disable-next-line guard-for-in
                    for (let subfact in newSubfacts) {
                        // A props() callback could insert arbitrary keys into
                        // the result, but it shouldn't matter, because nothing
                        // pays any attention to them.
                        if (!result.hasOwnProperty(subfact)) {
                            result[subfact] = newSubfacts[subfact];
                        }
                        haveSubfacts |= SUBFACTS[subfact];
                    }
                }
            }
        }
        this._checkAtMost(result);
        this._checkTypeIn(result, leftType);
        return result;
    }

    /**
     * Return a record describing the types I might emit (which means either to
     * add a type to a fnode or to output a fnode that already has that type).
     * {couldChangeType: whether I might add a type to the fnode,
     *  possibleTypes: If couldChangeType, the types I might emit; empty set if
     *      we cannot infer it. If not couldChangeType, undefined.}
     */
    possibleEmissions() {
        // If there is a typeIn() constraint or there is a type() call to the
        // right of all props() calls, we have a constraint. We hunt for the
        // tightest constraint we can find, favoring a type() call because it
        // gives us a single type but then falling back to a typeIn().
        let couldChangeType = false;
        for (let call of reversed(this._calls)) {
            if (call.kind === 'props') {
                couldChangeType = true;
                break;
            } else if (call.kind === 'type') {
                return {couldChangeType: true,
                        possibleTypes: new Set([call.type])};
            }
        }
        return {couldChangeType,
                possibleTypes: this._types};
    }
}

class OutwardRhs {
    constructor(key, through = x => x, allThrough = x => x) {
        this.key = key;
        this.callback = through;
        this.allCallback = allThrough;
    }

    /**
     * Append ``.through`` to :func:`out` to run each :term:`fnode` emitted
     * from the LHS through an arbitrary function before returning it to the
     * containing program. Example::
     *
     *     out('titleLengths').through(fnode => fnode.noteFor('title').length)
     */
    through(callback) {
        return new this.constructor(this.key, callback, this.allCallback);
    }

    /**
     * Append ``.allThrough`` to :func:`out` to run the entire iterable of
     * emitted :term:`fnodes<fnode>` through an arbitrary function before
     * returning them to the containing program. Example::
     *
     *     out('sortedTitles').allThrough(domSort)
     */
    allThrough(callback) {
        return new this.constructor(this.key, this.callback, callback);
    }

    asRhs() {
        return this;
    }
}

function props(callback) {
    return new Side({method: 'props', args: [callback]});
}

/** Constrain to an input type on the LHS, or apply a type on the RHS. */
function type(theType) {
    return new Side({method: 'type', args: [theType]});
}

function note(callback) {
    return new Side({method: 'note', args: [callback]});
}

function score(scoreOrCallback) {
    return new Side({method: 'score', args: [scoreOrCallback]});
}

function atMost(score) {
    return new Side({method: 'atMost', args: [score]});
}

function typeIn(...types) {
    return new Side({method: 'typeIn', args: types});
}

/**
 * Pull nodes that conform to multiple conditions at once.
 *
 * For example: ``and(type('title'), type('english'))``
 *
 * Caveats: ``and`` supports only simple ``type`` calls as arguments for now,
 * and it may fire off more rules as prerequisites than strictly necessary.
 * ``not`` and ``or`` don't exist yet, but you can express ``or`` the long way
 * around by having 2 rules with identical RHSs.
 */
function and(...lhss) {
    return new Side({method: 'and', args: lhss});
}

/**
 * Experimental. For each :term:`fnode` from ``typeCallA``, find the closest
 * node from ``typeCallB``, and attach it as a note. The note is attached to
 * the type specified by the RHS, defaulting to the type of ``typeCallA``. If
 * no nodes are emitted from ``typeCallB``, do nothing.
 *
 * For example... ::
 *
 *     nearest(type('image'), type('price'))
 *
 * The score of the ``typeCallA`` can be added to the new type's score by using
 * :func:`conserveScore` (though this routine has since been removed)::
 *
 *     rule(nearest(type('image'), type('price')),
 *          type('imageWithPrice').score(2).conserveScore())
 *
 * Caveats: ``nearest`` supports only simple ``type`` calls as arguments ``a``
 * and ``b`` for now.
 *
 * @arg distance {function} A function that takes 2 fnodes and returns a
 *     numerical distance between them. Included options are :func:`distance`,
 *     which is a weighted topological distance, and :func:`euclidean`, which
 *     is a spatial distance.
 */
function nearest(typeCallA, typeCallB, distance = euclidean) {
    return new Side({method: 'nearest', args: [typeCallA, typeCallB, distance]});
}

/**
 * A chain of calls that can be compiled into a Rhs or Lhs, depending on its
 * position in a Rule. This lets us use type() as a leading call for both RHSs
 * and LHSs. I would prefer to do this dynamically, but that wouldn't compile
 * down to old versions of ES.
 */
class Side {
    constructor(...calls) {
        // A "call" is like {method: 'dom', args: ['p.smoo']}.
        this._calls = calls;
    }

    max() {
        return this._and('max');
    }

    bestCluster(options) {
        return this._and('bestCluster', options);
    }

    props(callback) {
        return this._and('props', callback);
    }

    type(...types) {
        return this._and('type', ...types);
    }

    note(callback) {
        return this._and('note', callback);
    }

    score(scoreOrCallback) {
        return this._and('score', scoreOrCallback);
    }

    atMost(score) {
        return this._and('atMost', score);
    }

    typeIn(...types) {
        return this._and('typeIn', ...types);
    }

    and(...lhss) {
        return this._and('and', lhss);
    }

    _and(method, ...args) {
        return new this.constructor(...this._calls.concat({method, args}));
    }

    asLhs() {
        return this._asSide(Lhs.fromFirstCall(this._calls[0]), this._calls.slice(1));
    }

    asRhs() {
        return this._asSide(new InwardRhs(), this._calls);
    }

    _asSide(side, calls) {
        for (let call of calls) {
            side = side[call.method](...call.args);
        }
        return side;
    }

    when(pred) {
        return this._and('when', pred);
    }
}

/**
 * A wrapper around a DOM node, storing :term:`types<type>`,
 * :term:`scores<score>`, and :term:`notes<note>` that apply to it
 */
class Fnode {
    /**
     * @arg element The DOM element described by the fnode.
     * @arg ruleset The ruleset which created the fnode.
     */
    constructor(element, ruleset) {
        if (element === undefined) {
            throw new Error("Someone tried to make a fnode without specifying the element they're talking about.");
        }
        /**
         * The raw DOM element this fnode describes
         */
        this.element = element;
        this._ruleset = ruleset;

        // A map of type => {score: number, note: anything}. `score` is always
        // present and defaults to 1. A note is set iff `note` is present and
        // not undefined.
        this._types = new Map();

        // Note: conserveScore() is temporarily absent in 3.0.
        //
        // By default, a fnode has an independent score for each of its types.
        // However, a RHS can opt to conserve the score of an upstream type,
        // carrying it forward into another type. To avoid runaway scores in
        // the case that multiple rules choose to do this, we limit the
        // contribution of an upstream type's score to being multiplied in a
        // single time. In this set, we keep track of which upstream types'
        // scores have already been multiplied into each type. LHS fnode => Set
        // of types whose score for that node have been multiplied into this
        // node's score.
        this._conservedScores = new Map();
    }

    /**
     * Return whether the given type is one of the ones attached to the wrapped
     * HTML node.
     */
    hasType(type) {
        // Run type(theType) against the ruleset to make sure this doesn't
        // return false just because we haven't lazily run certain rules yet.
        this._computeType(type);
        return this._types.has(type);
    }

    /**
     * Return the confidence, in the range (0, 1), that the fnode belongs to the
     * given type, 0 by default.
     */
    scoreFor(type) {
        this._computeType(type);
        return sigmoid(this._ruleset.weightedScore(this.scoresSoFarFor(type)) +
                       getDefault(this._ruleset.biases, type, () => 0));
    }

    /**
     * Return the fnode's note for the given type, ``undefined`` if none.
     */
    noteFor(type) {
        this._computeType(type);
        return this._noteSoFarFor(type);
    }

    /**
     * Return whether this fnode has a note for the given type.
     *
     * ``undefined`` is not considered a note and may be overwritten with
     * impunity.
     */
    hasNoteFor(type) {
        this._computeType(type);
        return this._hasNoteSoFarFor(type);
    }

    // -------- Methods below this point are private to the framework. --------

    /**
     * Return an iterable of the types tagged onto me by rules that have
     * already executed.
     */
    typesSoFar() {
        return this._types.keys();
    }

    _noteSoFarFor(type) {
        return this._typeRecordForGetting(type).note;
    }

    _hasNoteSoFarFor(type) {
        return this._noteSoFarFor(type) !== undefined;
    }

    /**
     * Return the score thus far computed on me for a certain type. Doesn't
     * implicitly run any rules. If no score has yet been determined for the
     * given type, return undefined.
     */
    scoresSoFarFor(type) {
        return this._typeRecordForGetting(type).score;
    }

    /**
     * Add a given number to one of our per-type scores. Implicitly assign us
     * the given type. Keep track of which rule it resulted from so we can
     * later mess with the coeffs.
     */
    addScoreFor(type, score, ruleName) {
        this._typeRecordForSetting(type).score.set(ruleName, score);
    }

    /**
     * Set the note attached to one of our types. Implicitly assign us that
     * type if we don't have it already.
     */
    setNoteFor(type, note) {
        if (this._hasNoteSoFarFor(type)) {
            if (note !== undefined) {
                throw new Error(`Someone (likely the right-hand side of a rule) tried to add a note of type ${type} to an element, but one of that type already exists. Overwriting notes is not allowed, since it would make the order of rules matter.`);
            }
            // else the incoming note is undefined and we already have the
            // type, so it's a no-op
        } else {
            // Apply either a type and note or just a type (which means a note
            // that is undefined):
            this._typeRecordForSetting(type).note = note;
        }
    }

    /**
     * Return a score/note record for a type, creating it if it doesn't exist.
     */
    _typeRecordForSetting(type) {
        return setDefault(this._types, type, () => ({score: new Map()}));
    }

    /**
     * Manifest a temporary type record for reading, working around the lack of
     * a .? operator in JS.
     */
    _typeRecordForGetting(type) {
        return getDefault(this._types, type, () => ({score: new Map()}));
    }

    /**
     * Make sure any scores, notes, and type-tagging for the given type are
     * computed for my element.
     */
    _computeType(theType) {
        if (!this._types.has(theType)) {  // Prevent infinite recursion when an A->A rule looks at A's note in a callback.
            this._ruleset.get(type(theType));
        }
    }
}

/**
 * Construct and return the proper type of rule class based on the
 * inwardness/outwardness of the RHS.
 *
 * @arg lhs {Lhs} The left-hand side of the rule
 * @arg rhs {Rhs} The right-hand side of the rule
 * @arg options {object} Other, optional information about the rule.
 *     Currently, the only recognized option is ``name``, which points to a
 *     string that uniquely identifies this rule in a ruleset. The name
 *     correlates this rule with one of the coefficients passed into
 *     :func:`ruleset`. If no name is given, an identifier is assigned based on
 *     the index of this rule in the ruleset, but that is, of course, brittle.
 */
function rule(lhs, rhs, options) {
    // Since out() is a valid call only on the RHS (unlike type()), we can take
    // a shortcut here: any outward RHS will already be an OutwardRhs; we don't
    // need to sidetrack it through being a Side. And OutwardRhs has an asRhs()
    // that just returns itself.
    if (typeof rhs === 'string') {
        rhs = out(rhs);
    }
    return new ((rhs instanceof OutwardRhs) ? OutwardRule : InwardRule)(lhs, rhs, options);
}

let nextRuleNumber = 0;
function newInternalRuleName() {
    return '_' + nextRuleNumber++;
}

/**
 * We place the in/out distinction in Rules because it determines whether the
 * RHS result is cached, and Rules are responsible for maintaining the rulewise
 * cache ruleset.ruleCache.
 */
class Rule {  // abstract
    constructor(lhs, rhs, options) {
        this.lhs = lhs.asLhs();
        this.rhs = rhs.asRhs();
        // TODO: Make auto-generated rule names be based on the out types of
        // the rules, e.g. _priceish_4. That way, adding rules for one type
        // won't make the coeffs misalign for another.
        this.name = (options ? options.name : undefined) || newInternalRuleName();
    }

    /**
     * Return a NiceSet of the rules that this one shallowly depends on in the
     * given ruleset. In a BoundRuleset, this may include rules that have
     * already been executed.
     *
     * Depend on emitters of any LHS type this rule finalizes. (See
     * _typesFinalized for a definition.) Depend on adders of any other LHS
     * types (because, after all, we need to know what nodes have that type in
     * order to find the set of LHS nodes). This works for simple rules and
     * complex ones like and().
     *
     * Specific examples (where A is a type):
     * * A.max->* depends on anything emitting A.
     * * Even A.max->A depends on A emitters, because we have to have all the
     *   scores factored in first. For example, what if we did
     *   max(A)->score(.5)?
     * * A->A depends on anything adding A.
     * * A->(something other than A) depends on anything emitting A. (For
     *   example, we need the A score finalized before we could transfer it to
     *   B using conserveScore().)
     * * A->out() also depends on anything emitting A. Fnode methods aren't
     *   smart enough to lazily run emitter rules as needed. We could make them
     *   so if it was shown to be an advantage.
     */
    prerequisites(ruleset) {
        // Optimization: we could cache the result of this when in a compiled (immutable) ruleset.

        // Extend prereqs with rules derived from each of the given types. If
        // no rules are found, raise an exception, as that indicates a
        // malformed ruleset.
        function extendOrThrow(prereqs, types, ruleGetter, verb) {
            for (let type of types) {
                const rules = ruleGetter(type);
                if (rules.length > 0) {
                    prereqs.extend(rules);
                } else {
                    throw new Error(`No rule ${verb} the "${type}" type, but another rule needs it as input.`);
                }
            }
        }

        const prereqs = new NiceSet();

        // Add finalized types:
        extendOrThrow(prereqs, this._typesFinalized(), type => ruleset.inwardRulesThatCouldEmit(type), 'emits');

        // Add mentioned types:
        // We could say this.lhs.typesMentioned().minus(typesFinalized) as an
        // optimization. But since types mentioned are a superset of types
        // finalized and rules adding are a subset of rules emitting, we get
        // the same result without.
        extendOrThrow(prereqs, this.lhs.typesMentioned(), type => ruleset.inwardRulesThatCouldAdd(type), 'adds');

        return prereqs;
    }

    /**
     * Return the types that this rule finalizes.
     *
     * To "finalize" a type means to make sure we're finished running all
     * possible rules that might change a node's score or notes w.r.t. a given
     * type. This is generally done because we're about to use those data for
     * something, like computing a new type's score or or an aggregate
     * function. Exhaustively, we're about to...
     * * change the type of the nodes or
     * * aggregate all nodes of a type
     *
     * This base-class implementation just returns what aggregate functions
     * need, since that need spans inward and outward rules.
     *
     * @return Set of types
     */
    _typesFinalized() {
        // Get the types that are fed to aggregate functions. Aggregate
        // functions are more demanding than a simple type() LHS. A type() LHS
        // itself does not finalize its nodes because the things it could do to
        // them without changing their type (adding notes, adding to score)
        // are immutable or commutative (respectively). Thus, we require a RHS
        // type change in order to require finalization of a simple type()
        // mention. A max(B), OTOH, is not commutative with other B->B rules
        // (imagine type(B).max()->score(.5)), so it must depend on B emitters
        // and thus finalize B. (This will have to be relaxed or rethought when
        // we do the max()/atMost() optimization. Perhaps we can delegate to
        // aggregate functions up in Rule.prerequisites() to ask what their
        // prereqs are. If they implement such an optimization, they can reply.
        // Otherwise, we can assume they are all the nodes of their type.)
        //
        // TODO: Could arbitrary predicates (once we implement those) matter
        // too? Maybe it's not just aggregations.
        const type = this.lhs.aggregatedType();
        return (type === undefined) ? new NiceSet() : new NiceSet([type]);
    }
}

/**
 * A normal rule, whose results head back into the Fathom knowledgebase, to be
 * operated on by further rules.
 */
class InwardRule extends Rule {
    // TODO: On construct, complain about useless rules, like a dom() rule that
    // doesn't assign a type.

    /**
     * Return an iterable of the fnodes emitted by the RHS of this rule.
     * Side effect: update ruleset's store of fnodes, its accounting of which
     * rules are done executing, and its cache of results per type.
     */
    results(ruleset) {
        if (ruleset.doneRules.has(this)) {  // shouldn't happen
            throw new Error('A bug in Fathom caused results() to be called on an inward rule twice. That could cause redundant score contributions, etc.');
        }
        const self = this;
        // For now, we consider most of what a LHS computes to be cheap, aside
        // from type() and type().max(), which are cached by their specialized
        // LHS subclasses.
        const leftResults = this.lhs.fnodes(ruleset);
        // Avoid returning a single fnode more than once. LHSs uniquify
        // themselves, but the RHS can change the element it's talking
        // about and thus end up with dupes.
        const returnedFnodes = new Set();

        // Merge facts into fnodes:
        forEach(
            // leftResult can be either a fnode or a {fnode, rhsTransformer} pair.
            function updateFnode(leftResult) {
                const leftType = self.lhs.guaranteedType();
                // Get a fnode and a RHS transformer, whether a plain fnode is
                // returned or a {fnode, rhsTransformer} pair:
                const {fnode: leftFnode = leftResult, rhsTransformer = identity} = leftResult;
                // Grab the fact from the RHS, and run the LHS's optional
                // transformer over it to pick up anything special it wants to
                // do:
                const fact = rhsTransformer(self.rhs.fact(leftFnode, leftType));
                self.lhs.checkFact(fact);
                const rightFnode = ruleset.fnodeForElement(fact.element || leftFnode.element);
                // If the RHS doesn't specify a type, default to the
                // type of the LHS, if any:
                const rightType = fact.type || self.lhs.guaranteedType();
                if (fact.score !== undefined) {
                    if (rightType !== undefined) {
                        rightFnode.addScoreFor(rightType, fact.score, self.name);
                    } else {
                        throw new Error(`The right-hand side of a rule specified a score (${fact.score}) with neither an explicit type nor one we could infer from the left-hand side.`);
                    }
                }
                if (fact.type !== undefined || fact.note !== undefined) {
                    // There's a reason to call setNoteFor.
                    if (rightType === undefined) {
                        throw new Error(`The right-hand side of a rule specified a note (${fact.note}) with neither an explicit type nor one we could infer from the left-hand side. Notes are per-type, per-node, so that's a problem.`);
                    } else {
                        rightFnode.setNoteFor(rightType, fact.note);
                    }
                }
                returnedFnodes.add(rightFnode);
            },
            leftResults);

        // Update ruleset lookup tables.
        // First, mark this rule as done:
        ruleset.doneRules.add(this);
        // Then, stick each fnode in typeCache under all applicable types.
        // Optimization: we really only need to loop over the types
        // this rule can possibly add.
        for (let fnode of returnedFnodes) {
            for (let type of fnode.typesSoFar()) {
                setDefault(ruleset.typeCache, type, () => new Set()).add(fnode);
            }
        }
        return returnedFnodes.values();
    }

    /**
     * Return a Set of the types that could be emitted back into the system.
     * To emit a type means to either to add it to a fnode emitted from the RHS
     * or to leave it on such a fnode where it already exists.
     */
    typesItCouldEmit() {
        const rhs = this.rhs.possibleEmissions();
        if (!rhs.couldChangeType && this.lhs.guaranteedType() !== undefined) {
            // It's a b -> b rule.
            return new Set([this.lhs.guaranteedType()]);
        } else if (rhs.possibleTypes.size > 0) {
            // We can prove the type emission from the RHS alone.
            return rhs.possibleTypes;
        } else {
            throw new Error('Could not determine the emitted type of a rule because its right-hand side calls props() without calling typeIn().');
        }
    }

    /**
     * Return a Set of types I could add to fnodes I output (where the fnodes
     * did not already have them).
     */
    typesItCouldAdd() {
        const ret = new Set(this.typesItCouldEmit());
        ret.delete(this.lhs.guaranteedType());
        return ret;
    }

    /**
     * Add the types we could change to the superclass's result.
     */
    _typesFinalized() {
        const self = this;
        function typesThatCouldChange() {
            const ret = new NiceSet();

            // Get types that could change:
            const emissions = self.rhs.possibleEmissions();
            if (emissions.couldChangeType) {
                // Get the possible guaranteed combinations of types on the LHS
                // (taking just this LHS into account). For each combo, if the RHS
                // adds a type that's not in the combo, the types in the combo get
                // unioned into ret.
                for (let combo of self.lhs.possibleTypeCombinations()) {
                    for (let rhsType of emissions.possibleTypes) {
                        if (!combo.has(rhsType)) {
                            ret.extend(combo);
                            break;
                        }
                    }
                }
            }
            // Optimization: the possible combos could be later expanded to be
            // informed by earlier rules which add the types mentioned in the LHS.
            // If the only way for something to get B is to have Q first, then we
            // can add Q to each combo and end up with fewer types finalized. Would
            // this imply the existence of a Q->B->Q cycle and thus be impossible?
            // Think about it. If we do this, we can centralize that logic here,
            // rather than repeating it in all the Lhs subclasses).
            return ret;
        }

        return typesThatCouldChange().extend(super._typesFinalized());
    }
}

/**
 * A rule whose RHS is an out(). This represents a final goal of a ruleset.
 * Its results go out into the world, not inward back into the Fathom
 * knowledgebase.
 */
class OutwardRule extends Rule {
    /**
     * Compute the whole thing, including any .through() and .allThrough().
     * Do not mark me done in ruleset.doneRules; out rules are never marked as
     * done so they can be requested many times without having to cache their
     * (potentially big, since they aren't necessarily fnodes?) results. (We
     * can add caching later if it proves beneficial.)
     */
    results(ruleset) {
        /**
         * From a LHS's ``{fnode, rhsTransform}`` object or plain fnode, pick off just
         * the fnode and return it.
         */
        function justFnode(fnodeOrStruct) {
            return (fnodeOrStruct instanceof Fnode) ? fnodeOrStruct : fnodeOrStruct.fnode;
        }

        return this.rhs.allCallback(map(this.rhs.callback, map(justFnode, this.lhs.fnodes(ruleset))));
    }

    /**
     * @return the key under which the output of this rule will be available
     */
    key() {
        return this.rhs.key;
    }

    /**
     * OutwardRules finalize all types mentioned.
     */
    _typesFinalized() {
        return this.lhs.typesMentioned().extend(super._typesFinalized());
    }
}

/**
 * A shortcut for creating a new :class:`Ruleset`, for symmetry with
 * :func:`rule`
 */
function ruleset(rules, coeffs = [], biases = []) {
    return new Ruleset(rules, coeffs, biases);
}

/**
 * An unbound ruleset. When you bind it by calling :func:`~Ruleset.against()`,
 * the resulting :class:`BoundRuleset` will be immutable.
 */
class Ruleset {
    /**
     * @arg rules {Array} Rules returned from :func:`rule`
     * @arg coeffs {Map} A map of rule names to numerical weights, typically
     *     returned by the :doc:`trainer<training>`. Example:
     *     ``[['someRuleName', 5.04], ...]``. If not given, coefficients
     *     default to 1.
     * @arg biases {object} A map of type names to neural-net biases. These
     *      enable accurate confidence estimates. Example: ``[['someType',
     *      -2.08], ...]``. If absent, biases default to 0.
     */
    constructor(rules, coeffs = [], biases = []) {
        this._inRules = [];
        this._outRules = new Map();  // key -> rule
        this._rulesThatCouldEmit = new Map();  // type -> [rules]
        this._rulesThatCouldAdd = new Map();  // type -> [rules]
        // Private to the framework:
        this._coeffs = new Map(coeffs);  // rule name => coefficient
        this.biases = new Map(biases);  // type name => bias

        // Separate rules into out ones and in ones, and sock them away. We do
        // this here so mistakes raise errors early.
        for (let rule of rules) {
            if (rule instanceof InwardRule) {
                this._inRules.push(rule);

                // Keep track of what inward rules can emit or add:
                // TODO: Combine these hashes for space efficiency:
                const emittedTypes = rule.typesItCouldEmit();
                for (let type of emittedTypes) {
                    setDefault(this._rulesThatCouldEmit, type, () => []).push(rule);
                }
                for (let type of rule.typesItCouldAdd()) {
                    setDefault(this._rulesThatCouldAdd, type, () => []).push(rule);
                }
            } else if (rule instanceof OutwardRule) {
                this._outRules.set(rule.key(), rule);
            } else {
                throw new Error(`This element of ruleset()'s first param wasn't a rule: ${rule}`);
            }
        }
    }

    /**
     * Commit this ruleset to running against a specific DOM tree or subtree.
     *
     * When run against a subtree, the root of the subtree is not considered as
     * a possible match.
     *
     * This doesn't actually modify the Ruleset but rather returns a fresh
     * :class:`BoundRuleset`, which contains caches and other stateful, per-DOM
     * bric-a-brac.
     */
    against(doc) {
        return new BoundRuleset(doc,
                                this._inRules,
                                this._outRules,
                                this._rulesThatCouldEmit,
                                this._rulesThatCouldAdd,
                                this._coeffs,
                                this.biases);
    }

    /**
     * Return all the rules (both inward and outward) that make up this ruleset.
     *
     * From this, you can construct another ruleset like this one but with your
     * own rules added.
     */
    rules() {
        return Array.from([...this._inRules, ...this._outRules.values()]);
    }
}

/**
 * A ruleset that is earmarked to analyze a certain DOM
 *
 * Carries a cache of rule results on that DOM. Typically comes from
 * :meth:`~Ruleset.against`.
 */
class BoundRuleset {
    /**
     * @arg inRules {Array} Non-out() rules
     * @arg outRules {Map} Output key -> out() rule
     */
    constructor(doc, inRules, outRules, rulesThatCouldEmit, rulesThatCouldAdd, coeffs, biases) {
        this.doc = doc;
        this._inRules = inRules;
        this._outRules = outRules;
        this._rulesThatCouldEmit = rulesThatCouldEmit;
        this._rulesThatCouldAdd = rulesThatCouldAdd;
        this._coeffs = coeffs;

        // Private, for the use of only helper classes:
        this.biases = biases;
        this._clearCaches();
        this.elementCache = new WeakMap();  // DOM element => fnode about it
        this.doneRules = new Set();  // InwardRules that have been executed. OutwardRules can be executed more than once because they don't change any fnodes and are thus idempotent.
    }

    /**
     * Change my coefficients and biases after construction.
     *
     * @arg coeffs See the :class:`Ruleset` constructor.
     * @arg biases See the :class:`Ruleset` constructor.
     */
    setCoeffsAndBiases(coeffs, biases = []) {
        // Destructuring assignment doesn't make it through rollup properly
        // (https://github.com/rollup/rollup-plugin-commonjs/issues/358):
        this._coeffs = new Map(coeffs);
        this.biases = new Map(biases);
        this._clearCaches();
    }

    /**
     * Clear the typeCache and maxCache, usually in the wake of changing
     * ``this._coeffs``, because both of thise depend on weighted scores.
     */
    _clearCaches() {
        this.maxCache = new Map();  // type => Array of max fnode (or fnodes, if tied) of this type
        this.typeCache = new Map();  // type => Set of all fnodes of this type found so far. (The dependency resolution during execution ensures that individual types will be comprehensive just in time.)
    }

    /**
     * Return an array of zero or more fnodes.
     * @arg thing {string|Lhs|Node} Can be
     *
     *       (1) A string which matches up with an "out" rule in the ruleset.
     *           If the out rule uses through(), the results of through's
     *           callback (which might not be fnodes) will be returned.
     *       (2) An arbitrary LHS which we calculate and return the results of.
     *       (3) A DOM node, for which we will return the corresponding fnode.
     *
     *     Results are cached for cases (1) and (3).
     */
    get(thing) {
        if (typeof thing === 'string') {
            if (this._outRules.has(thing)) {
                return Array.from(this._execute(this._outRules.get(thing)));
            } else {
                throw new Error(`There is no out() rule with key "${thing}".`);
            }
        } else if (isDomElement(thing)) {
            // Return the fnode and let it run type(foo) on demand, as people
            // ask it things like scoreFor(foo).
            return this.fnodeForElement(thing);
        } else if (thing.asLhs !== undefined) {
            // Make a temporary out rule, and run it. This may add things to
            // the ruleset's cache, but that's fine: it doesn't change any
            // future results; it just might make them faster. For example, if
            // you ask for .get(type('smoo')) twice, the second time will be a
            // cache hit.
            const outRule = rule(thing, out(Symbol('outKey')));
            return Array.from(this._execute(outRule));
        } else {
            throw new Error('ruleset.get() expects a string, an expression like on the left-hand side of a rule, or a DOM node.');
        }
    }

    /**
     * Return the weighted sum of the per-rule, per-type scores from a fnode.
     *
     * @arg mapOfScores a Map of rule name to the [0, 1] score it computed for
     *      the type in question
     */
    weightedScore(mapOfScores) {
        let total = 0;
        for (const [name, score] of mapOfScores) {
            total += score * getDefault(this._coeffs, name, () => 1);
        }
        return total;
    }

    // Provide an opaque context object to be made available to all ranker
    // functions.
    // context (object) {
    //     self.context = object;
    // }

    // -------- Methods below this point are private to the framework. --------

    /**
     * Return all the thus-far-unexecuted rules that will have to run to run
     * the requested rule, in the form of Map(prereq: [rulesItIsNeededBy]).
     */
    _prerequisitesTo(rule, undonePrereqs = new Map()) {
        for (let prereq of rule.prerequisites(this)) {
            if (!this.doneRules.has(prereq)) {
                // prereq is not already run. (If it were, we wouldn't care
                // about adding it to the graph.)
                const alreadyAdded = undonePrereqs.has(prereq);
                setDefault(undonePrereqs, prereq, () => []).push(rule);

                // alreadyAdded means we've already computed the prereqs of
                // this prereq and added them to undonePrereqs. So, now
                // that we've hooked up the rule to this prereq in the
                // graph, we can stop. But, if we haven't, then...
                if (!alreadyAdded) {
                    this._prerequisitesTo(prereq, undonePrereqs);
                }
            }
        }
        return undonePrereqs;
    }

    /**
     * Run the given rule (and its dependencies, in the proper order), and
     * return its results.
     *
     * The caller is responsible for ensuring that _execute() is not called
     * more than once for a given InwardRule, lest non-idempotent
     * transformations, like score contributions, be applied to fnodes more
     * than once.
     *
     * The basic idea is to sort rules in topological order (according to input
     * and output types) and then run them. On top of that, we do some
     * optimizations. We keep a cache of results by type (whether partial or
     * comprehensive--either way, the topology ensures that any
     * non-comprehensive typeCache entry is made comprehensive before another
     * rule needs it). And we prune our search for prerequisite rules at the
     * first encountered already-executed rule.
     */
    _execute(rule) {
        const prereqs = this._prerequisitesTo(rule);
        let sorted;
        try {
            sorted = [rule].concat(toposort(prereqs.keys(),
                                            prereq => prereqs.get(prereq)));
        } catch (exc) {
            if (exc instanceof CycleError) {
                throw new CycleError('There is a cyclic dependency in the ruleset.');
            } else {
                throw exc;
            }
        }
        let fnodes;
        for (let eachRule of reversed(sorted)) {
            // Sock each set of results away in this.typeCache:
            fnodes = eachRule.results(this);
        }
        return Array.from(fnodes);
    }

    /** @return {Rule[]} */
    inwardRulesThatCouldEmit(type) {
        return getDefault(this._rulesThatCouldEmit, type, () => []);
    }

    /** @return {Rule[]} */
    inwardRulesThatCouldAdd(type) {
        return getDefault(this._rulesThatCouldAdd, type, () => []);
    }

    /**
     * @return the Fathom node that describes the given DOM element. This does
     *     not trigger any execution, so the result may be incomplete.
     */
    fnodeForElement(element) {
        return setDefault(this.elementCache,
                          element,
                          () => new Fnode(element, this));
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const version = '3.7.3';

export { and, atMost, clusters$1 as clusters, dom, element, exceptions, nearest, note, out, props, rule, ruleset, score, type, typeIn, utilsForFrontend as utils, version };
