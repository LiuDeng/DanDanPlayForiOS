//
//  DanmakuFilterTableViewCell.m
//  DanDanPlayForiOS
//
//  Created by JimHuang on 2017/8/31.
//  Copyright © 2017年 JimHuang. All rights reserved.
//

#import "DanmakuFilterTableViewCell.h"
#import "JHEdgeButton.h"

@interface DanmakuFilterTableViewCell ()
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIButton *regexButton;
@property (strong, nonatomic) UIButton *enableButton;
@end

@implementation DanmakuFilterTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.mas_offset(10);
            make.bottom.mas_offset(-10);
        }];
        
        [self.regexButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(self.titleLabel);
            make.left.equalTo(self.titleLabel.mas_right).mas_offset(0);
        }];
        
        [self.enableButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(self.titleLabel);
            make.left.equalTo(self.regexButton.mas_right).mas_offset(10);
            make.right.mas_offset(0);
        }];
    }
    return self;
}

- (void)setModel:(JHFilter *)model {
    _model = model;
    self.titleLabel.text = _model.content;
    self.regexButton.selected = _model.isRegex;
    self.enableButton.selected = _model.enable;
}

#pragma mark - 私有方法
- (void)touchEnableButton:(UIButton *)button {
    _model.enable = !_model.enable;
    button.selected = _model.enable;
    if (self.touchEnableButtonCallBack) {
        self.touchEnableButtonCallBack(_model);
    }
}

- (void)touchRegexButton:(UIButton *)button {
    _model.isRegex = !_model.isRegex;
    button.selected = _model.isRegex;
    if (self.touchRegexButtonCallBack) {
        self.touchRegexButtonCallBack(_model);
    }
}

#pragma mark - 懒加载
- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = NORMAL_SIZE_FONT;
        _titleLabel.numberOfLines = 2;
        [_titleLabel setContentCompressionResistancePriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisHorizontal];
        [_titleLabel setContentHuggingPriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisHorizontal];
        [self.contentView addSubview:_titleLabel];
    }
    return _titleLabel;
}

- (UIButton *)regexButton {
    if (_regexButton == nil) {
        JHEdgeButton *aButton = [[JHEdgeButton alloc] init];
        aButton.inset = CGSizeMake(20, 10);
        _regexButton = aButton;
        _regexButton.titleLabel.font = SMALL_SIZE_FONT;
        [_regexButton setTitle:@"正" forState:UIControlStateNormal];
        [_regexButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [_regexButton setTitleColor:MAIN_COLOR forState:UIControlStateSelected];
        [_regexButton addTarget:self action:@selector(touchRegexButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_regexButton];
    }
    return _regexButton;
}

- (UIButton *)enableButton {
    if (_enableButton == nil) {
        JHEdgeButton *aButton = [[JHEdgeButton alloc] init];
        aButton.inset = CGSizeMake(20, 10);
        _enableButton = aButton;
        [_enableButton setImage:[UIImage imageNamed:@"cheak_mark_noselected"] forState:UIControlStateNormal];
        [_enableButton setImage:[UIImage imageNamed:@"cheak_mark_selected"] forState:UIControlStateSelected];
        [_enableButton addTarget:self action:@selector(touchEnableButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_enableButton];
    }
    return _enableButton;
}

@end