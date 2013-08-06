//
//  SelectionHandler.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 06/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "SelectionHandler.h"


@interface SelectionHandler()
{
    UIViewController *_viewController; //to push the modals
    ModalTVC *_modalTVC;
    
    DetectorResourceHandler *_detectorResourceHandler;
    NSArray *_detectorTargetClasses;
    NSString *_modalSent; //identifier of the kind of modal that has been shown
}


@end


@implementation SelectionHandler

#pragma mark -
#pragma mark Initialization

- (id)initWithViewController:(UIViewController *)viewController andDetecorResourceHandler:(DetectorResourceHandler *) detectorResourceHandler
{
    if (self = [super init]) {
        
        _viewController = viewController;
        
        _modalTVC = [[ModalTVC alloc] init];
        _modalTVC.delegate = self;
        
        _detectorResourceHandler = detectorResourceHandler;
        
    }
    return self;
}


#pragma mark -
#pragma mark Public Methods

- (void) addNewDetector
{
    [self configureModalForClassSelection];
    [_viewController presentModalViewController:_modalTVC animated:YES];
}

- (void) selectTrainingImages
{
    //set the current classifier clases
    _detectorTargetClasses = [[self.delegate currentDetector] targetClasses];
    
    [self configureModalForTrainingImages];
    [_viewController presentModalViewController:_modalTVC animated:YES];
}


#pragma mark -
#pragma mark ModalTVCDelegate

- (void) userSlection:(NSArray *)selectedItems for:(NSString *)identifier;
{

    if([identifier isEqualToString:@"classes"]){
        NSArray *availableObjectClasses = [_detectorResourceHandler getObjectClassesNames];
        NSMutableArray *classes = [[NSMutableArray alloc] init];
        for(NSNumber *sel in selectedItems)
            [classes addObject:[availableObjectClasses objectAtIndex:sel.intValue]];
        
        _detectorTargetClasses = [NSArray arrayWithArray:classes];
        
        //Present the modal for training images
        [_modalTVC dismissViewControllerAnimated:YES completion:^{
            [self configureModalForFirstTrainingImages];
            [_viewController presentModalViewController:_modalTVC animated:YES];
        }];

        
    }else if([identifier isEqualToString:@"images"]){
        
        //split train and test
        NSMutableArray *traingImagesNames = [[NSMutableArray alloc] init];
        NSMutableArray *testImagesNames = [[NSMutableArray alloc]init];
        
        NSArray *availablePositiveImagesNames = [_detectorResourceHandler getImageNamesContainingClasses:_detectorTargetClasses];
        
        for(int i=0; i<availablePositiveImagesNames.count; i++){
            NSUInteger index = [selectedItems indexOfObject:[NSNumber numberWithInt:i]];
            if(index != NSNotFound) [traingImagesNames addObject:[availablePositiveImagesNames objectAtIndex:i]];
            else [testImagesNames addObject:[availablePositiveImagesNames objectAtIndex:i]];
        }
        if(testImagesNames.count == 0) testImagesNames = traingImagesNames;
        
        [self.delegate trainDetectorForClasses:_detectorTargetClasses
                        andTrainingImagesNames:traingImagesNames
                            andTestImagesNames:testImagesNames];
        [_modalTVC dismissModalViewControllerAnimated:YES];
    }
}

- (void) selectionCancelled
{
    if(![_modalSent isEqualToString:@"images"])
        [_viewController.navigationController popViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Private Methods

- (void) configureModalForClassSelection
{
    _modalSent = @"classes";
    
    _modalTVC.showCancelButton = YES;
    _modalTVC.modalTitle = @"New Detector";
    _modalTVC.modalSubtitle = @"1 of 2: select class(es)";
    _modalTVC.modalID = @"classes";
    _modalTVC.multipleChoice = YES;
    _modalTVC.doneButtonTitle = @"Create";
    
    //data to be loaded in the modaltvcc
    _modalTVC.data = [_detectorResourceHandler getObjectClassesNames];

}

- (void) configureModalForFirstTrainingImages
{
    _modalSent = @"imagesFirstTime";
    
    [self configureModalForTrainingImages];
    _modalTVC.modalTitle = @"New Detector";
    _modalTVC.modalSubtitle = @"2 of 2: select training image(es)";
}

- (void) configureModalForTrainingImages
{
    _modalSent = @"images";
    
    _modalTVC.modalTitle = @"Train Detector";
    _modalTVC.modalSubtitle = @"1 of 1: select training images";
    _modalTVC.doneButtonTitle = @"Train";
    _modalTVC.modalID = @"images";
    _modalTVC.multipleChoice = NO;
    _modalTVC.showCancelButton = YES;
    
    NSArray *availablePositiveImagesNames = [_detectorResourceHandler getImageNamesContainingClasses:_detectorTargetClasses];
    
    NSMutableArray *imagesList = [[NSMutableArray alloc] init];
    Classifier *detector = [self.delegate currentDetector];
    for(NSString *imageName in availablePositiveImagesNames){
        
        //set the image
        [imagesList addObject:[_detectorResourceHandler getThumbnailImageWithImageName:imageName]];
        
        //set the selected images
        if(detector.imagesUsedTraining == nil || [detector.imagesUsedTraining indexOfObject:imageName]!= NSNotFound)
            [_modalTVC.selectedItems addObject:[NSNumber numberWithInt:(imagesList.count-1)]];
    }
    
    //data to be loaded in the modaltvc
    _modalTVC.data = imagesList;
}

@end
