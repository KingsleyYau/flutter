//
//  Copyright (c) 2018 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "ViewController.h"
#import "ModelInterpreterManager.h"
#import "UIImage+TFLite.h"
@import Firebase;

static NSString *const failedToDetectObjectsMessage = @"Failed to detect objects in image.";
static NSString *const defaultImage = @"grace_hopper.jpg";

typedef NS_ENUM(NSInteger, CloudModel) {
  CloudModelQuantized = 0,
  CloudModelFloat = 1,
  CloudModelInvalid = 2
};

NSString * const CloudModelDownloadCompletedKey[] = {
  [CloudModelQuantized] = @"FIRCloudModel1DownloadCompleted",
  [CloudModelFloat] = @"FIRCloudModel2DownloadCompleted",
  [CloudModelInvalid] = @"FIRCloudInvalidModel"
};

// REPLACE THESE CLOUD MODEL NAMES WITH ONES THAT ARE UPLOADED TO YOUR FIREBASE CONSOLE.
NSString * const CloudModelDescription[] = {
  [CloudModelQuantized] = @"image-classification-quant-v2",
  [CloudModelFloat] = @"image-classification-float-v2",
  [CloudModelInvalid] = @"invalid_model"
};

typedef NS_ENUM(NSInteger, LocalModel) {
  LocalModelQuantized = 0,
  LocalModelFloat = 1,
  LocalModelInvalid = 2
};

NSString * const LocalModelDescription[] = {
  [CloudModelQuantized] = quantizedModelFilename,
  [CloudModelFloat] = floatModelFilename,
  [CloudModelInvalid] = invalidModelFilename
};



@interface ViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
  
  /// Model interpreter manager that manages loading models and detecting objects.
  @property(nonatomic) ModelInterpreterManager *modelManager;
  
  /// Indicates whether the download cloud model button was selected.
  @property(nonatomic) bool downloadCloudModelButtonSelected;
  
  /// An image picker for accessing the photo library or camera.
  @property(nonatomic) UIImagePickerController *imagePicker;
  
  @property(nonatomic) CloudModel currentCloudModel;
  @property(nonatomic) LocalModel currentLocalModel;
  @property(nonatomic) BOOL isModelQuantized;
  @property(nonatomic) BOOL isCloudModelDownloaded;
  
  
  /// A segmented control for changing models (0 = float, 1 = quantized, 2 = invalid).
  @property (weak, nonatomic) IBOutlet UISegmentedControl *modelControl;
  
  @property (weak, nonatomic) IBOutlet UIImageView *imageView;
  @property (weak, nonatomic) IBOutlet UITextView *resultsTextView;
  @property (weak, nonatomic) IBOutlet UIBarButtonItem *detectButton;
  @property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;
  @property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadModelButton;
  
  @end

@implementation ViewController
  
- (CloudModel) currentCloudModel {
  return _modelControl.selectedSegmentIndex;
}
  
- (LocalModel) currentLocalModel {
  return _modelControl.selectedSegmentIndex;
}
  
- (BOOL) isCloudModelDownloaded {
  return [NSUserDefaults.standardUserDefaults boolForKey:CloudModelDownloadCompletedKey[_currentCloudModel]];
}
  
- (BOOL) isModelQuantized {
  return _isCloudModelDownloaded ? _currentCloudModel == CloudModelQuantized : _currentLocalModel == LocalModelQuantized;
}
  
- (void)viewDidLoad {
  [super viewDidLoad];
  
  
  self.modelManager = [ModelInterpreterManager new];
  self.downloadCloudModelButtonSelected = NO;
  self.imagePicker = [UIImagePickerController new];
  _imageView.image = [UIImage imageNamed:defaultImage];
  _imagePicker.delegate = self;
  
  if (![UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront] ||
      ![UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
    [_cameraButton setEnabled:NO];
  }
  
  [self setUpCloudModel];
  [self setUpLocalModel];
}
  
#pragma mark - IBActions
  
- (IBAction)detectObjects:(id)sender {
  [self clearResults];
  UIImage *image = _imageView.image;
  if (!image) {
    _resultsTextView.text = @"Image must not be nil.\n";
    return;
  }
  
  if (!_downloadCloudModelButtonSelected) {
    _resultsTextView.text = @"Loading the local model...\n";
    if (![_modelManager loadLocalModelWithIsModelQuantized:(_currentLocalModel == LocalModelQuantized)]) {
      _resultsTextView.text = @"Failed to load the local model.";
      return;
    }
  }
  NSString *newResultsTextString = @"Starting inference...\n";
  if (_resultsTextView.text) {
    _resultsTextView.text = [_resultsTextView.text stringByAppendingString:newResultsTextString];
  }
  CloudModel cloudmodel = _currentCloudModel;
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    NSObject *imageData = [self.modelManager scaledImageDataFromImage:image];
    [self.modelManager detectObjectsInImageData:imageData topResultsCount:nil completion:^(NSArray * _Nullable results, NSError * _Nullable error) {
      if (!results || results.count == 0) {
        NSString *errorString = error ? error.localizedDescription : failedToDetectObjectsMessage;
        errorString = [NSString stringWithFormat:@"Inference error: %@", errorString];
        NSLog(@"%@", errorString);
        self.resultsTextView.text = errorString;
        return;
      }
      
      NSString *inferenceMessageString = @"Inference results using ";
      if (self.downloadCloudModelButtonSelected) {
        [NSUserDefaults.standardUserDefaults setBool:YES forKey:CloudModelDownloadCompletedKey[cloudmodel]];
        inferenceMessageString = [inferenceMessageString stringByAppendingFormat:@"`%@` cloud model:\n", CloudModelDescription[cloudmodel]];
      } else {
        inferenceMessageString = [inferenceMessageString stringByAppendingFormat:@"`%@` local model:\n", LocalModelDescription[self.currentLocalModel]];;
      }
      self.resultsTextView.text = [inferenceMessageString stringByAppendingString:[self detectionResultsStringRromResults:results]];
    }];
  });
}
  
- (IBAction)openPhotoLibrary:(id)sender {
  _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  [self presentViewController:_imagePicker animated:YES completion:nil];
}
  
- (IBAction)openCamera:(id)sender {
  _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
  [self presentViewController:_imagePicker animated:YES completion:nil];
}
  
- (IBAction)downloadCloudModel:(id)sender {
  [self clearResults];
  _downloadCloudModelButtonSelected = true;
  _resultsTextView.text = _isCloudModelDownloaded ?
  @"Cloud model loaded. Select the `Detect` button to start the inference." :
  @"Downloading cloud model. Once the download has completed, select the `Detect` button to start the inference.";
  if (![_modelManager loadCloudModelWithIsModelQuantized:(_currentCloudModel == CloudModelQuantized)]) {
    _resultsTextView.text = @"Failed to load the cloud model.";
  }
}
  
- (IBAction)modelSwitched:(id)sender {
  [self clearResults];
  [self setUpLocalModel];
  [self setUpCloudModel];
}
  
#pragma mark - Private
  
  /// Sets up the currently selected cloud model.
- (void)setUpCloudModel {
  NSString *modelName = CloudModelDescription[_currentCloudModel];
  if (![_modelManager setUpCloudModelWithName:modelName]) {
    if (_resultsTextView.text) {
      _resultsTextView.text = @"";
    }
    _resultsTextView.text = [NSString stringWithFormat:@"%@\nFailed to set up the `%@` cloud model.", _resultsTextView.text, modelName];
  }
}
  
  /// Sets up the local model.
- (void)setUpLocalModel {
  NSString *localModelName = LocalModelDescription[_currentLocalModel];
  if (![_modelManager setUpLocalModelWithName:localModelName filename:localModelName]) {
    if (_resultsTextView.text) {
      _resultsTextView.text = @"";
    }
    _resultsTextView.text = [_resultsTextView.text stringByAppendingString:@"\nFailed to set up the local model."];
  }
}
  
  /// Returns a string representation of the detection results.
- (NSString *)detectionResultsStringRromResults:(NSArray *)results {
  if (!results) {
    return failedToDetectObjectsMessage;
  }
  
  NSMutableString *resultString = [NSMutableString new];
  for (NSArray *result in results) {
    [resultString appendFormat:@"%@: %@\n", result[0], ((NSNumber *)result[1]).stringValue];
  }
  return resultString;
}
  
  /// Clears the results from the last inference call.
- (void)clearResults {
  _resultsTextView.text = nil;
}
  
  /// Updates the image view with a scaled version of the given image.
- (void)updateImageViewWithImage:(UIImage *)image {
  UIInterfaceOrientation orientation =  UIApplication.sharedApplication.statusBarOrientation;
  CGFloat imageWidth = image.size.width;
  CGFloat imageHeight = image.size.height;
  if (imageWidth <= FLT_EPSILON || imageHeight <= FLT_EPSILON) {
    _imageView.image = image;
    NSLog(@"Failed to update image view because image has invalid size: %@", NSStringFromCGSize(image.size));
    return;
  }
  
  CGFloat scaledImageWidth = 0.0;
  CGFloat scaledImageHeight = 0.0;
  switch (orientation) {
    case UIInterfaceOrientationPortrait:
    case UIInterfaceOrientationPortraitUpsideDown:
    case UIInterfaceOrientationUnknown:
    scaledImageWidth = _imageView.bounds.size.width;
    scaledImageHeight = imageHeight * scaledImageWidth / imageWidth;
    break;
    case UIInterfaceOrientationLandscapeLeft:
    case UIInterfaceOrientationLandscapeRight:
    scaledImageWidth = imageWidth * scaledImageHeight / imageHeight;
    scaledImageHeight = _imageView.bounds.size.height;
  }
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    // Scale image while maintaining aspect ratio so it displays better in the UIImageView.
    UIImage *scaledImage = [image scaledImageWithSize:CGSizeMake(scaledImageWidth, scaledImageHeight)];
    dispatch_async(dispatch_get_main_queue(), ^{
      self.imageView.image = scaledImage ? scaledImage : image;
    });
  });
}
  
#pragma mark - Constants
  
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
  [self clearResults];
  
  UIImage *pickedImage = info[UIImagePickerControllerOriginalImage];
  if (pickedImage) [self updateImageViewWithImage:pickedImage];
  [self dismissViewControllerAnimated:YES completion:nil];
}
  
@end
