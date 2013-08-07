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
 
 Class  Responsabilities:
 
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

@end


@interface SelectionHandler : NSObject <ModalTVCDelegate>


@property (strong, nonatomic) id<SelectionHandlerDelegate> delegate;

// VC needed to push the modalsVC
- (id)initWithViewController:(UIViewController *)viewController andDetecorResourceHandler:(DetectorResourceHandler *) detectorResourceHandler;

- (void) addNewDetector;
- (void) selectTrainingImages;


@end
