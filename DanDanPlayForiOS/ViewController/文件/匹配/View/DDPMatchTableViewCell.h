//
//  DDPMatchTableViewCell.h
//  DanDanPlayForiOS
//
//  Created by JimHuang on 2017/4/20.
//  Copyright © 2017年 JimHuang. All rights reserved.
//

#import "DDPOtherSettingTitleSubtitleTableViewCell.h"

@interface DDPMatchTableViewCell : UITableViewCell
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *detailLabel;
@property (strong, nonatomic) DDPMatch *model;
@end
