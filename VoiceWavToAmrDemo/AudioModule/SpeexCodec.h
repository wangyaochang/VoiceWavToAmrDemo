//
//  SpeexCodec.h
//  TEST_Speex_001
//
//  Created by cai xuejun on 12-9-4.
//  Copyright (c) 2012年 caixuejun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpeexAllHeader.h"
#import "AudioFormat.h"

#define MAX_NB_BYTES 200
#define SPEEX_SAMPLE_RATE 8000

@interface SpeexCodec : NSObject

int EncodeWAVEFileToSpeexFile(const char* pchWAVEFilename, const char* pchAMRFileName, int nChannels, int nBitsPerSample);

int DecodeSpeexFileToWAVEFile(const char* pchAMRFileName, const char* pchWAVEFilename);

NSData* DecodeSpeexToWAVE(NSData* data);
NSData* EncodeWAVEToSpeex(NSData* data, int nChannels, int nBitsPerSample);

NSData *DenoisePCM(char *PCMdata, NSUInteger maxLen,int nChannels, int nBitsPerSample);

// 根据帧头计算当前帧大小
float CalculatePlayTime(NSData *speexData, int frame_size);



@end
