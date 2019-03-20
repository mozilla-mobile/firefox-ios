// JRSwizzle.h semver:1.0
//   Copyright (c) 2007-2011 Jonathan 'Wolf' Rentzsch: http://rentzsch.com
//   Some rights reserved: http://opensource.org/licenses/MIT
//   https://github.com/rentzsch/jrswizzle

#import <Foundation/Foundation.h>

#define LP_SWIZZLE_DECLARE \
    IMP originalMethod; \
    BOOL isSuper; \
    static NSMapTable *currentClasses;

#define LP_SWIZZLE_GET_IMPLEMENTING_CLASS(_method, _isSuper) {\
    if (currentClasses == nil) { \
        currentClasses = [NSMapTable weakToStrongObjectsMapTable]; \
    } \
    /* If self is in currentViewControllerSet, this is a "super" viewWillAppear call from somewhere \
    // up the class hierarchy ancestor chain. */ \
    Class currentClass = [currentClasses objectForKey:self]; \
    if (!currentClass) { \
        currentClass = [self class]; \
        _isSuper = NO; \
    } else { \
        _isSuper = YES; \
    } \
    Class implementingClass = [LPSwizzle originalImplementingClassForInstanceMethod:_cmd forClass:currentClass]; \
    [currentClasses setObject:class_getSuperclass(implementingClass) forKey:self]; \
    _method = [LPSwizzle originalImplementationForInstanceMethod:_cmd forClass:implementingClass]; \
}

#define LP_SWIZZLE_FOOTER [currentClasses removeObjectForKey:self];

#define LP_GET_ORIGINAL_IMP(selector) [LPSwizzle originalImplementationForInstanceMethod:selector forClass:[self class]]

@interface LPSwizzle : NSObject

+ (BOOL)swizzleMethod:(SEL)origSel_ withMethod:(SEL)altSel_ error:(NSError**)error_ class:(Class) clazz;
+ (BOOL)swizzleClassMethod:(SEL)origSel_ withClassMethod:(SEL)altSel_ error:(NSError**)error_ class:(Class) clazz;

@end

// Methods by Leanplum.
@interface LPSwizzle (LeanplumExtension)

// Returns if the method already exists.
+ (BOOL)hookInto:(SEL)originalSelector withSelector:(SEL)newSelector forObject:(id)object;

+ (BOOL)swizzleInstanceMethod:(SEL)originalMethod forClass:(Class)class withReplacementMethod:(IMP)replacement;
+ (Class)originalImplementingClassForInstanceMethod:(SEL)selector forClass:(Class)class;
+ (IMP)originalImplementationForInstanceMethod:(SEL)selector forClass:(Class)class;

@end
