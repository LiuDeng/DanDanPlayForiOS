//
//  DDPPlayerDanmakuControlView.h
//  DanDanPlayForiOS
//
//  Created by JimHuang on 2017/4/24.
//  Copyright © 2017年 JimHuang. All rights reserved.
//  弹幕控制面板

#import <UIKit/UIKit.h>

@interface DDPPlayerDanmakuControlView : UIView

/**
 弹幕偏移时间
 */
@property (copy, nonatomic) void(^touchStepperCallBack)(CGFloat value);

/**
 加载本地弹幕
 */
@property (copy, nonatomic) void(^touchSelectedDanmakuCellCallBack)(void);

/**
 手动匹配视频
 */
@property (copy, nonatomic) void(^touchMatchVideoCellCallBack)(void);

/**
 点击筛选弹幕功能
 */
@property (copy, nonatomic) void(^touchFilterDanmakuCellCallBack)(void);

/**
 点击其他设置
 */
@property (copy, nonatomic) void(^touchOtherSettingCellCallBack)(void);
@end
