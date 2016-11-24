//
//  ChuckPadSocial.h
//  chuckpad-social-ios
//  https://github.com/markcerqueira/chuckpad-social-ios
// 

#ifndef ChuckPadSocial_h
#define ChuckPadSocial_h

#import <objc/NSObject.h>
#import <Foundation/Foundation.h>

@class Patch;

// If the service returns 0 patches because 0 patches match the conditions (e.g. you request a user's patches but the
// user has 0), the callback will return an NSArry of size 0 and a nil error.
typedef void(^GetPatchesCallback)(NSArray *patchesArray, NSError *error);

typedef void(^CreateUserCallback)(BOOL succeeded, NSError *error);

typedef void(^CreatePatchCallback)(BOOL succeeded, Patch *patch, NSError *error);

typedef void(^UpdatePatchCallback)(BOOL succeeded, Patch *patch, NSError *error);

typedef void(^GetPatchInfoCallback)(BOOL succeeded, Patch *patch, NSError *error);

typedef void(^DeletePatchCallback)(BOOL succeeded, NSError *error);

typedef void(^DownloadPatchResourceCallback)(NSData *patchData, NSError *error);

typedef void(^ReportAbuseCallback)(BOOL succeeded, NSError *error);

typedef void(^LogOutCallback)(BOOL succeeded, NSError *error);

typedef void(^ForgotPasswordCallback)(BOOL succeeded, NSError *error);

// Notification Constants

// Posted when login (regular login and automatic login following registration) of a user is complete
extern NSString *const CHUCKPAD_SOCIAL_LOG_IN;

// Sent when a user is logged out
extern NSString *const CHUCKPAD_SOCIAL_LOG_OUT;

// The ChuckPadSocial service can host patches from different applications. This singleton class needs to be
// bootstrapped via the bootstrapForPatchType method to get and upload the proper patch types.
typedef enum {
    Unconfigured = 0,
    MiniAudicle = 1,
    Auraglyph = 2
} PatchType;

// If the number of elements in this enum change, update the toggleEnvironment method!
typedef enum {
    Production,
    Stage,
    Local
} Environment;

#define EnvironmentHostUrls @"https://chuckpad-social.herokuapp.com", @"https://chuckpad-social-stage.herokuapp.com", @"http://localhost:9292", nil

@interface ChuckPadSocial : NSObject

// This method configures the ChuckPadSocial class to upload and get patches of a specific type. This method MUST be
// called before any other method on ChuckPadSocial!
+ (void)bootstrapForPatchType:(PatchType)patchType;

// Returns the ChuckPadSocial singleton instance.
+ (ChuckPadSocial *)sharedInstance;

// --- Environment ---

// Returns the root URL of the environment API calls will be made against.
- (NSString *)getBaseUrl;

// Sets environment. Environment can be Production, Stage, or Local. Note that credentials are stored per environment
// so if you log into Stage as User A, then switch to Production and log in as User B, and then switch back to Stage
// you will remain logged in as User A. If this behavior is not desired, call logOut before switching environment.
- (void)setEnvironment:(Environment)environment;

// Rotates through the environments as they are declared in the Environment enum. If called while enviroment is
// Production the environment switches to Stage. If called on Local, the environment switches to Production.
- (void)toggleEnvironment;

// --- User API ---

// Registers a new user with the provided parameters. If the callback is called with succeeded = true, the user is
// considered logged in for subsequent API requests so no login call is needed.
- (void)createUser:(NSString *)username email:(NSString *)email password:(NSString *)password
          callback:(CreateUserCallback)callback;

// Logs a user in. The usernameOrEmail parameter can be the email OR username. The API will use the parameter to match
// against usernames and emails.
- (void)logIn:(NSString *)usernameOrEmail password:(NSString *)password callback:(CreateUserCallback)callback;

// De-authenticates a user from the service (i.e. invalidates their auth token) and clears their login information
// stored on the device.
- (void)logOut:(LogOutCallback)callback;

// Similiar to the above method but only clears local credentials and does not invalidate the auth token on the
// service. The logOut method above is the preferred method of logging out.
- (void)localLogOut;

// Triggers an email to be sent to the account linked to the given username/password which includes a web link that
// allows the user to reset their password.
- (void)forgotPassword:(NSString *)usernameOrEmail callback:(ForgotPasswordCallback)callback;

// Returns the user id (non-changing, permanent integer identifier) for the currently logged in user.
- (NSInteger)getLoggedInUserId;

// Returns the username of the currently logged in user.
- (NSString *)getLoggedInUserName;

// Returns the email address of the currently logged in user.
- (NSString *)getLoggedInEmail;

// Changes the currently logged in user's password.
- (void)changePassword:(NSString *)newPassword callback:(CreateUserCallback)callback;

// Returns YES if there is a user currently logged in.
- (BOOL)isLoggedIn;

// --- Get Patches API ---

// Gets patch metadata for the given patch id.
- (void)getPatchInfo:(NSInteger)patchId callback:(GetPatchInfoCallback)callback;

// Returns all patches for the currently logged in user.
- (void)getMyPatches:(GetPatchesCallback)callback;

// Returns all patches for the specified user with given id.
- (void)getPatchesForUserId:(NSInteger)userId callback:(GetPatchesCallback)callback;

// Returns all patches flagged as documentation.
- (void)getDocumentationPatches:(GetPatchesCallback)callback;

// Returns all patches flagged as featured.
- (void)getFeaturedPatches:(GetPatchesCallback)callback;

// Returns recently created patches.
- (void)getRecentPatches:(GetPatchesCallback)callback;

// Downloads patch resource (i.e. the actual content of the file associated with the patch)
- (void)downloadPatchResource:(Patch *)patch callback:(DownloadPatchResourceCallback)callback;

// --- Create/Modify Patches API ---

// Update method for a patch that allows updating hidden state, patch name, description filename, and patch data. One or,
// all of these can be set. If updating file data, both name and data parameters should be provided.
//
// Why is the hidden param a NSNumber instead of BOOL? Because Objective-C annoyingly enough does not have a Boolean
// class that allows a boolean to nil. So pass nil to skip changing visibility, 0 to set not hidden, and 1 to set
// hidden.
- (void)updatePatch:(Patch *)patch hidden:(NSNumber *)isHidden name:(NSString *)name description:(NSString *)description
           filename:(NSString *)filename fileData:(NSData *)fileData callback:(UpdatePatchCallback)callback;

// Creates a new patch.
- (void)uploadPatch:(NSString *)patchName description:(NSString *)description parent:(NSInteger)parentId
           filename:(NSString *)filename fileData:(NSData *)fileData callback:(CreatePatchCallback)callback;

// Deletes the given patch.
- (void)deletePatch:(Patch *)patch callback:(DeletePatchCallback)callback;

// --- Patch Abuse API ---

- (void)reportAbuse:(Patch *)patch isAbuse:(BOOL)isAbuse callback:(ReportAbuseCallback)callback;

@end

#endif /* ChuckPadSocial_h */
