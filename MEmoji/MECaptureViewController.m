//
//  MECaptureViewController.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 8/13/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MECaptureViewController.h"
#import <MBProgressHUD.h>

@implementation MECaptureViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self initializeCamera];
    
    self.instructionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, self.view.bounds.size.width, 50)];
    [self.instructionLabel setTextAlignment:NSTextAlignmentCenter];
    [self.instructionLabel setTextColor:[UIColor grayColor]];
    [self.instructionLabel setShadowColor:[UIColor blackColor]];
    [self.instructionLabel setShadowOffset:CGSizeMake(0, 1)];
    [self.instructionLabel setFont:[UIFont fontWithDescriptor:self.instructionLabel.font.fontDescriptor size:25]];
    [self.instructionLabel setText:@"Tap to capture."];
    [self.view.layer addSublayer:self.instructionLabel.layer];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:1 delay:1 options:UIViewAnimationOptionCurveEaseIn animations:^{
        [self.instructionLabel setAlpha:0];
    } completion:^(BOOL finished) {
        //
        [self.instructionLabel removeFromSuperview];
    }];

}

//AVCaptureSession to show live video feed in view
- (void) initializeCamera
{
    self.session = [[AVCaptureSession alloc] init];
	self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    
	self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
	self.previewLayer.frame = self.view.bounds;
	[self.view.layer addSublayer:self.previewLayer];
    
    
    AVCaptureDevice *frontCamera;
    
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        
        if ([device hasMediaType:AVMediaTypeVideo]) {
            if ([device position] == AVCaptureDevicePositionFront) {
                frontCamera = device;
            }
        }
    }
    
    if (!frontCamera) {
        NSLog(@"Could not find Front Camera");
    }
    
    NSError *error;
    
    self.inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
    if (!self.inputDevice) {
        NSLog(@"ERROR: trying to open camera: %@", error);
    }
    
    [self.session addInput:self.inputDevice];
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
    
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    [self.session addOutput:self.stillImageOutput];
    
	[self.session startRunning];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self captureImage:self];
}

- (IBAction)captureImage:(id)sender
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
