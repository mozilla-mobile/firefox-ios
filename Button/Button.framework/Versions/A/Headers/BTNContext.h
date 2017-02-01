#import "BTNBaseEntity.h"
#import "BTNLocation.h"
#import "BTNMusicArtist.h"
#import "BTNJourney.h"
#import "BTNEvent.h"
#import "BTNJourney.h"
#import "BTNItem.h"

/**
 All fields are optional and should be populated only if known.
 @see `BTNBaseEntity` for inherited configuration options.
 */

NS_ASSUME_NONNULL_BEGIN

@interface BTNContext : BTNBaseEntity

///--------------------
/// @name Initilization
///--------------------

/**
 Returns a newly instantiated context object.
 */
+ (instancetype)context;


/**
 Returns a newly instantiated context object with a userLocation. 
 @param userLocation the current location of the user.
 @see -setUserLocation for more info.
 */
+ (instancetype)contextWithUserLocation:(BTNLocation *)userLocation;


/**
 Returns a newly instantiated context object with a subject location.
 @param subjectLocation a location subject for the current activity or content.
 @see -setSubjectLocation: for more info.
 */
+ (instancetype)contextWithSubjectLocation:(BTNLocation *)subjectLocation;


/**
 Returns a newly instantiated context object with an artist.
 @param artist a music artist associated with the current context.
 @see -setArtist: for more info.
 */
+ (instancetype)contextWithArtist:(BTNMusicArtist *)artist;


/**
 Returns a newly instantiated context object with a journey.
 @param journey a journey object which is relevant to the current user context.
 @see -setJourney: for more info.
 */
+ (instancetype)contextWithJourney:(BTNJourney *)journey;


/**
 Returns a newly instantiated context object with an event.
 @param event an event object which is relevant to the current user context.
 @see -setEvent: for more info.
 */
+ (instancetype)contextWithEvent:(BTNEvent *)event;



/**
 Returns a newly instantiated context object with a single item.
 @param item An item that is the subject of the page.
 @see -addItems: for more info.
 */
+ (instancetype)contextWithItem:(BTNItem *)item;


/**
 Returns a newly instantiated context object with an array of items.
 @param items one or more items that are the subject of the page.
 @see -addItems: for more info.
 */
+ (instancetype)contextWithItems:(NSArray <BTNItem *> *)items;


/**
 Returns a newly instantiated context object with a URL.
 @param URL a URL that specifies the current context.
 @see -setURL: for more info.
 */
+ (instancetype)contextWithURL:(NSURL *)URL;



///-----------------------------
/// @name Adding Additional Data
///-----------------------------

/**
 Sets the current location of the user.
 @note Provide whatever level of granularity makes sense for the context / that you have access to.
 */
- (void)setUserLocation:(BTNLocation *)userLocation;


/**
 Sets a location subject for the current activity or content.
 Example: A restaurant on a venue page, point on a map or city in a travel app
 @note Provide whatever level of granularity makes sense for the context.
 @see `BTNLocation` for details of all the different ways of expressing a location.
 */
- (void)setSubjectLocation:(BTNLocation *)subjectLocation;


/**
 Sets a relevant date for the user’s context.
 Example: The time of a reservation, date of a hotel reservation etc..
 @note If date is not relevant, do not provide it.
 */
- (void)setDate:(NSDate *)date;


/**
 Sets a date range when the current context represents a discrete period of time with a beginning and an end.
 Example: a return flight, movie showing, sporting event etc..
 */
- (void)setDateRangeWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate;


/**
 Sets a music artist associated with the current context.
 @see `BTNMusicArtist` context object for details.
 */
- (void)setArtist:(BTNMusicArtist *)artist;


/**
 Sets a journey object which is relevant to the current user context.
 @note Specify a `BTNJourney` only when the current context represents a journey.
 Example: itinerary for a flight, bus, train, interstellar travel etc..
 */
- (void)setJourney:(BTNJourney *)journey;


/**
 Sets an event object which is relevant to the current user context.
 Example: A concert, art show, conference etc..
 */
- (void)setEvent:(BTNEvent *)event;


/**
 Add one or more items that are the subject of the page.
 Example: a book, iPad etc..
 */
- (void)addItems:(NSArray <BTNItem *> *)items;
- (void)addItem:(BTNItem *)item;


/**
 Sets a URL that specifies the current context.
 This can either be a Universal Links representation of the page or URL of the canonical crawlable web page.
 */
- (void)setURL:(NSURL *)URL;



///---------------------
/// @name Custom Context
///---------------------

/**
 Add custom key-value pairs to further define your users context.
 @note you can also use object subscripting (e.g. object[key] = value) @see BTNSubscriptable
 */
- (void)addCustomValue:(id)obj forContextKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
