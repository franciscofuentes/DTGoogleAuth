//
//  DTSafariViewController.h
//  DTGoogleAuth
//
//  Created by Diego Torres on 6/16/15.
//  Copyright (c) 2015 Diego Torres. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol DTSafariViewControllerDelegate;

/*!
 @class SFSafariViewController
 A view controller for displaying web content in a Safari-like interface with some of Safari’s features. The
 web content in SFSafariViewController shares cookie and website data with web content opened in Safari.
 */
NS_CLASS_AVAILABLE_IOS(9_0)
@interface DTSafariViewController : UIViewController

/*! @abstract The view controller's delegate */
@property (nonatomic, weak, nullable) id<DTSafariViewControllerDelegate> delegate;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

/*! @abstract Returns a view controller that loads a URL.
 @param URL, the URL to navigate to.
 @param entersReaderIfAvailable indicates if the Safari Reader version of content should be shown automatically
 when Safari Reader is available on a web page
 */
- (instancetype)initWithURL:(NSURL *)URL entersReaderIfAvailable:(BOOL)entersReaderIfAvailable NS_DESIGNATED_INITIALIZER;

/*! @abstract Returns a view controller that loads a URL.
 @param URL, the URL to navigate to.
 */
- (instancetype)initWithURL:(NSURL *)URL;

@end

@protocol DTSafariViewControllerDelegate <NSObject>
@optional

/*! @abstract Called when the view controller is about to show UIActivityViewController after the user taps the action button.
 @param URL, the URL of the web page.
 @param title, the title of the web page.
 @result Returns an array of UIActivity instances that will be appended to UIActivityViewController.
 @note This method is never called in the shim.
 */
- (NSArray *)safariViewController:(DTSafariViewController *)controller activityItemsForURL:(NSURL *)URL title:(nullable NSString *)title;

/*! @abstract Delegate callback called when the user taps the Done button. Upon this call, the client should dismiss the view controller modally. */
- (void)safariViewControllerDidFinish:(DTSafariViewController *)controller;

@end

NS_ASSUME_NONNULL_END