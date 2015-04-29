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
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import <FacebookSDK/FacebookSDK.h>
#import <FBSDKMessengerShareKit/FBSDKMessengerShareKit.h>

@implementation AMGParseSampleSource
static NSMutableArray *mutableSections = nil;
NSString *const EMAIL = @"alaniOS@alaniOS.com";
NSString *const USERNAME = @"alaniOS";
NSString *const PASSWORD = @"alaniOS";
NSArray *FB_READ_PERMS_ARRAY = nil;
NSArray *FB_PUBLISH_PERMS_ARRAY = nil;

// OG Testing
NSString *og_image_uri = nil;
NSString *og_object_id = nil;

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
      @"Login" : @[@"Sign Up", @"Log In", @"Anonymous Login", @"View Controller Login", @"Facebook", @"Twitter", @"Reset Password", @"Facebook Unlink", @"Log out"],
      @"Facebook" : @[@"See Current Permissions", @"Request publish_actions", @"Publish Random Post", @"Stage Image", @"Create OG Object", @"OG Post", @"Full OG Sample", @"Messenger Send Pic"],
      @"Events / Analytics" : @[@"Save Installation", @"Save Event"],
      @"ACL" : @[@"Add New Field", @"Update Existing Field", @"ACL Test Query"],
      @"PFObjects" : @[@"Save PFUser Property", @"Refresh User"],
      @"Queries" : @[@"Get First Object", @"Get First, using class", @"Compound Query Test"],
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
            if (![PFUser currentUser]) {
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
            
        // Handled by the Table View Controller
        case VC_LOGIN: {break;}
        
        case FB_LOGIN: {
            NSLog(@"Starting Facebook Auth");
            
            // Login PFUser using Facebook
            [PFFacebookUtils logInWithPermissions:FB_READ_PERMS_ARRAY block:^(PFUser *user, NSError *error) {
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
                    
                    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
                    
                    [params setObject:@"id,gender,first_name,last_name,birthday" forKey:@"fields"];
                    
                    [FBRequestConnection startWithGraphPath:@"me/friends" parameters:params HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                        ////// do stuff with the friends. here we get only friends that use the app if permissions are asked via Safari > facebook.com
                        NSArray* friends = [result objectForKey:@"data"];
                        NSLog(@"Found: %lu friends", friends.count);
                        for (NSDictionary<FBGraphUser>* friend in friends) {
                            NSLog(@"I have a friend named %@ with id %@", friend.name, friend.objectID);
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
            
        case FB_CURRENT_PERMISSIONS: {
            [self alertWithMessage:[NSString stringWithFormat:@"%@", [[PFFacebookUtils session] permissions]] title:@"Current Permissions"];
            break;
        }
            
        case FB_REQUEST_EXTRA_PERMISSIONS: {
            if ([[PFFacebookUtils session] isOpen]) {
                NSLog(@"Session Permissions %@", [[PFFacebookUtils session] permissions]);
                [PFFacebookUtils reauthorizeUser:[PFUser currentUser] withPublishPermissions:FB_PUBLISH_PERMS_ARRAY audience:FBSessionDefaultAudienceOnlyMe block:^(BOOL succeeded, NSError *error){
                    if (!error) {
                        [self alertWithMessage:@"Requested extra permission successfully!" title:@"Request extra permissions"];
                    }
                }];
            } else {
                [self alertWithMessage:@"Login through Facebook First" title:@"FB Request Extra Perms"];
            }
            break;
        }
        
        case FB_PUBLISH_RANDOM_POST: {
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSString stringWithFormat:@"Random Post %@", [NSDate date]], @"message", nil];
            
            [FBRequestConnection startWithGraphPath:@"/me/feed"
                                         parameters:params
                                         HTTPMethod:@"POST"
                                  completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                      if (error) {
                                          NSLog(@"newpost: publish error is: %@", error);
                                      }
                                      else {
                                          [self alertWithMessage:@"Publish success!" title:@"Publish Random Post"];
                                      }
            }];
            break;
        }
            
        case FB_STAGE_IMAGE: {
            NSLog(@"FB Staging image!");
            UIImage *snoopy = [UIImage imageNamed:@"snoopy.png"];
            [FBRequestConnection
             startForUploadStagingResourceWithImage:snoopy
             completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                 if(!error) {
                     og_image_uri = [result objectForKey:@"uri"];
                     // Log the uri of the staged image
                     [self alertWithMessage:og_image_uri title:@"Image Staging Success!"];
                     NSLog(@"Picture URI: %@", og_image_uri);
                 } else {
                     // An error occurred
                     [self alertWithMessage:[error description] title:@"Image Staging Failed"];
                 }
             }];
            break;
        }
            
        case FB_PUBLISH_OG_OBJECT: {
            if (!og_image_uri) {
                [self alertWithMessage:@"Please Stage Image First" title:@"Can't Publish Yet"];
            } else {
                NSMutableDictionary<FBOpenGraphObject> *object = [FBGraphObject openGraphObjectForPost];
                object.provisionedForPost = YES;
                object[@"title"] = @"Death by Hug";
                object[@"type"] = @"alanmgsandbox:accident";
                object[@"description"] = [NSString stringWithFormat:@"Snoopy choked Woodstock with Love. %@", [NSDate date]];
                object[@"image"] = @[@{@"url":og_image_uri, @"user_generated" : @"true" }];
                
                // Post custom object
                [FBRequestConnection
                 startForPostOpenGraphObject:object
                 completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                     if(!error) {
                         og_object_id = [result objectForKey:@"id"];
                         NSLog(@"object id: %@", og_object_id);
                         [self alertWithMessage:og_object_id title:@"OG Object Creation Success!"];
                     } else {
                         // An error occurred
                         NSLog(@"Error posting the Open Graph object to the Object API: %@", [error description]);
                     }
                 }];
            }
            break;
        }
            
        case FB_OG_POST: {
            if (!og_object_id) {
                [self alertWithMessage:@"Please Publish Object First" title:@"Can't Post Yet!"];
            } else {
                id<FBOpenGraphAction> action = (id<FBOpenGraphAction>)[FBGraphObject graphObject];
                [action setObject:og_object_id forKey:@"accident"];
                [FBRequestConnection
                 startForPostWithGraphPath:@"/me/alanmgsandbox:photograph"
                 graphObject:action
                 completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                     if(!error) {
                         NSLog(@"OG story posted, story id: %@", [result objectForKey:@"id"]);
                         [self alertWithMessage:@"Check your Facebook profile or activity log to see the story." title:@"OG story posted"];
                     } else {
                         // An error occurred
                         [self alertWithMessage:[error description] title:@"Error Posting to Open Graph"];
                     }
                 }];
            }
            break;
        }
            
        case FB_OG_IMAGE_FULL: {
            NSLog(@"Full OG Image Staging OG Posting FB Publishing!");
            UIImage *snoopy = [UIImage imageNamed:@"snoopy.png"];
            NSLog(@"Access Token to Use: %@",[FBSession activeSession].accessTokenData.accessToken);
            
            [FBRequestConnection
             startForUploadStagingResourceWithImage:snoopy
             completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                 if(!error) {

                     // Log the uri of the staged image
                     [self alertWithMessage:[result objectForKey:@"uri"] title:@"Image Staging Success!"];
                     NSLog(@"Picture URI: %@", [result objectForKey:@"uri"]);
                     NSMutableDictionary<FBOpenGraphObject> *object = [FBGraphObject openGraphObjectForPost];
                     object.provisionedForPost = YES;
                     object[@"title"] = @"Death by Hug";
                     object[@"type"] = @"alanmgsandbox:accident";
                     object[@"description"] = [NSString stringWithFormat:@"Snoopy choked Woodstock with Love. %@", [NSDate date]];
                     object[@"image"] = @[@{@"url": [result objectForKey:@"uri"], @"user_generated" : @"true" }];
                     // Post custom object
                     [FBRequestConnection
                      startForPostOpenGraphObject:object
                      completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                          if(!error) {
                              NSString *objectId = [result objectForKey:@"id"];
                              NSLog(@"object id: %@", objectId);
                              id<FBOpenGraphAction> action = (id<FBOpenGraphAction>)[FBGraphObject graphObject];
                              [action setObject:objectId forKey:@"accident"];
                              [FBRequestConnection
                               startForPostWithGraphPath:@"/me/alanmgsandbox:photograph"
                               graphObject:action
                               completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                   if(!error) {
                                       NSLog(@"OG story posted, story id: %@", [result objectForKey:@"id"]);
                                       [self alertWithMessage:@"Check your Facebook profile or activity log to see the story." title:@"OG story posted"];
                                   } else {
                                       // An error occurred
                                       [self alertWithMessage:[error description] title:@"Error Posting to Open Graph"];
                                   }
                               }];
                          } else {
                              // An error occurred
                              NSLog(@"Error posting the Open Graph object to the Object API: %@", error);
                          }
                      }];
                 } else {
                     // An error occurred
                     [self alertWithMessage:[error description] title:@"Image Staging Failed"];
                 }
             }];
            break;
        }
            
        case FB_MESSENGER_SEND_PIC: {
            NSLog(@"Sending Pic Through Messenger!");
            if ([FBSDKMessengerSharer messengerPlatformCapabilities] & FBSDKMessengerPlatformCapabilityImage) {
                UIImage *image = [UIImage imageNamed:@"snoopy"];
                
                [FBSDKMessengerSharer shareImage:image withOptions:nil];
            }
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
            [aclTestQuery setCachePolicy:kPFCachePolicyCacheElseNetwork];
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
            
        case LDS_PINNING: {
            PFQuery *aclq = [PFQuery queryWithClassName:@"ACLTest"];
            [aclq findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (error == nil) {
                    NSLog(@"Find In Background is back!");
                    for (PFObject *object in objects) {
                        NSLog(@"Found %@ = %@", object.objectId, object[@"value"]);
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

- (void)logUser:(PFUser*) fetched {
    NSLog(@"Current user is %@", fetched[@"username"]);
}

- (void)alertWithMessage:(NSString *)message title:(NSString *)title {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Got It", nil];
    
    [alert show];
}
@end
