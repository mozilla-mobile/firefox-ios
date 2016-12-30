#import "SwrveConversationStyler.h"
#import "SwrveConversationButton.h"
#import "SwrveSetup.h"

#define kSwrveKeyBg @"bg"
#define kSwrveKeyFg @"fg"
#define kSwrveKeyLb @"lb"
#define kSwrveKeyType @"type"
#define kSwrveKeyValue @"value"
#define kSwrveKeyBorderRadius @"border_radius"
#define kSwrveMaxBorderRadius 22.5

#define kSwrveTypeTransparent @"transparent"
#define kSwrveTypeColor @"color"

#define kSwrveDefaultColorBg @"#ffffff"   // white
#define kSwrveDefaultColorFg @"#000000"   // black
#define kSwrveDefaultColorLb @"#B3000000" // 70% alpha black

@implementation SwrveConversationStyler : NSObject

+ (void)styleView:(UIView *)uiView withStyle:(NSDictionary*)style {
    NSString *fgHexColor = [self colorFromStyle:[style objectForKey:kSwrveKeyFg] withDefault:kSwrveDefaultColorFg];
    UIColor *fgUIColor = [self convertToUIColor:fgHexColor];
    if([uiView isKindOfClass:[UITableViewCell class]] ) {
        UITableViewCell *uiTableViewCell = (UITableViewCell*)uiView;
        uiTableViewCell.textLabel.textColor = fgUIColor;
    }

    NSString *bgHexColor = [self colorFromStyle:[style objectForKey:kSwrveKeyBg] withDefault:kSwrveDefaultColorBg];
    UIColor *bgUIColor = [self convertToUIColor:bgHexColor];
    uiView.backgroundColor = bgUIColor;
}

+ (void)styleModalView:(UIView *)uiView withStyle:(NSDictionary*)style {
    if([style.allKeys containsObject:kSwrveKeyBorderRadius]){
        float border = [self convertBorderRadius:[[style objectForKey:kSwrveKeyBorderRadius] floatValue]];
        uiView.layer.cornerRadius = border;
    }
    
    NSDictionary *lightBox = [style objectForKey:kSwrveKeyLb];
    NSString *color = [self colorFromStyle:lightBox withDefault:kSwrveDefaultColorLb];
    uiView.superview.backgroundColor = [self convertToUIColor:color];
}

+ (NSString *)colorFromStyle:(NSDictionary *)dict withDefault:(NSString*) defaultColor {
    if (dict) {
        NSString *type = [dict objectForKey:kSwrveKeyType];
        if ([type isEqualToString:kSwrveTypeTransparent]) {
            return kSwrveTypeTransparent;
        } else if ([type isEqualToString:kSwrveTypeColor]) {
            return [dict objectForKey:kSwrveKeyValue];
        }
    }
    return defaultColor;
}


+ (UIColor *) convertToUIColor:(NSString*)color {
    UIColor *uiColor;
    if ([color isEqualToString:kSwrveTypeTransparent]) {
        uiColor = [UIColor clearColor];
    } else {
        uiColor = [self processHexColorValue:color];
    }
    return uiColor;
}

+ (UIColor *) processHexColorValue:(NSString *)color {
    NSString *colorString = [[color stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    UIColor *returnColor;
    
    if([colorString length] == 6) {
        unsigned int hexInt = 0;
        NSScanner *scanner = [NSScanner scannerWithString:colorString];
        [scanner scanHexInt:&hexInt];
        returnColor = Swrve_UIColorFromRGB(hexInt, 1.0f);
        
    }else if([colorString length] == 8) {
        
        NSString *alphaSub = [colorString substringWithRange: NSMakeRange(0, 2)];
        NSString *colorSub = [colorString substringWithRange: NSMakeRange(2, 6)];
        
        unsigned hexComponent;
        unsigned int hexInt = 0;
        [[NSScanner scannerWithString: alphaSub] scanHexInt: &hexComponent];
        float alpha = hexComponent / 255.0f;
        
        NSScanner *scanner = [NSScanner scannerWithString:colorSub];
        [scanner scanHexInt:&hexInt];
        returnColor = Swrve_UIColorFromRGB(hexInt, alpha);
    }
    
    return returnColor;
}

+ (NSString *) convertContentToHtml:(NSString*)content withPageCSS:(NSString*)pageCSS withStyle:(NSDictionary*)style {
    NSString *fgHexColor = [self colorFromStyle:[style objectForKey:kSwrveKeyFg] withDefault:kSwrveDefaultColorFg];
    NSString *bgHexColor = [self colorFromStyle:[style objectForKey:kSwrveKeyBg] withDefault:kSwrveDefaultColorBg];

    NSString *html = [NSString stringWithFormat:@"<html><head><style type=\"text/css\">%@ html { color: %@; } \
                          body { background-color: %@; } \
                          </style> \
                          </head> \
                          <body> \
                          %@ \
                          </body></html>", pageCSS, fgHexColor, bgHexColor, content];
    
    return html;
}

+ (float) convertBorderRadius:(float)borderRadiusPercentage {
    if(borderRadiusPercentage >= 100.0){
        return (float)kSwrveMaxBorderRadius;
    }else{
        float percentage = borderRadiusPercentage / 100;
        return (float)kSwrveMaxBorderRadius * percentage;
    }
}

+ (void) styleButton:(SwrveConversationUIButton*)button withStyle:(NSDictionary*)style {
    NSString *fgHexColor = [self colorFromStyle:[style objectForKey:kSwrveKeyFg] withDefault:kSwrveDefaultColorFg];
    UIColor *fgUIColor = [self convertToUIColor:fgHexColor];
    NSString *styleType = kSwrveTypeSolid;
    if([style objectForKey:kSwrveKeyType]) {
        styleType = [style objectForKey:kSwrveKeyType];
    }
    NSString *bgHexColor = [self colorFromStyle:[style objectForKey:kSwrveKeyBg] withDefault:kSwrveDefaultColorBg];
    UIColor *bgUIColor = [self convertToUIColor:bgHexColor];
    float borderRadius = [self convertBorderRadius:[[style objectForKey:kSwrveKeyBorderRadius] floatValue]];
    
    [button initButtonType:styleType withForegroundColor:fgUIColor withBackgroundColor:bgUIColor withBorderRadius:borderRadius];
}

+ (void) styleStarRating:(SwrveContentStarRatingView*)ratingView withStyle:(NSDictionary*)style withStarColor:(NSString*)starColorHex {

    NSString *styleType = kSwrveTypeSolid;
    if([style objectForKey:kSwrveKeyType]) {
        styleType = [style objectForKey:kSwrveKeyType];
    }
    NSString *bgHexColor = [self colorFromStyle:[style objectForKey:kSwrveKeyBg] withDefault:kSwrveDefaultColorBg];
    UIColor *bgUIColor = [self convertToUIColor:bgHexColor];
    UIColor *starColor = [self convertToUIColor:starColorHex];
    
    [ratingView updateWithStarColor:starColor withBackgroundColor:bgUIColor];
}

@end
