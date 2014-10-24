//
//  CollectionViewLayoutSmallLayout.m
//  IntegrationSNS-iPad
//
//  Created by RyousukeKushihata on 2014/10/24.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import "CollectionViewLayoutSmallLayout.h"

@implementation CollectionViewLayoutSmallLayout
- (id)init
{
    if (!(self = [super init])) return nil;
    
    self.itemSize = CGSizeMake(142, 254);
    self.sectionInset = UIEdgeInsetsMake((([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO) ? 314 : 224), 2, 0, 2);
    self.minimumInteritemSpacing = 10.0f;
    self.minimumLineSpacing = 2.0f;
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    return self;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)oldBounds
{
    return NO;
}

@end
