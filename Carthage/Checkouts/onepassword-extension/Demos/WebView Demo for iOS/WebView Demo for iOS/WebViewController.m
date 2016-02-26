//
//  WebViewController.m
//  1Password Extension Demo
//
//  Created by Dave Teare on 2014-07-19.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "WebViewController.h"

#import "OnePasswordExtension.h"

@interface WebViewController() <UISearchBarDelegate, WKNavigationDelegate>

@property (weak, nonatomic) IBOutlet UIButton *onepasswordFillButton;
@property (weak, nonatomic) IBOutlet UIView *webViewContainer;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) WKWebView *webView;

@end

@implementation WebViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
	[super viewDidLoad];

	[self.onepasswordFillButton setHidden:![[OnePasswordExtension sharedExtension] isAppExtensionAvailable]];

	WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
	self.webView = [[WKWebView alloc] initWithFrame:self.webViewContainer.bounds configuration:configuration];
	self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	self.webView.navigationDelegate = self;
	[self.webViewContainer addSubview:self.webView];

	NSString *htmlFilePath = [[NSBundle mainBundle] pathForResource:@"welcome" ofType:@"html"];
	NSError *htmlStringError = nil;
	NSString* htmlString = [NSString stringWithContentsOfFile:htmlFilePath encoding:NSUTF8StringEncoding error:&htmlStringError];

	if (htmlString.length == 0) {
		NSLog(@"Failed to obtain the html string from file %@ with error: <%@>", htmlFilePath, htmlStringError);
	}

	[self.webView loadHTMLString:htmlString baseURL:nil];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	if (NO == [[OnePasswordExtension sharedExtension] isAppExtensionAvailable]) {
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
		}];
		
		UIAlertAction *get1PasswordAction = [UIAlertAction actionWithTitle:@"Get 1Password" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/ca/app/1password-password-manager/id568903335?mt=8"]];
		}];
		
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"1Password is not installed" message:@"Get 1Password from the App Store" preferredStyle:UIAlertControllerStyleAlert];
		
		[alertController addAction:cancelAction];
		[alertController addAction:get1PasswordAction];
		
		[self presentViewController:alertController animated:YES completion:nil];
	}
}

#pragma mark - Actions

- (IBAction)fillUsing1Password:(id)sender {
	[[OnePasswordExtension sharedExtension] fillItemIntoWebView:self.webView forViewController:self sender:sender showOnlyLogins:NO completion:^(BOOL success, NSError *error) {
		if (!success) {
			NSLog(@"Failed to fill into webview: <%@>", error);
		}
	}];
}

- (IBAction)goBack:(id)sender {
	WKNavigation *navigation = [self.webView goBack];

	if (navigation != nil) {
		NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"welcome" ofType:@"html"];
		NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
		[self.webView loadHTMLString:htmlString baseURL:nil];

	}
}

- (IBAction)goForward:(id)sender {
	[self.webView goForward];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	[self performSearch:searchBar.text];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
	[self performSearch:searchBar.text];
}

- (void)handleSearch:(UISearchBar *)searchBar {
	[self performSearch:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar {
	[self performSearch:searchBar.text];
}

#pragma mark - Convenience Methods

- (void)performSearch:(NSString *)text {
	NSString *lowercaseText = [text lowercaseStringWithLocale:[NSLocale currentLocale]];
	NSURL *URL = nil;

	BOOL hasSpaces = [lowercaseText rangeOfString:@" "].location != NSNotFound;
	BOOL hasDots = [lowercaseText rangeOfString:@"."].location != NSNotFound;
	BOOL search = !hasSpaces || !hasDots;
	if (search) {
		BOOL hasScheme = [lowercaseText hasPrefix:@"http:"] || [lowercaseText hasPrefix:@"https:"];
		if (hasScheme) {
			URL = [NSURL URLWithString:lowercaseText];
		}
		else {
			URL = [NSURL URLWithString:[@"https://" stringByAppendingString:lowercaseText]];
		}
	}

	if (URL == nil) {
		NSURLComponents *URLComponents = [[NSURLComponents alloc] init];
		URLComponents.scheme = @"https";
		URLComponents.host = @"www.google.com";
		URLComponents.path = @"/search";
		
		NSURLQueryItem *queryItem = [NSURLQueryItem queryItemWithName:@"q" value:text];
		URLComponents.queryItems = @[queryItem];
		
		URL = URLComponents.URL;
	}

	self.searchBar.text = [URL absoluteString];
	[self.searchBar resignFirstResponder];

	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
	[self.webView loadRequest:request];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
	self.searchBar.text = webView.URL.absoluteString;

	if ([self.searchBar.text isEqualToString:@"about:blank"]) {
		self.searchBar.text = @"";
	}
}

@end
