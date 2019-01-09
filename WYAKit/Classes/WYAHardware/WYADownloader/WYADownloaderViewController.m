//
//  WYADownloaderViewController.m
//  WYAKit
//
//  Created by 李世航 on 2019/1/7.
//

#import "WYADownloaderViewController.h"
#import "WYADownloadModel.h"
#import "WYADownloadedViewController.h"
#import "WYADownloader.h"
#import "WYADownloadingViewController.h"
#import "WYAProgressView.h"

@interface WYADownloaderViewController () <WYANavBarDelegate>
@property (nonatomic, strong) WYANavBar * customNavBar;
@property (nonatomic, strong) UILabel * cacheLabel;
@property (nonatomic, strong) WYAProgressView * cacheProgressView;
@end

@implementation WYADownloaderViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
}
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navBar          = [[WYANavBar alloc] init];
    self.navBar.navTitle = @"下载管理器";
    [self.navBar wya_goBackButtonWithImage:@"返回"];
    self.navBar.delegate = self;
    [self.view addSubview:self.navBar];
    [self.view addSubview:self.cacheProgressView];
    [self.view addSubview:self.cacheLabel];

    [self setupCacheLabel];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    CGFloat cacheLabel_X      = 0;
    CGFloat cacheLabel_Y      = self.view.cmam_height - 30 - WYABottomHeight;
    CGFloat cacheLabel_Width  = ScreenWidth;
    CGFloat cacheLabel_Height = 30;
    self.cacheLabel.frame     = CGRectMake(cacheLabel_X, cacheLabel_Y, cacheLabel_Width, cacheLabel_Height);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupCacheLabel
{
    double allMemory           = [NSString wya_phoneFreeMemory];
    NSString * allSize         = [NSString stringWithFormat:@"%2.fG", allMemory];
    WYADownloader * downloader = [WYADownloader sharedDownloader];
    double size                = [downloader.floder wya_fileSize] / 1024 / 1024;

    NSString * useSize               = [NSString stringWithFormat:@"%2.fM", size];
    NSString * string                = [NSString stringWithFormat:@"已下载%@,可用空间%@", useSize, allSize];
    NSMutableAttributedString * text = [[NSMutableAttributedString alloc] initWithString:string];
    [text addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:[string rangeOfString:useSize]];
    [text addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:[string rangeOfString:allSize]];
    self.cacheLabel.attributedText  = text;
    self.cacheProgressView.progress = (size / 1024) / allMemory;
}

- (void)wya_goBackPressed:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark ======= delegate
- (NSInteger)wya_numberOfTitlesInMenuView:(WYAMenuView *)menu
{
    return 2;
}
- (NSInteger)wya_numbersOfChildControllersInPageController:(WYAPageController *)pageController
{
    return 2;
}
- (NSString *)wya_pageController:(WYAPageController *)pageController titleAtIndex:(NSInteger)index
{
    switch (index % 2) {
        case 0: return @"下载中";
        case 1: return @"已完成";
    }
    return @"NONE";
}

- (UIViewController *)wya_pageController:(WYAPageController *)pageController viewControllerAtIndex:(NSInteger)index
{
    switch (index % 2) {
        case 0: {
            WYADownloadingViewController * download = [[WYADownloadingViewController alloc] init];
            WeakSelf(weakSelf);
            download.loadCacheCallback = ^{
                [weakSelf setupCacheLabel];
            };
            return download;
        }

        case 1: {
            WYADownloadedViewController * vc = [[WYADownloadedViewController alloc] init];
            WeakSelf(weakSelf);
            vc.loadCacheCallback = ^{
                [weakSelf setupCacheLabel];
            };
            return vc;
        }
    }
    return [[UIViewController alloc] init];
}

- (CGFloat)wya_menuView:(WYAMenuView *)menu widthForItemAtIndex:(NSInteger)index
{
    CGFloat width = [super wya_menuView:menu widthForItemAtIndex:index];
    return width + 20;
}
- (CGRect)wya_pageController:(WYAPageController *)pageController preferredFrameForMenuView:(WYAMenuView *)menuView
{
    CGFloat leftMargin = self.showOnNavigationBar ? 50 : 0;
    CGFloat originY    = self.showOnNavigationBar ? 0 : WYATopHeight;
    return CGRectMake(leftMargin, originY, self.view.frame.size.width - 2 * leftMargin, WYANavBarHeight);
}

- (CGRect)wya_pageController:(WYAPageController *)pageController preferredFrameContentView:(WYAPageScrollView *)contentView
{
    CGFloat originY = CGRectGetMaxY([self wya_pageController:pageController preferredFrameForMenuView:self.menuView]);
    return CGRectMake(0, originY, self.view.frame.size.width, self.view.frame.size.height - originY - 30);
}

#pragma mark - Getter -
- (UILabel *)cacheLabel
{
    if (!_cacheLabel) {
        _cacheLabel = ({
            UILabel * object       = [[UILabel alloc] init];
            object.backgroundColor = [UIColor clearColor];
            object.textAlignment   = NSTextAlignmentCenter;
            object;
        });
    }
    return _cacheLabel;
}

- (WYAProgressView *)cacheProgressView
{
    if (!_cacheProgressView) {
        _cacheProgressView = ({
            CGFloat cacheLabel_X      = 0;
            CGFloat cacheLabel_Y      = self.view.cmam_height - 30 - WYABottomHeight;
            CGFloat cacheLabel_Width  = ScreenWidth;
            CGFloat cacheLabel_Height = 30;
            CGRect rect               = CGRectMake(cacheLabel_X, cacheLabel_Y, cacheLabel_Width, cacheLabel_Height);
            WYAProgressView * object  = [[WYAProgressView alloc] initWithFrame:rect progressViewStyle:WYAProgressViewStyleStraight];
            object.progressTintColor  = [UIColor redColor];
            object.trackTintColor     = random(244, 244, 244, 1);
            object;
        });
    }
    return _cacheProgressView;
}
@end
