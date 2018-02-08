//
//  SpeexCodec.m
//  TEST_Speex_001
//
//  Created by cai xuejun on 12-9-4.
//  Copyright (c) 2012年 caixuejun. All rights reserved.
//

#import "SpeexCodec.h"

typedef unsigned long long u64;
typedef long long s64;
typedef unsigned int u32;
typedef unsigned short u16;
typedef unsigned char u8;

u16 readUInt16(char* bis) {
    u16 result = 0;
    result += ((u16)(bis[0])) << 8;
    result += (u8)(bis[1]);
    return result;
}

u32 readUint32(char* bis) {
    u32 result = 0;
    result += ((u32) readUInt16(bis)) << 16;
    bis+=2;
    result += readUInt16(bis);
    return result;
}

s64 readSint64(char* bis) {
    s64 result = 0;
    result += ((u64) readUint32(bis)) << 32;
    bis+=4;
    result += readUint32(bis);
    return result;
}

@implementation SpeexCodec

#pragma mark Encode
//struct CAFFileHeader {
//    UInt32  mFileType;
//    UInt16  mFileVersion;
//    UInt16  mFileFlags;
//};
//
//struct CAFChunkHeader {
//    UInt32  mChunkType;
//    SInt64  mChunkSize;
//};

//跳过CAF文件头
/**
 *  @brief 获取音频文件头数据数
 *
 *  @param buf 音频文件
 *
 *  @return 音频文件头数据数量
 */
int SkipCaffHead(char* buf){    
    return 256*16;
    
    
//    
//    if (!buf) {
//        return 0;
//    }
//    char* oldBuf = buf;
//    
//    u32 mFileType = readUint32(buf);
//    if (0x63616666 != mFileType && 0x52494646!=mFileType) {
//        return 0;
//    }
//    buf += 4;
//    
//    /*u16 mFileVersion = */readUInt16(buf);
//    buf += 2;
//    /*u16 mFileFlags = */readUInt16(buf);
//    buf += 2;
//    //    NSLog(@"fileVersion:%d,fileFlags:%d.",mFileVersion, mFileFlags);
//    
//    //desc free data
//    u32 magics[3] = {0x64657363,0x66726565,0x64617461};
//    
//    for (int i=0; i<3; ++i) {
//        u32 mChunkType = readUint32(buf);
//        
//        if (magics[i]!=mChunkType) {
//            return 0;
//        }
//        
//        buf+=4;
//        
//        u32 mChunkSize = readSint64(buf);buf+=8;
//        if (mChunkSize<=0) {
//            return 0;
//        }
//        if (i==2) {
//            return buf-oldBuf;
//        }
//        buf += mChunkSize;
//        
//    }
//    
//    return 1;
}

/**
 *  @brief Speex编码
 *
 *  @param PCMdata        pcm数据
 *  @param maxLen         最大长度
 *  @param nChannels      音轨数
 *  @param nBitsPerSample 比特率
 *
 *  @return 编码后的数据
 */
NSData *EncodePCMToRawSpeex(char *PCMdata, NSUInteger maxLen,int nChannels, int nBitsPerSample)
{
    char *oldBuf = PCMdata;
    short speech[PCM_FRAME_SIZE];
    int byte_counter, frames = 0, bytes = 0;
    
    float input[PCM_FRAME_SIZE];
    char speexFrame[MAX_NB_BYTES];

    int tmp = 4;// bps?
    void *encode_state = speex_encoder_init(&speex_nb_mode);
    speex_encoder_ctl(encode_state, SPEEX_SET_QUALITY, &tmp);
    
    
    /**
     *  @brief 消噪
     */
    SpeexPreprocessState *preprocess_state;
    preprocess_state = speex_preprocess_state_init(PCM_FRAME_SIZE, SPEEX_SAMPLE_RATE);
    
    int denoise = 1;
//    int noiseSuppress = -10;
    speex_preprocess_ctl(preprocess_state, SPEEX_PREPROCESS_SET_DENOISE, &denoise);// 降噪
//    speex_preprocess_ctl(preprocess_state, SPEEX_PREPROCESS_SET_NOISE_SUPPRESS, &noiseSuppress);// 设置噪音的dB
    
    int agc = 20;
    int level = 8000;
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
    
    SpeexBits bits;
    speex_bits_init(&bits);
    NSMutableData *speexRawData = [[NSMutableData alloc] init];
    for (; ; ) {
        if ((PCMdata - oldBuf + sizeof(short)*PCM_FRAME_SIZE) > maxLen) {
            break;
        }
        
        int nRead = ReadPCMFrameData(speech, PCMdata, nChannels, nBitsPerSample);        
        
        //消噪
        speex_preprocess_run(preprocess_state,speech);
        for (int i = 0; i < PCM_FRAME_SIZE; i++) {
            input[i] = speech[i];
        }
        
        PCMdata += nRead;
        
		frames++;
        
        
        
        speex_bits_reset(&bits);
        speex_encode(encode_state, input, &bits);
        
        byte_counter = speex_bits_write(&bits, speexFrame, MAX_NB_BYTES);
        bytes += byte_counter;
        
        [speexRawData appendBytes:speexFrame length:byte_counter];
    }
    
    NSMutableData *speexData = [[NSMutableData alloc] init];
    SpeexHeader speexHeader;
    speex_init_header(&speexHeader, SPEEX_SAMPLE_RATE, 1, &speex_nb_mode);
    speexHeader.reserved1 = speex_bits_nbytes(&bits);
    [speexData appendBytes:&speexHeader length:speexHeader.header_size];
    [speexData appendData:speexRawData];
    
    speex_bits_destroy(&bits);
    speex_encoder_destroy(encode_state);
    return speexData;
}

/**
 *  @brief WAV文件编码
 *
 *  @param data           WAV文件数据
 *  @param nChannels      Channel数
 *  @param nBitsPerSample 比特率
 *
 *  @return Speex编码数据
 */
NSData *EncodeWAVEToSpeex(NSData *data, int nChannels, int nBitsPerSample)
{
    if (data == nil){
        NSLog(@"data is nil...");
        return nil;
    }
    
    int nPos  = 0;
    char *buf = (char *)[data bytes];
    NSUInteger maxLen = [data length];
    
    
    nPos += SkipToPCMAudioData(buf);
    if (nPos >= maxLen) {
        return nil;
    }
    
    //这时取出来的是纯pcm数据
    buf += nPos;
    
    NSData *speexData = EncodePCMToRawSpeex(buf, maxLen-nPos, nChannels, nBitsPerSample);
    return speexData;
}

#pragma mark  -------------------- 解码

/**
 *  @brief Speex解码
 *
 *  @param data Speex数据
 *
 *  @return 解码成PCM后的的数据
 */
NSData *DecodeSpeexToWAVE(NSData *data)
{
    if (data == nil){
        NSLog(@"data is nil...");
        return nil;
    }
    
    int nPos  = 0;
    char *buf = (char *)[data bytes];
    NSUInteger maxLen = [data length];
    
    SpeexHeader *speexHeader = (SpeexHeader *)buf;
    int nbBytes = speexHeader->reserved1;
    
    nPos += sizeof(SpeexHeader);
    if (nPos >= maxLen) {
        return nil;
    }

    //这时取出来的是纯speex数据
    buf += nPos;
    //--------------------------------------
    
    char *oldBuf = (char *)[data bytes];
    int frames = 0;
    
    short pcmFrame[PCM_FRAME_SIZE];
    float output[PCM_FRAME_SIZE];
    
    int tmp = 1;
    void *dec_state = speex_decoder_init(&speex_nb_mode);
    speex_decoder_ctl(dec_state, SPEEX_SET_ENH,&tmp);
    
    NSMutableData *PCMRawData = [[NSMutableData alloc] init];
    
    SpeexBits bits;
    speex_bits_init(&bits);
    for (; ; ) {
        if ((buf - oldBuf + nbBytes) > maxLen) {
            break;
        }
        
        speex_bits_read_from(&bits, buf, nbBytes);
        speex_decode(dec_state, &bits, output);
        
        for (int i = 0; i < PCM_FRAME_SIZE; i++) {
            pcmFrame[i] = output[i];
        }
        
        [PCMRawData appendBytes:pcmFrame length:sizeof(short)*PCM_FRAME_SIZE];
    
        buf += nbBytes;
        frames++;
    }
    
    speex_bits_destroy(&bits);
    speex_decoder_destroy(dec_state);
    
    
    NSMutableData *outData = [[NSMutableData alloc]init];
	WriteWAVEHeader(outData, frames);
    [outData appendData:PCMRawData];
    
    return outData;
}

#pragma mark ------------------ 降噪功能

/**
 *  @brief 降噪处理
 *
 *  @param PCMdata        PCM数据
 *  @param maxLen         总长度
 *  @param nChannels      Channel数
 *  @param nBitsPerSample 比特率
 *
 *  @return 降噪后的数据
 */
NSData *DenoisePCM(char *PCMdata, NSUInteger maxLen,int nChannels, int nBitsPerSample)
{
    int headerLength = SkipToPCMAudioData(PCMdata);
    
    PCMdata+=headerLength;
    char *oldBuf = PCMdata;
    short speech[PCM_FRAME_SIZE];
    
    char speexFrame[PCM_FRAME_SIZE<<1];
    
    int frames = 0;
    
    /**
     *  @brief 消噪
     */
    SpeexPreprocessState *preprocess_state;
    preprocess_state = speex_preprocess_state_init(PCM_FRAME_SIZE, SPEEX_SAMPLE_RATE);
    
    int denoise = 1;
    //    int noiseSuppress = -10;
    speex_preprocess_ctl(preprocess_state, SPEEX_PREPROCESS_SET_DENOISE, &denoise);// 降噪
    //    speex_preprocess_ctl(preprocess_state, SPEEX_PREPROCESS_SET_NOISE_SUPPRESS, &noiseSuppress);// 设置噪音的dB
    
    int agc = 20;
    int level = 8000;
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
    
    NSMutableData *speexRawData = [[NSMutableData alloc] init];
//    [speexRawData appendBytes:PCMdata length:256*16];
//    PCMdata+=256*16;
//    char *oldBuf = PCMdata;
    
    while (1) {
        if ((PCMdata - oldBuf + sizeof(short)*PCM_FRAME_SIZE) > maxLen) {
            break;
        }
        
        int nRead = ReadPCMFrameData(speech, PCMdata, nChannels, nBitsPerSample);
        
        //消噪
        speex_preprocess_run(preprocess_state,speech);
		frames++;
        
        
        memcpy(speexFrame, speech, nRead);
        
        PCMdata += nRead;
        
        [speexRawData appendBytes:speexFrame length:PCM_FRAME_SIZE<<1];
    }
    
    NSMutableData *speexData = [[NSMutableData alloc] init];
    
	WriteWAVEHeader(speexData, frames);
    [speexData appendData:speexRawData];
    return speexData;
}



#pragma mark ------------------ 其他

/**
 *  @brief 计算音频大小
 *
 *  @param speexData speex编码数据
 *  @param nbBytes   数据大小
 *
 *  @return 该音频的播放时间长度
 */
float CalculatePlayTime(NSData *speexData, int nbBytes)
{
    float play_time = 0.0;
    unsigned int speexHeaderLength = sizeof(SpeexHeader);
    NSUInteger rawSpeexDataLength = [speexData length] - speexHeaderLength;
    play_time = (float)rawSpeexDataLength/(nbBytes*50); //每秒是50帧
    
    return play_time;
}

@end
