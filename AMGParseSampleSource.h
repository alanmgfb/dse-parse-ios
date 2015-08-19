//
//  AMGParseSampleSource.h
//  parseApp
//
//  Created by Alan Morales on 1/12/15.
//  Copyright (c) 2015 Facebook Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FBSDKShareKit/FBSDKShareKit.h>

@interface AMGParseSampleSource : NSObject <FBSDKSharingDelegate, FBSDKGameRequestDialogDelegate, FBSDKAppInviteDialogDelegate>

@property NSMutableArray *repro_steps;
extern NSString *const EMAIL;
extern NSString *const USERNAME;
extern NSString *const PASSWORD;

typedef enum {
    SIGN_UP,
    LOGIN,
    ANON_LOGIN,
    IS_ANON_USER,
    VC_LOGIN,
    FB_LOGIN,
    TWITTER_LOGIN,
    RESET_PASSWORD,
    FB_UNLINK,
    LOG_OUT,
    FB_ONLY_LOGIN,
    FB_CURRENT_PERMISSIONS,
    FB_REQUEST_EXTRA_PERMISSIONS,
    FB_REFRESH_ACCESS_TOKEN,
    FB_PUBLISH_RANDOM_POST,
    FB_MOVIE,
    FB_OG_IMAGE_FULL,
    FB_OG_MOVIE,
    FB_UPLOAD_PHOTO,
    FB_GAME_REQUEST,
    FB_MESSENGER_SEND_PIC,
    FB_INVITE,
    FB_SHARE_LINK,
    FB_SHARE_SHEET,
    SAVE_INSTALLATION,
    ANALYTICS_TEST,
    ACL_NEW_FIELD,
    ACL_EXISTING_FIELD,
    ACL_TEST_QUERY,
    SAVE_USER_PROPERTY,
    REFRESH_USER,
    MUTEX_LOCK,
    QUERY_FIRST_OBJECT,
    QUERY_FIRST_OBJECT_USING_CLASS,
    QUERY_COMPOUND,
    QUERY_DESCRIPTOR,
    QUERY_CACHE,
    LDS_PINNING,
    LDS_PIN_WITH_NAME,
    LDS_QUERY_PIN_WITH_NAME,
    LDS_QUERY_ALL,
    LDS_QUERY_LOCAL,
    LDS_SAVE_LOCAL,
    LDS_DELETE_BACKGROUND,
    LDS_PIN_NULL,
    LDS_CREATE_PIN_LOCALLY,
    LDS_QUERY_PIN_OFFLINE,
    LDS_QUERY_PIN_ONLINE,
    LDS_NESTED_PIN,
    LDS_NESTED_FETCH,
    LDS_USER_RELATION_CREATE,
    LDS_USER_RELATION_ONLINE_FETCH,
    LDS_USER_RELATION_LOCAL_FETCH,
    CLOUD_CODE_POINTER_TEST,
    CLOUD_CODE_EMPTY_POINTER_TEST,
    BC_AD_DATES_SAVING,
    BC_AD_DATES_RETRIEVING
} ParseSampleEnum;

+ (instancetype)sharedSource;
- (NSNumber *)currentStep;
- (bool)isTutorialDone;
- (NSArray *)sections;
- (void)executeSample:(NSInteger)sampleIndex;
- (void)sampleFinished:(NSInteger)sampleIndex;
@end
