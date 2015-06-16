//
//  DTSafariViewController.m
//  DTGoogleAuth
//
//  Created by Diego Torres on 6/16/15.
//  Copyright (c) 2015 Diego Torres. All rights reserved.
//

#import "DTSafariViewController.h"
@import WebKit;
#if defined(__IPHONE_9_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
@import SafariServices.SFSafariViewController;
#endif

@interface DTSafariViewController () <UIWebViewDelegate, WKNavigationDelegate>

@property (nonatomic, copy, readonly) NSURL *url;

@end

@implementation DTSafariViewController

#if defined(__IPHONE_9_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
+ (instancetype)alloc
{
    if ([SFSafariViewController class]) {
        return (id)[SFSafariViewController alloc];
    }
    return [super alloc];
}
#endif

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (nonnull instancetype)initWithURL:(nonnull NSURL *)URL
{
    return [self initWithURL:URL entersReaderIfAvailable:NO];
}

- (nonnull instancetype)initWithURL:(nonnull NSURL *)URL entersReaderIfAvailable:(BOOL)entersReaderIfAvailable
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _url = URL;
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(title))]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.title = [object title];
        });
    }
}

- (void)dealloc
{
    if ([self isViewLoaded] && [self.view isKindOfClass:[WKWebView class]]) {
        [self.view removeObserver:self forKeyPath:NSStringFromSelector(@selector(title))];
    }
}

- (void)loadView
{
    if ([WKWebView class]) {
        WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero];
        [webView addObserver:self forKeyPath:NSStringFromSelector(@selector(title)) options:0 context:NULL];
        webView.navigationDelegate = self;
        self.view = webView;
    } else {
        UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        webView.delegate = self;
        self.view = webView;
    }
    [((UIWebView *)self.view) loadRequest:[NSURLRequest requestWithURL:self.url]];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(safariViewControllerDidFinish:)];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

static BOOL DTShouldLoadRequest(NSURLRequest *request) {
    BOOL shouldLoad = NO;
    NSString *scheme = request.URL.scheme;
    if (![request.HTTPMethod isEqualToString:@"GET"]) {
        shouldLoad = YES;
    } else if ([scheme rangeOfString:@"http" options:NSCaseInsensitiveSearch].location != NSNotFound ||
               [scheme rangeOfString:@"about" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        shouldLoad = YES;
    }
    if (!shouldLoad) {
        [[UIApplication sharedApplication] openURL:request.URL];
    }
    return shouldLoad;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return DTShouldLoadRequest(request);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    WKNavigationActionPolicy policy = DTShouldLoadRequest(navigationAction.request) ? WKNavigationActionPolicyAllow : WKNavigationActionPolicyCancel;
    decisionHandler(policy);
}


- (void)safariViewControllerDidFinish:(id)sender
{
    [self.delegate safariViewControllerDidFinish:self];
}

@end
