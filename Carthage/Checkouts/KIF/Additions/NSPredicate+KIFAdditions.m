//
//  NSPredicate+KIFAdditions.m
//  KIF
//
//  Created by Alex Odawa on 2/3/15.
//
//

#import <objc/runtime.h>
#import "NSPredicate+KIFAdditions.h"

@implementation NSPredicate (KIFAdditions)

- (NSArray *)flatten
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    if ([self isKindOfClass:[NSCompoundPredicate class]]) {
        for (NSPredicate *predicate in ((NSCompoundPredicate *)self).subpredicates) {
            [result addObjectsFromArray:[predicate flatten]];
        }
    } else {
        [result addObject:self];
    }
    
    return result;
}

- (NSCompoundPredicate *)minusSubpredicatesFrom:(NSPredicate *)otherPredicate;
{
    if (self == otherPredicate) {
        return nil;
    }
    NSMutableSet *subpredicates = [NSMutableSet setWithArray:[self flatten]];
    NSMutableSet *otherSubpredicates = [NSMutableSet setWithArray:[otherPredicate flatten]];
    [subpredicates minusSet:otherSubpredicates];
    return [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType
                                       subpredicates:[subpredicates allObjects]];
}

- (void)setKifPredicateDescription:(NSString *)description;
{
    NSString *desc = description.copy;
    objc_setAssociatedObject(self, @selector(kifPredicateDescription), desc, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)kifPredicateDescription;
{
    id object = objc_getAssociatedObject(self, @selector(kifPredicateDescription));
    if (object) {
        return object;
    }
    // Compound predicates containing subpredicates with the kifPredicateDescription set should still get our pretty formatting.
    if ([self isKindOfClass:[NSCompoundPredicate class]]) {
        NSArray *subpredicates = [self flatten];
        NSString *description = @"";
        
        for (NSPredicate *predicate in subpredicates) {
            if (description.length > 0) {
                description = [description stringByAppendingString:@", "];
            }
            description = [description stringByAppendingString:predicate.kifPredicateDescription];
        }
        if (description.length > 0) {
            return description;
        }
    }
    
    return self.description;
}

@end
