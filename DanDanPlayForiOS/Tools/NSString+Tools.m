//
//  NSString+Tools.m
//  DanDanPlayForiOS
//
//  Created by JimHuang on 2017/4/25.
//  Copyright © 2017年 JimHuang. All rights reserved.
//

#import "NSString+Tools.h"
#import <ifaddrs.h>
#import <arpa/inet.h>

@implementation NSString (Tools)

+ (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

+ (void)bilibiliAidWithPath:(NSString *)path complectionHandler:(void(^)(NSString *aid, NSString *page))completion {
    //http://www.bilibili.com/video/av46431/index_2.html
    if (!path) {
        completion(nil, nil);
    }
    
    NSString *aid;
    NSString *index;
    NSArray *arr = [path componentsSeparatedByString:@"/"];
    for (NSString *obj in arr) {
        if ([obj hasPrefix: @"av"]) {
            aid = [obj substringFromIndex: 2];
        }
        else if ([obj hasPrefix: @"index"]) {
            index = [[obj componentsSeparatedByString: @"."].firstObject componentsSeparatedByString: @"_"].lastObject;
        }
    }
    completion(aid, index);
}

+ (void)acfunAidWithPath:(NSString *)path complectionHandler:(void(^)(NSString *aid, NSString *index))completion {
    if (!path) {
        completion(nil, nil);
    }
    
    NSString *aid;
    NSString *index;
    NSArray *arr = [[path componentsSeparatedByString: @"/"].lastObject componentsSeparatedByString:@"_"];
    if (arr.count == 2) {
        index = arr.lastObject;
        aid = [arr.firstObject substringFromIndex: 2];
    }
    completion(aid, index);
}

- (BOOL)isSubtileFileWithVideoPath:(NSString *)videoPath {
    if (jh_isSubTitleFile(self) == NO || videoPath.length == 0 || self.length < videoPath.length) {
        return NO;
    }
    
    NSString *subtitleName = [self stringByDeletingPathExtension];
    NSString *pathName = [videoPath stringByDeletingPathExtension];
    NSRange range = [subtitleName rangeOfString:pathName];
    
    if (range.location != NSNotFound) {
        return YES;
    }
    return NO;
}

- (BOOL)isDanmakuFileWithVideoPath:(NSString *)videoPath {
    if (jh_isDanmakuFile(self) == NO || videoPath.length == 0 || self.length < videoPath.length) {
        return NO;
    }
    
    NSString *danmakuName = [self stringByDeletingPathExtension];
    NSString *pathName = [videoPath stringByDeletingPathExtension];
    NSRange range = [danmakuName rangeOfString:pathName];
    
    if (range.location != NSNotFound) {
        return YES;
    }
    return NO;
}

- (JHDMHYParse *)parseModel {
    NSURL *url = [NSURL URLWithString:self];
    //url解码
    NSString *query = [url.query stringByURLDecode];
    NSArray <NSString *>*parameter = [query componentsSeparatedByString:@"&"];
    //获取keyword
    __block NSString *keyword = nil;
    [parameter enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj rangeOfString:@"keyword"].location != NSNotFound) {
            keyword = obj;
            *stop = YES;
        }
    }];
    
    //获取team_id
    NSString *value = [keyword componentsSeparatedByString:@"="].lastObject;
    NSMutableArray <NSString *>*values = [value componentsSeparatedByString:@"+"].mutableCopy;
    __block NSString *teamId = nil;
    [values enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj rangeOfString:@"team_id"].location != NSNotFound) {
            teamId = [obj componentsSeparatedByString:@":"].lastObject;
            [values removeObject:obj];
        }
    }];
    
    JHDMHYParse *model = [[JHDMHYParse alloc] init];
    model.keywords = values;
    model.identity = teamId.integerValue;
    return model;
}

@end
