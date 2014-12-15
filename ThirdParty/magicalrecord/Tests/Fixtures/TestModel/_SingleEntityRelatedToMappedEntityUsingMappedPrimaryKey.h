// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SingleEntityRelatedToMappedEntityUsingMappedPrimaryKey.h instead.

#import <CoreData/CoreData.h>

extern const struct SingleEntityRelatedToMappedEntityUsingMappedPrimaryKeyRelationships {
	__unsafe_unretained NSString *mappedEntity;
} SingleEntityRelatedToMappedEntityUsingMappedPrimaryKeyRelationships;

@class MappedEntity;

@interface SingleEntityRelatedToMappedEntityUsingMappedPrimaryKeyID : NSManagedObjectID {}
@end

@interface _SingleEntityRelatedToMappedEntityUsingMappedPrimaryKey : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (SingleEntityRelatedToMappedEntityUsingMappedPrimaryKeyID*)objectID;

@property (nonatomic, strong) MappedEntity *mappedEntity;

//- (BOOL)validateMappedEntity:(id*)value_ error:(NSError**)error_;

@end

@interface _SingleEntityRelatedToMappedEntityUsingMappedPrimaryKey (CoreDataGeneratedPrimitiveAccessors)

- (MappedEntity*)primitiveMappedEntity;
- (void)setPrimitiveMappedEntity:(MappedEntity*)value;

@end
