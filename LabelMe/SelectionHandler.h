//
//  SelectionHandler.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 06/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ModalTVC.h"
#import "Detector.h"
#import "DetectorResourceHandler.h"

/*
 
 Class  Responsibilities:
 
 - Coordinate the visualization of modals for selecting the class and for
    selecting the training images
 - Inform the delegate (|DetectorDescriptionVC|) of the selections
 - Return to the |DetectorGalleryVC| in case of cancelling first training
 
 */



@protocol SelectionHandlerDelegate <NSObject>

// Inform about the selection made.
// For a new detector is important to also set the target classes chosen
- (void) trainDetectorForClasses:(NSArray *)classes
          andTrainingImagesNames:(NSArray *)trainingImagesNames andTestImagesNames:(NSArray *)testImagesNames;

// Request the current detector
// Used to obtain the target classes and current training images
- (Detector *) currentDetector;

// If something go wrong during the selection, inform the delegate
// and make it show an error message
- (void) showErrorString:(NSString *)errorString;

@end


@interface SelectionHandler : NSObject <ModalTVCDelegate>


@property (strong, nonatomic) id<SelectionHandlerDelegate> delegate;

// VC needed to push the modalsVC
- (id)initWithViewController:(UIViewController *)viewController andDetecorResourceHandler:(DetectorResourceHandler *) detectorResourceHandler;

// Show modalTVC with (1st) classes to select and (2nd) images to select for training set
- (void) addNewDetector;

// Show modalTVC for selecting the images for the training set
- (void) selectTrainingImages;


@end
