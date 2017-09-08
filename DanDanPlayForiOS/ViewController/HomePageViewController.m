//
//  HomePageViewController.m
//  DanDanPlayForiOS
//
//  Created by JimHuang on 2017/9/2.
//  Copyright © 2017年 JimHuang. All rights reserved.
//

#import "HomePageViewController.h"
#import "HomePageItemViewController.h"
#import "JHDefaultPageViewController.h"
#import "WebViewController.h"
#import "HomePageSearchViewController.h"

#import "MJRefreshHeader+Tools.h"
#import "NSDate+Tools.h"
#import "JHEdgeButton.h"

#define HEAD_VIEW_HEIGHT (self.view.height * .4)

@interface HomePageViewController ()<WMPageControllerDelegate, WMPageControllerDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>
@property (strong, nonatomic) JHDefaultPageViewController *pageViewController;
@property (strong, nonatomic) JHHomePage *model;
@end

@implementation HomePageViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"新番列表";
    self.edgesForExtendedLayout = UIRectEdgeTop | UIRectEdgeLeft | UIRectEdgeRight;
    
    [self configRightItem];
    
    [self.view addSubview:self.pageViewController.view];
    
    [self requestHomePageWithAnimate:YES completion:^{
        [self.pageViewController reloadData];
    }];
    
    [[CacheManager shareCacheManager] addObserver:self forKeyPath:@"user" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"user"]) {
        [self requestHomePageWithAnimate:NO completion:^{
            [self.pageViewController reloadData];
        }];
    }
}

- (void)dealloc {
    [[CacheManager shareCacheManager] removeObserver:self forKeyPath:@"user"];
}

- (void)configLeftItem {
    
}

#pragma mark - WMPageControllerDataSource
- (NSInteger)numbersOfChildControllersInPageController:(WMPageController *)pageController {
    return self.model.bangumis.count;
}

- (__kindof UIViewController *)pageController:(WMPageController *)pageController viewControllerAtIndex:(NSInteger)index {
    HomePageItemViewController *vc = [[HomePageItemViewController alloc] init];
    vc.bangumis = [self bangumiCollectionWithIndex:index].collection;
    @weakify(vc)
    @weakify(self)
    vc.handleBannerCallBack = ^() {
        @strongify(self)
        if (!self) return;
        
        [self requestHomePageWithAnimate:NO completion:^{
            [weak_vc endRefresh];
        }];
    };
    
    vc.endRefreshCallBack = ^{
        @strongify(self)
        if (!self) return;
        
        [self.pageViewController reloadData];
    };
    
    return vc;
}


- (NSString *)pageController:(WMPageController *)pageController titleAtIndex:(NSInteger)index {
    JHBangumiCollection *model = [self bangumiCollectionWithIndex:index];
    return model.weekDayStringValue;
}

- (CGRect)pageController:(WMPageController *)pageController preferredFrameForMenuView:(WMMenuView *)menuView {
    return CGRectMake(0, 0, self.view.width, NORMAL_SIZE_FONT.lineHeight + 20);
}

- (CGRect)pageController:(WMPageController *)pageController preferredFrameForContentView:(WMScrollView *)contentView {
    const float menuViewHeight = CGRectGetMaxY([self pageController:pageController preferredFrameForMenuView:pageController.menuView]);
    return CGRectMake(0, menuViewHeight, self.view.width, self.view.height - menuViewHeight);
}

#pragma mark - DZNEmptyDataSetSource
- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"暂无数据" attributes:@{NSFontAttributeName : NORMAL_SIZE_FONT, NSForegroundColorAttributeName : [UIColor lightGrayColor]}];
    return str;
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"点击重试" attributes:@{NSFontAttributeName : SMALL_SIZE_FONT, NSForegroundColorAttributeName : [UIColor lightGrayColor]}];
    return str;
}

#pragma mark - DZNEmptyDataSetDelegate
- (void)emptyDataSet:(UIScrollView *)scrollView didTapView:(UIView *)view {
    [self requestHomePageWithAnimate:YES completion:^{
        [self.pageViewController reloadData];
    }];
}

#pragma mark - 私有方法
- (JHBangumiCollection *)bangumiCollectionWithIndex:(NSInteger)index {
    NSInteger week = [NSDate currentWeekDay];
    if (week < 0 || week > 7) {
        return self.model.bangumis[index];
    }
    index = (index + week) % self.model.bangumis.count;
    return self.model.bangumis[index];
}

- (void)requestHomePageWithAnimate:(BOOL)animate
                        completion:(dispatch_block_t)completion {
    if (animate) {
        [MBProgressHUD showLoadingInView:self.view text:nil];
    }
    
    [RecommedNetManager recommedInfoWithCompletionHandler:^(JHHomePage *responseObject, NSError *error) {
        if (animate) {
            [MBProgressHUD hideLoading];
        }
        
        if (error) {
            [MBProgressHUD showWithError:error atView:self.view];
            ((void (*)(id, SEL))(void *) objc_msgSend)((id)self.pageViewController, NSSelectorFromString(@"wm_addScrollView"));
            UIScrollView *view = self.pageViewController.scrollView;
            view.emptyDataSetSource = self;
            view.emptyDataSetDelegate = self;
            view.frame = self.view.bounds;
            [view reloadEmptyDataSet];
        }
        else {
            self.model = responseObject;
        }
        
        if (completion) {
            completion();
        }
    }];
}

- (void)configRightItem {
    JHEdgeButton *backButton = [[JHEdgeButton alloc] init];
    backButton.inset = CGSizeMake(10, 10);
    [backButton addTarget:self action:@selector(touchRightItem:) forControlEvents:UIControlEventTouchUpInside];
    [backButton setBackgroundImage:[UIImage imageNamed:@"search"] forState:UIControlStateNormal];
    [backButton sizeToFit];
    
    UIBarButtonItem *spaceBar = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spaceBar.width = -2;
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.navigationItem.rightBarButtonItems = @[spaceBar, item];
}

- (void)touchRightItem:(UIButton *)button {
    HomePageSearchViewController *vc = [[HomePageSearchViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - 懒加载
- (JHDefaultPageViewController *)pageViewController {
    if (_pageViewController == nil) {
        _pageViewController = [[JHDefaultPageViewController alloc] init];
        _pageViewController.delegate = self;
        _pageViewController.dataSource = self;
        [self addChildViewController:_pageViewController];
    }
    return _pageViewController;
}

@end
