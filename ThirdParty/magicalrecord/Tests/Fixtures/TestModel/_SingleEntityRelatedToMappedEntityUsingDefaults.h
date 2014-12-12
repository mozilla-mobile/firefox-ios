// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SingleEntityRelatedToMappedEntityUsingDefaults.h instead.

#import <CoreData/CoreData.h>

extern const struct SingleEntityRelatedToMappedEntityUsingDefaultsAttributes {
	__unsafe_unretained NSString *singleEntityRelatedToMappedEntityUsingDefaultsID;
} SingleEntityRelatedToMappedEntityUsingDefaultsAttributes;

extern const struct SingleEntityRelatedToMappedEntityUsingDefaultsRelationships {
	__unsafe_unretained NSString *mappedEntity;
} SingleEntityRelatedToMappedEntityUsingDefaultsRelationships;

@class MappedEntity;

@interface SingleEntityRelatedToMappedEntityUsingDefaultsID : NSManagedObjectID {}
@end

@interface _SingleEntityRelatedToMappedEntityUsingDefaults : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (SingleEntityRelatedToMappedEntityUsingDefaultsID*)objectID;

@property (nonatomic, strong) NSNumber* singleEntityRelatedToMappedEntityUsingDefaultsID;

//- (BOOL)validateSingleEntityRelatedToMappedEntityUsingDefaultsID:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) MappedEntity *mappedEntity;

//- (BOOL)validateMappedEntity:(id*)value_ error:(NSError**)error_;

@end

@interface _SingleEntityRelatedToMappedEntityUsingDefaults (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveSingleEntityRelatedToMappedEntityUsingDefaultsID;
- (void)setPrimitiveSingleEntityRelatedToMappedEntityUsingDefaultsID:(NSNumber*)value;

- (MappedEntity*)primitiveMappedEntity;
- (void)setPrimitiveMappedEntity:(MappedEntity*)value;

@end
