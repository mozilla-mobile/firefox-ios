// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MappedEntity.m instead.

#import "_MappedEntity.h"

const struct MappedEntityAttributes MappedEntityAttributes = {
	.mappedEntityID = @"mappedEntityID",
	.nestedAttribute = @"nestedAttribute",
	.sampleAttribute = @"sampleAttribute",
	.testMappedEntityID = @"testMappedEntityID",
};

const struct MappedEntityUserInfo MappedEntityUserInfo = {
	.relatedByAttribute = @"mapped",
};

@implementation MappedEntityID
@end

@implementation _MappedEntity

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"MappedEntity" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"MappedEntity";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"MappedEntity" inManagedObjectContext:moc_];
}

- (MappedEntityID*)objectID {
	return (MappedEntityID*)[super objectID];
}

@dynamic mappedEntityID;

@dynamic nestedAttribute;

@dynamic sampleAttribute;

@dynamic testMappedEntityID;

@end

