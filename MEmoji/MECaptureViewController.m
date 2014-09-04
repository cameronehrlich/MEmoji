//
//  MECaptureViewController.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 8/13/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MECaptureViewController.h"
#import <UIImage+animatedGIF.h>

static CGFloat stepOfGIF = 0.2f;

@implementation MECaptureViewController

-(void)awakeFromNib
{
    [self initializeCaptureSession];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedThumbnails:) name:MPMoviePlayerThumbnailImageRequestDidFinishNotification object:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.instructionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, self.view.bounds.size.width, 50)];
    [self.instructionLabel setTextAlignment:NSTextAlignmentCenter];
    [self.instructionLabel setTextColor:[UIColor grayColor]];
    [self.instructionLabel setShadowColor:[UIColor blackColor]];
    [self.instructionLabel setShadowOffset:CGSizeMake(0, 1)];
    [self.instructionLabel setFont:[UIFont fontWithDescriptor:self.instructionLabel.font.fontDescriptor size:25]];
    [self.instructionLabel setText:NSLocalizedString(@"Tap to capture.", nil)];
    
    [UIView animateWithDuration:1 delay:1 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [self.instructionLabel setAlpha:0];
    } completion:^(BOOL finished) {
        //
        [self.instructionLabel removeFromSuperview];
    }];
    
    [self.view.layer addSublayer:self.instructionLabel.layer];
    
    self.singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.view addGestureRecognizer:self.singleTapRecognizer];
    
    self.longPressRecognier = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.view addGestureRecognizer:self.longPressRecognier];
    
}

#pragma mark -
#pragma mark UIGestureRecognizerHandlers

- (void)handleSingleTap:(UITapGestureRecognizer *)sender
{
    NSLog(@"%s", __FUNCTION__);
    [self captureImage:self];
}

-  (void)handleLongPress:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        NSLog(@"Began %s", __FUNCTION__);
        [self startRecording];
    }
    else if (sender.state == UIGestureRecognizerStateEnded){
        NSLog(@"Ended %s", __FUNCTION__);
        [self finishRecording];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self togglePreview];
        });
    }
}

#pragma mark -
#pragma mark AVFoundation Setup
- (void)initializeCaptureSession
{
    self.session = [[AVCaptureSession alloc] init];
    
    [self initializeCameraReferences];
    [self initializePreviewLayer];
    
    [self beginRecordingWithDevice:self.frontCamera];
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    [self.stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
    [self.session addOutput:self.stillImageOutput];
    
    
    self.fileOutput = [[AVCaptureMovieFileOutput alloc] init];
    //    [self.movieFileOutput setMaxRecordedDuration:CMTimeMakeWithSeconds(5, 30)];
    //    [self.movieFileOutput setMinFreeDiskSpaceLimit:1024*1024];
    [self.session addOutput:self.fileOutput];
    
    [self.session startRunning];
}

- (void)initializeCameraReferences
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for(AVCaptureDevice *device in devices)
    {
        if(device.position == AVCaptureDevicePositionBack)
        {
            self.backCamera = device;
        }
        else if(device.position == AVCaptureDevicePositionFront)
        {
            self.frontCamera = device;
        }
    }
}

- (void)initializePreviewLayer
{
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    self.previewLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.previewLayer];
}

#pragma mark -
#pragma mark AVCaptureMovieFileDelegate

- (void)beginRecordingWithDevice:(AVCaptureDevice *)device
{
    [self.session stopRunning];
    
    if (self.inputDevice)
    {
        [self.session removeInput:self.inputDevice];
    }
    
    NSError *error = nil;
    self.inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error) {
        NSLog(@"Error: %@", error);
        return;
    }
    
    [self.session addInput:self.inputDevice];
    
    self.session.sessionPreset = AVCaptureSessionPreset640x480;
    
    [self ensureConnectionIsActive];
}

- (void)ensureConnectionIsActive
{
    [self.session startRunning];
}

- (NSString *)currentVideoPath
{
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directory = directories.firstObject;
    NSString *absolutePath = [directory stringByAppendingPathComponent:@"/current.mov"];
    
    return absolutePath;
}

- (void)startRecording
{
    NSString *path = [self currentVideoPath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:path])
    {
        NSError *error = nil;
        [fileManager removeItemAtPath:path error:&error];
        if(error)
        {
            NSLog(@"Error: %@", error);
        }
    }
    
    NSURL *url = [NSURL fileURLWithPath:path];
    [self.fileOutput startRecordingToOutputFileURL:url recordingDelegate:self];
}

- (void)finishRecording
{
    [self.fileOutput stopRecording];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    if (error) {
        NSLog(@"Error: %@", error);
    }

}


- (void)toggleCameras
{
    BOOL isBackFacing = (self.inputDevice.device == self.backCamera);
    [self.session stopRunning];
    
    if (isBackFacing)
    {
        [self beginRecordingWithDevice:self.frontCamera];
    }
    else
    {
        [self beginRecordingWithDevice:self.backCamera];
    }
}

- (void)captureImage:(id)sender
{
    [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in self.stillImageOutput.connections) {
        
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        
        if (videoConnection) {
            break;
        }
    }
    
    
    [self.stillImageOutput
     captureStillImageAsynchronouslyFromConnection:videoConnection
     completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
         
         [self.session stopRunning];
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         
         [[MEModel sharedInstance] createEmojiFromImage:[UIImage imageWithData:imageData] complete:^{
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             [self dismissViewControllerAnimated:YES completion:^{
                 //
             }];
             
         }];
     }];
}

- (void)togglePreview
{
    NSURL *url = [NSURL fileURLWithPath:[self currentVideoPath]];
    [self generateImagesForVideo:url];
}

- (void)generateImagesForVideo:(NSURL *)url
{
    NSLog(@"%s", __FUNCTION__);
    AVURLAsset *asset= [[AVURLAsset alloc] initWithURL:url options:nil];
    
    // Begin conversion
    self.currentTime = [asset duration];
    self.currentFrames = [NSMutableArray array];
    
    NSMutableArray *keyFrames = [NSMutableArray array];
    float current = 0.0f;
    
    while (current <= self.currentTime.value/self.currentTime.timescale)
    {
        [keyFrames addObject:[NSNumber numberWithFloat:current]];
        current += stepOfGIF;
    }
    
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    
    AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result != AVAssetImageGeneratorSucceeded) {
            NSLog(@"couldn't generate thumbnail, error:%@", error);
        }
        
        UIImage *currentFrame = [UIImage imageWithCGImage:im];
        [self.currentFrames addObject:currentFrame];
        
        if ( (requestedTime.value/requestedTime.timescale) >= [[keyFrames lastObject] floatValue] - 2*stepOfGIF) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSLog(@"Last frame found");
                NSData *gifData = [self createGIFwithFrames:[self.currentFrames copy]];
                self.gifView = [[UIImageView alloc] initWithFrame:self.view.bounds];
                [self.gifView setBackgroundColor:[UIColor blackColor]];
                [self.gifView setImage:[UIImage animatedImageWithAnimatedGIFData:gifData]];
                [self.view addSubview:self.gifView];
            });
            
        }
    };
    
    [generator generateCGImagesAsynchronouslyForTimes:keyFrames completionHandler:handler];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (NSData *)createGIFwithFrames:(NSArray *)images
{
    NSDictionary *fileProperties = @{
                                     (__bridge id)kCGImagePropertyGIFDictionary: @{
                                             (__bridge id)kCGImagePropertyGIFLoopCount: @0, // 0 means loop forever
                                             }
                                     };
    NSDictionary *frameProperties = @{
                                      (__bridge id)kCGImagePropertyGIFDictionary: @{
                                              (__bridge id)kCGImagePropertyGIFDelayTime:[NSNumber numberWithFloat:stepOfGIF], // a float (not double!) in seconds, rounded to centiseconds in the GIF data
                                              }
                                      };
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    NSURL *fileURL = [documentsDirectoryURL URLByAppendingPathComponent:@"animated.gif"];
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeGIF, images.count, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    
    
    @autoreleasepool {
        for (UIImage *image in images ) {
            CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef)frameProperties);
        }
    }
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"failed to finalize image destination");
    }
    CFRelease(destination);
    
    NSData *gifData = [NSData dataWithContentsOfFile:fileURL.relativePath];
    
    return gifData;
    
}

@end
