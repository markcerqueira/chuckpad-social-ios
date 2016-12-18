//
//  ChuckPadSocial.m
//  chuckpad-social-ios
//  https://github.com/markcerqueira/chuckpad-social-ios
//

//  For network calls there are normally two completion blocks for the actual network request but each network request
//  ultimately falls into one of three categories:
//      1 - Success block and response code from service is 200 -> Network call succeeded and service succeeded at handling request.
//      2 - Success block and non-200 response code from service -> Network call succeeded, but the service failed to handle request.
//      3 - Failure block - The network call failed. The service may or may not have been reached properly.

#import "ChuckPadSocial.h"

#import "AFHTTPSessionManager.h"

#include <CommonCrypto/CommonDigest.h>

static PatchType sPatchType = Unconfigured;

@implementation ChuckPadSocial {
    @private AFHTTPSessionManager *httpSessionManager;
    @private NSString *baseUrl;
    @private NSArray *environmentUrls;
}

// Version of this client-side SDK. This won't be updated unless there is a client-breaking change in the API.
NSInteger IOS_SDK_VERSION = 1;

// API Response Code constants
NSInteger SUCCESS_CODE = 200;
NSInteger ERROR_CODE = 500;
NSInteger AUTH_ERROR = 400;

// API URLs
NSString *const CREATE_USER_URL = @"/user/create";
NSString *const LOGIN_USER_URL = @"/user/login";
NSString *const LOG_OUT_URL = @"/user/logout";

NSString *const CHANGE_PASSWORD_URL = @"/user/password/change";
NSString *const FORGOT_PASSWORD_URL = @"/user/password/reset";

NSString *const GET_DOCUMENTATION_URL = @"/patch/documentation";
NSString *const GET_FEATURED_URL = @"/patch/featured";
NSString *const GET_RECENT_URL = @"/patch/new";
NSString *const GET_MY_PATCHES_URL = @"/patch/my";
NSString *const GET_PATCHES_FOR_USER_URL = @"/patch/user";
NSString *const GET_SINGLE_PATCH_INFO = @"/patch/info";

NSString *const CREATE_PATCH_URL = @"/patch/create/";
NSString *const UPDATE_PATCH_URL = @"/patch/update/";
NSString *const DELETE_PATCH_URL = @"/patch/delete/";
NSString *const REPORT_PATCH_URL = @"/patch/report/";

// iOS User Agent Identifier
NSString *const CHUCKPAD_SOCIAL_IOS_USER_AGENT = @"chuckpad-social-ios";

// User-facing error strings
NSString *const ERROR_STRING_LOGGED_IN_ALREADY = @"Someone is already logged in. Please log out and try again.";
NSString *const ERROR_STRING_NO_USER_LOGGED_IN = @"No user is currently logged in. Please log in and try again.";
NSString *const ERROR_STRING_ERROR_FETCHING_PATCHES = @"There was an error fetching the scripts. Please try again later.";
NSString *const ERROR_STRING_ERROR_DOWNLOADING_PATCH_RESOURCE = @"There was an error downloading the resource. Please try again later.";
NSString *const ERROR_STRING_LOGGING_OUT = @"There was an error logging out. Please try again later.";
NSString *const ERROR_STRING_NO_EXTRA_RESOURCE = @"This patch does not have any extra data associated with it.";

// NSNotification constants
NSString *const CHUCKPAD_SOCIAL_LOG_IN = @"CHUCKPAD_SOCIAL_LOG_IN";
NSString *const CHUCKPAD_SOCIAL_LOG_OUT = @"CHUCKPAD_SOCIAL_LOG_OUT";

// NSUserDefaults Keys
NSString *const ENVIRONMENT_KEY = @"ENVIRONMENT_KEY";

// API Param Keys
NSString *const PARAMS_USERNAME = @"username";
NSString *const PARAMS_EMAIL = @"email";
NSString *const PARAMS_PASSWORD = @"password";
NSString *const PARAMS_USERNAME_OR_EMAIL = @"username_or_email";
NSString *const PARAMS_NEW_PASSWORD = @"new_password";

NSString *const PATCH_GUID_PARAM_NAME = @"guid";
NSString *const PATCH_DATA_PARAM_NAME = @"patch_data";
NSString *const PATCH_EXTRA_DATA_PARAM_NAME = @"patch_extra_data";
NSString *const PATCH_TYPE_PARAM_NAME = @"patch_type";
NSString *const PATCH_NAME_PARAM_NAME = @"patch_name";
NSString *const PATCH_DESCRIPTION_PARAM_NAME = @"patch_description";
NSString *const PATCH_PARENT_GUID_PARAM_NAME = @"patch_parent_guid";
NSString *const PATCH_IS_HIDDEN_PARAM_NAME = @"patch_hidden";

NSString *const IS_ABUSE_PARAM_NAME = @"is_abuse";

NSString *const USER_ID_PARAM_KEY = @"user_id";
NSString *const AUTH_TOKEN_PARAM_KEY = @"auth_token";
NSString *const EMAIL_PARAM_KEY = @"email";
NSString *const TYPE_PARAM_KEY = @"type";

NSString *const PARAM_KEY_DIGEST = @"digest";
NSString *const PARAM_KEY_RANDOM = @"random";
NSString *const PARAM_VERSION = @"version";

NSString *const FILE_DATA_MIME_TYPE = @"application/octet-stream";

+ (void)bootstrapForPatchType:(PatchType)patchType {
    if ((sPatchType != Unconfigured && sPatchType != patchType) || patchType == Unconfigured) {
        [NSException raise:@"ChuckPadSocial already bootstrapped"
                    format:@"bootstrapForPatchType should only be called once and its value cannot be changed once set"];
    }
    
    sPatchType = patchType;
}

// DO NOT call this method! This method should ONLY be called from unit tests.
+ (void)resetSharedInstanceAndBoostrap {
    sPatchType = Unconfigured;
    sharedInstance = nil;
    onceToken = 0;
}

static ChuckPadSocial *sharedInstance = nil;
static dispatch_once_t onceToken;

+ (ChuckPadSocial *)sharedInstance {
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ChuckPadSocial alloc] init];
        [sharedInstance initializeNetworkManager];
    });
    return sharedInstance;
}

- (void)initializeNetworkManager {
    httpSessionManager = [AFHTTPSessionManager manager];
    
    // So the service can uniquely identify iOS calls
    NSString *userAgent = [httpSessionManager.requestSerializer  valueForHTTPHeaderField:@"User-Agent"];
    userAgent = [userAgent stringByAppendingPathComponent:CHUCKPAD_SOCIAL_IOS_USER_AGENT];
    [httpSessionManager.requestSerializer setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    
    environmentUrls = [[NSArray alloc] initWithObjects:EnvironmentHostUrls];
    baseUrl = environmentUrls[[[NSUserDefaults standardUserDefaults] integerForKey:ENVIRONMENT_KEY]];
}

- (NSString *)getBaseUrl {
    return baseUrl;
}

- (void)setEnvironment:(Environment)environment {
    baseUrl = environmentUrls[environment];
    [[NSUserDefaults standardUserDefaults] setInteger:environment forKey:ENVIRONMENT_KEY];
}

- (void)toggleEnvironment {
    NSInteger currentEnviroment = [[NSUserDefaults standardUserDefaults] integerForKey:ENVIRONMENT_KEY];
    currentEnviroment++;
    
    if (currentEnviroment > 2) {
        currentEnviroment = 0;
    }

    [self setEnvironment:(Environment) currentEnviroment];
}

- (BOOL)isLocalEnvironment {
    return [[NSUserDefaults standardUserDefaults] integerForKey:ENVIRONMENT_KEY] == Local;
}

// User API

- (void)createUser:(NSString *)username email:(NSString *)email password:(NSString *)password callback:(CreateUserCallback)callback {
    // If a user is already logged in, do not allow creating another user
    if ([self isLoggedIn]) {
        NSLog(@"createUser - a user is already logged in");
        callback(false, [self errorWithErrorString:ERROR_STRING_LOGGED_IN_ALREADY]);
        return;
    }
    
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", baseUrl, CREATE_USER_URL]];
    
    NSLog(@"createUser - url = %@", url.absoluteString);
    
    NSMutableDictionary *requestParams = [[NSMutableDictionary alloc] init];
    requestParams[PARAMS_USERNAME] = username;
    requestParams[PARAMS_EMAIL] = email;
    requestParams[PARAMS_PASSWORD] = password;

    [self POST:url.absoluteString parameters:requestParams progress:nil
       success:^(NSURLSessionDataTask *task, id responseObject) {
           NSLog(@"createUser - response: %@", responseObject);
           [self processAuthResponse:responseObject callback:callback];
       }
       failure:^(NSURLSessionDataTask *task, NSError *error) {
           NSLog(@"createUser - error: %@", [error localizedDescription]);
           callback(false, [self errorMakingNetworkCall:error]);
       }];
}

- (void)logIn:(NSString *)usernameOrEmail password:(NSString *)password callback:(CreateUserCallback)callback {
    // If a user is already logged in, do not allow logging in as another user
    if ([self isLoggedIn]) {
        NSLog(@"logIn - a user is already logged in");
        callback(false, [self errorWithErrorString:ERROR_STRING_LOGGED_IN_ALREADY]);
        return;
    }
    
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", baseUrl, LOGIN_USER_URL]];
    
    NSLog(@"logIn - url = %@", url.absoluteString);
    
    NSMutableDictionary *requestParams = [[NSMutableDictionary alloc] init];
    
    // We don't know if the user entered a username or email so we'll send it up to the server as "both" and if we
    // succeed in logging in, the server will let us know what the email and user name is.
    requestParams[PARAMS_USERNAME_OR_EMAIL] = usernameOrEmail;
    
    requestParams[PARAMS_PASSWORD] = password;

    [self POST:url.absoluteString parameters:requestParams progress:nil
       success:^(NSURLSessionDataTask *task, id responseObject) {
           NSLog(@"logIn - response: %@", responseObject);
           [self processAuthResponse:responseObject callback:callback];
       }
       failure:^(NSURLSessionDataTask *task, NSError *error) {
           NSLog(@"logIn - error: %@", [error localizedDescription]);
           callback(false, [self errorMakingNetworkCall:error]);
       }];
}

- (void)logOut:(LogOutCallback)callback {
    // If not logged in, log an error and abort early
    if (![self isLoggedIn]) {
        NSLog(@"logOut - no user is currently logged in; aborting");
        callback(false, [self errorWithErrorString:ERROR_STRING_NO_USER_LOGGED_IN]);
        return;
    }
    
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", baseUrl, LOG_OUT_URL]];

    NSLog(@"logOut - url = %@", url.absoluteString);
    
    NSMutableDictionary *requestParams = [self getCurrentUserAuthParamsDictionary];
    
    [self POST:url.absoluteString parameters:requestParams progress:nil
       success:^(NSURLSessionTask *task, id responseObject) {
           if ([self responseOk:responseObject]) {
               [self localLogOut];
               callback(true, nil);
           } else {
               callback(false, [self errorWithErrorString:ERROR_STRING_LOGGING_OUT]);
           }
       }
       failure:^(NSURLSessionTask *operation, NSError *error) {
           NSLog(@"logOut - error: %@", [error localizedDescription]);
           callback(false, [self errorMakingNetworkCall:error]);
       }];
}

- (void)localLogOut {
    // Clear the credentials from the keychain
    [[ChuckPadKeychain sharedInstance] clearCredentials];
    
    // Post notification so UI can update itself
    [[NSNotificationCenter defaultCenter] postNotificationName:CHUCKPAD_SOCIAL_LOG_OUT object:nil userInfo:nil];
    
    // Flush the cache on user change events
    [[PatchCache sharedInstance] removeAllObjects];
}

- (void)forgotPassword:(NSString *)usernameOrEmail callback:(ForgotPasswordCallback)callback {
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", baseUrl, FORGOT_PASSWORD_URL]];

    NSLog(@"forgotPassword - url = %@", url.absoluteString);

    NSMutableDictionary *requestParams = [[NSMutableDictionary alloc] init];
    requestParams[PARAMS_USERNAME_OR_EMAIL] = usernameOrEmail;

    [self POST:url.absoluteString parameters:requestParams progress:nil
       success:^(NSURLSessionDataTask *task, id responseObject) {
           NSLog(@"forgotPassword - success: %@", responseObject);
           if ([self responseOk:responseObject]) {
               callback(true, nil);
           } else {
               callback(false, [self errorWithErrorString:[self getErrorMessageFromServiceReply:responseObject]]);
           }
       }
       failure:^(NSURLSessionDataTask *task, NSError *error) {
           NSLog(@"forgotPassword - error: %@", [error localizedDescription]);
           callback(false, [self errorMakingNetworkCall:error]);
       }];
}

- (void)changePassword:(NSString *)newPassword callback:(CreateUserCallback)callback {
    // If not logged in, log an error and abort
    if (![self isLoggedIn]) {
        callback(false, [self errorBecauseNotLoggedIn]);
        return;
    }

    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", baseUrl, CHANGE_PASSWORD_URL]];
    
    NSLog(@"changedPassword - url = %@", url.absoluteString);
    
    NSMutableDictionary *requestParams = [self getCurrentUserAuthParamsDictionary];
    requestParams[PARAMS_NEW_PASSWORD] = newPassword;
    
    [self POST:url.absoluteString parameters:requestParams progress:nil
       success:^(NSURLSessionDataTask *task, id responseObject) {
           NSLog(@"changedPassword - success: %@", responseObject);
           if ([self responseOk:responseObject]) {
               // No need to do anything besides notifying caller because our auth token is still valid.
               callback(true, nil);
           } else {
               callback(false, [self errorWithErrorString:[self getErrorMessageFromServiceReply:responseObject]]);
           }
       }
       failure:^(NSURLSessionDataTask *task, NSError *error) {
           NSLog(@"changedPassword - error: %@", [error localizedDescription]);
           callback(false, [self errorMakingNetworkCall:error]);
       }];
}

- (void)authSucceededWithUser:(User *)user {
    [[ChuckPadKeychain sharedInstance] authSucceededWithUser:user];

    // Post notification so UI can update itself
    [[NSNotificationCenter defaultCenter] postNotificationName:CHUCKPAD_SOCIAL_LOG_IN object:nil userInfo:nil];

    // Flush the cache on user change events
    [[PatchCache sharedInstance] removeAllObjects];
}

- (NSString *)getLoggedInUserName {
    return [[ChuckPadKeychain sharedInstance] getLoggedInUserName];
}

- (NSString *)getLoggedInEmail {
    return [[ChuckPadKeychain sharedInstance] getLoggedInEmail];
}

- (NSInteger)getLoggedInUserId {
    return [[ChuckPadKeychain sharedInstance] getLoggedInUserId];
}

- (NSString *)getLoggedInAuthToken {
    return [[ChuckPadKeychain sharedInstance] getLoggedInAuthToken];
}

- (BOOL)isLoggedIn {
    return [[ChuckPadKeychain sharedInstance] isLoggedIn];
}

// Patches API

- (void)getMyPatches:(GetPatchesCallback)callback {
    // If the user is not logged in, fail now
    if (![self isLoggedIn]) {
        NSLog(@"getMyPatches - no user is currently logged in");
        callback(false, [self errorBecauseNotLoggedIn]);
        return;
    }

    [self getPatchesInternal:GET_MY_PATCHES_URL withCallback:callback];
}

- (void)getPatchesForUserId:(NSInteger)userId callback:(GetPatchesCallback)callback {
    [self getPatchesInternal:[NSString stringWithFormat:@"%@/%ld", GET_PATCHES_FOR_USER_URL, (long)userId] withCallback:callback];
}

- (void)getDocumentationPatches:(GetPatchesCallback)callback {
    [self getPatchesInternal:GET_DOCUMENTATION_URL withCallback:callback];
}

- (void)getFeaturedPatches:(GetPatchesCallback)callback {
    [self getPatchesInternal:GET_FEATURED_URL withCallback:callback];
}

- (void)getRecentPatches:(GetPatchesCallback)callback {
    [self getPatchesInternal:GET_RECENT_URL withCallback:callback];
}

- (void)getPatchesInternal:(NSString *)urlPath withCallback:(GetPatchesCallback)callback {
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", baseUrl, urlPath]];

    NSLog(@"getPatchesInternal - url = %@", url.absoluteString);

    NSArray *patchesArrayFromCache = [[PatchCache sharedInstance] objectForKey:urlPath];
    if (patchesArrayFromCache != nil && [patchesArrayFromCache count] > 0) {
        NSLog(@"getPatchesInternal - using cached patches array");
        callback(patchesArrayFromCache, nil);
        return;
    }

    // Add currentUser params because if a user has hidden patches in any category we want to return them to the user.
    NSMutableDictionary *requestParams = [self getCurrentUserAuthParamsDictionary];

    [self GET:url.absoluteString parameters:requestParams progress:nil
      success:^(NSURLSessionTask *task, id responseObject) {
          if ([self responseOk:responseObject]) {
              NSMutableArray *patchesArray = [[NSMutableArray alloc] init];
              for (id object in [self getPatchListFromMessageResponse:responseObject]) {
                  Patch *patch = [[Patch alloc] initWithDictionary:object];
                  [patchesArray addObject:patch];
              }
              
              NSLog(@"@getPatchesInternal - fetched %lu patches", (unsigned long)[patchesArray count]);
              
              // Save response to our cache in case we hit this API again soon
              [[PatchCache sharedInstance] setObject:patchesArray forKey:urlPath];
              
              callback(patchesArray, nil);
          } else {
              callback(nil, [self errorWithErrorString:ERROR_STRING_ERROR_FETCHING_PATCHES]);
          }
      }
      failure:^(NSURLSessionTask *operation, NSError *error) {
          NSLog(@"getPatchesInternal - error: %@", [error localizedDescription]);
          callback(nil, [self errorMakingNetworkCall:error]);
      }];
}

- (void)getPatchInfo:(NSString *)patchGUID callback:(GetPatchInfoCallback)callback {
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@/%@", baseUrl, GET_SINGLE_PATCH_INFO, patchGUID]];
    
    NSLog(@"getPatchInfo - url = %@", url.absoluteString);

    // Do not use cache here because we want to ensure we always return fresh metadata.
    
    [self GET:url.absoluteString parameters:nil progress:nil
      success:^(NSURLSessionTask *task, id responseObject) {
          if ([self responseOk:responseObject]) {
              Patch *patch = [self getPatchFromMessageResponse:responseObject];
              callback(YES, patch, nil);
          } else {
              callback(NO, nil, [self errorWithErrorString:ERROR_STRING_ERROR_FETCHING_PATCHES]);
          }
      }
      failure:^(NSURLSessionTask *operation, NSError *error) {
          NSLog(@"getPatchInfo - error: %@", [error localizedDescription]);
          callback(NO, nil, [self errorMakingNetworkCall:error]);
      }];
}

- (void)downloadPatchResource:(Patch *)patch callback:(DownloadResourceCallback)callback {
    NSString *url = [NSString stringWithFormat:@"%@%@", [[ChuckPadSocial sharedInstance] getBaseUrl], patch.resourceUrl];
    [self getData:url callback:callback];
}

- (void)downloadPatchExtraData:(Patch *)patch callback:(DownloadResourceCallback)callback {
    if (![patch hasExtraResource]) {
        NSLog(@"downloadPatchExtraData - this patch does not have an extra resource");
        callback(nil, [self errorWithErrorString:ERROR_STRING_NO_EXTRA_RESOURCE]);
        return;
    }
    
    NSString *url = [NSString stringWithFormat:@"%@%@", [[ChuckPadSocial sharedInstance] getBaseUrl], patch.extraResourceUrl];
    [self getData:url callback:callback];
}

- (void)getData:(NSString *)url callback:(DownloadResourceCallback)callback {
    NSLog(@"getData - url = %@", url);

    NSData *patchDataFromCache = [[PatchCache sharedInstance] objectForKey:url];
    if (patchDataFromCache != nil) {
        NSLog(@"getData - using cached data");
        callback(patchDataFromCache, nil);
        return;
    }
    
    // TODO Use AFNetworking if I can figure out how to make it work easily
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        int statusCode = -1;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            statusCode = (int)[(NSHTTPURLResponse *) response statusCode];
        }

        if (error == nil && data != nil && (statusCode == 200 || statusCode == -1)) {
            [[PatchCache sharedInstance] setObject:data forKey:url];
            callback(data, nil);
        } else {
            callback(nil, [self errorWithErrorString:ERROR_STRING_ERROR_DOWNLOADING_PATCH_RESOURCE]);
        }
    }] resume];
}

- (void)updatePatch:(Patch *)patch hidden:(NSNumber *)isHidden name:(NSString *)name description:(NSString *)description
          patchData:(NSData *)patchData extraMetaData:(NSData *)extraData callback:(UpdatePatchCallback)callback {
    // If the user is not logged in, fail now because not being logged in means you cannot update a patch
    if (![self isLoggedIn]) {
        NSLog(@"updatePatch - no user is currently logged in");
        callback(false, nil, [self errorBecauseNotLoggedIn]);
        return;
    }
    
    // Flush cache for getting my patches
    [[PatchCache sharedInstance] removeObjectForKey:GET_MY_PATCHES_URL];

    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", baseUrl, UPDATE_PATCH_URL]];

    NSMutableDictionary *requestParams = [self getCurrentUserAuthParamsDictionary];

    requestParams[PATCH_GUID_PARAM_NAME] = [NSString stringWithFormat:@"%@", patch.guid];
    
    [self appendIfNotNilToRequestParams:requestParams key:PATCH_NAME_PARAM_NAME value:name];
    [self appendIfNotNilToRequestParams:requestParams key:PATCH_DESCRIPTION_PARAM_NAME value:description];
    [self appendIfNotNilToRequestParams:requestParams key:PATCH_IS_HIDDEN_PARAM_NAME value:isHidden];
    
    [self POST:url.absoluteString parameters:requestParams constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
        [self appendFormData:formData patchData:patchData extraData:extraData];
    } progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"updatePatch - success: %@", responseObject);
        if ([self responseOk:responseObject]) {
            callback(true, [self getPatchFromMessageResponse:responseObject], nil);
        } else {
            callback(false, nil, [self errorWithErrorString:[self getErrorMessageFromServiceReply:responseObject]]);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"updatePatch - error: %@", [error localizedDescription]);
        callback(false, nil, [self errorMakingNetworkCall:error]);
    }];
}

- (void)uploadPatch:(NSString *)patchName description:(NSString *)description parent:(NSString *)parentGUID
          patchData:(NSData *)patchData extraMetaData:(NSData *)extraData callback:(CreatePatchCallback)callback {
    [self uploadPatch:patchName description:description parent:parentGUID hidden:nil patchData:patchData extraMetaData:extraData callback:callback];
}

- (void)uploadPatch:(NSString *)patchName description:(NSString *)description parent:(NSString *)parentGUID hidden:(NSNumber *)isHidden
        patchData:(NSData *)patchData extraMetaData:(NSData *)extraData callback:(CreatePatchCallback)callback {
    // If the user is not logged in, fail now because not being logged in means you cannot update a patch
    if (![self isLoggedIn]) {
        NSLog(@"uploadPatch - no user is currently logged in");
        callback(false, nil, [self errorBecauseNotLoggedIn]);
        return;
    }

    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", baseUrl, CREATE_PATCH_URL]];

    NSLog(@"uploadPatch - url = %@", url.absoluteString);
    
    NSMutableDictionary *requestParams = [self getCurrentUserAuthParamsDictionary];

    [self appendIfNotNilToRequestParams:requestParams key:PATCH_NAME_PARAM_NAME value:patchName];
    [self appendIfNotNilToRequestParams:requestParams key:PATCH_DESCRIPTION_PARAM_NAME value:description];
    [self appendIfNotNilToRequestParams:requestParams key:PATCH_PARENT_GUID_PARAM_NAME value:parentGUID];
    [self appendIfNotNilToRequestParams:requestParams key:PATCH_IS_HIDDEN_PARAM_NAME value:isHidden];

    requestParams[PATCH_TYPE_PARAM_NAME] = @(sPatchType);
    
    // Flush cache for getting my patches
    [[PatchCache sharedInstance] removeObjectForKey:GET_MY_PATCHES_URL];

    [self POST:url.absoluteString parameters:requestParams constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
        [self appendFormData:formData patchData:patchData extraData:extraData];
    } progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"uploadPatch - success: %@", responseObject);
        if ([self responseOk:responseObject]) {
            callback(true, [self getPatchFromMessageResponse:responseObject], nil);
        } else {
            callback(false, nil, [self errorWithErrorString:[self getErrorMessageFromServiceReply:responseObject]]);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"uploadPatch - error: %@", [error localizedDescription]);
        callback(false, nil, [self errorMakingNetworkCall:error]);
    }];
}

- (void)deletePatch:(Patch *)patch callback:(DeletePatchCallback)callback {
    // If the user is not logged in, fail now because not being logged in means you cannot delete a patch
    if (![self isLoggedIn]) {
        NSLog(@"deletePatch - no user is currently logged in");
        callback(false, [self errorBecauseNotLoggedIn]);
        return;
    }
    
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@%@/", baseUrl, DELETE_PATCH_URL, patch.guid]];
    
    NSLog(@"deletePatch - url = %@", url.absoluteString);
 
    // Flush cache for getting my patches and the resource since we're about to delete one
    [[PatchCache sharedInstance] removeObjectForKey:GET_MY_PATCHES_URL];
    [[PatchCache sharedInstance] removeObjectForKey:[NSString stringWithFormat:@"%@%@", [[ChuckPadSocial sharedInstance] getBaseUrl], patch.resourceUrl]];
    
    [self GET:url.absoluteString parameters:[self getCurrentUserAuthParamsDictionary] progress:nil
      success:^(NSURLSessionTask *task, id responseObject) {
          NSLog(@"deletePatch - success: %@", responseObject);
          if ([self responseOk:responseObject]) {
              callback(YES, nil);
          } else {
              callback(NO, [self errorWithErrorString:[self getErrorMessageFromServiceReply:responseObject]]);
          }
      }
      failure:^(NSURLSessionTask *operation, NSError *error) {
          NSLog(@"deletePatch - error: %@", [error localizedDescription]);
          callback(NO, [self errorMakingNetworkCall:error]);
      }];
}

- (void)reportAbuse:(Patch *)patch isAbuse:(BOOL)isAbuse callback:(ReportAbuseCallback)callback {
    // If the user is not logged in, fail now because not being logged in means you cannot report an abusive patch
    if (![self isLoggedIn]) {
        NSLog(@"reportAbuse - no user is currently logged in");
        callback(false, [self errorBecauseNotLoggedIn]);
        return;
    }
    
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@%@/", baseUrl, REPORT_PATCH_URL, patch.guid]];
    
    NSLog(@"reportAbuse - url = %@", url.absoluteString);
    
    NSMutableDictionary *requestParams = [self getCurrentUserAuthParamsDictionary];
    [requestParams setObject:@(isAbuse) forKey:IS_ABUSE_PARAM_NAME];
    
    [self POST:url.absoluteString parameters:requestParams progress:nil
       success:^(NSURLSessionTask *task, id responseObject) {
           NSLog(@"reportAbuse - success: %@", responseObject);
           if ([self responseOk:responseObject]) {
               callback(YES, nil);
           } else {
               callback(NO, [self errorWithErrorString:[self getErrorMessageFromServiceReply:responseObject]]);
           }
       }
       failure:^(NSURLSessionTask *operation, NSError *error) {
           NSLog(@"reportAbuse - error: %@", [error localizedDescription]);
           callback(NO, [self errorMakingNetworkCall:error]);
       }];
}

// Private Helper Methods

- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(NSMutableDictionary *)parameters
     constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                      progress:(nullable void (^)(NSProgress * _Nonnull))uploadProgress
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    return [httpSessionManager POST:URLString parameters:[self signedParameters:parameters url:URLString] constructingBodyWithBlock:block progress:uploadProgress success:success failure:failure];
}

- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(NSMutableDictionary *)parameters
                      progress:(void (^)(NSProgress * _Nonnull))uploadProgress
                       success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                       failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure {
    return [httpSessionManager POST:URLString parameters:[self signedParameters:parameters url:URLString] progress:uploadProgress success:success failure:failure];
}

- (NSURLSessionDataTask *)GET:(NSString *)URLString
                   parameters:(NSMutableDictionary *)parameters
                     progress:(void (^)(NSProgress * _Nonnull))downloadProgress
                      success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                      failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure {
    return [httpSessionManager GET:URLString parameters:[self signedParameters:parameters url:URLString] progress:downloadProgress success:success failure:failure];
}

- (NSDictionary *)signedParameters:(NSMutableDictionary *)parameters url:(NSString *)url {
    if ([self isLocalEnvironment] && overrideRandomValue != nil) {
        parameters[PARAM_KEY_RANDOM] = overrideRandomValue;
        overrideRandomValue = nil;
    } else {
        parameters[PARAM_KEY_RANDOM] = [[[NSProcessInfo processInfo] globallyUniqueString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    }
    
    parameters[PARAM_VERSION] = @(IOS_SDK_VERSION);
    
    NSMutableDictionary *signedParameters = [[NSMutableDictionary alloc] init];
    
    NSArray *sortedKeys = [[parameters allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    NSMutableString *digest = [[NSMutableString alloc] init];
    
    for (NSString *key in sortedKeys) {
        [digest appendString:key];
        [digest appendFormat:@"%@", parameters[key]];
        
        signedParameters[key] = parameters[key];
    }
    
    if ([self isLocalEnvironment] && overrideDigestValue != nil) {
        signedParameters[PARAM_KEY_DIGEST] = overrideDigestValue;
        overrideDigestValue = nil;
    } else {
        signedParameters[PARAM_KEY_DIGEST] = [self SHA256hexDigestForData:[digest dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    return signedParameters;
}

- (void)appendIfNotNilToRequestParams:(NSMutableDictionary *)requestParams key:(NSString *)key value:(id)value {
    if (value != nil) {
        if ([value isKindOfClass:[NSString class]]) {
            requestParams[key] = value;
        } else if ([value isKindOfClass:[NSNumber class]]) {
            requestParams[key] = [NSString stringWithFormat:@"%d", [value boolValue]];
        } else {
            NSLog(@"appendIfNotNilToRequestParams - value for key %@ is of unsupported class", key);
        }
    }
}

- (void)appendFormData:(id<AFMultipartFormData>)formData patchData:(NSData *)patchData extraData:(NSData *)extraData {
    if (patchData != nil) {
        NSLog(@"formDataAppendHelper - appending patchData data");
        [formData appendPartWithFileData:patchData name:PATCH_DATA_PARAM_NAME fileName:@"data"
                                mimeType:FILE_DATA_MIME_TYPE];
    }
    
    if (extraData != nil) {
        NSLog(@"formDataAppendHelper - appending extraData data");
        [formData appendPartWithFileData:extraData name:PATCH_EXTRA_DATA_PARAM_NAME fileName:@"extra_data"
                                mimeType:FILE_DATA_MIME_TYPE];
    }
}

// SHA256 hex digest adapted from: http://stackoverflow.com/a/7520655/265791
- (NSString *)SHA256hexDigestForData:(NSData *)data {
    NSMutableData *sha256Out = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, sha256Out.mutableBytes);
    
    NSUInteger capacity = sha256Out.length * 2;
    NSMutableString *hexDigestString = [NSMutableString stringWithCapacity:capacity];
    const unsigned char *buf = sha256Out.bytes;
    NSInteger i;
    for (i=0; i<sha256Out.length; ++i) {
        [hexDigestString appendFormat:@"%02X", buf[i]];
    }
    return hexDigestString;
}

- (void)processAuthResponse:(id)responseObject callback:(CreateUserCallback)callback {
    if ([self responseOk:responseObject]) {
        // If a valid create user or login call, persist user credentials to keychain
        [self authSucceededWithUser:[self getUserFromMessageResponse:responseObject]];
        callback(true, nil);
    } else {
        callback(false, [self errorWithErrorString:[self getErrorMessageFromServiceReply:responseObject]]);
    }
}

// Constructs a User object from the JSON in the "message" response body
- (User *)getUserFromMessageResponse:(id)responseObject {
    return [[User alloc] initWithDictionary:[responseObject objectForKey:@"message"]];
}

// Constructs a Patch object from the JSON in the "message" response body
- (Patch *)getPatchFromMessageResponse:(id)responseObject {
    NSData *data = [[responseObject objectForKey:@"message"] dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return [[Patch alloc] initWithDictionary:json];
}

// Returns a list of JSON blobs contained in the "message" response body
- (NSArray *)getPatchListFromMessageResponse:(id)responseObject {
    NSData *data = [[responseObject objectForKey:@"message"] dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return json;
}

- (NSMutableDictionary *)getCurrentUserAuthParamsDictionary {
    NSMutableDictionary *requestParams = [self getBaseRequestDictionary];
    
    if ([self isLoggedIn]) {
        requestParams[USER_ID_PARAM_KEY] = @([self getLoggedInUserId]);
        requestParams[AUTH_TOKEN_PARAM_KEY] = [self getLoggedInAuthToken];
        requestParams[EMAIL_PARAM_KEY] = [self getLoggedInEmail];
    }
    
    return requestParams;
}

- (NSMutableDictionary *)getBaseRequestDictionary {
    NSMutableDictionary *baseRequestDictionary = [[NSMutableDictionary alloc] init];
    
    baseRequestDictionary[TYPE_PARAM_KEY] = @(sPatchType);
    
    return baseRequestDictionary;
}

- (BOOL)responseOk:(id)responseObject {
    if (responseObject == nil) {
        return NO;
    }
    
    if ([responseObject[@"code"] intValue] != SUCCESS_CODE) {
        // If we get an AUTH_ERROR code that means this user is making calls with an invalid auth token. Log them out.
        if ([responseObject[@"code"] intValue] == AUTH_ERROR) {
            NSLog(@"responseOk - received an AUTH_ERROR response code; calling localLogOut");
            [self localLogOut];
        }
        
        return NO;
    }

    return YES;
}

- (NSError *)errorMakingNetworkCall:(NSError *)error {
    NSDictionary *details = @{NSLocalizedDescriptionKey : [error localizedDescription]};
    return [NSError errorWithDomain:[error localizedDescription] code:500 userInfo:details];
}

- (NSError *)errorWithErrorString:(NSString *)errorString {
    NSDictionary *details = @{NSLocalizedDescriptionKey : errorString};
    return [NSError errorWithDomain:errorString code:500 userInfo:details];
}

- (NSError *)errorBecauseNotLoggedIn {
    return [self errorWithErrorString:ERROR_STRING_NO_USER_LOGGED_IN];
}

- (NSString *)getErrorMessageFromServiceReply:(id)responseObject {
    return [NSString stringWithUTF8String: [[responseObject objectForKey:@"message"] cStringUsingEncoding:NSUTF8StringEncoding]];
}

// For unit testing only! Please do not call these methods!

static NSString *overrideRandomValue;
static NSString *overrideDigestValue;

+ (void)overrideRandomValueForNextRequest:(NSString *)randomValue {
    overrideRandomValue = randomValue;
}

+ (void)overrideDigestValueForNextRequest:(NSString *)digestValue {
    overrideDigestValue = digestValue;
}

@end
