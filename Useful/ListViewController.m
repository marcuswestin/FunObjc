//
//  ListViewController.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 8/8/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "ListViewController.h"
#import "UIView+FunStyle.h"
#import "FunTypes.h"
#import "UIColor+Fun.h"
#import "Keyboard.h"
#import "UIScrollView+Fun.h"
#import "UIView+FunStyle.h"
#import "UIView+Fun.h"
#import "NSArray+Fun.h"

// Used to differentiate group head views from item views
@interface ListGroupHeadView : UIView;
@end
@implementation ListGroupHeadView
@end

@interface ListGroupFootView : UIView;
@end
@implementation ListGroupFootView
@end

@interface ListItemView : UIView;
@end
@implementation ListItemView
@end

@implementation ListViewController {
    NSUInteger _withoutScrollEventStack;
    BOOL _hasReachedTheVeryTop;
    BOOL _hasReachedTheVeryBottom;
    NSInteger _topItemIndex;
    NSInteger _bottomItemIndex;
    CGFloat _previousContentOffsetY;
    ListGroupId _bottomGroupId;
    ListGroupId _topGroupId;
    CGFloat _topY;
    CGFloat _bottomY;
}

static CGFloat MAX_Y = 9999999.0f;
static CGFloat START_Y = 99999.0f;

/////////////////
// API methods //
/////////////////

- (void)reloadDataForList {
    [self _withoutScrollEvents:^{
        [self.scrollView empty];
        [self _renderInitialContent];
    }];
    
    // Top should start scrolled down below the navigation bar
    if (_listStartLocation == TOP && !_hasReachedTheVeryBottom) {
        CGFloat amount = 20; // status bar
        if (self.navigationController.navigationBar) {
            amount += self.navigationController.navigationBar.height;
        }
        [_scrollView addContentOffset:-amount animated:NO];
    }
}

- (void)stopScrollingList {
    [_scrollView setContentOffset:_scrollView.contentOffset animated:NO];
}

- (void)appendToList:(NSUInteger)numItems startingAtIndex:(ListIndex)firstIndex {
    if (numItems == 0) {
        return;
    }
    
    if (firstIndex <= _bottomItemIndex) {
        [NSException raise:@"Invalid state" format:@"Appended item with index <= current bottom item index"];
        return;
    }
    
    CGFloat changeInHeight = 0;
    
    CGFloat screenVisibleFold = (_scrollView.height - _scrollView.contentInset.bottom);
    CGFloat offsetVisibleFold = (_scrollView.contentOffset.y + screenVisibleFold);
    
    for (NSUInteger i=0; i<numItems; i++) {
        ListIndex index = firstIndex + i;
        UIView* view = [self _getViewForIndex:index];
        changeInHeight += view.height;
    }
    
    [_scrollView addContentHeight:changeInHeight];
    
    CGFloat scrollAmount = (_bottomY + changeInHeight) - offsetVisibleFold;
    if (scrollAmount > 0) {
        [_scrollView addContentOffset:scrollAmount animated:YES];
    } else {
        [self _extendBottom];
    }
}

- (void)moveListWithKeyboard:(CGFloat)heightChange {
    [_scrollView addContentInsetTop:-heightChange];
    [self.view moveByY:heightChange];
}

- (void)makeRoomForKeyboard:(CGFloat)keyboardHeight {
    [_scrollView addContentInsetBottom:keyboardHeight];
}

//////////////////////
// Setup & Teardown //
//////////////////////

- (void)beforeRender:(BOOL)animated {
    if (!_delegate) {
        if ([self conformsToProtocol:@protocol(ListViewDelegate)]) {
            _delegate = (id<ListViewDelegate>)self;
        } else {
            [NSException raise:@"Error" format:@"Make sure your ListViewController subclass implements the ListViewDelegate protocol"];
        }
    }
    if (!_listStartLocation) {
        _listStartLocation = TOP;
    }
    
    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.alwaysBounceVertical = YES;
    
    [self _setupScrollview];
    [self.view insertSubview:_scrollView atIndex:0];
    
    [Keyboard onWillShow:self callback:^(KeyboardEventInfo *info) {
        [UIView animateWithDuration:info.duration delay:0 options:info.curve animations:^{
            if ([self _shouldMoveWithKeyboard]) {
                [self moveListWithKeyboard:info.heightChange];
            } else {
                [self makeRoomForKeyboard:info.heightChange];
            }
        }];
    }];
    [Keyboard onWillHide:self callback:^(KeyboardEventInfo *info) {
        [UIView animateWithDuration:info.duration delay:0 options:info.curve animations:^{
            if ([self _shouldMoveWithKeyboard]) {
                [self moveListWithKeyboard:info.heightChange];
            } else {
                [self makeRoomForKeyboard:info.heightChange];
            }
        }];
    }];
}

- (BOOL)_shouldMoveWithKeyboard {
    if ([_delegate respondsToSelector:@selector(listShouldMoveWithKeyboard)]) {
        return [_delegate listShouldMoveWithKeyboard];
    } else {
        return YES;
    }
}

- (void)afterRender:(BOOL)animated {
    [self reloadDataForList];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [Keyboard offWillShow:self];
    [Keyboard offWillHide:self];
}

- (void)_setupScrollview {
    [_scrollView setDelegate:self];
    [_scrollView onTap:^(UITapGestureRecognizer *sender) {
        CGPoint tapPoint = [sender locationInView:_scrollView];
        NSInteger index = _topItemIndex;
        for (UIView* view in self._views) {
            BOOL isGroupView = [self _isGroupView:view];
            if (CGRectContainsPoint(view.frame, tapPoint)) {
                if (isGroupView) {
                    if ([_delegate respondsToSelector:@selector(listSelectGroupWithId:withIndex:)]) {
                        ListGroupId groupId = [self _groupIdForIndex:index];
                        [_delegate listSelectGroupWithId:groupId withIndex:index];
                    }
                    
                } else {
                    [_delegate listSelectIndex:index view:view.subviews[0]];
                }
                break;
            }
            if (!isGroupView) {
                index += 1; // Don't count group heads against item indices.
            }
        }
    }];
}

- (void)_renderInitialContent {
    _topY = START_Y;
    _bottomY = START_Y;
    _scrollView.contentSize = CGSizeMake(self.view.width, MAX_Y);
    _scrollView.contentOffset = CGPointMake(0, START_Y);
    _previousContentOffsetY = _scrollView.contentOffset.y;

    ListIndex startIndex = ([_delegate respondsToSelector:@selector(listStartIndex)] ? [_delegate listStartIndex] : 0);
    ListGroupId startGroupId = [self _groupIdForIndex:startIndex];
    
    if (![self _getViewForIndex:startIndex]) {
        return; // Empty list
    }

    if (_listStartLocation == TOP) {
        // Starting at the top, render items downwards
        _topItemIndex = startIndex;
        _bottomItemIndex = startIndex - 1;
        _bottomGroupId = startGroupId;
        [self _addGroupHeadViewForIndex:startIndex withGroupId:startGroupId atLocation:TOP];
        [self _extendBottom];
        [self _extendTop];
        
    } else if (_listStartLocation == BOTTOM) {
        // Starting at the bottom, render items upwards
        _bottomItemIndex = startIndex;
        _topItemIndex = startIndex + 1;
        _topGroupId = startGroupId;
        [self _addGroupFootViewForIndex:startIndex withGroupId:startGroupId atLocation:BOTTOM];
        [self _extendTop];
        [self _extendBottom];
        
    } else {
        [NSException raise:@"Bad" format:@"Invalid listStartLocation %d", _listStartLocation];
    }
}

///////////////////////////////////////////
// Extend list up/down & as view scrolls //
///////////////////////////////////////////

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat contentOffsetY = scrollView.contentOffset.y;
    if (contentOffsetY > _previousContentOffsetY) {
        // scrolled down
        [self _extendBottom];
        
    } else if (contentOffsetY < _previousContentOffsetY) {
        // scrolled up
        [self _extendTop];
        
    } else {
        // no change (contentOffsetY == _previousContentOffsetY)
        return;
    }
    
    _previousContentOffsetY = scrollView.contentOffset.y;
}

- (void)_extendBottom {
    CGFloat targetY = _scrollView.contentOffset.y + _scrollView.height;
    while (_bottomY < targetY) {
        BOOL didAddView = [self _listAddNextViewDown];
        if (!didAddView) {
            [self _didReachTheVeryBottom];
            break;
        }
    }
    [self _cleanupTop];
}

- (void)_extendTop {
    CGFloat targetY = _scrollView.contentOffset.y;
    while (_topY > targetY) {
        BOOL didAddView = [self _listAddNextViewUp];
        if (!didAddView) {
            [self _didReachTheVeryTop];
            break;
        }
    }
    [self _cleanupBottom];
}

- (BOOL)_listAddNextViewDown {
    NSInteger index = _bottomItemIndex + 1;
    UIView* view = [self _getViewForIndex:index];
    
    if (!view) {
        // There are no more items to display at the bottom.
        // Last thing: add a group fiit view at the bottom.
        if ([self _isGroupFootView:[self _bottomView]]) {
            return NO; // All done!
            
        } else {
            [self _addGroupFootViewForIndex:_bottomItemIndex withGroupId:_bottomGroupId atLocation:BOTTOM];
            return YES;
        }
    }
    
    // Check if the new item falls outside of the group of the current bottom-most item.
    ListGroupId groupId = [self _groupIdForIndex:index];
    if (![groupId isEqual:_bottomGroupId]) {
        // This item is the first of a new group. In order, add:
        // 1) A foot view for the current bottom group
        // 2) A gead view for the next bottom group
        // 3) The item view
        
        UIView* bottomView = [self _bottomView];
        if ([self _isItemView:bottomView]) {
            [self _addGroupFootViewForIndex:_bottomItemIndex withGroupId:_bottomGroupId atLocation:BOTTOM];
            return YES;
            
        } else if ([self _isGroupFootView:bottomView]) {
            [self _addGroupHeadViewForIndex:index withGroupId:groupId atLocation:BOTTOM];
            return YES;
            
        } else {
            [NSException raise:@"Error" format:@"Should not get here"];
        }
    }
    
    [self _addView:view at:BOTTOM];
    _bottomItemIndex = index;
    return YES;
}

- (BOOL)_listAddNextViewUp {
    NSInteger index = _topItemIndex - 1;
    
    UIView* view = [self _getViewForIndex:index];
    
    if (!view) {
        // There are no more items to display at the top.
        // Last thing: add a group head view at the top.
        if ([self _isGroupHeadView:[self _topView]]) {
            return NO; // All done!
            
        } else {
            [self _addGroupHeadViewForIndex:_topItemIndex withGroupId:_topGroupId atLocation:TOP];
            return YES;
        }
    }
    
    ListGroupId groupId = [self _groupIdForIndex:index];
    if (![groupId isEqual:_topGroupId]) {
        // This item is the first of a new group. In order, add:
        // 1) A head view for the current top group
        // 2) A foot view for the next top group
        // 3) The item view
        
        UIView* topView = [self _topView];
        if ([self _isItemView:topView]) {
            [self _addGroupHeadViewForIndex:_topItemIndex withGroupId:_topGroupId atLocation:TOP];
            return YES;
            
        } else if ([self _isGroupHeadView:topView]) {
            [self _addGroupFootViewForIndex:index withGroupId:groupId atLocation:TOP];
            return YES;
            
        } else {
            [NSException raise:@"Error" format:@"Should not get here"];
        }
    }
    
    [self _addView:view at:TOP];
    _topItemIndex = index;
    return YES;
}

- (void) _cleanupTop {
    // Clean up views at the top that are now out of sight
    CGFloat targetY = _scrollView.contentOffset.y;
    UIView* view;
    while ((view = [self _topView]) && CGRectGetMaxY(view.frame) < targetY) {
        [view removeFromSuperview];
        _topY += view.height;
        if ([self _isItemView:view]) {
            _topItemIndex += 1;
        } else if ([self _isGroupFootView:view]) {
            [self _setTopGroupId:[self _groupIdForIndex:_topItemIndex] index:_topItemIndex];
        }
    }
}

- (void) _cleanupBottom {
    // Clean up views at the bottom that are now out of sight
    CGFloat targetY = _scrollView.contentOffset.y + _scrollView.height;
    UIView* view;
    while ((view = [self _bottomView]) && CGRectGetMinY(view.frame) > targetY) {
        [view removeFromSuperview];
        _bottomY -= view.height;
        if ([self _isItemView:view]) {
            _bottomItemIndex -= 1;
        } else if ([self _isGroupHeadView:view]) {
            [self _setBottomGroupId:[self _groupIdForIndex:_bottomItemIndex] index:_bottomItemIndex];
        }
    }
}

//////////////////////////////////
// Item & Group Head/Foot Views //
//////////////////////////////////

- (BOOL)_isGroupHeadView:(UIView*)view {
    return [view isMemberOfClass:[ListGroupHeadView class]];
}
- (BOOL)_isGroupFootView:(UIView*)view {
    return [view isMemberOfClass:[ListGroupFootView class]];
}
- (BOOL)_isGroupView:(UIView*)view {
    return [self _isGroupHeadView:view] || [self _isGroupFootView:view];
}
- (BOOL)_isItemView:(UIView*)view {
    return ![self _isGroupView:view];
}

- (CGFloat)_widthForItemView {
    return self.view.width - (_listGroupMargins.left + _listGroupMargins.right + _listItemMargins.left + _listItemMargins.right);
}

- (UIView*)_getViewForIndex:(ListIndex)index {
    UIView* content = [_delegate listViewForIndex:index width:[self _widthForItemView]];
    if (!content) { return nil; }
    CGRect frame = content.bounds;
    frame.size.height += _listItemMargins.top + _listItemMargins.bottom;
    frame.size.width = self.view.width;
    content.y = _listItemMargins.top;
    content.x = _listItemMargins.left + _listGroupMargins.left;
    ListItemView* view = [[ListItemView alloc] initWithFrame:frame];
    [view addSubview:content];
    return view;
}

- (CGFloat)_widthForGroupView {
    return self.view.width - (_listGroupMargins.left + _listGroupMargins.right);
}

- (void) _addGroupFootViewForIndex:(ListIndex)index withGroupId:(id)groupId atLocation:(ListViewLocation)location {
    CGFloat width = [self _widthForGroupView];
    UIView* view = ([_delegate respondsToSelector:@selector(listFootViewForGroupId:withIndex:width:)]
                    ? [_delegate listFootViewForGroupId:groupId withIndex:index width:width]
                    : [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 0)]);
    
    view.x = _listGroupMargins.left;
    view.y = 0;
    
    CGRect frame = view.bounds;
    frame.size.height += _listGroupMargins.bottom;
    ListGroupFootView* groupView = [[ListGroupFootView alloc] initWithFrame:frame];
    [groupView addSubview:view];
    
    [self _addView:groupView at:location];
    if (location == TOP) {
        [self _setTopGroupId:groupId index:index];
    } else {
        [self _setBottomGroupId:groupId index:index];
    }
}

- (void) _addGroupHeadViewForIndex:(ListIndex)index withGroupId:(ListGroupId)groupId atLocation:(ListViewLocation)location {
    CGFloat width = [self _widthForGroupView];
    UIView* view = ([_delegate respondsToSelector:@selector(listHeadViewForGroupId:withIndex:width:)]
                    ? [_delegate listHeadViewForGroupId:groupId withIndex:index width:width]
                    : [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 0)]);
    
    view.x = _listGroupMargins.left;
    view.y = _listGroupMargins.top;
    
    CGRect frame = view.bounds;
    frame.size.height += _listGroupMargins.top;
    ListGroupHeadView* groupView = [[ListGroupHeadView alloc] initWithFrame:frame];
    [groupView addSubview:view];
    
    [self _addView:groupView at:location];
    if (location == TOP) {
        [self _setTopGroupId:groupId index:index];
    } else {
        [self _setBottomGroupId:groupId index:index];
    }
}

- (void)_addView:(UIView*)view at:(ListViewLocation)location {
    if (location == TOP) {
        _topY -= view.height;
        view.y = _topY;
        [_scrollView insertSubview:view atIndex:0];
    } else {
        view.y = _bottomY;
        _bottomY += view.height;
        [_scrollView addSubview:view];
    }
}

////////////////
// Misc stuff //
////////////////

- (ListGroupId)_groupIdForIndex:(ListIndex)index {
    if ([_delegate respondsToSelector:@selector(listGroupIdForIndex:)]) {
        return [_delegate listGroupIdForIndex:index];
    } else {
        return @1;
    }
}

- (void)_setTopGroupId:(ListGroupId)topGroupId index:(ListIndex)index {
    ListGroupId previousTopGroupId = _topGroupId;
    _topGroupId = topGroupId;
    if ([_delegate respondsToSelector:@selector(listTopGroupDidChangeTo:withIndex:from:)]) {
        [_delegate listTopGroupDidChangeTo:topGroupId withIndex:index from:previousTopGroupId];
    }
}

- (void)_setBottomGroupId:(ListGroupId)bottomGroupId index:(ListIndex)index {
    ListGroupId previousBottomGroupId = _bottomGroupId;
    _bottomGroupId = bottomGroupId;
    if ([_delegate respondsToSelector:@selector(listBottomGroupDidChangeTo:withIndex:from:)]) {
        [_delegate listBottomGroupDidChangeTo:bottomGroupId withIndex:index from:previousBottomGroupId];
    }
}

- (void)_didReachTheVeryBottom {
    _hasReachedTheVeryBottom = YES;
    _scrollView.contentSize = CGSizeMake(_scrollView.width, CGRectGetMaxY([self _bottomView].frame));
}

- (void)_didReachTheVeryTop {
    _hasReachedTheVeryTop = YES;
    CGFloat changeInHeight = CGRectGetMinY([self _topView].frame);
    if (changeInHeight == 0) { return; }
    _topY -= changeInHeight;
    _bottomY -= changeInHeight;
    [self _withoutScrollEvents:^{
        _scrollView.contentOffset = CGPointMake(0, _scrollView.contentOffset.y - changeInHeight);
        _scrollView.contentSize = CGSizeMake(self.view.width,  _scrollView.contentSize.height - changeInHeight);
        for (UIView* subView in self._views) {
            [subView moveByY:-changeInHeight];
        }
    }];
}

- (void)_withoutScrollEvents:(Block)block {
    if (_withoutScrollEventStack == 0) {
        _scrollView.delegate = nil;
    }
    _withoutScrollEventStack += 1;
    block();
    _withoutScrollEventStack -= 1;
    if (_withoutScrollEventStack == 0) {
        _scrollView.delegate = self;
    }
}

- (NSArray*)_views {
    if (!_scrollView.subviews || !_scrollView.subviews.count) { return @[]; }
    return [_scrollView.subviews filter:^BOOL(UIView* view, NSUInteger i) {
        // Why is a random UIImageView hanging in the scroll view? Asch.
        return ![view isKindOfClass:UIImageView.class];
    }];
}
- (UIView*)_topView {
    return self._views.firstObject;
}
- (UIView*)_bottomView {
    return self._views.lastObject;
}

@end
