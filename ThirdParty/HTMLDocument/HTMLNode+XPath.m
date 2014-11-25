/*###################################################################################
#                                                                                   #
#     HTMLNode+XPath.m                                                              #
#     Category of HTMLNode for XPath support                                        #
#                                                                                   #
#     Copyright © 2014 by Stefan Klieme                                             #
#                                                                                   #
#     Objective-C wrapper for HTML parser of libxml2                                #
#                                                                                   #
#     Version 1.7 - 20. Sep 2014                                                    #
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


#import "HTMLNode+XPath.h"
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>

static NSString *kXPathPredicateNode = @"/descendant::%@";
static NSString *kXPathPredicateNodeWithAttribute = @"//%@[@%@]";
static NSString *kXPathPredicateAttribute = @"//*[@%@]";
static NSString *kXPathPredicateAttributeIsEqual = @"//*[@%@ ='%@']";
static NSString *kXPathPredicateAttributeBeginsWith = @"//*[starts-with(@%@,'%@')]";
static NSString *kXPathPredicateAttributeEndsWith = @"//*['%@' = substring(@%@, string-length(@%@)- string-length('%@') +1)]";
static NSString *kXPathPredicateAttributeContains = @"//*[contains(@%@,'%@')]";

static id performXPathQuery(xmlNode * node, NSString * query, BOOL returnSingleNode, BOOL considerError, HTMLNode *htmlNode);
static void XPathErrorCallback(void *node, xmlErrorPtr err);

#pragma mark - static C functions

// xpath error callback
static void XPathErrorCallback(void *node, xmlErrorPtr err)
{
    NSInteger errorCode = (NSInteger )err->code;
    if ((errorCode > 1199) && (errorCode < 1223)) { // filter XPath errors 1200 - 1222
        char *errMessage = err->message;
        NSString *errorMessage = (errMessage) ? [NSString stringWithUTF8String:errMessage] : @"unknown error";
#if __has_feature(objc_arc)
        [(__bridge_transfer HTMLNode *)node setErrorWithMessage:errorMessage andCode:errorCode];
#else
        [(HTMLNode *)node setErrorWithMessage:errorMessage andCode:errorCode];
#endif
    }
}


// performXPathQuery() returns one HTMLNode object or an array of HTMLNode objects
// if the query matches any nodes, otherwise nil.

static id performXPathQuery(xmlNode * node, NSString * query, BOOL returnSingleNode, BOOL considerError, HTMLNode *htmlNode)
{
    if (query == nil) {
        if (considerError) [htmlNode setErrorWithMessage:@"query string must not be nil value" andCode:6];
        return nil;
    }
    xmlXPathContextPtr xpathContext;
    xmlXPathObjectPtr xpathObject;
    id result = (returnSingleNode) ? nil : [NSMutableArray array];
    
    xpathContext = xmlXPathNewContext((xmlDocPtr)node);
    if (xpathContext) {
        if (considerError)
#if __has_feature(objc_arc)
        { xmlSetStructuredErrorFunc((__bridge_retained void *)htmlNode, XPathErrorCallback); }
#else
        { xmlSetStructuredErrorFunc((void *)htmlNode, XPathErrorCallback); }
#endif
        
        xpathObject = xmlXPathEvalExpression((xmlChar *)[query UTF8String], xpathContext);
        
        if (xpathObject) {
            xmlNodeSetPtr nodes = xpathObject->nodesetval;
            if (xmlXPathNodeSetIsEmpty(nodes) == NO) {
                if (returnSingleNode) {
                    result = [HTMLNode nodeWithXMLNode:nodes->nodeTab[0]];
                } else {
    
                    
                    for (int i = 0; i < nodes->nodeNr; i++) {
                        HTMLNode *matchedNode = [[HTMLNode alloc] initWithXMLNode:nodes->nodeTab[i]];
                        [result addObject:matchedNode];
#if !__has_feature(objc_arc)
                        [matchedNode release];
#endif
                    }
                }
            }
            xmlXPathFreeObject(xpathObject);
        }
        else {
            if (considerError) [htmlNode setErrorWithMessage:@"Could not evaluate XPath expression" andCode:5];
        }
        xmlXPathFreeContext(xpathContext);
    }
    else
        if (considerError) [htmlNode setErrorWithMessage:@"Could not create XPath context" andCode:4];
    
    return result;
}

#pragma mark

@implementation HTMLNode (XPath)

#pragma mark - private getter

- (xmlNode *)xmlNode
{
    return xmlNode_;
}

#pragma mark - Objective-C wrapper for XPath Query function

// perform XPath query and return first search result

- (HTMLNode *)nodeForXPath:(NSString *)query error:(NSError **)error
{
    self.xpathError = nil;
    HTMLNode *result = (HTMLNode *)performXPathQuery(xmlNode_, query, YES, error != nil, self);
    if (error) *error = xpathError;
    return result;
}

- (HTMLNode *)nodeForXPath:(NSString *)query
{
    return [self nodeForXPath:query error:nil];
}


// perform XPath query and return all results

- (NSArray *)nodesForXPath:(NSString *)query error:(NSError **)error
{
    self.xpathError = nil;
    NSArray *result = (NSArray *)performXPathQuery(xmlNode_, query, NO, error != nil, self);
    if (error) *error = xpathError;
    return result;
}

- (NSArray *)nodesForXPath:(NSString *)query
{
    return [self nodesForXPath:query error:nil];
}

#pragma mark - specific XPath Query methods

- (HTMLNode *)nodeOfTag:(NSString *)tagName error:(NSError **)error
{
    return [self nodeForXPath:[NSString stringWithFormat:kXPathPredicateNode, tagName] error:error];
}

- (HTMLNode *)nodeOfTag:(NSString *)tagName
{
    return [self nodeOfTag:tagName error:nil];
}

- (NSArray *)nodesOfTag:(NSString *)tagName error:(NSError **)error
{
    return [self nodesForXPath:[NSString stringWithFormat:kXPathPredicateNode, tagName] error:error];
}

- (NSArray *)nodesOfTag:(NSString *)tagName
{
    return [self nodesOfTag:tagName error:nil];
}

- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName error:(NSError **)error
{
    return [self nodeForXPath:[NSString stringWithFormat:kXPathPredicateAttribute, attributeName] error:error];
}

- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName
{
    return [self nodeWithAttribute:attributeName error:nil];
}

- (NSArray *)nodesWithAttribute:(NSString *)attributeName error:(NSError **)error
{
    return [self nodesForXPath:[NSString stringWithFormat:kXPathPredicateAttribute, attributeName] error:error];
}

- (NSArray *)nodesWithAttribute:(NSString *)attributeName
{
    return [self nodesWithAttribute:attributeName error:nil];
}

- (HTMLNode *)nodeOfTag:(NSString *)tagName withAttribute:(NSString *)attributeName error:(NSError **)error
{
    return [self nodeForXPath:[NSString stringWithFormat:kXPathPredicateNodeWithAttribute, tagName, attributeName] error:error];
}

- (HTMLNode *)nodeOfTag:(NSString *)tagName withAttribute:(NSString *)attributeName
{
    return [self nodeOfTag:tagName withAttribute:attributeName error:nil];
}

- (NSArray *)nodesOfTag:(NSString *)tagName withAttribute:(NSString *)attributeName error:(NSError **)error
{
    return [self nodesForXPath:[NSString stringWithFormat:kXPathPredicateNodeWithAttribute, tagName, attributeName] error:error];
}

- (NSArray *)nodesOfTag:(NSString *)tagName withAttribute:(NSString *)attributeName
{
    return [self nodesOfTag:tagName withAttribute:attributeName error:nil];
}

- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueMatches:(NSString *)value error:(NSError **)error
{
    return [self nodeForXPath:[NSString stringWithFormat:kXPathPredicateAttributeIsEqual, attributeName, value] error:error];
}

- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueMatches:(NSString *)value
{
    return [self nodeWithAttribute:attributeName valueMatches:value error:nil];
}

- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueMatches:(NSString *)value error:(NSError **)error
{
    return [self nodesForXPath:[NSString stringWithFormat:kXPathPredicateAttributeIsEqual, attributeName, value] error:error];
}

- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueMatches:(NSString *)value
{
    return [self nodesWithAttribute:attributeName valueMatches:value error:nil];
}

- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueBeginsWith:(NSString *)value error:(NSError **)error
{
    return [self nodeForXPath:[NSString stringWithFormat:kXPathPredicateAttributeBeginsWith, attributeName, value] error:error];
}

- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueBeginsWith:(NSString *)value
{
    return [self nodeWithAttribute:attributeName valueBeginsWith:value error:nil];
}

- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueBeginsWith:(NSString *)value error:(NSError **)error
{
    return [self nodesForXPath:[NSString stringWithFormat:kXPathPredicateAttributeBeginsWith, attributeName, value] error:error];
}

- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueBeginsWith:(NSString *)value
{
    return [self nodesWithAttribute:attributeName valueBeginsWith:value error:nil];
}

- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueEndsWith:(NSString *)value error:(NSError **)error
{
    return [self nodeForXPath:[NSString stringWithFormat:kXPathPredicateAttributeEndsWith, value, attributeName, attributeName, value] error:error];
}

- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueEndsWith:(NSString *)value
{
    return [self nodeWithAttribute:attributeName valueEndsWith:value error:nil];
}

- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueEndsWith:(NSString *)value error:(NSError **)error
{
    return [self nodesForXPath:[NSString stringWithFormat:kXPathPredicateAttributeEndsWith, value, attributeName, attributeName, value] error:error];
}

- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueEndsWith:(NSString *)value
{
    return [self nodesWithAttribute:attributeName valueEndsWith:value error:nil];
}

- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueContains:(NSString *)value error:(NSError **)error
{
    return [self nodeForXPath:[NSString stringWithFormat:kXPathPredicateAttributeContains, attributeName, value] error:error];
}

- (HTMLNode *)nodeWithAttribute:(NSString *)attributeName valueContains:(NSString *)value
{
    return [self nodeWithAttribute:attributeName valueContains:value error:nil];
}

- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueContains:(NSString *)value error:(NSError **)error
{
    return [self nodesForXPath:[NSString stringWithFormat:kXPathPredicateAttributeContains, attributeName, value] error:error];
}

- (NSArray *)nodesWithAttribute:(NSString *)attributeName valueContains:(NSString *)value
{
    return [self nodesWithAttribute:attributeName valueContains:value error:nil];
}

- (HTMLNode *)nodeWithClass:(NSString *)classValue error:(NSError **)error
{
    return [self nodeWithAttribute:kClassKey valueMatches:classValue error:error];
}

- (HTMLNode *)nodeWithClass:(NSString *)classValue
{
    return [self nodeWithAttribute:kClassKey valueMatches:classValue];
}

- (NSArray *)nodesWithClass:(NSString *)classValue error:(NSError **)error
{
    return [self nodesWithAttribute:kClassKey valueMatches:classValue error:error];
}

- (NSArray *)nodesWithClass:(NSString *)classValue
{
    return [self nodesWithAttribute:kClassKey valueMatches:classValue];
}

#pragma mark - Overriding Equality

//compare HTMLNode objects with XPath
- (BOOL)isEqual:(HTMLNode *)node
{
    if (node == self) return YES;
    if (!node || ![node isKindOfClass: [self class]]) return NO;
    return xmlXPathCmpNodes([self xmlNode], [node xmlNode]) == 0;
}

#pragma mark - error handling

- (void)setErrorWithMessage:(NSString *)message andCode:(NSInteger)code
{
    self.xpathError = [NSError errorWithDomain:@"com.klieme.HTMLDocument"
                                          code:code
                                      userInfo:@{NSLocalizedDescriptionKey: message}];
}

@end
