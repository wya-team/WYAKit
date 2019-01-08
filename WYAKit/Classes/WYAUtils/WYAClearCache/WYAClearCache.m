//
//  WYAClearCache.m
//  CocoaLumberjack
//
//  Created by 李俊恒 on 2018/12/6.
//

#import "WYAClearCache.h"

#include <sys/param.h>
#include <sys/mount.h>

@implementation WYAClearCache
+ (void)wya_defaultCachesFolderSizeBlock:(void (^)(NSString * folderSize))folderSize
{
    NSString * cachPath = [NSString wya_libCachePath];
    [self folderSizeAtPath:cachPath FolderSizeBlock:folderSize];
}

+ (void)wya_fileSizeAtPath:(NSString *)filePath FolderSizeBlock:(void (^)(NSString* folderSize))folderSize
{
    [self folderSizeAtPath:filePath FolderSizeBlock:folderSize];
}

+ (void)wya_clearCachesClearStatusBlock:(void (^)(BOOL status))clearStatus
{
    NSString * cachPath = [NSString wya_libCachePath];
    [self clearFileAtPath:cachPath ClearStatusBlock:clearStatus];
}

+ (void)wya_clearFileAtPath:(NSString *)filePath ClearStatusBlock:(void (^)(BOOL status))clearStatus
{
    [self clearFileAtPath:filePath ClearStatusBlock:clearStatus];
}
#pragma mark ======= private methods
+ (void)clearFileAtPath:(NSString *)folderPath ClearStatusBlock:(void (^)(BOOL status))clearStatus
{
    NSFileManager * manage = [NSFileManager defaultManager];

    if (![manage fileExistsAtPath:folderPath]) {
        clearStatus(NO);
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ //地址
        NSArray * files = [[NSFileManager defaultManager] subpathsAtPath:folderPath];

        for (NSString * p in files) {
            NSError * error = nil;
            NSString * path = [folderPath stringByAppendingPathComponent:p];
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            //回调或者说是通知主线程刷新，
            clearStatus(YES);
        });
    });
}

+ (void)folderSizeAtPath:(NSString *)folderPath FolderSizeBlock:(void (^)(NSString* fileSize))fileSize
{
    NSFileManager * manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) {
        fileSize(0);
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ //地址
        NSEnumerator * childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
        NSString * fileName;
        long long folderSize = 0;
        while ((fileName = [childFilesEnumerator nextObject]) != nil) {
            NSString * fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
            folderSize += [self fileSizeAtPath:fileAbsolutePath];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            //回调或者说是通知主线程刷新，
            fileSize([self automaticUnitWith:folderSize]);
        });
    });
}

+ (long long)fileSizeAtPath:(NSString *)filePath
{
    NSFileManager * manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]) {
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}
+(NSString *)wya_getDivceSize{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *attributes = [fileManager attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    
    NSLog(@"容量%.2fG",[attributes[NSFileSystemSize] doubleValue] / (powf(1024, 3)));
    NSLog(@"可用%.2fG",[attributes[NSFileSystemFreeSize] doubleValue] / powf(1024, 3));
    NSString * sizeStr = [NSString stringWithFormat:@"可用空间%0.2fG / 总空间%0.2fG",[attributes[NSFileSystemFreeSize] doubleValue] / powf(1024, 3),[attributes[NSFileSystemSize] doubleValue] / (powf(1024, 3))];
    return sizeStr;
}

+ (void)wya_getDivceAvailableSizeBlock:(void (^)(NSString * folderSize))folderSize{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *attributes = [fileManager attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    double folder = [attributes[NSFileSystemFreeSize] doubleValue];
    
    folderSize([self automaticUnitWith:folder]);
}

// 自动获取单位
+ (NSString *)automaticUnitWith:(double)folder{
    if (folder / 1000.0 < 1 ) {
        return [NSString stringWithFormat:@"%.2fB",folder];
    }
    if (folder / (1000.0 * 1000.0) < 1 ) {
      return [NSString stringWithFormat:@"%.2fKB",folder / 1000.0];
    }
    if (folder / (1000.0 * 1000.0 * 1000.0) < 1) {
       return [NSString stringWithFormat:@"%.2fMB",folder / (1000.0 * 1000.0)];
    }else{
     return [NSString stringWithFormat:@"%.2fGB",folder / (1000.0 * 1000.0 * 1000.0)];
    }
    
}

@end
