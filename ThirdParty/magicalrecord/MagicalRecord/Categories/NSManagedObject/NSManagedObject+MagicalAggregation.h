//
//  NSManagedObject+MagicalAggregation.h
//  Magical Record
//
//  Created by Saul Mora on 3/7/12.
//  Copyright (c) 2012 Magical Panda Software LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (MagicalAggregation)

+ (NSNumber *) MR_numberOfEntities;
+ (NSNumber *) MR_numberOfEntitiesWithContext:(NSManagedObjectContext *)context;
+ (NSNumber *) MR_numberOfEntitiesWithPredicate:(NSPredicate *)searchTerm;
+ (NSNumber *) MR_numberOfEntitiesWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;

+ (NSUInteger) MR_countOfEntities;
+ (NSUInteger) MR_countOfEntitiesWithContext:(NSManagedObjectContext *)context;
+ (NSUInteger) MR_countOfEntitiesWithPredicate:(NSPredicate *)searchFilter;
+ (NSUInteger) MR_countOfEntitiesWithPredicate:(NSPredicate *)searchFilter inContext:(NSManagedObjectContext *)context;

+ (BOOL) MR_hasAtLeastOneEntity;
+ (BOOL) MR_hasAtLeastOneEntityInContext:(NSManagedObjectContext *)context;

- (id) MR_minValueFor:(NSString *)property;
- (id) MR_maxValueFor:(NSString *)property;

+ (id) MR_aggregateOperation:(NSString *)function onAttribute:(NSString *)attributeName withPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;
+ (id) MR_aggregateOperation:(NSString *)function onAttribute:(NSString *)attributeName withPredicate:(NSPredicate *)predicate;

/**
 *  Supports aggregating values using a key-value collection operator that can be grouped by an attribute.
 *  See https://developer.apple.com/library/ios/documentation/cocoa/conceptual/KeyValueCoding/Articles/CollectionOperators.html for a list of valid collection operators.
 *
 *  @since 2.3.0
 *
 *  @param collectionOperator   Collection operator
 *  @param attributeName        Entity attribute to apply the collection operator to
 *  @param predicate            Predicate to filter results
 *  @param groupingKeyPath      Key path to group results by
 *  @param context              Context to perform the request in
 *
 *  @return Results of the collection operator, filtered by the provided predicate and grouped by the provided key path
 */
+ (NSArray *) MR_aggregateOperation:(NSString *)collectionOperator onAttribute:(NSString *)attributeName withPredicate:(NSPredicate *)predicate groupBy:(NSString*)groupingKeyPath inContext:(NSManagedObjectContext *)context;

/**
 *  Supports aggregating values using a key-value collection operator that can be grouped by an attribute.
 *  See https://developer.apple.com/library/ios/documentation/cocoa/conceptual/KeyValueCoding/Articles/CollectionOperators.html for a list of valid collection operators.
 *
 *  This method is run against the default MagicalRecordStack's context.
 *
 *  @since 2.3.0
 *
 *  @param collectionOperator   Collection operator
 *  @param attributeName        Entity attribute to apply the collection operator to
 *  @param predicate            Predicate to filter results
 *  @param groupingKeyPath      Key path to group results by
 *
 *  @return Results of the collection operator, filtered by the provided predicate and grouped by the provided key path
 */
+ (NSArray *) MR_aggregateOperation:(NSString *)collectionOperator onAttribute:(NSString *)attributeName withPredicate:(NSPredicate *)predicate groupBy:(NSString*)groupingKeyPath;

- (instancetype) MR_objectWithMinValueFor:(NSString *)property;
- (instancetype) MR_objectWithMinValueFor:(NSString *)property inContext:(NSManagedObjectContext *)context;

@end
