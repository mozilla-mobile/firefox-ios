//
//  NSPredicate+KIFAdditions.h
//  KIF
//
//  Created by Alex Odawa on 2/3/15.
//
//

#import <Foundation/Foundation.h>

@interface NSPredicate (KIFAdditions)

@property NSString *kifPredicateDescription;

- (NSArray *)flatten;
- (NSCompoundPredicate *)minusSubpredicatesFrom:(NSPredicate *)otherPredicate;

@end
