#import "BTNBaseEntity.h"

/**
 All fields are optional and should be populated only if known.
 @see `BTNBaseEntity` for inherited configuration options.
 */

NS_ASSUME_NONNULL_BEGIN

@interface BTNMusicArtist : BTNBaseEntity

/**
 Returns an instance with a given name.
 @param name The artist's name.
 */
+ (instancetype)artistWithName:(NSString *)name;


/// Sets the genre of the artist.
- (void)setGenre:(NSString *)genre;

@end

NS_ASSUME_NONNULL_END
