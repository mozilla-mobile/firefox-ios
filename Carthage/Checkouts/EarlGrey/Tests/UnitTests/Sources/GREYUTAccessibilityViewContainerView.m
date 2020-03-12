//
// Copyright 2017 Google Inc.
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

#import "GREYUTAccessibilityViewContainerView.h"

@implementation GREYUTAccessibilityViewContainerView

@synthesize accessibleElements;

- (id)initWithImage:(UIImage *)image {
  return [self initWithElements:@[ image ]];
}

- (id)initWithElements:(NSArray *)elements {
  self = [super init];
  if (self) {
    accessibleElements = [[NSMutableArray alloc] init];
    [accessibleElements addObjectsFromArray:elements];
  }
  return(self);
}

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

#pragma mark - UIAccessibilityContainer Protocol

- (NSInteger)accessibilityElementCount {
  return (NSInteger)[[self accessibleElements] count];
}

- (id)accessibilityElementAtIndex:(NSInteger)index {
  return [[self accessibleElements] objectAtIndex:(NSUInteger)index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
  return (NSInteger)[[self accessibleElements] indexOfObject:element];
}

@end
