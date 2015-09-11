//
//  TextConversionTests.m
//  RaptureXML
//
//  Created by John Blanco on 9/24/11.
//  Copyright (c) 2011 Rapture In Venice. All rights reserved.
//

#import "RXMLElement.h"

@interface TextConversionTests : SenTestCase {
    NSString *simplifiedXML_;
    NSString *attributedXML_;
}

@end



@implementation TextConversionTests

- (void)setUp {
    simplifiedXML_ = @"\
        <shapes>\
            <square>\
                <id>1</id>\
                <name>Square</name>\
            </square>\
            <triangle>\
                <id>2.5</id>\
                <name>Triangle</name>\
            </triangle>\
        </shapes>";
    
    attributedXML_ = @"\
        <shapes>\
            <square id=\"1\">\
                <name>Square</name>\
            </square>\
            <triangle id=\"2.5\">\
                <name>Triangle</name>\
            </triangle>\
        </shapes>";
}

- (void)testIntTags {
    RXMLElement *rxml = [RXMLElement elementFromXMLString:simplifiedXML_ encoding:NSUTF8StringEncoding];
    __block NSInteger i = 0;
    
    [rxml iterate:@"*" usingBlock:^(RXMLElement *e) {
        if (i == 0) {
            STAssertEquals([e child:@"id"].textAsInt, 1, nil);
        } else if (i == 1) {
            STAssertEqualsWithAccuracy([e child:@"id"].textAsDouble, 2.5, 0.01, nil);
        }
        
        i++;
    }];
}

- (void)testIntAttributes {
    RXMLElement *rxml = [RXMLElement elementFromXMLString:attributedXML_ encoding:NSUTF8StringEncoding];
    __block NSInteger i = 0;
    
    [rxml iterate:@"*" usingBlock:^(RXMLElement *e) {
        if (i == 0) {
            STAssertEquals([e attributeAsInt:@"id"], 1, nil);
        } else if (i == 1) {
            STAssertEqualsWithAccuracy([e attributeAsDouble:@"id"], 2.5, 0.01, nil);
        } else if (i == 2) {
            STAssertEquals([e attributeAsInt:@"id"], 3, nil);
        }
        
        i++;
    }];
}

@end
