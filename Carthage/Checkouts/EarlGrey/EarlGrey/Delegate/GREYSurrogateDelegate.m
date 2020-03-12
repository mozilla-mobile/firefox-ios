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

#import "Delegate/GREYSurrogateDelegate.h"

#import "Common/GREYDefines.h"

@interface GREYSurrogateDelegate()
/**
 *  Original delegate being proxied.
 */
@property(weak, nonatomic, readwrite) id weakOriginalDelegate;
/**
 *  Strong Original delegate being proxied.
 */
@property(nonatomic, readwrite) id strongOriginalDelegate;
@end

@implementation GREYSurrogateDelegate {
  /**
   *  Indicates whether the original delegate is held weakly or strongly.
   */
  BOOL _isWeak;
}

- (instancetype)initWithOriginalDelegate:(id)originalDelegate isWeak:(BOOL)shouldBeWeak {
  self = [super init];
  if (self) {
    if (shouldBeWeak) {
      self.weakOriginalDelegate = originalDelegate;
    } else {
      self.strongOriginalDelegate = originalDelegate;
    }
    _isWeak = shouldBeWeak;
  }
  return self;
}

#pragma mark - Message forwarding

- (id)forwardingTargetForSelector:(SEL)aSelector {
  return self.originalDelegate;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
  return [super respondsToSelector:aSelector]
      || [self.originalDelegate respondsToSelector:aSelector];
}

- (BOOL)isKindOfClass:(Class)aClass {
  return [super isKindOfClass:aClass]
      || [self.originalDelegate isKindOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
  return [super conformsToProtocol:aProtocol]
      || [self.originalDelegate conformsToProtocol:aProtocol];
}

- (id)originalDelegate {
  return _isWeak ? self.weakOriginalDelegate : self.strongOriginalDelegate;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
  NSMethodSignature *superMethodSignatureForSelector = [super methodSignatureForSelector:aSelector];
  NSMethodSignature *proxyMethodSignatureForSelector =
      [[self originalDelegate] methodSignatureForSelector:aSelector];
  if (proxyMethodSignatureForSelector) {
    return proxyMethodSignatureForSelector;
  } else if (superMethodSignatureForSelector) {
    return superMethodSignatureForSelector;
  } else {
    return nil;
  }
}

@end
