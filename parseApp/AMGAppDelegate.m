//
//  AMGAppDelegate.m
//  parseApp
//
//  Created by Alan Morales on 9/2/14.
//  Copyright (c) 2014 Facebook Inc. All rights reserved.
//

#import "AMGAppDelegate.h"
#import <Parse/Parse.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <ParseTwitterUtils/ParseTwitterUtils.h>
#import "AMGTableViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <Bolts/Bolts.h>

@implementation AMGAppDelegate
FBSDKMessengerURLHandler *_messengerUrlHandler = nil;
FBSDKMessengerURLHandlerOpenFromComposerContext *_composerContext = nil;
FBSDKMessengerURLHandlerReplyContext *_replyContext = nil;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // [PFUser enableAutomaticUser];
    [Parse enableLocalDatastore];
    [Parse setApplicationId:@"YOUR_APP_ID"
                  clientKey:@"YOUR_CLIENT_KEY"];
    [PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:launchOptions];
    /*
    [PFTwitterUtils initializeWithConsumerKey:@"consumer_key"
                               consumerSecret:@"consumer_secret"];
    */
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    // Remote notifications. Won't work on this app but still :P
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes  categories:nil];
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
    
    // Saving PFInstallation because why not.
    [[PFInstallation currentInstallation] saveInBackground];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Override point for customization after application launch.
    AMGTableViewController *tableViewController = [[AMGTableViewController alloc] init];
    
    UINavigationController *mainViewController = [[UINavigationController alloc] initWithRootViewController:tableViewController];
    [[mainViewController navigationBar] setBackgroundColor:[UIColor blueColor]];
    
    _messengerUrlHandler = [[FBSDKMessengerURLHandler alloc] init];
    _messengerUrlHandler.delegate = self;
    
    self.window.rootViewController = mainViewController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    // App Links Debugging
    NSLog(@"Inbound URL %@", url);
    BFURL *parsedUrl = [BFURL URLWithInboundURL:url sourceApplication:sourceApplication];
    //NSLog([[parsedUrl targetURL] host]);
    NSDictionary *queryParams = [parsedUrl inputQueryParameters];
    // App Link data available, handle it here
    if ([parsedUrl appLinkData]) {
        NSLog(@"Parsed URL: %@", [parsedUrl targetURL]);
    }
    
    // Check if the handler knows what to do with this url
    if ([_messengerUrlHandler canOpenURL:url sourceApplication:sourceApplication]) {
        // Handle the url
        [_messengerUrlHandler openURL:url sourceApplication:sourceApplication];
    }
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBSDKAppEvents activateApp];
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"We registered for remote notifications with device token!");
    // Store the deviceToken in the current Installation and save it to Parse
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
        NSLog(@"Installation saved successfully!");
    }];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Failed to register for remote notifications because %@", [error description]);
}

/**
 *
 *  Messenger
 *
 */
/*
 * When people enter your app through the composer in Messenger,
 * this delegate function will be called.
 */
- (void)messengerURLHandler:(FBSDKMessengerURLHandler *)messengerURLHandler
didHandleOpenFromComposerWithContext:(FBSDKMessengerURLHandlerOpenFromComposerContext *)context;
{
    NSLog(@"Composer Handle this!");
    _composerContext = context;
}

/*
 * When people enter your app through the "Reply" button on content
 * this delegate function will be called.
 */
- (void)messengerURLHandler:(FBSDKMessengerURLHandler *)messengerURLHandler
  didHandleReplyWithContext:(FBSDKMessengerURLHandlerReplyContext *)context;
{
    NSLog(@"Reply Handle this!");
    _replyContext = context;
}
@end
