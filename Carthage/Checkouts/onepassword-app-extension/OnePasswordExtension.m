//
//  1Password Extension
//
//  Lovingly handcrafted by Dave Teare, Michael Fey, Rad Azzouz, and Roustem Karimov.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "OnePasswordExtension.h"

// Version
#define VERSION_NUMBER @(185)
static NSString *const AppExtensionVersionNumberKey = @"version_number";

// Available App Extension Actions
static NSString *const kUTTypeAppExtensionFindLoginAction = @"org.appextension.find-login-action";
static NSString *const kUTTypeAppExtensionSaveLoginAction = @"org.appextension.save-login-action";
static NSString *const kUTTypeAppExtensionChangePasswordAction = @"org.appextension.change-password-action";
static NSString *const kUTTypeAppExtensionFillWebViewAction = @"org.appextension.fill-webview-action";
static NSString *const kUTTypeAppExtensionFillBrowserAction = @"org.appextension.fill-browser-action";

// WebView Dictionary keys
static NSString *const AppExtensionWebViewPageFillScript = @"fillScript";
static NSString *const AppExtensionWebViewPageDetails = @"pageDetails";

@implementation OnePasswordExtension

#pragma mark - Public Methods

+ (OnePasswordExtension *)sharedExtension {
	static dispatch_once_t onceToken;
	static OnePasswordExtension *__sharedExtension;

	dispatch_once(&onceToken, ^{
		__sharedExtension = [OnePasswordExtension new];
	});

	return __sharedExtension;
}

- (BOOL)isAppExtensionAvailable {
	if ([self isSystemAppExtensionAPIAvailable]) {
		return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"org-appextension-feature-password-management://"]];
	}

	return NO;
}

#pragma mark - Native app Login

- (void)findLoginForURLString:(nonnull NSString *)URLString forViewController:(nonnull UIViewController *)viewController sender:(nullable id)sender completion:(nonnull OnePasswordLoginDictionaryCompletionBlock)completion {
	NSAssert(URLString != nil, @"URLString must not be nil");
	NSAssert(viewController != nil, @"viewController must not be nil");

	if (NO == [self isSystemAppExtensionAPIAvailable]) {
		NSLog(@"Failed to findLoginForURLString, system API is not available");
		if (completion) {
			completion(nil, [OnePasswordExtension systemAppExtensionAPINotAvailableError]);
		}

		return;
	}

#ifdef __IPHONE_8_0
	NSDictionary *item = @{ AppExtensionVersionNumberKey: VERSION_NUMBER, AppExtensionURLStringKey: URLString };

	UIActivityViewController *activityViewController = [self activityViewControllerForItem:item viewController:viewController sender:sender typeIdentifier:kUTTypeAppExtensionFindLoginAction];
	activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		if (returnedItems.count == 0) {
			NSError *error = nil;
			if (activityError) {
				NSLog(@"Failed to findLoginForURLString: %@", activityError);
				error = [OnePasswordExtension failedToContactExtensionErrorWithActivityError:activityError];
			}
			else {
				error = [OnePasswordExtension extensionCancelledByUserError];
			}

			if (completion) {
				completion(nil, error);
			}

			return;
		}

		[self processExtensionItem:returnedItems.firstObject completion:^(NSDictionary *itemDictionary, NSError *error) {
			if (completion) {
				completion(itemDictionary, error);
			}
		}];
	};

	[viewController presentViewController:activityViewController animated:YES completion:nil];
#endif
}

#pragma mark - New User Registration

- (void)storeLoginForURLString:(nonnull NSString *)URLString loginDetails:(nullable NSDictionary *)loginDetailsDictionary passwordGenerationOptions:(nullable NSDictionary *)passwordGenerationOptions forViewController:(nonnull UIViewController *)viewController sender:(nullable id)sender completion:(nonnull OnePasswordLoginDictionaryCompletionBlock)completion {
	NSAssert(URLString != nil, @"URLString must not be nil");
	NSAssert(viewController != nil, @"viewController must not be nil");

	if (NO == [self isSystemAppExtensionAPIAvailable]) {
		NSLog(@"Failed to storeLoginForURLString, system API is not available");
		if (completion) {
			completion(nil, [OnePasswordExtension systemAppExtensionAPINotAvailableError]);
		}

		return;
	}


#ifdef __IPHONE_8_0
	NSMutableDictionary *newLoginAttributesDict = [NSMutableDictionary new];
	newLoginAttributesDict[AppExtensionVersionNumberKey] = VERSION_NUMBER;
	newLoginAttributesDict[AppExtensionURLStringKey] = URLString;
	[newLoginAttributesDict addEntriesFromDictionary:loginDetailsDictionary];
	if (passwordGenerationOptions.count > 0) {
		newLoginAttributesDict[AppExtensionPasswordGeneratorOptionsKey] = passwordGenerationOptions;
	}

	UIActivityViewController *activityViewController = [self activityViewControllerForItem:newLoginAttributesDict viewController:viewController sender:sender typeIdentifier:kUTTypeAppExtensionSaveLoginAction];
	activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		if (returnedItems.count == 0) {
			NSError *error = nil;
			if (activityError) {
				NSLog(@"Failed to storeLoginForURLString: %@", activityError);
				error = [OnePasswordExtension failedToContactExtensionErrorWithActivityError:activityError];
			}
			else {
				error = [OnePasswordExtension extensionCancelledByUserError];
			}

			if (completion) {
				completion(nil, error);
			}

			return;
		}

		[self processExtensionItem:returnedItems.firstObject completion:^(NSDictionary *itemDictionary, NSError *error) {
			if (completion) {
				completion(itemDictionary, error);
			}
		}];
	};

	[viewController presentViewController:activityViewController animated:YES completion:nil];
#endif
}

#pragma mark - Change Password

- (void)changePasswordForLoginForURLString:(nonnull NSString *)URLString loginDetails:(nullable NSDictionary *)loginDetailsDictionary passwordGenerationOptions:(nullable NSDictionary *)passwordGenerationOptions forViewController:(UIViewController *)viewController sender:(nullable id)sender completion:(nonnull OnePasswordLoginDictionaryCompletionBlock)completion {
	NSAssert(URLString != nil, @"URLString must not be nil");
	NSAssert(viewController != nil, @"viewController must not be nil");

	if (NO == [self isSystemAppExtensionAPIAvailable]) {
		NSLog(@"Failed to changePasswordForLoginWithUsername, system API is not available");
		if (completion) {
			completion(nil, [OnePasswordExtension systemAppExtensionAPINotAvailableError]);
		}

		return;
	}

#ifdef __IPHONE_8_0
	NSMutableDictionary *item = [NSMutableDictionary new];
	item[AppExtensionVersionNumberKey] = VERSION_NUMBER;
	item[AppExtensionURLStringKey] = URLString;
	[item addEntriesFromDictionary:loginDetailsDictionary];
	if (passwordGenerationOptions.count > 0) {
		item[AppExtensionPasswordGeneratorOptionsKey] = passwordGenerationOptions;
	}

	UIActivityViewController *activityViewController = [self activityViewControllerForItem:item viewController:viewController sender:sender typeIdentifier:kUTTypeAppExtensionChangePasswordAction];

	activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		if (returnedItems.count == 0) {
			NSError *error = nil;
			if (activityError) {
				NSLog(@"Failed to changePasswordForLoginWithUsername: %@", activityError);
				error = [OnePasswordExtension failedToContactExtensionErrorWithActivityError:activityError];
			}
			else {
				error = [OnePasswordExtension extensionCancelledByUserError];
			}

			if (completion) {
				completion(nil, error);
			}

			return;
		}

		[self processExtensionItem:returnedItems.firstObject completion:^(NSDictionary *itemDictionary, NSError *error) {
			if (completion) {
				completion(itemDictionary, error);
			}
		}];
	};

	[viewController presentViewController:activityViewController animated:YES completion:nil];
#endif
}

#pragma mark - Web View filling Support

- (void)fillItemIntoWebView:(nonnull id)webView forViewController:(nonnull UIViewController *)viewController sender:(nullable id)sender showOnlyLogins:(BOOL)yesOrNo completion:(nonnull OnePasswordSuccessCompletionBlock)completion {
	NSAssert(webView != nil, @"webView must not be nil");
	NSAssert(viewController != nil, @"viewController must not be nil");
	NSAssert([webView isKindOfClass:[WKWebView class]], @"webView must be an instance of WKWebView.");

    [self fillItemIntoWKWebView:webView forViewController:viewController sender:(id)sender showOnlyLogins:yesOrNo completion:^(BOOL success, NSError *error) {
        if (completion) {
            completion(success, error);
        }
    }];
}

#pragma mark - Support for custom UIActivityViewControllers

- (BOOL)isOnePasswordExtensionActivityType:(nullable NSString *)activityType {
	return [@"com.agilebits.onepassword-ios.extension" isEqualToString:activityType] || [@"com.agilebits.beta.onepassword-ios.extension" isEqualToString:activityType];
}

- (void)createExtensionItemForWebView:(nonnull id)webView completion:(nonnull OnePasswordExtensionItemCompletionBlock)completion {
	NSAssert(webView != nil, @"webView must not be nil");
	NSAssert([webView isKindOfClass:[WKWebView class]], @"webView must be an instance of WKWebView.");
	
    WKWebView *wkWebView = (WKWebView *)webView;
    [wkWebView evaluateJavaScript:OPWebViewCollectFieldsScript completionHandler:^(NSString *result, NSError *evaluateError) {
        if (result == nil) {
            NSLog(@"1Password Extension failed to collect web page fields: %@", evaluateError);
            NSError *failedToCollectFieldsError = [OnePasswordExtension failedToCollectFieldsErrorWithUnderlyingError:evaluateError];
            if (completion) {
                if ([NSThread isMainThread]) {
                    completion(nil, failedToCollectFieldsError);
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(nil, failedToCollectFieldsError);
                    });
                }
            }

            return;
        }

        [self createExtensionItemForURLString:wkWebView.URL.absoluteString webPageDetails:result completion:completion];
    }];
}

- (void)fillReturnedItems:(nullable NSArray *)returnedItems intoWebView:(nonnull id)webView completion:(nonnull OnePasswordSuccessCompletionBlock)completion {
	NSAssert(webView != nil, @"webView must not be nil");

	if (returnedItems.count == 0) {
		NSError *error = [OnePasswordExtension extensionCancelledByUserError];
		if (completion) {
			completion(NO, error);
		}

		return;
	}

	[self processExtensionItem:returnedItems.firstObject completion:^(NSDictionary *itemDictionary, NSError *error) {
		if (itemDictionary.count == 0) {
			if (completion) {
				completion(NO, error);
			}

			return;
		}

		NSString *fillScript = itemDictionary[AppExtensionWebViewPageFillScript];
		[self executeFillScript:fillScript inWebView:webView completion:^(BOOL success, NSError *executeFillScriptError) {
			if (completion) {
				completion(success, executeFillScriptError);
			}
		}];
	}];
}

#pragma mark - Private methods

- (BOOL)isSystemAppExtensionAPIAvailable {
#ifdef __IPHONE_8_0
	return [NSExtensionItem class] != nil;
#else
	return NO;
#endif
}

- (void)findLoginIn1PasswordWithURLString:(nonnull NSString *)URLString collectedPageDetails:(nullable NSString *)collectedPageDetails forWebViewController:(nonnull UIViewController *)forViewController sender:(nullable id)sender withWebView:(nonnull id)webView showOnlyLogins:(BOOL)yesOrNo completion:(nonnull OnePasswordSuccessCompletionBlock)completion {
	if ([URLString length] == 0) {
		NSError *URLStringError = [OnePasswordExtension failedToObtainURLStringFromWebViewError];
		NSLog(@"Failed to findLoginIn1PasswordWithURLString: %@", URLStringError);
		if (completion) {
			completion(NO, URLStringError);
		}
		return;
	}

	NSError *jsonError = nil;
	NSData *data = [collectedPageDetails dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *collectedPageDetailsDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];

	if (collectedPageDetailsDictionary.count == 0) {
		NSLog(@"Failed to parse JSON collected page details: %@", jsonError);
		if (completion) {
			completion(NO, jsonError);
		}
		return;
	}

	NSDictionary *item = @{ AppExtensionVersionNumberKey : VERSION_NUMBER, AppExtensionURLStringKey : URLString, AppExtensionWebViewPageDetails : collectedPageDetailsDictionary };

	NSString *typeIdentifier = yesOrNo ? kUTTypeAppExtensionFillWebViewAction  : kUTTypeAppExtensionFillBrowserAction;
	UIActivityViewController *activityViewController = [self activityViewControllerForItem:item viewController:forViewController sender:sender typeIdentifier:typeIdentifier];
	activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
		if (returnedItems.count == 0) {
			NSError *error = nil;
			if (activityError) {
				NSLog(@"Failed to findLoginIn1PasswordWithURLString: %@", activityError);
				error = [OnePasswordExtension failedToContactExtensionErrorWithActivityError:activityError];
			}
			else {
				error = [OnePasswordExtension extensionCancelledByUserError];
			}

			if (completion) {
				completion(NO, error);
			}

			return;
		}

		[self processExtensionItem:returnedItems.firstObject completion:^(NSDictionary *itemDictionary, NSError *processExtensionItemError) {
			if (itemDictionary.count == 0) {
				if (completion) {
					completion(NO, processExtensionItemError);
				}

				return;
			}

			NSString *fillScript = itemDictionary[AppExtensionWebViewPageFillScript];
			[self executeFillScript:fillScript inWebView:webView completion:^(BOOL success, NSError *executeFillScriptError) {
				if (completion) {
					completion(success, executeFillScriptError);
				}
			}];
		}];
	};

	[forViewController presentViewController:activityViewController animated:YES completion:nil];
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0 || ONE_PASSWORD_EXTENSION_ENABLE_WK_WEB_VIEW
- (void)fillItemIntoWKWebView:(nonnull WKWebView *)webView forViewController:(nonnull UIViewController *)viewController sender:(nullable id)sender showOnlyLogins:(BOOL)yesOrNo completion:(nonnull OnePasswordSuccessCompletionBlock)completion {
	[webView evaluateJavaScript:OPWebViewCollectFieldsScript completionHandler:^(NSString *result, NSError *error) {
		if (result == nil) {
			NSLog(@"1Password Extension failed to collect web page fields: %@", error);
			if (completion) {
				completion(NO,[OnePasswordExtension failedToCollectFieldsErrorWithUnderlyingError:error]);
			}

			return;
		}

		[self findLoginIn1PasswordWithURLString:webView.URL.absoluteString collectedPageDetails:result forWebViewController:viewController sender:sender withWebView:webView showOnlyLogins:yesOrNo completion:^(BOOL success, NSError *findLoginError) {
			if (completion) {
				completion(success, findLoginError);
			}
		}];
	}];
}
#endif

- (void)executeFillScript:(NSString * __nullable)fillScript inWebView:(nonnull id)webView completion:(nonnull OnePasswordSuccessCompletionBlock)completion {

	if (fillScript == nil) {
		NSLog(@"Failed to executeFillScript, fillScript is missing");
		if (completion) {
			completion(NO, [OnePasswordExtension failedToFillFieldsErrorWithLocalizedErrorMessage:NSLocalizedStringFromTable(@"Failed to fill web page because script is missing", @"OnePasswordExtension", @"1Password Extension Error Message") underlyingError:nil]);
		}

		return;
	}

	NSMutableString *scriptSource = [OPWebViewFillScript mutableCopy];
	[scriptSource appendFormat:@"(document, %@, undefined);", fillScript];

    if ([webView isKindOfClass:[WKWebView class]]) {
        [((WKWebView *)webView) evaluateJavaScript:scriptSource completionHandler:^(NSString *result, NSError *evaluationError) {
            BOOL success = (result != nil);
            NSError *error = nil;

            if (!success) {
                NSLog(@"Cannot executeFillScript, evaluateJavaScript failed: %@", evaluationError);
                error = [OnePasswordExtension failedToFillFieldsErrorWithLocalizedErrorMessage:NSLocalizedStringFromTable(@"Failed to fill web page because script could not be evaluated", @"OnePasswordExtension", @"1Password Extension Error Message") underlyingError:error];
            }

            if (completion) {
                completion(success, error);
            }
        }];
    }
}

#ifdef __IPHONE_8_0
- (void)processExtensionItem:(nullable NSExtensionItem *)extensionItem completion:(nonnull OnePasswordLoginDictionaryCompletionBlock)completion {
	if (extensionItem.attachments.count == 0) {
		NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Unexpected data returned by App Extension: extension item had no attachments." };
		NSError *error = [[NSError alloc] initWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeUnexpectedData userInfo:userInfo];
		if (completion) {
			completion(nil, error);
		}
		return;
	}

	NSItemProvider *itemProvider = extensionItem.attachments.firstObject;
	if (NO == [itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypePropertyList]) {
		NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Unexpected data returned by App Extension: extension item attachment does not conform to kUTTypePropertyList type identifier" };
		NSError *error = [[NSError alloc] initWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeUnexpectedData userInfo:userInfo];
		if (completion) {
			completion(nil, error);
		}
		return;
	}


	[itemProvider loadItemForTypeIdentifier:(__bridge NSString *)kUTTypePropertyList options:nil completionHandler:^(NSDictionary *itemDictionary, NSError *itemProviderError) {
		 NSError *error = nil;
		 if (itemDictionary.count == 0) {
			 NSLog(@"Failed to loadItemForTypeIdentifier: %@", itemProviderError);
			 error = [OnePasswordExtension failedToLoadItemProviderDataErrorWithUnderlyingError:itemProviderError];
		 }

		 if (completion) {
			 if ([NSThread isMainThread]) {
				 completion(itemDictionary, error);
			 }
			 else {
				 dispatch_async(dispatch_get_main_queue(), ^{
					 completion(itemDictionary, error);
				 });
			 }
		 }
	 }];
}

- (UIActivityViewController *)activityViewControllerForItem:(nonnull NSDictionary *)item viewController:(nonnull UIViewController*)viewController sender:(nullable id)sender typeIdentifier:(nonnull NSString *)typeIdentifier {
#ifdef __IPHONE_8_0
	NSAssert(NO == (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && sender == nil), @"sender must not be nil on iPad.");

	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:item typeIdentifier:typeIdentifier];

	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];

	UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[ extensionItem ]  applicationActivities:nil];

	if ([sender isKindOfClass:[UIBarButtonItem class]]) {
		controller.popoverPresentationController.barButtonItem = sender;
	}
	else if ([sender isKindOfClass:[UIView class]]) {
		controller.popoverPresentationController.sourceView = [sender superview];
		controller.popoverPresentationController.sourceRect = [sender frame];
	}
	else {
		NSLog(@"sender can be nil on iPhone");
	}

	return controller;
#else
	return nil;
#endif
}

#endif

- (void)createExtensionItemForURLString:(nonnull NSString *)URLString webPageDetails:(nullable NSString *)webPageDetails completion:(nonnull OnePasswordExtensionItemCompletionBlock)completion {
	NSError *jsonError = nil;
	NSData *data = [webPageDetails dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *webPageDetailsDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];

	if (webPageDetailsDictionary.count == 0) {
		NSLog(@"Failed to parse JSON collected page details: %@", jsonError);
		if (completion) {
			completion(nil, jsonError);
		}
		return;
	}

	NSDictionary *item = @{ AppExtensionVersionNumberKey : VERSION_NUMBER, AppExtensionURLStringKey : URLString, AppExtensionWebViewPageDetails : webPageDetailsDictionary };

	NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithItem:item typeIdentifier:kUTTypeAppExtensionFillBrowserAction];

	NSExtensionItem *extensionItem = [[NSExtensionItem alloc] init];
	extensionItem.attachments = @[ itemProvider ];

	if (completion) {
		if ([NSThread isMainThread]) {
			completion(extensionItem, nil);
		}
		else {
			dispatch_async(dispatch_get_main_queue(), ^{
				completion(extensionItem, nil);
			});
		}
	}
}

#pragma mark - Errors

+ (NSError *)systemAppExtensionAPINotAvailableError {
	NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedStringFromTable(@"App Extension API is not available in this version of iOS", @"OnePasswordExtension", @"1Password Extension Error Message") };
	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeAPINotAvailable userInfo:userInfo];
}


+ (NSError *)extensionCancelledByUserError {
	NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedStringFromTable(@"1Password Extension was cancelled by the user", @"OnePasswordExtension", @"1Password Extension Error Message") };
	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeCancelledByUser userInfo:userInfo];
}

+ (NSError *)failedToContactExtensionErrorWithActivityError:(nullable NSError *)activityError {
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	userInfo[NSLocalizedDescriptionKey] = NSLocalizedStringFromTable(@"Failed to contact the 1Password Extension", @"OnePasswordExtension", @"1Password Extension Error Message");
	if (activityError) {
		userInfo[NSUnderlyingErrorKey] = activityError;
	}

	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeFailedToContactExtension userInfo:userInfo];
}

+ (NSError *)failedToCollectFieldsErrorWithUnderlyingError:(nullable NSError *)underlyingError {
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	userInfo[NSLocalizedDescriptionKey] = NSLocalizedStringFromTable(@"Failed to execute script that collects web page information", @"OnePasswordExtension", @"1Password Extension Error Message");
	if (underlyingError) {
		userInfo[NSUnderlyingErrorKey] = underlyingError;
	}

	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeCollectFieldsScriptFailed userInfo:userInfo];
}

+ (NSError *)failedToFillFieldsErrorWithLocalizedErrorMessage:(nullable NSString *)errorMessage underlyingError:(nullable NSError *)underlyingError {
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	if (errorMessage) {
		userInfo[NSLocalizedDescriptionKey] = errorMessage;
	}
	if (underlyingError) {
		userInfo[NSUnderlyingErrorKey] = underlyingError;
	}

	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeFillFieldsScriptFailed userInfo:userInfo];
}

+ (NSError *)failedToLoadItemProviderDataErrorWithUnderlyingError:(nullable NSError *)underlyingError {
	NSMutableDictionary *userInfo = [NSMutableDictionary new];
	userInfo[NSLocalizedDescriptionKey] = NSLocalizedStringFromTable(@"Failed to parse information returned by 1Password Extension", @"OnePasswordExtension", @"1Password Extension Error Message");
	if (underlyingError) {
		userInfo[NSUnderlyingErrorKey] = underlyingError;
	}

	return [[NSError alloc] initWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeFailedToLoadItemProviderData userInfo:userInfo];
}

+ (NSError *)failedToObtainURLStringFromWebViewError {
	NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedStringFromTable(@"Failed to obtain URL String from web view. The web view must be loaded completely when calling the 1Password Extension", @"OnePasswordExtension", @"1Password Extension Error Message") };
	return [NSError errorWithDomain:AppExtensionErrorDomain code:AppExtensionErrorCodeFailedToObtainURLStringFromWebView userInfo:userInfo];
}

#pragma mark - WebView field collection and filling scripts

static NSString *const OPWebViewCollectFieldsScript = @";(function(document, undefined) {\
\
	document.addEventListener('input',function(b){!1!==b.isTrusted&&'input'===b.target.tagName.toLowerCase()&&(b.target.dataset['com.agilebits.onepassword.userEdited']='yes')},!0);\
(function(b,a,c){a.FieldCollector=new function(){function f(d){return d?d.toString().toLowerCase():''}function e(d,b,a,e){e!==c&&e===a||null===a||a===c||(d[b]=a)}function k(d,b){var a=[];try{a=d.querySelectorAll(b)}catch(J){console.error('[COLLECT FIELDS] @ag_querySelectorAll Exception in selector \"'+b+'\"')}return a}function m(d){var a,c=[];if(d.labels&&d.labels.length&&0<d.labels.length)c=Array.prototype.slice.call(d.labels);else{d.id&&(c=c.concat(Array.prototype.slice.call(k(b,'label[for='+JSON.stringify(d.id)+\
']'))));if(d.name){a=k(b,'label[for='+JSON.stringify(d.name)+']');for(var e=0;e<a.length;e++)-1===c.indexOf(a[e])&&c.push(a[e])}for(a=d;a&&a!=b;a=a.parentNode)'label'===f(a.tagName)&&-1===c.indexOf(a)&&c.push(a)}0===c.length&&(a=d.parentNode,'dd'===a.tagName.toLowerCase()&&null!==a.previousElementSibling&&'dt'===a.previousElementSibling.tagName.toLowerCase()&&c.push(a.previousElementSibling));return 0<c.length?c.map(function(d){return l(r(d))}).join(''):null}function n(d){var a;for(d=d.parentElement||\
d.parentNode;d&&'td'!=f(d.tagName);)d=d.parentElement||d.parentNode;if(!d||d===c)return null;a=d.parentElement||d.parentNode;if('tr'!=a.tagName.toLowerCase())return null;a=a.previousElementSibling;if(!a||'tr'!=(a.tagName+'').toLowerCase()||a.cells&&d.cellIndex>=a.cells.length)return null;d=r(a.cells[d.cellIndex]);return d=l(d)}function p(a){return a.options?(a=Array.prototype.slice.call(a.options).map(function(a){var d=a.text,d=d?f(d).replace(/\\s/mg,'').replace(/[~`!@$%^&*()\\-_+=:;'\"\\[\\]|\\\\,<.>\\/?]/mg,\
''):null;return[d?d:null,a.value]}),{options:a}):null}function F(a){switch(f(a.type)){case 'checkbox':return a.checked?'✓':'';case 'hidden':a=a.value;if(!a||'number'!=typeof a.length)return'';254<a.length&&(a=a.substr(0,254)+'...SNIPPED');return a;case 'submit':case 'button':case 'reset':if(''===a.value)return l(r(a))||'';default:return a.value}}function G(a,b){if(-1===['text','password'].indexOf(b.type.toLowerCase())||!(h.test(a.value)||h.test(a.htmlID)||h.test(a.htmlName)||h.test(a.placeholder)||\
h.test(a['label-tag'])||h.test(a['label-data'])||h.test(a['label-aria'])))return!1;if(!a.visible)return!0;if('password'==b.type.toLowerCase())return!1;a=b.type;t(b,!0);return a!==b.type}function H(a){var b={};a.forEach(function(a){b[a.opid]=a});return b}function g(a,b){var c=a[b];if('string'==typeof c)return c;a=a.getAttribute(b);return'string'==typeof a?a:null}function z(a){return'input'===a.nodeName.toLowerCase()&&-1===a.type.search(/button|submit|reset|hidden|checkbox/i)}var u={},h=/((\\b|_|-)pin(\\b|_|-)|password|passwort|kennwort|(\\b|_|-)passe(\\b|_|-)|contraseña|senha|密码|adgangskode|hasło|wachtwoord)/i;\
this.collect=this.a=function(b,c){u={};var d=b.defaultView?b.defaultView:a,h=b.activeElement,E=Array.prototype.slice.call(k(b,'form')).map(function(a,b){var c={};b='__form__'+b;a.opid=b;c.opid=b;e(c,'htmlName',g(a,'name'));e(c,'htmlID',g(a,'id'));b=g(a,'action');b=new URL(b,window.location.href);e(c,'htmlAction',b?b.href:null);e(c,'htmlMethod',g(a,'method'));return c}),D=Array.prototype.slice.call(v(b)).map(function(a,b){z(a)&&a.hasAttribute('value')&&!a.dataset['com.agilebits.onepassword.initialValue']&&\
(a.dataset['com.agilebits.onepassword.initialValue']=a.value);var c={},d='__'+b,q=-1==a.maxLength?999:a.maxLength;if(!q||'number'===typeof q&&isNaN(q))q=999;u[d]=a;a.opid=d;c.opid=d;c.elementNumber=b;e(c,'maxLength',Math.min(q,999),999);c.visible=w(a);c.viewable=x(a);e(c,'htmlID',g(a,'id'));e(c,'htmlName',g(a,'name'));e(c,'htmlClass',g(a,'class'));e(c,'tabindex',g(a,'tabindex'));e(c,'title',g(a,'title'));e(c,'userEdited',!!a.dataset['com.agilebits.onepassword.userEdited']);if('hidden'!=f(a.type)){e(c,\
'label-tag',m(a));e(c,'label-data',g(a,'data-label'));e(c,'label-aria',g(a,'aria-label'));e(c,'label-top',n(a));b=[];for(d=a;d&&d.nextSibling;){d=d.nextSibling;if(y(d))break;A(b,d)}e(c,'label-right',b.join(''));b=[];B(a,b);b=b.reverse().join('');e(c,'label-left',b);e(c,'placeholder',g(a,'placeholder'))}e(c,'rel',g(a,'rel'));e(c,'type',f(g(a,'type')));e(c,'value',F(a));e(c,'checked',a.checked,!1);e(c,'autoCompleteType',a.getAttribute('x-autocompletetype')||a.getAttribute('autocompletetype')||a.getAttribute('autocomplete'),\
'off');e(c,'disabled',a.disabled);e(c,'readonly',a.c||a.readOnly);e(c,'selectInfo',p(a));e(c,'aria-hidden','true'==a.getAttribute('aria-hidden'),!1);e(c,'aria-disabled','true'==a.getAttribute('aria-disabled'),!1);e(c,'aria-haspopup','true'==a.getAttribute('aria-haspopup'),!1);e(c,'data-unmasked',a.dataset.unmasked);e(c,'data-stripe',g(a,'data-stripe'));e(c,'data-braintree-name',g(a,'data-braintree-name'));e(c,'onepasswordFieldType',a.dataset.onepasswordFieldType||a.type);e(c,'onepasswordDesignation',\
a.dataset.onepasswordDesignation);e(c,'onepasswordSignInUrl',a.dataset.onepasswordSignInUrl);e(c,'onepasswordSectionTitle',a.dataset.onepasswordSectionTitle);e(c,'onepasswordSectionFieldKind',a.dataset.onepasswordSectionFieldKind);e(c,'onepasswordSectionFieldTitle',a.dataset.onepasswordSectionFieldTitle);e(c,'onepasswordSectionFieldValue',a.dataset.onepasswordSectionFieldValue);a.form&&(c.form=g(a.form,'opid'));e(c,'fakeTested',G(c,a),!1);return c});D.filter(function(a){return a.fakeTested}).forEach(function(a){var b=\
u[a.opid];b.getBoundingClientRect();var c=b.value;t(b,!1);b.dispatchEvent(C(b,'keydown'));b.dispatchEvent(C(b,'keypress'));b.dispatchEvent(C(b,'keyup'));if(''===b.value||b.dataset['com.agilebits.onepassword.initialValue']&&b.value===b.dataset['com.agilebits.onepassword.initialValue'])b.value=c;b.click&&b.click();a.postFakeTestVisible=w(b);a.postFakeTestViewable=x(b);a.postFakeTestType=b.type;a=b.value;var c=b.ownerDocument.createEvent('HTMLEvents'),d=b.ownerDocument.createEvent('HTMLEvents');b.dispatchEvent(C(b,\
'keydown'));b.dispatchEvent(C(b,'keypress'));b.dispatchEvent(C(b,'keyup'));d.initEvent('input',!0,!0);b.dispatchEvent(d);c.initEvent('change',!0,!0);b.dispatchEvent(c);b.blur();if(''===b.value||b.dataset['com.agilebits.onepassword.initialValue']&&b.value===b.dataset['com.agilebits.onepassword.initialValue'])b.value=a});c={documentUUID:c,title:b.title,url:d.location.href,documentURL:b.location.href,forms:H(E),fields:D,collectedTimestamp:(new Date).getTime()};(b=b.querySelector('[data-onepassword-title]'))&&\
b.dataset.onepasswordTitle&&(c.displayTitle=b.dataset.onepasswordTitle);h&&z(h)&&t(h,!0);return c};this.elementForOPID=this.b=function(a){return u[a]}}})(document,window,void 0);document.elementForOPID=I;function C(b,a){var c;c=b.ownerDocument.createEvent('Events');c.initEvent(a,!0,!1);c.charCode=0;c.keyCode=0;c.which=0;c.srcElement=b;c.target=b;return c}window.LOGIN_TITLES=[/^\\W*log\\W*[oi]n\\W*$/i,/log\\W*[oi]n (?:securely|now)/i,/^\\W*sign\\W*[oi]n\\W*$/i,'continue','submit','weiter','accès','вход','connexion','entrar','anmelden','accedi','valider','登录','लॉग इन करें'];window.CHANGE_PASSWORD_TITLES=[/^(change|update) password$/i,'save changes','update'];\
window.LOGIN_RED_HERRING_TITLES=['already have an account','sign in with'];window.REGISTER_TITLES=['register','sign up','signup','join',/^create (my )?(account|profile)$/i,'регистрация','inscription','regístrate','cadastre-se','registrieren','registrazione','注册','साइन अप करें'];window.SEARCH_TITLES='search find поиск найти искать recherche suchen buscar suche ricerca procurar 検索'.split(' ');window.FORGOT_PASSWORD_TITLES='forgot geändert vergessen hilfe changeemail español'.split(' ');\
window.REMEMBER_ME_TITLES=['remember me','rememberme','keep me signed in'];window.BACK_TITLES=['back','назад'];window.DIVITIS_BUTTON_CLASSES=['button','btn-primary'];function r(b){return b.textContent||b.innerText}function l(b){var a=null;b&&(a=b.replace(/^\\s+|\\s+$|\\r?\\n.*$/mg,'').replace(/\\s{2,}/,' '),a=0<a.length?a:null);return a}function A(b,a){var c='';3===a.nodeType?c=a.nodeValue:1===a.nodeType&&(c=r(a));(a=l(c))&&b.push(a)}\
function y(b){var a;b&&void 0!==b?(a='select option input form textarea button table iframe body head script'.split(' '),b?(b=b?(b.tagName||'').toLowerCase():'',a=a.constructor==Array?0<=a.indexOf(b):b===a):a=!1):a=!0;return a}\
function B(b,a,c){var f;for(c||(c=0);b&&b.previousSibling;){b=b.previousSibling;if(y(b))return;A(a,b)}if(b&&0===a.length){for(f=null;!f;){b=b.parentElement||b.parentNode;if(!b)return;for(f=b.previousSibling;f&&!y(f)&&f.lastChild;)f=f.lastChild}y(f)||(A(a,f),0===a.length&&B(f,a,c+1))}}\
function w(b){for(var a=b,c=(b=b.ownerDocument)?b.defaultView:{},f;a&&a!==b;){f=c.getComputedStyle&&a instanceof Element?c.getComputedStyle(a,null):a.style;if(!f)return!0;if('none'===f.display||'hidden'==f.visibility)return!1;a=a.parentNode}return a===b}\
function x(b){var a=b.ownerDocument.documentElement,c=b.getBoundingClientRect(),f=a.scrollWidth,e=a.scrollHeight,k=c.left-a.clientLeft,a=c.top-a.clientTop,m;if(!w(b)||!b.offsetParent||10>b.clientWidth||10>b.clientHeight)return!1;var n=b.getClientRects();if(0===n.length)return!1;for(var p=0;p<n.length;p++)if(m=n[p],m.left>f||0>m.right)return!1;if(0>k||k>f||0>a||a>e)return!1;for(c=b.ownerDocument.elementFromPoint(k+(c.right>window.innerWidth?(window.innerWidth-k)/2:c.width/2),a+(c.bottom>window.innerHeight?\
(window.innerHeight-a)/2:c.height/2));c&&c!==b&&c!==document;){if(c.tagName&&'string'===typeof c.tagName&&'label'===c.tagName.toLowerCase()&&b.labels&&0<b.labels.length)return 0<=Array.prototype.slice.call(b.labels).indexOf(c);c=c.parentNode}return c===b}\
function I(b){var a;if(void 0===b||null===b)return null;if(a=FieldCollector.b(b))return a;try{var c=Array.prototype.slice.call(v(document)),f=c.filter(function(a){return a.opid==b});if(0<f.length)a=f[0],1<f.length&&console.warn('More than one element found with opid '+b);else{var e=parseInt(b.split('__')[1],10);isNaN(e)||(a=c[e])}}catch(k){console.error('An unexpected error occurred: '+k)}finally{return a}};function v(b){var a=[];try{a=b.querySelectorAll('input, select, button')}catch(c){console.error('[COMMON] @ag_querySelectorAll Exception in selector \"input, select, button\"')}return a}function t(b,a){if(b){var c;a&&(c=b.value);'function'===typeof b.click&&b.click();'function'===typeof b.focus&&b.focus();a&&b.value!==c&&(b.value=c)}};\
	\
	return JSON.stringify(FieldCollector.a(document, 'oneshotUUID'));\
})(document);\
\
";

static NSString *const OPWebViewFillScript = @";(function(document, fillScript, undefined) {\
\
	var g=!0,h=!0,k=!0;function m(a){return a?0===a.indexOf('https://')&&'http:'===document.location.protocol&&(a=document.querySelectorAll('input[type=password]'),0<a.length&&(confirmResult=confirm('1Password warning: This is an unsecured HTTP page, and any information you submit can potentially be seen and changed by others. This Login was originally saved on a secure (HTTPS) page.\\n\\nDo you still wish to fill this login?'),0==confirmResult))?!0:!1:!1}\
function l(a){var b,c=[],d=a.properties,e=1,f=[];d&&d.delay_between_operations&&(e=d.delay_between_operations);if(!m(a.savedURL)){var r=function(a,b){var c=a[0];if(void 0===c)b();else{if('delay'===c.operation||'delay'===c[0])e=c.parameters?c.parameters[0]:c[1];else if(c=n(c))for(var d=0;d<c.length;d++)-1===f.indexOf(c[d])&&f.push(c[d]);setTimeout(function(){r(a.slice(1),b)},e)}};g=k=!0;if(b=a.options)b.hasOwnProperty('animate')&&(h=b.animate),b.hasOwnProperty('markFilling')&&(g=b.markFilling);if((b=\
a.metadata)&&b.hasOwnProperty('action'))switch(b.action){case 'fillPassword':g=!1;break;case 'fillLogin':k=!1}a.hasOwnProperty('script')&&r(a.script,function(){a.hasOwnProperty('autosubmit')&&'function'==typeof autosubmit&&(a.itemType&&'fillLogin'!==a.itemType||(0<f.length?setTimeout(function(){autosubmit(a.autosubmit,d.allow_clicky_autosubmit,f)},AUTOSUBMIT_DELAY):DEBUG_AUTOSUBMIT&&console.log('[AUTOSUBMIT] Not attempting to submit since no fields were filled: ',f)));c=f.map(function(a){return a&&\
a.hasOwnProperty('opid')?a.opid:null});'object'==typeof protectedGlobalPage&&protectedGlobalPage.c('fillItemResults',{documentUUID:documentUUID,fillContextIdentifier:a.fillContextIdentifier,usedOpids:c},function(){fillingItemType=null})})}}var y={fill_by_opid:p,fill_by_query:q,click_on_opid:t,click_on_query:u,touch_all_fields:v,simple_set_value_by_query:w,focus_by_opid:x,delay:null};\
function n(a){var b;if(a.hasOwnProperty('operation')&&a.hasOwnProperty('parameters'))b=a.operation,a=a.parameters;else if('[object Array]'===Object.prototype.toString.call(a))b=a[0],a=a.splice(1);else return null;return y.hasOwnProperty(b)?y[b].apply(this,a):null}function p(a,b){return(a=z(a))?(A(a,b),[a]):null}function q(a,b){a=B(a);return Array.prototype.map.call(Array.prototype.slice.call(a),function(a){A(a,b);return a},this)}\
function w(a,b){var c=[];a=B(a);Array.prototype.forEach.call(Array.prototype.slice.call(a),function(a){a.disabled||a.a||a.readOnly||void 0===a.value||(a.value=b,c.push(a))});return c}function x(a){(a=z(a))&&C(a,!0);return null}function t(a){return(a=z(a))?C(a,!1)?[a]:null:null}function u(a){a=B(a);return Array.prototype.map.call(Array.prototype.slice.call(a),function(a){C(a,!0);return[a]},this)}function v(){D()};var E={'true':!0,y:!0,1:!0,yes:!0,'✓':!0},F=200;function A(a,b){var c;if(!(!a||null===b||void 0===b||k&&(a.disabled||a.a||a.readOnly)))switch(g&&!a.opfilled&&(a.opfilled=!0,a.form&&(a.form.opfilled=!0)),a.type?a.type.toLowerCase():null){case 'checkbox':c=b&&1<=b.length&&E.hasOwnProperty(b.toLowerCase())&&!0===E[b.toLowerCase()];a.checked===c||G(a,function(a){a.checked=c});break;case 'radio':!0===E[b.toLowerCase()]&&a.click();break;default:a.value==b||G(a,function(a){a.value=b})}}\
function G(a,b){H(a);b(a);I(a);J(a)&&(a.className+=' com-agilebits-onepassword-extension-animated-fill',setTimeout(function(){a&&a.className&&(a.className=a.className.replace(/(\\s)?com-agilebits-onepassword-extension-animated-fill/,''))},F))};document.elementForOPID=z;function K(a,b){var c;c=a.ownerDocument.createEvent('Events');c.initEvent(b,!0,!1);c.charCode=0;c.keyCode=0;c.which=0;c.srcElement=a;c.target=a;return c}function H(a){var b=a.value;C(a,!1);a.dispatchEvent(K(a,'keydown'));a.dispatchEvent(K(a,'keypress'));a.dispatchEvent(K(a,'keyup'));if(''===a.value||a.dataset['com.agilebits.onepassword.initialValue']&&a.value===a.dataset['com.agilebits.onepassword.initialValue'])a.value=b}\
function I(a){var b=a.value,c=a.ownerDocument.createEvent('HTMLEvents'),d=a.ownerDocument.createEvent('HTMLEvents');a.dispatchEvent(K(a,'keydown'));a.dispatchEvent(K(a,'keypress'));a.dispatchEvent(K(a,'keyup'));d.initEvent('input',!0,!0);a.dispatchEvent(d);c.initEvent('change',!0,!0);a.dispatchEvent(c);a.blur();if(''===a.value||a.dataset['com.agilebits.onepassword.initialValue']&&a.value===a.dataset['com.agilebits.onepassword.initialValue'])a.value=b}\
function L(){var a=/((\\b|_|-)pin(\\b|_|-)|password|passwort|kennwort|passe|contraseña|senha|密码|adgangskode|hasło|wachtwoord)/i;return Array.prototype.slice.call(B(\"input[type='text']\")).filter(function(b){return b.value&&a.test(b.value)},this)}function D(){L().forEach(function(a){H(a);a.click&&a.click();I(a)})}\
window.LOGIN_TITLES=[/^\\W*log\\W*[oi]n\\W*$/i,/log\\W*[oi]n (?:securely|now)/i,/^\\W*sign\\W*[oi]n\\W*$/i,'continue','submit','weiter','accès','вход','connexion','entrar','anmelden','accedi','valider','登录','लॉग इन करें'];window.CHANGE_PASSWORD_TITLES=[/^(change|update) password$/i,'save changes','update'];window.LOGIN_RED_HERRING_TITLES=['already have an account','sign in with'];\
window.REGISTER_TITLES=['register','sign up','signup','join',/^create (my )?(account|profile)$/i,'регистрация','inscription','regístrate','cadastre-se','registrieren','registrazione','注册','साइन अप करें'];window.SEARCH_TITLES='search find поиск найти искать recherche suchen buscar suche ricerca procurar 検索'.split(' ');window.FORGOT_PASSWORD_TITLES='forgot geändert vergessen hilfe changeemail español'.split(' ');window.REMEMBER_ME_TITLES=['remember me','rememberme','keep me signed in'];\
window.BACK_TITLES=['back','назад'];window.DIVITIS_BUTTON_CLASSES=['button','btn-primary'];function J(a){var b;if(b=h)a:{b=a;for(var c=a.ownerDocument,d=c?c.defaultView:{},e;b&&b!==c;){e=d.getComputedStyle&&b instanceof Element?d.getComputedStyle(b,null):b.style;if(!e){b=!0;break a}if('none'===e.display||'hidden'==e.visibility){b=!1;break a}b=b.parentNode}b=b===c}return b?-1!=='email text password number tel url'.split(' ').indexOf(a.type||''):!1}\
function z(a){var b;if(void 0===a||null===a)return null;if(b=FieldCollector.b(a))return b;try{var c=Array.prototype.slice.call(B('input, select, button')),d=c.filter(function(b){return b.opid==a});if(0<d.length)b=d[0],1<d.length&&console.warn('More than one element found with opid '+a);else{var e=parseInt(a.split('__')[1],10);isNaN(e)||(b=c[e])}}catch(f){console.error('An unexpected error occurred: '+f)}finally{return b}};function B(a){var b=document,c=[];try{c=b.querySelectorAll(a)}catch(d){console.error('[COMMON] @ag_querySelectorAll Exception in selector \"'+a+'\"')}return c}function C(a,b){if(!a)return!1;var c;b&&(c=a.value);'function'===typeof a.click&&a.click();'function'===typeof a.focus&&a.focus();b&&a.value!==c&&(a.value=c);return'function'===typeof a.click||'function'===typeof a.focus};\
\
	l(fillScript);\
	return JSON.stringify({'success': true});\
})\
\
";


#pragma mark - Deprecated methods

/*
 Deprecated in version 1.5
 Use fillItemIntoWebView:forViewController:sender:showOnlyLogins:completion: instead
 */
- (void)fillLoginIntoWebView:(nonnull id)webView forViewController:(nonnull UIViewController *)viewController sender:(nullable id)sender completion:(nonnull OnePasswordSuccessCompletionBlock)completion {
	[self fillItemIntoWebView:webView forViewController:viewController sender:sender showOnlyLogins:YES completion:completion];
}

@end
