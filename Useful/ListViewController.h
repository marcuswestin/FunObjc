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

- (UIView*) listViewForIndex:(ListIndex)index width:(CGFloat)width;
- (void) listSelectIndex:(ListIndex)index view:(UIView*)itemView;

@optional
- (ListIndex)listStartIndex;
- (id) listGroupIdForIndex:(ListIndex)index;

- (UIView*) listHeadViewForGroupId:(id)groupId withIndex:(ListIndex)index width:(CGFloat)width;
- (UIView*) listFootViewForGroupId:(id)groupId withIndex:(ListIndex)index width:(CGFloat)width;

- (void) listTopGroupViewDidMove:(CGRect)frame;
- (void) listTopGroupIdDidChange:(id)topGroupItem withIndex:(ListIndex)index withDirection:(ListViewDirection)direction;

- (void) listSelectGroupWithId:(id)groupId withIndex:(ListIndex)index;
@end


@interface ListViewController : ViewController <UIScrollViewDelegate>
@property UIScrollView* scrollView;
@property UIEdgeInsets listGroupMargins;
@property UIEdgeInsets listItemMargins;
@property ListViewLocation listStartLocation;
@property (weak) id<ListViewDelegate> delegate;

// API methods
//////////////
- (void) reloadDataForList;
- (void) stopScrollingList;
- (void) appendToList:(NSUInteger)numItems startingAtIndex:(ListIndex)firstIndex;
- (void) moveListWithKeyboard:(CGFloat)keyboardHeight;
@end
