//
//  MEViewController.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 7/28/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEViewController.h"
#import <UIImage+Additions.h>
#import "MEMEmojiCell.h"
@import MessageUI;
@import MobileCoreServices;

#define Emoji_Size 50

@interface MEViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, MFMessageComposeViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;

- (IBAction)createAction:(id)sender;

@end

@implementation MEViewController
{
    NSArray *_currentImages;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _currentImages = [Image MR_findAllSortedBy:@"createdAt" ascending:YES];
    NSLog(@"%s", __FUNCTION__);
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)createAction:(id)sender
{
    if (!self.imagePickerController) {
        self.imagePickerController = [[UIImagePickerController alloc] init];
        [self.imagePickerController setSourceType:UIImagePickerControllerSourceTypeCamera];
        [self.imagePickerController setCameraCaptureMode:UIImagePickerControllerCameraCaptureModePhoto];
        [self.imagePickerController setCameraDevice:UIImagePickerControllerCameraDeviceFront];
        [self.imagePickerController setDelegate:self];
    }
    
    [self presentViewController:self.imagePickerController animated:YES completion:^{
        
    }];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
    
    UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    [self createEmojiFromImage:originalImage];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

- (void)createEmojiFromImage:(UIImage *)originalImage
{
    NSDictionary *detectorOptions = @{CIDetectorAccuracy: CIDetectorAccuracyHigh};
    
    CIDetector *faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    
    NSDictionary *imageOptions = @{CIDetectorImageOrientation: @(6),
                                   CIDetectorSmile: @YES};
    
    CIImage *ciImage = [CIImage imageWithCGImage:originalImage.CGImage];
    
    NSArray *faceFeatures = [faceDetector featuresInImage:ciImage options:imageOptions];
    
    if (faceFeatures.count == 0) {
        NSLog(@"Not able to find bounds.");
        [[[UIAlertView alloc] initWithTitle:@"No Emotion Detected"
                                    message:@"Your face is missing."
                                   delegate:nil
                          cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
        return;
    }
    
    CGRect faceBounds;
    BOOL hasSmile = NO;
    
    for (CIFaceFeature *faceFeature in faceFeatures) {
        
        faceBounds = faceFeature.bounds;
        hasSmile = faceFeature.hasSmile;
        
        break;
    }
    
    // Get cropped image of just the face
    CGRect adjustedRect = faceBounds;
    
    // Translate bounds to account for mirroring
    CGFloat distanceFromCenter = CGRectGetMidY(faceBounds) - originalImage.size.width/2;
    
    if (distanceFromCenter > 0) {
        adjustedRect.origin.y -= MAX(0, 2 * ABS(distanceFromCenter));
    }else{
        adjustedRect.origin.y += 2 * ABS(distanceFromCenter);
    }
    
    CGImageRef imref = CGImageCreateWithImageInRect([originalImage CGImage], adjustedRect);
    
    // Create UIImage
    UIImage *emojiImage = [UIImage imageWithCGImage:imref];
    
    emojiImage = [self rotateImage:emojiImage onDegrees:90];
    emojiImage = [emojiImage imageWithCornerRadius:emojiImage.size.width/2];
    
    // Scale image down
    UIGraphicsBeginImageContext(CGSizeMake(Emoji_Size + 10, Emoji_Size + 10));
    
    [emojiImage drawInRect:CGRectMake(5, 5, Emoji_Size, Emoji_Size)];
    
    emojiImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Image *newImage = [Image MR_createInContext:localContext];
        [newImage setCreatedAt:[NSDate date]];
        [newImage setHasSmile:@(hasSmile)];
        [newImage setImageData:UIImagePNGRepresentation(emojiImage)];
        
    } completion:^(BOOL success, NSError *error) {
        [self.collectionView reloadData];
        _currentImages = [Image MR_findAllSortedBy:@"createdAt" ascending:YES];
    }];
}

- (UIImage *)rotateImage:(UIImage *)image onDegrees:(CGFloat)degrees
{
    CGFloat rads = M_PI * degrees / 180;
    float newSide = MAX([image size].width, [image size].height);
    CGSize size =  CGSizeMake(newSide, newSide);
    UIGraphicsBeginImageContext(size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(ctx, newSide/2, newSide/2);
    CGContextRotateCTM(ctx, rads);
    CGContextDrawImage(UIGraphicsGetCurrentContext(),CGRectMake(-[image size].width/2,-[image size].height/2,size.width, size.height),image.CGImage);
    UIImage *i = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return i;
}


#pragma mark -
#pragma mark UIMessageComposeViewController Delegate

-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    if (result == MessageComposeResultCancelled || result == MessageComposeResultFailed) {
        NSLog(@"Didn't send!");
    }
    if (result == MessageComposeResultSent) {
        NSLog(@"Sent message!");
    }
    
    [controller dismissViewControllerAnimated:YES completion:^{
        _currentImages = [Image MR_findAllSortedBy:@"createdAt" ascending:YES];
        [self.collectionView reloadData];
    }];
}

#pragma mark -
#pragma mark UICollectionViewDataSource and Delegate Methods

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _currentImages.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"MEmojiCell";
    Image *thisImage = [_currentImages objectAtIndex:indexPath.row];
    MEMEmojiCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    [cell.imageView setImage:[UIImage imageWithData:thisImage.imageData]];
    if ([thisImage.hasSmile boolValue]) {
        [cell setBackgroundColor:[UIColor yellowColor]];
    }else{
        [cell setBackgroundColor:[UIColor whiteColor]];
    }

    return cell;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Image *thisImage = [_currentImages objectAtIndex:indexPath.row];
    
    MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
    [controller setMessageComposeDelegate:self];
    [controller addAttachmentData:thisImage.imageData typeIdentifier:@"public.png" filename:[NSString stringWithFormat:@"MEmoji-%@.png", thisImage.createdAt.description]];
    
    [self presentViewController:controller animated:YES completion:^{
        
    }];
    
}

@end

