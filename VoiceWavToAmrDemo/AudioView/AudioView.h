//
//  AudioView.h
//  Fadein
//
//  Created by WangYaochang on 15/4/2.
//  Copyright (c) 2015年 Arceus. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AudioView;

@protocol AudioChatViewDelegate <NSObject>

- (void)audioChatView:(AudioView *)audioView withAudioPath:(NSString*)audioPath withAudioLength:(CGFloat)audioLength;

@end

@interface AudioView : UIView

@property (strong, nonatomic) IBOutlet UIView *littleMoveView;
@property (strong, nonatomic) IBOutlet UIView *audioRecordView;
@property (strong, nonatomic) IBOutlet UILabel *lbRecord;
@property (strong, nonatomic) IBOutlet UILabel *lbTop;

@property (strong, nonatomic) IBOutlet UIView *bgRedView;
@property (strong, nonatomic) IBOutlet UILabel *lbBottom;

@property (nonatomic ,weak) id<AudioChatViewDelegate> delegate;

@end
