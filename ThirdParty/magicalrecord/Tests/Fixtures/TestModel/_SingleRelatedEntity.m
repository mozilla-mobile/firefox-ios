// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SingleRelatedEntity.m instead.

#import "_SingleRelatedEntity.h"

const struct SingleRelatedEntityAttributes SingleRelatedEntityAttributes = {
	.mappedStringAttribute = @"mappedStringAttribute",
};

const struct SingleRelatedEntityRelationships SingleRelatedEntityRelationships = {
	.testAbstractToManyRelationship = @"testAbstractToManyRelationship",
	.testAbstractToOneRelationship = @"testAbstractToOneRelationship",
	.testConcreteToManyRelationship = @"testConcreteToManyRelationship",
	.testConcreteToOneRelationship = @"testConcreteToOneRelationship",
};

@implementation SingleRelatedEntityID
@end

@implementation _SingleRelatedEntity

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"SingleRelatedEntity" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"SingleRelatedEntity";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"SingleRelatedEntity" inManagedObjectContext:moc_];
}

- (SingleRelatedEntityID*)objectID {
	return (SingleRelatedEntityID*)[super objectID];
}

@dynamic mappedStringAttribute;

@dynamic testAbstractToManyRelationship;

- (NSMutableSet*)testAbstractToManyRelationshipSet {
	[self willAccessValueForKey:@"testAbstractToManyRelationship"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"testAbstractToManyRelationship"];

	[self didAccessValueForKey:@"testAbstractToManyRelationship"];
	return result;
}

@dynamic testAbstractToOneRelationship;

@dynamic testConcreteToManyRelationship;

- (NSMutableSet*)testConcreteToManyRelationshipSet {
	[self willAccessValueForKey:@"testConcreteToManyRelationship"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"testConcreteToManyRelationship"];

	[self didAccessValueForKey:@"testConcreteToManyRelationship"];
	return result;
}

@dynamic testConcreteToOneRelationship;

@end

