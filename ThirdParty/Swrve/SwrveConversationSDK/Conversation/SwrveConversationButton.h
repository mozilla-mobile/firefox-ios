#import <Foundation/Foundation.h>
#import "SwrveConversationAtom.h"

#define kSwrveKeyDescription @"description"
#define kSwrveTypeSolid @"solid"
#define kSwrveTypeOutline @"outline"

@interface SwrveConversationButton : SwrveConversationAtom

-(id) initWithTag:(NSString *)tag andDescription:(NSString *)description;
-(BOOL) endsConversation;

@property (readonly, nonatomic) NSString     *description;
@property (strong, nonatomic)   NSDictionary *actions;
@property (strong, nonatomic)   NSString     *target;

@end
