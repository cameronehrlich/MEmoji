//
//  MEModel.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 8/13/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEModel.h"

#define Emoji_Size 200
#define Emoji_Padding Emoji_Size*0.75

@implementation MEModel

+ (instancetype)sharedInstance
{
    static MEModel *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MEModel alloc] init];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [MagicalRecord setupAutoMigratingCoreDataStack];
        self.currentImages = [Image MR_findAllSortedBy:@"createdAt" ascending:NO];
    }
    return self;
}


- (void)createEmojiFromImage:(UIImage *)originalImage complete:(MemojiCallback)callback
{
    NSDictionary *detectorOptions = @{CIDetectorAccuracy: CIDetectorAccuracyHigh};
    
    CIDetector *faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    
    NSDictionary *imageOptions = @{
                                   CIDetectorImageOrientation: @(6),
                                   CIDetectorSmile: @YES
                                   };
    
    CIImage *ciImage = [CIImage imageWithCGImage:originalImage.CGImage];
    
    NSArray *faceFeatures = [faceDetector featuresInImage:ciImage options:imageOptions];
    
    if (faceFeatures.count == 0) {
        NSLog(@"Not able to find bounds.");
        [[[UIAlertView alloc] initWithTitle:@"No Emotion Detected"
                                    message:@"Your face is missing."
                                   delegate:nil
                          cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
        callback();
        return;
    }
    
    CGRect faceBounds;
    CGPoint leftEye, rightEye, mouthPosition;
    
    BOOL hasSmile = NO;
    
    for (CIFaceFeature *faceFeature in faceFeatures) {
        
        leftEye = faceFeature.leftEyePosition;
        rightEye = faceFeature.rightEyePosition;
        mouthPosition = faceFeature.mouthPosition;
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
    
    CGFloat insetBasedOnEyeDistance = ABS(rightEye.y - leftEye.y)/3;
    
    adjustedRect = CGRectInset(adjustedRect, insetBasedOnEyeDistance, insetBasedOnEyeDistance);
    
    CGImageRef imref = CGImageCreateWithImageInRect([originalImage CGImage], adjustedRect);
    
    // Create UIImage
    UIImage *emojiImage = [UIImage imageWithCGImage:imref];
    
    CGImageRelease(imref);
    
    emojiImage = [self rotateImage:emojiImage onDegrees:90];
    
    GPUImageToonFilter *filter = [[GPUImageToonFilter alloc] init];
    
    //    GPUImageSketchFilter *filter = [[GPUImageSketchFilter alloc] init];
    GPUImagePicture *filteredImage = [[GPUImagePicture alloc] initWithImage:emojiImage];
    [filter setThreshold:0.6];
    [filter setQuantizationLevels:8];
    
    [filteredImage addTarget:filter];
    [filter useNextFrameForImageCapture];
    [filteredImage processImage];
    
    emojiImage = [filter imageFromCurrentFramebuffer];
    
    emojiImage = [emojiImage imageWithCornerRadius:emojiImage.size.width/2];
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Image *newImage = [Image MR_createInContext:localContext];
        [newImage setCreatedAt:[NSDate date]];
        [newImage setHasSmile:@(hasSmile)];
        [newImage setImageData:UIImagePNGRepresentation(emojiImage)];
        
    } completion:^(BOOL success, NSError *error) {
        
        self.currentImages = [Image MR_findAllSortedBy:@"createdAt" ascending:NO];
        callback();
    }];
}

- (UIImage *)paddedImageFromImage:(UIImage *)image
{
    // Scale image down
    UIGraphicsBeginImageContext(CGSizeMake(Emoji_Size + Emoji_Padding, Emoji_Size + Emoji_Padding));
    
    [image drawInRect:CGRectMake(Emoji_Padding/2, Emoji_Padding/2, Emoji_Size, Emoji_Size)];
    
    image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *)rotateImage:(UIImage *)image onDegrees:(CGFloat)degrees
{
    CGFloat rads = M_PI * degrees / 180;
    CGFloat newSide = MAX([image size].width, [image size].height);
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




@end
