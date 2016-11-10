//
//  UIApplicationKIFAdditionsTests.m
//  KIF
//
//  Created by Lucien Constantino on 10/12/15.
//
//

#import <KIF/KIF.h>
#import "UIApplication-KIFAdditions.h"

@interface UIApplication ()
- (NSString *)imageNameForFile:(NSString *)filename lineNumber:(NSUInteger)lineNumber description:(NSString *)description;
@end

@interface UIApplicationKIFAdditionsTests : KIFTestCase

@end

@implementation UIApplicationKIFAdditionsTests

- (void)setUp {
    [super setUp];
    XCTAssertTrue([UIApplication instancesRespondToSelector:@selector(imageNameForFile:lineNumber:description:)]);
}

- (void)testScreenshotImageName {
    
    NSString *filename1 = @"screenshots/KIF";
    NSUInteger lineNumber1 = 123;
    NSString *description1 = @"a screenshot";
    
    NSString *imageName1 = [[UIApplication sharedApplication] imageNameForFile:filename1
                                                                    lineNumber:lineNumber1
                                                                   description:description1];
    XCTAssertEqualObjects(imageName1, @"KIF, line 123, a screenshot");
    
    NSString *filename2 = @"screenshots/KIF";
    NSUInteger lineNumber2 = 123;
    NSString *description2 = nil;
    
    NSString *imageName2 = [[UIApplication sharedApplication] imageNameForFile:filename2
                                                                    lineNumber:lineNumber2
                                                                   description:description2];
    XCTAssertEqualObjects(imageName2, @"KIF, line 123");
    
    NSString *filename3 = @"screenshots/KIF";
    NSUInteger lineNumber3 = 0;
    NSString *description3 = nil;
    
    NSString *imageName3 = [[UIApplication sharedApplication] imageNameForFile:filename3
                                                                    lineNumber:lineNumber3
                                                                   description:description3];
    XCTAssertEqualObjects(imageName3, @"KIF");
    
    NSString *filename4 = @"screenshots/KIF";
    NSUInteger lineNumber4 = 0;
    NSString *description4 = @"a screenshot";
    
    NSString *imageName4 = [[UIApplication sharedApplication] imageNameForFile:filename4
                                                                    lineNumber:lineNumber4
                                                                   description:description4];
    XCTAssertEqualObjects(imageName4, @"KIF, a screenshot");
    
    NSString *filename5 = nil;
    NSUInteger lineNumber5 = 123;
    NSString *description5 = @"a screenshot";
    
    NSString *imageName5 = [[UIApplication sharedApplication] imageNameForFile:filename5
                                                                    lineNumber:lineNumber5
                                                                   description:description5];
    XCTAssertNil(imageName5);
}

@end
