//
//  amrFileCodec.h
//  amrDemoForiOS
//
//  Created by Tang Xiaoping on 9/27/11.
//  Copyright 2011 test. All rights reserved.
//
#ifndef amrFileCodec_h
#define amrFileCodec_h
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "interf_dec.h"
#include "interf_enc.h"
#import "AudioFormat.h"

#define AMR_MAGIC_NUMBER "#!AMR\n"

#define MAX_AMR_FRAME_SIZE 32
#define AMR_FRAME_COUNT_PER_SECOND 50

// WAVE音频采样频率是8khz 
// 音频样本单元数 = 8000*0.02 = 160 (由采样频率决定)
// 声道数 1 : 160
//        2 : 160*2 = 320
// bps决定样本(sample)大小
// bps = 8 --> 8位 unsigned char
//       16 --> 16位 unsigned short

/**
 *  @brief 将WAV文件编成AMR,并且消噪
 *
 *  @param pcmData        pcm数据
 *  @param nChannels      频道数
 *  @param nBitsPerSample 比特率
 *
 *  @return 编码后的数据
 */
NSData *EncodeWAVEToAMRForDenoise(NSData *pcmData,int nChannels, int nBitsPerSample);

// 将AMR文件解码成WAVE文件
NSData *DecodeAMRFileToWAVEFile(NSData* data);

#endif
