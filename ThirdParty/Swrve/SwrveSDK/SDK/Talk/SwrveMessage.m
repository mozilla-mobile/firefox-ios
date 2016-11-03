#import "SwrveMessage.h"
#import "Swrve.h"
#import "SwrveButton.h"
#import "SwrveImage.h"

@interface SwrveMessage()

@property (nonatomic, weak) SwrveMessageController* controller;

@end

@implementation SwrveMessage

@synthesize controller, campaign, messageID, name, priority, formats;

-(SwrveMessageFormat*)getBestFormatFor:(UIInterfaceOrientation)orientation
{    
    for (SwrveMessageFormat* format in formats)
    {
        bool format_is_landscape = format.orientation == SWRVE_ORIENTATION_LANDSCAPE;
        if (UIInterfaceOrientationIsLandscape(orientation))
        {
            // device is landscape
            if (format_is_landscape) return format;
        }
        else
        {
            // device is portrait
            if(!format_is_landscape) return format;
        }
    }
    return nil;
}

-(BOOL)supportsOrientation:(UIInterfaceOrientation)orientation
{
    return (nil != [self getBestFormatFor:orientation]);
}

-(SwrveMessage*)updateWithJSON:(NSDictionary*)json
                 forCampaign:(SwrveCampaign*)_campaign
                 forController:(SwrveMessageController*)_controller
{
    self.campaign     = _campaign;
    self.controller   = _controller;
    self.messageID    = [json objectForKey:@"id"];
    self.name         = [json objectForKey:@"name"];
    if ([json objectForKey:@"priority"]) {
        self.priority = [json objectForKey:@"priority"];
    } else {
        self.priority = [NSNumber numberWithInt:9999];
    }

    NSDictionary* messageTemplate = (NSDictionary*)[json objectForKey:@"template"];
    
    NSArray* jsonFormats = [messageTemplate objectForKey:@"formats"];
    
    NSMutableArray* loadedFormats = [[NSMutableArray alloc] init];
    
    for (NSDictionary* jsonFormat in jsonFormats)
    {
        SwrveMessageFormat* format = [[SwrveMessageFormat alloc] initFromJson:jsonFormat
                                                                forController:controller
                                                                   forMessage:self];
        [loadedFormats addObject:format];
    }

    self.formats = [[NSArray alloc] initWithArray:loadedFormats];
    return self;
}

+(SwrveMessage*)fromJSON:(NSDictionary*)json forCampaign:(SwrveCampaign*)campaign forController:(SwrveMessageController*)controller
{
    return [[[SwrveMessage alloc] init] updateWithJSON:json
                                         forCampaign: campaign
                                         forController:controller];
}

static bool in_cache(NSString* file, NSSet* set){
    return [file length] == 0 || [set containsObject:file];
}

-(BOOL)assetsReady:(NSSet*)assets
{
    for (SwrveMessageFormat* format in self.formats) {
        for (SwrveButton* button in format.buttons) {
            if (!in_cache(button.image, assets)){
                DebugLog(@"Button Asset not yet downloaded: %@", button.image);
                return false;
            }
        }

        for (SwrveImage* image in format.images) {
            if (!in_cache(image.file, assets)){
                DebugLog(@"Image Asset not yet downloaded: %@", image.file);
                return false;
            }
        }
    }

    return true;
}

-(void)wasShownToUser
{
    SwrveMessageController* c = self.controller;
    if (c != nil) {
        [c messageWasShownToUser:self];
    }
}

@end
