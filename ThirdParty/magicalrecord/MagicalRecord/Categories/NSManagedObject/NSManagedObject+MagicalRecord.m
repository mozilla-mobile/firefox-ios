
//  Created by Saul Mora on 11/15/09.
//  Copyright 2010 Magical Panda Software, LLC All rights reserved.
//

#import "CoreData+MagicalRecord.h"
#import "MagicalRecordLogging.h"

static NSUInteger defaultBatchSize = kMagicalRecordDefaultBatchSize;


@implementation NSManagedObject (MagicalRecord)

+ (NSString *) MR_entityName;
{
    NSString *entityName;

    if ([self respondsToSelector:@selector(entityName)])
    {
        entityName = [self performSelector:@selector(entityName)];
    }

    if ([entityName length] == 0) {
        entityName = NSStringFromClass(self);
    }

    return entityName;
}

+ (void) MR_setDefaultBatchSize:(NSUInteger)newBatchSize
{
	@synchronized(self)
	{
		defaultBatchSize = newBatchSize;
	}
}

+ (NSUInteger) MR_defaultBatchSize
{
	return defaultBatchSize;
}

+ (NSArray *) MR_executeFetchRequest:(NSFetchRequest *)request inContext:(NSManagedObjectContext *)context
{
    __block NSArray *results = nil;
    [context performBlockAndWait:^{

        NSError *error = nil;
        
        results = [context executeFetchRequest:request error:&error];
        
        if (results == nil) 
        {
            [MagicalRecord handleErrors:error];
        }

    }];
	return results;	
}

+ (NSArray *) MR_executeFetchRequest:(NSFetchRequest *)request
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return [self MR_executeFetchRequest:request inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (id) MR_executeFetchRequestAndReturnFirstObject:(NSFetchRequest *)request inContext:(NSManagedObjectContext *)context
{
	[request setFetchLimit:1];
	
	NSArray *results = [self MR_executeFetchRequest:request inContext:context];
	if ([results count] == 0)
	{
		return nil;
	}
	return [results firstObject];
}

+ (id) MR_executeFetchRequestAndReturnFirstObject:(NSFetchRequest *)request
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return [self MR_executeFetchRequestAndReturnFirstObject:request inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
#pragma clang diagnostic pop
}

#if TARGET_OS_IPHONE

+ (void) MR_performFetch:(NSFetchedResultsController *)controller
{
	NSError *error = nil;
	if (![controller performFetch:&error])
	{
		[MagicalRecord handleErrors:error];
	}
}

#endif

+ (NSEntityDescription *) MR_entityDescription
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return [self MR_entityDescriptionInContext:[NSManagedObjectContext MR_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (NSEntityDescription *) MR_entityDescriptionInContext:(NSManagedObjectContext *)context
{
    NSString *entityName = [self MR_entityName];
    return [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
}

+ (NSArray *) MR_propertiesNamed:(NSArray *)properties
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [self MR_propertiesNamed:properties inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (NSArray *) MR_propertiesNamed:(NSArray *)properties inContext:(NSManagedObjectContext *)context
{
	NSEntityDescription *description = [self MR_entityDescriptionInContext:context];
	NSMutableArray *propertiesWanted = [NSMutableArray array];

	if (properties)
	{
		NSDictionary *propDict = [description propertiesByName];

		for (NSString *propertyName in properties)
		{
			NSPropertyDescription *property = [propDict objectForKey:propertyName];
			if (property)
			{
				[propertiesWanted addObject:property];
			}
			else
			{
				MRLogWarn(@"Property '%@' not found in %lx properties for %@", propertyName, (unsigned long)[propDict count], NSStringFromClass(self));
			}
		}
	}
	return propertiesWanted;
}

+ (NSArray *) MR_sortAscending:(BOOL)ascending attributes:(NSArray *)attributesToSortBy
{
	NSMutableArray *attributes = [NSMutableArray array];
    
    for (NSString *attributeName in attributesToSortBy) 
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:attributeName ascending:ascending];
        [attributes addObject:sortDescriptor];
    }
    
	return attributes;
}

+ (NSArray *) MR_ascendingSortDescriptors:(NSArray *)attributesToSortBy
{
	return [self MR_sortAscending:YES attributes:attributesToSortBy];
}

+ (NSArray *) MR_descendingSortDescriptors:(NSArray *)attributesToSortBy
{
	return [self MR_sortAscending:NO attributes:attributesToSortBy];
}

#pragma mark -

+ (id) MR_createEntityInContext:(NSManagedObjectContext *)context
{
    if ([self respondsToSelector:@selector(insertInManagedObjectContext:)] && context != nil)
    {
        id entity = [self performSelector:@selector(insertInManagedObjectContext:) withObject:context];
        return entity;
    }
    else
    {
        NSEntityDescription *entity = nil;
        if (context == nil)
        {
            entity = [self MR_entityDescription];
        }
        else
        {
            entity  = [self MR_entityDescriptionInContext:context];
        }
        
        if (entity == nil)
        {
            return nil;
        }
        
        return [[self alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
    }
}

+ (id) MR_createEntity
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	NSManagedObject *newEntity = [self MR_createEntityInContext:[NSManagedObjectContext MR_contextForCurrentThread]];
#pragma clang diagnostic pop

	return newEntity;
}

- (BOOL) MR_deleteEntityInContext:(NSManagedObjectContext *)context
{
    NSError *error = nil;
    NSManagedObject *inContext = [context existingObjectWithID:[self objectID] error:&error];

    [MagicalRecord handleErrors:error];

    [context deleteObject:inContext];
    
    return YES;
}

- (BOOL) MR_deleteEntity
{
	[self MR_deleteEntityInContext:[self managedObjectContext]];
	return YES;
}

+ (BOOL) MR_deleteAllMatchingPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [self MR_requestAllWithPredicate:predicate inContext:context];
    [request setReturnsObjectsAsFaults:YES];
	[request setIncludesPropertyValues:NO];
    
	NSArray *objectsToTruncate = [self MR_executeFetchRequest:request inContext:context];
    
	for (id objectToTruncate in objectsToTruncate) 
    {
		[objectToTruncate MR_deleteInContext:context];
	}
    
	return YES;
}

+ (BOOL) MR_deleteAllMatchingPredicate:(NSPredicate *)predicate
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [self MR_deleteAllMatchingPredicate:predicate inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (BOOL) MR_truncateAllInContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [self MR_requestAllInContext:context];
    [request setReturnsObjectsAsFaults:YES];
    [request setIncludesPropertyValues:NO];

    NSArray *objectsToDelete = [self MR_executeFetchRequest:request inContext:context];
    for (NSManagedObject *objectToDelete in objectsToDelete)
    {
        [objectToDelete MR_deleteEntityInContext:context];
    }
    return YES;
}

+ (BOOL) MR_truncateAll
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self MR_truncateAllInContext:[NSManagedObjectContext MR_contextForCurrentThread]];
#pragma clang diagnostic pop

    return YES;
}

- (id) MR_inContext:(NSManagedObjectContext *)otherContext
{
    NSError *error = nil;
    
    if ([[self objectID] isTemporaryID])
    {
        BOOL success = [[self managedObjectContext] obtainPermanentIDsForObjects:@[self] error:&error];
        if (!success)
        {
            [MagicalRecord handleErrors:error];
            return nil;
        }
    }
    
    error = nil;
    
    NSManagedObject *inContext = [otherContext existingObjectWithID:[self objectID] error:&error];
    [MagicalRecord handleErrors:error];
    
    return inContext;
}

- (id) MR_inThreadContext
{
    NSManagedObject *weakSelf = self;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [weakSelf MR_inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
#pragma clang diagnostic pop
}

@end

#pragma mark - Deprecated Methods — DO NOT USE
@implementation NSManagedObject (MagicalRecordDeprecated)

+ (instancetype) MR_createInContext:(NSManagedObjectContext *)context
{
    return [self MR_createEntityInContext:context];
}

- (BOOL) MR_deleteInContext:(NSManagedObjectContext *)context
{
    return [self MR_deleteEntityInContext:context];
}

@end
