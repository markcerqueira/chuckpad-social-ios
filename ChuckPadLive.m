//
//  ChuckPadLive.m
//  hello-chuckpad
//
//  Created by Mark Cerqueira on 1/7/18.
//

#import "ChuckPadLive.h"

#import <PubNub/PubNub.h>

#import "ChuckPadSocial.h"

@interface ChuckPadLive () <PNObjectEventListener>

@property (nonatomic, strong) PubNub *client;
@property (nonatomic, strong) LiveSession *liveSession;

@end

@implementation ChuckPadLive

// TODO Add support for staging/production keys
NSString *const PUBNUB_PUBLISH_KEY = @"pub-c-a2852cba-9aeb-43d4-899f-700a0377bf3c";
NSString *const PUBNUB_SUBSCRIBE_KEY = @"sub-c-e48357a8-f3dd-11e7-a966-520fb0a815a8";

static ChuckPadLive *sharedInstance = nil;
static dispatch_once_t onceToken;

+ (ChuckPadLive *)sharedInstance {
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ChuckPadLive alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        // Initialize and configure PubNub client instance
        PNConfiguration *configuration = [PNConfiguration configurationWithPublishKey:PUBNUB_PUBLISH_KEY subscribeKey:PUBNUB_SUBSCRIBE_KEY];
        configuration.stripMobilePayload = YES;
        
        self.client = [PubNub clientWithConfiguration:configuration];
        
        [self.client addListener:self];
    }
    return self;
}

- (void)connect:(LiveSession *)liveSession chuckPadLiveDelegate:(id<ChuckPadLiveDelegate>)delegate {
    if (liveSession == nil || delegate == nil) {
        NSLog(@"connect - liveSession and/or delegate param is nil. Aborting!");
        return;
    }
    
    self.liveSession = liveSession;
    self.delegate = delegate;

    [self.client subscribeToChannels:@[liveSession.sessionGUID] withPresence:YES];
}

- (void)publish:(id)data {
    if (self.liveSession == nil || self.delegate == nil) {
        NSLog(@"publish - liveSession and/or delegate property is nil. Aborting!");
        return;
    }
    
    [self.client publish:data toChannel:self.liveSession.sessionGUID withCompletion:^(PNPublishStatus * _Nonnull status) {
        if (!status.isError) {
            // Message successfully published to specified channel.
            NSLog(@"publish - successfully published data: %@", data);
        } else {
            // Message publish error. Request can be resent using: [status retry]
            NSLog(@"publish - failure (%@) publishing data: %@", status.errorData.information, data);
        }
    }];
}

- (void)unsubscribe {
    [self.client unsubscribeFromAll];
}

#pragma mark - PNObjectiveEventListener

// Adapted from: https://www.pubnub.com/docs/ios-objective-c/pubnub-objective-c-sdk#include_pubnub_sdk_app_delegate

// Handle new message from one of channels on which client has been subscribed.
- (void)client:(PubNub *)client didReceiveMessage:(PNMessageResult *)message {
    NSLog(@"didReceiveMessage - %@ on channel %@ at %@", message.data.message, message.data.channel, message.data.timetoken);
    
    [self.delegate chuckPadLive:self didReceiveData:message.data.message];
}

// New presence event handling.
- (void)client:(PubNub *)client didReceivePresenceEvent:(PNPresenceEventResult *)event {

}

// Handle subscription status change.
- (void)client:(PubNub *)client didReceiveStatus:(PNStatus *)status {
    if (status.operation == PNSubscribeOperation) {
        // Check whether received information about successful subscription or restore.
        if (status.category == PNConnectedCategory || status.category == PNReconnectedCategory) {
            // Status object for those categories can be casted to `PNSubscribeStatus` for use below.
            PNSubscribeStatus *subscribeStatus = (PNSubscribeStatus *)status;
            if (subscribeStatus.category == PNConnectedCategory) {
                // This is expected for a subscribe, this means there is no error or issue whatsoever.
                [self.delegate chuckPadLive:self didReceiveStatus:LiveStatusConnected];
            } else {
                // This usually occurs if subscribe temporarily fails but reconnects. This means there was
                // an error but there is no longer any issue.
                [self.delegate chuckPadLive:self didReceiveStatus:LiveStatusReconnected];
            }
        } else if (status.category == PNUnexpectedDisconnectCategory) {
             // This is usually an issue with the internet connection, this is an error, handle
             // appropriately retry will be called automatically.
            [self.delegate chuckPadLive:self didReceiveStatus:LiveStatusUnexpectedlyDisconnected];
        } else {
            // Looks like some kind of issues happened while client tried to subscribe or disconnected from network.
            PNErrorStatus *errorStatus = (PNErrorStatus *)status;
            if (errorStatus.category == PNAccessDeniedCategory) {
                // This means that PAM does allow this client to subscribe to this channel and channel group
                // configuration. This is another explicit error.
                [self.delegate chuckPadLive:self didReceiveStatus:LiveStatusErrorAccessDenied];
            } else {
                // More errors can be directly specified by creating explicit cases for other error categories
                // of PNStatusCategory such as: PNDecryptionErrorCategory, PNMalformedFilterExpressionCategory,
                // PNMalformedResponseCategory, PNTimeoutCategory or PNNetworkIssuesCategory.
                [self.delegate chuckPadLive:self didReceiveStatus:LiveStatusErrorOther];
            }
        }
        
        return;
    }
    
    if (status.operation == PNUnsubscribeOperation) {
        if (status.category == PNDisconnectedCategory) {
            // This is the expected category for an unsubscribe. This means there was no error in unsubscribing
            // from everything.
            [self.delegate chuckPadLive:self didReceiveStatus:LiveStatusDisconnected];
        }
        
        return;
    }
}

@end
