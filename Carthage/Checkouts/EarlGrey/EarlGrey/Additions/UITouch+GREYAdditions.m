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

#import "Additions/UITouch+GREYAdditions.h"

#import "Additions/CGGeometry+GREYAdditions.h"
#import "Common/GREYAppleInternals.h"
#import "Common/GREYThrowDefines.h"

@implementation UITouch (GREYAdditions)

- (id)initAtPoint:(CGPoint)point relativeToWindow:(UIWindow *)window {
  GREYThrowOnNilParameter(window);

  point = CGPointAfterRemovingFractionalPixels(point);

  self = [super init];
  if (self) {
    [self setTapCount:1];
    [self setIsTap:YES];
    [self setPhase:UITouchPhaseBegan];
    [self setWindow:window];
    [self _setLocationInWindow:point resetPrevious:YES];
    [self setView:[window hitTest:point withEvent:nil]];
    [self _setIsFirstTouchForView:YES];
    [self setTimestamp:[[NSProcessInfo processInfo] systemUptime]];
  }
  return self;
}

@end
