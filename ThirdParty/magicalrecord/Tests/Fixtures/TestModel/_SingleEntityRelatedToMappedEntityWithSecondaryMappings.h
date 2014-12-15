// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SingleEntityRelatedToMappedEntityWithSecondaryMappings.h instead.

#import <CoreData/CoreData.h>

extern const struct SingleEntityRelatedToMappedEntityWithSecondaryMappingsAttributes {
	__unsafe_unretained NSString *secondaryMappedAttribute;
    __unsafe_unretained NSString *notImportedAttribute;
} SingleEntityRelatedToMappedEntityWithSecondaryMappingsAttributes;

extern const struct SingleEntityRelatedToMappedEntityWithSecondaryMappingsRelationships {
	__unsafe_unretained NSString *mappedRelationship;
} SingleEntityRelatedToMappedEntityWithSecondaryMappingsRelationships;

@class MappedEntity;

@interface SingleEntityRelatedToMappedEntityWithSecondaryMappingsID : NSManagedObjectID {}
@end

@interface _SingleEntityRelatedToMappedEntityWithSecondaryMappings : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (SingleEntityRelatedToMappedEntityWithSecondaryMappingsID*)objectID;

@property (nonatomic, strong) NSString* secondaryMappedAttribute;

//- (BOOL)validateSecondaryMappedAttribute:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber *notImportedAttribute;

//- (BOOL)validateNotImportedAttribute:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) MappedEntity *mappedRelationship;

//- (BOOL)validateMappedRelationship:(id*)value_ error:(NSError**)error_;

@end

@interface _SingleEntityRelatedToMappedEntityWithSecondaryMappings (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveNotImportedAttribute;
- (void)setPrimitiveNotImportedAttribute:(NSNumber*)value;

- (NSString*)primitiveSecondaryMappedAttribute;
- (void)setPrimitiveSecondaryMappedAttribute:(NSString*)value;

- (MappedEntity*)primitiveMappedRelationship;
- (void)setPrimitiveMappedRelationship:(MappedEntity*)value;

@end
