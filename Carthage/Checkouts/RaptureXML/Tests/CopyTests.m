//
//  CopyTests.m
//  RaptureXML
//
//  Created by John Blanco on 9/24/11.
//  Copy tests modified from SimpleTests.m by Graham Ramsey on 2/23/13
//  Copyright (c) 2011 Rapture In Venice. All rights reserved.
//

#import "RXMLElement.h"

@interface CopyTests : SenTestCase {
    NSString *simplifiedXML_;
    NSString *attributedXML_;
    NSString *interruptedTextXML_;
    NSString *cdataXML_;
}

@end

@implementation CopyTests

- (void)setUp {
    simplifiedXML_ = @"\
    <shapes>\
    <square>Square</square>\
    <triangle>Triangle</triangle>\
    <circle>Circle</circle>\
    </shapes>";
    
    attributedXML_ = @"\
    <shapes>\
    <square name=\"Square\" />\
    <triangle name=\"Triangle\" />\
    <circle name=\"Circle\" />\
    </shapes>";
    interruptedTextXML_ = @"<top><a>this</a>is<a>interrupted</a>text<a></a></top>";
    cdataXML_ = @"<top><![CDATA[this]]><![CDATA[is]]><![CDATA[cdata]]></top>";
}

- (void)testInterruptedText {
    RXMLElement *rxml = [RXMLElement elementFromXMLString:interruptedTextXML_ encoding:NSUTF8StringEncoding];
    RXMLElement *rxml2 = [rxml copy];
    STAssertEqualObjects(rxml2.text, @"thisisinterruptedtext", nil);
}

- (void)testCDataText {
    RXMLElement *rxml = [RXMLElement elementFromXMLString:cdataXML_ encoding:NSUTF8StringEncoding];
    RXMLElement *rxml2 = [rxml copy];
    STAssertEqualObjects(rxml2.text, @"thisiscdata", nil);
}

- (void)testTags {
    RXMLElement *rxml = [RXMLElement elementFromXMLString:simplifiedXML_ encoding:NSUTF8StringEncoding];
    RXMLElement *rxml2 = [rxml copy];
    __block NSInteger i = 0;
    
    [rxml2 iterate:@"*" usingBlock:^(RXMLElement *e) {
        if (i == 0) {
            STAssertEqualObjects(e.tag, @"square", nil);
            STAssertEqualObjects(e.text, @"Square", nil);
        } else if (i == 1) {
            STAssertEqualObjects(e.tag, @"triangle", nil);
            STAssertEqualObjects(e.text, @"Triangle", nil);
        } else if (i == 2) {
            STAssertEqualObjects(e.tag, @"circle", nil);
            STAssertEqualObjects(e.text, @"Circle", nil);
        }
        
        i++;
    }];
    
    STAssertEquals(i, 3, nil);
}

- (void)testAttributes {
    RXMLElement *rxml = [RXMLElement elementFromXMLString:attributedXML_ encoding:NSUTF8StringEncoding];
    RXMLElement *rxml2 = [rxml copy];
    __block NSInteger i = 0;
    
    [rxml2 iterate:@"*" usingBlock:^(RXMLElement *e) {
        if (i == 0) {
            STAssertEqualObjects([e attribute:@"name"], @"Square", nil);
        } else if (i == 1) {
            STAssertEqualObjects([e attribute:@"name"], @"Triangle", nil);
        } else if (i == 2) {
            STAssertEqualObjects([e attribute:@"name"], @"Circle", nil);
        }
        
        i++;
    }];
    
    STAssertEquals(i, 3, nil);
}

@end
