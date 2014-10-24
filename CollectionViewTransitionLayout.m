//
//  CollectionViewTransitionLayout.m
//  IntegrationSNS-iPad
//
//  Created by RyousukeKushihata on 2014/10/24.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import "CollectionViewTransitionLayout.h"

static NSString *kOffsetH = @"offsetH";
static NSString *kOffsetV = @"offsetV";

@implementation CollectionViewTransitionLayout
- (void)setTransitionProgress:(CGFloat)transitionProgress
{
    [super setTransitionProgress:transitionProgress];
    
    // return the most recently set values for each key
    CGFloat offsetH = [self valueForAnimatedKey:kOffsetH];
    CGFloat offsetV = [self valueForAnimatedKey:kOffsetV];
    _offset = UIOffsetMake(offsetH, offsetV);
}
- (void)setOffset:(UIOffset)offset
{
    // store the floating-point values with out meaningful keys for our transition layout object
    [self updateValue:offset.horizontal forAnimatedKey:kOffsetH];
    [self updateValue:offset.vertical forAnimatedKey:kOffsetV];
    _offset = offset;
}
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray *attributes = [super layoutAttributesForElementsInRect:rect];
    
    for (UICollectionViewLayoutAttributes *currentAttribute in attributes)
    {
        CGPoint currentCenter = currentAttribute.center;
        CGPoint updatedCenter = CGPointMake(currentCenter.x, currentCenter.y + self.offset.vertical);
        currentAttribute.center = updatedCenter;
    }
    return attributes;
}
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // returns the layout attributes for the item at the specified index path
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    CGPoint currentCenter = attributes.center;
    CGPoint updatedCenter = CGPointMake(currentCenter.x + self.offset.horizontal, currentCenter.y + self.offset.vertical);
    attributes.center = updatedCenter;
    return attributes;
}

@end
