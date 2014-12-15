// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SingleEntityRelatedToMappedEntityUsingDefaults.m instead.

#import "_SingleEntityRelatedToMappedEntityUsingDefaults.h"

const struct SingleEntityRelatedToMappedEntityUsingDefaultsAttributes SingleEntityRelatedToMappedEntityUsingDefaultsAttributes = {
	.singleEntityRelatedToMappedEntityUsingDefaultsID = @"singleEntityRelatedToMappedEntityUsingDefaultsID",
};

const struct SingleEntityRelatedToMappedEntityUsingDefaultsRelationships SingleEntityRelatedToMappedEntityUsingDefaultsRelationships = {
	.mappedEntity = @"mappedEntity",
};

@implementation SingleEntityRelatedToMappedEntityUsingDefaultsID
@end

@implementation _SingleEntityRelatedToMappedEntityUsingDefaults

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"SingleEntityRelatedToMappedEntityUsingDefaults" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"SingleEntityRelatedToMappedEntityUsingDefaults";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"SingleEntityRelatedToMappedEntityUsingDefaults" inManagedObjectContext:moc_];
}

- (SingleEntityRelatedToMappedEntityUsingDefaultsID*)objectID {
	return (SingleEntityRelatedToMappedEntityUsingDefaultsID*)[super objectID];
}

@dynamic singleEntityRelatedToMappedEntityUsingDefaultsID;

@dynamic mappedEntity;

@end

