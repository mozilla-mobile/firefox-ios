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
#import <EarlGrey/EarlGrey.h>

@interface FTROrientationChangeTest : FTRBaseIntegrationTest
@end

@implementation FTROrientationChangeTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Rotated Views"];
}

- (void)testBasicOrientationChange {
  // Test rotating to landscape.
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft errorOrNil:nil];
  GREYAssertEqual([UIDevice currentDevice].orientation, UIDeviceOrientationLandscapeLeft,
                  @"Device orientation should now be left landscape");
  UIApplication *sharedApp = [UIApplication sharedApplication];
  GREYAssertEqual(sharedApp.statusBarOrientation, UIInterfaceOrientationLandscapeRight,
                  @"Interface orientation should now be right landscape");

  // Test rotating to portrait.
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationPortrait errorOrNil:nil];
  GREYAssertEqual([UIDevice currentDevice].orientation, UIDeviceOrientationPortrait,
                  @"Device orientation should now be portrait");
  GREYAssertEqual(sharedApp.statusBarOrientation, UIInterfaceOrientationPortrait,
                  @"Interface orientation should now be portrait");
}

- (void)testRotateToCurrentOrientation {
  UIApplication *sharedApp = [UIApplication sharedApplication];
  UIDeviceOrientation deviceOrientation = (UIDeviceOrientation)sharedApp.statusBarOrientation;
  // We have to rotate device twice to test behavior of rotating to the same deviceOrientation,
  // because device orientation could be unknown, or face up, or face down at this point.
  [EarlGrey rotateDeviceToOrientation:deviceOrientation errorOrNil:nil];
  GREYAssertEqual([UIDevice currentDevice].orientation, deviceOrientation,
                  @"Device orientation should match");
  [EarlGrey rotateDeviceToOrientation:deviceOrientation errorOrNil:nil];
  GREYAssertEqual([UIDevice currentDevice].orientation, deviceOrientation,
                  @"Device orientation should match");
}

- (void)testInteractingWithElementsAfterRotation {
  NSArray *buttonNames = @[ @"Top Left", @"Top Right", @"Bottom Right", @"Bottom Left", @"Center" ];
  NSArray *orientations = @[ @(UIDeviceOrientationLandscapeLeft),
                             @(UIDeviceOrientationPortraitUpsideDown),
                             @(UIDeviceOrientationLandscapeRight),
                             @(UIDeviceOrientationPortrait),
                             @(UIDeviceOrientationFaceUp),
                             @(UIDeviceOrientationFaceDown) ];

  for (NSUInteger i = 0; i < [orientations count]; i++) {
    UIDeviceOrientation orientation = [orientations[i] integerValue];
    [EarlGrey rotateDeviceToOrientation:orientation errorOrNil:nil];
    GREYAssertEqual([UIDevice currentDevice].orientation, orientation,
                    @"Device orientation should match");
    // Tap clear, check if label was reset
    [[EarlGrey selectElementWithMatcher:grey_text(@"Clear")] performAction:grey_tap()];
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"lastTapped")]
        assertWithMatcher:grey_text([NSString stringWithFormat:@"Last tapped: None"])];
    // Each of the buttons, when tapped, execute an action that changes the |lastTapped| UILabel
    // to contain their locations. We tap each button then check if the label actually changed.
    for (NSString *buttonName in buttonNames) {
      [[EarlGrey selectElementWithMatcher:grey_text(buttonName)] performAction:grey_tap()];
      [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"lastTapped")]
          assertWithMatcher:grey_text([NSString stringWithFormat:@"Last tapped: %@", buttonName])];
    }
  }
}

@end
