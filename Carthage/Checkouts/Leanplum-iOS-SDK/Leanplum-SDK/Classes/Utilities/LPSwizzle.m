// JRSwizzle.m semver:1.0
//   Copyright (c) 2007-2011 Jonathan 'Wolf' Rentzsch: http://rentzsch.com
//   Some rights reserved: http://opensource.org/licenses/MIT
//   https://github.com/rentzsch/jrswizzle

#import "LPSwizzle.h"
#import "LPConstants.h"
#import "LeanplumInternal.h"

#if TARGET_OS_IPHONE
#import <objc/runtime.h>
#import <objc/message.h>
#else
#import <objc/objc-class.h>
#endif

#define SetNSErrorFor(FUNC, ERROR_VAR, FORMAT,...) \
if (ERROR_VAR) { \
NSString *errStr = [NSString stringWithFormat:@"%s: " FORMAT,FUNC,##__VA_ARGS__]; \
*ERROR_VAR = [NSError errorWithDomain:@"NSCocoaErrorDomain" \
code:-1 \
userInfo:[NSDictionary dictionaryWithObject:errStr forKey:NSLocalizedDescriptionKey]]; \
}
#define SetNSError(ERROR_VAR, FORMAT,...) SetNSErrorFor(__func__, ERROR_VAR, FORMAT, ##__VA_ARGS__)

#if OBJC_API_VERSION >= 2
#define GetClass(obj) object_getClass(obj)
#else
#define GetClass(obj) (obj ? obj->isa : Nil)
#endif

static NSMutableDictionary *_methodTable;

@implementation LPSwizzle

+ (BOOL)swizzleMethod:(SEL)origSel_ withMethod:(SEL)altSel_ error:(NSError**)error_ class:(Class)clazz {
#if OBJC_API_VERSION >= 2
    Method origMethod = class_getInstanceMethod(clazz, origSel_);
    if (!origMethod) {
#if TARGET_OS_IPHONE
        SetNSError(error_, @"original method %@ not found for class %@",
                   NSStringFromSelector(origSel_), clazz);
#else
        SetNSError(error_, @"original method %@ not found for class %@",
                   NSStringFromSelector(origSel_), [clazz className]);
#endif
        return NO;
    }
    
    Method altMethod = class_getInstanceMethod(clazz, altSel_);
    if (!altMethod) {
#if TARGET_OS_IPHONE
        SetNSError(error_, @"alternate method %@ not found for class %@",
                   NSStringFromSelector(altSel_), clazz);
#else
        SetNSError(error_, @"alternate method %@ not found for class %@",
                   NSStringFromSelector(altSel_), [clazz className]);
#endif
        return NO;
    }
    
    class_addMethod(clazz,
                    origSel_,
                    class_getMethodImplementation(clazz, origSel_),
                    method_getTypeEncoding(origMethod));
    class_addMethod(clazz,
                    altSel_,
                    class_getMethodImplementation(clazz, altSel_),
                    method_getTypeEncoding(altMethod));
    
    method_exchangeImplementations(class_getInstanceMethod(clazz, origSel_),
                                   class_getInstanceMethod(clazz, altSel_));
    return YES;
#else
    // Scan for non-inherited methods.
    Method directOriginalMethod = NULL, directAlternateMethod = NULL;
    
    void *iterator = NULL;
    struct objc_method_list *mlist = class_nextMethodList(clazz, &iterator);
    while (mlist) {
        int method_index = 0;
        for (; method_index < mlist->method_count; method_index++) {
            if (mlist->method_list[method_index].method_name == origSel_) {
                assert(!directOriginalMethod);
                directOriginalMethod = &mlist->method_list[method_index];
            }
            if (mlist->method_list[method_index].method_name == altSel_) {
                assert(!directAlternateMethod);
                directAlternateMethod = &mlist->method_list[method_index];
            }
        }
        mlist = class_nextMethodList(clazz, &iterator);
    }
    
    // If either method is inherited, copy it up to the target class to make it non-inherited.
    if (!directOriginalMethod || !directAlternateMethod) {
        Method inheritedOriginalMethod = NULL, inheritedAlternateMethod = NULL;
        if (!directOriginalMethod) {
            inheritedOriginalMethod = class_getInstanceMethod(clazz, origSel_);
            if (!inheritedOriginalMethod) {
                SetNSError(error_, @"original method %@ not found for class %@",
                           NSStringFromSelector(origSel_), [clazz className]);
                return NO;
            }
        }
        if (!directAlternateMethod) {
            inheritedAlternateMethod = class_getInstanceMethod(clazz, altSel_);
            if (!inheritedAlternateMethod) {
                SetNSError(error_, @"alternate method %@ not found for class %@",
                           NSStringFromSelector(altSel_), [clazz className]);
                return NO;
            }
        }
        
        int hoisted_method_count = !directOriginalMethod && !directAlternateMethod ? 2 : 1;
        struct objc_method_list *hoisted_method_list = malloc(sizeof(struct objc_method_list) +
                                        (sizeof(struct objc_method)*(hoisted_method_count-1)));
        hoisted_method_list->obsolete = NULL; // soothe valgrind -
        // apparently ObjC runtime accesses this value and it shows as uninitialized in valgrind
        hoisted_method_list->method_count = hoisted_method_count;
        Method hoisted_method = hoisted_method_list->method_list;
        
        if (!directOriginalMethod) {
            bcopy(inheritedOriginalMethod, hoisted_method, sizeof(struct objc_method));
            directOriginalMethod = hoisted_method++;
        }
        if (!directAlternateMethod) {
            bcopy(inheritedAlternateMethod, hoisted_method, sizeof(struct objc_method));
            directAlternateMethod = hoisted_method;
        }
        class_addMethods(clazz, hoisted_method_list);
    }
    
    // Swizzle.
    IMP temp = directOriginalMethod->method_imp;
    directOriginalMethod->method_imp = directAlternateMethod->method_imp;
    directAlternateMethod->method_imp = temp;
    
    return YES;
#endif
}

+ (BOOL)swizzleClassMethod:(SEL)origSel_ withClassMethod:(SEL)altSel_ error:(NSError**)error_
                     class:(Class)clazz {
    return [LPSwizzle swizzleMethod:origSel_ withMethod:altSel_ error:error_
                              class:GetClass((id)clazz)];
}

@end

// Methods by Leanplum.
@implementation LPSwizzle (LeanplumExtension)

+ (BOOL)hookInto:(SEL)originalSelector withSelector:(SEL)newSelector forObject:(id)object
{
    NSError *error;
    Method originalMethod = class_getInstanceMethod(object, originalSelector);
    if (!originalMethod) {
        class_addMethod(object, originalSelector,
                        class_getMethodImplementation(NSObject.class, newSelector),
                        method_getTypeEncoding(class_getInstanceMethod(
                                            NSObject.class, newSelector)));
        return NO;
    } else {
        [LPSwizzle swizzleMethod:originalSelector withMethod:newSelector error:&error
                           class:[object class]];
        return YES;
    }
}

+ (Class)implementingSuperclassForSelector:(SEL)selector onClass:(Class)class
{
    Class currentClass = class;
    while (currentClass && [currentClass instanceMethodForSelector:selector] ==
           [[currentClass superclass] instanceMethodForSelector:selector]) {
        currentClass = [currentClass superclass];
    }
    return currentClass;
}

+ (BOOL)swizzleInstanceMethod:(SEL)originalSelector forClass:(Class)clazz withReplacementMethod:(IMP)replacement;
{
    clazz = [self implementingSuperclassForSelector:originalSelector onClass:clazz];

    Method method = class_getInstanceMethod(clazz, originalSelector);

    if (method_getImplementation(method) == replacement) {
        return NO;
    }

    // Save pointer to original implementation.
    IMP originalImplementation = method_setImplementation(method, (IMP) replacement);
    NSValue *impValue = [NSValue valueWithPointer:originalImplementation];
    if (!_methodTable) {
        _methodTable = [NSMutableDictionary dictionary];
    }
    NSString *className = NSStringFromClass(clazz);
    if (!_methodTable[className]) {
        _methodTable[NSStringFromClass(clazz)] = [NSMutableDictionary dictionary];
    }
    NSString *originalMethodName = NSStringFromSelector(originalSelector);
    _methodTable[className][originalMethodName] = impValue;

    LPLog(LPDebug, @"Swizzled instance method %@ %@", className, originalMethodName);

    return YES;
}

+ (Class)originalImplementingClassForInstanceMethod:(SEL)selector forClass:(Class)clazz
{
    NSString *selectorName = NSStringFromSelector(selector);
    IMP value = NULL;
    Class currentClass = clazz;
    while (currentClass) {
        value = (IMP) [_methodTable[NSStringFromClass(currentClass)][selectorName] pointerValue];
        if (value) {
            return currentClass;
        }
        currentClass = [currentClass superclass];
    }
    return nil;
}

+ (IMP)originalImplementationForInstanceMethod:(SEL)selector forClass:(Class)clazz
{
    NSString *selectorName = NSStringFromSelector(selector);
    IMP value = NULL;
    Class currentClass = clazz;
    while (!value && currentClass) {
        value = (IMP) [_methodTable[NSStringFromClass(currentClass)][selectorName] pointerValue];
        currentClass = [currentClass superclass];
    }

    LPLog(LPDebug, @"Implementation for %@ %@: %llu", clazz, NSStringFromSelector(selector),
          (unsigned long long) value);
    
    if (!value) {
        LPLog(LPDebug, @"Method table: %@", _methodTable);
    }
    
    return value;
}

@end
