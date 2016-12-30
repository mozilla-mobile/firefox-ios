#import "SwrveConversationUIButton.h"
#import "SwrveContentStarRatingView.h"
#import <Foundation/Foundation.h>

@interface SwrveConversationStyler : NSObject

+ (void)styleView:(UIView *)uiView withStyle:(NSDictionary*)style;
+ (void)styleModalView:(UIView *)uiView withStyle:(NSDictionary*)style;
+ (NSString *) convertContentToHtml:(NSString*)content withPageCSS:(NSString*)pageCSS withStyle:(NSDictionary*)style;
+ (NSString *)colorFromStyle:(NSDictionary *)dict withDefault:(NSString*) defaultColor;
+ (UIColor *) convertToUIColor:(NSString*)color;
+ (float) convertBorderRadius:(float)borderRadiusPercentage;
+ (void) styleButton:(SwrveConversationUIButton *)button withStyle:(NSDictionary*)style;
+ (void) styleStarRating:(SwrveContentStarRatingView*)ratingView withStyle:(NSDictionary*)style withStarColor:(NSString*)starColorHex;

@end
