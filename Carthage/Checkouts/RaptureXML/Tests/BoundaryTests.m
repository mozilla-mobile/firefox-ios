//
//  BoundaryTests.m
//  RaptureXML
//
//  Created by John Blanco on 9/24/11.
//  Copyright (c) 2011 Rapture In Venice. All rights reserved.
//

#import "RXMLElement.h"

@interface BoundaryTests : SenTestCase {
    NSString *emptyXML_;
    NSString *emptyTopTagXML_;
    NSString *childXML_;
    NSString *childrenXML_;
    NSString *attributeXML_;
    NSString *namespaceXML_;
}

@end



@implementation BoundaryTests

- (void)setUp {
    emptyXML_ = @"";
    emptyTopTagXML_ = @"<top></top>";
    childXML_ = @"<top><empty_child></empty_child><text_child>foo</text_child></top>";
    childrenXML_ = @"<top><child></child><child></child><child></child></top>";
    attributeXML_ = @"<top foo=\"bar\"></top>";
    namespaceXML_ = @"<ns:top xmlns:ns=\"*\" ns:foo=\"bar\" ns:one=\"1\"><ns:text>something</ns:text></ns:top>";
}

- (void)testEmptyXML {
    RXMLElement *rxml = [RXMLElement elementFromXMLString:emptyXML_ encoding:NSUTF8StringEncoding];
    STAssertFalse(rxml.isValid, nil);
}

- (void)testEmptyTopTagXML {
    RXMLElement *rxml = [RXMLElement elementFromXMLString:emptyTopTagXML_ encoding:NSUTF8StringEncoding];
    STAssertTrue(rxml.isValid, nil);
    STAssertEqualObjects(rxml.text, @"", nil);
    STAssertEqualObjects([rxml childrenWithRootXPath:@"*"], [NSArray array], nil);
}

- (void)testAttribute {
    RXMLElement *rxml = [RXMLElement elementFromXMLString:attributeXML_ encoding:NSUTF8StringEncoding];
    STAssertTrue(rxml.isValid, nil);
    STAssertEqualObjects([rxml attribute:@"foo"], @"bar", nil);
}

- (void)testNamespaceAttribute {
    RXMLElement *rxml = [RXMLElement elementFromXMLString:namespaceXML_ encoding:NSUTF8StringEncoding];
    STAssertTrue(rxml.isValid, nil);
    STAssertEqualObjects([rxml attribute:@"foo" inNamespace:@"*"], @"bar", nil);
    STAssertEquals([rxml attributeAsInt:@"one" inNamespace:@"*"], 1, nil);
}

- (void)testChild {
    RXMLElement *rxml = [RXMLElement elementFromXMLString:childXML_ encoding:NSUTF8StringEncoding];
    STAssertTrue(rxml.isValid, nil);
    STAssertEqualObjects([rxml child:@"empty_child"].text, @"", nil);
    STAssertEqualObjects([rxml child:@"text_child"].text, @"foo", nil);
}

- (void)testNamespaceChild {
    RXMLElement *rxml = [RXMLElement elementFromXMLString:namespaceXML_ encoding:NSUTF8StringEncoding];
    STAssertTrue(rxml.isValid, nil);
    STAssertEqualObjects([rxml child:@"text" inNamespace:@"*"].text, @"something", nil);
}

- (void)testChildren {
    RXMLElement *rxml = [RXMLElement elementFromXMLString:childrenXML_ encoding:NSUTF8StringEncoding];
    STAssertTrue(rxml.isValid, nil);
    STAssertEquals([rxml children:@"child"].count, 3U, nil);
}

- (void)testNamespaceChildren {
    RXMLElement *rxml = [RXMLElement elementFromXMLString:namespaceXML_ encoding:NSUTF8StringEncoding];
    STAssertTrue(rxml.isValid, nil);
    STAssertEquals([rxml children:@"text" inNamespace:@"*"].count, 1U, nil);
}

@end
