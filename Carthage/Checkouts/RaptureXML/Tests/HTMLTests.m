//
//  HTMLTests.m
//  RaptureXML
//
//  Created by Francis Chong on 22/3/13.
//  Copyright (c) 2013 Rapture In Venice. All rights reserved.
//

#import "RXMLElement.h"

@interface HTMLTests : SenTestCase {
    NSString *simpleHTML_;
}
@end

@implementation HTMLTests

- (void)setUp {
    simpleHTML_ = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\
    <!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\"\
    \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">\
    <html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" >\
    <head>\
    <title>Minimal XHTML 1.1 Document</title>\
    </head>\
    <body>\
    <p>This is a minimal <a href=\"http://www.w3.org/TR/xhtml11\">XHTML 1.1</a> document.</p>\
    </body>\
    </html>";
}

- (void)testBasicXHTML {
    RXMLElement *html = [RXMLElement elementFromHTMLString:simpleHTML_ encoding:NSUTF8StringEncoding];
    NSArray *atts = [html attributeNames];
    STAssertEquals(atts.count, 2U, nil);
    
    NSArray* children = [html childrenWithRootXPath:@"//html/body/p"];
    STAssertTrue([children count] > 0, nil);

    RXMLElement* child = [children objectAtIndex:0];
    NSLog(@"content: %@", [child text]);
    STAssertEqualObjects([child text], @"This is a minimal XHTML 1.1 document.", nil);
}

-(void) testHtmlEntity {
    RXMLElement* html = [RXMLElement elementFromHTMLString:@"<p>Don&apos;t say &quot;lazy&quot;</p>" encoding:NSUTF8StringEncoding];
    STAssertEqualObjects([html text], @"Don't say \"lazy\"", nil);
}

-(void) testFixBrokenHtml {
    RXMLElement* html = [RXMLElement elementFromHTMLString:@"<p><b>Test</p> Broken HTML</b>" encoding:NSUTF8StringEncoding];
    STAssertEqualObjects([html text], @"Test Broken HTML", nil);
    STAssertEqualObjects([html xml], @"<html><body><p><b>Test</b></p> Broken HTML</body></html>", nil);
}

@end
