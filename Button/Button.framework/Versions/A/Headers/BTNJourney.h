#import "BTNBaseEntity.h"
#import "BTNLocation.h"

typedef NS_ENUM(NSInteger, BTNTransportType) {
    BTNTransportTypeUnknown,
    BTNTransportTypeFlight,
    BTNTransportTypeTrain,
    BTNTransportTypeBus,
    BTNTransportTypeCar,
    BTNTransportTypeWalking,
    BTNTransportTypeSubway,
    BTNTransportTypeBoat,
    BTNTransportTypeSpaceship
};

/**
 All fields are optional and should be populated only if known.
 @see `BTNBaseEntity` for inherited configuration options.
 */

NS_ASSUME_NONNULL_BEGIN

@interface BTNJourney : BTNBaseEntity

/// Sets the starting location of the journey.
- (void)setStartLocation:(BTNLocation *)startLocation;


/// Sets the destination location of the journey.
- (void)setDestinationLocation:(BTNLocation *)destinationLocation;


/// Sets the start date/time of the journey.
- (void)setStartTime:(NSDate *)startTime;


/// Sets the end date/time of the journey.
- (void)setEndTime:(NSDate *)endTime;


/// Sets the type of transportation @see BTNTransportType.
- (void)setTransportType:(BTNTransportType)transportType;

@end

NS_ASSUME_NONNULL_END
