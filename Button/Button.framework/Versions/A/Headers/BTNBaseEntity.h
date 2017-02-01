#import "BTNModelObject.h"
#import "BTNSubscriptableProtocol.h"

/**
 All fields are optional and should be populated only if known.
 */

NS_ASSUME_NONNULL_BEGIN

@interface BTNBaseEntity : BTNModelObject <BTNSubscriptable>

/**
 Specifies the name of the entity (location, artist, event, journey, item, etc).
 @note: This string may be visible in recipient applications.
 */
- (void)setName:(NSString *)name;


/**
 A URL that specifies the current context. 
 @note: This can either be a Universal Links representation of the page or URL of the canonical crawlable web page.
 */
- (void)setURL:(NSURL *)URL;



///-------------------------------------
/// @name Adding Third Party Identifiers
///--------------------------------------


/**
 Adds an identifier for a third party provider to aid in mapping services.
 @param identifier An identifier that maps to a third party service.
 @param provider The third party provider of the identifier. @see Known Providers below.
 */
- (void)addIdentifier:(NSString *)identifier forProvider:(NSString *)provider;



///---------------------
/// @name Custom Context
///---------------------

/**
 Add custom key-value pairs to further define your users context.
 @note you can also use object subscripting (e.g. object[key] = value) @see BTNSubscriptable
 */
- (void)addCustomValue:(id)obj forContextKey:(NSString *)key;

@end


///----------------------
/// @name Known Providers
///----------------------

extern NSString * const BTNIDProviderAmazon;
extern NSString * const BTNIDProviderDeliveryHero;
extern NSString * const BTNIDProviderFacebook;
extern NSString * const BTNIDProviderFactual;
extern NSString * const BTNIDProviderFoursquare;
extern NSString * const BTNIDProviderGoogleMaps;
extern NSString * const BTNIDProviderOpenStreetMap;
extern NSString * const BTNIDProviderOpenTable;
extern NSString * const BTNIDProviderTicketmaster;
extern NSString * const BTNIDProviderWalmart;
extern NSString * const BTNIDProviderYelp;

extern NSString * const BTNIDProviderSelfProvided;

NS_ASSUME_NONNULL_END
