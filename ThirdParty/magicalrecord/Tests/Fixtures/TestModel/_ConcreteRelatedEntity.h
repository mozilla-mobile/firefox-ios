// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to ConcreteRelatedEntity.h instead.

#import <CoreData/CoreData.h>
#import "AbstractRelatedEntity.h"

extern const struct ConcreteRelatedEntityAttributes {
	__unsafe_unretained NSString *sampleConcreteAttribute;
} ConcreteRelatedEntityAttributes;

@interface ConcreteRelatedEntityID : AbstractRelatedEntityID {}
@end

@interface _ConcreteRelatedEntity : AbstractRelatedEntity {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (ConcreteRelatedEntityID*)objectID;

@property (nonatomic, strong) NSString* sampleConcreteAttribute;

//- (BOOL)validateSampleConcreteAttribute:(id*)value_ error:(NSError**)error_;

@end

@interface _ConcreteRelatedEntity (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveSampleConcreteAttribute;
- (void)setPrimitiveSampleConcreteAttribute:(NSString*)value;

@end
