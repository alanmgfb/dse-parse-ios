//
//  AMGAppDelegate.h
//  parseApp
//
//  Created by Alan Morales on 9/2/14.
//  Copyright (c) 2014 Facebook Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FBSDKMessengerShareKit/FBSDKMessengerShareKit.h>

@interface AMGAppDelegate : UIResponder <UIApplicationDelegate, FBSDKMessengerURLHandlerDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
