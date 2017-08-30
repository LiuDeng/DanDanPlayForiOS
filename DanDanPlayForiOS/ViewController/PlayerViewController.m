//
//  PlayerViewController.m
//  DanDanPlayForiOS
//
//  Created by JimHuang on 2017/4/21.
//  Copyright © 2017年 JimHuang. All rights reserved.
//

#import "PlayerViewController.h"
#import "MatchViewController.h"
#import "LocalFileManagerPickerViewController.h"
#import "SMBFileManagerPickerViewController.h"
#import "PlayerSelectedColorViewController.h"

#import "PlayerInterfaceView.h"
#import "JHMediaPlayer.h"
#import "JHDanmakuRender.h"
#import "DanmakuManager.h"
#import "PlayerConfigPanelView.h"
#import "PlayerSendDanmakuConfigView.h"
#import "PlayerSubTitleIndexView.h"
#import "PlayerNoticeView.h"

#import "SMBVideoModel.h"
#import "NSString+Tools.h"
#import <MediaPlayer/MediaPlayer.h>
#import "NSURL+Tools.h"
#import "JHBaseDanmaku+Tools.h"

static const float slowRate = 0.05f;
static const float normalRate = 0.2f;
static const float fastRate = 0.6f;

typedef NS_ENUM(NSUInteger, InterfaceViewPanType) {
    InterfaceViewPanTypeInactive,
    InterfaceViewPanTypeProgress,
    InterfaceViewPanTypeVolume,
    InterfaceViewPanTypeLight,
};

@interface PlayerViewController ()<JHMediaPlayerDelegate, JHDanmakuEngineDelegate, PlayerConfigPanelViewDelegate, PlayerInterfaceViewDelegate>
@property (strong, nonatomic) PlayerInterfaceView *interfaceView;
@property (strong, nonatomic) JHMediaPlayer *player;
@property (strong, nonatomic) JHDanmakuEngine *danmakuEngine;
@end

@implementation PlayerViewController
{
    //进度条是否不响应通知
    BOOL _isSliderNoActionNotice;
    NSMutableDictionary <NSNumber *, NSMutableArray<JHBaseDanmaku *>*> *_danmakuDic;
    NSInteger _currentTime;
    //滑动速率
    float _sliderRate;
    InterfaceViewPanType _panType;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setNavigationBarWithColor:[UIColor clearColor]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.player.isPlaying == NO) {
        [self.player play];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.player.isPlaying) {
        [self.player pause];
    }
}

- (BOOL)prefersStatusBarHidden {
    return !_interfaceView.isShow;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _currentTime = -1;
    self.view.backgroundColor = [UIColor blackColor];
    
    NSArray *keyPaths = @[@"danmakuFont", @"danmakuSpeed", @"danmakuShadowStyle", @"danmakuOpacity"];
    [keyPaths enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [[CacheManager shareCacheManager] addObserver:self forKeyPath:obj options:NSKeyValueObservingOptionNew context:nil];
    }];
    
    [self.danmakuEngine.canvas mas_makeConstraints:^(MASConstraintMaker *make) {
        if ([CacheManager shareCacheManager].subtitleProtectArea) {
            make.top.left.right.mas_equalTo(0);
            make.bottom.mas_offset(-HEIGHT * 0.12);
        }
        else {
            make.edges.mas_equalTo(0);
        }
    }];
    
    [self.player.mediaView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    }];
    
    [self.interfaceView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    }];
    
    [self reload];
}

- (void)setModel:(VideoModel *)model {
    
    VideoModel *oldVideoModel = _model;
    //保存上次播放时间
    _model = model;
    [CacheManager shareCacheManager].currentPlayVideoModel = _model;
    
    if (self.isViewLoaded) {
        [[CacheManager shareCacheManager] saveLastPlayTime:self.player.currentTime videoModel:oldVideoModel];
        [self reload];
        [self.player play];
    }
}

- (void)dealloc {
    //保存上次播放时间
    [[CacheManager shareCacheManager] saveLastPlayTime:self.player.currentTime videoModel:_model];
    
    self.player.speed = 1.0;
    [self.player stop];
    [self.danmakuEngine stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSArray *keyPaths = @[@"danmakuFont", @"danmakuSpeed", @"danmakuShadowStyle", @"danmakuOpacity"];
    [keyPaths enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [[CacheManager shareCacheManager] removeObserver:self forKeyPath:obj];
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"danmakuFont"]) {
        UIFont *font = change[NSKeyValueChangeNewKey];
        self.danmakuEngine.globalFont = font;
    }
    else if ([keyPath isEqualToString:@"danmakuSpeed"]) {
        float speed = [change[NSKeyValueChangeNewKey] floatValue];
        [self.danmakuEngine setSpeed:speed];
        NSLog(@"弹幕速度 %f", speed);
    }
    else if ([keyPath isEqualToString:@"danmakuShadowStyle"]) {
        JHDanmakuShadowStyle style = [change[NSKeyValueChangeNewKey] integerValue];
        self.danmakuEngine.globalShadowStyle = style;
    }
    else if ([keyPath isEqualToString:@"danmakuOpacity"]) {
        self.danmakuEngine.canvas.alpha = [change[NSKeyValueChangeNewKey] floatValue];
    }
}

#pragma mark - JHMediaPlayerDelegate
- (void)mediaPlayer:(JHMediaPlayer *)player progress:(float)progress currentTime:(NSString *)currentTime totalTime:(NSString *)totalTime {
    self.interfaceView.currentTimeLabel.text = currentTime;
    self.interfaceView.totalTimeLabel.text = totalTime;
    if (_isSliderNoActionNotice == NO) {
        self.interfaceView.progressSlider.value = progress;
    }
    
}

- (void)mediaPlayer:(JHMediaPlayer *)player statusChange:(JHMediaPlayerStatus)status {
    switch (status) {
        case JHMediaPlayerStatusPlaying:
        {
            self.interfaceView.playButton.selected = NO;
            [self.danmakuEngine start];
        }
            break;
        case JHMediaPlayerStatusStop:
        {
            PlayerPlayMode mode = [CacheManager shareCacheManager].playMode;
            //单集循环
            if (mode == PlayerPlayModeSingleCircle) {
                self.model = self.model;
            }
            //列表循环
            else if (mode == PlayerPlayModeCircle) {
                JHFile *currentFile = self.model.file;
                JHFile *parentFile = currentFile.parentFile;
                NSInteger index = [parentFile.subFiles indexOfObject:currentFile];
                
                if (index != NSNotFound) {
                    NSInteger count = parentFile.subFiles.count;
                    //找到下一个是视频的模型
                    for (NSInteger i = 0; i < count; ++i) {
                        currentFile = parentFile.subFiles[(i + 1 + index) % count];
                        if (currentFile.type == JHFileTypeDocument && jh_isVideoFile(currentFile.fileURL.absoluteString)) {
                            [self playerConfigPanelView:self.interfaceView.configPanelView didSelectedModel:currentFile.videoModel];
                            return;
                        }
                    }
                }
            }
            else if (mode == PlayerPlayModeOrder) {
                JHFile *currentFile = self.model.file;
                JHFile *parentFile = currentFile.parentFile;
                NSInteger index = [parentFile.subFiles indexOfObject:currentFile];
                if (index != NSNotFound) {
                    NSInteger count = parentFile.subFiles.count;
                    //找到下一个是视频的模型
                    for (NSInteger i = index + 1; i < count; ++i) {
                        currentFile = parentFile.subFiles[i];
                        if (currentFile.type == JHFileTypeDocument && jh_isVideoFile(currentFile.fileURL.absoluteString)) {
                            [self playerConfigPanelView:self.interfaceView.configPanelView didSelectedModel:currentFile.videoModel];
                            return;
                        }
                    }
                }
            }
        }
            break;
        default:
            self.interfaceView.playButton.selected = YES;
            [self.danmakuEngine pause];
            break;
    }
}

- (void)mediaPlayer:(JHMediaPlayer *)player rateChange:(float)rate {
    self.danmakuEngine.systemSpeed = rate;
}

#pragma mark - JHDanmakuEngineDelegate
- (NSArray <__kindof JHBaseDanmaku*>*)danmakuEngine:(JHDanmakuEngine *)danmakuEngine didSendDanmakuAtTime:(NSUInteger)time {
    if (_currentTime == time) return nil;
    
    _currentTime = time;
    return _danmakuDic[@(time)];
}

- (BOOL)danmakuEngine:(JHDanmakuEngine *)danmakuEngine shouldSendDanmaku:(__kindof JHBaseDanmaku *)danmaku {
    //用户发送
    if (danmaku.sendByUserId != 0) {
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:danmaku.attributedString];
        [str addAttributes:@{NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle), NSUnderlineColorAttributeName : MAIN_COLOR} range:NSMakeRange(0, str.length)];
        danmaku.attributedString = str;
    }
    
    return YES;
}

#pragma mark - PlayerConfigPanelViewDelegate
- (void)playerConfigPanelView:(PlayerConfigPanelView *)view didSelectedModel:(VideoModel *)model {
    //smb文件 获取文件hash值之后再匹配弹幕
    if ([model isKindOfClass:[SMBVideoModel class]]) {
        SMBVideoModel *aVideoModel = (SMBVideoModel *)model;
        JHSMBFile *file = aVideoModel.file;
        
        if (jh_isVideoFile(file.fileURL.absoluteString)) {
            void(^matchVideoAction)(NSString *) = ^(NSString *path) {
                NSString *hash = [[[NSFileHandle fileHandleForReadingAtPath:path] readDataOfLength: MEDIA_MATCH_LENGTH] md5String];
                [[CacheManager shareCacheManager] saveSMBFileHashWithHash:hash file:file.sessionFile];
                SMBVideoModel *model = [[SMBVideoModel alloc] initWithFileURL:file.sessionFile.fullURL hash:hash length:file.sessionFile.fileSize];
                model.file = file;
                [self matchVideoWithModel:model];
            };
            
            //查找是否获取过文件hash
            NSString *hash = [[CacheManager shareCacheManager] SMBFileHash:file.sessionFile];
            if (hash.length) {
                SMBVideoModel *model = [[SMBVideoModel alloc] initWithFileURL:file.sessionFile.fullURL hash:hash length:file.sessionFile.fileSize];
                model.file = file;
                
                [self matchVideoWithModel:model];
            }
            else {
                MBProgressHUD *_aHUD = [MBProgressHUD defaultTypeHUDWithMode:MBProgressHUDModeAnnularDeterminate InView:self.view];
                _aHUD.label.text = @"分析视频中...";
                
                [[ToolsManager shareToolsManager] downloadSMBFile:file progress:^(uint64_t totalBytesReceived, int64_t totalBytesExpectedToReceive, TOSMBSessionDownloadTask *downloadTask) {
                    _aHUD.progress = totalBytesReceived * 1.0 / MIN(totalBytesExpectedToReceive, MEDIA_MATCH_LENGTH);
                    if (totalBytesReceived >= MEDIA_MATCH_LENGTH) {
                        [downloadTask cancel];
                    }
                } cancel:^(NSString *cachePath) {
                    [_aHUD hideAnimated:YES];
                    matchVideoAction(cachePath);
                } completion:^(NSString *destinationFilePath, NSError *error) {
                    [_aHUD hideAnimated:YES];
                    
                    if (error) {
                        [MBProgressHUD showWithError:error];
                    }
                    else {
                        matchVideoAction(destinationFilePath);
                    }
                }];
            }
        }
    }
    else {
        [self matchVideoWithModel:model];
    }
}

- (void)playerConfigPanelView:(PlayerConfigPanelView *)view didTouchStepper:(CGFloat)value {
    self.danmakuEngine.offsetTime = value;
}

- (void)playerConfigPanelViewDidTouchSelectedDanmakuCell {
    @weakify(self)
    [self pickFileWithType:PickerFileTypeDanmaku selectedFileCallBack:^(__kindof JHFile *aFile) {
        @strongify(self)
        if (!self) return;
        
        if ([aFile isKindOfClass:[JHSMBFile class]]) {
            [self downloadDanmakuFile:aFile];
        }
        else {
            [self openDanmakuWithURL:aFile.fileURL];
        }
    }];
}

- (void)playerConfigPanelViewDidTouchMatchCell {
    MatchViewController *vc = [[MatchViewController alloc] init];
    vc.model = self.model;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - PlayerInterfaceViewDelegate
- (void)interfaceViewDidTouchSendDanmakuButton {
    
    PlayerSelectedColorViewController *vc = [[PlayerSelectedColorViewController alloc] init];
    @weakify(self)
    vc.sendDanmakuCallBack = ^(UIColor *color, JHDanmakuMode mode, NSString *text) {
        @strongify(self)
        if (!self) return;
        
        if (text.length) {
            NSUInteger episodeId = self.model.danmakus.identity;
            if (episodeId == 0) {
                NSDictionary *dic = [[CacheManager shareCacheManager] episodeInfoWithVideoModel:self.model];
                episodeId = [dic[videoEpisodeIdKey] integerValue];
            }
            if (episodeId == 0) return;
            
            JHUser *user = [CacheManager shareCacheManager].user;
            
            JHDanmaku *danmaku = [[JHDanmaku alloc] init];
            danmaku.color = color.red * 256 * 256 * 255 + color.green * 256 * 255 + color.blue * 255;
            danmaku.time = self.player.currentTime;
            danmaku.mode = mode;
            danmaku.token = user.token;
            danmaku.userId = user.identity;
            danmaku.message = text;
            //隐藏UI
            [self.interfaceView dismissWithAnimate:YES];
            //发射弹幕
            [CommentNetManager launchDanmakuWithModel:danmaku episodeId:episodeId completionHandler:^(NSError *error) {
                if (error) {
                    [MBProgressHUD showWithText:@"发送失败"];
                }
                else {
                    [MBProgressHUD showWithText:@"发送成功"];
                    JHBaseDanmaku *sendDanmaku = [DanmakuManager converDanmaku:danmaku];
                    sendDanmaku.sendByUserId = [[NSDate date] timeIntervalSince1970];
                    
                    NSUInteger appearTime = (NSInteger)sendDanmaku.appearTime;
                    if (_danmakuDic[@(appearTime)] == nil) {
                        _danmakuDic[@(appearTime)] = [NSMutableArray array];
                    }
                    [_danmakuDic[@(appearTime)] appendObject:sendDanmaku];
                    [self.danmakuEngine sendDanmaku:sendDanmaku];
                }
            }];
        }
    };
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - 私有方法
- (void)reload {
    //转换弹幕
    _danmakuDic = [DanmakuManager converDanmakus:_model.danmakus.collection];
    self.interfaceView.titleLabel.text = _model.name;
    //更换视频
    [self.player setMediaURL:_model.fileURL];
    self.danmakuEngine.currentTime = 0;
    
    //设置匹配名称
    NSString *matchName = _model.matchName;
    [self.interfaceView.matchNoticeView.titleButton setTitle:matchName forState:UIControlStateNormal];
    if (matchName.length) {
        [self.interfaceView.matchNoticeView show];
    }
    
    //设置上次播放时间
    NSInteger lastPlayTime = [[CacheManager shareCacheManager] lastPlayTimeWithVideoModel:_model];
    if (lastPlayTime > 0) {
        [self.interfaceView.lastTimeNoticeView.titleButton setTitle:[NSString stringWithFormat:@"继续观看: %@", jh_mediaFormatterTime((int)lastPlayTime)] forState:UIControlStateNormal];
        @weakify(self)
        [self.interfaceView.lastTimeNoticeView.titleButton addBlockForControlEvents:UIControlEventTouchUpInside block:^(id  _Nonnull sender) {
            @strongify(self)
            if (!self) return;
            
            [self.player jump:(int)lastPlayTime completionHandler:^(NSTimeInterval time) {
                [self.danmakuEngine setCurrentTime:time];
            }];
        }];
        [self.interfaceView.lastTimeNoticeView show];
    }
    
    JHSMBFile *file = _model.file;
    JHSMBFile *parentFile = file.parentFile;
    
    //自动下载远程视频字幕
    if ([CacheManager shareCacheManager].openAutoDownloadSubtitle && [_model isKindOfClass:[SMBVideoModel class]]) {
        NSString *videoPath = file.sessionFile.filePath;
        [parentFile.subFiles enumerateObjectsUsingBlock:^(JHSMBFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *path = obj.sessionFile.filePath;
            if ([path isSubtileFileWithVideoPath:videoPath]) {
                *stop = YES;
                [self downloadSubtitleFile:obj];
            }
        }];
    }
    
    //弹幕
    //    if ([CacheManager shareCacheManager].priorityLoadLocalDanmaku) {
    if ([_model isKindOfClass:[SMBVideoModel class]]) {
        NSString *videoPath = file.sessionFile.filePath;
        [parentFile.subFiles enumerateObjectsUsingBlock:^(JHSMBFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.sessionFile.filePath isDanmakuFileWithVideoPath:videoPath]) {
                *stop = YES;
                [self downloadDanmakuFile:obj];
            }
        }];
    }
    else {
        NSArray *subtitles = [ToolsManager subTitleFileWithLocalURL:file.fileURL];
        if (subtitles.count) {
            [self openDanmakuWithURL:subtitles.firstObject];
        }
    }
    //    }
}

/**
 下载字幕文件
 
 @param file 字幕文件
 */
- (void)downloadSubtitleFile:(JHSMBFile *)file {
    NSString *downloadPath = jh_subtitleDownloadPath();
    NSString *cachePath = [downloadPath stringByAppendingPathComponent:file.name];
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
        [self.player openVideoSubTitlesFromFile:[NSURL fileURLWithPath:cachePath]];
    }
    else {
        [[ToolsManager shareToolsManager] downloadSMBFile:file destinationPath:downloadPath progress:nil cancel:nil completion:^(NSString *destinationFilePath, NSError *error) {
            [self.player openVideoSubTitlesFromFile:[NSURL fileURLWithPath:destinationFilePath]];
        }];
    }
}


/**
 下载弹幕
 
 @param file 弹幕文件
 */
- (void)downloadDanmakuFile:(JHSMBFile *)file {
    NSString *downloadPath = jh_danmakuDownloadPath();
    NSString *cachePath = [downloadPath stringByAppendingPathComponent:file.name];
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
        [self openDanmakuWithURL:[NSURL fileURLWithPath:cachePath]];
    }
    else {
        [[ToolsManager shareToolsManager] downloadSMBFile:file destinationPath:downloadPath progress:nil cancel:nil completion:^(NSString *destinationFilePath, NSError *error) {
            if (error) {
                [MBProgressHUD showWithError:error];
            }
            else {
                [self openDanmakuWithURL:[NSURL fileURLWithPath:destinationFilePath]];
            }
        }];
    }
}


/**
 尝试打开本地弹幕文件
 
 @param url 路径
 */
- (void)openDanmakuWithURL:(NSURL *)url {
    NSError *err;
    NSData *danmaku = [[NSData alloc] initWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&err];
    if (err) {
        [MBProgressHUD showWithText:@"弹幕读取出错"];
    }
    else {
        self->_danmakuDic = [DanmakuManager parseLocalDanmakuWithSource:DanDanPlayDanmakuTypeBiliBili obj:danmaku];
        self.danmakuEngine.currentTime = self.player.currentTime;
    }
}

/**
 查找视频弹幕
 
 @param model 视频模型
 */
- (void)matchVideoWithModel:(VideoModel *)model {
    void(^jumpToMatchVCAction)() = ^{
        MatchViewController *vc = [[MatchViewController alloc] init];
        vc.model = model;
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    };
    
    if ([CacheManager shareCacheManager].openFastMatch) {
        MBProgressHUD *aHUD = [MBProgressHUD defaultTypeHUDWithMode:MBProgressHUDModeAnnularDeterminate InView:self.view];
        [MatchNetManager fastMatchVideoModel:model progressHandler:^(float progress) {
            aHUD.progress = progress;
            aHUD.label.text = danmakusProgressToString(progress);
        } completionHandler:^(JHDanmakuCollection *responseObject, NSError *error) {
            model.danmakus = responseObject;
            [aHUD hideAnimated:NO];
            
            if (responseObject == nil) {
                jumpToMatchVCAction();
            }
            else {
                [self.interfaceView dismissWithAnimate:YES];
                self.model = model;
            }
        }];
    }
    else {
        jumpToMatchVCAction();
    }
}

- (void)configLeftItem {
    
}

- (void)pickFileWithType:(PickerFileType)type
    selectedFileCallBack:(SelectedFileAction)selectedFileCallBack {
    JHFile *file = self.model.file;
    if ([file isKindOfClass:[JHSMBFile class]]) {
        NSMutableArray *vcArr = [NSMutableArray array];
        JHSMBFile *tempFile = file.parentFile;
        do {
            SMBFileManagerPickerViewController *vc = [[SMBFileManagerPickerViewController alloc] init];
            vc.fileType = type;
            vc.selectedFileCallBack = selectedFileCallBack;
            
            NSMutableArray *tempArr = [NSMutableArray arrayWithArray:tempFile.subFiles];
            [tempArr enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(JHSMBFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.type == JHFileTypeDocument) {
                    if ((type & PickerFileTypeDanmaku) && jh_isDanmakuFile(obj.fileURL.absoluteString) == NO) {
                        [tempArr removeObject:obj];
                    }
                    else if ((type & PickerFileTypeSubtitle) && jh_isSubTitleFile(obj.fileURL.absoluteString) == NO) {
                        [tempArr removeObject:obj];
                    }
                }
            }];
            
            JHSMBFile *aFile = [tempFile mutableCopy];
            aFile.subFiles = tempArr;
            
            vc.file = aFile;
            
            tempFile = tempFile.parentFile;
            [vcArr insertObject:vc atIndex:0];
        } while (tempFile != nil);
        [vcArr insertObject:self atIndex:0];
        [self.navigationController setViewControllers:vcArr animated:YES];
    }
    else {
        __block JHFile *tempFile = nil;
        JHSMBFile *parentFile = file.parentFile;
        
        [[ToolsManager shareToolsManager] startDiscovererVideoWithFile:jh_getANewRootFile() type:type completion:^(JHFile *aFile) {
            
            [aFile.subFiles enumerateObjectsUsingBlock:^(__kindof JHFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.fileURL relationshipWithURL:parentFile.fileURL] == NSURLRelationshipSame) {
                    tempFile = obj;
                    *stop = YES;
                }
            }];
            
            //没找到当前文件夹 则显示根目录
            if (tempFile == nil) {
                LocalFileManagerPickerViewController *vc = [[LocalFileManagerPickerViewController alloc] init];
                vc.file = aFile;
                vc.fileType = type;
                vc.selectedFileCallBack = selectedFileCallBack;
                [self.navigationController pushViewController:vc animated:YES ];
            }
            //找到则推出当前文件夹
            else {
                NSMutableArray *vcArr = [NSMutableArray array];
                do {
                    LocalFileManagerPickerViewController *vc = [[LocalFileManagerPickerViewController alloc] init];
                    vc.file = tempFile;
                    vc.fileType = type;
                    vc.selectedFileCallBack = selectedFileCallBack;
                    [vcArr insertObject:vc atIndex:0];
                } while ((tempFile = tempFile.parentFile));
                [vcArr insertObject:self atIndex:0];
                
                [self.navigationController setViewControllers:vcArr animated:YES];
            }
        }];
    }
}

#pragma mark UI

- (void)touchBackButton:(UIButton *)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)touchPlayButton {
    if ([self.player isPlaying]) {
        [self.player pause];
    }
    else {
        [self.player play];
    }
}

- (void)touchSliderDown:(UISlider *)slider {
    _isSliderNoActionNotice = YES;
}

- (void)touchSliderUp:(UISlider *)slider {
    @weakify(self)
    [self.player setPosition:slider.value completionHandler:^(NSTimeInterval time) {
        @strongify(self)
        if (!self) return;
        
        [self.danmakuEngine setCurrentTime:time];
        self->_isSliderNoActionNotice = NO;
        MBProgressHUD *aHUD = [self.view viewWithTag:1000];
        [aHUD hideAnimated:YES];
    }];
}

- (void)touchSlider:(UISlider *)slider {
    MBProgressHUD *aHUD = [self.view viewWithTag:1000];
    if (aHUD == nil) {
        aHUD = [MBProgressHUD defaultTypeHUDWithMode:MBProgressHUDModeDeterminateHorizontalBar InView:self.view];
        aHUD.label.numberOfLines = 0;
        aHUD.tag = 1000;
    }
    
    int length = [self.player length];
    NSString *time = [NSString stringWithFormat:@"%@/%@", jh_mediaFormatterTime(length * slider.value), jh_mediaFormatterTime(length)];
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:time attributes:@{NSFontAttributeName : NORMAL_SIZE_FONT, NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    NSString *speed = nil;
    if (_sliderRate == slowRate) {
        speed = @"\n慢速";
    }
    else if (_sliderRate == normalRate) {
        speed = @"\n中速";
    }
    else {
        speed = @"\n快速";
    }
    
    [str appendAttributedString:[[NSAttributedString alloc] initWithString:speed attributes:@{NSFontAttributeName : SMALL_SIZE_FONT, NSForegroundColorAttributeName : [UIColor whiteColor]}]];
    aHUD.label.attributedText = str;
    aHUD.progress = slider.value;
    
    [self.interfaceView resetTimer];
}

- (void)touchSwitch:(UISwitch *)sender {
    self.danmakuEngine.canvas.hidden = !sender.on;
}

- (void)touchSubTitleIndexButton {
    [self.interfaceView endEditing:YES];
    self.interfaceView.subTitleIndexView.currentVideoSubTitleIndex = self.player.currentSubtitleIndex;
    self.interfaceView.subTitleIndexView.videoSubTitlesIndexes = self.player.subtitleIndexs;
    self.interfaceView.subTitleIndexView.videoSubTitlesNames = self.player.subtitleTitles;
    [self.interfaceView.subTitleIndexView show];
}

- (void)panScreen:(UIPanGestureRecognizer *)panGesture {
    if (panGesture.state == UIGestureRecognizerStateEnded) {
        if (_panType == InterfaceViewPanTypeProgress) {
            [self touchSliderUp:self.interfaceView.progressSlider];
        }
        
        _panType = InterfaceViewPanTypeInactive;
    }
    else {
        if (_panType == InterfaceViewPanTypeInactive) {
            CGPoint translation = [panGesture translationInView:nil];
            CGPoint point = [panGesture locationInView:nil];
            CGPoint velocity = [panGesture velocityInView:nil];
            
            if (fabs(velocity.x) > 30 && fabs(velocity.y) > 30) {
                //横向移动
                if (fabs(translation.y) < 5) {
                    //让slider不响应进度更新
                    [self touchSliderDown:self.interfaceView.progressSlider];
                    _panType = InterfaceViewPanTypeProgress;
                }
                //亮度调节
                else if (point.x < self.view.width / 2) {
                    _panType = InterfaceViewPanTypeLight;
                }
                //音量调节
                else {
                    _panType = InterfaceViewPanTypeVolume;
                }
            }
        }
        else if (_panType == InterfaceViewPanTypeProgress) {
            float y = [panGesture locationInView:self.view].y;
            if (y >= 0 && y <= self.view.height / 3) {
                _sliderRate = slowRate;
            }
            else if (y >= self.view.height / 3 && y <= self.view.height * 2 / 3) {
                _sliderRate = normalRate;
            }
            else {
                _sliderRate = fastRate;
            }
            
            float x = self.player.position + ([panGesture translationInView:nil].x / self.view.width) * _sliderRate;
            self.interfaceView.progressSlider.value = x;
            [self touchSlider:self.interfaceView.progressSlider];
        }
        else {
            float rate = -[panGesture translationInView:nil].y;
            [panGesture setTranslation:CGPointZero inView:nil];
            rate /= self.view.height;
            
            if (_panType == InterfaceViewPanTypeVolume) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                float volume = [MPMusicPlayerController applicationMusicPlayer].volume;
                volume += rate;
                [[MPMusicPlayerController applicationMusicPlayer] setVolume:volume];
#pragma clang diagnostic pop
            }
            else {
                float brightness = [UIScreen mainScreen].brightness;
                brightness += rate;
                [[UIScreen mainScreen] setBrightness:brightness];
            }
        }
    }
}

- (void)tapGesture:(UITapGestureRecognizer *)sender {
    if (self.interfaceView.isShow) {
        [self.interfaceView dismissWithAnimate:YES];
    }
    else {
        [self.interfaceView showWithAnimate:YES];
    }
}


#pragma mark - 懒加载
- (PlayerInterfaceView *)interfaceView {
    if (_interfaceView == nil) {
        _interfaceView = [[PlayerInterfaceView alloc] initWithFrame:self.view.bounds];
        [_interfaceView.backButton addTarget:self action:@selector(touchBackButton:) forControlEvents:UIControlEventTouchUpInside];
        [_interfaceView.playButton addTarget:self action:@selector(touchPlayButton) forControlEvents:UIControlEventTouchUpInside];
        [_interfaceView.progressSlider addTarget:self action:@selector(touchSliderDown:) forControlEvents:UIControlEventTouchDown];
        [_interfaceView.progressSlider addTarget:self action:@selector(touchSliderUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
        [_interfaceView.progressSlider addTarget:self action:@selector(touchSlider:) forControlEvents:UIControlEventValueChanged];
        [_interfaceView.danmakuHideSwitch addTarget:self action:@selector(touchSwitch:) forControlEvents:UIControlEventValueChanged];
        [_interfaceView.subTitleIndexButton addTarget:self action:@selector(touchSubTitleIndexButton) forControlEvents:UIControlEventTouchUpInside];
        
        _interfaceView.configPanelView.delegate = self;
        _interfaceView.delegate = self;
        
        //手势
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
        tapGesture.numberOfTapsRequired = 1;
        [_interfaceView.gestureView addGestureRecognizer:tapGesture];
        
        UITapGestureRecognizer *pauseGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchPlayButton)];
        pauseGesture.numberOfTapsRequired = 2;
        [_interfaceView.gestureView addGestureRecognizer:pauseGesture];
        [tapGesture requireGestureRecognizerToFail:pauseGesture];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panScreen:)];
        [_interfaceView.gestureView addGestureRecognizer:panGesture];
        
        //字幕视图
        @weakify(self)
        [_interfaceView.subTitleIndexView setSelectedIndexCallBack:^(int index) {
            @strongify(self)
            if (!self) return;
            
            self.player.currentSubtitleIndex = index;
        }];
        
        [_interfaceView.subTitleIndexView setDidTapEmptyViewCallBack:^{
            @strongify(self)
            if (!self) return;
            
            [self pickFileWithType:PickerFileTypeSubtitle selectedFileCallBack:^(__kindof JHFile *aFile) {
                @strongify(self)
                if (!self) return;
                
                if ([aFile isKindOfClass:[JHSMBFile class]]) {
                    [self downloadSubtitleFile:aFile];
                }
                else {
                    [self.player openVideoSubTitlesFromFile:aFile.fileURL];
                }
            }];
        }];
        
        [self.view addSubview:_interfaceView];
    }
    return _interfaceView;
}

- (JHMediaPlayer *)player {
    if (_player == nil) {
        _player = [JHMediaPlayer sharePlayer];
        _player.delegate = self;
        [self.view addSubview:_player.mediaView];
    }
    return _player;
}

- (JHDanmakuEngine *)danmakuEngine {
    if (_danmakuEngine == nil) {
        _danmakuEngine = [[JHDanmakuEngine alloc] init];
        _danmakuEngine.delegate = self;
        [_danmakuEngine setSpeed:[CacheManager shareCacheManager].danmakuSpeed];
        _danmakuEngine.canvas.alpha = [CacheManager shareCacheManager].danmakuOpacity;
        [self.view insertSubview:_danmakuEngine.canvas aboveSubview:self.player.mediaView];
    }
    return _danmakuEngine;
}

@end
