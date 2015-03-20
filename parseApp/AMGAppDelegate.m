//
//  AMGAppDelegate.m
//  parseApp
//
//  Created by Alan Morales on 9/2/14.
//  Copyright (c) 2014 Facebook Inc. All rights reserved.
//

#import "AMGAppDelegate.h"
#import <Parse/Parse.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import "AMGTableViewController.h"
#import <FacebookSDK/FacebookSDK.h>

@implementation AMGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //[FBSettings setFacebookDomainPart:@"{FACEBOOK-DOMAIN}"];
    
    [Parse enableLocalDatastore];
    [Parse setApplicationId:@"YOUR_APP_ID"
                  clientKey:@"YOUR_CLIENT_KEY"];
    [PFFacebookUtils initializeFacebook];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Override point for customization after application launch.
    AMGTableViewController *tableViewController = [[AMGTableViewController alloc] init];
    
    UINavigationController *mainViewController = [[UINavigationController alloc] initWithRootViewController:tableViewController];
    [[mainViewController navigationBar] setBackgroundColor:[UIColor blueColor]];
    
    self.window.rootViewController = mainViewController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                        withSession:[PFFacebookUtils session]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[PFFacebookUtils session] close];
}
@end
