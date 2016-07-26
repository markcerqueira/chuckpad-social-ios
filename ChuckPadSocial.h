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

typedef void(^CreatePatchCallback)(BOOL succeeded, Patch *patch);

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
- (void)createUser:(NSString *)username withEmail:(NSString *)email withPassword:(NSString *)password
      withCallback:(CreateUserCallback)callback;

// Logs a user in. The usernameOrEmail parameter can be the email OR username. The API will use the parameter to match
// against usernames and emails.
- (void)logIn:(NSString *)usernameOrEmail withPassword:(NSString *)password withCallback:(CreateUserCallback)callback;

// De-authenticates a user from the ChuckPad service and clears their login information stored on the device.
- (void)logOut;

// Returns the username of the currently logged in user. Note this may be an email if the user chose to log in with
// an email address.
- (NSString *)getLoggedInUserName;

// Changes the currently logged in user's password.
- (void)changePassword:(NSString *)newPassword withCallback:(CreateUserCallback)callback;

// Returns YES if there is a user currently logged in.
- (BOOL)isLoggedIn;

// --- Patches API ---

// Returns all patches for the currently logged in user.
- (void)getMyPatches:(GetPatchesCallback)callback;

// Returns all patches for the specified user with given id.
- (void)getPatchesForUserId:(NSInteger)userId withCallback:(GetPatchesCallback)callback;

// Returns all patches flagged as documentation.
- (void)getDocumentationPatches:(GetPatchesCallback)callback;

// Returns all patches flagged as featured.
- (void)getFeaturedPatches:(GetPatchesCallback)callback;

// Returns all patches. Once the number of patches reaches a certain threshold this function may only return a (large)
// subset of all patches.
- (void)getAllPatches:(GetPatchesCallback)callback;

// Uploads a patch. Defaults featured, documentation flags to false.
- (void)uploadPatch:(NSString *)patchName filename:(NSString *)filename fileData:(NSData *)fileData
           callback:(CreatePatchCallback)callback;

// Uploads a patch and whether the patch is featured or documentation can be explicitly specified.
- (void)uploadPatch:(NSString *)patchName isFeatured:(BOOL)isFeatured isDocumentation:(BOOL)isDocumentation
           filename:(NSString *)filename fileData:(NSData *)fileData callback:(CreatePatchCallback)callback;

@end

#endif /* ChuckPadSocial_h */
