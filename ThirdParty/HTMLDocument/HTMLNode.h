/*###################################################################################
 #                                                                                  #
 #     HTMLNode.h                                                                   #
 #                                                                                  #
 #     Copyright © 2014 by Stefan Klieme                                            #
 #                                                                                  #
 #     Objective-C wrapper for HTML parser of libxml2                               #
 #                                                                                  #
 #     Version 1.7 - 20. Sep 2014                                                   #
 #                                                                                  #
 #     usage:     add libxml2.dylib to frameworks                                   #
 #                add $SDKROOT/usr/include/libxml2 to target -> Header Search Paths #
 #                add -lxml2 to target -> other linker flags                        #
 #                                                                                  #
 #                                                                                  #
 ####################################################################################
 #                                                                                  #
 # Permission is hereby granted, free of charge, to any person obtaining a copy of  #
 # this software and associated documentation files (the "Software"), to deal       #
 # in the Software without restriction, including without limitation the rights     #
 # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies #
 # of the Software, and to permit persons to whom the Software is furnished to do   #
 # so, subject to the following conditions:                                         #
 # The above copyright notice and this permission notice shall be included in       #
 # all copies or substantial portions of the Software.                              #
 # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR       #
 # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,         #
 # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE      #
 # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,#
 # WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR     #
 # IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.    #
 #                                                                                  #
 ##################################################################################*/

#import <Foundation/Foundation.h>
#import <libxml/tree.h>
#import <libxml/HTMLtree.h>

#define kClassKey @"class"
#define kIDKey @"id"

// ARCMacros by John Blanco
// added a macro for computed readonly properties which return always autoreleased objects

#if __has_feature(objc_arc)
    #define SAFE_ARC_PROP_RETAIN strong
    #define SAFE_ARC_READONLY_OBJ_PROP unsafe_unretained, readonly 
    #define SAFE_ARC_RELEASE(x)
    #define SAFE_ARC_AUTORELEASE(x) (x)
    #define SAFE_ARC_SUPER_DEALLOC()
#else
    #define SAFE_ARC_PROP_RETAIN retain
    #define SAFE_ARC_READONLY_OBJ_PROP readonly
    #define SAFE_ARC_RELEASE(x) ([(x) release])
    #define SAFE_ARC_AUTORELEASE(x) ([(x) autorelease])
    #define SAFE_ARC_SUPER_DEALLOC() ([super dealloc])
#endif

#if __has_feature(objc_instancetype)
    #define INSTANCETYPE_OR_ID instancetype
#else
    #define INSTANCETYPE_OR_ID id
#endif

@interface HTMLNode : NSObject {
    NSError *xpathError;
	xmlNode * xmlNode_;
}

/*! An XPath error*/
@property (SAFE_ARC_PROP_RETAIN)  NSError *xpathError;

#pragma mark - init methods
#pragma mark class
// Returns a HTMLNode object initialized with a xml node pointer of xmllib

/*! Returns an HTMLNode object with a specified xmlNode pointer.
 * \param xmlNode The xmlNode pointer for the created node object
 * \returns An HTMLNode object
 */
+ (HTMLNode *)nodeWithXMLNode:(xmlNode *)xmlNode; // convenience initializer

#pragma mark instance
/*! Initializes and returns a newly allocated HTMLNode object with a specified xmlNode pointer.
 * \param xmlNode The xmlNode pointer for the created node object
 * \returns An initizlized HTMLNode object or nil if the object couldn't be created
 */
- (INSTANCETYPE_OR_ID)initWithXMLNode:(xmlNode *)xmlNode;

#pragma mark - navigation
// Node navigation relative to current node (self)

/*! The parent node
 * \returns The parent node or nil
 */
@property (SAFE_ARC_READONLY_OBJ_PROP) HTMLNode *parent;

/*! The next sibling node
 * \returns The next sibling node or nil
 */
@property (SAFE_ARC_READONLY_OBJ_PROP) HTMLNode *nextSibling;

/*! The previous sibling node
 * \returns The previous sibling or nil
 */
@property (SAFE_ARC_READONLY_OBJ_PROP) HTMLNode *previousSibling;

/*! The first child node
 * \returns The first child or nil
 */
@property (SAFE_ARC_READONLY_OBJ_PROP) HTMLNode *firstChild;

/*! The last child node
 * \returns The last child or nil
 */
@property (SAFE_ARC_READONLY_OBJ_PROP) HTMLNode *lastChild;

/*! The first level of children
 * \returns The children array or an empty array
 */
@property (SAFE_ARC_READONLY_OBJ_PROP) NSArray *children;

/*! The number of children*/
@property (readonly) NSUInteger childCount;

/*! The child node at specified index
 * \param index The specified index
 * \returns The child node or nil if the index is invalid
 */
- (HTMLNode *)childAtIndex:(NSUInteger)index;

#pragma mark - attributes and values of current node (self)

/*! The attribute value of a node matching a given name
 * \param attributeName A name of an attribute
 * \returns The attribute value or nil if the attribute could not be found
 */
- (NSString *)attributeForName:(NSString *)attributeName;

/*! All attributes and values as dictionary
 * \returns a dictionary which could be empty if there are no attributes. Returns nil if the node is nil or is document node
 */
@property (SAFE_ARC_READONLY_OBJ_PROP) NSDictionary *attributes;

/*! The tag name
* \returns The tag name or nil if the node is document node
 */
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *tagName;

/*! The value for the class attribute*/
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *classValue;

/*! The value for the id attribute*/
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *IDValue;

/*! The value for the href attribute*/
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *hrefValue;

/*! The value for the src attribute*/
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *srcValue;

/*! The integer value*/
@property (readonly) NSInteger integerValue;

/*! The double value*/
@property (readonly) double doubleValue;

/*! Returns the double value of the string value for a specified locale identifier
 * \param identifier A locale identifier. The locale identifier must conform to http://www.iso.org/iso/country_names_and_code_elements and http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
 * \returns The double value of the string value depending on the parameter
*/
- (double )doubleValueForLocaleIdentifier:(NSString *)identifier;

/*! Returns the double value of the string value for a specified locale identifier considering a plus sign prefix
 * \param identifier A locale identifier. The locale identifier must conform to http://www.iso.org/iso/country_names_and_code_elements and http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
 * \param flag Considers the plus sign in the string if YES
 * \returns The double value of the string value depending on the parameters
 */
- (double )doubleValueForLocaleIdentifier:(NSString *)identifier consideringPlusSign:(BOOL)flag;

/*! Returns the double value of the text content for a specified locale identifier
 * \param identifier A locale identifier. The locale identifier must conform to http://www.iso.org/iso/country_names_and_code_elements and http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
 * \returns The double value of the text content depending on the parameter
 */
- (double )contentDoubleValueForLocaleIdentifier:(NSString *)identifier;

/*! Returns the double value of the text content for a specified locale identifier considering a plus sign prefix
 * \param identifier A locale identifier. The locale identifier must conform to http://www.iso.org/iso/country_names_and_code_elements and http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
 * \param flag Considers the plus sign in the string if YES
 * \returns The double value of the text content depending on the parameters
 */
- (double )contentDoubleValueForLocaleIdentifier:(NSString *)identifier consideringPlusSign:(BOOL)flag;

/*! Returns the date value of the string value for a specified date format and time zone
* \param dateFormat A date format string. The date format must conform to http://unicode.org/reports/tr35/tr35-10.html#Date_Format_Patterns
* \param timeZone A time zone
* \returns The date value of the string value depending on the parameters
*/
- (NSDate *)dateValueForFormat:(NSString *)dateFormat timeZone:(NSTimeZone *)timeZone;

/*! Returns the date value of the text content for a specified date format and time zone
 * \param dateFormat A date format string. The date format must conform to http://unicode.org/reports/tr35/tr35-10.html#Date_Format_Patterns
 * \param timeZone A time zone
 * \returns The date value of the text content depending on the parameters
 */
- (NSDate *)contentDateValueForFormat:(NSString *)dateFormat timeZone:(NSTimeZone *)timeZone;

/*! Returns the date value of the string value for a specified date format
 * \param dateFormat A date format string. The date format must conform to http://unicode.org/reports/tr35/tr35-10.html#Date_Format_Patterns
 * \returns The date value of the string value depending on the parameter
 */
- (NSDate *)dateValueForFormat:(NSString *)dateFormat;

/*! Returns the date value of the text content for a specified date format
 * \param dateFormat A date format string. The date format must conform to http://unicode.org/reports/tr35/tr35-10.html#Date_Format_Patterns
 * \returns The date value of the text content depending on the parameter
 */
- (NSDate *)contentDateValueForFormat:(NSString *)dateFormat;

/*! The raw string
 * \returns The raw string value or nil
 */

@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *rawStringValue;

/*! The string value of a node trimmed by whitespace and newline characters
 * \returns The string value or nil
 */
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *stringValue;

/*! The string value of a node trimmed by whitespace and newline characters and collapsing all multiple occurrences of whitespace and newline characters within the string into a single space
 * \returns The trimmed and collapsed string value or nil
 */
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *stringValueCollapsingWhitespace;

/*! The raw html text dump
 * \returns The raw html text dump or nil
 */
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *HTMLString;

/*! The array of all text content of children
 * \returns The text content array - each array item is trimmed by whitespace and newline characters - or an empty array
 */
@property (SAFE_ARC_READONLY_OBJ_PROP) NSArray *textContentOfChildren;

/*! The element type of the node*/
@property (readonly) xmlElementType elementType;

/*! Is the node an attribute node*/
@property (readonly) BOOL isAttributeNode;

/*! Is the node a document node*/
@property (readonly) BOOL isDocumentNode;

/*! Is the node an element node*/
@property (readonly) BOOL isElementNode;

/*! Is the node a text node*/
@property (readonly) BOOL isTextNode;

#pragma mark - contents of current node and its descendants (descendant-or-self)

/*! The raw text content of descendant-or-self
 * \returns The raw text content of the node and all its descendants or nil
 */
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *rawTextContent;

/*! The text content of descendant-or-self trimmed by whitespace and newline characters
 * \returns The trimmed text content of the node and all its descendants or nil
 */
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *textContent;

/*! The text content of descendant-or-self trimmed by whitespace and newline characters and collapsing all multiple occurrences of whitespace and newline characters within the string into a single space
 * \returns The text content of the node and all its descendants trimmed and collapsed or nil
 */
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *textContentCollapsingWhitespace;

/*! The text content of descendant-or-self in an array, each item trimmed by whitespace and newline characters
 * \returns An array of all text content of the node and its descendants - each array item is trimmed by whitespace and newline characters - or nil
 */
@property (SAFE_ARC_READONLY_OBJ_PROP) NSArray *textContentOfDescendants;

/*! The raw html text dump of descendant-or-self
 * \returns The raw html text dump of the node and all its descendants or nil
 */
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *HTMLContent;


#pragma mark - Query method declarations

// Note: In the category HTMLNode+XPath all appropriate query methods begin with node instead of descendant

/*! Returns the first descendant node with the specifed attribute name and value matching exactly
 * \param attributeName The name of the attribute
 * \param attributeValue The value of the attribute
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)descendantWithAttribute:(NSString *)attributeName valueMatches:(NSString *)attributeValue;

/*! Returns the first child node with the specifed attribute name and value matching exactly
 * \param attributeName The name of the attribute
 * \param attributeValue The value of the attribute
 * \returns The first found child node or nil if no node matches the parameters
 */
- (HTMLNode *)childWithAttribute:(NSString *)attributeName valueMatches:(NSString *)attributeValue;

/*! Returns the first sibling node with the specifed attribute name and value matching exactly
 * \param attributeName The name of the attribute
 * \param attributeValue The value of the attribute
 * \returns The first found sibling node or nil if no node matches the parameters
 */
- (HTMLNode *)siblingWithAttribute:(NSString *)attributeName valueMatches:(NSString *)attributeValue;

/*! Returns the first descendant node with the specifed attribute name and the value contains the specified attribute value
 * \param attributeName The name of the attribute
 * \param attributeValue The partial string of the attribute value
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)descendantWithAttribute:(NSString *)attributeName valueContains:(NSString *)attributeValue;

/*! Returns the first child node with the specifed attribute name and the value contains the specified attribute value
 * \param attributeName The name of the attribute
 * \param attributeValue The partial string of the attribute value
 * \returns The first found child node or nil if no node matches the parameters
 */
- (HTMLNode *)childWithAttribute:(NSString *)attributeName valueContains:(NSString *)attributeValue;

/*! Returns the first sibling node with the specifed attribute name and the value contains the specified attribute value
 * \param attributeName The name of the attribute
 * \param attributeValue The partial string of the attribute value
 * \returns The first found sibling node or nil if no node matches the parameters
 */
- (HTMLNode *)siblingWithAttribute:(NSString *)attributeName valueContains:(NSString *)attributeValue;

/*! Returns the first descendant node with the specifed attribute name and the value contains the specified attribute value
 * \param attributeName The name of the attribute
 * \param attributeValue The partial string of the attribute value
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)descendantWithAttribute:(NSString *)attributeName valueBeginsWith:(NSString *)attributeValue;

/*! Returns the first child node with the specifed attribute name and the value begins with the specified attribute value
 * \param attributeName The name of the attribute
 * \param attributeValue The partial string of the attribute value
 * \returns The first found child node or nil if no node matches the parameters
 */
- (HTMLNode *)childWithAttribute:(NSString *)attributeName valueBeginsWith:(NSString *)attributeValue;

/*! Returns the first sibling node with the specifed attribute name and the value begins with the specified attribute value
 * \param attributeName The name of the attribute
 * \param attributeValue The partial string of the attribute value
 * \returns The first found sibling node or nil if no node matches the parameters
 */
- (HTMLNode *)siblingWithAttribute:(NSString *)attributeName valueBeginsWith:(NSString *)attributeValue;

/*! Returns the first descendant node with the specifed attribute name and the value ends with the specified attribute value
 * \param attributeName The name of the attribute
 * \param attributeValue The partial string of the attribute value
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)descendantWithAttribute:(NSString *)attributeName valueEndsWith:(NSString *)attributeValue;

/*! Returns the first child node with the specifed attribute name and the value ends with the specified attribute value
 * \param attributeName The name of the attribute
 * \param attributeValue The partial string of the attribute value
 * \returns The first found child node or nil if no node matches the parameters
 */
- (HTMLNode *)childWithAttribute:(NSString *)attributeName valueEndsWith:(NSString *)attributeValue;

/*! Returns the first sibling node with the specifed attribute name and the value ends with the specified attribute value
 * \param attributeName The name of the attribute
 * \param attributeValue The partial string of the attribute value
 * \returns The first found sibling node or nil if no node matches the parameters
 */
- (HTMLNode *)siblingWithAttribute:(NSString *)attributeName valueEndsWith:(NSString *)attributeValue;


/*! Returns all descendant nodes with the specifed attribute name and value matching exactly
 * \param attributeName The name of the attribute
 * \param attributeValue The value of the attribute
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)descendantsWithAttribute:(NSString *)attributeName valueMatches:(NSString *)attributeValue;

/*! Returns all child nodes with the specifed attribute name and value matching exactly
 * \param attributeName The name of the attribute
 * \param attributeValue The value of the attribute
 * \returns The array of all found child nodes or an empty array
 */
- (NSArray *)childrenWithAttribute:(NSString *)attributeName valueMatches:(NSString *)attributeValue;

/*! Returns all sibling nodes with the specifed attribute name and value matching exactly
 * \param attributeName The name of the attribute
 * \param attributeValue The value of the attribute
 * \returns The array of all found sibling nodes or an empty array
 */
- (NSArray *)siblingsWithAttribute:(NSString *)attributeName valueMatches:(NSString *)attributeValue;

/*! Returns all descendant nodes with the specifed attribute name and the value contains the specified attribute value
 * \param attributeName The name of the attribute
 * \param attributeValue The partial string of the attribute value
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)descendantsWithAttribute:(NSString *)attributeName valueContains:(NSString *)attributeValue;

/*! Returns all child nodes with the specifed attribute name and the value contains the specified attribute value
 * \param attributeName The name of the attribute
 * \param attributeValue The partial string of the attribute value
 * \returns The array of all found child nodes or an empty array
 */
- (NSArray *)childrenWithAttribute:(NSString *)attributeName valueContains:(NSString *)attributeValue;

/*! Returns all sibling nodes with the specifed attribute name and the value contains the specified attribute value
 * \param attributeName The name of the attribute
 * \param attributeValue The partial string of the attribute value
 * \returns The array of all found sibling nodes or an empty array
 */
- (NSArray *)siblingsWithAttribute:(NSString *)attributeName valueContains:(NSString *)attributeValue;

/*! Returns all descendant nodes with the specifed attribute name and the value begins with the specified attribute value
 * \param attributeName The name of the attribute
 * \param attributeValue The partial string of the attribute value
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)descendantsWithAttribute:(NSString *)attributeName valueBeginsWith:(NSString *)attributeValue;

/*! Returns all child nodes with the specifed attribute name and the value begins with the specified attribute value
 * \param attributeName The name of the attribute
 * \param attributeValue The partial string of the attribute value
 * \returns The array of all found child nodes or an empty array
 */
- (NSArray *)childrenWithAttribute:(NSString *)attributeName valueBeginsWith:(NSString *)attributeValue;

/*! Returns all sibling nodes with the specifed attribute name and the value begins with the specified attribute value
 * \param attributeName The name of the attribute
 * \param attributeValue The partial string of the attribute value
 * \returns The array of all found sibling nodes or an empty array
 */
- (NSArray *)siblingsWithAttribute:(NSString *)attributeName valueBeginsWith:(NSString *)attributeValue;

/*! Returns all descendant nodes with the specifed attribute name and the value ends with the specified attribute value
 * \param attributeName The name of the attribute
 * \param attributeValue The partial string of the attribute value
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)descendantsWithAttribute:(NSString *)attributeName valueEndsWith:(NSString *)attributeValue;

/*! Returns all child nodes with the specifed attribute name and the value ends with the specified attribute value
 * \param attributeName The name of the attribute
 * \param attributeValue The partial string of the attribute value
 * \returns The array of all found child nodes or an empty array
 */
- (NSArray *)childrenWithAttribute:(NSString *)attributeName valueEndsWith:(NSString *)attributeValue;

/*! Returns all sibling nodes with the specifed attribute name and the value ends with the specified attribute value
 * \param attributeName The name of the attribute
 * \param attributeValue The partial string of the attribute value
 * \returns The array of all found sibling nodes or an empty array
 */
- (NSArray *)siblingsWithAttribute:(NSString *)attributeName valueEndsWith:(NSString *)attributeValue;

/*! Returns the first descendant node with the specifed attribute name
 * \param attributeName The name of the attribute
 * \returns The first found descendant node or nil
 */
- (HTMLNode *)descendantWithAttribute:(NSString *)attributeName;

/*! Returns the first child node with the specifed attribute name
 * \param attributeName The name of the attribute
 * \returns The first found child node or nil
 */
- (HTMLNode *)childWithAttribute:(NSString *)attributeName;

/*! Returns the first sibling node with the specifed attribute name
 * \param attributeName The name of the attribute
 * \returns The first found sibling node or nil
 */
- (HTMLNode *)siblingWithAttribute:(NSString *)attributeName;

/*! Returns all descendant nodes with the specifed attribute name
 * \param attributeName The name of the attribute
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)descendantsWithAttribute:(NSString *)attributeName;

/*! Returns all child nodes with the specifed attribute name
* \param attributeName The name of the attribute
* \returns The array of all found child nodes or an empty array
*/
- (NSArray *)childrenWithAttribute:(NSString *)attributeName;

/*! Returns all sibling nodes with the specifed attribute name
 * \param attributeName The name of the attribute
 * \returns The array of all found sibling nodes or an empty array
 */
- (NSArray *)siblingsWithAttribute:(NSString *)attributeName;

/*! Returns the first descendant node with the specifed class value
 * \param classValue The name of the class
 * \returns The first found descendant node or nil
 */
- (HTMLNode *)descendantWithClass:(NSString *)classValue;

/*! Returns the first child node with the specifed class value
 * \param classValue The name of the class
 * \returns The first found child node or nil
 */
- (HTMLNode *)childWithClass:(NSString *)classValue;

/*! Returns the first sibling node with the specifed class value
 * \param classValue The name of the class
 * \returns The first found sibling node or nil
 */
- (HTMLNode *)siblingWithClass:(NSString *)classValue;

/*! Returns all descendant nodes with the specifed class value
 * \param classValue The name of the class
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)descendantsWithClass:(NSString *)classValue;

/*! Returns all child nodes with the specifed class value
 * \param classValue The name of the class
 * \returns The array of all found child nodes or an empty array
 */
- (NSArray *)childrenWithClass:(NSString *)classValue;

/*! Returns all sibling nodes with the specifed class value
 * \param classValue The name of the class
 * \returns The array of all found sibling nodes or an empty array
 */
- (NSArray *)siblingsWithClass:(NSString *)classValue;

/*! Returns the first descendant node with the specifed id value
 * \param classValue The name of the class
 * \returns The first found descendant node or nil
 */
- (HTMLNode *)descendantWithID:(NSString *)IDValue;

/*! Returns the first child node with the specifed id value
 * \param classValue The name of the class
 * \returns The first found child node or nil
 */
- (HTMLNode *)childWithID:(NSString *)IDValue;

/*! Returns the first sibling node with the specifed id value
 * \param classValue The name of the class
 * \returns The first found sibling node or nil
 */
- (HTMLNode *)siblingWithID:(NSString *)IDValue;

/*! Returns the first descendant node with the specifed tag name and string value matching exactly
 * \param tagName The name of the tag
 * \param value The string value of the tag
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)descendantOfTag:(NSString *)tagName valueMatches:(NSString *)value;

/*! Returns the first child node with the specifed tag name and string value matching exactly
 * \param tagName The name of the tag
 * \param value The string value of the tag
 * \returns The first found child node or nil if no node matches the parameters
 */
- (HTMLNode *)childOfTag:(NSString *)tagName valueMatches:(NSString *)value;

/*! Returns the first sibling node with the specifed tag name and string value matching exactly
 * \param tagName The name of the tag
 * \param value The string value of the tag
 * \returns The first found sibling node or nil if no node matches the parameters
 */
- (HTMLNode *)siblingOfTag:(NSString *)tagName valueMatches:(NSString *)value;

/*! Returns all descendant nodes with the specifed tag name and string value matching exactly
* \param tagName The name of the tag
* \param value The string value of the tag
* \returns The array of all found descendant nodes or an empty array
*/
- (NSArray *)descendantsOfTag:(NSString *)tagName valueMatches:(NSString *)value;

/*! Returns all child nodes with the specifed tag name and string value matching exactly
* \param tagName The name of the tag
* \param value The string value of the tag
* \returns The array of all found child nodes or an empty array
*/
- (NSArray *)childrenOfTag:(NSString *)tagName valueMatches:(NSString *)value;

/*! Returns all sibling nodes with the specifed tag name and string value matching exactly
 * \param tagName The name of the tag
 * \param value The string value of the tag
 * \returns The array of all found sibling nodes or an empty array
 */
- (NSArray *)siblingsOfTag:(NSString *)tagName valueMatches:(NSString *)value;

/*! Returns the first descendant node with the specifed attribute name and the string value contains the specified value
 * \param tagName The name of the attribute
 * \param value The partial string of the attribute value
 * \returns The first found descendant node or nil if no node matches the parameters
 */
- (HTMLNode *)descendantOfTag:(NSString *)tagName valueContains:(NSString *)value;

/*! Returns the child node with the specifed attribute name and the string value contains the specified value
 * \param tagName The name of the attribute
 * \param value The partial string of the attribute value
 * \returns The first found child node or nil if no node matches the parameters
 */
- (HTMLNode *)childOfTag:(NSString *)tagName valueContains:(NSString *)value;

/*! Returns the sibling node with the specifed attribute name and the string value contains the specified value
 * \param tagName The name of the attribute
 * \param value The partial string of the attribute value
 * \returns The first found sibling node or nil if no node matches the parameters
 */
- (HTMLNode *)siblingOfTag:(NSString *)tagName valueContains:(NSString *)value;

/*! Returns all descendant nodes with the specifed attribute name and the string value contains the specified value
 * \param tagName The name of the attribute
 * \param value The partial string of the attribute value
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)descendantsOfTag:(NSString *)tagName valueContains:(NSString *)value;

/*! Returns all child nodes with the specifed attribute name and the string value contains the specified value
 * \param tagName The name of the attribute
 * \param value The partial string of the attribute value
 * \returns The array of all found child nodes or an empty array
 */
- (NSArray *)childrenOfTag:(NSString *)tagName valueContains:(NSString *)value;

/*! Returns all sibling nodes with the specifed attribute name and the string value contains the specified value
 * \param tagName The name of the attribute
 * \param value The partial string of the attribute value
 * \returns The array of all found sibling nodes or an empty array
 */
- (NSArray *)siblingsOfTag:(NSString *)tagName valueContains:(NSString *)value;

/*! Returns the first descendant node with the specifed tag name
 * \param tagName The name of the tag
 * \returns The first found descendant node or nil
 */
- (HTMLNode *)descendantOfTag:(NSString *)tagName;

/*! Returns the first child node with the specifed tag name
 * \param tagName The name of the tag
 * \returns The first found child node or nil
 */
- (HTMLNode *)childOfTag:(NSString *)tagName;

/*! Returns the first sibling node with the specifed tag name
 * \param tagName The name of the tag
 * \returns The first found sibling node or nil
 */
- (HTMLNode *)siblingOfTag:(NSString *)tagName;

/*! Returns all descendant nodes with the specifed tag name
 * \param tagName The name of the tag
 * \returns The array of all found descendant nodes or an empty array
 */
- (NSArray *)descendantsOfTag:(NSString *)tagName;

/*! Returns all child nodes with the specifed tag name
 * \param tagName The name of the tag
 * \returns The array of all found child nodes or an empty array
 */

- (NSArray *)childrenOfTag:(NSString *)tagName;

/*! Returns all sibling nodes with the specifed tag name
 * \param tagName The name of the tag
 * \returns The array of all found sibling nodes or an empty array
 */
- (NSArray *)siblingsOfTag:(NSString *)tagName;


@end
