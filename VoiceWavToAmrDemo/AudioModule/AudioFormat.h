//
//  AudioFormat.h
//  TestSpeex
//
//  Created by WangYaochang on 14-4-22.
//  Copyright (c) 2014年 WangYaochang. All rights reserved.
//
#import <UIKit/UIKit.h>

#ifndef TestSpeex_AudioFormat_h
#define TestSpeex_AudioFormat_h
#endif


#define PCM_FRAME_SIZE 160 // 8khz 8000*0.02=160 PCM音频8khz*20ms -> 8000*0.02=160
#define PCM_SAMPLE_RATE 8000

#pragma mark --------- wav文件头格式

typedef struct
{
	char chChunkID[4];
	int nChunkSize;
}XCHUNKHEADER;

typedef struct
{
	short nFormatTag;
	short nChannels;
	int nSamplesPerSec;
	int nAvgBytesPerSec;
	short nBlockAlign;
	short nBitsPerSample;
}WAVEFORMAT;

typedef struct
{
	short nFormatTag;
	short nChannels;
	int nSamplesPerSec;
	int nAvgBytesPerSec;
	short nBlockAlign;
	short nBitsPerSample;
	short nExSize;
}WAVEFORMATX;

typedef struct
{
	char chRiffID[4];
	int nRiffSize;
	char chRiffFormat[4];
}RIFFHEADER;

typedef struct
{
	char chFmtID[4];
	int nFmtSize;
	WAVEFORMAT wf;
}FMTBLOCK;

/**
 *  @brief 添加音频文件头
 *
 *  @param fpwave wav文件数据引用
 *  @param nFrame 帧数
 */
void WriteWAVEHeader(NSMutableData* fpwave, int nFrame);

/**
 *  @brief 获取音频文件头长度
 *
 *  @param buf 音频文件数据
 *
 *  @return 音频头长度
 */
int SkipToPCMAudioData(char* buf);

/**
 *  @brief 从WAVE文件读一个完整的PCM音频帧
 *
 *  @param speech         数字信号
 *  @param fpwave         wav的模拟信号
 *  @param nChannels      channel数
 *  @param nBitsPerSample 比特率
 *
 *  @return 0-错误 >0: 完整帧大小
 */
int ReadPCMFrameData(short speech[], char* fpwave, int nChannels, int nBitsPerSample);
