//
// Created by Mark Cerqueira on 7/27/16.
//

#import <Foundation/Foundation.h>

extern const int TIME_TO_LIVE;

@interface PatchCache : NSCache

+ (PatchCache *)sharedInstance;

@end