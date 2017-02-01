@import Foundation;
#import "BTNSerializable.h"

@interface BTNModelObject : NSObject <BTNSerializable, NSCopying>

/**
 Part of the BTNSerializable protocol. 
 Provides a required, base implementation to ensure the passed dictionary is in fact an NSDictionary.
 @see BTNSerializable
 */
+ (BOOL)canInitWithDictionary:(nonnull NSDictionary *)dictionary NS_REQUIRES_SUPER;



///---------------------------------------
/// @name Serializing/Deserializing Arrays
///---------------------------------------

/**
 Returns a new array of objects from an array of dictionaries.
 @param representations An array of dictionary representations to be converted into objects.
 @note Non NSDictionary objects will be omitted.
 */
+ (nullable NSArray *)arrayOfObjectsFromRepresentations:(nullable NSArray <NSDictionary *> *)representations;


/**
 Returns a serialized array of dictionaries from an array of BTNModelObject objects.
 @note Objects not conforming to BTNSerializable will be omitted.
 */
+ (nullable NSArray <NSDictionary *> *)arrayOfRepresentationsFromObjects:(nullable NSArray <BTNModelObject *> *)objects;

@end
