//
//  CollectionViewTransitionLayout.h
//  IntegrationSNS-iPad
//
//  Created by RyousukeKushihata on 2014/10/24.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CollectionViewTransitionLayout : UICollectionViewTransitionLayout

@property (nonatomic) UIOffset offset;
@property (nonatomic) CGFloat progress;
@property (nonatomic) CGSize itemSize;

@end
