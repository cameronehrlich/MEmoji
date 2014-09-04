//
//  MECaptureViewController.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 8/13/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MECaptureViewController.h"

@implementation MECaptureViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initializeCaptureSession];
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
    [self captureImage];
}

-  (void)handleLongPress:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self startRecording];
    }
    else if (sender.state == UIGestureRecognizerStateEnded){
        [MBProgressHUD showHUDAddedTo:self.view animated:NO];
        [self finishRecording];
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
//    [self.fileOutput setMaxRecordedDuration:CMTimeMa/keWithSeconds(5, 30)]; // TODO : enforce a time-limit
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
    
    CGRect layerFrame = CGRectMake(0, (self.view.height/2) - (self.view.width/2), self.view.width, self.view.width);
    
    self.previewLayer.frame = layerFrame;
    [self.view.layer addSublayer:self.previewLayer];
}

#pragma mark -
#pragma mark AVCaptureMovieFileDelegate
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{

}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    if (error) {
        NSLog(@"Error: %@", error);
        [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Video could not be converted for some reason!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
    }else{
        [self captureGIF];
        
    }
}

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
    
    self.session.sessionPreset = AVCaptureSessionPresetMedium;
    [self.session startRunning];

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
    if ([fileManager fileExistsAtPath:path])
    {
        NSError *error = nil;
        [fileManager removeItemAtPath:path error:&error];
        if (error){ NSLog(@"Error: %@", error);}
    }
    
    NSURL *url = [NSURL fileURLWithPath:path];
    [self.fileOutput startRecordingToOutputFileURL:url recordingDelegate:self];
}

- (void)finishRecording
{
    [self.fileOutput stopRecording];

}

- (void)captureImage
{
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

- (void)captureGIF
{
    NSURL *url = [NSURL fileURLWithPath:[self currentVideoPath]];
    
    [[MEModel sharedInstance] createEmojiFromMovieURL:url complete:^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self dismissViewControllerAnimated:YES completion:^{
            //
        }];
    }];
}

@end
