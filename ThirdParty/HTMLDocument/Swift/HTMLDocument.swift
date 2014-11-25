/*###################################################################################
#                                                                                   #
#    HTMLDocument.swift                                                             #
#                                                                                   #
#    Copyright © 2014 by Stefan Klieme                                              #
#                                                                                   #
#    Swift wrapper for HTML parser of libxml2                                       #
#                                                                                   #
#    Version 0.9 - 20. Sep 2014                                                     #
#                                                                                   #
#    usage:     add libxml2.dylib to frameworks (depends on autoload settings)      #
#               add $SDKROOT/usr/include/libxml2 to target -> Header Search Paths   #
#               add -lxml2 to target -> other linker flags                          #
#               add Bridging-Header.h to your project and rename it as              #
#                       [Modulename]-Bridging-Header.h                              #
#                    where [Modulename] is the module name in your project          #
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

import Foundation

class HTMLDocument : NSObject {
    
    /** The class name */
    
    var className : String {
        return "HTMLDocument"
    }
    
    /** The document pointer */
    
    var htmlDoc: htmlDocPtr = nil
    
    /** The root node*/
    
    var rootNode: HTMLNode!
    
    /** The head node*/
    
    var head: HTMLNode? {
        return rootNode.childOfTag("head")
    }
    
    /** The body node*/
    
    var body: HTMLNode? {
        return rootNode.childOfTag("body")
    }
    
    /** The value of the title tag in the head node*/
    var title: String? {
        return head?.childOfTag("title")?.stringValue
    }
    
    
    // MARK: - Initialzers
    
    // default text encoding is UTF-8
    
    /*! Initializes and returns an HTMLDocument object created from an NSData object with specified string encoding
    * \param data A data object with HTML or XML content
    * \param encoding The string encoding for the HTML or XML content
    * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
    * \returns An initialized HTMLDocument object, or nil if initialization fails because of parsing errors or other reasons
    */
    
    // designated initializer
    init?(data: NSData?, encoding: NSStringEncoding, error: NSErrorPointer)
    {
        super.init()
        var errorCode = 1
        if let actualData = data {
            if actualData.length > 0 {
                let cfEncoding : CFStringEncoding = CFStringConvertNSStringEncodingToEncoding(encoding)
                let cfEncodingAsString : CFStringRef = CFStringConvertEncodingToIANACharSetName(cfEncoding)
                var cEncoding : UnsafePointer<Int8> = CFStringGetCStringPtr(cfEncodingAsString, 0)
                
                let htmlParseOptions : CInt = 1 << 0 | 1 << 5 | 1 << 6 // HTML_PARSE_RECOVER | HTML_PARSE_NOERROR | HTML_PARSE_NOWARNING
                let htmlDoc : htmlDocPtr = htmlReadMemory(UnsafePointer<Int8>(actualData.bytes), CInt(actualData.length), nil, cEncoding, htmlParseOptions)
                
                if (htmlDoc != nil) {
                    let xmlDocRootNode : xmlNodePtr = xmlDocGetRootElement(htmlDoc);
                    if xmlDocRootNode != nil && String.fromCString(UnsafePointer<CChar>(xmlDocRootNode.memory.name)) == "html" {
                        rootNode = HTMLNode(pointer: xmlDocRootNode)
                        errorCode = 0
                    } else {
                        errorCode = 3
                    }
                } else {
                    errorCode = 2
                }
            }
        }
        if errorCode != 0 {
            if error != nil { error.memory = errorForCode(errorCode) }
            return nil
        }
    }
    
    /*! Initializes and returns an HTMLDocument object created from an NSData object with assumed UTF-8 string encoding
    * \param data A data object with HTML or XML content
    * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
    * \returns An initialized HTMLDocument object, or nil if initialization fails because of parsing errors or other reasons
    */
    
    convenience init?(data: NSData?, inout error: NSError?)
    {
        self.init(data:data, encoding:NSUTF8StringEncoding, error:&error)
    }
    
    /*! Initializes and returns an HTMLDocument object created from the HTML or XML contents of a URL-referenced source with specified string encoding
    * \param url An NSURL object specifying a URL source
    * \param encoding The string encoding for the HTML or XML content
    * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
    * \returns An initialized HTMLDocument object, or nil if initialization fails because of parsing errors or other reasons
    */
    
    convenience init?(contentsOfURL url:NSURL, encoding:NSStringEncoding, inout error:NSError?)
    {
        let options = NSDataReadingOptions(rawValue: 0)
        let data = NSData(contentsOfURL:url, options:options, error:&error)
        self.init(data:data, encoding:encoding, error:&error)
    }
    
    /*! Initializes and returns an HTMLDocument object created from the HTML or XML contents of a URL-referenced source with assumed UTF-8 string encoding
    * \param url An NSURL object specifying a URL source
    * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
    * \returns An initialized HTMLDocument object, or nil if initialization fails because of parsing errors or other reasons
    */
    
    convenience init?(contentsOfURL url: NSURL, inout error: NSError?)
    {
        self.init(contentsOfURL:url, encoding:NSUTF8StringEncoding, error:&error)
    }
    
    /*! Initializes and returns an HTMLDocument object created from a string containing HTML or XML markup text with specified string encoding
    * \param url An NSURL object specifying a URL source
    * \param encoding The string encoding for the HTML or XML content
    * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems
    * \returns An initialized HTMLDocument object, or nil if initialization fails because of parsing errors or other reasons
    */
    
    convenience init?(HTMLString string: String, encoding:NSStringEncoding, inout error:NSError?)
    {
        self.init(data:string.dataUsingEncoding(encoding), encoding:encoding, error:&error)
    }
    
    /*! Initializes and returns an HTMLDocument object created from a string containing HTML or XML markup text with assumed UTF-8 string encoding
    * \param url An NSURL object specifying a URL source
    * \param encoding The string encoding for the HTML or XML content
    * \param error An error object that, on return, identifies any parsing errors and warnings or connection problems.
    * \returns An initialized HTMLDocument object, or nil if initialization fails because of parsing errors or other reasons
    */
    
    convenience init?(HTMLString string: String, inout error:NSError?)
    {
        self.init(HTMLString:string, encoding:NSUTF8StringEncoding, error:&error)
    }
    
    
    // MARK: - Errorhandling
    
    func stringFromCode(errorCode: Int) -> String {
        switch errorCode {
            
        case 1: return "No valid data";
        case 2: return "XML data could not be parsed";
        case 3: return "XML data seems not to be of type HTML";
        default:
            return "Unknown Error";
        }
    }
    
    func errorForCode(errorCode: Int) -> NSError
    {
        return NSError(domain:"com.klieme.\(self.className)", code:errorCode, userInfo:[NSLocalizedDescriptionKey: stringFromCode(errorCode)])
    }
}
