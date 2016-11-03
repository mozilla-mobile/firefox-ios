#import "UIWebView+YouTubeVimeo.h"
#import "SwrveSetup.h"

@implementation UIWebView (YouTubeVimeo)


-(NSString *)vimeoEmbed:(NSString *)url {
    return url;
}

-(void)loadYouTubeOrVimeoVideo:(NSString*)videoUrl {
    if ([videoUrl rangeOfString:@"vimeo"].length > 0) {
        [self loadVideo:videoUrl];
    } else if ([videoUrl rangeOfString:@"youtube"].length > 0) {
        [self loadVideo:videoUrl];
    } else {
        // It's not video, nor is it youtube, so we are not sure what to do.
        // The backend video URL conditioning should mean that we don't get here.
    }
}

-(void)loadVideo:(NSString*)url {
    self.scrollView.bounces = NO;
    self.scrollView.scrollEnabled = NO;
    [self setMediaPlaybackRequiresUserAction:NO];
    [self loadHTMLString:[self embedVideoInHTML:url] baseURL:[NSURL URLWithString:@"/"]];
}

-(NSString *)embedVideoInHTML:(NSString *)url {
    NSString *htmlString = @"<html style=\"margin:0;\"><head><meta name=\"viewport\" content=\"initial-scale = 1.0, user-scalable = no\"/></head><body style=\"background:#000000;margin:0;\"><iframe width=\"100%%\" height=\"100%%\" src=\"%@\" frameborder=\"0\" allowfullscreen></iframe></body></html>";
    return [NSString stringWithFormat:htmlString, url];
}

@end
