//
//  DDPVideoModel+Tools.m
//  DanDanPlayForiOS
//
//  Created by JimHuang on 2018/2/16.
//  Copyright © 2018年 JimHuang. All rights reserved.
//

#import "DDPVideoModel+Tools.h"
#import "DDPCacheManager+multiply.h"

@implementation DDPVideoModel (Tools)

- (NSUInteger)relevanceEpisodeId {
    DDPVideoCache *cache = [[DDPCacheManager shareCacheManager] relevanceCacheWithVideoModel:self];
    return cache.identity;
}

- (NSString *)relevanceName {
    DDPVideoCache *cache = [[DDPCacheManager shareCacheManager] relevanceCacheWithVideoModel:self];
    return cache.name;
}

- (NSString *)relevanceHash {
    DDPVideoCache *cache = [[DDPCacheManager shareCacheManager] relevanceCacheWithVideoModel:self];
    return cache.fileHash;
}

- (NSInteger)lastPlayTime {
    DDPVideoCache *cache = [[DDPCacheManager shareCacheManager] relevanceCacheWithVideoModel:self];
    return cache.lastPlayTime;
}

- (void)lastPlayTimeWithBlock:(void (^)(NSInteger))action {
    if (self.isCacheHash) {
        if (action) {
            action(self.lastPlayTime);
        }
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSInteger time = self.lastPlayTime;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (action) {
                action(time);
            }
        });
    });
}

@end
