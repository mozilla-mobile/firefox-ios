//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "FTRBaseIntegrationTest.h"
#import "FTRImageViewController.h"
#import <EarlGrey/EarlGrey.h>

@interface FTRPinchViewTest : FTRBaseIntegrationTest
@end

@implementation FTRPinchViewTest {
  // Image view frame before pinch action is callled.
  CGRect _imageViewFrameBeforePinch;
  // Image view frame after pinch action is callled.
  CGRect _imageViewFrameAfterPinch;
}

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Pinch Tests"];
}

- (void)testImageViewFrameSizeOnZoomingFastOutward {
  _imageViewFrameBeforePinch = [self ftr_imageViewFrame];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Image View")]
      performAction:grey_pinchFastInDirectionAndAngle(kGREYPinchDirectionOutward,
                                                      kGREYPinchAngleDefault)];
  _imageViewFrameAfterPinch = [self ftr_imageViewFrame];
  [self ftr_assertThatInitialSize:_imageViewFrameBeforePinch.size
                     andFinalSize:_imageViewFrameAfterPinch.size
                       areOrdered:NSOrderedAscending];
}

- (void)testImageViewFrameSizeOnZoomingSlowOutward {
  _imageViewFrameBeforePinch = [self ftr_imageViewFrame];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Image View")]
      performAction:grey_pinchSlowInDirectionAndAngle(kGREYPinchDirectionOutward,
                                                      kGREYPinchAngleDefault)];
  _imageViewFrameAfterPinch = [self ftr_imageViewFrame];
  [self ftr_assertThatInitialSize:_imageViewFrameBeforePinch.size
                     andFinalSize:_imageViewFrameAfterPinch.size
                       areOrdered:NSOrderedAscending];
}

- (void)testImageViewFrameSizeOnZoomingFastInward {
  _imageViewFrameBeforePinch = [self ftr_imageViewFrame];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Image View")]
      performAction:grey_pinchFastInDirectionAndAngle(kGREYPinchDirectionInward,
                                                      kGREYPinchAngleDefault)];
  _imageViewFrameAfterPinch = [self ftr_imageViewFrame];
  [self ftr_assertThatInitialSize:_imageViewFrameBeforePinch.size
                     andFinalSize:_imageViewFrameAfterPinch.size
                       areOrdered:NSOrderedDescending];
}

- (void)testImageViewFrameSizeOnZoomingSlowInward {
  _imageViewFrameBeforePinch = [self ftr_imageViewFrame];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Image View")]
      performAction:grey_pinchFastInDirectionAndAngle(kGREYPinchDirectionInward,
                                                      kGREYPinchAngleDefault)];
  _imageViewFrameAfterPinch = [self ftr_imageViewFrame];
  [self ftr_assertThatInitialSize:_imageViewFrameBeforePinch.size
                     andFinalSize:_imageViewFrameAfterPinch.size
                       areOrdered:NSOrderedDescending];
}

- (void)testImageViewFrameSizeOnZoomingInwardWithZeroAngle {
  double defaultPinchAngle = 0;
  _imageViewFrameBeforePinch = [self ftr_imageViewFrame];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Image View")]
      performAction:grey_pinchSlowInDirectionAndAngle(kGREYPinchDirectionInward,
                                                      defaultPinchAngle)];
  _imageViewFrameAfterPinch = [self ftr_imageViewFrame];
  [self ftr_assertThatInitialSize:_imageViewFrameBeforePinch.size
                     andFinalSize:_imageViewFrameAfterPinch.size
                       areOrdered:NSOrderedDescending];
}

- (void)testImageViewFrameSizeOnZoomingInwardWithNegativeAngle {
  double defaultPinchAngle = (-90.0 * M_PI / 180.0);
  _imageViewFrameBeforePinch = [self ftr_imageViewFrame];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Image View")]
      performAction:grey_pinchSlowInDirectionAndAngle(kGREYPinchDirectionInward,
                                                      defaultPinchAngle)];
  _imageViewFrameAfterPinch = [self ftr_imageViewFrame];
  [self ftr_assertThatInitialSize:_imageViewFrameBeforePinch.size
                     andFinalSize:_imageViewFrameAfterPinch.size
                       areOrdered:NSOrderedDescending];
}

- (void)testImageViewFrameSizeOnZoomingInwardWithAngle {
  double defaultPinchAngle = (30.0 * M_PI / 180.0);
  _imageViewFrameBeforePinch = [self ftr_imageViewFrame];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Image View")]
      performAction:grey_pinchFastInDirectionAndAngle(kGREYPinchDirectionInward,
                                                      defaultPinchAngle)];
  _imageViewFrameAfterPinch = [self ftr_imageViewFrame];
  [self ftr_assertThatInitialSize:_imageViewFrameBeforePinch.size
                     andFinalSize:_imageViewFrameAfterPinch.size
                       areOrdered:NSOrderedDescending];
}

- (void)testImageViewFrameSizeOnZoomingOutwardWithAngle {
  double defaultPinchAngle = (180.0 * M_PI / 180.0);
  _imageViewFrameBeforePinch = [self ftr_imageViewFrame];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Image View")]
      performAction:grey_pinchFastInDirectionAndAngle(kGREYPinchDirectionOutward,
                                                      defaultPinchAngle)];
  _imageViewFrameAfterPinch = [self ftr_imageViewFrame];
  [self ftr_assertThatInitialSize:_imageViewFrameBeforePinch.size
                     andFinalSize:_imageViewFrameAfterPinch.size
                       areOrdered:NSOrderedAscending];
}

#pragma mark - Private

/**
 *  Asserts that the given initial size and final size are in the given order.
 */
- (void)ftr_assertThatInitialSize:(CGSize)initialSize
                     andFinalSize:(CGSize)finalSize
                       areOrdered:(NSComparisonResult)expectedOrder {
  BOOL success;
  NSString *expectedOrderString;
  switch (expectedOrder) {
    case NSOrderedSame:
      success = initialSize.width == finalSize.width && initialSize.height == finalSize.height;
      expectedOrderString = @"equal";
      break;

    case NSOrderedAscending:
      success = initialSize.width < finalSize.width && initialSize.height < finalSize.height;
      expectedOrderString = @"in increasing order";
      break;

    case NSOrderedDescending:
      success = initialSize.width > finalSize.width && initialSize.height > finalSize.height;
      expectedOrderString = @"in decreasing order";
      break;

    default:
      GREYAssert(NO, @"Unknown comparison result was expected %d", (int)expectedOrder);
  }

  GREYAssert(success, @"Image sizes before pinch - %@ and after pinch - %@ must be %@.",
             NSStringFromCGSize(initialSize), NSStringFromCGSize(finalSize), expectedOrderString);
}

/**
 *  Returns the image view controller frame.
 */
- (CGRect)ftr_imageViewFrame {
  UIWindow *delegateWindow = [UIApplication sharedApplication].delegate.window;
  UINavigationController *rootNC = (UINavigationController *)[delegateWindow rootViewController];

  FTRImageViewController *imageVC = nil;
  for (UIViewController *controller in rootNC.viewControllers) {
    if ([controller isKindOfClass:[FTRImageViewController class]]) {
      imageVC = (FTRImageViewController *)controller;
    }
  }
  return imageVC.view.frame;
}

@end
