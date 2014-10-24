//
//  TransitionController.h
//  IntegrationSNS-iPad
//
//  Created by RyousukeKushihata on 2014/10/24.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol HATransitionControllerDelegate <NSObject>
- (void)interactionBeganAtPoint:(CGPoint)point;
@end


@interface TransitionController : NSObject

@property (nonatomic) id <HATransitionControllerDelegate> delegate;
@property (nonatomic) BOOL hasActiveInteraction;
@property (nonatomic) UINavigationControllerOperation navigationOperation;
@property (nonatomic) UICollectionView *collectionView;

- (instancetype)initWithCollectionView:(UICollectionView*)collectionView;


@end
