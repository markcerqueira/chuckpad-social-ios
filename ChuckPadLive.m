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

+ (ChuckPadLive *)initWithLiveSession:(LiveSession *)liveSession chuckPadLiveDelegate:(id<ChuckPadLiveDelegate>)delegate {
    ChuckPadLive *chuckPadLive = [[ChuckPadLive alloc] init];
    
    // Initialize and configure PubNub client instance
    PNConfiguration *configuration = [PNConfiguration configurationWithPublishKey:PUBNUB_PUBLISH_KEY subscribeKey:PUBNUB_SUBSCRIBE_KEY];
    configuration.stripMobilePayload = NO;
        
    chuckPadLive.client = [PubNub clientWithConfiguration:configuration];
    chuckPadLive.delegate = delegate;
    chuckPadLive.liveSession = liveSession;

    [chuckPadLive.client addListener:chuckPadLive];
    [chuckPadLive.client subscribeToChannels:@[liveSession.sessionGUID] withPresence:YES];
    
    return chuckPadLive;
}

- (void)publish:(id)data {
    [self.client publish:data toChannel:self.liveSession.sessionGUID withCompletion:^(PNPublishStatus * _Nonnull status) {
        if (!status.isError) {
            // Message successfully published to specified channel.
            NSLog(@"publish - successfully published data: %@", data);
        } else {
            // Handle message publish error. Check 'category' property to find out possible reason because of which request
            // did fail. Review 'errorData' property (which has PNErrorData data type) of status object to get additional
            // information about issue. Request can be resent using: [status retry]
            NSLog(@"publish - failure publishing data: %@", data);
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
    // Handle new message stored in message.data.message
    if (![message.data.channel isEqualToString:message.data.subscription]) {
        // Message has been received on channel group stored in message.data.subscription.
    } else {
        // Message has been received on channel stored in message.data.channel.
    }
    
    NSLog(@"didReceiveMessage - %@ on channel %@ at %@", message.data.message, message.data.channel, message.data.timetoken);
}

// New presence event handling.
- (void)client:(PubNub *)client didReceivePresenceEvent:(PNPresenceEventResult *)event {
    if (![event.data.channel isEqualToString:event.data.subscription]) {
        // Presence event has been received on channel group stored in event.data.subscription.
    } else {
        // Presence event has been received on channel stored in event.data.channel.
    }
    
    if (![event.data.presenceEvent isEqualToString:@"state-change"]) {
        NSLog(@"%@ \"%@'ed\"\nat: %@ on %@ (Occupancy: %@)", event.data.presence.uuid,
              event.data.presenceEvent, event.data.presence.timetoken, event.data.channel,
              event.data.presence.occupancy);
    } else {
        NSLog(@"%@ changed state at: %@ on %@ to: %@", event.data.presence.uuid, event.data.presence.timetoken, event.data.channel, event.data.presence.state);
    }
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
