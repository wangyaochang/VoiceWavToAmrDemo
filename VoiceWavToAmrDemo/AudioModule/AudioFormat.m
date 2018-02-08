//
//  AudioCommon.m
//  TestSpeex
//
//  Created by WangYaochang on 14-4-22.
//  Copyright (c) 2014年 WangYaochang. All rights reserved.
//

#import "AudioFormat.h"

/**
 *  @brief 跳过wav文件头
 *
 *  @param buf wav文件
 *
 *  @return 音频文件头数据数量
 */
int SkipToPCMAudioData(char* buf)
{
	RIFFHEADER riff;
	FMTBLOCK fmt;
	XCHUNKHEADER chunk;
	WAVEFORMATX wfx;
	int bDataBlock = 0;
	
    
    char* oldBuf = buf;
    
	// 1. 读RIFF头
    memcpy(&riff, buf, sizeof(RIFFHEADER));
    buf+=sizeof(RIFFHEADER);
    //	fread(&riff, 1, sizeof(RIFFHEADER), fpwave);
	
	// 2. 读FMT块 - 如果 fmt.nFmtSize>16 说明需要还有一个附属大小没有读
    memcpy(&chunk, buf, sizeof(XCHUNKHEADER));
    buf+=sizeof(XCHUNKHEADER);
    //	fread(&chunk, 1, sizeof(XCHUNKHEADER), fpwave);
	if ( chunk.nChunkSize>16 )
	{
        memcpy(&wfx, buf, sizeof(WAVEFORMATX));
        buf+=sizeof(WAVEFORMATX);
        
        //		fread(&wfx, 1, sizeof(WAVEFORMATX), fpwave);
	}
	else
	{
		memcpy(fmt.chFmtID, chunk.chChunkID, 4);
		fmt.nFmtSize = chunk.nChunkSize;
        
        
        memcpy(&fmt.wf, buf, sizeof(WAVEFORMAT));
        buf+=sizeof(WAVEFORMAT);
        //		fread(&fmt.wf, 1, sizeof(WAVEFORMAT), fpwave);
	}
	
	// 3.转到data块 - 有些还有fact块等。
	while(!bDataBlock)
	{
        memcpy(&chunk, buf, sizeof(XCHUNKHEADER));
        buf+=sizeof(XCHUNKHEADER);
        //		fread(&chunk, 1, sizeof(XCHUNKHEADER), fpwave);
		if ( !memcmp(chunk.chChunkID, "data", 4) )
		{
			bDataBlock = 1;
			break;
		}
		// 因为这个不是data块,就跳过块数据
        buf+=chunk.nChunkSize;
        //		fseek(fpwave, chunk.nChunkSize, SEEK_CUR);
	}
    return (int)(buf-oldBuf);
    
}

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
int ReadPCMFrameData(short speech[], char* fpwave, int nChannels, int nBitsPerSample)
{
	int nRead = 0;
	int x = 0, y=0;
	unsigned short ush1=0, ush2=0, ush=0;
	
	// 原始PCM音频帧数据
	unsigned char  pcmFrame_8b1[PCM_FRAME_SIZE];
	unsigned char  pcmFrame_8b2[PCM_FRAME_SIZE<<1];
	unsigned short pcmFrame_16b1[PCM_FRAME_SIZE];
	unsigned short pcmFrame_16b2[PCM_FRAME_SIZE<<1];
	
    nRead = (nBitsPerSample/8) * PCM_FRAME_SIZE*nChannels;
	if (nBitsPerSample==8 && nChannels==1)
    {
		//nRead = fread(pcmFrame_8b1, (nBitsPerSample/8), PCM_FRAME_SIZE*nChannels, fpwave);
        memcpy(pcmFrame_8b1,fpwave,nRead);
		for(x=0; x<PCM_FRAME_SIZE; x++)
        {
			speech[x] =(short)((short)pcmFrame_8b1[x] << 7);
        }
    }
	else
		if (nBitsPerSample==8 && nChannels==2)
        {
			//nRead = fread(pcmFrame_8b2, (nBitsPerSample/8), PCM_FRAME_SIZE*nChannels, fpwave);
            memcpy(pcmFrame_8b2,fpwave,nRead);
            
			for( x=0, y=0; y<PCM_FRAME_SIZE; y++,x+=2 )
            {
				// 1 - 取两个声道之左声道
				//speech[y] =(short)((short)pcmFrame_8b2[x+0] << 7);
				// 2 - 取两个声道之右声道
				//speech[y] =(short)((short)pcmFrame_8b2[x+1] << 7);
				// 3 - 取两个声道的平均值
				ush1 = (short)pcmFrame_8b2[x+0];
				ush2 = (short)pcmFrame_8b2[x+1];
				ush = (ush1 + ush2) >> 1;
				speech[y] = (short)((short)ush << 7);
            }
        }
		else
			if (nBitsPerSample==16 && nChannels==1)
            {
				//nRead = fread(pcmFrame_16b1, (nBitsPerSample/8), PCM_FRAME_SIZE*nChannels, fpwave);
                memcpy(pcmFrame_16b1,fpwave,nRead);
				
                for(x=0; x<PCM_FRAME_SIZE; x++)
                {
					speech[x] = (short)pcmFrame_16b1[x+0];
                }
            }
			else
				if (nBitsPerSample==16 && nChannels==2)
                {
					//nRead = fread(pcmFrame_16b2, (nBitsPerSample/8), PCM_FRAME_SIZE*nChannels, fpwave);
                    memcpy(pcmFrame_16b2,fpwave,nRead);
                    
                    
                    
					for( x=0, y=0; y<PCM_FRAME_SIZE; y++,x+=2 )
                    {
						//speech[y] = (short)pcmFrame_16b2[x+0];
						speech[y] = (short)((int)((int)pcmFrame_16b2[x+0] + (int)pcmFrame_16b2[x+1])) >> 1;
                    }
                }
	
	// 如果读到的数据不是一个完整的PCM帧, 就返回0
	return nRead;
}

/**
 *  @brief 添加音频文件头
 *
 *  @param fpwave wav文件数据引用
 *  @param nFrame 帧数
 */
void WriteWAVEHeader(NSMutableData* fpwave, int nFrame)
{
	char tag[10] = "";
	
	// 1. 写RIFF头
	RIFFHEADER riff;
	strcpy(tag, "RIFF");
	memcpy(riff.chRiffID, tag, 4);
	riff.nRiffSize = 4                                     // WAVE
	+ sizeof(XCHUNKHEADER)               // fmt
	+ sizeof(WAVEFORMATX)           // WAVEFORMATX
	+ sizeof(XCHUNKHEADER)               // DATA
	+ nFrame*160*sizeof(short);    //
	strcpy(tag, "WAVE");
	memcpy(riff.chRiffFormat, tag, 4);
	//fwrite(&riff, 1, sizeof(RIFFHEADER), fpwave);
    [fpwave appendBytes:&riff length:sizeof(RIFFHEADER)];
	
	// 2. 写FMT块
	XCHUNKHEADER chunk;
	WAVEFORMATX wfx;
	strcpy(tag, "fmt ");
	memcpy(chunk.chChunkID, tag, 4);
	chunk.nChunkSize = sizeof(WAVEFORMATX);
	//fwrite(&chunk, 1, sizeof(XCHUNKHEADER), fpwave);
    [fpwave appendBytes:&chunk length:sizeof(XCHUNKHEADER)];
	memset(&wfx, 0, sizeof(WAVEFORMATX));
	wfx.nFormatTag = 1;
	wfx.nChannels = 1; // 单声道
	wfx.nSamplesPerSec = 8000; // 8khz
	wfx.nAvgBytesPerSec = 16000;
	wfx.nBlockAlign = 2;
	wfx.nBitsPerSample = 16; // 16位
    //fwrite(&wfx, 1, sizeof(WAVEFORMATX), fpwave);
    [fpwave appendBytes:&wfx length:sizeof(WAVEFORMATX)];
	
	// 3. 写data块头
	strcpy(tag, "data");
	memcpy(chunk.chChunkID, tag, 4);
	chunk.nChunkSize = nFrame*160*sizeof(short);
	//fwrite(&chunk, 1, sizeof(XCHUNKHEADER), fpwave);
    [fpwave appendBytes:&chunk length:sizeof(XCHUNKHEADER)];
    
}