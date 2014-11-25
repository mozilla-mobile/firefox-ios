/*###################################################################################
 #                                                                                  #
 #     HTMLDocument.m                                                               #
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

#import "HTMLDocument.h"

const char *convertStringEncoding(NSStringEncoding encoding, char * buffer, size_t bufferSize);

const char * convertStringEncoding(NSStringEncoding encoding, char * buffer, size_t bufferSize) {
    CFStringEncoding cfEncoding = CFStringConvertNSStringEncodingToEncoding(encoding);
    CFStringRef cfEncodingAsString = CFStringConvertEncodingToIANACharSetName(cfEncoding);
    const char * cEncoding = CFStringGetCStringPtr(cfEncodingAsString, kCFStringEncodingMacRoman);
    if (! cEncoding) {
        Boolean ok = CFStringGetCString(cfEncodingAsString, buffer, bufferSize, kCFStringEncodingMacRoman);
        NSCAssert(ok, @"convertStringEncoding buffer too small");
        cEncoding = buffer;
    }
    return cEncoding;
}



@implementation HTMLDocument
@synthesize rootNode;

#pragma mark - error handling

- (NSError *)errorForCode:(NSInteger )errorCode
{
    NSString *errorString = @"";
    switch (errorCode) {
        case 1:
            errorString = @"No valid data";
            break;
            
        case 2:
            errorString = @"XML data could not be parsed";
            break;
            
        case 3:
            errorString = @"XML data seems not to be of type HTML";
            break;
    }
    return [NSError errorWithDomain:[@"com.klieme." stringByAppendingString: NSStringFromClass([self class])]
                               code:errorCode
                           userInfo:@{NSLocalizedDescriptionKey: errorString}];
}

#pragma mark - class methods

// convenience initializer methods

+ (HTMLDocument *)documentWithData:(NSData *)data encoding:(NSStringEncoding )encoding error:(NSError **)error
{
    return SAFE_ARC_AUTORELEASE([[HTMLDocument alloc] initWithData:data encoding:encoding error:error]);
}

+ (HTMLDocument *)documentWithData:(NSData *)data error:(NSError **)error
{
    return SAFE_ARC_AUTORELEASE([[HTMLDocument alloc] initWithData:data error:error]);
}

+ (HTMLDocument *)documentWithContentsOfURL:(NSURL *)url encoding:(NSStringEncoding )encoding error:(NSError **)error
{
    return SAFE_ARC_AUTORELEASE([[HTMLDocument alloc] initWithContentsOfURL:url encoding:encoding error:error]);
}

+ (HTMLDocument *)documentWithContentsOfURL:(NSURL *)url error:(NSError **)error
{
    return SAFE_ARC_AUTORELEASE([[HTMLDocument alloc] initWithContentsOfURL:url error:error]);
}

+ (HTMLDocument *)documentWithHTMLString:(NSString *)string encoding:(NSStringEncoding )encoding error:(NSError **)error
{
    return SAFE_ARC_AUTORELEASE([[HTMLDocument alloc] initWithHTMLString:string encoding:encoding error:error]);
}

+ (HTMLDocument *)documentWithHTMLString:(NSString *)string error:(NSError **)error
{
    return SAFE_ARC_AUTORELEASE([[HTMLDocument alloc] initWithHTMLString:string error:error]);
}

#pragma mark - instance init methods

// designated initializer
- (INSTANCETYPE_OR_ID)initWithData:(NSData *)data encoding:(NSStringEncoding )encoding error:(NSError **)error
{
    self = [super init];
    if (self) {
        NSInteger errorCode = 0;
		if (data && [data length]) {
            int htmlParseOptions = HTML_PARSE_RECOVER | HTML_PARSE_NOERROR | HTML_PARSE_NOWARNING;
            char encodingBuffer[32];
            htmlDoc_ = htmlReadMemory([data bytes], (int)[data length], NULL,  convertStringEncoding(encoding, encodingBuffer, sizeof(encodingBuffer)), htmlParseOptions);
            if (htmlDoc_) {
                xmlNodePtr xmlDocRootNode = xmlDocGetRootElement(htmlDoc_);
                if (xmlDocRootNode && xmlStrEqual(xmlDocRootNode->name, BAD_CAST "html")) {
                    rootNode = [[HTMLNode alloc] initWithXMLNode:xmlDocRootNode];
                }
                else
                    errorCode = 3;
            }
            else
                errorCode = 2;
		}
		else
            errorCode = 1;
        
        if (errorCode) {
            if (error)
                *error = [self errorForCode:errorCode];
            
            SAFE_ARC_RELEASE(self);
            return nil;
        }
    }
	return self;
}

- (INSTANCETYPE_OR_ID)initWithData:(NSData *)data error:(NSError **)error
{
	return [self initWithData:data encoding:NSUTF8StringEncoding error:error];
}

- (INSTANCETYPE_OR_ID)initWithContentsOfURL:(NSURL *)url encoding:(NSStringEncoding )encoding error:(NSError **)error
{
    
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:error];
    if (data && *error == nil) {
        return [self initWithData:data encoding:encoding error:error];
    }
	return nil;
}

- (INSTANCETYPE_OR_ID)initWithContentsOfURL:(NSURL *)url error:(NSError **)error
{
	return [self initWithContentsOfURL:url encoding:NSUTF8StringEncoding error:error];
}

- (INSTANCETYPE_OR_ID)initWithHTMLString:(NSString *)string encoding:(NSStringEncoding )encoding error:(NSError **)error
{
	return [self initWithData:[string dataUsingEncoding:encoding]
                     encoding:encoding
                        error:error];
}

- (INSTANCETYPE_OR_ID)initWithHTMLString:(NSString *)string error:(NSError **)error
{
	return [self initWithHTMLString:string encoding:NSUTF8StringEncoding error:error];
}


- (void)dealloc
{
    SAFE_ARC_RELEASE(rootNode);
    xmlFreeDoc(htmlDoc_);
	SAFE_ARC_SUPER_DEALLOC();
}

#pragma mark - frequently used nodes

- (HTMLNode *)head
{
	return [self.rootNode childOfTag:@"head"];
}

- (HTMLNode *)body
{
	return [self.rootNode childOfTag:@"body"];
}

- (NSString *)title
{
	return [[self.head childOfTag:@"title"] stringValue];
}


@end


@implementation XMLDocument

+ (XMLDocument *)documentWithData:(NSData *)data encoding:(NSStringEncoding )encoding error:(NSError **)error
{
    return SAFE_ARC_AUTORELEASE([[XMLDocument alloc] initWithData:data encoding:encoding error:error]);
}

+ (XMLDocument *)documentWithData:(NSData *)data error:(NSError **)error
{
    return SAFE_ARC_AUTORELEASE([[XMLDocument alloc] initWithData:data error:error]);
}

+ (XMLDocument *)documentWithContentsOfURL:(NSURL *)url encoding:(NSStringEncoding )encoding error:(NSError **)error
{
    return SAFE_ARC_AUTORELEASE([[XMLDocument alloc] initWithContentsOfURL:url encoding:encoding error:error]);
}

+ (XMLDocument *)documentWithContentsOfURL:(NSURL *)url error:(NSError **)error
{
    return SAFE_ARC_AUTORELEASE([[XMLDocument alloc] initWithContentsOfURL:url error:error]);
}

+ (XMLDocument *)documentWithHTMLString:(NSString *)string encoding:(NSStringEncoding )encoding error:(NSError **)error
{
    return SAFE_ARC_AUTORELEASE([[XMLDocument alloc] initWithHTMLString:string encoding:encoding error:error]);
}

+ (XMLDocument *)documentWithHTMLString:(NSString *)string error:(NSError **)error
{
    return SAFE_ARC_AUTORELEASE([[XMLDocument alloc] initWithHTMLString:string error:error]);
}

- (INSTANCETYPE_OR_ID)initWithData:(NSData *)data encoding:(NSStringEncoding )encoding error:(NSError **)error
{
    self = [super init];
    if (self) {
        NSInteger errorCode = 0;
		if (data && [data length]) {
            int xmlParseOptions = XML_PARSE_RECOVER | XML_PARSE_NOERROR | XML_PARSE_NOWARNING;
            char encodingBuffer[32];
            xmlDoc_ = xmlReadMemory([data bytes], (int)[data length], NULL, convertStringEncoding(encoding, encodingBuffer, sizeof(encodingBuffer)), xmlParseOptions);
            if (xmlDoc_) {
                xmlNodePtr xmlDocRootNode = xmlDocGetRootElement(xmlDoc_);
                if (xmlDocRootNode) {
                    rootNode = [[HTMLNode alloc] initWithXMLNode:xmlDocRootNode];
                }
                else
                    errorCode = 3;
            }
            else
                errorCode = 2;
		}
		else
            errorCode = 1;
        
        if (errorCode) {
            if (error)
                *error = [self errorForCode:errorCode];
            
            SAFE_ARC_RELEASE(self);
            return nil;
        }
    }
	return self;
}

@end


