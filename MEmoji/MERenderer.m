//
//  MERenderer.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/16/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MERenderer.h"

@implementation MERenderer

+ (void)movieFromImageArray:(NSArray *)images completion:(AssetWriterCompletion)completion
{
    NSURL *exportUrl = [NSURL fileURLWithPath:[self exportVideoPath]];
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:exportUrl fileType:AVFileTypeQuickTimeMovie error:&error];
    
    if (error) {
        NSLog(@"%@", error);
    }
    NSParameterAssert(videoWriter);
    
    CGSize tmpImageSize = [[images firstObject] size];
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:tmpImageSize.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:tmpImageSize.height], AVVideoHeightKey,
                                   nil];
    AVAssetWriterInput* writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    [videoWriter addInput:writerInput];
    
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];

    for (UIImage *image in images) {
        
        CVPixelBufferRef sampleBuffer = [self pixelBufferFromCGImage:image.CGImage andSize:tmpImageSize];
        
        BOOL appendedSampleBuffer = [writerInput appendSampleBuffer:sampleBuffer];
        NSLog(@"%@", @(appendedSampleBuffer));
    }
    
    [writerInput markAsFinished];
    [videoWriter finishWritingWithCompletionHandler:^{
        
        NSError *error;
        NSData *data = [NSData dataWithContentsOfFile:[self exportVideoPath] options:NSDataReadingMappedIfSafe error:&error];
        if (error) {
            NSLog(@"%@", error);
        }
        NSLog(@"Data length: %lu", (unsigned long)data.length);
        completion(data);
     }];
}

+ (NSString *)exportVideoPath
{
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directory = directories.firstObject;
    NSString *absolutePath = [directory stringByAppendingPathComponent:@"/export.mov"];
    
    return absolutePath;
}

+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image andSize:(CGSize)size
{
    @autoreleasepool {
        
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                                 [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                                 nil];
        
        CVPixelBufferRef pxbuffer = NULL;
        
        CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, kCVPixelFormatType_32ARGB,(__bridge CFDictionaryRef) options, &pxbuffer);
        NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
        
        CVPixelBufferLockBaseAddress(pxbuffer, 0);
        void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
        NSParameterAssert(pxdata != NULL);
        
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height, 8, 4*size.width, rgbColorSpace, kCGImageAlphaNoneSkipFirst);
        
        NSParameterAssert(context);
        CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
        CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
        CGColorSpaceRelease(rgbColorSpace);
        CGContextRelease(context);
        
        CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
        
        return pxbuffer;
    }
}

@end
