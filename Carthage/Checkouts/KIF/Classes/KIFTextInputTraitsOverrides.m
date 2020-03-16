//
//  KIFTextInputTraitsOverrides.m
//  KIF
//
//  Created by Harley Cooper on 1/31/18.
//

#import <objc/runtime.h>
#import "KIFTextInputTraitsOverrides.h"

@interface KIFTextInputTraitsOverrides()

/*!
 @abstract Swizzles the @c autocorrectionType property of @c UITextField and @c UITextView
 @discussion Sets the property to have default behavior when @c allowDefaultAutocorrectBehavior is set to @c YES, and always return @c UITextAutocorrectionTypeNo when it's set to no.
 */
+ (void)KIFSwizzleTextInputFieldsAutocorrect;

/*!
 @abstract Swizzles the @c smartDashesType property of @c UITextField and @c UITextView
 @discussion Sets the property to have default behavior when @c allowDefaultSmartDashesBehavior is set to @c YES, and always return @c UITextSmartDashesTypeNo when it's set to no.
 */
+ (void)KIFSwizzleTextInputFieldsSmartDashes;

/*!
 @abstract Swizzles the @c smartQuotesType property of @c UITextField and @c UITextView
 @discussion Sets the property to have default behavior when @c allowDefaultSmartQuotesBehavior is set to @c YES, and always return @c UITextSmartQuotesTypeNo when it's set to no.
 */
+ (void)KIFSwizzleTextInputFieldsSmartQuotes;

@end

@implementation KIFTextInputTraitsOverrides

typedef NSInteger (*send_type_uitextfield)(UITextField*, SEL);
typedef NSInteger (*send_type_uitextview)(UITextView*, SEL);

static BOOL KIFAutocorrectEnabled = NO;
static BOOL KIFSmartDashesEnabled = NO;
static BOOL KIFSmartQuotesEnabled = NO;

+ (void)load
{
    [self KIFSwizzleTextInputFieldsAutocorrect];
    [self KIFSwizzleTextInputFieldsSmartDashes];
    [self KIFSwizzleTextInputFieldsSmartQuotes];
}

+ (BOOL)allowDefaultAutocorrectBehavior
{
    return KIFAutocorrectEnabled;
}

+ (void)setAllowDefaultAutocorrectBehavior:(BOOL)allowDefaultBehavior
{
    KIFAutocorrectEnabled = allowDefaultBehavior;
}

+ (BOOL)allowDefaultSmartDashesBehavior
{
    return KIFSmartDashesEnabled;
}

+ (void)setAllowDefaultSmartDashesBehavior:(BOOL)allowDefaultBehavior
{
    KIFSmartDashesEnabled = allowDefaultBehavior;
}

+ (BOOL)allowDefaultSmartQuotesBehavior
{
    return KIFSmartQuotesEnabled;
}

+ (void)setAllowDefaultSmartQuotesBehavior:(BOOL)allowDefaultBehavior
{
    KIFSmartQuotesEnabled = allowDefaultBehavior;
}

+ (void)KIFSwizzleTextInputFieldsAutocorrect
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct objc_method_description autocorrectionTypeMethodDescription = protocol_getMethodDescription(@protocol(UITextInputTraits), @selector(autocorrectionType), NO, YES);
        send_type_uitextfield autocorrectOriginalImp_textField = (send_type_uitextfield)[UITextField instanceMethodForSelector:@selector(autocorrectionType)];
        send_type_uitextview autocorrectOriginalImp_textView = (send_type_uitextview)[UITextView instanceMethodForSelector:@selector(autocorrectionType)];

        IMP autocorrectImp_textView = imp_implementationWithBlock(^(UITextView *_self) {
            if(self.allowDefaultAutocorrectBehavior) {
                return autocorrectOriginalImp_textView(_self, @selector(autocorrectionType));
            } else {
                return UITextAutocorrectionTypeNo;
            }
        });

        IMP autocorrectImp_textField = imp_implementationWithBlock(^(UITextField *_self) {
            if(self.allowDefaultAutocorrectBehavior) {
                return autocorrectOriginalImp_textField(_self, @selector(autocorrectionType));
            } else {
                return UITextAutocorrectionTypeNo;
            }
        });

        class_replaceMethod([UITextField class], @selector(autocorrectionType), autocorrectImp_textField, autocorrectionTypeMethodDescription.types);
        class_replaceMethod([UITextView class], @selector(autocorrectionType), autocorrectImp_textView, autocorrectionTypeMethodDescription.types);
    });
}

+ (void)KIFSwizzleTextInputFieldsSmartDashes
{
    // This #ifdef is necessary for versions of Xcode before Xcode 9.
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            struct objc_method_description smartDashesTypeMethodDescription = protocol_getMethodDescription(@protocol(UITextInputTraits), @selector(smartDashesType), NO, YES);
            send_type_uitextfield smartDashesOriginalImp_textField = (send_type_uitextfield)[UITextField instanceMethodForSelector:@selector(smartDashesType)];
            send_type_uitextview smartDashesOriginalImp_textView = (send_type_uitextview)[UITextView instanceMethodForSelector:@selector(smartDashesType)];

            IMP smartDashesImp_textField = imp_implementationWithBlock(^(UITextField *_self) {
                if(self.allowDefaultSmartDashesBehavior) {
                    return smartDashesOriginalImp_textField(_self, @selector(smartQuotesType));
                } else {
                    return UITextSmartDashesTypeNo;
                }
            });
            IMP smartDashesImp_textView = imp_implementationWithBlock(^(UITextView *_self) {
                if(self.allowDefaultSmartDashesBehavior) {
                    return smartDashesOriginalImp_textView(_self, @selector(smartQuotesType));
                } else {
                    return UITextSmartDashesTypeNo;
                }
            });

            class_replaceMethod([UITextField class], @selector(smartDashesType), smartDashesImp_textField, smartDashesTypeMethodDescription.types);
            class_replaceMethod([UITextView class], @selector(smartDashesType), smartDashesImp_textView, smartDashesTypeMethodDescription.types);
        });
    }
#endif
}

+ (void)KIFSwizzleTextInputFieldsSmartQuotes
{
        // This #ifdef is necessary for versions of Xcode before Xcode 9.
#ifdef __IPHONE_11_0
        if (@available(iOS 11.0, *)) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                struct objc_method_description smartQuotesTypeMethodDescription = protocol_getMethodDescription(@protocol(UITextInputTraits), @selector(smartQuotesType), NO, YES);
                send_type_uitextfield smartQuotesOriginalImp_textField = (send_type_uitextfield)[UITextField instanceMethodForSelector:@selector(smartDashesType)];
                send_type_uitextview smartQuotesOriginalImp_textView = (send_type_uitextview)[UITextView instanceMethodForSelector:@selector(smartDashesType)];

                IMP smartQuotesImp_textField = imp_implementationWithBlock(^(UITextField *_self) {
                    if(self.allowDefaultSmartQuotesBehavior) {
                        return smartQuotesOriginalImp_textField(_self, @selector(smartQuotesType));
                    } else {
                        return UITextSmartQuotesTypeNo;
                    }
                });
                IMP smartQuotesImp_textView = imp_implementationWithBlock(^(UITextView *_self) {
                    if(self.allowDefaultSmartQuotesBehavior) {
                        return smartQuotesOriginalImp_textView(_self, @selector(smartQuotesType));
                    } else {
                        return UITextSmartQuotesTypeNo;
                    }
                });

                class_replaceMethod([UITextField class], @selector(smartQuotesType), smartQuotesImp_textField, smartQuotesTypeMethodDescription.types);
                class_replaceMethod([UITextView class], @selector(smartQuotesType), smartQuotesImp_textView, smartQuotesTypeMethodDescription.types);
            });
        }
#endif
}

@end
