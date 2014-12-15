// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SingleEntityRelatedToMappedEntityWithNestedMappedAttributes.m instead.

#import "_SingleEntityRelatedToMappedEntityWithNestedMappedAttributes.h"

const struct SingleEntityRelatedToMappedEntityWithNestedMappedAttributesRelationships SingleEntityRelatedToMappedEntityWithNestedMappedAttributesRelationships = {
	.mappedEntity = @"mappedEntity",
};

@implementation SingleEntityRelatedToMappedEntityWithNestedMappedAttributesID
@end

@implementation _SingleEntityRelatedToMappedEntityWithNestedMappedAttributes

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"SingleEntityRelatedToMappedEntityWithNestedMappedAttributes" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"SingleEntityRelatedToMappedEntityWithNestedMappedAttributes";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"SingleEntityRelatedToMappedEntityWithNestedMappedAttributes" inManagedObjectContext:moc_];
}

- (SingleEntityRelatedToMappedEntityWithNestedMappedAttributesID*)objectID {
	return (SingleEntityRelatedToMappedEntityWithNestedMappedAttributesID*)[super objectID];
}

@dynamic mappedEntity;

@end

