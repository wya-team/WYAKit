//
//  UIImage+WYAImage.h
//  QRCodeDemo
//
//  Created by 李世航 on 2018/6/13.
//  Copyright © 2018年 WeiYiAn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Catagory)


/**
 不对外使用

 @param imageName 图片名
 @param className 类名
 @return image
 */
+ (UIImage *)loadBundleImage:(NSString *)imageName ClassName:(NSString *)className;

+ (UIImage *)wya_ImageSizeWithScreenImage:(UIImage *)image;


/**
 将颜色转化为图片

 @param color UIColor对象
 @return Image对象
 */
+ (UIImage *)wya_createImageWithColor:(UIColor * _Nonnull)color;

/**
 根据url获取图片信息
 like this :{
     ColorModel = RGB;
     DPIHeight = 72;
     DPIWidth = 72;
     Depth = 8;
     PixelHeight = 795;
     PixelWidth = 1200;
     "{JFIF}" =     {
     DensityUnit = 1;
     JFIFVersion =         (
     1,
     0,
     1
     );
     XDensity = 72;
     YDensity = 72;
 };

 @param urlString url
 @return 信息
 */
+ (NSDictionary *)wya_imageInfoWithUrl:(NSString *)urlString;
@end
