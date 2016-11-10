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

- (void)test_majorSwipeDisplacement_ScreenSizeEqualTo320Pts_Returns200Pts {
    CGRect iPhone5PortraitBounds = CGRectMake(0, 0, 320, 468);
    CustomBoundsUIScreen *screen = [[CustomBoundsUIScreen alloc] initWithBounds:iPhone5PortraitBounds];
    
    CGFloat actual = screen.majorSwipeDisplacement;
    
    XCTAssertEqual(200, actual);
}

- (void)test_majorSwipeDisplacement_ScreenSizeEqualTo414Pts_Returns258Point75Pts {
    CGRect iPhone5PortraitBounds = CGRectMake(0, 0, 414, 736);
    CustomBoundsUIScreen *screen = [[CustomBoundsUIScreen alloc] initWithBounds:iPhone5PortraitBounds];
    
    CGFloat actual = screen.majorSwipeDisplacement;
    
    XCTAssertEqual(258.75, actual);
}

@end
