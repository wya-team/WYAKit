//
//  ImagePickerViewController.h
//  ImagePickerDemo
//
//  Created by 李世航 on 2018/6/14.
//  Copyright © 2018年 WeiYiAn. All rights reserved.
//

#import "WYAPhotoBrowserModel.h"
#import <Photos/Photos.h>
#import <UIKit/UIKit.h>

@interface WYAPhotoBrowserViewController : UIViewController
@property (nonatomic, strong) WYAPhotoBrowserAlbumModel * album;
@end
