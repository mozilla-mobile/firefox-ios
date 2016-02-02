//
//  AttributeTests.m
//  RaptureXML
//
//  Created by John Blanco on 9/24/11.
//  Copyright (c) 2011 Rapture In Venice. All rights reserved.
//

#import "RXMLElement.h"

@interface AttributeTests : SenTestCase {
    NSString *attributedXML_;
}

@end

@implementation AttributeTests

- (void)setUp {
    attributedXML_ = @"\
    <shapes count=\"3\" style=\"basic\">\
    <square name=\"Square\" id=\"8\" sideLength=\"5\" />\
    <triangle name=\"Triangle\" style=\"equilateral\" />\
    <circle name=\"Circle\" />\
    </shapes>";
}

- (void)testAttributedText {
    RXMLElement *rxml = [RXMLElement elementFromXMLString:attributedXML_ encoding:NSUTF8StringEncoding];
    NSArray *atts = [rxml attributeNames];
    STAssertEquals(atts.count, 2U, nil);
    STAssertTrue([atts containsObject:@"count"], nil);
    STAssertTrue([atts containsObject:@"style"], nil);

    RXMLElement *squarexml = [rxml child:@"square"];
    atts = [squarexml attributeNames];
    STAssertEquals(atts.count, 3U, nil);
    STAssertTrue([atts containsObject:@"name"], nil);
    STAssertTrue([atts containsObject:@"id"], nil);
    STAssertTrue([atts containsObject:@"sideLength"], nil);
}

@end

