//
//  CacheManager.h
//  DanDanPlayForiOS
//
//  Created by JimHuang on 2017/4/19.
//  Copyright © 2017年 JimHuang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JHBaseDanmaku.h"
#import "JHSMBInfo.h"

/**
 视频播放模式

 - PlayerPlayModeSingle: 单集播放
 - PlayerPlayModeSingleCircle: 单集循环
 - PlayerPlayModeCircle: 列表循环
 - PlayerPlayModeOrder: 顺序播放
 */
typedef NS_ENUM(NSUInteger, PlayerPlayMode) {
    PlayerPlayModeSingle,
    PlayerPlayModeSingleCircle,
    PlayerPlayModeCircle,
    PlayerPlayModeOrder,
};

typedef NS_ENUM(NSUInteger, SMBDownloadTasksDidChangeType) {
    SMBDownloadTasksDidChangeTypeAdd,
    SMBDownloadTasksDidChangeTypeRemove,
};

typedef NS_ENUM(NSUInteger, CollectionCacheDidChangeType) {
    CollectionCacheDidChangeTypeAdd,
    CollectionCacheDidChangeTypeRemove,
};

FOUNDATION_EXPORT NSString *const videoNameKey;
FOUNDATION_EXPORT NSString *const videoEpisodeIdKey;

//缓存所有弹幕的标识
#define CACHE_ALL_DANMAKU_FLAG 9999

@class JHUser, JHFile, TOSMBSessionFile, TOSMBSessionDownloadTask, JHMediaPlayer, JHCollectionCache, JHSMBFileHashCache;

@protocol CacheManagerDelagate <NSObject>
@optional
- (void)SMBDownloadTasksDidChange:(NSArray <TOSMBSessionDownloadTask *>*)tasks type:(SMBDownloadTasksDidChangeType)type;
- (void)SMBDownloadTasksDidDownloadCompletion;
- (void)lastPlayTimeWithVideoModel:(VideoModel *)videoModel time:(NSInteger)time;
- (void)collectionDidHandleCache:(JHCollectionCache *)cache operation:(CollectionCacheDidChangeType)operation;
@end

@interface CacheManager : NSObject

/**
 当前登录的用户
 */
@property (strong, nonatomic) JHUser *user;

/**
 上次登录的用户
 */
@property (strong, nonatomic) JHUser *lastLoginUser;

@property (weak, nonatomic) JHMediaPlayer *mediaPlayer;
/**
 连接信息
 */
@property (strong, nonatomic) JHLinkInfo *linkInfo;

/**
 弹幕字体
 */
@property (strong, nonatomic) UIFont *danmakuFont;

/**
 弹幕边缘特效
 */
@property (assign, nonatomic) JHDanmakuShadowStyle danmakuShadowStyle;

/**
 字幕保护区域
 */
@property (assign, nonatomic) BOOL subtitleProtectArea;


/**
 弹幕缓存时间 默认7天
 */
@property (assign, nonatomic) NSUInteger danmakuCacheTime;

/**
 自动请求第三方弹幕
 */
@property (assign, nonatomic) BOOL autoRequestThirdPartyDanmaku;

/**
 是否打开快速匹配
 */
@property (assign, nonatomic) BOOL openFastMatch;

/**
 是否自动下载远程设备字幕
 */
@property (assign, nonatomic) BOOL openAutoDownloadSubtitle;

/**
 使用touchId登录
 */
@property (assign, nonatomic) BOOL useTouchIdLogin;


/**
 显示下载状态视图
 */
@property (assign, nonatomic) BOOL showDownloadStatusView;

/**
 播放器播放模式
 */
@property (assign, nonatomic) PlayerPlayMode playMode;

/**
 弹幕速度
 */
@property (assign, nonatomic) float danmakuSpeed;

/**
 弹幕不透明度
 */
@property (assign, nonatomic) float danmakuOpacity;


/**
 选择的弹幕颜色
 */
@property (strong, nonatomic) UIColor *sendDanmakuColor;

/**
 选择的弹幕类型
 */
@property (assign, nonatomic) JHDanmakuMode sendDanmakuMode;


/**
 同屏弹幕数量 默认14
 */
@property (assign, nonatomic) NSUInteger danmakuLimitCount;


/**
 播放页默认旋屏位置
 */
@property (assign, nonatomic) UIInterfaceOrientation playInterfaceOrientation;

/**
 存储文件夹名称和文件hash
 */
@property (strong, nonatomic) NSMutableDictionary <NSString *, NSMutableArray <NSString *>*>*folderCache;

/**
 弹幕过滤
 */
@property (strong, nonatomic, readonly) NSArray <JHFilter *>*danmakuFilters;
- (void)addFilter:(JHFilter *)model;
- (void)addFilters:(NSArray <JHFilter *>*)models;
- (void)addFilters:(NSArray <JHFilter *>*)models atHeader:(BOOL)atHeader;
- (void)removeFilter:(JHFilter *)model;
- (void)removeFilters:(NSArray <JHFilter *>*)models;
- (void)updateFilter:(JHFilter *)model;

/**
 关联视频和本地节目id

 @param episodeId 节目id
 @param episodeId 节目名称
 @param model 视频模型
 */
- (void)saveEpisodeId:(NSUInteger)episodeId episodeName:(NSString *)episodeName videoModel:(VideoModel *)model;
/**
 获取缓存中的关联 videoNameKey 视频名称 videoEpisodeIdKey 节目id
 
 @param model 视频模型
 @return 关联的id
 */
- (NSDictionary *)episodeInfoWithVideoModel:(VideoModel *)model;

//存储上次播放时间
- (void)saveLastPlayTime:(NSInteger)time videoModel:(VideoModel *)model;
- (NSInteger)lastPlayTimeWithVideoModel:(VideoModel *)model;


/**
 smb共享登录信息
 */
@property (strong, nonatomic) NSArray <JHSMBInfo *>*SMBInfos;
- (void)saveSMBInfo:(JHSMBInfo *)info;
- (void)removeSMBInfo:(JHSMBInfo *)info;


/**
 保存smb文件Hash

 @param hash hash
 @param file smb文件
 */
- (void)saveSMBFileHashWithHash:(NSString *)hash file:(TOSMBSessionFile *)file;

/**
 获取smb文件hash

 @param file smb文件
 @return hash
 */
- (NSString *)SMBFileHash:(TOSMBSessionFile *)file;

//当前分析的视频模型
@property (strong, nonatomic) VideoModel *currentPlayVideoModel;

- (NSMutableArray <JHCollectionCache *>*)collectionList;
- (NSError *)addCollectionCache:(JHCollectionCache *)cache;
- (NSError *)removeCollectionCache:(JHCollectionCache *)cache;

/**
 缓存大小

 @return byte
 */
+ (NSUInteger)cacheSize;
+ (void)removeAllCache;

- (void)addObserver:(id<CacheManagerDelagate>)observer;
- (void)removeObserver:(id<CacheManagerDelagate>)observer;
- (void)addSMBSessionDownloadTask:(TOSMBSessionDownloadTask *)task;
- (void)addSMBSessionDownloadTasks:(NSArray <TOSMBSessionDownloadTask *>*)tasks;
- (void)removeSMBSessionDownloadTasks:(NSArray <TOSMBSessionDownloadTask *>*)tasks;
- (void)removeSMBSessionDownloadTask:(TOSMBSessionDownloadTask *)task;
- (NSArray <TOSMBSessionDownloadTask *>*)downloadTasks;

@property (assign, nonatomic) NSUInteger totoalExpectedToReceive;
@property (assign, nonatomic) NSUInteger totoalToReceive;

//@property (assign, nonatomic) NSUInteger linkTotoalExpectedToReceive;
//@property (assign, nonatomic) NSUInteger linkTotoalToReceive;
@property (assign, nonatomic) NSUInteger linkDownloadingTaskCount;
- (BOOL)timerIsStart;
- (void)addLinkDownload;
- (void)updateLinkDownloadInfo;

+ (instancetype)shareCacheManager;
@end
