//
//  ChuckPadSocial.m
//  chuckpad-social-ios
//
//  Created by Mark Cerqueira on 6/17/16.
//
//

#import <Foundation/Foundation.h>
#import "ChuckPadSocial.h"
#import "AFHTTPSessionManager.h"
#import "Patch.h"
#import "ChuckPadKeychain.h"

@implementation ChuckPadSocial {
    @private AFHTTPSessionManager *httpSessionManager;
    @private NSString *baseUrl;
}

NSString *const CHUCK_PAD_SOCIAL_BASE_URL = @"https://chuckpad-social.herokuapp.com";
NSString *const CHUCK_PAD_SOCIAL_DEV_BASE_URL = @"http://localhost:9292";

NSString *const CREATE_USER_URL = @"/user/create_user";
NSString *const LOGIN_USER_URL = @"/user/login";
NSString *const CHANGE_PASSWORD_URL = @"/user/change_password";

NSString *const GET_DOCUMENTATION_URL = @"/patch/json/documentation";
NSString *const GET_FEATURED_URL = @"/patch/json/featured";
NSString *const GET_ALL_URL = @"/patch/json/all";
NSString *const GET_MY_PATCHES_URL = @"/patch/my";
NSString *const GET_PATCHES_FOR_USER_URL = @"/patch/json/user";

NSString *const CREATE_PATCH_URL = @"/patch/create_patch/";
NSString *const UPDATE_PATCH_URL = @"/patch/update/";

NSString *const CHUCKPAD_SOCIAL_IOS_USER_AGENT = @"chuckpad-social-ios";

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
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"debugEnvironment"]) {
        baseUrl = CHUCK_PAD_SOCIAL_DEV_BASE_URL;
    } else {
        baseUrl = CHUCK_PAD_SOCIAL_BASE_URL;
    }
}

- (NSString *)getBaseUrl {
    return baseUrl;
}

- (void)toggleEnvironment {
    BOOL isDebugEnvironment;
    if ([baseUrl isEqualToString:CHUCK_PAD_SOCIAL_BASE_URL]) {
        baseUrl = CHUCK_PAD_SOCIAL_DEV_BASE_URL;
        isDebugEnvironment = YES;
    } else {
        baseUrl = CHUCK_PAD_SOCIAL_BASE_URL;
        isDebugEnvironment = NO;
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:isDebugEnvironment forKey:@"debugEnvironment"];
}

- (void)setEnvironmentToDebug {
    baseUrl = CHUCK_PAD_SOCIAL_DEV_BASE_URL;
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"debugEnvironment"];
}

// User API

- (void)createUser:(NSString *)username email:(NSString *)email password:(NSString *)password callback:(CreateUserCallback)callback {
    // If a user is already logged in, do not allow creating another user
    if ([self isLoggedIn]) {
        NSLog(@"createUser - a user is already logged in");
        callback(false, [NSError errorWithDomain:@"A user is already logged in" code:500 userInfo:nil]);
        return;
    }
    
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", baseUrl, CREATE_USER_URL]];
    
    NSLog(@"createUser: %@", url.absoluteString);
    
    NSMutableDictionary *requestParams = [[NSMutableDictionary alloc] init];
    [requestParams setObject:username forKey:@"user[username]"];
    [requestParams setObject:email forKey:@"user[email]"];
    [requestParams setObject:password forKey:@"password"];

    [httpSessionManager POST:url.absoluteString parameters:requestParams progress:nil
                     success:^(NSURLSessionDataTask *task, id responseObject) {
                         NSLog(@"createUser - response: %@", responseObject);

                         // This will handle calling our callback
                         [self authResponse:responseObject withUsername:username withEmail:email withPassword:password withCallback:callback];
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         NSLog(@"createUser - error: %@", [error localizedDescription]);
                         callback(false, [self errorFromServiceFailure:error]);
                     }];
}

- (void)logIn:(NSString *)usernameOrEmail password:(NSString *)password callback:(CreateUserCallback)callback {
    // If a user is already logged in, do not allow logging in as another user
    if ([self isLoggedIn]) {
        NSLog(@"logIn - a user is already logged in");
        callback(false, [NSError errorWithDomain:@"A user is already logged in" code:500 userInfo:nil]);
        return;
    }
    
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", baseUrl, LOGIN_USER_URL]];
    
    NSLog(@"logIn: %@", url.absoluteString);
    
    NSMutableDictionary *requestParams = [[NSMutableDictionary alloc] init];
    [requestParams setObject:usernameOrEmail forKey:@"username_or_email"];
    [requestParams setObject:password forKey:@"password"];

    // TODO Response from service should include username so the client is aware of what it is
    [httpSessionManager POST:url.absoluteString parameters:requestParams progress:nil
                     success:^(NSURLSessionDataTask *task, id responseObject) {
                         NSLog(@"logIn - response: %@", responseObject);

                         // This will handle calling our callback
                         [self authResponse:responseObject withUsername:usernameOrEmail withEmail:usernameOrEmail withPassword:password withCallback:callback];
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         NSLog(@"logIn - error: %@", [error localizedDescription]);
                         callback(false, [self errorFromServiceFailure:error]);
                     }];
}

- (void)authResponse:(id)responseObject withUsername:(NSString *)username withEmail:(NSString *)email withPassword:(NSString *)password withCallback:(CreateUserCallback)callback {
    int responseCode = [[responseObject objectForKey:@"code"] intValue];
    if (responseCode == 200) {
        // If a valid create user or login call, persist user credentials to keychain
        [self loginCompletedWithUsername:username withEmail:email withPassword:password];
        callback(true, nil);
    } else {
        callback(false, [self errorFromPreconditionChecks:@"Error hitting user API"]);
    }
}

- (void)logOut {
    // If not logged in, log an error and abort early
    if (![self isLoggedIn]) {
        NSLog(@"logOut - no user is currently logged in; aborting");
        return;
    }

    // There is no API to log out. We just clear the credentials from the keychain which makes the user "logged out."
    [[ChuckPadKeychain sharedInstance] clearCredentials];
}

- (void)changePassword:(NSString *)newPassword callback:(CreateUserCallback)callback {
    // If not logged in, log an error and abort
    if (![self isLoggedIn]) {
        NSLog(@"changePassword - no user is currently logged in; aborting");
        callback(false, [self errorBecauseNotLoggedIn]);
        return;
    }

    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", baseUrl, CHANGE_PASSWORD_URL]];
    
    NSLog(@"changedPassword - %@", url.absoluteString);
    
    NSMutableDictionary *requestParams = [[NSMutableDictionary alloc] init];
    [requestParams setObject:[self getLoggedInUserName] forKey:@"username_or_email"];
    [requestParams setObject:[self getLoggedInPassword] forKey:@"password"];
    [requestParams setObject:newPassword forKey:@"new_password"];
    
    [httpSessionManager POST:url.absoluteString parameters:requestParams progress:nil
                     success:^(NSURLSessionDataTask *task, id responseObject) {
                         NSLog(@"changedPassword - success: %@", responseObject);
                         
                         int responseCode = [[responseObject objectForKey:@"code"] intValue];
                         if (responseCode == 200) {
                             [[ChuckPadKeychain sharedInstance] updatePassword:newPassword];

                             callback(true, nil);
                         } else {
                             callback(false, nil);
                         }
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         NSLog(@"changedPassword - error: %@", [error localizedDescription]);
                         callback(false, [self errorFromServiceFailure:error]);
                     }];
}

- (void)loginCompletedWithUsername:(NSString *)username withEmail:(NSString *)email withPassword:(NSString *)password {
    [[ChuckPadKeychain sharedInstance] authComplete:username withEmail:email withPassword:password];
}

- (NSString *)getLoggedInUserName {
    return [[ChuckPadKeychain sharedInstance] getLoggedInUserName];
}

- (NSString *)getLoggedInPassword {
    return [[ChuckPadKeychain sharedInstance] getLoggedInPassword];
}

- (NSString *)getLoggedInEmail {
    return [[ChuckPadKeychain sharedInstance] getLoggedInEmail];
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

- (void)getAllPatches:(GetPatchesCallback)callback {
    [self getPatchesInternal:GET_ALL_URL withCallback:callback];
}

- (void)getPatchesInternal:(NSString *)urlPath withCallback:(GetPatchesCallback)callback {
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", baseUrl, urlPath]];

    NSLog(@"getPatchesInternal - %@", url.absoluteString);

    // Add currentUser params because if a user has hidden patches in any category we want to return them to the user.
    NSMutableDictionary *requestParams = [[NSMutableDictionary alloc] init];
    if ([self isLoggedIn]) {
        [self addCurrentUserParams:requestParams];
    }

    [httpSessionManager GET:url.absoluteString parameters:requestParams progress:nil
                    success:^(NSURLSessionTask *task, id responseObject) {
                        if (responseObject != nil && [responseObject count] > 0) {
                            NSMutableArray *patchesArray = [[NSMutableArray alloc] init];

                            for (id object in responseObject) {
                                Patch *patch = [[Patch alloc] initWithDictionary:object];
                                // NSLog(@"Patch: %@", patch.description);
                                [patchesArray addObject:patch];
                            }

                            callback(patchesArray, nil);
                        } else {
                            callback(nil, nil);
                        }
                    }
                    failure:^(NSURLSessionTask *operation, NSError *error) {
                        callback(nil, error);
                    }];
}

NSString *const PATCH_ID_PARAM_NAME = @"patch[id]";
NSString *const FILE_DATA_PARAM_NAME = @"patch[data]";
NSString *const PATCH_NAME_PARAM_NAME = @"patch[name]";
NSString *const IS_HIDDEN_PARAM_NAME = @"patch[hidden]";

NSString *const FILE_DATA_MIME_TYPE = @"application/octet-stream";

- (void)updatePatch:(Patch *)patch hidden:(NSNumber *)isHidden patchName:(NSString *)patchName filename:(NSString *)filename
           fileData:(NSData *)fileData callback:(UpdatePatchCallback)callback {
    // If the user is not logged in, fail now because not being logged in means you cannot update a patch
    if (![self isLoggedIn]) {
        NSLog(@"updatePatch - no user is currently logged in");
        callback(false, nil, [self errorBecauseNotLoggedIn]);
        return;
    }

    // Patch cannot be nil
    if (patch == nil) {
        NSLog(@"updatePatch - cannot update a nil patch");
        callback(false, nil, [self errorFromPreconditionChecks:@"No patch given to update"]);
        return;
    }

    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", baseUrl, UPDATE_PATCH_URL]];

    NSMutableDictionary *requestParams = [[NSMutableDictionary alloc] init];

    [requestParams setObject:[NSString stringWithFormat:@"%ld", (long)patch.patchId] forKey:PATCH_ID_PARAM_NAME];

    if (isHidden != nil) {
        [requestParams setObject:[NSString stringWithFormat:@"%d", [isHidden boolValue]] forKey:IS_HIDDEN_PARAM_NAME];
    }

    if (patchName != nil) {
        [requestParams setObject:patchName forKey:PATCH_NAME_PARAM_NAME];
    }

    [self addCurrentUserParams:requestParams];

    [httpSessionManager POST:url.absoluteString parameters:requestParams constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
                if (fileData != nil && filename != nil) {
                    [formData appendPartWithFileData:fileData
                                                name:FILE_DATA_PARAM_NAME
                                            fileName:filename
                                            mimeType:FILE_DATA_MIME_TYPE];
                }
            }
                    progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                NSLog(@"updatePatch - success: %@", responseObject);
                callback(true, [self getPatchFromMessageResponse:responseObject], nil);
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                NSLog(@"updatePatch - error: %@", [error localizedDescription]);
                callback(false, nil, [self errorFromServiceFailure:error]);
            }];

}

- (NSError *)errorFromServiceFailure:(NSError *)error {
    return [NSError errorWithDomain:[error localizedDescription] code:500 userInfo:nil];
}

- (NSError *)errorFromPreconditionChecks:(NSString *)errorString {
    return [NSError errorWithDomain:errorString code:500 userInfo:nil];
}

- (NSError *)errorBecauseNotLoggedIn {
    return [self errorFromPreconditionChecks:@"No user is currently logged in"];
}

- (void)uploadPatch:(NSString *)patchName filename:(NSString *)filename fileData:(NSData *)fileData callback:(CreatePatchCallback)callback {
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", baseUrl, CREATE_PATCH_URL]];

    NSLog(@"uploadPatch - %@", url.absoluteString);
    
    NSMutableDictionary *requestParams = [[NSMutableDictionary alloc] init];

    if (patchName != nil) {
        [requestParams setObject:patchName forKey:PATCH_NAME_PARAM_NAME];
    }

    [self addCurrentUserParams:requestParams];

    [httpSessionManager POST:url.absoluteString parameters:requestParams constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
        [formData appendPartWithFileData:fileData
                                    name:FILE_DATA_PARAM_NAME
                                fileName:filename
                                mimeType:FILE_DATA_MIME_TYPE];
            }
             progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                 NSLog(@"uploadPatch - success: %@", responseObject);
                 callback(true, [self getPatchFromMessageResponse:responseObject], nil);
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                NSLog(@"uploadPatch - error: %@", [error localizedDescription]);
                callback(false, nil, [self errorFromServiceFailure:error]);
            }];
}

- (Patch *)getPatchFromMessageResponse:(id)responseObject {
    // Need to convert the string in "message" to a JSON object
    NSData *data = [[responseObject objectForKey:@"message"] dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return [[Patch alloc] initWithDictionary:json];
}

- (void)addCurrentUserParams:(NSMutableDictionary *)requestParams {
    [requestParams setObject:[self getLoggedInUserName] forKey:@"username"];
    [requestParams setObject:[self getLoggedInPassword] forKey:@"password"];
    [requestParams setObject:[self getLoggedInEmail] forKey:@"email"];
}

@end
