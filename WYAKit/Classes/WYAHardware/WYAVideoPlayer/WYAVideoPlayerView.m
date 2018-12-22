//
//  WYAVideoPlayerView.m
//  VideoDemo
//
//  Created by 李世航 on 2018/5/28.
//  Copyright © 2018年 WeiYiAn. All rights reserved.
//

#import "WYAVideoPlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "WYAVideoPlayerControlView.h"
#import "WYAVideoSlider.h"
#import "WYABrightnessView.h"
@interface WYAVideoPlayerView () <VideoControlDelegate>

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) AVPlayerItem *playerItem;

@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) UIImageView *previewImageView;

@property (nonatomic, strong) WYAVideoPlayerControlView *controlView;

@property (nonatomic, strong) WYAVideoItem *videoItem;

@property (nonatomic, strong) id timeObserve;

@property (nonatomic, strong) UIActivityIndicatorView *activeView;

@property (nonatomic, assign) BOOL isFullScreen;
@property (nonatomic, strong) UISlider * volumeSlider;
@property (nonatomic, assign) CGFloat                sumTime;//用来保存快进的总时长
@property (nonatomic, strong) WYABrightnessView * brightnessView;

@end


@implementation WYAVideoPlayerView{
    BOOL isVolume;//是否是音量改变，否则就是亮度改变
    BOOL isVertical;//是否是垂直移动，否则横向移动
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.playerLayer.frame = self.bounds;
    
    CGFloat previewImageView_X = 0;
    CGFloat previewImageView_Y = 0;
    CGFloat previewImageView_Width = self.bounds.size.width;
    CGFloat previewImageView_Height = self.bounds.size.height;
    self.previewImageView.frame = CGRectMake(previewImageView_X, previewImageView_Y, previewImageView_Width, previewImageView_Height);
    
    CGFloat activeView_X = (self.bounds.size.width-44)*0.5;
    CGFloat activeView_Y = (self.bounds.size.height-44)*0.5;
    CGFloat activeView_Width = 44;
    CGFloat activeView_Height = 44;
    self.activeView.frame = CGRectMake(activeView_X, activeView_Y, activeView_Width, activeView_Height);
    
    CGFloat controlView_X = 0;
    CGFloat controlView_Y = 0;
    CGFloat controlView_Width = self.bounds.size.width;
    CGFloat controlView_Height = self.bounds.size.height;
    self.controlView.frame = CGRectMake(controlView_X, controlView_Y, controlView_Width, controlView_Height);

    CGFloat brightnessView_X = (self.bounds.size.width-100*SizeAdapter)*0.5;
    CGFloat brightnessView_Y = (self.bounds.size.height-100*SizeAdapter)*0.5;
    CGFloat brightnessView_Width = 100*SizeAdapter;
    CGFloat brightnessView_Height = 100*SizeAdapter;
    self.brightnessView.frame = CGRectMake(brightnessView_X, brightnessView_Y, brightnessView_Width, brightnessView_Height);

}
#pragma mark - Private Method -
- (void)setupUI{
    [self.layer addSublayer:self.playerLayer];
    [self addSubview:self.previewImageView];
    [self addSubview:self.activeView];
    [self addSubview:self.controlView];
    [self addSubview:self.brightnessView];
    
    self.backgroundColor = [UIColor grayColor];
    
    UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panClick:)];
    [self addGestureRecognizer:pan];
    [self configureVolume];
    [self addNotice];
}

- (void)addNotice{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configVideoScreen) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)configVideoScreen{
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    switch (orientation) {
        case UIDeviceOrientationFaceUp:
            NSLog(@"屏幕朝上平躺");
            break;
        case UIDeviceOrientationFaceDown:
            NSLog(@"屏幕朝下平躺");
            break;
        case UIDeviceOrientationUnknown:
            NSLog(@"未知方向");
            break;
        case UIDeviceOrientationLandscapeLeft:
            NSLog(@"屏幕向左横置");
            [self enterFullscreenWithLeft:YES];
            break;
        case UIDeviceOrientationLandscapeRight:
            NSLog(@"屏幕向右橫置");
            [self enterFullscreenWithLeft:NO];
            break;
        case UIDeviceOrientationPortrait:
            NSLog(@"屏幕直立");
            [self exitFullscreen];
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            NSLog(@"屏幕直立，上下顛倒");
            [self exitFullscreen];
            break;
        default:
            NSLog(@"无法辨识");
            break;
    }
}

#pragma mark - Setter -
- (void)setVideoItem:(WYAVideoItem *)videoItem
{
    _videoItem = videoItem;
}

- (void)setPlayerItem:(AVPlayerItem *)playerItem
{
    if (_playerItem) {
        [_playerItem removeObserver:self forKeyPath:@"status"];
        [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [_playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
    }
    _playerItem = playerItem;
    if (playerItem) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
        [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];           // 监听status属性
        [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil]; // 监听loadedTimeRanges属性
        // 缓冲区空了，需要等待数据
        [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        // 缓冲区有足够数据可以播放了
        [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    }
}

//- (void)setNeedOneClick:(BOOL)needOneClick
//{
//    _needOneClick = needOneClick;
//    self.controlView.oneFingerClick = needOneClick;
//}

#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        if ([playerItem status] == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayerStatusReadyToPlay");

            _status = PlayerStatePlaying;
            if (self.videoItem.seekTime) {
                [self wya_getNetWorkStatus:^(WYANetWorkStatus status) {
                    if (status == WYANetWorkStatusWIFI) {
                        [self seekToTime:self.videoItem.seekTime AutoPlay:self.videoItem.seekToTimeAutoPlay FastForward:NO HiddenFastView:YES];
                    }else if (status == WYANetWorkStatusWWAN) {
                        [self.player pause];
                        [self.controlView playFail];
                    }
                }];
                
            }
            [self.activeView stopAnimating];
            self.activeView.hidden = YES;
        } else if ([playerItem status] == AVPlayerStatusFailed) {
            NSLog(@"AVPlayerStatusFailed");
            _status = PlayerStateFailed;
            [self.controlView playFail];
        } else {
            _status = PlayerStateFailed;
            [self.controlView playFail];
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        // 计算缓冲进度
        NSTimeInterval timeInterval = [self availableDuration];
        CMTime duration = self.playerItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);

        [self.controlView wya_playerSetProgress:timeInterval / totalDuration];
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        // 当缓冲是空的时候
        if (self.playerItem.playbackBufferEmpty) {
            _status = PlayerStateBuffering;
            self.activeView.hidden = NO;
            [self.activeView startAnimating];
        }

    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        // 当缓冲好的时候
        if (self.playerItem.playbackLikelyToKeepUp && _status == PlayerStateBuffering) {
//            _status = PlayerStatePlaying;

        }
    }
}

#pragma mark NSNotificationCenter
- (void)playerItemDidReachEnd:(NSNotification *) not
{
    [self.controlView playerEnd];
//    if (self.playerDelegate && [self.playerDelegate respondsToSelector:@selector(videoEnd)]) {
//        [self.playerDelegate videoEnd];
//    }
}


#pragma mark Private Action
- (void)configPlayInfo
{
    self.playerItem = [[AVPlayerItem alloc] initWithURL:self.videoItem.videoUrl];
    self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    if (WYAiPhoneX) {
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    
}

- (void)createTimer
{
    __weak typeof(self) weakSelf = self;
    self.timeObserve = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 1) queue:nil usingBlock:^(CMTime time) {
        AVPlayerItem *currentItem = weakSelf.playerItem;
        NSArray *loadedRanges = currentItem.seekableTimeRanges;
        if (loadedRanges.count > 0 && currentItem.duration.timescale != 0) {
            NSInteger currentTime = (NSInteger)CMTimeGetSeconds([currentItem currentTime]);
            CGFloat totalTime = (CGFloat)currentItem.duration.value / currentItem.duration.timescale;
            CGFloat value = CMTimeGetSeconds([currentItem currentTime]) / totalTime;
            [weakSelf.controlView getCurrentTime:currentTime TotalTime:totalTime SlideValue:value];
        }
    }];
}

/**
 *  计算缓冲进度
 *
 *  @return 缓冲进度
 */
- (NSTimeInterval)availableDuration
{
    NSArray *loadedTimeRanges = [[_player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue]; // 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds; // 计算缓冲总进度
    return result;
}

- (void)enterFullscreenWithLeft:(BOOL)isLeft
{
    self.controlView.zoomButton.selected = YES;
    self.controlView.backButton.hidden = NO;
    if (!self.videoItem.superV) {
        self.videoItem.superV = self.superview;
        self.videoItem.rect = self.frame;
    }

    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    self.isFullScreen = YES;

    /*
     * movieView移到window上
     */
    CGRect rectInWindow = [self convertRect:self.bounds toView:[UIApplication sharedApplication].keyWindow];
    [self removeFromSuperview];
    self.frame = rectInWindow;
    [[UIApplication sharedApplication].keyWindow addSubview:self];

    /*
     * 执行动画
     */
    [UIView animateWithDuration:0.5 animations:^{
        self.transform = CGAffineTransformMakeRotation(isLeft? M_PI_2 : -M_PI_2);
        self.bounds = CGRectMake(0, 0, CGRectGetHeight(self.superview.bounds)-(WYAiPhoneX?WYAStatusBarHeight:0)-WYABottomHeight, CGRectGetWidth(self.superview.bounds));
        self.center = CGPointMake(CGRectGetMidX(self.superview.bounds), CGRectGetMidY(self.superview.bounds));
    } completion:^(BOOL finished){
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }];
    
    if (self.playerDelegate && [self.playerDelegate respondsToSelector:@selector(wya_playerView:isfullScreen:)]) {
        [self.playerDelegate wya_playerView:self isfullScreen:YES];
    }
    
    [[UIApplication sharedApplication] setStatusBarOrientation:isLeft ? UIInterfaceOrientationLandscapeRight : UIInterfaceOrientationLandscapeLeft animated:YES];
}

- (void)exitFullscreen
{
    self.controlView.zoomButton.selected = NO;
    self.controlView.backButton.hidden = YES;
    self.isFullScreen = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    CGRect frame = [self.videoItem.superV convertRect:self.videoItem.rect toView:[UIApplication sharedApplication].keyWindow];
    [UIView animateWithDuration:0.5 animations:^{
        self.transform = CGAffineTransformIdentity;
        self.frame = frame;
    } completion:^(BOOL finished) {
        /*
         * movieView回到小屏位置
         */
        [self removeFromSuperview];
        self.frame = self.videoItem.rect;
        [self.videoItem.superV addSubview:self];
    }];
    
    if (self.playerDelegate && [self.playerDelegate respondsToSelector:@selector(wya_playerView:isfullScreen:)]) {
        [self.playerDelegate wya_playerView:self isfullScreen:NO];
    }
    
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
}

- (void)seekToTime:(NSInteger)time AutoPlay:(BOOL)autoPlay FastForward:(BOOL)fastForward HiddenFastView:(BOOL)hiddenFastView
{
    CMTime timeA = CMTimeMake(time, 1);
    [self.player seekToTime:timeA completionHandler:^(BOOL finished) {
        if (self.status == PlayerStatePlaying) {
            if (autoPlay == YES) {
                [self.player play];
            } else {
                [self.player pause];
            }
        }
        
    }];
    [self.controlView getDragTime:time AutoPlay:autoPlay FastForward:fastForward HiddenFastView:hiddenFastView];
}

/**
 手势改变手机音量、亮度、快进、快退
 
 @param gestureRecognizer 手势
 */
-(void)panClick:(UIPanGestureRecognizer *)gestureRecognizer{
    CGPoint point = [gestureRecognizer locationInView:self];
//    NSLog(@"point.x==%f,point.y==%f",point.x,point.y);
    CGPoint speedPoint = [gestureRecognizer velocityInView:self];
//    NSLog(@"speedPoint.x==%f,speedPoint.y==%f",speedPoint.x,speedPoint.y);
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        
        CGFloat x = fabs(speedPoint.x);
        CGFloat y = fabs(speedPoint.y);
        if (x>y) {
            //横向移动
            isVertical = NO;
            CMTime time       = self.player.currentTime;
            self.sumTime      = time.value/time.timescale;
        }else{
            //纵向移动
            isVertical = YES;
            if (point.x>self.cmam_width/2) {
                isVolume = YES;
            }else{
                isVolume = NO;
            }
        }
        
    }else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        if (isVertical) {
            [self editVolumeOrBrigressWithNumber:speedPoint.y];
        }else{
            [self editVideoFastMoveWithNumber:speedPoint.x];
        }
        
    }else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if (isVertical) {
            isVolume = NO;
        }else{
            [self seekToTime:self.sumTime AutoPlay:YES FastForward:NO HiddenFastView:YES];
        }
    }
}

/**
 设置视频快进快退
 
 @param number 数值
 */
-(void)editVideoFastMoveWithNumber:(CGFloat)number{
    // 每次滑动需要叠加时间
    self.sumTime += number / 200;
    // 需要限定sumTime的范围
    CMTime totalTime           = self.playerItem.duration;
    CGFloat totalMovieDuration = (CGFloat)totalTime.value/totalTime.timescale;
    if (self.sumTime > totalMovieDuration) { self.sumTime = totalMovieDuration;}
    if (self.sumTime < 0) { self.sumTime = 0; }
    
    BOOL style = false;
    if (number > 0) { style = YES; }
    if (number < 0) { style = NO; }
    if (number == 0) { return; }
    [self seekToTime:self.sumTime AutoPlay:NO FastForward:style HiddenFastView:NO];
}

/**
 修改手机音量和亮度（除以10000，才可以得到比例值）
 
 @param number 数值
 */
-(void)editVolumeOrBrigressWithNumber:(CGFloat)number{
    if (isVolume) {
        self.volumeSlider.value -= number/10000;
    }else{
        NSLog(@"改变之前xxx==%f",[UIScreen mainScreen].brightness);
        CGFloat x = [UIScreen mainScreen].brightness;
        x = x - number/10000;
        NSLog(@"x==%f",x);
        [[UIScreen mainScreen] setBrightness:x];
        NSLog(@"改变之后xxx==%f",[UIScreen mainScreen].brightness);
    }
}

/**
 配置修改音量视图
 */
- (void)configureVolume {
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    _volumeSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            _volumeSlider = (UISlider *)view;
            break;
        }
    }
    
    // 使用这个category的应用不会随着手机静音键打开而静音，可在手机静音下播放声音
    NSError *setCategoryError = nil;
    BOOL success = [[AVAudioSession sharedInstance]
                    setCategory: AVAudioSessionCategoryPlayback
                    error: &setCategoryError];
    
    if (!success) { /* handle the error in setCategoryError */ }
}

#pragma mark Public Action
- (void)wya_RegisterPlayerItem:(WYAVideoItem *)item
{
    self.videoItem = item;
    [self.playerLayer removeFromSuperlayer];
//    [self wya_ResetPlayer];
    [self configPlayInfo];
    [self.layer insertSublayer:self.playerLayer atIndex:0];
    [self createTimer];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)wya_ResetPlayer
{
    if (self.timeObserve) {
        [self.player removeTimeObserver:self.timeObserve];
        self.timeObserve = nil;
    }
    [self.playerLayer removeFromSuperlayer];
    self.playerLayer = nil;
    self.playerItem = nil;
    self.player = nil;
    [self.controlView resetVideoPlayControl];
}

- (void)RestorePlayerToOriginalFrame
{
    [self exitFullscreen];
}

#pragma mark VideoControlDelegate
- (void)videoControl:(UIView *)videoControl backButton:(UIButton *)backButton
{
    if (self.isFullScreen == YES) {
        [self exitFullscreen];
        self.controlView.zoomButton.selected = NO;
    }
}

- (void)videoControl:(UIView *)videoControl PlayButton:(UIButton *)playButton
{
    self.previewImageView.hidden = YES;
    if (playButton.selected) {
        [self.player pause];
        _status = PlayerStateStopped;
    } else {
        [self.player play];
        _status = PlayerStatePlaying;
    }
}

- (void)videoControl:(UIView *)videoControl SlideBegin:(WYAVideoSlider *)slide
{
    [self.player pause];
}

- (void)videoControl:(UIView *)videoControl SlideChange:(WYAVideoSlider *)slide
{
    CGFloat totalTime = self.playerItem.duration.value / self.playerItem.duration.timescale;
    CGFloat currentTime = floorf(totalTime * slide.value);
    
    [self.controlView getDragTime:currentTime AutoPlay:NO FastForward:slide.isFastForward HiddenFastView:NO];
}

- (void)videoControl:(UIView *)videoControl SlideEnd:(WYAVideoSlider *)slide
{
    CGFloat totalTime = self.playerItem.duration.value / self.playerItem.duration.timescale;
    CGFloat currentTime = floorf(totalTime * slide.value);
    [self seekToTime:currentTime AutoPlay:YES FastForward:NO HiddenFastView:YES];
}

- (void)videoControl:(UIView *)videoControl zoomButton:(UIButton *)zoomButton
{
    if (zoomButton.selected) {
        //全屏
        [self enterFullscreenWithLeft:NO];
        
       
    } else {
        [self exitFullscreen];
        
    }
}

- (void)videoControlRetry:(UIView *)videoControl{
    NSLog(@"self.videoItem==%@",self.videoItem);
    [self wya_RegisterPlayerItem:self.videoItem];
}

- (void)videoControlGoOn:(UIView *)videoControl{
    [self.player play];
}

#pragma mark - Getter -
- (UIImageView *)previewImageView
{
    if (!_previewImageView) {
        _previewImageView = [[UIImageView alloc] init];
        _previewImageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.videoItem.previewImage]]];
    }
    return _previewImageView;
}

- (UIActivityIndicatorView *)activeView
{
    if (!_activeView) {
        _activeView = [[UIActivityIndicatorView alloc] init];
        _activeView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        _activeView.hidden = YES;
    }
    return _activeView;
}

- (WYAVideoPlayerControlView *)controlView
{
    if (!_controlView) {
        _controlView = [[WYAVideoPlayerControlView alloc] initWithPlayItem:self.videoItem];
        _controlView.videoControlDelegate = self;
    }
    return _controlView;
}

- (WYABrightnessView *)brightnessView{
    if(!_brightnessView){
        _brightnessView = [[WYABrightnessView alloc]init];
        _brightnessView.alpha = 0;
    }
    return _brightnessView;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.timeObserve) {
        [self.player removeTimeObserver:self.timeObserve];
        self.timeObserve = nil;
    }
    self.controlView.videoControlDelegate = nil;
    [self.playerLayer removeFromSuperlayer];
    self.playerLayer = nil;
    self.playerItem = nil;
    self.player = nil;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/



@end
