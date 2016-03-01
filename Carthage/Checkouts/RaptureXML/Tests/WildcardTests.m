//
//  WildcardTests.m
//  RaptureXML
//
//  Created by John Blanco on 9/24/11.
//  Copyright (c) 2011 Rapture In Venice. All rights reserved.
//

#import "RXMLElement.h"

@interface WildcardTests : SenTestCase {
}

@end



@implementation WildcardTests

- (void)testEndingWildcard {
    RXMLElement *rxml = [RXMLElement elementFromXMLFile:@"players.xml"];
    __block NSInteger i;
    
    // count the players and coaches
    i = 0;

    [rxml iterate:@"players.*" usingBlock: ^(RXMLElement *e) {
        i++;
    }];    
    
    STAssertEquals(i, 10, nil);
}

- (void)testMidstreamWildcard {
    RXMLElement *rxml = [RXMLElement elementFromXMLFile:@"players.xml"];
    __block NSInteger i;
    
    // count the tags that have a name
    i = 0;
    
    [rxml iterate:@"players.*.name" usingBlock: ^(RXMLElement *e) {
        i++;
    }];    
    
  //  STAssertEquals(i, 10, nil);

    // count the tags that have a position
    i = 0;
    
    [rxml iterate:@"players.*.position" usingBlock: ^(RXMLElement *e) {
        i++;
    }];    
    
   // STAssertEquals(i, 9, nil);
}

@end
