//
//  LiveSession.h
//  hello-chuckpad
//
//  Created by Mark Cerqueira on 1/3/18.
//

#ifndef LiveSession_h
#define LiveSession_h

@interface LiveSession : NSObject

@property(nonatomic, retain) NSString *sessionGUID;
@property(nonatomic, assign) NSInteger creatorID;
@property(nonatomic, retain) NSString *sessionTitle;
@property(nonatomic, retain) NSString *creatorUsername;
@property(nonatomic, assign) NSInteger state;
@property(nonatomic, assign) NSInteger occupancy;
@property(nonatomic, retain) NSData *sessionData;

// These times are in UTC. When first created, createdAt and lastActive will be equal. As messages are passed on the
// associated PubSub channel, lastActive will update but createdAt will never change.
@property(nonatomic, retain) NSDate *createdAt;
@property(nonatomic, retain) NSDate *lastActive;

- (LiveSession *)initWithDictionary:(NSDictionary *)dictionary;

- (BOOL)isSessionOpen;

- (BOOL)isSessionClosed;

- (NSDictionary *)asDictionary;

@end

#endif /* LiveSession_h */
