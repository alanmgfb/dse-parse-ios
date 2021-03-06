//
//  AMGParseSampleSource.m
//  parseApp
//
//  Created by Alan Morales on 1/12/15.
//  Copyright (c) 2015 Facebook Inc. All rights reserved.
//

#import "AMGParseSampleSource.h"
#import "ACLTest.h"
#import "AMGParseSection.h"
#import "AMGParseSample.h"
#import <ParseUI/ParseUI.h>
#import <Parse/Parse.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <ParseTwitterUtils/ParseTwitterUtils.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>
#import <FBSDKMessengerShareKit/FBSDKMessengerShareKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@implementation AMGParseSampleSource
static NSMutableArray *mutableSections = nil;
NSString *const EMAIL = @"alaniOS@alaniOS.com";
NSString *const USERNAME = @"alaniOS";
NSString *const PASSWORD = @"alaniOS";
NSArray *FB_READ_PERMS_ARRAY = nil;
NSArray *FB_PUBLISH_PERMS_ARRAY = nil;
FBSDKLoginManager *loginManager = nil;

// Parse Local Datastore
bool pinned_first = NO;

+ (instancetype)sharedSource {
    static AMGParseSampleSource *sharedSource;
    
    if (!sharedSource) {
        sharedSource = [[self alloc] initPrivate];
    }
    
    return sharedSource;
}

- (NSNumber *)currentStep {
    if (![self isTutorialDone]) {
        return [[self repro_steps] objectAtIndex:0];
    }
    
    return nil;
}

- (bool)isTutorialDone {
    return [[self repro_steps] count] == 0;
}

- (instancetype)init {
    [NSException raise:@"Singleton" format:@"Use [AMGParseSampleSource sharedSource]"];
    
    return nil;
}

- (instancetype)initPrivate {
    self = [super init];
    [self setupSections];
    
    FB_READ_PERMS_ARRAY = @[@"user_friends", @"email"];
    FB_PUBLISH_PERMS_ARRAY = @[@"publish_actions"];
    
    NSArray *steps = @[
                       [NSNumber numberWithUnsignedInteger: FB_LOGIN],
                       [NSNumber numberWithUnsignedInteger: FB_REQUEST_EXTRA_PERMISSIONS],
                       [NSNumber numberWithUnsignedInteger: FB_OG_IMAGE_FULL]
                       ];
    NSMutableArray *mSteps = [[NSMutableArray alloc] initWithArray:steps];
    [self setRepro_steps:mSteps];
    
    return self;
}

- (NSArray *)sections {
    if (mutableSections == nil) {
        [self setupSections];
    }
    
    return mutableSections;
}

/*
 *
 *  This is where you set up UI for new sections and samples
 *
 */
- (void)setupSections {
    mutableSections = [[NSMutableArray alloc] init];
    NSArray *sections = @[@"Login", @"Facebook", @"Events / Analytics", @"ACL", @"PFObjects", @"Queries", @"LDS", @"Pointers", @"Random"];
    
    NSDictionary *samples =
    @{
      @"Login" : @[@"Sign Up", @"Log In", @"Anonymous Login", @"Is Anon User?", @"View Controller Login", @"Facebook", @"Twitter", @"Reset Password", @"Facebook Unlink", @"Log out"],
      @"Facebook" : @[@"Login [No Parse]", @"See Current Permissions", @"Request publish_actions", @"Refresh Access Token", @"Logout", @"Publish Random Post", @"Publish Video", @"Publish Image", @"OG Image Share", @"OG Image Share via API", @"OG Movie", @"Upload Photo", @"Send Game Request", @"Messenger Send Pic", @"App Invite Dialog", @"Share Link", @"Share Sheet"],
      @"Events / Analytics" : @[@"Save Installation", @"Save Event"],
      @"ACL" : @[@"Add New Field", @"Update Existing Field", @"ACL Test Query"],
      @"PFObjects" : @[@"Save PFUser Property", @"Refresh User", @"Mutex Lock"],
      @"Queries" : @[@"Get First Object", @"Get First, using class", @"Compound Query Test", @"Using Descriptor", @"CacheThenNetwork"],
      @"LDS" : @[@"Pinning", @"Pin With Name",@"Query Pin With Name", @"Query All Locally (Pin First)", @"Query Locally (Pin First)", @"Save Locally", @"Delete In Background", @"Pinning Null, then Querying", @"Save and Pin LocalPinObjects", @"Count LocalPinObjects, offline", @"Count LocalPinObjects, online", @"LDS Nested Pin", @"LDS Nested Fetch", @"User Relation Create", @"User Relation Online Fetch", @"User Relation Local Fetch"],
      @"Pointers": @[@"Get Pointer Object Test", @"Get Empty Pointer Object Test"],
      @"Random" : @[@"BC / AD Dates Saving", @"BC / AD Dates Retrieving"]
    };
    
    for (NSString *section in sections) {
        AMGParseSection *sectionWrapper = [[AMGParseSection alloc] initWithName:section];
        
        NSArray *currentSamples = [samples objectForKey:section];
        for (NSString *sample in currentSamples) {
            AMGParseSample *sampleWrapper = [[AMGParseSample alloc] initWithName:sample];
            
            [sectionWrapper addSample:sampleWrapper];
        }
        
        [mutableSections addObject:sectionWrapper];
    }
}

/*
 *
 *  This is where you put the code for new samples. Please also update AMGParseSampleSource.h enum
 *
 */
- (void)executeSample:(NSInteger)sampleIndex {
    switch (sampleIndex) {

        case SIGN_UP: {
            NSLog(@"Sign Up!");
            if (![PFUser currentUser]) {
                PFUser *user    = [PFUser user];
                user.username   = USERNAME;
                user.email      = EMAIL;
                user.password   = PASSWORD;
                [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (error == nil) {
                        NSLog(@"Signed up!");
                        [self logUser: user];
                    } else if ([error code] == 202) {
                        [self alertWithMessage:@"Name Already Taken. Maybe Login?" title:@"Sign Up"];
                    } else {
                        NSLog(@"There was an error when Signing Up");
                        NSLog(@"%@", [error description]);
                    }
                }];
                
            } else {
                NSLog(@"User already exists!");
                [self logUser:[PFUser currentUser]];
            }
            break;
        }
            
        case LOGIN: {
            NSLog(@"Login!");
            // No user present, or
            // Anonymous user
            if (![PFUser currentUser] ||
                [PFAnonymousUtils isLinkedWithUser:[PFUser currentUser]]) {
                NSString *userName = USERNAME;
                NSString *password = PASSWORD;
                
                [PFUser logInWithUsernameInBackground:userName password:password block:^(PFUser *user, NSError *error) {
                    if (user) {
                        [self alertWithMessage:@"Logged In!" title:@"Success"];
                        NSLog(@"logged in successfully!");
                    } else {
                        [self alertWithMessage:[error description] title:@"Login Failed!"];
                    }
                }];
            } else {
                [self alertWithMessage:@"Was Already Logged In!" title:@"Success?"];
            }
            break;
        }
            
        case ANON_LOGIN: {
            NSLog(@"Parse Anonymous Login");
            [PFAnonymousUtils logInWithBlock:^(PFUser *user, NSError *error) {
                if (error == nil) {
                    NSLog(@"Anonymous Login Success!");
                    [self logUser:user];
                } else {
                
                }
            }];
            break;
        }
            
        case IS_ANON_USER: {
            [self alertWithMessage:[NSString stringWithFormat:@"%d", [PFAnonymousUtils isLinkedWithUser:[PFUser currentUser]]]
                             title:@"Is Anonymous User?"];
            
            NSLog(@"Printing RandomNumber: %@", [PFUser currentUser][@"RandomNumber"]);
            [PFUser currentUser][@"RandomNumber"] = @10022;
            break;
        }
            
        // Handled by the Table View Controller
        case VC_LOGIN: {break;}
        
        case FB_LOGIN: {
            NSLog(@"Starting Facebook Auth");
            
            // Login PFUser using Facebook
            [PFFacebookUtils logInInBackgroundWithReadPermissions:FB_READ_PERMS_ARRAY block:^(PFUser *user, NSError *error) {
                NSLog(@"Came back from loginWithPermissions! Name is %@", user[@"displayName"]);
                
                if (!user) {
                    NSString *errorMessage = nil;
                    if (!error) {
                        errorMessage = @"Uh oh. The user cancelled the Facebook login.";
                    } else {
                        NSLog(@"Uh oh. An error occurred: %@", error);
                        errorMessage = [error localizedDescription];
                    }
                    [self alertWithMessage:errorMessage title:@"Facebook Login Error"];
                } else {
                    if (user.isNew) {
                        NSLog(@"User with facebook signed up and logged in!");
                    } else {
                        NSLog(@"User with facebook logged in!");
                    }
                    
                    NSLog(@"Access Token es: %@", [[FBSDKAccessToken currentAccessToken] tokenString]);
                    NSLog(@"Facebook User Name es :%@", [[FBSDKProfile currentProfile] name]);
                    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
                    [params setObject:@"id,gender,first_name,last_name,birthday" forKey:@"fields"];
                    [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me/friends" parameters:params] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                        if (!error) {
                        ////// do stuff with the friends. here we get only friends that use the app if permissions are asked via Safari > facebook.com
                        NSArray* friends = [result objectForKey:@"data"];
                        NSLog(@"Found: %lu friends", friends.count);
                        for (NSDictionary *friend in friends) {
                            NSLog(@"%@: %@", friend[@"id"], friend[@"name"]);
                        }
                        } else {
                            NSLog(@"Graph API Error: %@", [error description]);
                        }
                    }];
                }
            }];
            break;
        }

        case TWITTER_LOGIN: {
            if ([PFUser currentUser]) {
                [PFTwitterUtils linkUser:[PFUser currentUser] block:^(BOOL succeeded, NSError *error) {
                     if (!error) {
                         if (succeeded) {
                             [self alertWithMessage:@"Authorization Successful!" title:@"Twitter Login"];
                             [self logTwitterCredentials];
                         }
                         else {
                             [self alertWithMessage:@"Authorization Cancelled!" title:@"Twitter Login"];
                         }
                     }
                     else
                     {
                         [self alertWithMessage:[error localizedDescription] title:@"Twitter Login"];
                     }
                 }];
            }
            else {
                NSLog(@"Creating user with twitter credentials");
                [PFTwitterUtils logInWithBlock:^(PFUser *user, NSError *error) {
                     if (!error) {
                         if (user) {
                             [self alertWithMessage:@"Authorization Successful!" title:@"Twitter Login"];
                             [self logTwitterCredentials];
                         } else {
                             [self alertWithMessage:@"Authorization Cancelled!" title:@"Twitter Login"];
                         }
                     } else {
                         [self alertWithMessage:[error localizedDescription] title:@"Twitter Login"];
                     }
                 }];
            }
            
            break;
        }
            
        case RESET_PASSWORD: {
            if ([PFUser currentUser]) {
                NSLog(@"About to reset your password!");
                [PFUser requestPasswordResetForEmailInBackground:EMAIL block:^(BOOL succeeded, NSError *error) {
                    [self alertWithMessage:@"Password email sent, log out after changing to test" title:@"Password Email"];
                }];
            }
            break;
        }
            
        case FB_UNLINK: {
            if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
                [PFFacebookUtils unlinkUserInBackground:[PFUser currentUser] block:^(BOOL succeeded, NSError *error){
                    NSLog(@"Came back from unlinking!");
                    NSLog(@"succeeded? %i", succeeded);
                    NSLog(@"Error es %@", error);
                }];
            }
            break;
        }
            
        case LOG_OUT: {
            if ([PFUser currentUser]) {
                [PFUser logOut];
                [self alertWithMessage:@"Log out Successful!" title:@"Parse Log Out"];
            } else {
                [self alertWithMessage:@"Please Log in first." title:@"Parse Log Out"];
            }
            break;
        }
            
        case FB_ONLY_LOGIN: {
            FBSDKLoginManager *manager = [self getLoginManager];
            dispatch_async(dispatch_get_main_queue(), ^{
                [manager logInWithReadPermissions:FB_READ_PERMS_ARRAY fromViewController:[self currentViewController] handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                    NSLog(@"%@", [result token].tokenString);
                    NSLog(@"IsCancelled? %d", [result isCancelled]);
                    
                    if (error != nil) {
                        NSLog(@"%@", [error description]);
                    }
                }];
            });
            break;
        }
            
        case FB_CURRENT_PERMISSIONS: {
            [self alertWithMessage:[NSString stringWithFormat:@"%@", [[FBSDKAccessToken currentAccessToken] permissions]] title:@"Current Permissions"];
            break;
        }
            
        case FB_REQUEST_EXTRA_PERMISSIONS: {
            if ([FBSDKAccessToken currentAccessToken] != nil) {
                NSLog(@"Session Permissions %@", [[FBSDKAccessToken currentAccessToken] permissions]);
                FBSDKLoginManager *manager = [self getLoginManager];
                [manager logInWithPublishPermissions:FB_PUBLISH_PERMS_ARRAY fromViewController:[self currentViewController] handler:^(FBSDKLoginManagerLoginResult *result, NSError *error){
                    if (!error) {
                        [self alertWithMessage:@"Requested extra permission successfully!" title:@"Request extra permissions"];
                    }
                }];
            } else {
                [self alertWithMessage:@"Login through Facebook First" title:@"FB Request Extra Perms"];
            }
            break;
        }
            
        case FB_REFRESH_ACCESS_TOKEN: {
            [FBSDKAccessToken refreshCurrentAccessToken:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                NSLog(@"Result: %@", result);
            }];
            break;
        }
            
        case FB_LOGOUT: {
            FBSDKLoginManager *manager = [self getLoginManager];
            [manager logOut];
            [self alertWithMessage:@"Logged out of the app" title:@"FB Logout"];
            break;
        }
        
        case FB_PUBLISH_RANDOM_POST: {
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSString stringWithFormat:@"Random Post %@", [NSDate date]], @"message", nil];
            
            [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me/feed" parameters:params HTTPMethod:@"POST"] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                if (error) {
                    NSLog(@"newpost: publish error is: %@", error);
                }
                else {
                    [self alertWithMessage:@"Publish success!" title:@"Publish Random Post"];
                }
            }];
            break;
        }
        
        case FB_MOVIE: {
            NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"IMG_0838" ofType:@"MOV"];
            NSURL *videoUrl = [NSURL fileURLWithPath:videoPath];
            
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            ALAssetsLibraryWriteVideoCompletionBlock videoWriteCompletionBlock = ^(NSURL *newURL, NSError *error) {
                if (error) {
                    [self alertWithMessage:@"Error copying video to Assets Library" title:@"Damn"];
                } else {
                    FBSDKShareVideo *video = [[FBSDKShareVideo alloc] init];
                    video.videoURL = newURL;
                    FBSDKShareVideoContent *content = [[FBSDKShareVideoContent alloc] init];
                    content.video = video;
                    
                    [FBSDKShareDialog showFromViewController: [self currentViewController]
                                                 withContent:content delegate:self];
                }
            };
            
            if (![library videoAtPathIsCompatibleWithSavedPhotosAlbum:videoUrl]) {
                [self alertWithMessage:@"Video not compatible with Saved Photos Album" title:@"Error"];
                return;
            }
            
            [library writeVideoAtPathToSavedPhotosAlbum:videoUrl completionBlock:videoWriteCompletionBlock];
            break;
        }
            
        case FB_IMAGE: {
            FBSDKSharePhoto *photo = [[FBSDKSharePhoto alloc] init];
            photo.image = [UIImage imageNamed:@"large.jpg"];
            photo.userGenerated = YES;
            
            FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
            content.photos = @[photo];
            
            [FBSDKShareDialog showFromViewController:[self currentViewController] withContent:content delegate:self];
            break;
        }
            
        case FB_OG_IMAGE_FULL: {
            NSLog(@"Full OG Image Staging OG Posting FB Publishing!");
            NSLog(@"Access Token to Use: %@",[[FBSDKAccessToken currentAccessToken] tokenString]);
            
            // Putting the image in the action right now using FBSDKShareDialog has the side effect of no image
            // actually being shown here. Will update later
            [FBSDKShareDialog showFromViewController: [self currentViewController]
                                         withContent:[self buildShareContent] delegate:self];
            break;
        }
            
        case FB_OG_IMAGE_FULL_API: {
            NSLog(@"Full OG Image Staging OG Posting FB Publishing!");
            NSLog(@"Access Token to Use: %@",[[FBSDKAccessToken currentAccessToken] tokenString]);
            
            // You can use either or:
            [FBSDKShareAPI shareWithContent:[self buildShareContent] delegate:self];
            break;
        }
            
        case FB_OG_MOVIE: {
            NSLog(@"Full OG Image Staging OG Posting FB Publishing!");
            NSLog(@"Access Token to Use: %@",[[FBSDKAccessToken currentAccessToken] tokenString]);
            
            // Photo to be shared
            FBSDKSharePhoto *shareSnoopy = [[FBSDKSharePhoto alloc] init];
            shareSnoopy.image = [UIImage imageNamed:@"snoopy.png"];
            
            // OG object
            NSDictionary *ogProperties = @{
                                           @"og:type":@"video.movie",
                                           @"og:title":@"Peanuts! Open Graph Adventure",
                                           @"og:description":[NSString stringWithFormat:@"To be released %@, be ready!", [NSDate date]],
                                           @"og:image": @[shareSnoopy]
                                           };
            FBSDKShareOpenGraphObject *ogObject = [FBSDKShareOpenGraphObject objectWithProperties:ogProperties];
            
            // Action
            FBSDKShareOpenGraphAction *action = [[FBSDKShareOpenGraphAction alloc] init];
            action.actionType = @"video.watches";
            [action setNumber:[NSNumber numberWithInt:2800] forKey:@"video:expires_in"];
            [action setNumber:[NSNumber numberWithBool:YES] forKey:@"video:fb:explicitly_shared"];
            [action setObject:ogObject forKey:@"movie"];
            
            // Content
            FBSDKShareOpenGraphContent *content = [FBSDKShareOpenGraphContent alloc];
            content.action = action;
            content.previewPropertyName = @"movie";
            
            [FBSDKShareAPI shareWithContent:content delegate:self];
            break;
        }
            
        case FB_UPLOAD_PHOTO: {
            if (![FBSDKAccessToken currentAccessToken]) {
                [self alertWithMessage:@"Log into FB and request publish_actions" title:@"Upload Failed"];
                return;
            }
            
            NSDictionary *params = @{
                                     @"source":UIImagePNGRepresentation([UIImage imageNamed:@"snoopy.png"])
                                     };
            
            [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me/photos" parameters:params HTTPMethod:@"POST"] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                if (!error) {
                    [self alertWithMessage:[NSString stringWithFormat:@"Result: %@", result] title:@"Post Photo Success!"];
                } else {
                    NSLog(@"Graph API Error: %@", [error description]);
                }
            }];
            
            break;
        }
            
        case FB_GAME_REQUEST: {
            FBSDKGameRequestContent *grc = [[FBSDKGameRequestContent alloc] init];
            grc.message = @"Game Request Message!";
            grc.title = @"Game Request Title!";
            [FBSDKGameRequestDialog showWithContent:grc delegate:self];
            
            break;
        }
            
        case FB_MESSENGER_SEND_PIC: {
            NSLog(@"Sending Pic Through Messenger!");
            if (FBSDKMessengerPlatformCapabilityImage) {
                UIImage *image = [UIImage imageNamed:@"snoopy"];
                
                [FBSDKMessengerSharer shareImage:image withOptions:nil];
            }
            break;
        }
            
        case FB_INVITE: {
            FBSDKAppInviteContent *content = [[FBSDKAppInviteContent alloc] init];
            content.appLinkURL = [NSURL URLWithString:@"https://fb.me/1565514703709197"];
            [FBSDKAppInviteDialog showFromViewController:[self currentViewController] withContent:content delegate:self];
            
            break;
        }
            
        case FB_SHARE_LINK: {
            FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
            content.contentURL = [NSURL URLWithString:@"http://munchies.vice.com/articles/could-new-orleans-public-drinking-culture-disappear"];
            
            [FBSDKShareDialog showFromViewController:[self currentViewController] withContent:content delegate:self];
            break;
        }
            
        case FB_SHARE_SHEET: {
            NSLog(@"Taken care of by the VC");
            break;
        }
            
        case SAVE_INSTALLATION: {
            NSLog(@"Saving Parse Installation");
            
            // Store the deviceToken in the current Installation and save it to Parse.
            PFInstallation *currentInstallation = [PFInstallation currentInstallation];
            [currentInstallation saveInBackground];
            
            [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                NSLog(@"Installation saved! check dashboard!");
            }];
            break;
        }
         
        case ANALYTICS_TEST: {
            NSLog(@"Starting Custom Analytics Test!");
            NSDate *today = [NSDate date];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
            NSString *todayString = [dateFormatter stringFromDate:today];
            
            NSDictionary *dimensions = @{
                                         @"type":@"Open Routebschrijving",
                                         @"timestring":todayString
                                         };
            
            //[PFAnalytics trackEvent:@"action" dimensions:dimensions];
            [PFAnalytics trackEventInBackground:@"action" dimensions:dimensions block:^(BOOL succeeded, NSError *error) {
                NSLog(@"Tracking Event Finished! Succeeded? %@", succeeded);
            }];
            
            NSLog(@"Custom Analytics Test Done!");
            break;
        }
            
        case ACL_NEW_FIELD: {
            [self roleTestWithField:@"new"];
            break;
        }
            
        case ACL_EXISTING_FIELD: {
            [self roleTestWithField:@"existing"];
            break;
        }
            
        case ACL_TEST_QUERY: {
            PFQuery *aclTestQuery = [PFQuery queryWithClassName:@"ACLTest"];
            [aclTestQuery whereKey:@"createdAt" lessThan:[NSDate date]];
            //[aclTestQuery setCachePolicy:kPFCachePolicyCacheElseNetwork];
            [aclTestQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                NSLog(@"Callback!");
                if (error) {
                    [self alertWithMessage:[error description] title:@"ACL Query"];
                } else {
                    NSLog(@"Finding!");
                    for (PFObject *object in objects) {
                        NSLog(@"Found %@ = %@", object.objectId, object[@"value"]);
                    }
                }
            }];
            break;
        }
            
        case SAVE_USER_PROPERTY: {
            NSLog(@"Save user property");
            if ([PFUser currentUser]) {
                [PFUser currentUser][@"location"] = @"Chicago, IL";
                [[PFUser currentUser] saveInBackground];
                NSLog(@"Done Saving property");
            }
            break;
        }
        
        case REFRESH_USER: {
            NSLog(@"Refresh User");
            if ([PFUser currentUser]) {
                [[PFUser currentUser] fetch];
                NSLog([PFUser currentUser][@"location"]);
            }
            break;
        }
            
        case MUTEX_LOCK: {
            NSLog(@"Mutex Lock. I recommend turning off wifi so your DB is not hammered");
            PFObject *a = [PFObject objectWithClassName:@"MutexLock"];
            a[@"user"] = [PFUser currentUser];
            a[@"name"] = @"a";
            [a saveEventually];
            
            PFObject *b = [PFObject objectWithClassName:@"MutexLock"];
            b[@"name"] = @"b";
            b[@"parent"] = a;
            [b saveEventually];
            
            PFObject *c = [PFObject objectWithClassName:@"MutexLock"];
            c[@"name"] = @"c";
            c[@"parent"] = b;
            [c saveEventually];
            
            PFObject *d = [PFObject objectWithClassName:@"MutexLock"];
            d[@"name"] = @"d";
            d[@"parent"] = b;
            [d saveEventually];

            PFObject *e = [PFObject objectWithClassName:@"MutexLock"];
            e[@"name"] = @"e";
            e[@"parent"] = b;
            [e saveEventually];
            
            // Trying to cause the world to burn
            d[@"friend_name"] = b[@"name"];
            
            NSLog(@"Mutex test done.");
            break;
        }
            
        case QUERY_FIRST_OBJECT: {
            PFQuery *aclq = [PFQuery queryWithClassName:@"ACLTest"];
            NSError *error;
            PFObject *first = [aclq getFirstObject:&error];
            
            NSLog(@"First id %@", [first objectId]);
            break;
        }
            
        case QUERY_FIRST_OBJECT_USING_CLASS: {
            PFQuery *aclq = [ACLTest query];
            NSError *error;
            PFObject *first = [aclq getFirstObject:&error];
            NSLog(@"First id %@", [first objectId]);
            ACLTest *result = (ACLTest *)first;
            NSLog(@"Device es %@", result);
            break;
        }
            
        case QUERY_COMPOUND: {
            [self alertWithMessage:@"Not Implemented" title:@"Compound Query Test"];
            break;
        }
            
        case QUERY_DESCRIPTOR: {
            NSLog(@"Querying using Sort Descriptor!");
            
            PFQuery *scoreQuery = [PFQuery queryWithClassName:@"Score"];
            NSSortDescriptor *scoreDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"objectId" ascending:YES comparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
                NSLog(@"Never executed");
                return [obj1 compare:obj2];
            }];
            
            [scoreQuery orderBySortDescriptor:scoreDescriptor];
            [scoreQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                NSLog(@"Query Callback!");
                if (error) {
                    [self alertWithMessage:[error description] title:@"Query Descriptor"];
                } else {
                    NSLog(@"Finding!");
                    for (PFObject *object in objects) {
                        NSLog(@"Found %@ = %@", object.objectId, object[@"score"]);
                    }
                }
            }];
            
            NSLog(@"Sort Descriptor Done!");
            break;
        }
            
        case QUERY_CACHE: {
            PFQuery *userQuery = [PFQuery queryWithClassName:@"_User"];
            userQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
            
            __block BOOL cachedResult = YES;
            [userQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                //we send whether or not the result is cached or not
                if (cachedResult) {
                    NSLog(@"Retrieved from cache");
                    cachedResult = NO;
                } else {
                    NSLog(@"Retrieved from network");
                }

                if (!error) {
                    NSLog(@"Retrieved object: %@", object.objectId);
                }
                else{
                    NSLog(@"Cache query error!");
                    if (error.code == kPFErrorCacheMiss) {
                        NSLog(@"Profile: kPFErrorCacheMiss");
                        [self alertWithMessage:error.localizedDescription title:@"Query Cache Failed"];
                    }
                }
            }];
            break;
        }
            
        case LDS_PINNING: {
            PFQuery *aclq = [PFQuery queryWithClassName:@"ACLTest"];
            [aclq findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (error == nil) {
                    NSLog(@"Find In Background is back!");
                    for (PFObject *object in objects) {
                        NSLog(@"Found %@ = %@", object.objectId, object[@"value"]);
                        object[@"user"] = [PFUser currentUser];
                    }
                    [PFObject pinAllInBackground:objects withName:@"ACLTestObjects" block:^(BOOL succeeded, NSError *error) {
                        if (error == nil) {
                            pinned_first = YES;
                            NSLog(@"Success when pinning %lu objects to local datastore", (unsigned long)[objects count]);
                        } else {
                            NSLog(@"There was an error when pinning: %@", [error description]);
                        }
                    }];
                } else {
                    NSLog(@"There was an error pulling objects in background: %@", [error description]);
                }
            }];
            
            break;
        }
        
        case LDS_PIN_WITH_NAME: {
            NSLog(@"Pinning with name!");
            PFObject *localObject = [PFObject objectWithClassName:@"NamePinnedObject"];
            localObject[@"value"] = @"I'm local!";
            [localObject pinInBackgroundWithName:@"namePin" block:^(BOOL succeeded, NSError *error) {
                if (error == nil) {
                    [self alertWithMessage:[NSString stringWithFormat:@"Status: %i", succeeded] title:@"Name Pinning Finished"];
                } else {
                    [self alertWithMessage:[error description] title:@"Name Pinning Failed"];
                }
            }];
            break;
        }
            
        case LDS_QUERY_PIN_WITH_NAME: {
            NSLog(@"Querying Pin with name!");
            PFQuery *pinQuery = [PFQuery queryWithClassName:@"NamedPinnedObject"];
            [pinQuery fromPinWithName:@"namePin"];
            [pinQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (error == nil) {
                    NSLog(@"Found %lu objects", (unsigned long)[objects count]);
                    for (PFObject *local in objects) {
                        NSLog(@"id:%@ value:%@", local.objectId, local[@"value"]);
                    }
                } else {
                    [self alertWithMessage:[error description] title:@"Name Pinning Failed"];
                }
            }];
            break;
        }

        case LDS_QUERY_ALL: {
            if (!pinned_first) {
                [self alertWithMessage:@"Pin First!" title:@"Query All"];
                return;
            }
            
            PFQuery *aclQ = [PFQuery queryWithClassName:@"ACLTest"];
            [aclQ fromLocalDatastore];
            [aclQ findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                for (PFObject *aclTest in objects) {
                    NSLog(@"id: %@, value: %@", [aclTest objectId], aclTest[@"value"]);
                }
            }];
            break;
        }
        
        case LDS_QUERY_LOCAL: {
            if (!pinned_first) {
                [self alertWithMessage:@"Pin First!" title:@"Query Local"];
                return;
            }
            
            PFQuery *aclQ = [PFQuery queryWithClassName:@"ACLTest"];
            [aclQ fromLocalDatastore];
            [aclQ whereKey:@"objectId" equalTo:@"mC6nn2MfTI"];
            [aclQ findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                PFObject *aclTest = objects[0];
                NSLog(@"Finished querying local datastore, object value is %@", aclTest[@"value"]);
            }];
            break;
        }
        
        case LDS_SAVE_LOCAL: {
            PFQuery *aclQ = [PFQuery queryWithClassName:@"ACLTest"];
            [aclQ fromLocalDatastore];
            [aclQ whereKey:@"objectId" equalTo:@"mC6nn2MfTI"];
            [aclQ findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                PFObject *aclTest = objects[0];
                NSLog(@"Finished querying local datastore, object value is %@", aclTest[@"value"]);
                [aclTest setObject:@"99" forKey:@"value"];
                NSLog(@"Sent for saving");
                [aclTest saveEventually];
            }];
            break;
        }
            
        case LDS_DELETE_BACKGROUND: {
            NSLog(@"Delete In Background!");
            PFQuery *aclQ = [PFQuery queryWithClassName:@"ACLTest"];
            [aclQ fromLocalDatastore];
            [aclQ findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                PFObject *aclTest = objects[0];
                NSLog(@"Finished querying local datastore, object value is %@", aclTest[@"value"]);
                
                [aclTest deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    NSLog(@"Call to deleteInBackground done!");
                    if (error != nil) {
                        [self alertWithMessage:[error description] title:@"Delete In Background Failed"];
                    } else {
                        [self alertWithMessage:@"Query Locally to verify" title:@"Delete In Background Finished"];
                    }
                }];
                /*
                [aclTest deleteEventually];
                */
            }];
            break;
        }
            
        case LDS_PIN_NULL: {
            NSLog(@"LDS Pinning null!");
            
            PFQuery *nullPinQuery = [PFQuery queryWithClassName:@"NullPin"];
            [nullPinQuery fromLocalDatastore];
            [nullPinQuery includeKey:@"nullColumn"];
            [nullPinQuery setLimit:1];
            
            [nullPinQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                NSLog(@"Finding nullPinQuery block!");
                if (!objects || error) {
                    NSLog(@"Found an issue %@", [error description]);
                    return;
                }
                
                if (objects.count == 0) {
                    NSLog(@"nullPinObject created and pinned in the background!");
                    PFObject *nullPinObject = [PFObject objectWithClassName:@"NullPin"];
                    [nullPinObject setObject:[NSNull null] forKey:@"nullColumn"];
                    [nullPinObject saveInBackground];
                    [nullPinObject pinInBackground];
                } else {
                    PFObject *nullPinObject = objects[0];
                    NSLog(@"Value of column: %@", nullPinObject[@"nullColumn"]);
                }
            }];
            break;
        }
            
        case LDS_CREATE_PIN_LOCALLY: {
            NSMutableArray *localObjects = [[NSMutableArray alloc] init];
            for (int i = 0; i < 5; i++) {
                PFObject *localPinObject = [PFObject objectWithClassName:@"LocalPinObject"];
                localPinObject[@"value"] = [NSString stringWithFormat:@"localValue %i", i];
                [localPinObject saveEventually:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        NSLog(@"Local object saved eventually successfully!");
                    } else {
                        NSLog(@"Local object could not be saved!");
                    }
                }];
                [localObjects addObject:localPinObject];
            }
            
            [PFObject pinAllInBackground:localObjects block:^(BOOL succeeded, NSError *error) {
                [self alertWithMessage:@"Now try counting them!" title:@"LocalPinObject Pinned offline"];
            }];
            break;
        }
            
        case LDS_QUERY_PIN_OFFLINE: {
            PFQuery *localPinQuery = [PFQuery queryWithClassName:@"LocalPinObject"];
            [localPinQuery fromLocalDatastore];
            NSInteger localCount = [localPinQuery countObjects];
            [self alertWithMessage:[NSString stringWithFormat:@"And they are %li", (long)localCount] title:@"LocalPinObject counted offline"];
            break;
        }
            
        case LDS_QUERY_PIN_ONLINE: {
            PFQuery *localPinQuery = [PFQuery queryWithClassName:@"LocalPinObject"];
            NSInteger localCount = [localPinQuery countObjects];
            [self alertWithMessage:[NSString stringWithFormat:@"And they are %li", (long)localCount] title:@"LocalPinObject counted online"];
            break;
        }
            
        case LDS_NESTED_PIN: {
            NSLog(@"LDS Nested Pin");
            PFObject *localObject = [PFObject objectWithClassName:@"LocalObject"];
            localObject[@"value"] = @"I'm local";
            
            PFObject *nestedObject = [PFObject objectWithClassName:@"NestedObject"];
            localObject[@"nested"] = nestedObject;
            
            [localObject pinInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [self alertWithMessage:@"Pinned Successfully!" title:@"Nested Pin"];
            }];
            break;
        }
            
        case LDS_NESTED_FETCH: {
            NSLog(@"LDS Nested Fetch");
            PFQuery *localSearch = [PFQuery queryWithClassName:@"LocalObject"];
            [localSearch fromLocalDatastore];
            
            [localSearch findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (error != nil) {
                    [self alertWithMessage:[error description] title:@"Nested fetch failed"];
                } else {
                    NSLog(@"Found Pinned objects in background!");
                    for (PFObject *localObject in objects) {
                        NSLog(@"Value: %@, Nested: %@", localObject[@"value"], localObject[@"nested"]);
                    }
                }
            }];
            break;
        }
            
        case LDS_USER_RELATION_CREATE: {
            NSLog(@"User relation object create!");
            if ([PFUser currentUser]) {
                PFObject *objectWithUser = [PFObject objectWithClassName:@"ObjectWithUser"];
                objectWithUser[@"column"] = @"I want User!";
                PFRelation *usersRelation = [objectWithUser relationForKey:@"users"];
                [usersRelation addObject:[PFUser currentUser]];
                [objectWithUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (error == nil) {
                        [objectWithUser pinInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if (error == nil) {
                                NSLog(@"User Pinning success? %i", succeeded);
                            } else {
                                NSLog(@"Pinning of user failed: %@", [error description]);
                            }
                        }];
                        [self alertWithMessage:@"ObjectWithUser Saved Online and Pinned to LDS" title:@"Success!"];
                    } else {
                        [self alertWithMessage:[error description] title:@"Error saving ObjectWithUser!"];
                    }
                }];
            } else {
                [self alertWithMessage:@"Log in first!" title:@"Can't create relation"];
            }
            break;
        }
            
        case LDS_USER_RELATION_ONLINE_FETCH: {
            NSLog(@"User relation online fetch!");
            if ([PFUser currentUser]) {
                PFQuery *owuQuery = [PFQuery queryWithClassName:@"ObjectWithUser"];
                [owuQuery whereKey:@"users" equalTo:[PFUser currentUser]];
                [owuQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    [self alertWithMessage:[NSString stringWithFormat:@"Found %lu", (unsigned long)[objects count]] title:@"Online Fetch Callback"];
                    if (error == nil) {
                        for (PFObject *objectWithUser in objects) {
                            NSLog(@"Object Id %@", objectWithUser.objectId);
                            PFRelation *users = objectWithUser[@"users"];
                            PFQuery *all = [users query];
                            NSArray *allResult = [all findObjects];
                            for (PFObject *result in allResult) {
                                NSLog(@"User Id in relation: %@", result.objectId);
                            }
                        }
                    } else {
                        [self alertWithMessage:[error description] title:@"Error online query!"];
                    }
                }];
            } else {
                [self alertWithMessage:@"Log in first!" title:@"Can't online query"];
            }
            break;
        }
            
        case LDS_USER_RELATION_LOCAL_FETCH: {
            NSLog(@"User relation local fetch!");
            if ([PFUser currentUser]) {
                PFQuery *owuQuery = [PFQuery queryWithClassName:@"ObjectWithUser"];
                [owuQuery fromLocalDatastore];
                [owuQuery whereKey:@"users" equalTo:[PFUser currentUser]];
                [owuQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    [self alertWithMessage:[NSString stringWithFormat:@"Found %lu", (unsigned long)[objects count]] title:@"Local Fetch Callback"];
                    if (error == nil) {
                        for (PFObject *objectWithUser in objects) {
                            NSLog(@"Object Id %@", objectWithUser.objectId);
                            PFRelation *users = objectWithUser[@"users"];
                            PFQuery *all = [users query];
                            NSArray *allResult = [all findObjects];
                            for (PFObject *result in allResult) {
                                NSLog(@"User Id in relation: %@", result.objectId);
                            }
                        }
                    } else {
                        [self alertWithMessage:[error description] title:@"Error online query!"];
                    }
                }];
            } else {
                [self alertWithMessage:@"Log in first!" title:@"Can't online query"];
            }
            break;
        }
            
        case CLOUD_CODE_POINTER_TEST: {
            NSLog(@"Cloud code pointer test");
            [PFCloud callFunctionInBackground:@"createObjectWithPointer" withParameters:@{} block:^(id object, NSError *error) {
                PFObject *objectWithPointer = (PFObject *)object;
                
                NSLog(@"randomColumn Value %@", objectWithPointer[@"randomColumn"]);
                PFObject *aclTest = objectWithPointer[@"pointer"];
                NSLog(@"Linked ACLTest objectID %@, isDataAvailable? %d", aclTest.objectId, [aclTest isDataAvailable]);
                if ([aclTest isDataAvailable]) {
                    NSLog(@"Pointer included value %@", aclTest[@"value"]);
                }
            }];
            break;
        }
        
        case CLOUD_CODE_EMPTY_POINTER_TEST: {
            NSLog(@"Cloud code empty pointer test");
            [PFCloud callFunctionInBackground:@"createObjectWithShellPointer" withParameters:@{} block:^(id object, NSError *error) {
                if (error == nil) {
                    PFObject *objectWithPointer = (PFObject *)object;
                
                    NSLog(@"randomColumn Value %@", objectWithPointer[@"randomColumn"]);
                    PFObject *aclTest = objectWithPointer[@"pointer"];
                    NSLog(@"Linked ACLTest objectID %@, isDataAvailable? %d", aclTest.objectId, [aclTest isDataAvailable]);
                    // Try to log fetched value
                    if ([aclTest isDataAvailable]) {
                        NSLog(@"Pointer included value %@", aclTest[@"value"]);
                    } else {
                        NSLog(@"There was no data available!");
                    }
                    // Try to get necessary data from DB
                    [aclTest fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                        NSLog(@"fetchedIn Background! Included value %@", object[@"value"]);
                    }];
                } else {
                    [self alertWithMessage:[error description] title:@"Cloud Code Error"];
                }
            }];
            break;
        }
            
        case BC_AD_DATES_SAVING: {
            NSLog(@"Testing BC/AD Dates");
            
            NSString *dateFormat = @"MMMM d, yyyy GGG";
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:dateFormat];
            
            NSArray *dateA = @[@"March 15, 44 BC",@"April 15, 62 AD",@"June 15, 101 AD"];
            NSMutableDictionary *dateMD = [NSMutableDictionary dictionaryWithCapacity:3];
            
            NSLog(@"Show strings and resulting dates");
            for (NSString *string in dateA) {
                NSDate *date = [dateFormatter dateFromString:string];
                NSLog(@"NSDate instance for string '%@' = %@\n       formatted = %@",string,date,[dateFormatter stringFromDate:date]);
                [dateMD setObject:date forKey:string];
            }
            
            // Saving to Parse
            /*
            for (NSString *key in dateMD) {
                NSDate *old_date = [dateMD objectForKey:key];
                
                
                PFObject *acBcTest = [[PFObject alloc] initWithClassName:@"ACBCDate"];
                acBcTest[@"name"] = [NSString stringWithFormat:@"%@%@", @"test_", key];
                acBcTest[@"savedDate"] = old_date;
                
                NSLog(@"Before Saving %@", acBcTest[@"savedDate"]);
                [acBcTest saveInBackground];
            }
            */
            
            break;
        }
            
        case BC_AD_DATES_RETRIEVING: {
            NSLog(@"Retrieving ACBCDates");
            PFQuery *acBcQuery = [PFQuery queryWithClassName:@"ACBCDate"];

            NSString *dateFormat = @"MMMM d, yyyy GGG";
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:dateFormat];
            [acBcQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error) {
                    for (PFObject *parseDate in objects) {
                        NSLog(@"%@ : %@", parseDate[@"name"], [dateFormatter stringFromDate:parseDate[@"savedDate"]]);
                    }
                } else {
                    NSLog(@"There was an error retrieving dates: %@", [error description]);
                }
            }];
            
            break;
        }

        default:
            NSLog(@"Unknown sample code to exeute!");
            break;
    }
}

- (void)sampleFinished:(NSInteger)sampleIndex {
    if ([self repro_steps].count > 0
        && sampleIndex == [[[self repro_steps] objectAtIndex:0] integerValue]
    ) {
        [[self repro_steps] removeObjectAtIndex:0];
    }
}

- (void)roleTestWithField:(NSString*)field {
    NSLog(@"Role Testing with %@ field", field);
    
    if ([PFUser currentUser]) {
        NSString* fieldName = @"description";
        
        if ([field  isEqual: @"new"]) {
            fieldName = @"fbTest";
        }
        
        PFObject *exception = [PFObject objectWithClassName:@"Exception"];
        exception[fieldName] = @"fbTest";
        [exception saveInBackgroundWithBlock:^(BOOL succeded, NSError *error) {
            if (error) {
                NSLog(@"Error saving Exception: %@", error);
            } else {
                NSLog(@"Saved succesfully, check the data browser");
            }
        }];
    } else {
        [self alertWithMessage:@"You have to Sign Up first!" title:[NSString stringWithFormat:@"Role Test With Field '%@d'", field]];
    }
}

/*
*
*   FBSDKSharingDelagte
*
*/
- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results {
    NSLog(@"Sharing didCompleteWithResults");
    [self alertWithMessage:[NSString stringWithFormat:@"Results:\n%@", results] title:@"Sharing Completed!"];
}

-(void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error {
    NSLog(@"Sharing didFailWithError");
    [self alertWithMessage:[NSString stringWithFormat:@"Error:]n%@", [error description]] title:@"Sharing Failed!"];
    NSLog([error description]);
}

-(void)sharerDidCancel:(id<FBSDKSharing>)sharer {
    [self alertWithMessage:@"Sharer Cancelled" title:@"Sharing Failed!"];
}

/*
 *
 *  FBSDKGameRequestDialogDelegate
 *
*/
- (void)gameRequestDialog:(FBSDKGameRequestDialog *)gameRequestDialog didCompleteWithResults:(NSDictionary *)results {
    NSLog(@"Game Request Dialog Completed");
}

- (void)gameRequestDialog:(FBSDKGameRequestDialog *)gameRequestDialog didFailWithError:(NSError *)error {
    NSLog(@"Game Request Dialog Failed");
}

- (void) gameRequestDialogDidCancel:(FBSDKGameRequestDialog *)gameRequestDialog {
    NSLog(@"Game Request Dialog Cancelled");
}

/*
 *
 *  FBSDKAppInviteDialogDelegate
 *
 */
- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didCompleteWithResults:(NSDictionary *)results {
    NSLog(@"Invite dialog did complete!");
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didFailWithError:(NSError *)error {
    NSLog(@"Invite dialog did fail with error %@", [error description]);
}

/*
 *
 *   Random Logging
 *
 */
- (void)logTwitterCredentials {
    [self alertWithMessage:[NSString stringWithFormat:@"AuthToken: %@\n@AuthTokenSecret: %@", [[PFTwitterUtils twitter] authToken], [[PFTwitterUtils twitter] authTokenSecret]] title:@"Twitter Credentials!"];
}

- (void)logUser:(PFUser*) fetched {
    NSLog(@"Current user is %@", fetched[@"username"]);
}

- (void)alertWithMessage:(NSString *)message title:(NSString *)title {
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:title
                                message:message
                                preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction
                         actionWithTitle:@"Got It" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                             [alert dismissViewControllerAnimated:YES completion:nil];
                         }];
    
    [alert addAction:ok];
    
    [[self currentViewController] presentViewController:alert animated:YES completion:nil];
}

/*
 *
 *  Utils
 *
 */
- (UIViewController*) currentViewController {
    return [self viewController];
}

- (FBSDKShareOpenGraphContent*) buildShareContent {
    // Photo to be shared
    FBSDKSharePhoto *shareImage = [[FBSDKSharePhoto alloc] init];
    shareImage.image = [UIImage imageNamed:@"720.png"];
    shareImage.userGenerated = YES;
    
    // OG object
    NSDictionary *ogProperties = @{
                                   @"og:type":@"alanmgsandbox:accident",
                                   @"og:title":@"Watch out!",
                                   @"og:url":@"http://thump.vice.com/en_us/article/this-is-what-its-like-to-spend-6-years-djing-for-justin-bieber",
                                   @"og:description":[NSString stringWithFormat:@"On %@, Snoopy tripped into Woodstock!", [NSDate date]]
                                   };
    FBSDKShareOpenGraphObject *ogObject = [FBSDKShareOpenGraphObject objectWithProperties:ogProperties];
    // If what you intend is to add the image to the OG Object, do it like this:
    [ogObject setPhoto:shareImage forKey:@"og:image"];
    
    // Action
    FBSDKShareOpenGraphAction *action = [[FBSDKShareOpenGraphAction alloc] init];
    action.actionType = @"alanmgsandbox:photograph";
    [action setObject:ogObject forKey:@"accident"];
    // If you want to add an image to the Action, use this:
    //[action setArray:@[shareImage] forKey:@"image"];
    
    // Content
    FBSDKShareOpenGraphContent *content = [FBSDKShareOpenGraphContent alloc];
    content.action = action;
    content.previewPropertyName = @"accident";

    return content;
}

- (FBSDKLoginManager*) getLoginManager {
    if (loginManager == nil) {
        loginManager = [[FBSDKLoginManager alloc] init];
    }
    
    return loginManager;
}
@end
