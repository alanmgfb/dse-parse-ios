# dse-parse-ios

DSE Parse iOS sample project with extendable UI.

## Setup

I am assuming you already have a Facebook Application, and a Parse application with your Facebook Application credentials set up. 

Modify `AMGAppDelegate.m` so it includes your Parse Credentials.

```objective-c
    [Parse setApplicationId:@"YOUR_APP_ID"
                  clientKey:@"YOUR_CLIENT_KEY"];
```

Modify `dse-parse-ios-Info.plist` to include your Facebook Applciation credentials under `FacebookAppID` and `URL Types`, and your Facebook Application Name under `FacebookDisplayName`.
Run the project. It should Just Work!

## Extending the UI

There's pre built functionality for Parse under this Project, but should you need to add anything else:

 On `AMGParseSampleSource.h`, add a new value to `ParseSampleEnum`, for example `MY_NEW_AWESEOME_SAMPLE`:

```objective-c
typedef enum {
    SIGN_UP,
    LOGIN,
    ANON_LOGIN,
    VC_LOGIN,
    FB_LOGIN,
    TWITTER_LOGIN,
    SAVE_INSTALLATION,
    ANALYTICS_TEST,
    ACL_NEW_FIELD,
    ACL_EXISTING_FIELD,
    ACL_TEST_QUERY,
    SAVE_USER_PROPERTY,
    REFRESH_USER,
    QUERY_FIRST_OBJECT,
    QUERY_FIRST_OBJECT_USING_CLASS,
    QUERY_COMPOUND,
    LDS_PINNING,
    MY_NEW_AWESOME_SAMPLE
} ParseSampleEnum;
```

 On `AMGParseSampleSource.m`, modify `-(void)setupSections`:
```objective-c
    NSArray *sections = @[@"Login", @"Events / Analytics", @"ACL", @"PFObjects", @"Queries", @"LDS", @"My New Awesome Section"];
    
    NSDictionary *samples =
    @{
      @"Login" : @[@"Sign Up", @"Log In", @"Anonymous Login", @"View Controller Login", @"Facebook", @"Twitter"],
      @"Events / Analytics" : @[@"Save Installation", @"Save Event"],
      @"ACL" : @[@"Add New Field", @"Update Existing Field", @"ACL Test Query"],
      @"PFObjects" : @[@"Save PFUser Property", @"Refresh User"],
      @"Queries" : @[@"Get First Object", @"Get First, using class", @"Compound Query Test"],
      @"LDS" : @[@"ACL Pinning Test"],
      @"My New Awesome Section" : @[@"My New Awesome Sample"],
      };
```

 On `AMGParseSampleSource.m`, add a new sample on `- (void)executeSample:(NSInteger)sampleIndex`:

```objective-c
switch(sampleIndex):
    case MY_NEW_AWESOME_SAMPLE {
        NSLog(@"Hello World!");
}
```

 Run. You should see your new section created on the UI, and when tapping on it, you will get a Log saying `Hello World!`
