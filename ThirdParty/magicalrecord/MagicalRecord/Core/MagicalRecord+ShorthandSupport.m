//
//  MagicalRecord+ShorthandSupport.m
//  Magical Record
//
//  Created by Saul Mora on 3/6/12.
//  Copyright (c) 2012 Magical Panda Software LLC. All rights reserved.
//

#import "MagicalRecord+ShorthandSupport.h"
#import <objc/runtime.h>


static NSString * const kMagicalRecordCategoryPrefix = @"MR_";
#ifdef MR_SHORTHAND
static BOOL methodsHaveBeenSwizzled = NO;
#endif


//Dynamic shorthand method helpers
BOOL addMagicalRecordShortHandMethodToPrefixedClassMethod(Class class, SEL selector);
BOOL addMagicalRecordShorthandMethodToPrefixedInstanceMethod(Class klass, SEL originalSelector);

void swizzleInstanceMethods(Class originalClass, SEL originalSelector, Class targetClass, SEL newSelector);
void replaceSelectorForTargetWithSourceImpAndSwizzle(Class originalClass, SEL originalSelector, Class newClass, SEL newSelector);


@implementation MagicalRecord (ShorthandSupport)

#pragma mark - Support methods for shorthand methods

#ifdef MR_SHORTHAND
+ (BOOL) MR_resolveClassMethod:(SEL)originalSelector
{
    BOOL resolvedClassMethod = [self MR_resolveClassMethod:originalSelector];
    if (!resolvedClassMethod) 
    {
        resolvedClassMethod = addMagicalRecordShortHandMethodToPrefixedClassMethod(self, originalSelector);
    }
    return resolvedClassMethod;
}

+ (BOOL) MR_resolveInstanceMethod:(SEL)originalSelector
{
    BOOL resolvedClassMethod = [self MR_resolveInstanceMethod:originalSelector];
    if (!resolvedClassMethod) 
    {
        resolvedClassMethod = addMagicalRecordShorthandMethodToPrefixedInstanceMethod(self, originalSelector);
    }
    return resolvedClassMethod;
}

//In order to add support for non-prefixed AND prefixed methods, we need to swap the existing resolveClassMethod: and resolveInstanceMethod: implementations with the one in this class.
+ (void) updateResolveMethodsForClass:(Class)klass
{
    replaceSelectorForTargetWithSourceImpAndSwizzle(self, @selector(MR_resolveClassMethod:), klass, @selector(resolveClassMethod:));
    replaceSelectorForTargetWithSourceImpAndSwizzle(self, @selector(MR_resolveInstanceMethod:), klass, @selector(resolveInstanceMethod:));    
}

+ (void) swizzleShorthandMethods;
{
    if (methodsHaveBeenSwizzled) return;
    
    NSArray *classes = [NSArray arrayWithObjects:
                        [NSManagedObject class],
                        [NSManagedObjectContext class], 
                        [NSManagedObjectModel class], 
                        [NSPersistentStore class], 
                        [NSPersistentStoreCoordinator class], nil];
    
    [classes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Class klass = (Class)obj;
        
        [self updateResolveMethodsForClass:klass];
    }];
    methodsHaveBeenSwizzled = YES;
}
#endif

@end

#pragma mark - Support functions for runtime shorthand Method calling

void replaceSelectorForTargetWithSourceImpAndSwizzle(Class sourceClass, SEL sourceSelector, Class targetClass, SEL targetSelector)
{
    Method sourceClassMethod = class_getClassMethod(sourceClass, sourceSelector);
    Method targetClassMethod = class_getClassMethod(targetClass, targetSelector);
    
    Class targetMetaClass = objc_getMetaClass([NSStringFromClass(targetClass) cStringUsingEncoding:NSUTF8StringEncoding]);
    
    BOOL methodWasAdded = class_addMethod(targetMetaClass, sourceSelector,
                                          method_getImplementation(targetClassMethod),
                                          method_getTypeEncoding(targetClassMethod));
    
    if (methodWasAdded)
    {
        class_replaceMethod(targetMetaClass, targetSelector, 
                            method_getImplementation(sourceClassMethod), 
                            method_getTypeEncoding(sourceClassMethod));
    }
}

BOOL addMagicalRecordShorthandMethodToPrefixedInstanceMethod(Class klass, SEL originalSelector)
{
    NSString *originalSelectorString = NSStringFromSelector(originalSelector);
    if ([originalSelectorString hasPrefix:@"_"] || [originalSelectorString hasPrefix:@"init"]) return NO;
    
    if (![originalSelectorString hasPrefix:kMagicalRecordCategoryPrefix]) 
    {
        NSString *prefixedSelector = [kMagicalRecordCategoryPrefix stringByAppendingString:originalSelectorString];
        Method existingMethod = class_getInstanceMethod(klass, NSSelectorFromString(prefixedSelector));
        
        if (existingMethod) 
        {
            BOOL methodWasAdded = class_addMethod(klass, 
                                                  originalSelector, 
                                                  method_getImplementation(existingMethod), 
                                                  method_getTypeEncoding(existingMethod));
            
            return methodWasAdded;
        }
    }
    return NO;
}


BOOL addMagicalRecordShortHandMethodToPrefixedClassMethod(Class klass, SEL originalSelector)
{
    NSString *originalSelectorString = NSStringFromSelector(originalSelector);
    if (![originalSelectorString hasPrefix:kMagicalRecordCategoryPrefix]) 
    {
        NSString *prefixedSelector = [kMagicalRecordCategoryPrefix stringByAppendingString:originalSelectorString];
        Method existingMethod = class_getClassMethod(klass, NSSelectorFromString(prefixedSelector));
        
        if (existingMethod) 
        {
            Class metaClass = objc_getMetaClass([NSStringFromClass(klass) cStringUsingEncoding:NSUTF8StringEncoding]);
            BOOL methodWasAdded = class_addMethod(metaClass, 
                                                  originalSelector, 
                                                  method_getImplementation(existingMethod), 
                                                  method_getTypeEncoding(existingMethod));
            
            return methodWasAdded;
        }
    }
    return NO;
}

