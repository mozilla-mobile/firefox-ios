// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey.h instead.

#import <CoreData/CoreData.h>

extern const struct SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKeyAttributes {
	__unsafe_unretained NSString *testPrimaryKey;
} SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKeyAttributes;

extern const struct SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKeyRelationships {
	__unsafe_unretained NSString *mappedEntities;
} SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKeyRelationships;

extern const struct SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKeyUserInfo {
	__unsafe_unretained NSString *relatedByAttribute;
} SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKeyUserInfo;

@class MappedEntity;

@interface SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKeyID : NSManagedObjectID {}
@end

@interface _SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKeyID*)objectID;

@property (nonatomic, strong) NSNumber* testPrimaryKey;

//- (BOOL)validateTestPrimaryKey:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *mappedEntities;

- (NSMutableSet*)mappedEntitiesSet;

@end

@interface _SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey (MappedEntitiesCoreDataGeneratedAccessors)
- (void)addMappedEntities:(NSSet*)value_;
- (void)removeMappedEntities:(NSSet*)value_;
- (void)addMappedEntitiesObject:(MappedEntity*)value_;
- (void)removeMappedEntitiesObject:(MappedEntity*)value_;
@end

@interface _SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveTestPrimaryKey;
- (void)setPrimitiveTestPrimaryKey:(NSNumber*)value;

- (NSMutableSet*)primitiveMappedEntities;
- (void)setPrimitiveMappedEntities:(NSMutableSet*)value;

@end
