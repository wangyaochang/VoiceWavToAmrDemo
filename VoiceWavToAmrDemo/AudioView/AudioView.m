
//
//  AudioView.m
//  Fadein
//
//  Created by WangYaochang on 15/4/2.
//  Copyright (c) 2015年 Arceus. All rights reserved.
//

#import "AudioView.h"
#import "AmrFileCodec.h"
#import <AVFoundation/AVFoundation.h>
#import "UIView+Addtions.h"
#import "UIColor+PXColors.h"
static CGFloat MaxAudioLength = 60;

#define kRedColor @"ff0003"
#define kWhiteColor @"f7f7f7"
#define TIMER_Interval 0.05
#define SCREEN_BOUNDS [[UIScreen mainScreen] bounds]

#define iOSVersionEqualTo(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define iOSVersionGreaterThan(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define iOSVersionGreaterThanOrEqualTo(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define iOSVersionLessThan(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define iOSVersionLessThanOrEqualTo(v)        ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

@interface AudioView ()<AVAudioRecorderDelegate>
{
    NSTimer *timer;//定时器
    int repleatNum;//重复定时器的次数
    NSInteger timeCount;//记录录制的时间
    CGRect audioRect;//定义取消录制的区域
    BOOL recordCancelStatus;//定义录制状态，取消录制或者记录录制
    BOOL isRecordingStatus; //是否正在录制
    CGFloat lastScale;//记录音波值
}
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *lbBottomBottomConstraint;//底部lb的底部约束
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *audioBottomConstraint;//录音按钮底部约束
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *moveViewWidthContraint;//移动视图宽约束
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *moveViewHeightContraint;//移动视图高约束
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *audioHeightContraint;//录音按钮高约束
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *audioWidthContraint;//录音按钮宽约束
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *lbTopTopConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *littleViewWidth;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *littleViewHeight;

/**
 *  @brief 录音缓存路径
 */
@property (nonatomic ,strong) NSString *recordCachPathWav;
@property (nonatomic ,strong) NSString *recordCachPathAmr;
@property (strong, nonatomic) AVAudioRecorder *recorder;
@end


@implementation AudioView
@synthesize delegate;

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


-(void)awakeFromNib
{
    if (iOSVersionLessThan(@"8.0")) {
        [self setTranslatesAutoresizingMaskIntoConstraints:YES];
        [_littleMoveView setTranslatesAutoresizingMaskIntoConstraints:YES];
        [_audioRecordView setTranslatesAutoresizingMaskIntoConstraints:YES];
        [_bgRedView setTranslatesAutoresizingMaskIntoConstraints:YES];
    }
    
    //将录制按钮 化成圆形
    _audioRecordView.layer.cornerRadius=CGRectGetHeight(_audioRecordView.bounds)/2;
    _audioRecordView.layer.masksToBounds=YES;
    
    //将变动的视图 化成圆形
    _littleMoveView.layer.cornerRadius=CGRectGetHeight(_littleMoveView.bounds)/2;
    _littleMoveView.layer.masksToBounds=YES;
    
    _lbBottomBottomConstraint.constant=0-_lbBottom.height;
    
    //将变动的视图 化成圆形
    _bgRedView.layer.cornerRadius=CGRectGetHeight(_bgRedView.bounds)/2;
    _bgRedView.layer.masksToBounds=YES;
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[[touches allObjects] lastObject];
    CGPoint currentPoint=[touch locationInView:self];
    audioRect=_audioRecordView.frame;
    if (CGRectContainsPoint(_audioRecordView.frame, currentPoint)) {
        if (!isRecordingStatus) {
            
            [self beginRecord];
            
            
        }
        
    }
}
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch=[[touches allObjects] lastObject];
    CGPoint currentPoint=[touch locationInView:self];
    if (isRecordingStatus) {
        if (CGRectContainsPoint(audioRect, currentPoint)) {
            
            [UIView animateWithDuration:.3 animations:^{
                [self changeRecordViewFrame];
                [self initRedViewFrame];
                [_audioRecordView setBackgroundColor:[UIColor colorWithHexString:kRedColor]];
            }];
            
            [self initTopLb];
            recordCancelStatus=NO;
            
        }else{
            [UIView animateWithDuration:.3 animations:^{
                [self initRecordView];
                [self changeRedViewFrame];
                [_audioRecordView setBackgroundColor:[UIColor colorWithHexString:kWhiteColor]];
            }];
            
            [self changeTopLb];
            recordCancelStatus=YES;
        }
    }
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (isRecordingStatus) {
        [self endRecord];
    }
}


//启动定时器
-(void)startTimer
{
    if (timer) {
        [self stopTimer];
    }
    timeCount=0;
    repleatNum=0;
    recordCancelStatus=NO;
    timer=[NSTimer scheduledTimerWithTimeInterval:TIMER_Interval target:self selector:@selector(changeTimeCount:) userInfo:nil repeats:YES];
}
//停止定时器
-(void)stopTimer
{
    if (timer) {
        [timer invalidate];
        timer=nil;
    }
}
//定时器 循环函数
-(void)changeTimeCount:(NSTimer *)timer
{
    repleatNum++;
    if (repleatNum == (int)(1/TIMER_Interval)) {
        repleatNum=0;
        timeCount+=1;
        if (recordCancelStatus) {
            _lbRecord.text=[self changeTimeKind];
        }else{
            _lbTop.text=[self changeTimeKind];
        }
        
        if (timeCount>59) {
            [self stopTimer];
        }
        if (timeCount>50) {
//            [self.viewController.view presentMessageTips:[NSString stringWithFormat:@"%d",60-(int)timeCount]];
        }
    }
    [self updateMeters];
    
}
//录制视图回归正常
-(void)initRecordView
{
    _audioRecordView.transform=CGAffineTransformIdentity;
    _lbBottom.transform=CGAffineTransformIdentity;
}
//录制视图变换
-(void)changeRecordViewFrame
{
    _audioRecordView.transform=CGAffineTransformScale(CGAffineTransformIdentity, 0.8, 0.8);
    _lbBottom.transform=CGAffineTransformTranslate(CGAffineTransformIdentity, 0, -30);
}
//红色视图变换
-(void)changeRedViewFrame
{
    _bgRedView.transform=CGAffineTransformScale(CGAffineTransformIdentity, SCREEN_BOUNDS.size.width/2, SCREEN_BOUNDS.size.width/2);
}
//红色视图回归
-(void)initRedViewFrame
{
    _bgRedView.transform=CGAffineTransformIdentity;
}
//上面label变化
-(void)initTopLb
{
    //加个弹簧效果
    if (recordCancelStatus) {
        [UIView animateWithDuration:.3 animations:^{
            _lbTop.transform=CGAffineTransformTranslate(CGAffineTransformIdentity, 0, 15);
            _lbRecord.transform=CGAffineTransformTranslate(CGAffineTransformIdentity, 0, -15);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:.3 delay:0 usingSpringWithDamping:1.0 initialSpringVelocity:5.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                _lbTop.transform=CGAffineTransformIdentity;
                _lbRecord.transform=CGAffineTransformIdentity;
            } completion:nil];
            _lbTop.text=[self changeTimeKind];
            [_lbTop setTextColor:[UIColor colorWithHexString:kRedColor]];
            _lbRecord.text=@"语音";
            [_lbRecord setTextColor:[UIColor whiteColor]];
        }];
    }
    //为了 时间恢复到初始状态
    _lbTop.text=[self changeTimeKind];
}
//上面label回归
-(void)changeTopLb
{
    if (!recordCancelStatus) {
        [UIView animateWithDuration:.3 animations:^{
            _lbTop.transform=CGAffineTransformTranslate(CGAffineTransformIdentity, 0, -15);
            _lbRecord.transform=CGAffineTransformTranslate(CGAffineTransformIdentity, 0, 15);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:.3 delay:0 usingSpringWithDamping:1.0 initialSpringVelocity:5.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                _lbTop.transform=CGAffineTransformIdentity;
                _lbRecord.transform=CGAffineTransformIdentity;
            } completion:nil];
            
            _lbTop.text=@"松开取消录制";
            [_lbTop setTextColor:[UIColor whiteColor]];
            _lbRecord.text=[self changeTimeKind];
            [_lbRecord setTextColor:[UIColor redColor]];
        }];
    }
     recordCancelStatus=YES;
}
//初始化变动视图
-(void)initLittleMoveView
{
    _littleMoveView.transform=CGAffineTransformIdentity;
    [_littleMoveView setBackgroundColor:[UIColor colorWithHexString:@"DADADA"]];
    _littleMoveView.alpha=1.0;
}
//改变变动视图
-(void)changeLittleMoveViewWithScale:(float)averagePower
{
    _littleMoveView.transform=CGAffineTransformScale(CGAffineTransformIdentity, averagePower, averagePower);
    [_littleMoveView setBackgroundColor:[UIColor colorWithHexString:recordCancelStatus?@"000000": @"DADADA"]];
    _littleMoveView.alpha=recordCancelStatus?0.1:1.0;
}


//时间转换为时间格式
-(NSString *)changeTimeKind
{
    NSDateFormatter *formatter=[[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    NSString *currentDateStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:isRecordingStatus?timeCount:0]];
    return [currentDateStr substringWithRange:NSMakeRange(currentDateStr.length-4, 4)];
}
#pragma mark - 开始录音
- (NSString*)getRecordCachPath
{
    NSString  *recordCachName = [[self getCurrentTimeString] stringByAppendingPathExtension:@"wav"];
    
    return [[self returnChatAudioPath] stringByAppendingPathComponent:recordCachName];
}
//获取当前时间值
-(NSString *)getCurrentTimeString
{
    NSDateFormatter *formatter=[[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddhhmmss"];
    return [formatter stringFromDate:[NSDate date]];
}

-(NSString *)returnChatAudioPath
{
    NSString *imageCachesPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Caches"] stringByAppendingPathComponent:@"audioCaches"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:imageCachesPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:imageCachesPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return imageCachesPath;
}
/**
	获取录音设置
	@returns 录音设置
 */
- (NSDictionary*)getAudioRecorderSettingDict
{
    static NSDictionary *recordSetting = nil;
    if (recordSetting==nil) {
        recordSetting = [[NSDictionary alloc] initWithObjectsAndKeys:
                         [NSNumber numberWithFloat: 8000.0],AVSampleRateKey, //采样率
                         [NSNumber numberWithInt: kAudioFormatLinearPCM],AVFormatIDKey,
                         [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,//采样位数 默认 16
                         [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,//通道的数目
                         [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,//大端还是小端 是内存的组织方式
                         //                                   [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,//采样信号是整数还是浮点数
                         //                                   [NSNumber numberWithFloat:8000.0],AVEncoderBitRateKey,
                         [NSNumber numberWithInt: AVAudioQualityLow],AVEncoderAudioQualityKey,//音频编码质量
                         nil];
    }
    return recordSetting;
}

#pragma mark-- 判断录音权限
- (BOOL)canRecord
{
    __block BOOL bCanRecord = YES;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
        [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
            if (granted) {
                bCanRecord = YES;
            } else {
                bCanRecord = NO;
            }
        }];
    }
    
    return bCanRecord;
}

#pragma mark -- 开始录音
- (void)beginRecord{
    
    if (![self canRecord]) {
//        [self.viewController.view presentMessageTips:@"请在设置->快活中打开快活访问麦克风"];
        recordCancelStatus=YES;
        [self endRecord];
        return;
    }
    
    //生成路径
    self.recordCachPathWav=[self getRecordCachPath];
    //初始化录音
    self.recorder = [[AVAudioRecorder alloc]initWithURL:[NSURL URLWithString:self.recordCachPathWav]
                                               settings:self.getAudioRecorderSettingDict
                                                  error:nil];
    self.recorder.delegate = self;
    self.recorder.meteringEnabled = YES;
    
    //还原发送
    recordCancelStatus= NO;
    
    //开始录音
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    if ([self.recorder prepareToRecord]) {
        
        [UIView animateWithDuration:.3 animations:^{
            [self changeRecordViewFrame];
            [self initRedViewFrame];
        }];
        [self startTimer];
        isRecordingStatus=YES;
        
        [self.recorder record];
    }else{
        NSLog(@"不能录音");
//        [self.viewController.view presentMessageTips:@"录音发生错误"];
        recordCancelStatus=YES;
        [self endRecord];
    }
}

#pragma mark -- 停止录音
- (void)endRecord
{
    isRecordingStatus=NO;
    [UIView animateWithDuration:.3 animations:^{
        [self initRecordView];
        [self initRedViewFrame];
        [_audioRecordView setBackgroundColor:[UIColor colorWithHexString:kRedColor]];
    }];
    [self initTopLb];
    [self initLittleMoveView];
    
    //停止计时器
    [self stopTimer];
    //停止录音
    if (self.recorder.isRecording)
        [self.recorder stop];
    if (timeCount<1 && [self canRecord]) {
        recordCancelStatus=YES;
//        [self.viewController.view presentMessageTips:@"录音时间太短"];
    }
    
    if (recordCancelStatus) {
        //如果是取消状态就删除本地录音
        [[NSFileManager defaultManager] removeItemAtPath:self.recordCachPathWav error:nil];
    }else{
        [self wavToAmr];
    }
}

#pragma mark -- 暂停录音
- (void)pauseRecord
{
    if (self.recorder.isRecording) {
        [self.recorder pause];
        [self stopTimer];
    }
}

- (void)resumeRecord
{
    if (!self.recorder.isRecording) {
        [self.recorder record];
        if (timer==nil) {
            [self startTimer];
        }
    }
}
#pragma mark -- 更新音频峰值
- (void)updateMeters{
    if (self.recorder.isRecording){
        //更新峰值
        [self.recorder updateMeters];
        
//        CGFloat averagePower = [self.recorder peakPowerForChannel:0];
        CGFloat maxAver = SCREEN_BOUNDS.size.width / 80 + 4;
        

//        if (averagePower < -30){
//            averagePower = 1.0;
//        }else if (averagePower > 0){
//            averagePower = maxAver;
//        }else{
//            averagePower=averagePower + 30;
//            averagePower=1.0 + (maxAver-1)*averagePower/30;
//            
//            if (fabs(lastScale - averagePower) < 1e-6) {
//                averagePower -= 0.2;
//            }
//            lastScale = averagePower;
//        }
//        [self changeLittleMoveViewWithScale:averagePower];
        
        
        float   level;                // The linear 0.0 .. 1.0 value we need.
        
        float   minDecibels = -80.0f; // Or use -60dB, which I measured in a silent room.
        
        float   decibels = [self.recorder averagePowerForChannel:0];
        
        if (decibels < minDecibels)
            
        {
            
            level = 0.0f;
            
        }
        
        else if (decibels >= 0.0f)
            
        {
            
            level = 1.0f;
            
        }
        
        else
            
        {
            
            float   root            = 2.0f;
            
            float   minAmp          = powf(10.0f, 0.05f * minDecibels);
            
            float   inverseAmpRange = 1.0f / (1.0f - minAmp);
            
            float   amp             = powf(10.0f, 0.05f * decibels);
            
            float   adjAmp          = (amp - minAmp) * inverseAmpRange;
            
            
            
            level = powf(adjAmp, 1.0f / root);
            
        }   
        
        NSLog(@"=%f=%f",decibels,level);
        [self changeLittleMoveViewWithScale:(maxAver*level)];
        
        
        //倒计时
        if (self.recorder.currentTime<=MaxAudioLength)
        {
            
        }
        else
        {
            //时间到
            [self endRecord];
        }
    }
    
}
#pragma mark-视频转码
-(void)wavToAmr
{
    if (self.recordCachPathWav) {
        
        self.recordCachPathAmr=[[self.recordCachPathWav stringByDeletingPathExtension] stringByAppendingPathExtension:@"amr"];
        NSData *PCMData = [NSData dataWithContentsOfFile:self.recordCachPathWav];
        NSData *amrData = EncodeWAVEToAMRForDenoise(PCMData, 1, 16);
        
        [amrData writeToFile:self.recordCachPathAmr atomically:YES];
        
        //在不取消发送的情况下出发协议 发送
        if ([delegate respondsToSelector:@selector(audioChatView:withAudioPath:withAudioLength:)]) {
            [delegate audioChatView:self withAudioPath:[self.recordCachPathAmr lastPathComponent] withAudioLength:timeCount];
        }
    }
}

#pragma mark-  amr 转 wav
-(void)amrToWav
{
//    NSData *amrData = [NSData dataWithContentsOfFile:audioPath];
//    NSData *PCMData = DecodeAMRFileToWAVEFile(amrData);
//    NSError *error = nil;
//    self.audioPlay = [[INKAudioPlayer alloc] initWithData:PCMData error:&error];
//    self.audioPlay.delegate = self;
//    self.audioPlay.chatAudio = aChat;
//    [self.audioPlay play];
}
#pragma mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    NSLog(@"录音停止");
}
-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    NSLog(@"发生错误");
}
-(void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder
{
    NSLog(@"开始中断");
}
-(void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder
{
    NSLog(@"结束中断");
}
@end
