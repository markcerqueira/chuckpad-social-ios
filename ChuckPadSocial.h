//
//  ChuckPadSocial.h
//  chuckpad-social-ios
//  https://github.com/markcerqueira/chuckpad-social-ios
// 

#ifndef ChuckPadSocial_h
#define ChuckPadSocial_h

#import <Foundation/Foundation.h>
#import <PubNub/PubNub.h>
 
#import "ChuckPadKeychain.h"
#import "Patch.h"
#import "PatchCache.h"
#import "PatchResource.h"
#import "User.h"

#import "NSDate+Helper.h"

// If the service returns 0 patches because 0 patches match the conditions (e.g. you request a user's patches but the
// user has 0), the callback will return an NSArry of size 0 and a nil error.
typedef void(^GetPatchesCallback)(NSArray *patchesArray, NSError *error);

typedef void(^CreateUserCallback)(BOOL succeeded, NSError *error);

typedef void(^CreatePatchCallback)(BOOL succeeded, Patch *patch, NSError *error);

typedef void(^UpdatePatchCallback)(BOOL succeeded, Patch *patch, NSError *error);

typedef void(^GetPatchInfoCallback)(BOOL succeeded, Patch *patch, NSError *error);

typedef void(^DeletePatchCallback)(BOOL succeeded, NSError *error);

typedef void(^DownloadResourceCallback)(NSData *resourceData, NSError *error);

typedef void(^ReportAbuseCallback)(BOOL succeeded, NSError *error);

typedef void(^LogOutCallback)(BOOL succeeded, NSError *error);

typedef void(^ForgotPasswordCallback)(BOOL succeeded, NSError *error);

// An NSArray of PatchResource objects is returned in this callback with more recent versions (i.e. higher version
// numbers) are at the front (e.g. the most recent version is index 0, second most recent is index 1, etc).
typedef void(^GetPatchVersionsCallback)(BOOL succeeded, NSArray *versions, NSError *error);

// Notification Constants

// Posted when successful login (regular login and automatic login following registration) of a user is complete.
extern NSString *const CHUCKPAD_SOCIAL_LOG_IN;

// Sent when a user is logged out. This can be voluntary (user chose to log out) or involuntary (the user's auth token
// was revoked).
extern NSString *const CHUCKPAD_SOCIAL_LOG_OUT;

// NSUserDefaults Keys
extern NSString *const ENVIRONMENT_KEY;

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

// Returns YES if ChuckPadSocial is currently pointing to the Local value of the Environment enum.
- (BOOL)isLocalEnvironment;

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

// Triggers an email to be sent to the account linked to the given username/email which includes a web link that
// allows the user to reset their password.
- (void)forgotPassword:(NSString *)usernameOrEmail callback:(ForgotPasswordCallback)callback;

// Returns the user id (non-changing, permanent identifier) for the currently logged in user.
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

// Gets patch metadata for the given patch GUID.
- (void)getPatchInfo:(NSString *)patchGUID callback:(GetPatchInfoCallback)callback;

// Returns all patches for the currently logged in user.
- (void)getMyPatches:(GetPatchesCallback)callback;

// Returns all patches for the specified user with given user id.
- (void)getPatchesForUserId:(NSInteger)userId callback:(GetPatchesCallback)callback;

// Returns all patches flagged as documentation.
- (void)getDocumentationPatches:(GetPatchesCallback)callback;

// Returns all patches flagged as featured.
- (void)getFeaturedPatches:(GetPatchesCallback)callback;

// Returns recently created patches.
- (void)getRecentPatches:(GetPatchesCallback)callback;

// Downloads patch resource (i.e. the actual content of the file associated with the patch).
- (void)downloadPatchResource:(Patch *)patch callback:(DownloadResourceCallback)callback;

// Downloads the extra meta-data associated with the patch.
- (void)downloadPatchExtraData:(Patch *)patch callback:(DownloadResourceCallback)callback;

// --- World Patches API ---

// Returns a variety of patches from around the world (based on their latitutde/longitude when uploaded).
- (void)getWorldPatches:(GetPatchesCallback)callback;

// --- Create/Modify Patches API ---

// Creates a new patch.
- (void)uploadPatch:(NSString *)patchName description:(NSString *)description parent:(NSString *)parentGUID
          patchData:(NSData *)patchData extraMetaData:(NSData *)extraData callback:(CreatePatchCallback)callback;

// Creates a new patch (allows setting a location via latitude/longitude).
- (void)uploadPatch:(NSString *)patchName description:(NSString *)description latitude:(NSNumber *)lat longitude:(NSNumber *)lng
          patchData:(NSData *)patchData extraMetaData:(NSData *)extraData callback:(CreatePatchCallback)callback;

// Creates a new patch (allows setting hidden flag).
- (void)uploadPatch:(NSString *)patchName description:(NSString *)description parent:(NSString *)parentGUID hidden:(NSNumber *)isHidden
          patchData:(NSData *)patchData extraMetaData:(NSData *)extraData callback:(CreatePatchCallback)callback;

// Update method for a patch that allows updating hidden state, patch name, description, data, and/or meta-data. If a
// parameter is left nil, it will be ignored and no changes will be made to that particular field.
//
// Why is the hidden param a NSNumber instead of BOOL? Because Objective-C annoyingly enough does not have a Boolean
// class that allows a boolean to nil. So pass nil to skip changing visibility, @(0) to set not hidden, and @(1) to set
// hidden.
- (void)updatePatch:(Patch *)patch hidden:(NSNumber *)isHidden name:(NSString *)name description:(NSString *)description
          patchData:(NSData *)patchData extraMetaData:(NSData *)extraData callback:(UpdatePatchCallback)callback;

// Update method that allows changing the location. Setting the latitude or longitude to nil clears it from a patch.
- (void)updatePatch:(Patch *)patch latitude:(NSNumber *)lat longitude:(NSNumber *)lng callback:(UpdatePatchCallback)callback;

// Deletes the given patch.
- (void)deletePatch:(Patch *)patch callback:(DeletePatchCallback)callback;

// --- Patch Abuse API ---

- (void)reportAbuse:(Patch *)patch isAbuse:(BOOL)isAbuse callback:(ReportAbuseCallback)callback;

// --- Versioning API ---

// Gets a list of all versions for the given patch. See the type definition for GetPatchVersionsCallback above to
// learn about how resource version data is returned in the callback.
- (void)getPatchVersions:(Patch *)patch callback:(GetPatchVersionsCallback)callback;

// Downloads patch data from the revision specified in the version parameter. The version parameter should normally be
// pulled directly from the PatchResource objects returned in the GetPatchVersionsCallback when calling the
// getPatchVersions method.
- (void)downloadPatchVersion:(Patch *)patch version:(NSInteger)version callback:(DownloadResourceCallback)callback;

@end

#endif /* ChuckPadSocial_h */
