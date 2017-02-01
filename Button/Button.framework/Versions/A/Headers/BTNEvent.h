#import "BTNBaseEntity.h"
#import "BTNLocation.h"

/**
 All fields are optional and should be populated only if known.
 @see `BTNBaseEntity` for inherited configuration options.
 */

NS_ASSUME_NONNULL_BEGIN

@interface BTNEvent : BTNBaseEntity

/**
 Returns an instance with start/end times and location
 @param startTime A date representing the start of the event.
 @param endTime A date representing the end of the event.
 @param location The location of the event.
 */
+ (instancetype)eventWithStartTime:(NSDate *)startTime
                           endTime:(NSDate *)endTime
                          location:(BTNLocation *)location;


/// Sets the location of the event.
- (void)setLocation:(BTNLocation *)location;


/// Sets the start date/time of the event.
- (void)setStartTime:(NSDate *)startTime;


/// Sets the end date/time of the event.
- (void)setEndTime:(NSDate *)endTime;

@end

NS_ASSUME_NONNULL_END
