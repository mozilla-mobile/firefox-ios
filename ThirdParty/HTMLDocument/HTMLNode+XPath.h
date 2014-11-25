/*###################################################################################
#                                                                                   #
#     HTMLNode+XPath.h                                                              #
#     Category of HTMLNode for XPath support                                        #
#                                                                                   #
#     Copyright © 2014 by Stefan Klieme                                             #
#                                                                                   #
#     Objective-C wrapper for HTML parser of libxml2                                #
#                                                                                   #
#	  Version 1.7 - 20. Sep 2014                                                    #
#                                                                                   #
#     usage:     add #import HTMLNode+XPath.h                                       #
#                                                                                   #
#                                                                                   #
#####################################################################################
#                                                                                   #
# Permission is hereby granted, free of charge, to any person obtaining a copy of   #
# this software and associated documentation files (the "Software"), to deal        #
# in the Software without restriction, including without limitation the rights      #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies  #
# of the Software, and to permit persons to whom the Software is furnished to do    #
# so, subject to the following conditions:                                          #
# The above copyright notice and this permission notice shall be included in        #
# all copies or substantial portions of the Software.                               #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR        #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,          #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE       #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, #
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR      #
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.     #
#                                                                                   #
###################################################################################*/

#import "HTMLNode.h"

#if !defined(__clang__) || __clang_major__ < 3

#ifndef __bridge_retained
#define __bridge_retained
#endif

#ifndef __bridge_transfer
#define __bridge_transfer
#endif

#endif


@interface HTMLNode (XPath)

// Xpath query methods


/*! Returns the first descendant node for a XPath query
 * \param query The XPath query string
 * \param error An error object that, on return, identifies any Xpath errors.
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)nodeForXPath:(NSString *)query error:(NSError **)error;

/*! Returns the first descendant node for a XPath query
 * \param query The XPath query string
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)nodeForXPath:(NSString *)query;

/*! Returns all descendant nodes for a XPath query
 * \param query The XPath query string
 * \param error An error object that, on return, identifies any Xpath errors.
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)nodesForXPath:(NSString *)query error:(NSError **)error;

/*! Returns all descendant nodes for a XPath query
 * \param query The XPath query string
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)nodesForXPath:(NSString *)query;

// Note: In the HTMLNode main class all appropriate query methods begin with descendant instead of node 

/*! Returns the first descendant node for a specified tag name
 * \param tagName The tag name
 * \param error An error object that, on return, identifies any Xpath errors.
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)nodeOfTag:(NSString *)tagName error:(NSError **)error;

/*! Returns the first descendant node for a specified tag name
 * \param tagName The tag name
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)nodeOfTag:(NSString *)tagName;

/*! Returns all descendant nodes for a specified tag name
 * \param tagName The tag name
 * \param error An error object that, on return, identifies any Xpath errors.
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)nodesOfTag:(NSString *)tagName error:(NSError **)error;

/*! Returns all descendant nodes for a specified tag name
 * \param tagName The tag name
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)nodesOfTag:(NSString *)tagName;

/*! Returns the first descendant node for a matching tag name and matching attribute name
 * \param tagName The tag name
 * \param attributeName The attribute name
 * \param error An error object that, on return, identifies any Xpath errors.
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)nodeOfTag:(NSString *)tagName withAttribute:(NSString *)attributeName error:(NSError **)error;

/*! Returns the first descendant node for a matching tag name and matching attribute name
 * \param tagName The tag name
 * \param attributeName The attribute name
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)nodeOfTag:(NSString *)tagName withAttribute:(NSString *)attributeName;

/*! Returns all descendant nodes for a matching tag name and matching attribute name
 * \param tagName The tag name
 * \param attributeName The attribute name
 * \param error An error object that, on return, identifies any Xpath errors.
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)nodesOfTag:(NSString *)tagName withAttribute:(NSString *)attributeName error:(NSError **)error;

/*! Returns all descendant nodes for a matching tag name and matching attribute name
 * \param tagName The tag name
 * \param attributeName The attribute name
 * \param error An error object that, on return, identifies any Xpath errors.
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)nodesOfTag:(NSString *)tagName withAttribute:(NSString *)attributeName;

/*! Returns the first descendant node for a specified attribute name
 * \param attributeName The attribute name
 * \param error An error object that, on return, identifies any Xpath errors.
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName error:(NSError **)error;

/*! Returns the first descendant node for a specified attribute name
 * \param attributeName The attribute name
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName;

/*! Returns all descendant nodes for a specified attribute name
 * \param attributeName The attribute name
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)nodesWithAttribute:(NSString *)attributeName error:(NSError **)error;

/*! Returns all descendant nodes for a specified attribute name
 * \param attributeName The attribute name
 * \param error An error object that, on return, identifies any Xpath errors.
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)nodesWithAttribute:(NSString *)attributeName;

/*! Returns the first descendant node for a matching attribute name and matching attribute value
 * \param attributeName The attribute name
 * \param value The attribute value
 * \param error An error object that, on return, identifies any Xpath errors.
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueMatches:(NSString *)value error:(NSError **)error;

/*! Returns the first descendant node for a matching attribute name and matching attribute value
 * \param attributeName The attribute name
 * \param value The attribute value
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueMatches:(NSString *)value;

/*! Returns all descendant nodes for a matching attribute name and matching attribute value
 * \param attributeName The attribute name
 * \param value The attribute value
 * \param error An error object that, on return, identifies any Xpath errors.
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueMatches:(NSString *)value error:(NSError **)error;

/*! Returns all descendant nodes for a matching attribute name and matching attribute value
 * \param attributeName The attribute name
 * \param value The attribute value
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueMatches:(NSString *)value;

/*! Returns the first descendant node for a matching attribute name and beginning of the attribute value
 * \param attributeName The attribute name
 * \param value The attribute value
 * \param error An error object that, on return, identifies any Xpath errors.
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueBeginsWith:(NSString *)value error:(NSError **)error;

/*! Returns the first descendant node for a matching attribute name and beginning of the attribute value
 * \param attributeName The attribute name
 * \param value The attribute value
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueBeginsWith:(NSString *)value;

/*! Returns all descendant nodes for a matching attribute name and beginning of the attribute value
 * \param attributeName The attribute name
 * \param value The attribute value
 * \param error An error object that, on return, identifies any Xpath errors.
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueBeginsWith:(NSString *)value error:(NSError **)error;

/*! Returns all descendant nodes for a matching attribute name and beginning of the attribute value
* \param attributeName The attribute name
* \param value The attribute value
* \returns The array of all found descendant nodes or an empty array
*/
- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueBeginsWith:(NSString *)value;

/*! Returns the first descendant node for a matching attribute name and ending of the attribute value
 * \param attributeName The attribute name
 * \param value The attribute value
 * \param error An error object that, on return, identifies any Xpath errors.
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueEndsWith:(NSString *)value error:(NSError **)error;

/*! Returns the first descendant node for a matching attribute name and ending of the attribute value
 * \param attributeName The attribute name
 * \param value The attribute value
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueEndsWith:(NSString *)value;

/*! Returns all descendant nodes for a matching attribute name and ending of the attribute value
 * \param attributeName The attribute name
 * \param value The attribute value
 * \param error An error object that, on return, identifies any Xpath errors.
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueEndsWith:(NSString *)value error:(NSError **)error;

/*! Returns all descendant nodes for a matching attribute name and ending of the attribute value
 * \param attributeName The attribute name
 * \param value The attribute value
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueEndsWith:(NSString *)value;

/*! Returns the first descendant node for a matching attribute name and containing the attribute value
 * \param attributeName The attribute name
 * \param value The attribute value
 * \param error An error object that, on return, identifies any Xpath errors.
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueContains:(NSString *)value error:(NSError **)error;

/*! Returns the first descendant node for a matching attribute name and containing the attribute value
 * \param attributeName The attribute name
 * \param value The attribute value
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueContains:(NSString *)value;

/*! Returns all descendant nodes for a matching attribute name and containing the attribute value
 * \param attributeName The attribute name
 * \param value The attribute value
 * \param error An error object that, on return, identifies any Xpath errors.
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueContains:(NSString *)value error:(NSError **)error;

/*! Returns all descendant nodes for a matching attribute name and containing the attribute value
 * \param attributeName The attribute name
 * \param value The attribute value
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueContains:(NSString *)value;

/*! Returns the first descendant node for a specified class name
 * \param classValue The class name
 * \param error An error object that, on return, identifies any Xpath errors.
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)nodeWithClass:(NSString *)classValue error:(NSError **)error;

/*! Returns the first descendant node for a specified class name
 * \param classValue The class name
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)nodeWithClass:(NSString *)classValue;

/*! Returns all descendant nodes for a specified class name
 * \param classValue The class name
 * \param error An error object that, on return, identifies any Xpath errors.
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)nodesWithClass:(NSString *)classValue error:(NSError **)error;

/*! Returns all descendant nodes for a specified class name
 * \param classValue The class name
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)nodesWithClass:(NSString *)classValue;


// Compare two nodes w.r.t document order with XPath
/*! Returns a Boolean value that indicates whether the receiver is equal to another given object
 * \param node The node with which to compare the receiver
 * \returns YES if the receiver is equal to the node, otherwise NO. In effect returns NO if receiver is nil
 */
- (BOOL)isEqual:(HTMLNode *)node;


- (void)setErrorWithMessage:(NSString *)message andCode:(NSInteger)code;

@end
