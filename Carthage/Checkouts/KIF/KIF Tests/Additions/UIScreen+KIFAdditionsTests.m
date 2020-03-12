//
//  UIScreen+KIFAdditionsTests.m
//  KIF
//
//  Created by Steven King on 25/02/2016.
//
//

#import <XCTest/XCTest.h>
#import "UIScreen+KIFAdditions.h"

@interface CustomBoundsUIScreen : UIScreen

@property (nonatomic, readonly) CGRect bounds;

@end

@implementation CustomBoundsUIScreen {
    CGRect _bounds;
}

- (instancetype)initWithBounds:(CGRect)bounds {
    if (self = [super init]) {
        _bounds = bounds;
    }
    return self;
}

- (CGRect)bounds {
    return _bounds;
}

@end

@interface UIScreen_KIFAdditionsTests : XCTestCase

@end

@implementation UIScreen_KIFAdditionsTests

- (void)test_majorSwipeDisplacement_ScreenSizeEqualTo320Pts_Returns160Pts {
    CGRect iPhone5PortraitBounds = CGRectMake(0, 0, 320, 568);
    CustomBoundsUIScreen *screen = [[CustomBoundsUIScreen alloc] initWithBounds:iPhone5PortraitBounds];
    
    CGFloat actual = screen.majorSwipeDisplacement;
    
    XCTAssertEqual(160, actual);
}

- (void)test_majorSwipeDisplacement_ScreenSizeEqualTo414Pts_Returns207Pts {
    CGRect iPhone6PlusPortraitBounds = CGRectMake(0, 0, 414, 736);
    CustomBoundsUIScreen *screen = [[CustomBoundsUIScreen alloc] initWithBounds:iPhone6PlusPortraitBounds];
    
    CGFloat actual = screen.majorSwipeDisplacement;
    
    XCTAssertEqual(207, actual);
}

@end
