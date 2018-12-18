//
//  WYAPopViewController.m
//  WYAKit_Example
//
//  Created by 李世航 on 2018/11/16.
//  Copyright © 2018 WYATeam. All rights reserved.
//

#import "WYAPopViewController.h"
#import "WYATestViewController.h"
#import "WYAIMGCodeViewController.h"
@interface WYAPopViewController ()<UIPopoverPresentationControllerDelegate>

@end

@implementation WYAPopViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self wya_addRightNavBarButtonWithNormalImage:@[@"iocn_saoyisao"] highlightedImg:nil];
    
    
}

- (void)wya_customrRightBarButtonItemPressed:(UIButton *)sender{
    WYATestViewController * test = [[WYATestViewController alloc]init];
    test.preferredContentSize = CGSizeMake(100, 132);
    test.modalPresentationStyle = UIModalPresentationPopover;
    __block WYATestViewController * vc = test;
    test.popCallback = ^(NSIndexPath * _Nonnull indexPath) {
        [vc dismissViewControllerAnimated:YES completion:nil];
        if (indexPath.row == 0) {
            WYAQRCodeViewController * qr = [[WYAQRCodeViewController alloc]init];
            [self presentViewController:qr animated:YES completion:nil];
        }else if (indexPath.row == 1) {
            WYAIMGCodeViewController * imgCode = [[WYAIMGCodeViewController alloc]init];
            [self.navigationController pushViewController:imgCode animated:YES];
        }
        
    };
    UIPopoverPresentationController * popover = [test popoverPresentationController];
    popover.delegate = self;
    popover.permittedArrowDirections = UIPopoverArrowDirectionAny;//设置箭头位置
    popover.sourceView = sender;//设置目标视图
    popover.sourceRect = sender.bounds;//弹出视图显示位置
    popover.backgroundColor = [UIColor whiteColor];//设置弹窗背景颜色
    [self presentViewController:test animated:YES completion:nil];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller{
    
    return UIModalPresentationNone;
    
}

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController{
}

// Called on the delegate when the popover controller will dismiss the popover. Return NO to prevent the
// dismissal of the view.
- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController{
    return YES;
}

// Called on the delegate when the user has taken action to dismiss the popover. This is not called when the popover is dimissed programatically.
- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController{
    
}

// -popoverPresentationController:willRepositionPopoverToRect:inView: is called on your delegate when the
// popover may require a different view or rectangle.
- (void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView  * __nonnull * __nonnull)view{
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
