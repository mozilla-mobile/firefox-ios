/*###################################################################################
 #                                                                                  #
 #     HTMLDocument.h                                                               #
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
#import <libxml/HTMLparser.h>
#import "HTMLNode.h"

@interface HTMLDocument : NSObject
{    
    htmlDocPtr  htmlDoc_;
    HTMLNode    *rootNode;
}

// convenience initializer methods
// default text encoding is UTF-8

/*! Returns an HTMLDocument object created from an NSData object with specified string encoding
 * \param data A data object with HTML content
 * \param encoding The string encoding for the HTML content
 * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
 * \returns An initialized HTMLDocument object, or nil if initialization fails because of parsing errors or other reasons
 */
+ (HTMLDocument *)documentWithData:(NSData *)data encoding:(NSStringEncoding )encoding error:(NSError **)error;

/*! Returns an HTMLDocument object created from an NSData object with assumed UTF-8 string encoding
 * \param data A data object with HTML content
 * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
 * \returns An initialized HTMLDocument object, or nil if initialization fails because of parsing errors or other reasons
 */
+ (HTMLDocument *)documentWithData:(NSData *)data error:(NSError **)error;

/*! Returns an HTMLDocument object created from the HTML contents of a URL-referenced source with specified string encoding
 * \param url An NSURL object specifying a URL source
 * \param encoding The string encoding for the HTML content
 * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
 * \returns An initialized HTMLDocument object, or nil if initialization fails because of parsing errors or other reasons
 */
+ (HTMLDocument *)documentWithContentsOfURL:(NSURL *)url encoding:(NSStringEncoding )encoding error:(NSError **)error;

/*! Returns an HTMLDocument object created from the HTML contents of a URL-referenced source with assumed UTF-8 string encoding
 * \param url An NSURL object specifying a URL source
 * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
 * \returns An initialized HTMLDocument object, or nil if initialization fails because of parsing errors or other reasons
 */
+ (HTMLDocument *)documentWithContentsOfURL:(NSURL *)url error:(NSError **)error;

/*! Returns an HTMLDocument object created from a string containing HTML markup text with specified string encoding
 * \param url An NSURL object specifying a URL source
 * \param encoding The string encoding for the HTML content
 * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
 * \returns An initialized HTMLDocument object, or nil if initialization fails because of parsing errors or other reasons
 */
+ (HTMLDocument *)documentWithHTMLString:(NSString *)string encoding:(NSStringEncoding )encoding error:(NSError **)error;

/*! Returns an HTMLDocument object created from a string containing HTML markup text with assumed UTF-8 string encoding
 * \param url An NSURL object specifying a URL source
 * \param encoding The string encoding for the HTML content
 * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
 * \returns An initialized HTMLDocument object, or nil if initialization fails because of parsing errors or other reasons
 */
+ (HTMLDocument *)documentWithHTMLString:(NSString *)string error:(NSError **)error;


/*! Initializes and returns an HTMLDocument object created from an NSData object with specified string encoding
 * \param data A data object with HTML or XML content
 * \param encoding The string encoding for the HTML or XML content
 * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
 * \returns An initialized HTMLDocument object, or nil if initialization fails because of parsing errors or other reasons
 */
- (INSTANCETYPE_OR_ID)initWithData:(NSData *)data encoding:(NSStringEncoding )encoding error:(NSError **)error; // designated initializer

/*! Initializes and returns an HTMLDocument object created from an NSData object with assumed UTF-8 string encoding
 * \param data A data object with HTML or XML content
 * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
 * \returns An initialized HTMLDocument object, or nil if initialization fails because of parsing errors or other reasons
 */
- (INSTANCETYPE_OR_ID)initWithData:(NSData *)data error:(NSError **)error;

/*! Initializes and returns an HTMLDocument object created from the HTML or XML contents of a URL-referenced source with specified string encoding
 * \param url An NSURL object specifying a URL source
 * \param encoding The string encoding for the HTML or XML content
 * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
 * \returns An initialized HTMLDocument object, or nil if initialization fails because of parsing errors or other reasons
 */
- (INSTANCETYPE_OR_ID)initWithContentsOfURL:(NSURL *)url encoding:(NSStringEncoding )encoding error:(NSError **)error;

/*! Initializes and returns an HTMLDocument object created from the HTML or XML contents of a URL-referenced source with assumed UTF-8 string encoding
 * \param url An NSURL object specifying a URL source
 * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
 * \returns An initialized HTMLDocument object, or nil if initialization fails because of parsing errors or other reasons
 */
- (INSTANCETYPE_OR_ID)initWithContentsOfURL:(NSURL *)url error:(NSError **)error;

/*! Initializes and returns an HTMLDocument object created from a string containing HTML or XML markup text with specified string encoding
 * \param url An NSURL object specifying a URL source
 * \param encoding The string encoding for the HTML or XML content
 * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
 * \returns An initialized HTMLDocument object, or nil if initialization fails because of parsing errors or other reasons
 */
- (INSTANCETYPE_OR_ID)initWithHTMLString:(NSString *)string encoding:(NSStringEncoding )encoding error:(NSError **)error;

/*! Initializes and returns an HTMLDocument object created from a string containing HTML or XML markup text with assumed UTF-8 string encoding
* \param url An NSURL object specifying a URL source
* \param encoding The string encoding for the HTML or XML content
* \param error An error object that, on return, identifies any parsing errors and warnings or connection problems.
* \returns An initialized HTMLDocument object, or nil if initialization fails because of parsing errors or other reasons
*/
- (INSTANCETYPE_OR_ID)initWithHTMLString:(NSString *)string error:(NSError **)error;


/*! The root node*/
@property (readonly) HTMLNode *rootNode;

/*! The head node*/
@property (SAFE_ARC_READONLY_OBJ_PROP) HTMLNode *head;

/*! The body node*/
@property (SAFE_ARC_READONLY_OBJ_PROP) HTMLNode *body;

/*! The value of the title tag in the head node*/
@property (SAFE_ARC_READONLY_OBJ_PROP) NSString *title;

@end



@interface XMLDocument : HTMLDocument
{
    xmlDocPtr  xmlDoc_;
}

/*! Returns an XMLDocument object created from an NSData object with specified string encoding
 * \param data A data object with XML content
 * \param encoding The string encoding for the XML content
 * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
 * \returns An initialized XMLDocument object, or nil if initialization fails because of parsing errors or other reasons
 */
+ (XMLDocument *)documentWithData:(NSData *)data encoding:(NSStringEncoding )encoding error:(NSError **)error;

/*! Returns an XMLDocument object created from an NSData object with assumed UTF-8 string encoding
 * \param data A data object with XML content
 * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
 * \returns An initialized XMLDocument object, or nil if initialization fails because of parsing errors or other reasons
 */
+ (XMLDocument *)documentWithData:(NSData *)data error:(NSError **)error;

/*! Returns an XMLDocument object created from the XML contents of a URL-referenced source with specified string encoding
 * \param url An NSURL object specifying a URL source
 * \param encoding The string encoding for the XML content
 * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
 * \returns An initialized XMLDocument object, or nil if initialization fails because of parsing errors or other reasons
 */
+ (XMLDocument *)documentWithContentsOfURL:(NSURL *)url encoding:(NSStringEncoding )encoding error:(NSError **)error;

/*! Returns an XMLDocument object created from the XML contents of a URL-referenced source with assumed UTF-8 string encoding
 * \param url An NSURL object specifying a URL source
 * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
 * \returns An initialized XMLDocument object, or nil if initialization fails because of parsing errors or other reasons
 */
+ (XMLDocument *)documentWithContentsOfURL:(NSURL *)url error:(NSError **)error;

/*! Returns an XMLDocument object created from a string containing XML markup text with specified string encoding
 * \param url An NSURL object specifying a URL source
 * \param encoding The string encoding for the XML content
 * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
 * \returns An initialized XMLDocument object, or nil if initialization fails because of parsing errors or other reasons
 */
+ (XMLDocument *)documentWithHTMLString:(NSString *)string encoding:(NSStringEncoding )encoding error:(NSError **)error;

/*! Returns an XMLDocument object created from a string containing XML markup text with assumed UTF-8 string encoding
 * \param url An NSURL object specifying a URL source
 * \param encoding The string encoding for the XML content
 * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
 * \returns An initialized XMLDocument object, or nil if initialization fails because of parsing errors or other reasons
 */
+ (XMLDocument *)documentWithHTMLString:(NSString *)string error:(NSError **)error;



@end
