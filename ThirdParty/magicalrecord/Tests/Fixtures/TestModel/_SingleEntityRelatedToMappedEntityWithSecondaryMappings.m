// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SingleEntityRelatedToMappedEntityWithSecondaryMappings.m instead.

#import "_SingleEntityRelatedToMappedEntityWithSecondaryMappings.h"

const struct SingleEntityRelatedToMappedEntityWithSecondaryMappingsAttributes SingleEntityRelatedToMappedEntityWithSecondaryMappingsAttributes = {
	.secondaryMappedAttribute = @"secondaryMappedAttribute",
    .notImportedAttribute = @"notImportedAttribute",
};

const struct SingleEntityRelatedToMappedEntityWithSecondaryMappingsRelationships SingleEntityRelatedToMappedEntityWithSecondaryMappingsRelationships = {
	.mappedRelationship = @"mappedRelationship",
};

@implementation SingleEntityRelatedToMappedEntityWithSecondaryMappingsID
@end

@implementation _SingleEntityRelatedToMappedEntityWithSecondaryMappings

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"SingleEntityRelatedToMappedEntityWithSecondaryMappings" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"SingleEntityRelatedToMappedEntityWithSecondaryMappings";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"SingleEntityRelatedToMappedEntityWithSecondaryMappings" inManagedObjectContext:moc_];
}

- (SingleEntityRelatedToMappedEntityWithSecondaryMappingsID*)objectID {
	return (SingleEntityRelatedToMappedEntityWithSecondaryMappingsID*)[super objectID];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    if ([key isEqualToString:@"secondaryMappedAttribute"])
    {
        return self.secondaryMappedAttribute;
    }
    else if ([key isEqualToString:@"notImportedAttribute"])
    {
        return self.notImportedAttribute;
    }

    return nil;
}

@dynamic secondaryMappedAttribute;

@dynamic notImportedAttribute;

@dynamic mappedRelationship;

@end

