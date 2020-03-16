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

#import "Common/GREYSwizzler.h"

#include <dlfcn.h>
#include <objc/runtime.h>

#import "Common/GREYDefines.h"
#import "Common/GREYFatalAsserts.h"

typedef NS_ENUM(NSUInteger, GREYMethodType) {
  GREYMethodTypeClass,
  GREYMethodTypeInstance
};

#pragma mark - GREYResetter

/**
 *  Utility class to hold original implementation of a method of a class for the purpose of
 *  resetting.
 */
@interface GREYResetter : NSObject

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Designated initializer.
 *
 *  @param originalMethod Method being swizzled
 *  @param originalIMP    Implementation of the method being swizzled
 */
- (instancetype)initWithOriginalMethod:(Method)originalMethod
                originalImplementation:(IMP)originalIMP;

/**
 *  Reset the original method selector to its unmodified/vanilla implementations.
 */
- (void)reset;

@end

@implementation GREYResetter {
  Method _originalMethod;
  IMP _originalIMP;
}

- (instancetype)initWithOriginalMethod:(Method)originalMethod
                originalImplementation:(IMP)originalIMP {
  self = [super init];
  if (self) {
    _originalMethod = originalMethod;
    _originalIMP = originalIMP;
  }
  return self;
}

- (void)reset {
  method_setImplementation(_originalMethod, _originalIMP);
}

@end

#pragma mark - GREYSwizzler

@implementation GREYSwizzler {
  NSMutableDictionary *_resetters;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _resetters = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (BOOL)resetClassMethod:(SEL)methodSelector class:(Class)klass {
  if (!klass || !methodSelector) {
    NSLog(@"Nil Parameter(s) found when swizzling.");
    return NO;
  }

  NSString *key = [[self class] grey_keyForClass:klass
                                        selector:methodSelector
                                            type:GREYMethodTypeClass];
  GREYResetter *resetter = _resetters[key];
  if (resetter) {
    [resetter reset];
    [_resetters removeObjectForKey:key];
    return YES;
  } else {
    NSLog(@"Resetter was nil for class: %@ and class selector: %@",
          NSStringFromClass(klass),
          NSStringFromSelector(methodSelector));
    return NO;
  }
}

- (BOOL)resetInstanceMethod:(SEL)methodSelector class:(Class)klass {
  if (!klass || !methodSelector) {
    NSLog(@"Nil Parameter(s) found when swizzling.");
    return NO;
  }

  NSString *key = [[self class] grey_keyForClass:klass
                                        selector:methodSelector
                                            type:GREYMethodTypeInstance];
  GREYResetter *resetter = _resetters[key];
  if (resetter) {
    [resetter reset];
    [_resetters removeObjectForKey:key];
    return YES;
  } else {
    NSLog(@"Resetter was nil for class: %@ and instance selector: %@",
          NSStringFromClass(klass),
          NSStringFromSelector(methodSelector));
    return NO;
  }
}

- (void)resetAll {
  for (GREYResetter *resetter in [_resetters allValues]) {
    [resetter reset];
  }
  [_resetters removeAllObjects];
}

- (BOOL)swizzleClass:(Class)klass
    replaceClassMethod:(SEL)methodSelector1
            withMethod:(SEL)methodSelector2 {
  if (!klass || !methodSelector1 || !methodSelector2) {
    NSLog(@"Nil Parameter(s) found when swizzling.");
    return NO;
  }

  Method method1 = class_getClassMethod(klass, methodSelector1);
  Method method2 = class_getClassMethod(klass, methodSelector2);
  // Only swizzle if both methods are found.
  if (method1 && method2) {
    // Save the current implementations
    IMP imp1 = method_getImplementation(method1);
    IMP imp2 = method_getImplementation(method2);
    [self grey_saveOriginalMethod:method1
                      originalIMP:imp1
                    originalClass:klass
                   swizzledMethod:method2
                      swizzledIMP:imp2
                    swizzledClass:klass
                       methodType:GREYMethodTypeClass];

    // To add a class method, we need to get the class meta first.
    // http://stackoverflow.com/questions/9377840/how-to-dynamically-add-a-class-method
    Class classMeta = object_getClass(klass);
    if (class_addMethod(classMeta, methodSelector1, imp2, method_getTypeEncoding(method2))) {
      class_replaceMethod(classMeta, methodSelector2, imp1, method_getTypeEncoding(method1));
    } else {
      method_exchangeImplementations(method1, method2);
    }

    return YES;
  } else {
    NSLog(@"Swizzling Method(s) not found while swizzling class %@.", NSStringFromClass(klass));
    return NO;
  }
}

- (BOOL)swizzleClass:(Class)klass
    replaceInstanceMethod:(SEL)methodSelector1
               withMethod:(SEL)methodSelector2 {
  if (!klass || !methodSelector1 || !methodSelector2) {
    NSLog(@"Nil Parameter(s) found when swizzling.");
    return NO;
  }

  Method method1 = class_getInstanceMethod(klass, methodSelector1);
  Method method2 = class_getInstanceMethod(klass, methodSelector2);
  // Only swizzle if both methods are found.
  if (method1 && method2) {
    // Save the current implementations
    IMP imp1 = method_getImplementation(method1);
    IMP imp2 = method_getImplementation(method2);
    [self grey_saveOriginalMethod:method1
                      originalIMP:imp1
                    originalClass:klass
                   swizzledMethod:method2
                      swizzledIMP:imp2
                    swizzledClass:klass
                       methodType:GREYMethodTypeInstance];

    if (class_addMethod(klass, methodSelector1, imp2, method_getTypeEncoding(method2))) {
      class_replaceMethod(klass, methodSelector2, imp1, method_getTypeEncoding(method1));
    } else {
      method_exchangeImplementations(method1, method2);
    }
    return YES;
  } else {
    NSLog(@"Swizzling Method(s) not found while swizzling class %@.", NSStringFromClass(klass));
    return NO;
  }
}

- (BOOL)swizzleClass:(Class)klass
               addInstanceMethod:(SEL)addSelector
              withImplementation:(IMP)addIMP
    andReplaceWithInstanceMethod:(SEL)instanceSelector {
  if (!klass || !addSelector || !addIMP || !instanceSelector) {
    NSLog(@"Nil Parameter(s) found when swizzling.");
    return NO;
  }

  // Check for whether an implementation forwards to a nil selector or not.
  // This is caused when you use the incorrect methodForSelector call in order
  // to get the implementation for a selector.
  void *messageForwardingIMP = dlsym(RTLD_DEFAULT, "_objc_msgForward");
  if (addIMP == messageForwardingIMP) {
    NSLog(@"Wrong Type of Implementation obtained for selector %@", NSStringFromClass(klass));
    return NO;
  }

  Method instanceMethod = class_getInstanceMethod(klass, instanceSelector);
  if (instanceMethod) {
    struct objc_method_description *desc = method_getDescription(instanceMethod);
    if (!desc || desc->name == NULL) {
      NSLog(@"Failed to get method description.");
      return NO;
    }

    if (!class_addMethod(klass, addSelector, addIMP, desc->types)) {
      NSLog(@"Failed to add class method.");
      return NO;
    }
    return [self swizzleClass:klass replaceInstanceMethod:instanceSelector withMethod:addSelector];
  } else {
    NSLog(@"Instance method: %@ does not exist in the class %@.",
          NSStringFromSelector(instanceSelector), NSStringFromClass(klass));
    return NO;
  }
}

#pragma mark - Private

+ (NSString *)grey_keyForClass:(Class)klass selector:(SEL)sel type:(GREYMethodType)methodType {
  GREYFatalAssert(klass);
  GREYFatalAssert(sel);

  NSString *methodTypeString;
  if (methodType == GREYMethodTypeClass) {
    methodTypeString = @"+";
  } else {
    methodTypeString = @"-";
  }
  return [NSString stringWithFormat:@"%@[%@ %@]",
                                    methodTypeString,
                                    NSStringFromClass(klass),
                                    NSStringFromSelector(sel)];
}

- (void)grey_saveOriginalMethod:(Method)originalMethod
                    originalIMP:(IMP)originalIMP
                  originalClass:(Class)originalClass
                 swizzledMethod:(Method)swizzledMethod
                    swizzledIMP:(IMP)swizzledIMP
                  swizzledClass:(Class)swizzledClass
                     methodType:(GREYMethodType)methodType {
  GREYFatalAssert(originalMethod);
  GREYFatalAssert(originalIMP);
  GREYFatalAssert(originalClass);
  GREYFatalAssert(swizzledMethod);
  GREYFatalAssert(swizzledIMP);

  NSString *keyForOriginal = [[self class] grey_keyForClass:originalClass
                                                     selector:method_getName(originalMethod)
                                                       type:methodType];
  if (!_resetters[keyForOriginal]) {
    GREYResetter *resetter = [[GREYResetter alloc] initWithOriginalMethod:originalMethod
                                                   originalImplementation:originalIMP];
    _resetters[keyForOriginal] = resetter;
  }

  NSString *keyForSwizzled = [[self class] grey_keyForClass:swizzledClass
                                                     selector:method_getName(swizzledMethod)
                                                       type:methodType];
  if (!_resetters[keyForSwizzled]) {
    GREYResetter *resetter = [[GREYResetter alloc] initWithOriginalMethod:swizzledMethod
                                                   originalImplementation:swizzledIMP];
    _resetters[keyForSwizzled] = resetter;
  }
}

@end
