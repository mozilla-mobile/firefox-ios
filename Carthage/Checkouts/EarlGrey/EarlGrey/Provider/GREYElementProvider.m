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

#import "Provider/GREYElementProvider.h"

#include <objc/runtime.h>

#import "Assertion/GREYAssertionDefines.h"
#import "Common/GREYConstants.h"
#import "Common/GREYDefines.h"
#import "Common/GREYFatalAsserts.h"
#import "Provider/GREYDataEnumerator.h"
#import "Traversal/GREYTraversalBFS.h"

@implementation GREYElementProvider {
  id<GREYProvider> _rootProvider;
  NSArray *_rootElements;
  NSArray *_elements;
}

+ (instancetype)providerWithElements:(NSArray *)elements {
  return [[GREYElementProvider alloc] initWithElements:elements];
}

+ (instancetype)providerWithRootElements:(NSArray *)rootElements {
  return [[GREYElementProvider alloc] initWithRootElements:rootElements];
}

+ (instancetype)providerWithRootProvider:(id<GREYProvider>)rootProvider {
  return [[GREYElementProvider alloc] initWithRootProvider:rootProvider];
}

- (instancetype)initWithElements:(NSArray *)elements {
  return [self initWithRootProvider:nil orRootElements:nil orElements:elements];
}

- (instancetype)initWithRootElements:(NSArray *)rootElements {
  return [self initWithRootProvider:nil orRootElements:rootElements orElements:nil];
}

- (instancetype)initWithRootProvider:(id<GREYProvider>)rootProvider {
  return [self initWithRootProvider:rootProvider orRootElements:nil orElements:nil];
}

- (instancetype)initWithRootProvider:(id<GREYProvider>)rootProvider
                      orRootElements:(NSArray *)rootElements
                          orElements:(NSArray *)elements {
  GREYFatalAssertWithMessage((rootProvider && !rootElements && !elements) ||
                             (!rootProvider && rootElements && !elements) ||
                             (!rootProvider && !rootElements && elements),
                             @"Must provide exactly one non-nil parameter out of all the "
                             @"parameters accepted by this initializer.");
  self = [super init];
  if (self) {
    _rootProvider = rootProvider;
    _rootElements = [rootElements copy];
    _elements = [elements copy];
  }
  return self;
}

#pragma mark - GREYProvider

- (NSEnumerator *)dataEnumerator {
  GREYFatalAssertMainThread();

  NSEnumerator *enumerator;
  if (_rootElements) {
    enumerator = [_rootElements objectEnumerator];
  } else if (_rootProvider) {
    enumerator = [_rootProvider dataEnumerator];
  } else {
    enumerator = [_elements objectEnumerator];
  }

  NSObject *userInfo = [[NSObject alloc] init];
  return [[GREYDataEnumerator alloc] initWithUserInfo:userInfo block:^id(NSObject *userinfo) {
    GREYTraversalBFS *traversal = objc_getAssociatedObject(userInfo, @selector(dataEnumerator));
    id objToReturn = [traversal nextObject];
    if (!objToReturn) {
      id nextElement = [enumerator nextObject];
      if (nextElement) {
        // The GREYTraversalBFS object does all the hierarchy unrolling. In other words, the element
        // provider relies on the GREYTraversalBFS object for its needs.
        traversal = [GREYTraversalBFS hierarchyForElementWithBFSTraversal:nextElement];
        objc_setAssociatedObject(userInfo,
                                 @selector(dataEnumerator),
                                 traversal,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objToReturn = [traversal nextObject];
      }
    }
    return objToReturn;
  }];
}

@end
