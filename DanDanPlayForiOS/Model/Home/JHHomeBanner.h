//
//  JHHomeBanner.h
//  DanDanPlayForiOS
//
//  Created by JimHuang on 2017/11/26.
//  Copyright © 2017年 JimHuang. All rights reserved.
//  首页banner模型

#import "JHBase.h"

@interface JHHomeBanner : JHBase
/**
 *  desc : 描述
 name : 名字
 */

@property (strong, nonatomic) NSURL *imageURL;
@property (strong, nonatomic) NSURL *link;
@end
