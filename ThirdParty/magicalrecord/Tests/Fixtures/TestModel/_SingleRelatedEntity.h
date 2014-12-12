// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SingleRelatedEntity.h instead.

#import <CoreData/CoreData.h>

extern const struct SingleRelatedEntityAttributes {
	__unsafe_unretained NSString *mappedStringAttribute;
} SingleRelatedEntityAttributes;

extern const struct SingleRelatedEntityRelationships {
	__unsafe_unretained NSString *testAbstractToManyRelationship;
	__unsafe_unretained NSString *testAbstractToOneRelationship;
	__unsafe_unretained NSString *testConcreteToManyRelationship;
	__unsafe_unretained NSString *testConcreteToOneRelationship;
} SingleRelatedEntityRelationships;

@class AbstractRelatedEntity;
@class AbstractRelatedEntity;
@class ConcreteRelatedEntity;
@class ConcreteRelatedEntity;

@interface SingleRelatedEntityID : NSManagedObjectID {}
@end

@interface _SingleRelatedEntity : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (SingleRelatedEntityID*)objectID;

@property (nonatomic, strong) NSString* mappedStringAttribute;

//- (BOOL)validateMappedStringAttribute:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *testAbstractToManyRelationship;

- (NSMutableSet*)testAbstractToManyRelationshipSet;

@property (nonatomic, strong) AbstractRelatedEntity *testAbstractToOneRelationship;

//- (BOOL)validateTestAbstractToOneRelationship:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSSet *testConcreteToManyRelationship;

- (NSMutableSet*)testConcreteToManyRelationshipSet;

@property (nonatomic, strong) ConcreteRelatedEntity *testConcreteToOneRelationship;

//- (BOOL)validateTestConcreteToOneRelationship:(id*)value_ error:(NSError**)error_;

@end

@interface _SingleRelatedEntity (TestAbstractToManyRelationshipCoreDataGeneratedAccessors)
- (void)addTestAbstractToManyRelationship:(NSSet*)value_;
- (void)removeTestAbstractToManyRelationship:(NSSet*)value_;
- (void)addTestAbstractToManyRelationshipObject:(AbstractRelatedEntity*)value_;
- (void)removeTestAbstractToManyRelationshipObject:(AbstractRelatedEntity*)value_;
@end

@interface _SingleRelatedEntity (TestConcreteToManyRelationshipCoreDataGeneratedAccessors)
- (void)addTestConcreteToManyRelationship:(NSSet*)value_;
- (void)removeTestConcreteToManyRelationship:(NSSet*)value_;
- (void)addTestConcreteToManyRelationshipObject:(ConcreteRelatedEntity*)value_;
- (void)removeTestConcreteToManyRelationshipObject:(ConcreteRelatedEntity*)value_;
@end

@interface _SingleRelatedEntity (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveMappedStringAttribute;
- (void)setPrimitiveMappedStringAttribute:(NSString*)value;

- (NSMutableSet*)primitiveTestAbstractToManyRelationship;
- (void)setPrimitiveTestAbstractToManyRelationship:(NSMutableSet*)value;

- (AbstractRelatedEntity*)primitiveTestAbstractToOneRelationship;
- (void)setPrimitiveTestAbstractToOneRelationship:(AbstractRelatedEntity*)value;

- (NSMutableSet*)primitiveTestConcreteToManyRelationship;
- (void)setPrimitiveTestConcreteToManyRelationship:(NSMutableSet*)value;

- (ConcreteRelatedEntity*)primitiveTestConcreteToOneRelationship;
- (void)setPrimitiveTestConcreteToOneRelationship:(ConcreteRelatedEntity*)value;

@end
