#import "SwrveConversationAtomFactory.h"
#import "SwrveContentHTML.h"
#import "SwrveContentImage.h"
#import "SwrveContentVideo.h"
#import "SwrveContentSpacer.h"
#import "SwrveConversationButton.h"
#import "SwrveContentStarRating.h"
#import "SwrveInputMultiValue.h"

#define kSwrveKeyTag @"tag"
#define kSwrveKeyType @"type"

@implementation SwrveConversationAtomFactory

+ (NSMutableArray <SwrveConversationAtom *> *) atomsForDictionary:(NSDictionary *)dict {
    NSString *tag = [dict objectForKey:kSwrveKeyTag];
    NSString *type = [dict objectForKey:kSwrveKeyType];
    
    NSMutableArray<SwrveConversationAtom *> *atomArray = [NSMutableArray array];
    
    if(type == nil) {
        type = kSwrveControlTypeButton;
    }

    // Create some resilience with defaults for tag and type.
    // the tag must be unique within the context of the page.
    if (tag == nil) {
        tag = [[NSUUID UUID] UUIDString];
    }
    
    if([type isEqualToString:kSwrveContentTypeHTML]) {
        SwrveContentHTML *swrveContentHTML = [[SwrveContentHTML alloc] initWithTag:tag andDictionary:dict];
        swrveContentHTML.style = [dict objectForKey:@"style"];
        [atomArray addObject:swrveContentHTML];
    } else if([type isEqualToString:kSwrveContentTypeImage]) {
        SwrveContentImage *swrveContentImage = [[SwrveContentImage alloc] initWithTag:tag andDictionary:dict];
        swrveContentImage.style = [dict objectForKey:@"style"];
        [atomArray addObject:swrveContentImage];
    } else if([type isEqualToString:kSwrveContentTypeVideo]) {
        SwrveContentVideo *swrveContentVideo = [[SwrveContentVideo alloc] initWithTag:tag andDictionary:dict];
        swrveContentVideo.style = [dict objectForKey:@"style"];
        [atomArray addObject:swrveContentVideo];
    } else if([type isEqualToString:kSwrveControlTypeButton]) {
        SwrveConversationButton *swrveConversationButton = [[SwrveConversationButton alloc] initWithTag:tag andDescription:[dict objectForKey:kSwrveKeyDescription]];
        swrveConversationButton.actions = [dict objectForKey:@"action"];
        swrveConversationButton.style = [dict objectForKey:@"style"];
        NSString *target = [dict objectForKey:@"target"]; // Leave the target nil if this a conversation ender (i.e. no following state)
        if (target && ![target isEqualToString:@""]) {
            swrveConversationButton.target = target;
        }
        [atomArray addObject:swrveConversationButton];
    } else if([type isEqualToString:kSwrveInputMultiValue]) {
        SwrveInputMultiValue *swrveInputMultiValue = [[SwrveInputMultiValue alloc] initWithTag:tag andDictionary:dict];
        swrveInputMultiValue.style = [dict objectForKey:@"style"];
        [atomArray addObject:swrveInputMultiValue];
        
    } else if ([type isEqualToString:kSwrveContentSpacer]) {
        SwrveContentSpacer* swrveContentSpacer = [[SwrveContentSpacer alloc] initWithTag:tag andDictionary:dict];
        swrveContentSpacer.style = [dict objectForKey:@"style"];
        [atomArray addObject:swrveContentSpacer];
    } else if ([type isEqualToString:kSwrveControlStarRating]) {
        SwrveContentHTML *swrveContentHTML = [[SwrveContentHTML alloc] initWithTag:tag andDictionary:dict];
        swrveContentHTML.style = [dict objectForKey:@"style"];
        [atomArray addObject:swrveContentHTML];
        SwrveContentStarRating *swrveConversationStarRating = [[SwrveContentStarRating alloc] initWithTag:tag andDictionary:dict];
        swrveConversationStarRating.style = [dict objectForKey:@"style"];
        [atomArray addObject:swrveConversationStarRating];
    }
    
    return atomArray;
}

@end
