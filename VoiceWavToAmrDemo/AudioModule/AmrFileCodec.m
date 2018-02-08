//
//  amrFileCodec.cpp
//  amrDemoForiOS
//
//  Created by Tang Xiaoping on 9/27/11.
//  Copyright 2011 test. All rights reserved.
//

#include "AmrFileCodec.h"
#import "SpeexAllHeader.h"
//#import "SLYKit.h"



#pragma mark --------------- 编码

int amrEncodeMode[] = {4750, 5150, 5900, 6700, 7400, 7950, 10200, 12200}; // amr 编码方式



// WAVE音频采样频率是8khz 
// 音频样本单元数 = 8000*0.02 = 160 (由采样频率决定)
// 声道数 1 : 160
//        2 : 160*2 = 320
// bps决定样本(sample)大小
// bps = 8 --> 8位 unsigned char
//       16 --> 16位 unsigned short
/**
 *  @brief pcm数据编码成amr文件
 *
 *  @param PCMdata        PCM音频数据
 *  @param maxLen         音频数据的最大数据
 *  @param nChannels      channel数
 *  @param nBitsPerSample 比特率
 *  @param denoise 支持嗓音
 *
 *  @return 编码后的纯amr数据，无头
 */
NSData *EncodePCMToAMRFile(char *PCMdata, NSUInteger maxLen,int nChannels, int nBitsPerSample,BOOL denoise)
{
	char *oldBuf = PCMdata;
	/* input speech vector */
	short speech[PCM_FRAME_SIZE];
	
	/* counters */
	int byte_counter, frames = 0, bytes = 0;
	
	/**
	 *  @brief 编码引擎
	 */
	void *enstate;
	
	/**
	 *  @brief requested mode,质量
	 */
	enum Mode req_mode = MR67;
	int dtx = 0;
	
	/**
	 *  @brief amr帧数据 bitstream filetype
	 */
	unsigned char amrFrame[MAX_AMR_FRAME_SIZE];
	
	
    //消噪初始化
    SpeexPreprocessState *preprocess_state;
    preprocess_state = speex_preprocess_state_init(PCM_FRAME_SIZE, PCM_SAMPLE_RATE);
    int adenoise = 1;
    int noiseSuppress = -20;
    speex_preprocess_ctl(preprocess_state, SPEEX_PREPROCESS_SET_DENOISE, &adenoise);// 降噪
    speex_preprocess_ctl(preprocess_state, SPEEX_PREPROCESS_SET_NOISE_SUPPRESS, &noiseSuppress);// 设置噪音的dB
    int agc = 20;
    int level = PCM_SAMPLE_RATE;
    //    level = 20;
    //actually default is 8000(0,32768),here make it louder for voice is not loudy enough by default.
    speex_preprocess_ctl(preprocess_state,SPEEX_PREPROCESS_SET_AGC_INCREMENT,&agc);//SPEEX_PREPROCESS_SET_AGC, &agc);// 增益
    speex_preprocess_ctl(preprocess_state,SPEEX_PREPROCESS_SET_AGC_LEVEL,&level);//SPEEX_PREPROCESS_SET_AGC_LEVEL,&level);
    
    int i=0;
    speex_preprocess_ctl(preprocess_state, SPEEX_PREPROCESS_SET_DEREVERB, &i);
    float f=.0;
    speex_preprocess_ctl(preprocess_state, SPEEX_PREPROCESS_SET_DEREVERB_DECAY, &f);
    f=.0;
    speex_preprocess_ctl(preprocess_state, SPEEX_PREPROCESS_SET_DEREVERB_LEVEL, &f);
    
    
    
    NSMutableData *amrRawData = [[NSMutableData alloc] init];
	/* write magic number to indicate single channel AMR file storage format */
    
    NSUInteger headerLength = sizeof(char);
    headerLength = headerLength*strlen(AMR_MAGIC_NUMBER);
    [amrRawData appendBytes:AMR_MAGIC_NUMBER length:headerLength];
	
	enstate = Encoder_Interface_init(dtx);
	
    
	while(1)
	{
        if ((PCMdata - oldBuf + sizeof(short)*PCM_FRAME_SIZE) > maxLen) {
            break;
        }
		// read one pcm frame
        int nRead = ReadPCMFrameData(speech, PCMdata, nChannels, nBitsPerSample);
        PCMdata += nRead;
		frames++;
        
        //消噪
        denoise?speex_preprocess_run(preprocess_state,speech):0;
		
		/* call encoder */
		byte_counter = Encoder_Interface_Encode(enstate, req_mode, speech, amrFrame, 0);
		
		bytes += byte_counter;
        [amrRawData appendBytes:amrFrame length:byte_counter];
	}
//	INFO(@"frame = %d", frames);
	Encoder_Interface_exit(enstate);
	
	return amrRawData;
}

NSData *EncodeWAVEToAMRForDenoise(NSData *pcmData,int nChannels, int nBitsPerSample)
{
    if (pcmData == nil){
        NSLog(@"pcmData is nil...");
        return nil;
    }
    
    int nPos  = 0;
    char *buf = (char *)[pcmData bytes];
    NSUInteger maxLen = [pcmData length];
    
    nPos += SkipToPCMAudioData(buf);
    if (nPos >= maxLen) {
        return nil;
    }
    
    //这时取出来的是纯pcm数据
    buf += nPos;
    maxLen-=nPos;
    NSData *amrData = nil;
    amrData = EncodePCMToAMRFile(buf, maxLen, nChannels, nBitsPerSample, YES);
    
    //    EncodePCMToAMRFile(buf, maxLen, nChannels, nBitsPerSample, YES);
    return amrData;
    
    //    temp
}



#pragma mark - Decode
//decode
//void WriteWAVEFileHeader(FILE* fpwave, int nFrame)
//{
//	char tag[10] = "";
//	
//	// 1. 写RIFF头
//	RIFFHEADER riff;
//	strcpy(tag, "RIFF");
//	memcpy(riff.chRiffID, tag, 4);
//	riff.nRiffSize = 4                                     // WAVE
//	+ sizeof(XCHUNKHEADER)               // fmt 
//	+ sizeof(WAVEFORMATX)           // WAVEFORMATX
//	+ sizeof(XCHUNKHEADER)               // DATA
//	+ nFrame*160*sizeof(short);    //
//	strcpy(tag, "WAVE");
//	memcpy(riff.chRiffFormat, tag, 4);
//	fwrite(&riff, 1, sizeof(RIFFHEADER), fpwave);
//	
//	// 2. 写FMT块
//	XCHUNKHEADER chunk;
//	WAVEFORMATX wfx;
//	strcpy(tag, "fmt ");
//	memcpy(chunk.chChunkID, tag, 4);
//	chunk.nChunkSize = sizeof(WAVEFORMATX);
//	fwrite(&chunk, 1, sizeof(XCHUNKHEADER), fpwave);
//	memset(&wfx, 0, sizeof(WAVEFORMATX));
//	wfx.nFormatTag = 1;
//	wfx.nChannels = 1; // 单声道
//	wfx.nSamplesPerSec = 8000; // 8khz
//	wfx.nAvgBytesPerSec = 16000;
//	wfx.nBlockAlign = 2;
//	wfx.nBitsPerSample = 16; // 16位
//	fwrite(&wfx, 1, sizeof(WAVEFORMATX), fpwave);
//	
//	// 3. 写data块头
//	strcpy(tag, "data");
//	memcpy(chunk.chChunkID, tag, 4);
//	chunk.nChunkSize = nFrame*160*sizeof(short);
//	fwrite(&chunk, 1, sizeof(XCHUNKHEADER), fpwave);
//}

const int myround(const double x)
{
	return((int)(x+0.5));
} 

// 根据帧头计算当前帧大小
int caclAMRFrameSize(unsigned char frameHeader)
{
	int mode;
	int temp1 = 0;
	int temp2 = 0;
	int frameSize;
	
	temp1 = frameHeader;
	
	// 编码方式编号 = 帧头的3-6位
	temp1 &= 0x78; // 0111-1000
	temp1 >>= 3;
	
	mode = amrEncodeMode[temp1];
	
	// 计算amr音频数据帧大小
	// 原理: amr 一帧对应20ms，那么一秒有50帧的音频数据
	temp2 = myround((double)(((double)mode / (double)AMR_FRAME_COUNT_PER_SECOND) / (double)8));
	
	frameSize = myround((double)temp2 + 0.5);
	return frameSize;
}

// 读第一个帧 - (参考帧)
// 返回值: 0-出错; 1-正确
/**
 *  @brief 读第一个帧 - (参考帧)
 *
 *  @param buf            所有数据
 *  @param maxLen         最大长度
 *  @param frameBuffer    arm一帧的数据
 *  @param stdFrameSize   一帧长度
 *  @param stdFrameHeader 帧头
 *
 *  @return  0-出错; 其他-返回当前帧长度
 */
NSUInteger ReadAMRFrameFirst(char* buf, unsigned char frameBuffer[], int* stdFrameSize, unsigned char* stdFrameHeader)
{
    char *oldBuf = buf;
	// 先读帧头
    memcpy(stdFrameHeader, buf, sizeof(unsigned char));
    buf+=sizeof(unsigned char);
	
	// 根据帧头计算帧大小
	*stdFrameSize = caclAMRFrameSize(*stdFrameHeader);
	
	// 读首帧
	frameBuffer[0] = *stdFrameHeader;
    memcpy(frameBuffer, buf, (*stdFrameSize-1)*sizeof(unsigned char));
    buf+= (*stdFrameSize-1)*sizeof(unsigned char);
    
    
	return buf-oldBuf;
}

/**
 *  @brief 读AMR数据帧
 *
 *  @param buf            所有数据
 *  @param maxLen         最大长度
 *  @param frameBuffer    arm一帧的数据
 *  @param stdFrameSize   一帧大小
 *  @param stdFrameHeader 帧头
 *
 *  @return 0-出错; 其他-返回当前帧长度
 */
NSUInteger ReadAMRFrame(char* buf,unsigned char frameBuffer[], int stdFrameSize, unsigned char stdFrameHeader)
{
    char *oldBuf = buf;
    
	unsigned char frameHeader; // 帧头
	
	// 读帧头
	// 如果是坏帧(不是标准帧头)，则继续读下一个字节，直到读到标准帧头
	while(1)
	{
		memcpy(&frameHeader, buf, sizeof(unsigned char));
        buf+=sizeof(unsigned char);
		if (frameHeader == stdFrameHeader) break;
	}
	
	// 读该帧的语音数据(帧头已经读过)
	frameBuffer[0] = frameHeader;
    
    memcpy(&(frameBuffer[1]), buf, (stdFrameSize-1)*sizeof(unsigned char));
    buf+=(stdFrameSize-1)*sizeof(unsigned char);
	
	return buf-oldBuf;
}

// 将AMR文件解码成WAVE文件
/**
 *  @brief  AMR解码成WAVE文件
 *
 *  @param data AMR数据
 *
 *  @return WAVE数据
 */
NSData *DecodeAMRFileToWAVEFile(NSData* data)
{
    if (data==nil) {
//        ERROR(@"data无数据");
        return nil;
    }
    
    char *buf = (char *)[data bytes];
    char *oldBuf = NULL;
    NSUInteger maxLen = [data length];
    
	char magic[8];
	void * destate;
	int nFrameCount = 0;
	int stdFrameSize;
	unsigned char stdFrameHeader;
	
	unsigned char amrFrame[MAX_AMR_FRAME_SIZE];
	short pcmFrame[PCM_FRAME_SIZE];
	
	// 检查amr文件头
    memcpy(magic, buf, sizeof(char)*strlen(AMR_MAGIC_NUMBER));
    buf+=sizeof(char)*strlen(AMR_MAGIC_NUMBER);
	if (strncmp(magic, AMR_MAGIC_NUMBER, strlen(AMR_MAGIC_NUMBER)))
	{
//        ERROR(@"不是amr文件");
	}
    
    maxLen-=(sizeof(char)*strlen(AMR_MAGIC_NUMBER));
    oldBuf = buf;
    
	
	/* init decoder */
	destate = Decoder_Interface_init();
	
	// 读第一帧 - 作为参考帧
	memset(amrFrame, 0, sizeof(amrFrame));
	memset(pcmFrame, 0, sizeof(pcmFrame));
	memset(amrFrame, 0, sizeof(amrFrame));
    
    /**
     *  @brief 读取的长度
     */
    NSUInteger frameLength = 0;
    frameLength = ReadAMRFrameFirst(buf, amrFrame, &stdFrameSize, &stdFrameHeader);
	if (frameLength>0) {
        buf+=frameLength;
    }
    
    
    NSMutableData *pcmData = [[NSMutableData alloc] init];
    
	// 解码一个AMR音频帧成PCM数据
	Decoder_Interface_Decode(destate, amrFrame, pcmFrame, 0);
	nFrameCount++;
    
    [pcmData appendBytes:pcmFrame length:sizeof(short)*PCM_FRAME_SIZE];
//	fwrite(pcmFrame, sizeof(short), PCM_FRAME_SIZE, fpwave);
	
	// 逐帧解码AMR并写到WAVE文件里
	while(1)
	{
        if (buf-oldBuf>=maxLen) {
            break;
        }
        
		memset(amrFrame, 0, sizeof(amrFrame));
		memset(pcmFrame, 0, sizeof(pcmFrame));
        
        frameLength = ReadAMRFrame(buf, amrFrame, stdFrameSize, stdFrameHeader);
		if (frameLength==0)
            break;
        buf+=frameLength;
		
		// 解码一个AMR音频帧成PCM数据 (8k-16b-单声道)
		Decoder_Interface_Decode(destate, amrFrame, pcmFrame, 0);
		nFrameCount++;
        [pcmData appendBytes:pcmFrame length:sizeof(short)*PCM_FRAME_SIZE];
	}
//	INFO(@"frame = %d", nFrameCount);
	Decoder_Interface_exit(destate);
    
    NSMutableData *tempData = [[NSMutableData alloc] init];
    WriteWAVEHeader(tempData, nFrameCount);
    [tempData appendData:pcmData];	
    //添加WAV音频头
    
    
	return tempData;
}