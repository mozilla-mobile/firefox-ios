@import Foundation;

@protocol BTNSerializable <NSObject>

@required

/**
 Checks that a dictionary contains all keys required to instantiate a valid instance
 of the object using the initWithDictionary method
 @param dictionary A dictionary of keys to be evaluated for use with initWithDictionary
 @return BOOL Whether this dictionary can create a valid instance of the object
 **/
+ (BOOL)canInitWithDictionary:(nonnull NSDictionary *)dictionary;


/**
 Creates an instance of the object from a valid NSDictionary which provides
 at least all mandatory keys for the object as checked in canInitWithDictionary:
 @param dictionary The dictionary of keys to create the object from
 @return instance of the object, or nil if all mandatory keys are not present
 **/
- (nullable instancetype)initWithDictionary:(nonnull NSDictionary *)dictionary;


/**
 Updates an instance of the object from a valid NSDictionary which provides
 at least all mandatory keys for the object as checked in canInitWithDictionary:
 @param dictionary The dictionary of keys to create the object from
 **/
- (void)updateWithRepresentation:(nonnull NSDictionary *)dictionary;


/**
 Translates the object into a serializable dictionary of keys matching initWithDictionary
 @return NSDictionary A dictionary which can be used to recreate the object from initWithDictionary
 @note [[[instancetype alloc] initWithDictionary:[existingObject dictionaryRepresentation]] isEqual:existingObject]
    should always be true
 **/
- (nullable NSDictionary *)dictionaryRepresentation;


@end
