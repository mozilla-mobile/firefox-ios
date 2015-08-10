//
//  SimpleTests.m
//  RaptureXML
//
//  Created by John Blanco on 9/24/11.
//  Copyright (c) 2011 Rapture In Venice. All rights reserved.
//

#import "RXMLElement.h"

@interface SimpleTests : SenTestCase {
    NSString *simplifiedXML_;
    NSString *attributedXML_;
    NSString *interruptedTextXML_;
    NSString *cdataXML_;
    NSString *treeXML_;
}

@end



@implementation SimpleTests

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
    STAssertEqualObjects(rxml.text, @"thisisinterruptedtext", nil);
}

- (void)testCDataText {
    RXMLElement *rxml = [RXMLElement elementFromXMLString:cdataXML_ encoding:NSUTF8StringEncoding];
    STAssertEqualObjects(rxml.text, @"thisiscdata", nil);
}

- (void)testTags {
    RXMLElement *rxml = [RXMLElement elementFromXMLString:simplifiedXML_ encoding:NSUTF8StringEncoding];
    __block NSInteger i = 0;
    
    [rxml iterate:@"*" usingBlock:^(RXMLElement *e) {
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
    __block NSInteger i = 0;
    
    [rxml iterate:@"*" usingBlock:^(RXMLElement *e) {
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

-(void) testInnerXml {    
    treeXML_ = @"<data>\
    <shapes><circle>Circle</circle></shapes>\
    <colors>TEST<rgb code=\"0,0,0\">Black<annotation>default color</annotation></rgb></colors>\
</data>";

    RXMLElement *rxml = [RXMLElement elementFromXMLString:treeXML_ encoding:NSUTF8StringEncoding];
    RXMLElement* shapes = [rxml child:@"shapes"];
    STAssertEqualObjects(shapes.xml, @"<shapes><circle>Circle</circle></shapes>", nil);
    STAssertEqualObjects(shapes.innerXml, @"<circle>Circle</circle>", nil);

    RXMLElement* colors = [rxml child:@"colors"];
    STAssertEqualObjects(colors.xml, @"<colors>TEST<rgb code=\"0,0,0\">Black<annotation>default color</annotation></rgb></colors>", nil);
    STAssertEqualObjects(colors.innerXml, @"TEST<rgb code=\"0,0,0\">Black<annotation>default color</annotation></rgb>", nil);
    
    RXMLElement *cdata = [RXMLElement elementFromXMLString:cdataXML_ encoding:NSUTF8StringEncoding];
    STAssertEqualObjects(cdata.xml, @"<top><![CDATA[thisiscdata]]></top>", nil);
    STAssertEqualObjects(cdata.innerXml, @"<![CDATA[thisiscdata]]>", nil);
}

@end
