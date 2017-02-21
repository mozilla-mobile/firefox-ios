#import "BTNBaseEntity.h"
@import CoreLocation;

/**
 All fields are optional and should be populated only if known.
 @see `BTNBaseEntity` for inherited configuration options.
 */

NS_ASSUME_NONNULL_BEGIN

@interface BTNLocation : BTNBaseEntity

///---------------------
/// @name Initialization
///---------------------


/**
 Returns a named location instance.
 @param name The displayable name of the location.
 @param latitude  The latitude of the location.
 @param longitude The longitude of the location.
 */
+ (instancetype)locationWithName:(nullable NSString *)name
                        latitude:(CLLocationDegrees)latitude
                       longitude:(CLLocationDegrees)longitude;


/**
 Returns a location instance.
 @param latitude  The latitude of the location.
 @param longitude The longitude of the location.
 */
+ (instancetype)locationWithLatitude:(CLLocationDegrees)latitude
                           longitude:(CLLocationDegrees)longitude;



///--------------------
/// @name Configuration
///--------------------


/// Sets the latitude of the location (requires a longitude).
- (void)setLatitude:(CLLocationDegrees)latitude;


/// Sets the longitude of the location (requires a latitude).
- (void)setLongitude:(CLLocationDegrees)longitude;


/// Sets the city associated with the location.
- (void)setCity:(NSString *)city;


/// Sets the state associated with the location.
- (void)setState:(NSString *)state;


/// Sets the postal code associated with the location.
- (void)setZip:(NSString *)zip;


/// The country of the location.
- (void)setCountry:(NSString *)country;


/// An address line for the location (e.g. 220 E 23rd Street).
- (void)setAddressLine:(NSString *)addressLine;

@end

NS_ASSUME_NONNULL_END
