//
//  FileManagerSearchView.m
//  DanDanPlayForiOS
//
//  Created by JimHuang on 2017/8/19.
//  Copyright © 2017年 JimHuang. All rights reserved.
//

#import "FileManagerSearchView.h"
#import "FileManagerFileLongViewCell.h"

@interface FileManagerSearchView ()<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
@property (strong, nonatomic) UIView *bgView;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) JHFile *file;
@end

@implementation FileManagerSearchView
{
    JHFile *_tempFile;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _showing = NO;
        
        [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(0);
        }];
        
        [self.searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.mas_equalTo(0);
            make.top.mas_offset(CGRectGetMaxY([UIApplication sharedApplication].statusBarFrame) - 5);
        }];
        
        [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.searchBar.mas_bottom);
            make.left.right.bottom.mas_equalTo(0);
        }];
    }
    return self;
}

- (instancetype)init {
    return [self initWithFrame:[UIScreen mainScreen].bounds];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _tempFile.subFiles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    JHFile *file = _tempFile.subFiles[indexPath.row];
    
    FileManagerFileLongViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FileManagerFileLongViewCell" forIndexPath:indexPath];
    cell.model = file.videoModel;
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100 + 40 * jh_isPad();
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegete respondsToSelector:@selector(searchView:didSelectedFile:)]) {
        [self.delegete searchView:self didSelectedFile:_tempFile.subFiles[indexPath.row]];
    }
    [self dismiss];
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [[ToolsManager shareToolsManager] startSearchVideoWithRootFile:self.file searchKey:searchText completion:^(JHFile *file) {
        _tempFile = file;
        [self.tableView reloadData];
    }];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self dismiss];
}

#pragma mark - 私有方法
- (void)show {
    if (_showing) return;
    
    if (self.superview == nil) {
        [[UIApplication sharedApplication].keyWindow addSubview:self];
    }
    
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    }];
    
    self.alpha = 0;
    [self.searchBar becomeFirstResponder];
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1;
    }];
    
    [[ToolsManager shareToolsManager] startDiscovererVideoWithFile:jh_getANewRootFile() type:PickerFileTypeVideo completion:^(JHFile *file) {
        self.file = file;
    }];
    
    _showing = YES;
}

- (void)dismiss {
    if (_showing == NO) return;
    
    self.searchBar.text = nil;
    [self.searchBar endEditing:YES];
    _tempFile = nil;
    self.file = nil;
    [self.tableView reloadData];
    
    self.alpha = 1;
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
    
    _showing = NO;
}

#pragma mark - 懒加载

- (UIView *)bgView {
    if (_bgView == nil) {
        _bgView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        [self addSubview:_bgView];
    }
    return _bgView;
}

- (UITableView *)tableView {
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        
        [_tableView registerClass:[FileManagerFileLongViewCell class] forCellReuseIdentifier:@"FileManagerFileLongViewCell"];
        _tableView.backgroundView = [[UIView alloc] init];
        @weakify(self)
        UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithActionBlock:^(id  _Nonnull sender) {
            @strongify(self)
            if (!self) return;
            
            [self dismiss];
        }];
        gestureRecognizer.cancelsTouchesInView = NO;
        [_tableView.backgroundView addGestureRecognizer:gestureRecognizer];
        
        [self addSubview:_tableView];
    }
    return _tableView;
}

- (UISearchBar *)searchBar {
    if (_searchBar == nil) {
        _searchBar = [[UISearchBar alloc] init];
        _searchBar.placeholder = @"搜索文件名";
        _searchBar.delegate = self;
        _searchBar.showsCancelButton = YES;
        _searchBar.backgroundImage = [[UIImage alloc] init];
        _searchBar.barTintColor = [UIColor whiteColor];
        _searchBar.tintColor = MAIN_COLOR;
        [self addSubview:_searchBar];
    }
    return _searchBar;
}

@end
