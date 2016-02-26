//
//  ErrorTests.m
//  RaptureXML
//
//  Created by John Blanco on 9/24/11.
//  Copyright (c) 2011 Rapture In Venice. All rights reserved.
//

#import "RXMLElement.h"

@interface ErrorTests : SenTestCase {
    NSString *simplifiedXML_;
    NSString *badXML_;
}

@end



@implementation ErrorTests

- (void)setUp {
    simplifiedXML_ = @"\
        <shapes>\
            <square>Square</square>\
            <triangle>Triangle</triangle>\
            <circle>Circle</circle>\
        </shapes>";
    badXML_ = @"</xml";
}

- (void)testBadXML {
    RXMLElement *rxml = [RXMLElement elementFromXMLString:badXML_ encoding:NSUTF8StringEncoding];
    STAssertFalse([rxml isValid], nil);
}

- (void)testMissingTag {
    RXMLElement *rxml = [RXMLElement elementFromXMLString:simplifiedXML_ encoding:NSUTF8StringEncoding];
    RXMLElement *hexagon = [rxml child:@"hexagon"];
    
    STAssertNil(hexagon, nil);
}

- (void)testMissingTagIteration {
    RXMLElement *rxml = [RXMLElement elementFromXMLString:simplifiedXML_ encoding:NSUTF8StringEncoding];
    __block NSInteger i = 0;
    
    [rxml iterate:@"hexagon" usingBlock:^(RXMLElement *e) {
        i++;
    }];
     
    STAssertEquals(i, 0, nil);
}

- (void)testMissingAttribute {
    RXMLElement *rxml = [RXMLElement elementFromXMLString:simplifiedXML_ encoding:NSUTF8StringEncoding];
    NSString *missingName = [rxml attribute:@"name"];
    
    STAssertNil(missingName, nil);
}

@end
