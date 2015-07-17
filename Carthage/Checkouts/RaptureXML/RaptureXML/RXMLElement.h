// ================================================================================================
//  RXMLElement.h
//  Fast processing of XML files
//
// ================================================================================================
//  Created by John Blanco on 9/23/11.
//  Version 1.4
//  
//  Copyright (c) 2011 John Blanco
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
// ================================================================================================
//

#import <Foundation/Foundation.h>
#import <libxml2/libxml/xmlreader.h>
#import <libxml2/libxml/xmlmemory.h>
#import <libxml2/libxml/HTMLparser.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>

@interface RXMLDocHolder : NSObject {
    xmlDocPtr doc_;
}

- (id)initWithDocPtr:(xmlDocPtr)doc;
- (xmlDocPtr)doc;

@end

@interface RXMLElement : NSObject<NSCopying> {
    xmlNodePtr node_;
}

- (id)initFromXMLString:(NSString *)xmlString encoding:(NSStringEncoding)encoding;
- (id)initFromXMLFile:(NSString *)filename;
- (id)initFromXMLFile:(NSString *)filename fileExtension:(NSString*)extension;
- (id)initFromXMLFilePath:(NSString *)fullPath;
- (id)initFromURL:(NSURL *)url __attribute__((deprecated));
- (id)initFromXMLData:(NSData *)data;
- (id)initFromXMLDoc:(RXMLDocHolder *)doc node:(xmlNodePtr)node;

- (id)initFromHTMLString:(NSString *)xmlString encoding:(NSStringEncoding)encoding;
- (id)initFromHTMLFile:(NSString *)filename;
- (id)initFromHTMLFile:(NSString *)filename fileExtension:(NSString*)extension;
- (id)initFromHTMLFilePath:(NSString *)fullPath;
- (id)initFromHTMLData:(NSData *)data;

+ (id)elementFromXMLString:(NSString *)xmlString encoding:(NSStringEncoding)encoding;
+ (id)elementFromXMLFile:(NSString *)filename;
+ (id)elementFromXMLFilename:(NSString *)filename fileExtension:(NSString *)extension;
+ (id)elementFromXMLFilePath:(NSString *)fullPath;
+ (id)elementFromURL:(NSURL *)url __attribute__((deprecated));
+ (id)elementFromXMLData:(NSData *)data;
+ (id)elementFromXMLDoc:(RXMLDocHolder *)doc node:(xmlNodePtr)node;

+ (id)elementFromHTMLString:(NSString *)xmlString encoding:(NSStringEncoding)encoding;
+ (id)elementFromHTMLFile:(NSString *)filename;
+ (id)elementFromHTMLFile:(NSString *)filename fileExtension:(NSString*)extension;
+ (id)elementFromHTMLFilePath:(NSString *)fullPath;
+ (id)elementFromHTMLData:(NSData *)data;

- (NSString *)attribute:(NSString *)attributeName;
- (NSString *)attribute:(NSString *)attributeName inNamespace:(NSString *)ns;

- (NSArray *)attributeNames;

- (NSInteger)attributeAsInt:(NSString *)attributeName;
- (NSInteger)attributeAsInt:(NSString *)attributeName inNamespace:(NSString *)ns;

- (double)attributeAsDouble:(NSString *)attributeName;
- (double)attributeAsDouble:(NSString *)attributeName inNamespace:(NSString *)ns;

- (RXMLElement *)child:(NSString *)tag;
- (RXMLElement *)child:(NSString *)tag inNamespace:(NSString *)ns;

- (NSArray *)children:(NSString *)tag;
- (NSArray *)children:(NSString *)tag inNamespace:(NSString *)ns;
- (NSArray *)childrenWithRootXPath:(NSString *)xpath;

- (void)iterate:(NSString *)query usingBlock:(void (^)(RXMLElement *))blk;
- (void)iterateWithRootXPath:(NSString *)xpath usingBlock:(void (^)(RXMLElement *))blk;
- (void)iterateElements:(NSArray *)elements usingBlock:(void (^)(RXMLElement *))blk;

@property (nonatomic, strong) RXMLDocHolder *xmlDoc;
@property (nonatomic, readonly) NSString *tag;
@property (nonatomic, readonly) NSString *text;
@property (nonatomic, readonly) NSString *xml;
@property (nonatomic, readonly) NSString *innerXml;
@property (nonatomic, readonly) NSInteger textAsInt;
@property (nonatomic, readonly) double textAsDouble;
@property (nonatomic, readonly) BOOL isValid;

@end

typedef void (^RXMLBlock)(RXMLElement *element);

