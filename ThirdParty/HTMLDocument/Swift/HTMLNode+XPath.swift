/*###################################################################################
#                                                                                   #
#    HTMLNode+XPath.swift - Extension for HTMLNode                                  #
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

extension HTMLNode  {
    
    // XPath format predicates
    
    struct XPathPredicate {
        static var node: (String) -> String = { return "./descendant::\($0)" }
        static var nodeWithAttribute: (String, String) -> String = { return "//\($0)[@\($1)]" }
        static var attribute: (String) -> String = { return "//*[@\($0)]" }
        static var attributeIsEqual: (String, String) -> String = { return "//*[@\($0) ='\($1)']" }
        static var attributeBeginsWith: (String, String) -> String = { return "./*[starts-with(@\($0),'\($1)')]" }
        static var attributeEndsWith: (String, String) -> String = { return "//*['\($1)' = substring(@\($0)@, string-length(@\($0))- string-length('\($1)') +1)]" }
        static var attributeContains: (String, String) -> String = { return "//*[contains(@\($0),'\($1)')]" }
    }
  
    
    private func xmlXPathNodeSetIsEmpty(nodes : xmlNodeSetPtr) -> Bool {
        return nodes == nil || nodes.memory.nodeNr == 0 || nodes.memory.nodeTab == nil
    }
    
 
    // performXPathQuery() returns one HTMLNode object or an array of HTMLNode objects if the query matches any nodes, otherwise nil or an empty array
    
    private func performXPathQuery(node : xmlNodePtr, query : String, returnSingleNode : Bool, error : NSErrorPointer) -> AnyObject?
    {
        var result : AnyObject? = (returnSingleNode) ? nil : Array<HTMLNode>()
        
        let xmlDoc = node.memory.doc
        let xpathContext = xmlXPathNewContext(xmlDoc)
        
        if xpathContext != nil {
            var xpathObject : xmlXPathObjectPtr
            
            if (query.hasPrefix("//") || query.hasPrefix("./")) {
                xpathObject = xmlXPathNodeEval(node, xmlCharFrom(query), xpathContext)
            } else {
                xpathObject = xmlXPathEvalExpression(xmlCharFrom(query), xpathContext)
            }

            if xpathObject != nil {
                let nodes = xpathObject.memory.nodesetval
                if xmlXPathNodeSetIsEmpty(nodes) == false {
                    let nodesArray = UnsafeBufferPointer(start: nodes.memory.nodeTab, count: Int(nodes.memory.nodeNr))
                    if returnSingleNode {
                        result = HTMLNode(pointer:nodesArray[0])
                    } else {
                        var resultArray = Array<HTMLNode>()
                        for item in nodesArray {
                            if let matchedNode = HTMLNode(pointer:item) {
                                resultArray.append(matchedNode)
                            }
                        }
                        result = resultArray
                    }
                }
                xmlXPathFreeObject(xpathObject)
            }
            else {
                if error != nil {
                    error.memory = setErrorWithMessage("Could not evaluate XPath expression", code:5)
                }
            }
            xmlXPathFreeContext(xpathContext)
        }
        else if error != nil {
            error.memory = setErrorWithMessage("Could not create XPath context", code:4)
        }
        
        return result
    }
    
   

    // MARK: - Objective-C wrapper for XPath Query function
    
    /*! Returns the first descendant node for a XPath query
    * \param query The XPath query string
    * \param error An error object that, on return, identifies any Xpath errors.
    * \returns The first found descendant node or nil if no node matches the parameters
    */
    
    func nodeForXPath(query : String, inout error : NSError?) -> HTMLNode?
    {
        return performXPathQuery(pointer, query:query, returnSingleNode: true, error: &error) as? HTMLNode
    }
    
    /*! Returns the first descendant node for a XPath query
    * \param query The XPath query string
    * \returns The first found descendant node or nil if no node matches the parameters
    */
    
    func nodeForXPath(query : String) -> HTMLNode?
    {
        return performXPathQuery(pointer, query:query, returnSingleNode: true, error: nil) as? HTMLNode
    }
    
    /*! Returns all descendant nodes for a XPath query
    * \param query The XPath query string
    * \param error An error object that, on return, identifies any Xpath errors.
    * \returns The array of all found descendant nodes or an empty array
    */
    
    func nodesForXPath(query : String, inout error : NSError?) -> Array<HTMLNode>
    {
        return performXPathQuery(pointer, query:query, returnSingleNode:false, error:&error) as Array<HTMLNode>
        
    }
    
    /*! Returns all descendant nodes for a XPath query
    * \param query The XPath query string
    * \returns The array of all found descendant nodes or an empty array
    */
    
    func nodesForXPath(query : String) -> Array<HTMLNode>
    {
        return performXPathQuery(pointer, query:query, returnSingleNode:false, error: nil) as Array<HTMLNode>
    }
    
    
    // MARK: - specific XPath Query methods
    // Note: In the HTMLNode main class all appropriate query methods begin with descendant instead of node
    
    /*! Returns the first descendant node for a specified tag name
    * \param tagName The tag name
    * \param error An error object that, on return, identifies any Xpath errors.
    * \returns The first found descendant node or nil if no node matches the parameters
    */
    
    func nodeOfTag(tagName : String, inout error : NSError?) -> HTMLNode?
    {
        return nodeForXPath(XPathPredicate.node(tagName), error:&error)
    }
    
    /*! Returns the first descendant node for a specified tag name
    * \param tagName The tag name
    * \returns The first found descendant node or nil if no node matches the parameters
    */
    
    func nodeOfTag(tagName : String) -> HTMLNode?
    {
        return nodeForXPath(XPathPredicate.node(tagName))
    }
    
    /*! Returns all descendant nodes for a specified tag name
    * \param tagName The tag name
    * \param error An error object that, on return, identifies any Xpath errors.
    * \returns The array of all found descendant nodes or an empty array
    */
    
    func nodesOfTag(tagName : String, inout error : NSError?) -> Array<HTMLNode>
    {
        return nodesForXPath(XPathPredicate.node(tagName), error:&error)
    }
    
    /*! Returns all descendant nodes for a specified tag name
    * \param tagName The tag name
    * \returns The array of all found descendant nodes or an empty array
    */
    
    func nodesOfTag(tagName : String) -> Array<HTMLNode>
    {
        return nodesForXPath(XPathPredicate.node(tagName))
    }
    
    /*! Returns the first descendant node for a matching tag name and matching attribute name
    * \param tagName The tag name
    * \param attributeName The attribute name
    * \param error An error object that, on return, identifies any Xpath errors.
    * \returns The first found descendant node or nil if no node matches the parameters
    */
    
    func nodeOfTag(tagName : String, withAttribute attribute : String, inout error : NSError?) -> HTMLNode?
    {
        return nodeForXPath(XPathPredicate.nodeWithAttribute(tagName, attribute), error:&error)
    }
    
    /*! Returns the first descendant node for a matching tag name and matching attribute name
    * \param tagName The tag name
    * \param attributeName The attribute name
    * \returns The first found descendant node or nil if no node matches the parameters
    */
    
    func nodeOfTag(tagName : String, withAttribute attribute : String) -> HTMLNode?
    {
        return nodeForXPath(XPathPredicate.nodeWithAttribute(tagName, attribute))
    }
    
    /*! Returns all descendant nodes for a matching tag name and matching attribute name
    * \param tagName The tag name
    * \param attributeName The attribute name
    * \param error An error object that, on return, identifies any Xpath errors.
    * \returns The array of all found descendant nodes or an empty array
    */
    
    func nodesOfTag(tagName : String, withAttribute attribute : String, inout error : NSError?) -> Array<HTMLNode>
    {
        return nodesForXPath(XPathPredicate.nodeWithAttribute(tagName, attribute), error:&error)
    }
    
    /*! Returns all descendant nodes for a matching tag name and matching attribute name
    * \param tagName The tag name
    * \param attributeName The attribute name
    * \param error An error object that, on return, identifies any Xpath errors.
    * \returns The array of all found descendant nodes or an empty array
    */
    
    func nodesOfTag(tagName : String, withAttribute attribute : String) -> Array<HTMLNode>
    {
        return nodesForXPath(XPathPredicate.nodeWithAttribute(tagName, attribute))
    }

    /*! Returns the first descendant node for a specified attribute name
    * \param attributeName The attribute name
    * \param error An error object that, on return, identifies any Xpath errors.
    * \returns The first found descendant node or nil if no node matches the parameters
    */
    
    func nodeWithAttribute(attributeName : String, inout error : NSError?) -> HTMLNode?
    {
        return nodeForXPath(XPathPredicate.attribute(attributeName), error:&error)
    }
    
    /*! Returns the first descendant node for a specified attribute name
    * \param attributeName The attribute name
    * \returns The first found descendant node or nil if no node matches the parameters
    */
    
    func nodeWithAttribute(attributeName : String) -> HTMLNode?
    {
        return nodeForXPath(XPathPredicate.attribute(attributeName))
    }
    
    /*! Returns all descendant nodes for a specified attribute name
    * \param attributeName The attribute name
    * \returns The array of all found descendant nodes or an empty array
    */
    
    func nodesWithAttribute(attributeName : String, inout error : NSError?)  -> Array<HTMLNode>
    {
        return nodesForXPath(XPathPredicate.attribute(attributeName), error:&error)
    }
    
    /*! Returns all descendant nodes for a specified attribute name
    * \param attributeName The attribute name
    * \param error An error object that, on return, identifies any Xpath errors.
    * \returns The array of all found descendant nodes or an empty array
    */
    
    func nodesWithAttribute(attributeName : String) -> Array<HTMLNode>
    {
        return nodesForXPath(XPathPredicate.attribute(attributeName))
    }
    
    /*! Returns the first descendant node for a matching attribute name and matching attribute value
    * \param attributeName The attribute name
    * \param value The attribute value
    * \param error An error object that, on return, identifies any Xpath errors.
    * \returns The first found descendant node or nil if no node matches the parameters
    */
    
    func nodeWithAttribute(attributeName : String, valueMatches value : String, inout error : NSError?) -> HTMLNode?
    {
        return nodeForXPath(XPathPredicate.attributeIsEqual(attributeName, value), error:&error)
    }
    
    /*! Returns the first descendant node for a matching attribute name and matching attribute value
    * \param attributeName The attribute name
    * \param value The attribute value
    * \returns The first found descendant node or nil if no node matches the parameters
    */
    
    func nodeWithAttribute(attributeName : String, valueMatches value : String) -> HTMLNode?
    {
        return nodeForXPath(XPathPredicate.attributeIsEqual(attributeName, value))
    }
    
    /*! Returns all descendant nodes for a matching attribute name and matching attribute value
    * \param attributeName The attribute name
    * \param value The attribute value
    * \param error An error object that, on return, identifies any Xpath errors.
    * \returns The array of all found descendant nodes or an empty array
    */
    
    func nodesWithAttribute(attributeName : String, valueMatches value : String, inout error : NSError?) -> Array<HTMLNode>
    {
        return nodesForXPath(XPathPredicate.attributeIsEqual(attributeName, value), error:&error)
    }
    
    /*! Returns all descendant nodes for a matching attribute name and matching attribute value
    * \param attributeName The attribute name
    * \param value The attribute value
    * \returns The array of all found descendant nodes or an empty array
    */
    
    func nodesWithAttribute(attributeName : String, valueMatches value : String) -> Array<HTMLNode>
    {
        return nodesForXPath(XPathPredicate.attributeIsEqual(attributeName, value))
    }
    
    /*! Returns the first descendant node for a matching attribute name and beginning of the attribute value
    * \param attributeName The attribute name
    * \param value The attribute value
    * \param error An error object that, on return, identifies any Xpath errors.
    * \returns The first found descendant node or nil if no node matches the parameters
    */

    func nodeWithAttribute(attributeName : String,  valueBeginsWith value : String, inout error : NSError?) -> HTMLNode?
    {
        return nodeForXPath(XPathPredicate.attributeBeginsWith(attributeName, value), error:&error)
    }
    
    /*! Returns the first descendant node for a matching attribute name and beginning of the attribute value
    * \param attributeName The attribute name
    * \param value The attribute value
    * \returns The first found descendant node or nil if no node matches the parameters
    */
    
    func nodeWithAttribute(attributeName : String,  valueBeginsWith value : String) -> HTMLNode?
    {
        return nodeForXPath(XPathPredicate.attributeBeginsWith(attributeName, value))
    }
    
    /*! Returns all descendant nodes for a matching attribute name and beginning of the attribute value
    * \param attributeName The attribute name
    * \param value The attribute value
    * \param error An error object that, on return, identifies any Xpath errors.
    * \returns The array of all found descendant nodes or an empty array
    */
    
    func nodesWithAttribute(attributeName : String,  valueBeginsWith value : String, inout error : NSError?) -> Array<HTMLNode>
    {
        return nodesForXPath(XPathPredicate.attributeBeginsWith(attributeName, value), error:&error)
    }
    
    /*! Returns all descendant nodes for a matching attribute name and beginning of the attribute value
    * \param attributeName The attribute name
    * \param value The attribute value
    * \returns The array of all found descendant nodes or an empty array
    */
    
    func nodesWithAttribute(attributeName : String,  valueBeginsWith value : String) -> Array<HTMLNode>
    {
        return nodesForXPath(XPathPredicate.attributeBeginsWith(attributeName, value))
    }
    
    /*! Returns the first descendant node for a matching attribute name and ending of the attribute value
    * \param attributeName The attribute name
    * \param value The attribute value
    * \param error An error object that, on return, identifies any Xpath errors.
    * \returns The first found descendant node or nil if no node matches the parameters
    */
    
    func nodeWithAttribute(attributeName : String,  valueEndsWith value : String, inout error : NSError?) -> HTMLNode?
    {
        return nodeForXPath(XPathPredicate.attributeEndsWith(attributeName, value), error:&error)
    }
    
    /*! Returns the first descendant node for a matching attribute name and ending of the attribute value
    * \param attributeName The attribute name
    * \param value The attribute value
    * \returns The first found descendant node or nil if no node matches the parameters
    */
    
    func nodeWithAttribute(attributeName : String,  valueEndsWith value : String) -> HTMLNode?
    {
        return nodeForXPath(XPathPredicate.attributeEndsWith(attributeName, value))
    }
    
    /*! Returns all descendant nodes for a matching attribute name and ending of the attribute value
    * \param attributeName The attribute name
    * \param value The attribute value
    * \param error An error object that, on return, identifies any Xpath errors.
    * \returns The array of all found descendant nodes or an empty array
    */
    
    func nodesWithAttribute(attributeName : String,  valueEndsWith value : String, inout error : NSError?) -> Array<HTMLNode>
    {
        return nodesForXPath(XPathPredicate.attributeEndsWith(attributeName, value), error:&error)
    }
    
    /*! Returns all descendant nodes for a matching attribute name and ending of the attribute value
    * \param attributeName The attribute name
    * \param value The attribute value
    * \returns The array of all found descendant nodes or an empty array
    */
    
    func nodesWithAttribute(attributeName : String,  valueEndsWith value : String) -> Array<HTMLNode>
    {
        return nodesForXPath(XPathPredicate.attributeEndsWith(attributeName, value))
    }
    
    /*! Returns the first descendant node for a matching attribute name and containing the attribute value
    * \param attributeName The attribute name
    * \param value The attribute value
    * \param error An error object that, on return, identifies any Xpath errors.
    * \returns The first found descendant node or nil if no node matches the parameters
    */
    
    func nodeWithAttribute(attributeName : String,  valueContains value : String, inout error : NSError?) -> HTMLNode?
    {
        return nodeForXPath(XPathPredicate.attributeContains(attributeName, value), error:&error)
    }
    
    /*! Returns the first descendant node for a matching attribute name and containing the attribute value
    * \param attributeName The attribute name
    * \param value The attribute value
    * \returns The first found descendant node or nil if no node matches the parameters
    */
    
    func nodeWithAttribute(attributeName : String,  valueContains value : String) -> HTMLNode?
    {
        return nodeForXPath(XPathPredicate.attributeContains(attributeName, value))
    }
    
    /*! Returns all descendant nodes for a matching attribute name and containing the attribute value
    * \param attributeName The attribute name
    * \param value The attribute value
    * \param error An error object that, on return, identifies any Xpath errors.
    * \returns The array of all found descendant nodes or an empty array
    */
    
    func nodesWithAttribute(attributeName : String,  valueContains value : String, inout error : NSError?) -> Array<HTMLNode>
    {
        return nodesForXPath(XPathPredicate.attributeContains(attributeName, value), error:&error)
    }
    
    /*! Returns all descendant nodes for a matching attribute name and containing the attribute value
    * \param attributeName The attribute name
    * \param value The attribute value
    * \returns The array of all found descendant nodes or an empty array
    */
    
    func nodesWithAttribute(attributeName : String,  valueContains value : String) -> Array<HTMLNode>
    {
        return nodesForXPath(XPathPredicate.attributeContains(attributeName, value))
    }
    
    /*! Returns the first descendant node for a specified class name
    * \param classValue The class name
    * \param error An error object that, on return, identifies any Xpath errors.
    * \returns The first found descendant node or nil if no node matches the parameters
    */
    
    func nodeWithClass(classValue : String, inout error : NSError?) -> HTMLNode?
    {
        return nodeWithAttribute(kClassKey, valueMatches:classValue, error:&error)
    }
    
    /*! Returns the first descendant node for a specified class name
    * \param classValue The class name
    * \returns The first found descendant node or nil if no node matches the parameters
    */
    
    func nodeWithClass(classValue : String) -> HTMLNode?
    {
        return nodeWithAttribute(kClassKey, valueMatches:classValue)
    }
    
    /*! Returns all descendant nodes for a specified class name
    * \param classValue The class name
    * \param error An error object that, on return, identifies any Xpath errors.
    * \returns The array of all found descendant nodes or an empty array
    */
    
    func nodesWithClass(classValue : String, inout error : NSError?) -> Array<HTMLNode>
    {
        return nodesWithAttribute(kClassKey, valueMatches:classValue, error:&error)
    }
    
    /*! Returns all descendant nodes for a specified class name
    * \param classValue The class name
    * \returns The array of all found descendant nodes or an empty array
    */
    
    func nodesWithClass(classValue : String) -> Array<HTMLNode>
    {
        return nodesWithAttribute(kClassKey, valueMatches:classValue)
    }

    // MARK: -  error handling
    
    func setErrorWithMessage(message : String, code : Int) -> NSError
    {
        return NSError(domain: "com.klieme.HTMLDocument", code:code, userInfo: [NSLocalizedDescriptionKey: message])
    }
    
}
