//
//  DDPBaseTreeView.h
//  DanDanPlayForiOS
//
//  Created by JimHuang on 2017/4/20.
//  Copyright © 2017年 JimHuang. All rights reserved.
//

#import <RATreeView/RATreeView.h>
#import "UIScrollView+Base.h"

@interface DDPBaseTreeView : RATreeView
- (void)endRefreshing;
@end


@interface RATreeView (Tools)
@property (strong, nonatomic, readonly) UITableView *ddp_tableView;
@end
