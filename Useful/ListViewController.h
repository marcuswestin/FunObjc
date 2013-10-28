//
//  ListViewController.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 8/8/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"

typedef NSInteger ListIndex;

enum ListViewLocation { TOP=1, BOTTOM=2 };
typedef enum ListViewLocation ListViewLocation;

enum ListViewDirection { UP=-1, DOWN=1 };
typedef enum ListViewDirection ListViewDirection;

@protocol ListViewDelegate <NSObject>
@required
//- (id) listItemForIndex:(NSInteger)index;
- (UIView*) listViewForIndex:(ListIndex)index withWidth:(CGFloat)width;
- (void) listSelectIndex:(ListIndex)index view:(UIView*)itemView;
@optional
- (ListIndex)listStartIndex;
- (UIView*) listViewForGroupId:(id)groupId withIndex:(ListIndex)index withWidth:(CGFloat)width;
- (id) listGroupIdForIndex:(ListIndex)index;
- (void) listTopGroupViewDidMove:(CGRect)frame;
- (void) listTopGroupIdDidChange:(id)topGroupItem withIndex:(ListIndex)index withDirection:(ListViewDirection)direction;
- (void) listSelectGroupWithId:(id)groupId withIndex:(ListIndex)index;
- (BOOL) listShouldMoveWithKeyboard;
@end


@interface ListViewController : ViewController <UIScrollViewDelegate>
@property UIScrollView* scrollView;
@property UIEdgeInsets listGroupMargins;
@property UIEdgeInsets listItemMargins;
@property ListViewLocation listStartLocation;

- (void) reloadData;
- (void) stopScrolling;

- (void) listAppendCount:(NSUInteger)count startingAtIndex:(ListIndex)firstIndex;
- (void) listMoveWithKeyboard:(CGFloat)keyboardHeight;
@end
