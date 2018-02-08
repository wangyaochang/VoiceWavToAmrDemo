//
//  ViewController.m
//  VoiceWavToAmrDemo
//
//  Created by 王耀昌 on 2018/2/8.
//  Copyright © 2018年 王耀昌. All rights reserved.
//

#import "ViewController.h"
#import "AudioView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    AudioView *audio = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([AudioView class]) owner:nil options:nil] lastObject];
    audio.frame = CGRectMake(0, self.view.bounds.size.height - 216, self.view.bounds.size.width,216);
    [self.view addSubview:audio];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
