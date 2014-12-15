// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SingleEntityRelatedToMappedEntityWithNestedMappedAttributes.h instead.

#import <CoreData/CoreData.h>

extern const struct SingleEntityRelatedToMappedEntityWithNestedMappedAttributesRelationships {
	__unsafe_unretained NSString *mappedEntity;
} SingleEntityRelatedToMappedEntityWithNestedMappedAttributesRelationships;

@class MappedEntity;

@interface SingleEntityRelatedToMappedEntityWithNestedMappedAttributesID : NSManagedObjectID {}
@end

@interface _SingleEntityRelatedToMappedEntityWithNestedMappedAttributes : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (SingleEntityRelatedToMappedEntityWithNestedMappedAttributesID*)objectID;

@property (nonatomic, strong) MappedEntity *mappedEntity;

//- (BOOL)validateMappedEntity:(id*)value_ error:(NSError**)error_;

@end

@interface _SingleEntityRelatedToMappedEntityWithNestedMappedAttributes (CoreDataGeneratedPrimitiveAccessors)

- (MappedEntity*)primitiveMappedEntity;
- (void)setPrimitiveMappedEntity:(MappedEntity*)value;

@end
