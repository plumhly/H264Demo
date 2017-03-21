#import <Foundation/Foundation.h>
#include "VideoFileParser.h"

const uint8_t KStartCode[4] = {0, 0, 0, 1};
const NSInteger bufferLength = 10240;

@implementation VideoPacket
- (instancetype)initWithSize:(NSInteger)size
{
    self = [super init];
    self.buffer = malloc(size);
    self.size = size;
    
    return self;
}

-(void)dealloc
{
    free(self.buffer);
}
@end

@interface VideoFileParser ()
{
    uint8_t *_buffer;
    NSInteger _bufferSize;
    NSInteger _bufferCap;
}
@property NSString *fileName;
@property NSInputStream *fileStream;
@property (nonatomic, strong) NSMutableData *data;
@end

@implementation VideoFileParser

-(BOOL)open:(NSString *)fileName
{
    _bufferSize = 0;
    _bufferCap = 512 * 1024;
    _buffer = malloc(_bufferCap);
    _data = [NSMutableData data];
    self.fileName = fileName;
    self.fileStream = [NSInputStream inputStreamWithFileAtPath:fileName];
    [self.fileStream open];

    return YES;
}

-(VideoPacket*)nextPacket
{
    if(/*_bufferSize < _bufferCap &&*/ self.fileStream.hasBytesAvailable) {
//        NSInteger readBytes = [self.fileStream read:_buffer + _bufferSize maxLength:_bufferCap - _bufferSize];
//        _bufferSize += readBytes;
        uint8_t buffer[bufferLength];
        NSUInteger length = [self.fileStream read:buffer maxLength:bufferLength];
        [_data appendBytes:buffer length:length];
        
    }
    
    uint8_t buffer[4];
    [_data getBytes:buffer length:4];
    if(memcmp(buffer, KStartCode, 4) != 0) {
        return nil;
    }
    uint8_t *begainP = (uint8_t *)_data.bytes;
    if(_data.length >= 5) {
        uint8_t *bufferBegin = begainP + 4;
        
        uint8_t *bufferEnd = begainP + _data.length;
        
        while(bufferBegin != bufferEnd) {
            if(*bufferBegin == 0x01) {
                if(memcmp(bufferBegin - 3, KStartCode, 4) == 0) {
                    NSInteger packetSize = bufferBegin - begainP - 3;
                    VideoPacket *vp = [[VideoPacket alloc] initWithSize:packetSize];
                    memcpy(vp.buffer, begainP, packetSize);
                    
//                    memmove(_buffer, _buffer + packetSize, _bufferSize - packetSize);
                    [_data replaceBytesInRange:NSMakeRange(0, packetSize) withBytes:NULL length:0];
//                    _bufferSize -= packetSize;
                    
                    return vp;
                }
            }
            ++bufferBegin;
        }
    }

    return nil;
}

-(void)close
{
    free(_buffer);
    [self.fileStream close];
}

@end
