//
//  WYATestViewController.h
//  WYAKit_Example
//
//  Created by 李世航 on 2018/11/16.
//  Copyright © 2018 WYATeam. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WYATestViewController : UIViewController
@property (nonatomic, copy) void (^popCallback)(NSIndexPath * indexPath);
@end

NS_ASSUME_NONNULL_END
