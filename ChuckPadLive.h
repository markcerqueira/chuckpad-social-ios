//
//  ChuckPadLive.h
//  hello-chuckpad
//
//  Created by Mark Cerqueira on 1/7/18.
//

#ifndef ChuckPadLive_h
#define ChuckPadLive_h

#import <Foundation/Foundation.h>

@class ChuckPadLive;
@class LiveSession;

typedef enum {
    LiveStatusConnected,
    LiveStatusDisconnected,
    LiveStatusReconnected,
    LiveStatusUnexpectedlyDisconnected,
    LiveStatusErrorAccessDenied,
    LiveStatusErrorOther
} LiveStatus;

@protocol ChuckPadLiveDelegate <NSObject>

- (void)chuckPadLive:(ChuckPadLive *)chuckPadLive didReceiveStatus:(LiveStatus)liveStatus;

- (void)chuckPadLive:(ChuckPadLive *)chuckPadLive didReceiveData:(id)data;

@end

@interface ChuckPadLive : NSObject

@property (nonatomic) id<ChuckPadLiveDelegate> delegate;

+ (ChuckPadLive *)sharedInstance;

// Returns the ChuckPadLive instance connected to the given LiveSession with callbacks dispatched onto delegate.
- (void)connect:(LiveSession *)liveSession chuckPadLiveDelegate:(id<ChuckPadLiveDelegate>)delegate;

// Publishes data to the Pub/Sub channel.
- (void)publish:(id)data;

// Unsubscribe from the Pub/Sub channel.
- (void)unsubscribe;

@end

#endif /* ChuckPadLive_h */
