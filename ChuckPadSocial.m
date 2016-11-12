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
#import "ChuckPadKeychain.h"
#import "Patch.h"
#import "PatchCache.h"
#import "User.h"

@implementation ChuckPadSocial {
    @private AFHTTPSessionManager *httpSessionManager;
    @private NSString *baseUrl;
    @private NSArray *environmentUrls;
}

// API URLs
NSString *const CREATE_USER_URL = @"/user/create_user";
NSString *const LOGIN_USER_URL = @"/user/login";
NSString *const CHANGE_PASSWORD_URL = @"/user/change_password";
NSString *const LOG_OUT_URL = @"/user/logout";

NSString *const GET_DOCUMENTATION_URL = @"/patch/documentation";
NSString *const GET_FEATURED_URL = @"/patch/featured";
NSString *const GET_RECENT_URL = @"/patch/new";
NSString *const GET_MY_PATCHES_URL = @"/patch/my";
NSString *const GET_PATCHES_FOR_USER_URL = @"/patch/user";
NSString *const GET_SINGLE_PATCH_INFO = @"/patch/info";

NSString *const CREATE_PATCH_URL = @"/patch/create_patch/";
NSString *const UPDATE_PATCH_URL = @"/patch/update/";
NSString *const DELETE_PATCH_URL = @"/patch/delete/";
NSString *const REPORT_PATCH_URL = @"/patch/report/";

// iOS User Agent Identifier
NSString *const CHUCKPAD_SOCIAL_IOS_USER_AGENT = @"chuckpad-social-ios";

// User-facing error strings
NSString *const ERROR_STRING_LOGGED_IN_ALREADY = @"Someone is already logged in. Please log out and try again.";
NSString *const ERROR_STRING_NO_USER_LOGGED_IN = @"No user is currently logged in. Please log in and try again.";
NSString *const ERROR_STRING_ERROR_FETCHING_PATCHES = @"There was an error fetching the scripts. Please try again later.";
NSString *const ERROR_STRING_ERROR_DOWNLOADING_PATCH_RESOURCE = @"There was an error downloading the script. Please try again later.";
NSString *const ERROR_STRING_LOGGING_OUT = @"There was an error logging out. Please try again later.";

// NSNotification constants
NSString *const CHUCKPAD_SOCIAL_LOG_IN = @"CHUCKPAD_SOCIAL_LOG_IN";
NSString *const CHUCKPAD_SOCIAL_LOG_OUT = @"CHUCKPAD_SOCIAL_LOG_OUT";

+ (ChuckPadSocial *)sharedInstance {
    static ChuckPadSocial *sharedInstance = nil;
    static dispatch_once_t onceToken;
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
    baseUrl = environmentUrls[[[NSUserDefaults standardUserDefaults] integerForKey:@"Environment"]];
}

- (NSString *)getBaseUrl {
    return baseUrl;
}

- (void)setEnvironment:(Environment)environment {
    baseUrl = environmentUrls[environment];
    [[NSUserDefaults standardUserDefaults] setInteger:environment forKey:@"Environment"];
}

- (void)toggleEnvironment {
    NSInteger currentEnviroment = [[NSUserDefaults standardUserDefaults] integerForKey:@"Environment"];
    currentEnviroment++;
    
    if (currentEnviroment > 2) {
        currentEnviroment = 0;
    }

    [self setEnvironment:(Environment) currentEnviroment];
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
    requestParams[@"user[username]"] = username;
    requestParams[@"user[email]"] = email;
    requestParams[@"password"] = password;

    [httpSessionManager POST:url.absoluteString parameters:requestParams progress:nil
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
    requestParams[@"username_or_email"] = usernameOrEmail;
    
    requestParams[@"password"] = password;

    [httpSessionManager POST:url.absoluteString parameters:requestParams progress:nil
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
    
    [httpSessionManager POST:url.absoluteString parameters:requestParams progress:nil
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

- (void)changePassword:(NSString *)newPassword callback:(CreateUserCallback)callback {
    // If not logged in, log an error and abort
    if (![self isLoggedIn]) {
        callback(false, [self errorBecauseNotLoggedIn]);
        return;
    }

    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", baseUrl, CHANGE_PASSWORD_URL]];
    
    NSLog(@"changedPassword - url = %@", url.absoluteString);
    
    NSMutableDictionary *requestParams = [self getCurrentUserAuthParamsDictionary];
    requestParams[@"new_password"] = newPassword;
    
    [httpSessionManager POST:url.absoluteString parameters:requestParams progress:nil
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

    [httpSessionManager GET:url.absoluteString parameters:requestParams progress:nil
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

- (void)getPatchInfo:(NSInteger)patchId callback:(GetPatchInfoCallback)callback {
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@/%ld", baseUrl, GET_SINGLE_PATCH_INFO, (long)patchId]];
    
    NSLog(@"getPatchInfo - url = %@", url.absoluteString);

    // Do not use cache here because we want to ensure we always return fresh metadata.
    
    [httpSessionManager GET:url.absoluteString parameters:nil progress:nil
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

- (void)downloadPatchResource:(Patch *)patch callback:(DownloadPatchResourceCallback)callback {
    NSString *url = [NSString stringWithFormat:@"%@%@", [[ChuckPadSocial sharedInstance] getBaseUrl], patch.resourceUrl];

    NSLog(@"downloadPatchResource - url = %@", url);

    NSData *patchDataFromCache = [[PatchCache sharedInstance] objectForKey:url];
    if (patchDataFromCache != nil) {
        NSLog(@"downloadPatchResource - using cached patch");
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

NSString *const PATCH_ID_PARAM_NAME = @"patch[id]";
NSString *const FILE_DATA_PARAM_NAME = @"patch[data]";
NSString *const PATCH_NAME_PARAM_NAME = @"patch[name]";
NSString *const PATCH_DESCRIPTION_PARAM_NAME = @"patch[description]";
NSString *const PATCH_PARENT_ID_PARAM_NAME = @"patch[parent_id]";
NSString *const IS_HIDDEN_PARAM_NAME = @"patch[hidden]";
NSString *const IS_ABUSE_PARAM_NAME = @"is_abuse";

NSString *const FILE_DATA_MIME_TYPE = @"application/octet-stream";

- (void)updatePatch:(Patch *)patch hidden:(NSNumber *)isHidden name:(NSString *)name description:(NSString *)description
           filename:(NSString *)filename fileData:(NSData *)fileData callback:(UpdatePatchCallback)callback {
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

    requestParams[PATCH_ID_PARAM_NAME] = [NSString stringWithFormat:@"%ld", (long) patch.patchId];

    if (isHidden != nil) {
        requestParams[IS_HIDDEN_PARAM_NAME] = [NSString stringWithFormat:@"%d", [isHidden boolValue]];
    }

    if (name != nil) {
        requestParams[PATCH_NAME_PARAM_NAME] = name;
    }

    if (description != nil) {
        requestParams[PATCH_DESCRIPTION_PARAM_NAME] = description;
    }

    [httpSessionManager POST:url.absoluteString parameters:requestParams constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
        if (fileData != nil && filename != nil) {
            NSLog(@"updatePatch - appending form data");
            [formData appendPartWithFileData:fileData
                                        name:FILE_DATA_PARAM_NAME
                                    fileName:filename
                                    mimeType:FILE_DATA_MIME_TYPE];
        }
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

- (void)uploadPatch:(NSString *)patchName description:(NSString *)description parent:(NSInteger)parentId
           filename:(NSString *)filename fileData:(NSData *)fileData callback:(CreatePatchCallback)callback {
    // If the user is not logged in, fail now because not being logged in means you cannot update a patch
    if (![self isLoggedIn]) {
        NSLog(@"uploadPatch - no user is currently logged in");
        callback(false, nil, [self errorBecauseNotLoggedIn]);
        return;
    }

    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", baseUrl, CREATE_PATCH_URL]];

    NSLog(@"uploadPatch - url = %@", url.absoluteString);
    
    NSMutableDictionary *requestParams = [self getCurrentUserAuthParamsDictionary];

    if (patchName != nil) {
        requestParams[PATCH_NAME_PARAM_NAME] = patchName;
    }

    if (description != nil) {
        requestParams[PATCH_DESCRIPTION_PARAM_NAME] = description;
    }

    if (parentId >= 0) {
        requestParams[PATCH_PARENT_ID_PARAM_NAME] = @(parentId);
    }

    // Flush cache for getting my patches
    [[PatchCache sharedInstance] removeObjectForKey:GET_MY_PATCHES_URL];

    [httpSessionManager POST:url.absoluteString parameters:requestParams constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
        [formData appendPartWithFileData:fileData
                                    name:FILE_DATA_PARAM_NAME
                                fileName:filename
                                mimeType:FILE_DATA_MIME_TYPE];
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
    
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@%ld/", baseUrl, DELETE_PATCH_URL, (long)patch.patchId]];
    
    NSLog(@"deletePatch - url = %@", url.absoluteString);
 
    // Flush cache for getting my patches and the resource since we're about to delete one
    [[PatchCache sharedInstance] removeObjectForKey:GET_MY_PATCHES_URL];
    [[PatchCache sharedInstance] removeObjectForKey:[NSString stringWithFormat:@"%@%@", [[ChuckPadSocial sharedInstance] getBaseUrl], patch.resourceUrl]];
    
    [httpSessionManager GET:url.absoluteString parameters:[self getCurrentUserAuthParamsDictionary] progress:nil
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
  
  NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@%ld/", baseUrl, REPORT_PATCH_URL, (long)patch.patchId]];
  
  NSLog(@"reportAbuse - url = %@", url.absoluteString);
  
  NSMutableDictionary *requestParams = [self getCurrentUserAuthParamsDictionary];
  [requestParams setObject:@(isAbuse) forKey:IS_ABUSE_PARAM_NAME];
    
  [httpSessionManager POST:url.absoluteString parameters:requestParams progress:nil
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
    NSMutableDictionary *requestParams = [[NSMutableDictionary alloc] init];
    
    if ([self isLoggedIn]) {
        requestParams[@"user_id"] = @([self getLoggedInUserId]);
        requestParams[@"auth_token"] = [self getLoggedInAuthToken];
        requestParams[@"email"] = [self getLoggedInEmail];
    }
    
    return requestParams;
}

- (BOOL)responseOk:(id)responseObject {
    if(responseObject == nil) {
        return NO;
    }

    if([responseObject respondsToSelector:@selector(objectForKey:)] &&
       [responseObject objectForKey:@"code"] != nil &&
       [responseObject[@"code"] intValue] != 200) {
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

@end
