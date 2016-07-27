//
//  ChuckPadSocial.h
//  chuckpad-social-ios
//  https://github.com/markcerqueira/chuckpad-social-ios
// 

#ifndef ChuckPadSocial_h
#define ChuckPadSocial_h

#import <objc/NSObject.h>

@class Patch;

typedef void(^GetPatchesCallback)(NSArray *patchesArray, NSError *error);

typedef void(^CreateUserCallback)(BOOL succeeded, NSError *error);

typedef void(^CreatePatchCallback)(BOOL succeeded, Patch *patch, NSError *error);

typedef void(^UpdatePatchCallback)(BOOL succeeded, Patch *patch, NSError *error);

typedef void(^DownloadPatchResourceCallback)(NSData *patchData, NSError *error);

@interface ChuckPadSocial : NSObject

// Returns the ChuckPadSocial singleton instance.
+ (ChuckPadSocial *)sharedInstance;

// --- Environment ---

// Returns the root URL of the environment API calls will be made against.
- (NSString *)getBaseUrl;

// Toggles between the production environment and local debugging environment.
- (void)toggleEnvironment;

// Sets the environment to use the local debugging environment running on localhost:9292.
- (void)setEnvironmentToDebug;

// --- User API ---

// Registers a new user with the provided parameters. If the callback is called with succeeded = true, the user is
// considered logged in for subsequent API requests so no login call is needed.
- (void)createUser:(NSString *)username email:(NSString *)email password:(NSString *)password
          callback:(CreateUserCallback)callback;

// Logs a user in. The usernameOrEmail parameter can be the email OR username. The API will use the parameter to match
// against usernames and emails.
- (void)logIn:(NSString *)usernameOrEmail password:(NSString *)password callback:(CreateUserCallback)callback;

// De-authenticates a user from the ChuckPad service and clears their login information stored on the device.
- (void)logOut;

// Returns the username of the currently logged in user. Note this may be an email if the user chose to log in with
// an email address.
- (NSString *)getLoggedInUserName;

// Changes the currently logged in user's password.
- (void)changePassword:(NSString *)newPassword callback:(CreateUserCallback)callback;

// Returns YES if there is a user currently logged in.
- (BOOL)isLoggedIn;

// --- Get Patches API ---

// Returns all patches for the currently logged in user.
- (void)getMyPatches:(GetPatchesCallback)callback;

// Returns all patches for the specified user with given id.
- (void)getPatchesForUserId:(NSInteger)userId callback:(GetPatchesCallback)callback;

// Returns all patches flagged as documentation.
- (void)getDocumentationPatches:(GetPatchesCallback)callback;

// Returns all patches flagged as featured.
- (void)getFeaturedPatches:(GetPatchesCallback)callback;

// Returns all patches. Once the number of patches reaches a certain threshold this function may only return a (large)
// subset of all patches.
- (void)getAllPatches:(GetPatchesCallback)callback;

// Downloads patch resource (i.e. the actual content of the file associated with the patch)
- (void)downloadPatchResource:(Patch *)patch callback:(DownloadPatchResourceCallback)callback;

// --- Create/Modify Patches API ---

// Update method for a patch that allows updating hidden state, patch name, filename, and patch data. One or all of
// these can be set. If updating file data, both name and data parameters should be provided.
//
// Why is the hidden param a NSNumber instead of BOOL? Because Objective-C annoyingly enough does not have a Boolean
// class that allows a boolean to nil. So pass nil to skip changing visibility, 0 to set not hidden, and 1 to set
// hidden.
- (void)updatePatch:(Patch *)patch hidden:(NSNumber *)isHidden patchName:(NSString *)patchName
           filename:(NSString *)filename fileData:(NSData *)fileData callback:(UpdatePatchCallback)callback;

// Creates a new patch.
- (void)uploadPatch:(NSString *)patchName filename:(NSString *)filename fileData:(NSData *)fileData
           callback:(CreatePatchCallback)callback;

@end

#endif /* ChuckPadSocial_h */
