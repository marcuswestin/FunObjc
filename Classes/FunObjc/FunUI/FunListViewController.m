//
//  FunListViewController.m
//  Dogo-iOS
//
//  Created by Marcus Westin on 8/8/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import "FunListViewController.h"
#import "UIView+FunStyle.h"
#import "FunBase.h"
#import "UIColor+Fun.h"
#import "Keyboard.h"
#import "UIScrollView+Fun.h"
#import "UIView+FunStyle.h"
#import "UIView+Fun.h"
#import "NSArray+Fun.h"

/////////////////////////////////////////////////////////////////
// Custom subviews - differentiate head/foot/item/sticky views //
/////////////////////////////////////////////////////////////////
@interface ListContentView : UIView
@property ListGroupId groupId;
@property ListIndex index;
@property BOOL isGroupHead;
@property BOOL isGroupFoot;
- (BOOL)isGroupView;
- (BOOL)isItemView;
- (UIView*)content;
+ (ListContentView*)withFrame:(CGRect)frame index:(ListIndex)index;
+ (ListContentView*)withFrame:(CGRect)frame footGroupId:(ListGroupId)groupId;
+ (ListContentView*)withFrame:(CGRect)frame headGroupId:(ListGroupId)groupId;
@end
@implementation ListContentView
+ (ListContentView *)withFrame:(CGRect)frame index:(ListIndex)index {
    ListContentView* view = [[ListContentView alloc] initWithFrame:frame];
    view.index = index;
    return view;
}
+ (ListContentView *)withFrame:(CGRect)frame headGroupId:(ListGroupId)groupId {
    ListContentView* view = [[ListContentView alloc] initWithFrame:frame];
    view.groupId = groupId;
    view.isGroupHead = YES;
    return view;
}
+ (ListContentView *)withFrame:(CGRect)frame footGroupId:(ListGroupId)groupId {
    ListContentView* view = [[ListContentView alloc] initWithFrame:frame];
    view.groupId = groupId;
    view.isGroupFoot = YES;
    return view;
}
- (BOOL)isGroupView {
    return _isGroupFoot || _isGroupHead;
}
- (BOOL)isItemView {
    return !_isGroupFoot && !_isGroupHead;
}
- (UIView *)content {
    return self.subviews.firstObject;
}
@end

@interface ListStickyView : UIView
@property CGFloat naturalOffset;
@property ListStickyView* viewAbove;
@property ListStickyView* viewBelow;
@end
@implementation ListStickyView
@end

///////////////////////////
// FunListViewController //
///////////////////////////

@interface FunViewController ()
- (void)_funViewControllerRender:(BOOL)animated;
@end

@implementation FunListViewController {
    NSUInteger _withoutScrollEventStack;
    BOOL _hasReachedTheVeryTop;
    BOOL _hasReachedTheVeryBottom;
    ListViewLocation _listStartLocation;
    NSInteger _topItemIndex;
    NSInteger _bottomItemIndex;
    CGFloat _previousContentOffsetY;
    ListGroupId _bottomGroupId;
    ListGroupId _topGroupId;
    CGFloat _topY;
    CGFloat _bottomY;
    BOOL _scrollViewPurged;

    // Stickies
    ///////////
    ListStickyView* _stickiesTopmost;
    ListStickyView* _stickiesCurrent;
    ListStickyView* _stickiesBottommost;
    NSMutableArray*  _stickiesAddedForView;
    UIView* _stickiesContainerNonInteractive;
    CGFloat _stickyY1;
    CGFloat _stickyY2;
    CGFloat _stickyHeight;
}

static CGFloat MAX_Y = 9999999.0f;
static CGFloat START_Y = 99999.0f;

/////////////////
// API methods //
/////////////////

- (UIView *)visibleViewWithIndex:(ListIndex)index {
    for (ListContentView* view in [self _views]) {
        if (view.isGroupView) { continue; }
        if (view.index == index) {
            return view.content;
        }
    }
    return nil;
}

- (void)reloadDataForList {
    [self _withoutScrollEvents:^{
        [self.scrollView empty];
        [self _renderInitialContent];
        [self _stickiesOnInitialContentRendered];
    }];
    
    // Top should start scrolled down below the navigation bar
    if (_listStartLocation == TOP && !_hasReachedTheVeryBottom) {
        [_scrollView addContentOffset:-self.navigationController.navigationBar.y2 animated:NO];
    } else if (_listStartLocation == BOTTOM) {
        // TODO Check if there is a visible status bar
        // TODO Check if there is a visible navigation bar
        [_scrollView addContentOffset:20 animated:NO];
    }
}

- (void)stopScrollingList {
    [_scrollView setContentOffset:_scrollView.contentOffset animated:NO];
}

- (void)prependToListCount:(NSUInteger)numItems {
    if (numItems == 0) {
        return;
    }
    
    _topItemIndex += numItems;
    _bottomItemIndex += numItems;
    for (ListContentView* view in [self _views]) {
        view.index += numItems;
    }
    
    if (_hasReachedTheVeryTop) {
        [self _fixContentTopByAdding:START_Y];
        _hasReachedTheVeryTop = NO;
    }
    [self _extendTop];
}

- (void)appendToListCount:(NSUInteger)numItems startingAtIndex:(ListIndex)firstIndex {
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
        ListContentView* view = [self _getViewForIndex:index];
        changeInHeight += view.height;
    }
    
    [_scrollView addContentHeight:changeInHeight];
    
    CGFloat scrollAmount = (_bottomY + changeInHeight) - offsetVisibleFold;
    if (scrollAmount > 0) {
        [_scrollView addContentOffset:scrollAmount animated:YES];
    } else {
        [self extendBottom];
    }
}

- (void)moveListWithKeyboard:(CGFloat)heightChange {
    [_scrollView addContentInsetTop:heightChange];
    [_listView moveByY:-heightChange];
}

- (void)makeRoomForKeyboard:(CGFloat)keyboardHeight {
    [_scrollView addContentInsetBottom:keyboardHeight];
}

- (void)setHeight:(CGFloat)height forVisibleViewWithIndex:(ListIndex)index {
    CGFloat __block dHeight = 0;
    for (ListContentView* view in self._views) {
        if (view.isGroupView) {
            view.y += dHeight;
        } else {
            if (view.index == index) {
                dHeight = (height - view.height) + _listItemMargins.bottom + _listItemMargins.top;
                view.height += dHeight;
            } else {
                view.y += dHeight;
            }
        }
    }
    _bottomY += dHeight;
    [_scrollView addContentHeight:dHeight];
}

//////////////////////
// Setup & Teardown //
//////////////////////

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    if (parent) { return; }
    _scrollView.delegate = nil;
}

- (void)_funViewControllerRender:(BOOL)animated {
    [self _beforeRender];
    [super _funViewControllerRender:animated];
    [self _afterRender];
}

- (void)_beforeRender {
    if (!_delegate) {
        if ([self conformsToProtocol:@protocol(FunListViewDelegate)]) {
            _delegate = (id<FunListViewDelegate>)self;
        } else {
            [NSException raise:@"Error" format:@"Make sure your FunListViewController subclass implements the FunListViewDelegate protocol"];
        }
    }
    _listStartLocation = TOP;
    if ([_delegate respondsToSelector:@selector(listStartLocation)]) {
        _listStartLocation = [_delegate listStartLocation];
    }
    
    _listView = [[UIView alloc] initWithFrame:self.view.bounds];
    _scrollView = [[UIScrollView alloc] initWithFrame:_listView.bounds];
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.alwaysBounceVertical = YES;
    [_scrollView appendTo:_listView];
    [self _stickiesBeforeRender];
}

- (void)_handleKeyboardWithHeightChange:(CGFloat)heightChange {
    if ([self _shouldMoveWithKeyboard]) {
        [self moveListWithKeyboard:heightChange];
    } else {
        [self makeRoomForKeyboard:heightChange];
    }
}

- (BOOL)_shouldMoveWithKeyboard {
    if ([_delegate respondsToSelector:@selector(listShouldMoveWithKeyboard)]) {
        return [_delegate listShouldMoveWithKeyboard];
    } else {
        return YES;
    }
}

static UIEdgeInsets insetsForAll;
static BOOL insetsForAllSet;
+ (void)insetAll:(UIEdgeInsets)insets {
    if (insetsForAllSet) {
        [NSException raise:@"Error" format:@"FunListViewController insetAll: called twice"];
    }
    insetsForAll = insets;
    insetsForAllSet = YES;
}

- (void)_afterRender {
    if (insetsForAllSet) {
        UIEdgeInsets groupMargins = self.listGroupMargins;
        groupMargins.top += insetsForAll.top;
        groupMargins.right += insetsForAll.right;
        groupMargins.bottom += insetsForAll.bottom;
        groupMargins.left += insetsForAll.left;
        self.listGroupMargins = groupMargins;
    }
    
    [self reloadDataForList];
    
    [self _setupScrollview];
    [self.view insertSubview:_listView atIndex:0];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [Keyboard onWillShow:self callback:^(KeyboardEventInfo *info) {
        [UIView animateWithDuration:info.duration delay:0 options:info.curve animations:^{
            [self _handleKeyboardWithHeightChange:info.heightChange];
        }];
    }];
    [Keyboard onWillHide:self callback:^(KeyboardEventInfo *info) {
        [UIView animateWithDuration:info.duration delay:0 options:info.curve animations:^{
            [self _handleKeyboardWithHeightChange:info.heightChange];
        }];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [Keyboard offWillShow:self];
    [Keyboard offWillHide:self];
}

- (void)_setupScrollview {
    [_scrollView setDelegate:self];
    [_scrollView onTap:^(UITapGestureRecognizer *sender) {
        CGPoint tapPoint = [sender locationInView:_scrollView];
        NSInteger index = _topItemIndex;
        for (ListContentView* view in self._views) {
            if (CGRectContainsPoint(view.frame, tapPoint)) {
                if (view.isGroupView) {
                    if ([_delegate respondsToSelector:@selector(listSelectGroupWithId:withIndex:)]) {
                        ListGroupId groupId = [self _groupIdForIndex:index];
                        [_delegate listSelectGroupWithId:groupId withIndex:index];
                    }
                    
                } else {
                    [_delegate listSelectIndex:index view:view.content];
                }
                break;
            }
            if (!view.isGroupView) {
                index += 1; // Don't count group heads against item indices.
            }
        }
    }];
}

- (void)selectVisibleIndex:(ListIndex)index {
    for (ListContentView* view in [self _views]) {
        if ([view isItemView] && view.index == index) {
            [_delegate listSelectIndex:index view:view.content];
            return;
        }
    }
}

- (void)_renderInitialContent {
    _scrollView.contentSize = CGSizeMake(_listView.width, MAX_Y);
    _scrollView.contentOffset = CGPointMake(0, START_Y);
    _previousContentOffsetY = _scrollView.contentOffset.y;

    ListIndex startIndex = ([_delegate respondsToSelector:@selector(listStartIndex)] ? [_delegate listStartIndex] : 0);
    ListGroupId startGroupId = [self _groupIdForIndex:startIndex];
    
    if (![self _getViewForIndex:startIndex]) {
        return; // Empty list
    }

    if (_listStartLocation == TOP) {
        // Starting at the top, render items downwards
        _topY = _bottomY = START_Y;
        _topItemIndex = startIndex;
        _bottomItemIndex = startIndex - 1;
        _bottomGroupId = startGroupId;
        {
            ListIndex previousIndex = _topItemIndex - 1;
            ListGroupId previousGroupId = [self _groupIdForIndex:previousIndex];
            ListContentView* previousView = [self _getViewForIndex:previousIndex];
            if (!previousView || !previousGroupId || ![startGroupId isEqual:previousGroupId]) {
                [self _addGroupHeadViewForIndex:startIndex withGroupId:startGroupId atLocation:TOP];
            }
        }
        [self extendBottom];
        [self _extendTop];
        
    } else if (_listStartLocation == BOTTOM) {
        // Starting at the bottom, render items upwards
        _topY = _bottomY = START_Y + _listView.height;
        _bottomItemIndex = startIndex;
        _topItemIndex = startIndex + 1;
        _topGroupId = startGroupId;
        {
            ListIndex nextIndex = _bottomItemIndex + 1;
            ListGroupId nextGroupId = [self _groupIdForIndex:nextIndex];
            ListContentView* nextView = [self _getViewForIndex:nextIndex];
            if (!nextView || !nextGroupId || ![startGroupId isEqual:nextGroupId]) {
                [self _addGroupFootViewForIndex:startIndex withGroupId:startGroupId atLocation:BOTTOM];
            }
        }
        [self _extendTop];
        [self extendBottom];
        
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
        [self extendBottom];
        [self _stickiesUpdateOnContentMoved:UP];
        
    } else if (contentOffsetY < _previousContentOffsetY) {
        // scrolled up
        [self _extendTop];
        [self _stickiesUpdateOnContentMoved:DOWN];
        
    } else {
        // no change (contentOffsetY == _previousContentOffsetY)
        return;
    }
    
    _previousContentOffsetY = scrollView.contentOffset.y;
}

- (void)extendBottom {
    CGFloat targetY = _scrollView.contentOffset.y + _scrollView.height;
    while (_bottomY < targetY) {
        BOOL didAddView = [self _listAddNextViewDown];
        if (!didAddView) {
            [self _onDidReachTheVeryBottom];
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
            [self _onDidReachTheVeryTop];
            break;
        }
    }
    [self _cleanupBottom];
}

- (BOOL)_listAddNextViewDown {
    NSInteger index = _bottomItemIndex + 1;
    ListContentView* view = [self _getViewForIndex:index];
    
    if (!view) {
        // There are no more items to display at the bottom.
        // Last thing: add a group view at the bottom.
        if ([self _bottomView].isGroupView) {
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
        
        ListContentView* bottomView = [self _bottomView];
        if (bottomView.isItemView) {
            [self _addGroupFootViewForIndex:_bottomItemIndex withGroupId:_bottomGroupId atLocation:BOTTOM];
            return YES;
            
        } else if (bottomView.isGroupFoot) {
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
    ListContentView* topView = [self _topView];
    if (_topItemIndex == 0) {
        // There are no more items to display at the top.
        // Last thing: add a group head view at the top.
        if (topView.isGroupHead) {
            return NO; // All done!
            
        } else {
            [self _addGroupHeadViewForIndex:_topItemIndex withGroupId:_topGroupId atLocation:TOP];
            return YES;
        }
    }
    
    NSInteger index = _topItemIndex - 1;
    
    ListContentView* view = [self _getViewForIndex:index];
    if (!view) {
        [NSException raise:@"Error" format:@"Got nil view for list index %d", index];
    }
    
    ListGroupId groupId = [self _groupIdForIndex:index];
    if (![groupId isEqual:_topGroupId]) {
        // This item is the first of a new group. In order, add:
        // 1) A head view for the current top group
        // 2) A foot view for the next top group
        // 3) The item view
        
        if (topView.isItemView) {
            [self _addGroupHeadViewForIndex:_topItemIndex withGroupId:_topGroupId atLocation:TOP];
            return YES;
            
        } else if (topView.isGroupHead) {
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
    ListContentView* view;
    while ((view = [self _topView]) && CGRectGetMaxY(view.frame) < targetY) {
        [view removeFromSuperview];
        _topY += view.height;
        if (view.isItemView) {
            _topItemIndex += 1;
        } else if (view.isGroupFoot) {
            [self _setTopGroupId:[self _groupIdForIndex:_topItemIndex] index:_topItemIndex];
        }
    }
}

- (void) _cleanupBottom {
    // Clean up views at the bottom that are now out of sight
    CGFloat targetY = _scrollView.contentOffset.y + _scrollView.height;
    ListContentView* view;
    while ((view = [self _bottomView]) && CGRectGetMinY(view.frame) > targetY) {
        [view removeFromSuperview];
        _bottomY -= view.height;
        if (view.isItemView) {
            _bottomItemIndex -= 1;
        } else if (view.isGroupHead) {
            [self _setBottomGroupId:[self _groupIdForIndex:_bottomItemIndex] index:_bottomItemIndex];
        }
    }
}

//////////////////////////////////
// Item & Group Head/Foot Views //
//////////////////////////////////
- (CGFloat)_widthForItemView {
    return _listView.width - (_listGroupMargins.left + _listGroupMargins.right + _listItemMargins.left + _listItemMargins.right);
}

- (ListContentView*)_getViewForIndex:(ListIndex)index {
    UIView* content = [_delegate listViewForIndex:index width:[self _widthForItemView]];
    if (!content) { return nil; }
    CGRect frame = content.bounds;
    frame.size.height += _listItemMargins.top + _listItemMargins.bottom;
    frame.size.width = _listView.width;
    content.y = _listItemMargins.top;
    content.x = _listItemMargins.left + _listGroupMargins.left;
    ListContentView* view = [ListContentView withFrame:frame index:index];
    [view addSubview:content];
    return view;
}

- (CGFloat)_widthForGroupView {
    return _listView.width - (_listGroupMargins.left + _listGroupMargins.right);
}

- (void) _addGroupFootViewForIndex:(ListIndex)index withGroupId:(id)groupId atLocation:(ListViewLocation)location {
    CGFloat width = [self _widthForGroupView];
    UIView* view = ([_delegate respondsToSelector:@selector(listViewForGroupFoot:withIndex:width:)]
                    ? [_delegate listViewForGroupFoot:groupId withIndex:index width:width]
                    : [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 0)]);
    
    view.x = _listGroupMargins.left;
    view.y = 0;
    
    CGRect frame = view.bounds;
    frame.size.height += _listGroupMargins.bottom;
    ListContentView* groupView = [ListContentView withFrame:frame footGroupId:groupId];
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
    UIView* view = ([_delegate respondsToSelector:@selector(listViewForGroupHead:withIndex:width:)]
                    ? [_delegate listViewForGroupHead:groupId withIndex:index width:width]
                    : [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 0)]);
    
    view.x = _listGroupMargins.left;
    view.y = _listGroupMargins.top;
    
    CGRect frame = view.bounds;
    frame.size.height += _listGroupMargins.top;
    ListContentView* groupView = [ListContentView withFrame:frame headGroupId:groupId];
    [groupView addSubview:view];
    
    [self _addView:groupView at:location];
    if (location == TOP) {
        [self _setTopGroupId:groupId index:index];
    } else {
        [self _setBottomGroupId:groupId index:index];
    }
}

- (void)_addView:(ListContentView*)view at:(ListViewLocation)location {
    if (location == TOP) {
        _topY -= view.height;
        view.y = _topY;
        [_scrollView insertSubview:view atIndex:0];
    } else {
        view.y = _bottomY;
        _bottomY += view.height;
        [_scrollView addSubview:view];
    }
    if (view.isItemView) {
        [self _stickiesOnDidAddView:view at:location];
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

- (void)_onDidReachTheVeryBottom {
    _hasReachedTheVeryBottom = YES;
    _scrollView.contentSize = CGSizeMake(_scrollView.width, CGRectGetMaxY([self _bottomView].frame));
}

- (void)_onDidReachTheVeryTop {
    _hasReachedTheVeryTop = YES;
    CGFloat changeInHeight = CGRectGetMinY([self _topView].frame);
    if (changeInHeight == 0) { return; }
    [self _fixContentTopByAdding:-changeInHeight];
}

- (void)_fixContentTopByAdding:(CGFloat)changeInHeight {
    _topY += changeInHeight;
    _bottomY += changeInHeight;
    [self _withoutScrollEvents:^{
        [_scrollView addContentOffset:changeInHeight];
        [_scrollView addContentHeight:changeInHeight];
        for (UIView* subView in self._views) {
            [subView moveByY:changeInHeight];
        }
    }];
    [self _stickiesRepositionByChangeInHeight:changeInHeight];
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
    if (!_scrollViewPurged) {
        for (UIView* view in _scrollView.subviews) {
            if (![view isKindOfClass:[ListContentView class]]) {
                [view removeFromSuperview];
            }
        }
        _scrollViewPurged = YES;
    }
    if (!_scrollView.subviews || !_scrollView.subviews.count) { return @[]; }
    return _scrollView.subviews;
}
- (ListContentView*)_topView {
    return self._views.firstObject;
}
- (ListContentView*)_bottomView {
    return self._views.lastObject;
}

//////////////
// Stickies //
//////////////

// Stickies API
///////////////
- (void)setStickyPoint:(CGFloat)y height:(CGFloat)height {
    _stickyY1 = y;
    _stickyY2 = y + height;
    _stickyHeight = height;
}

- (UIView *)stickyView {
    CGFloat left = _listGroupMargins.left + _listItemMargins.left;
    CGFloat right = _listGroupMargins.right + _listItemMargins.right;
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(left, 0, _listView.width - left - right, 0)];
    [_stickiesAddedForView addObject:view];
    return view;
}

// Stickies Internal
////////////////////
- (void)_stickiesBeforeRender {
    _stickiesAddedForView = [NSMutableArray array];
    _stickiesContainerNonInteractive = [UIView.appendTo(_listView) render];
}

- (void)_stickiesOnInitialContentRendered {
    if (!_stickiesTopmost) {
        if (_stickyY1 || _stickyY2) {
            [NSException raise:@"Error" format:@"Expected at least one sticky to be rendered in list view"];
        }
        return;
    }
    // Elect a first sticky
    ListStickyView* closest = _stickiesTopmost;
    CGFloat distance = 999999;
    CGFloat point = _stickyY1 + (_stickyY2 - _stickyY1)/2;
    ListStickyView* view = closest;
    while ((view = view.viewBelow)) {
        if (abs(view.center.y - point) < distance) {
            distance = abs(view.center.y - point);
            closest = view;
        }
    }
    _stickiesCurrent = closest;
    _stickiesCurrent.y = _stickyY1;
}

- (void)_stickiesUpdateOnContentMoved:(ListViewDirection)contentMoved {
    CGFloat offset = _scrollView.contentOffset.y;

    ListStickyView* stickyView = _stickiesTopmost;
    while (stickyView) {
        if (stickyView != _stickiesCurrent) {
            stickyView.y = stickyView.naturalOffset - offset;
        }
        stickyView = stickyView.viewBelow;
    }

    ListStickyView* enroaching;
    // TODO There may be multiple enroaching per loop
    if (_stickiesCurrent.viewBelow.y < _stickyY2) {
        // From below
        enroaching = _stickiesCurrent.viewBelow;
        if (enroaching.y <= _stickyY1) {
            _stickiesCurrent.naturalOffset = offset + _stickyY1 - _stickyHeight;
            _stickiesCurrent.y = _stickiesCurrent.naturalOffset - offset;
            _stickiesCurrent = enroaching;
            _stickiesCurrent.y = _stickyY1;
        } else {
            _stickiesCurrent.y2 = enroaching.y;
        }
    }
    if (_stickiesCurrent.viewAbove.y2 > _stickyY1) {
        // From above
        enroaching = _stickiesCurrent.viewAbove;
        if (enroaching.y2 >= _stickyY2) {
            _stickiesCurrent.naturalOffset = offset + _stickyY2;
            _stickiesCurrent.y = _stickiesCurrent.naturalOffset - offset;
            _stickiesCurrent = enroaching;
            _stickiesCurrent.y = _stickyY1;
        } else {
            _stickiesCurrent.y = enroaching.y2;
        }
    }

    if (contentMoved == UP) {
        [self _stickiesCleanupTop];
        
    } else if (contentMoved == DOWN) {
        [self _stickiesCleanupBottom];
    }
}

- (void)_stickiesOnDidAddView:(ListContentView*)view at:(ListViewLocation)location {
    if (!_stickiesAddedForView.count) { return; }
    ListStickyView* stickyView = [ListStickyView.appendTo(_stickiesContainerNonInteractive).h(_stickyHeight) render];
    for (UIView* view in _stickiesAddedForView) {
        [stickyView addSubview:view];
    }
    stickyView.naturalOffset = view.y;
    stickyView.y = stickyView.naturalOffset - _scrollView.contentOffset.y;
    [_stickiesAddedForView removeAllObjects];

    if (!_stickiesTopmost) {
        // First sticky
        _stickiesTopmost = stickyView;
        _stickiesBottommost = stickyView;
    } else if (location == TOP) {
        [self _stickyMakeTopmost:stickyView];
    } else if (location == BOTTOM) {
        [self _stickyMakeBottommost:stickyView];
    }
}

-(void)_stickiesRepositionByChangeInHeight:(CGFloat)changeInHeight {
    ListStickyView* stickyView = _stickiesTopmost;
    while (stickyView) {
        stickyView.naturalOffset += changeInHeight;
        stickyView = stickyView.viewBelow;
    }
}

// Stickies linked list
///////////////////////
- (void)_stickyMakeBottommost:(ListStickyView*)stickyView {
    _stickiesBottommost.viewBelow = stickyView;
    stickyView.viewAbove = _stickiesBottommost;
    _stickiesBottommost = stickyView;
}
- (void)_stickyMakeTopmost:(ListStickyView*)stickyView {
    stickyView.viewBelow = _stickiesTopmost;
    _stickiesTopmost.viewAbove = stickyView;
    _stickiesTopmost = stickyView;
}
- (void)_stickiesCleanupTop {
    CGFloat targetY = 0;
    while (_stickiesTopmost && _stickiesTopmost != _stickiesCurrent && _stickiesTopmost.y2 < targetY) {
        [_stickiesTopmost removeFromSuperview];
        _stickiesTopmost = _stickiesTopmost.viewBelow;
        _stickiesTopmost.viewAbove = nil;
    }
}
- (void)_stickiesCleanupBottom {
    CGFloat targetY = _listView.y2;
    while (_stickiesBottommost && _stickiesBottommost != _stickiesCurrent && _stickiesBottommost.y > targetY) {
        [_stickiesBottommost removeFromSuperview];
        _stickiesBottommost = _stickiesBottommost.viewAbove;
        _stickiesBottommost.viewBelow = nil;
    }
}

@end
