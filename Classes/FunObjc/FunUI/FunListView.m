//
//  FunListView.m
//  Dogo iOS
//
//  Created by Marcus Westin on 1/28/14.
//  Copyright (c) 2014 Flutterby Labs Inc. All rights reserved.
//

#import "FunListView.h"
#import "UIView+Fun.h"

// Custom subviews - differentiate head/foot/item views //
//////////////////////////////////////////////////////////

static ListViewOrientation Vertical = ListViewOrientationVertical;

@interface ListContentView : UIView
@property ListGroupId groupId;
@property ListViewIndex index;
@property BOOL isGroupHead;
@property BOOL isGroupFoot;
@property BOOL isEndView;
@property (readonly) UIView* content;
@end
@implementation ListContentView
+ (ListContentView *)withFrame:(CGRect)frame index:(ListViewIndex)index content:(UIView*)content {
    ListContentView* view = [[ListContentView alloc] initWithFrame:frame];
    view.index = index;
    [view addSubview:content];
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
+ (ListContentView *)endViewWithFrame:(CGRect)frame {
    ListContentView* view = [[ListContentView alloc] initWithFrame:frame];
    view.isEndView = YES;
    return view;
}
- (BOOL)isGroupView {
    return _isGroupFoot || _isGroupHead;
}
- (BOOL)isItemView {
    return !_isGroupFoot && !_isGroupHead && !_isEndView;
}
- (UIView *)content {
    return self.subviews.firstObject;
}
@end

///////////////////////////
// FunListViewController //
///////////////////////////

@interface FunListViewStickyGroup ()
- (id)initWithListView:(FunListView*)view point:(CGFloat)y height:(CGFloat)height viewOffset:(CGFloat)viewOffset;
- (void)onInitialContentRendered;
- (void)onContentMoved:(ListViewDirection)direction;
- (void)onDidAddView:(ListContentView*)view location:(ListViewLocation)location;
- (void)onListViewChangeInHeight:(CGFloat)changeInHeight;
@end

@implementation FunListView {
    NSUInteger _withoutScrollEventStack;
    BOOL _hasReachedTheVeryTop;
    BOOL _hasReachedTheVeryBottom;
    ListViewIndex _topListViewIndex;
    ListViewIndex _bottomItemIndex;
    ListGroupId _bottomGroupId;
    ListGroupId _topGroupId;
    CGFloat _previousContentOffset;
    CGFloat _topEdge;
    CGFloat _bottomEdge;
    NSUInteger _scrollViewPurgedCount;
    NSMutableArray* _stickyGroups;
    UIView* _emptyView;
    ListContentView* _endViewTop;
    BOOL _hasContent;
    BOOL _hasCalledEmpty;
}

static CGFloat MAX_EDGE = 9999999.0f;
static CGFloat START_EDGE = 99999.0f;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
//        _scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    }
    return self;
}

@synthesize delegate=_delegate;
- (void)setDelegate:(id<FunListViewDelegate>)delegate {
    _delegate = delegate;
    [self _beforeRender];
    
    if (insetsForAllSet) {
        UIEdgeInsets insets = _scrollView.contentInset;
        insets.top += insetsForAll.top;
        insets.right += insetsForAll.right;
        insets.bottom += insetsForAll.bottom;
        insets.left += insetsForAll.left;
        _scrollView.contentInset = insets;
    }
    [self _setupScrollview];
    [self reloadDataForList];
}
- (id<FunListViewDelegate>)delegate {
    return _delegate;
}

/////////////////
// API methods //
/////////////////

- (void)expandToSizeOfContent {
    [self _withoutScrollEvents:^{
        [self _onDidReachTheVeryTop];
        BOOL didAddView;
        while ((didAddView = [self _listAddNextViewDown])) {
            // Just keep adding views
        }
        self.scrollView.height = [self _bottomView].y2;
        self.height = self.scrollView.height;
    }];
}

- (UIView *)makeTopViewWithHeight:(CGFloat)height {
    _endViewTop = [ListContentView endViewWithFrame:CGRectMake(0, 0, _scrollView.width, height)];
    return _endViewTop;
}

- (UIView *)visibleViewWithIndex:(ListViewIndex)index {
    return [self visibleContentViewWithIndex:index].content;
}
- (ListContentView*)visibleContentViewWithIndex:(ListViewIndex)index {
    return [self._views pickOne:^BOOL(ListContentView* view, NSUInteger i) {
        return view.isItemView && view.index == index;
    }];
}

- (void)reloadDataForList {
    [self _renderInitialContent];
    
    // Top should start scrolled down below the navigation bar
    if (_startLocation == ListViewLocationTop && !_hasReachedTheVeryBottom) {
        //        [_scrollView addContentOffset:-self.navigationController.navigationBar.y2 animated:NO];
    } else if (_startLocation == ListViewLocationBottom) {
        // TODO Check if there is a visible status bar
        // TODO Check if there is a visible navigation bar
//        [_scrollView addContentOffset:20 animated:NO];
    }
}

- (void)stopScrollingList {
    [_scrollView setContentOffset:_scrollView.contentOffset animated:NO];
}

- (void)prependToListCount:(NSUInteger)numItems {
    if (numItems == 0) {
        return;
    }
    
    if (!_hasContent) {
        [self _renderInitialContent];
        return;
    }
    
    _topListViewIndex += numItems;
    _bottomItemIndex += numItems;
    for (ListContentView* view in [self _views]) {
        view.index += numItems;
    }
    
    if (_hasReachedTheVeryTop) {
        [self _fixTopEdgeByAdding:START_EDGE];
        _hasReachedTheVeryTop = NO;
    }
    
    // If the current top view is a group head, we may have prepended an item
    // above current top group above when it should have gone inside the group
    ListContentView* topView = [self _topView];
    if (topView.isGroupHead) {
        [topView removeFromSuperview];
        _topEdge += [self _orientedSizeOfView:topView];
    }
    
    [self extendTop];
}

- (CGFloat)_orientedContentOffset {
    return (_orientation == Vertical ? _scrollView.contentOffset.y : _scrollView.contentOffset.x);
}
- (CGFloat)_orientedSize {
    return (_orientation == Vertical ? self.height : self.width);
}
- (CGFloat)_orientedSizeOfView:(UIView*)view {
    return (_orientation == Vertical ? view.height : view.width);
}
- (void)_addOrientedContentOffset:(CGFloat)scrollAmount animated:(BOOL)animated {
    if (animated) {
        if (_orientation == Vertical) {
            [_scrollView addContentOffsetY:scrollAmount animated:YES];
        } else {
            [_scrollView addContentOffsetX:scrollAmount animated:YES];
        }
    } else {
        if (_orientation == Vertical) {
            [_scrollView addContentOffsetY:scrollAmount];
        } else {
            [_scrollView addContentOffsetX:scrollAmount];
        }
    }
}
- (void)_addOrientedContentSize:(CGFloat)change {
    if (_orientation == Vertical) {
        [_scrollView addContentHeight:change];
    } else {
        [_scrollView addContentWidth:change];
    }
}

- (void)appendToListCount:(NSUInteger)numItems startingAtIndex:(ListViewIndex)firstIndex {
    if (numItems == 0) {
        return;
    }
    
    if (_hasContent && firstIndex <= _bottomItemIndex) {
        [NSException raise:@"Invalid state" format:@"Appended item with index <= current bottom item index"];
        return;
    }
    
    if (!_hasContent) {
        [self _renderInitialContent];
        return;
    }
    
    CGFloat changeInSize = 0;
    
    CGFloat inset = (_orientation == Vertical ? _scrollView.contentInset.bottom : _scrollView.contentInset.right);
    CGFloat screenVisibleFold = ([self _orientedSize] - inset);
    CGFloat offsetVisibleFold = (self._orientedContentOffset + screenVisibleFold);
    
    for (NSUInteger i=0; i<numItems; i++) {
        ListViewIndex index = firstIndex + i;
        ListContentView* view = [self _getViewForIndex:index location:ListViewLocationBottom];
        changeInSize += [self _orientedSizeOfView:view];
    }
    
    [self _addOrientedContentSize:changeInSize];
    
    CGFloat scrollAmount = (_bottomEdge + changeInSize) - offsetVisibleFold;
    if (scrollAmount > 0) {
        [self _addOrientedContentOffset:scrollAmount animated:YES];
    } else {
        [self extendBottom];
    }
}

- (void)moveListWithKeyboard:(CGFloat)heightChange {
    [_scrollView addContentInsetTop:heightChange];
    for (UIView* view in self.subviews) {
        [view moveByY:-heightChange];
    }
}

- (CGFloat)setHeight:(CGFloat)height forVisibleViewWithIndex:(ListViewIndex)index {
    ListContentView* view = [self visibleContentViewWithIndex:index];
    return (view ? [self addSize:(CGSizeMake(0, height - view.height)) toVisibleView:view].height : 0);
}
- (CGFloat)setWidth:(CGFloat)width forVisibleViewWithIndex:(ListViewIndex)index {
    ListContentView* view = [self visibleContentViewWithIndex:index];
    return (view ? [self addSize:(CGSizeMake(width - view.width, 0)) toVisibleView:view].width : 0);
}
- (CGSize)addSize:(CGSize)addSize toVisibleView:(ListContentView*)targetView {
    for (ListContentView* view in self._views) {
        if (view == targetView) {
            [view addSize:addSize];
        } else if (view.index > targetView.index) {
            [view moveByX:addSize.width y:addSize.height];
        }
    }
    _bottomEdge += (_orientation == Vertical ? addSize.height : addSize.width);
    [_scrollView addContentSize:addSize];
    return addSize;
}


- (FunListViewStickyGroup*)stickyGroupWithPosition:(CGFloat)y height:(CGFloat)height viewOffset:(CGFloat)viewOffset {
    id group = [[FunListViewStickyGroup alloc] initWithListView:self point:y height:height viewOffset:viewOffset];
    [_stickyGroups addObject:group];
    return group;
}

//////////////////////
// Setup & Teardown //
//////////////////////

- (void)willMoveToWindow:(UIWindow *)newWindow {
    if (newWindow) {
        [Keyboard onWillChange:self callback:^(KeyboardEventInfo *info) {
            if (_shouldMoveWithKeyboard) {
                [UIView animateWithDuration:info.duration delay:0 options:info.curve animations:^{
                    [self moveListWithKeyboard:info.heightChange];
                }];
            } else {
                [_scrollView addContentInsetBottom:info.heightChange]; // make room for keyboard
            }
        }];
    } else {
        [Keyboard offWillChange:self];
    }
}

- (void)_beforeRender {
    if (!_delegate) {
        [NSException raise:@"Error" format:@"Missing FunListView delegate"];
    }
    
    if (!_startLocation) {
        _startLocation = ListViewLocationTop;
    }
    if (!_orientation) {
        _orientation = ListViewOrientationVertical;
    }
    
    _stickyGroups = [NSMutableArray array];
    
    if (!self.loadingMessage) {
        self.loadingMessage = @"Loading";
    }
    if (!self.emptyMessage) {
        self.emptyMessage = @"Nothing here";
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

- (void)_setupScrollview {
    [_scrollView appendTo:self];
    [_scrollView setDelegate:self];
    if (_orientation == Vertical) {
        _scrollView.alwaysBounceVertical = YES;
        _scrollView.showsVerticalScrollIndicator = NO;
    } else {
        _scrollView.alwaysBounceHorizontal = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
    }
    [_scrollView onTap:self selector:@selector(_onTap:)];
}

- (void)_onTap:(UITapGestureRecognizer*)tap {
    CGPoint tapPoint = [tap locationInView:_scrollView];
    ListContentView* view = [self visibleContentViewAtPoint:tapPoint];
    CGPoint contentTapPoint = [_scrollView convertPoint:tapPoint toView:view.content];
    if ([view isItemView]) {
        [_delegate listSelectIndex:view.index tapPoint:contentTapPoint];
    } else {
        ListGroupId groupId = [self _groupIdForIndex:view.index];
        if ([_delegate respondsToSelector:@selector(listSelectGroupWithId:withIndex:)]) {
            [_delegate listSelectGroupWithId:groupId withIndex:view.index];
        }
    }
}

- (ListContentView*)visibleContentViewAtPoint:(CGPoint)point {
    for (ListContentView* view in self._views) {
        if (CGRectContainsPoint(view.frame, point)) {
            return view;
        }
    }
    return nil;
}

- (ListViewIndex)indexForVisibleItemViewAtPoint:(CGPoint)point {
    ListContentView* view = [self visibleContentViewAtPoint:point];
    if (!view || !view.isItemView) {
        return -1;
    }
    return view.index;
}

- (void)_renderEmpty {
    if (_emptyView) {
        [_emptyView removeAndClean];
    }
    _emptyView = [UIView.appendAfter(_scrollView).fill render];
    _hasContent = NO;
    if ([_delegate respondsToSelector:@selector(listRenderEmptyInView:isFirst:)]) {
        [_delegate listRenderEmptyInView:_emptyView isFirst:!_hasCalledEmpty];
    } else {
        [UILabel.appendTo(_emptyView).text(_hasCalledEmpty ? self.emptyMessage : self.loadingMessage).size.center render];
    }
    _hasCalledEmpty = YES;
}

- (void)_renderInitialContent {
    [_scrollView empty];
    
    [self _withoutScrollEvents:^{
        _scrollView.contentSize = (_orientation == Vertical ? CGSizeMake(self.width, MAX_EDGE) : CGSizeMake(MAX_EDGE, self.height));
        _scrollView.contentOffset = (_orientation == Vertical ? CGPointMake(0, START_EDGE) : CGPointMake(START_EDGE, 0));
        _previousContentOffset = START_EDGE;
    }];
    
    
    ListGroupId startGroupId = [self _groupIdForIndex:_startIndex];
    
    if (![_delegate hasViewForIndex:_startIndex]) {
        [self _renderEmpty];
        return; // Empty list
    }
    
    if (_startLocation == ListViewLocationTop) {
        // Starting at the top, render items downwards
        _topEdge = _bottomEdge = START_EDGE;
        _topListViewIndex = _startIndex;
        _bottomItemIndex = _startIndex - 1;
        _bottomGroupId = startGroupId;
        {
            ListViewIndex previousIndex = _topListViewIndex - 1;
            ListGroupId previousGroupId = [self _groupIdForIndex:previousIndex];
            BOOL hasPreviousView = [_delegate hasViewForIndex:previousIndex];
            if (!hasPreviousView || !previousGroupId || ![startGroupId isEqual:previousGroupId]) {
                [self _addGroupHeadViewForIndex:_startIndex withGroupId:startGroupId atLocation:ListViewLocationTop];
            }
        }
        [self extendBottom];
        [self extendTop];
        
    } else if (_startLocation == ListViewLocationBottom) {
        // Starting at the bottom, render items upwards
        _topEdge = _bottomEdge = START_EDGE + [self _orientedSize];
        _bottomItemIndex = _startIndex;
        _topListViewIndex = _startIndex + 1;
        _topGroupId = startGroupId;
        {
            ListViewIndex nextIndex = _bottomItemIndex + 1;
            ListGroupId nextGroupId = [self _groupIdForIndex:nextIndex];
            BOOL hasNextView = [_delegate hasViewForIndex:nextIndex];
            if (!hasNextView || !nextGroupId || ![startGroupId isEqual:nextGroupId]) {
                [self _addGroupFootViewForIndex:_startIndex withGroupId:startGroupId atLocation:ListViewLocationBottom];
            }
        }
        [self extendTop];
        [self extendBottom];
        
    } else {
        [NSException raise:@"Bad" format:@"Invalid listStartLocation %d", _startLocation];
    }
    
    [_emptyView removeAndClean];
    _hasContent = YES;
    for (FunListViewStickyGroup* stickyGroup in _stickyGroups) {
        [stickyGroup onInitialContentRendered];
    }
}

///////////////////////////////////////////
// Extend list up/down & as view scrolls //
///////////////////////////////////////////

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat contentOffset = [self _orientedContentOffset];
    if (contentOffset > _previousContentOffset) {
        // scrolled down
        [self extendBottom];
        for (FunListViewStickyGroup* stickyGroup in _stickyGroups) {
            [stickyGroup onContentMoved:ListViewDirectionUp];
        }
        
    } else if (contentOffset < _previousContentOffset) {
        // scrolled up
        [self extendTop];
        for (FunListViewStickyGroup* stickyGroup in _stickyGroups) {
            [stickyGroup onContentMoved:ListViewDirectionDown];
        }
        
    } else {
        // no change (contentOffsetY == _previousContentOffsetY)
        return;
    }
    
    CGFloat offsetChange = [self _orientedContentOffset] - _previousContentOffset;
    _previousContentOffset = [self _orientedContentOffset];
    if ([_delegate respondsToSelector:@selector(listDidScroll:)]) {
        [_delegate listDidScroll:offsetChange];
    }
}

- (void)extendBottom {
    CGFloat targetEdge = [self _orientedContentOffset] + (_orientation == Vertical ? _scrollView.height : _scrollView.width);
    while (_bottomEdge < targetEdge) {
        BOOL didAddView = [self _listAddNextViewDown];
        if (!didAddView) {
            [self _onDidReachTheVeryBottom];
            break;
        }
    }
    [self _cleanupTop];
}

- (void)extendTop {
    CGFloat targetEdge = [self _orientedContentOffset];
    while (_topEdge > targetEdge) {
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
    BOOL hasView = [_delegate hasViewForIndex:index];
    ListContentView* bottomView = [self _bottomView];

    if (!hasView) {
        // There are no more items to display at the bottom.
        // Last thing: add a group view at the bottom.
        if (bottomView.isGroupView) {
            return NO; // All done!
            
        } else {
            [self _addGroupFootViewForIndex:_bottomItemIndex withGroupId:_bottomGroupId atLocation:ListViewLocationBottom];
            return YES;
        }
    }
    
    // Check if the new item falls outside of the group of the current bottom-most item.
    ListGroupId groupId = [self _groupIdForIndex:index];
    if (![groupId isEqual:_bottomGroupId]) {
        // This item is the first of a new group.
        // First time around, add a foot view for the current bottom group
        // Second time around, add a head view for the next bottom group
        // After these two have happened, the actual item view is added (see below)
        
        if (bottomView.isItemView) {
            [self _addGroupFootViewForIndex:_bottomItemIndex withGroupId:_bottomGroupId atLocation:ListViewLocationBottom];
            return YES;
            
        } else if (!_hasContent || bottomView.isGroupFoot) {
            [self _addGroupHeadViewForIndex:index withGroupId:groupId atLocation:ListViewLocationBottom];
            return YES;
            
        } else if (bottomView.isGroupHead) {
            [NSException raise:@"Error" format:@"If `bottomView.isGroupHead`, then the next groupId should equal bottomGroupId"];
        } else {
            [NSException raise:@"Error" format:@"bottomView should always be an item, foot or head view."];
        }
    }
    
    ListContentView* view = [self _getViewForIndex:index location:ListViewLocationBottom];
    [self _addContentView:view at:ListViewLocationBottom];
    _bottomItemIndex = index;
    return YES;
}

- (BOOL)_listAddNextViewUp {
    ListContentView* topView = [self _topView];
    if (_topListViewIndex == 0) {
        // There are no more items to display at the top.
        // Last thing: add a group head view at the top.
        if (topView.isGroupHead) {
            if (!_endViewTop) {
                return NO; // all done
            } else if (_endViewTop.superview) {
                return NO; // all done
            } else {
                [self _addView:_endViewTop at:ListViewLocationTop];
                return YES;
            }
            
        } else {
            [self _addGroupHeadViewForIndex:_topListViewIndex withGroupId:_topGroupId atLocation:ListViewLocationTop];
            return YES;
        }
    }
    
    ListViewIndex index = _topListViewIndex - 1;
    if (![_delegate hasViewForIndex:index]) {
        [NSException raise:@"Error" format:@"hasViewForIndex returned NO for index %ld", index];
    }
    
    ListGroupId groupId = [self _groupIdForIndex:index];
    if (![groupId isEqual:_topGroupId]) {
        // This item is the first of a new group. In order, add:
        // 1) A head view for the current top group
        // 2) A foot view for the next top group
        // 3) The item view
        
        if (topView.isItemView) {
            [self _addGroupHeadViewForIndex:_topListViewIndex withGroupId:_topGroupId atLocation:ListViewLocationTop];
            return YES;
            
        } else if (topView.isGroupHead) {
            [self _addGroupFootViewForIndex:index withGroupId:groupId atLocation:ListViewLocationTop];
            return YES;
            
        } else if (topView.isGroupFoot) {
            [NSException raise:@"Error" format:@"If `topView.isGroupFoot`, then the previous groupId should equal _topGroupId"];
        } else {
            [NSException raise:@"Error" format:@"topView should always be an item, foot or head view."];
        }
    }
    
    ListContentView* view = [self _getViewForIndex:index location:ListViewLocationTop];
    if (!view) {
        [NSException raise:@"Error" format:@"Got nil view for list index %ld", index];
    }
    [self _addContentView:view at:ListViewLocationTop];
    _topListViewIndex = index;
    return YES;
}

- (void) _cleanupTop {
    // Clean up views at the top that are now out of sight
    CGFloat targetEdge = [self _orientedContentOffset];
    ListContentView* view;
    while ((view = [self _topView]) && (_orientation == Vertical ? view.y2 : view.x2) < targetEdge) {
        [view removeAndClean];
        _topEdge += (_orientation == Vertical ? view.height : view.width);
        if (view.isItemView) {
            if ([_delegate respondsToSelector:@selector(listViewWasRemoved:location:index:)]) {
                [_delegate listViewWasRemoved:view location:ListViewLocationTop index:_topListViewIndex];
            }
            _topListViewIndex += 1;
        } else if (view.isGroupFoot) {
            [self _setTopGroupId:[self _groupIdForIndex:_topListViewIndex] index:_topListViewIndex];
        }
    }
}

- (void) _cleanupBottom {
    // Clean up views at the bottom that are now out of sight
    CGFloat targetEdge = [self _orientedContentOffset] + [self _orientedSize];
    ListContentView* view;
    while ((view = [self _bottomView]) && (_orientation == Vertical ? view.y : view.x) > targetEdge) {
        [view removeAndClean];
        _bottomEdge -= [self _orientedSizeOfView:view];
        if (view.isItemView) {
            if ([_delegate respondsToSelector:@selector(listViewWasRemoved:location:index:)]) {
                [_delegate listViewWasRemoved:view location:ListViewLocationBottom index:_bottomItemIndex];
            }
            _bottomItemIndex -= 1;
        } else if (view.isGroupHead) {
            [self _setBottomGroupId:[self _groupIdForIndex:_bottomItemIndex] index:_bottomItemIndex];
        }
    }
}

//////////////////////////////////
// Item & Group Head/Foot Views //
//////////////////////////////////
- (ListContentView*)_getViewForIndex:(ListViewIndex)index location:(ListViewLocation)location {
    CGRect frame = CGRectMake(0, 0, 0, 0);
    if (_orientation == Vertical) {
        frame.size.width = self.width;
    } else {
        frame.size.height = self.height;
    }

    UIView* content = [[UIView alloc] initWithFrame:[self _frameForItemView]];
    ListContentView* contentView = [ListContentView withFrame:frame index:index content:content];
    [_delegate listPopulateView:content forIndex:index location:location];
    
    if (_orientation == Vertical) {
        contentView.height = (content.height + _itemMargins.top + _itemMargins.bottom);
    } else {
        contentView.width += (content.width + _itemMargins.left + _itemMargins.right);
    }
    return contentView;
}

- (CGRect)_frameForItemView {
    if (_orientation == Vertical) {
        CGFloat left = _itemMargins.left + _groupMargins.left;
        CGFloat right = _itemMargins.right + _groupMargins.right;
        CGFloat width = self.width - (left + right);
        return CGRectMake(left, _itemMargins.top, width, 0);
    } else {
        CGFloat top = _itemMargins.top + _groupMargins.top;
        CGFloat bottom = _itemMargins.bottom + _groupMargins.bottom;
        CGFloat height = self.height - (top + bottom);
        return  CGRectMake(_itemMargins.left, top, 0, height);
    }
}

- (CGRect)_frameForGroupHead {
    if (_orientation == Vertical) {
        CGFloat width = self.width - (_groupMargins.left + _groupMargins.right);
        return CGRectMake(0, _groupMargins.top, width, 0);
    } else {
        CGFloat height = self.height - (_groupMargins.top + _groupMargins.bottom);
        return CGRectMake(_groupMargins.left, 0, 0, height);
    }
}

- (CGRect)_frameForGroupFoot {
    if (_orientation == Vertical) {
        CGFloat width = self.width - (_groupMargins.left + _groupMargins.right);
        return CGRectMake(0, 0, width, 0);
    } else {
        CGFloat height = self.height - (_groupMargins.top + _groupMargins.bottom);
        return CGRectMake(0, 0, 0, height);
    }
}

- (void) _addGroupFootViewForIndex:(ListViewIndex)index withGroupId:(id)groupId atLocation:(ListViewLocation)location {
    UIView* view = [[UIView alloc] initWithFrame:[self _frameForGroupFoot]];
    if ([_delegate respondsToSelector:@selector(listPopulateView:forGroupFoot:withIndex:)]) {
        [_delegate listPopulateView:view forGroupFoot:groupId withIndex:index];
    }
    
    CGRect frame = view.bounds;
    if (_orientation == Vertical) {
        frame.size.height += _groupMargins.bottom;
    } else {
        frame.size.width += _groupMargins.right;
    }
    ListContentView* groupView = [ListContentView withFrame:frame footGroupId:groupId];
    [groupView addSubview:view];
    
    [self _addContentView:groupView at:location];
    if (location == ListViewLocationTop) {
        [self _setTopGroupId:groupId index:index];
    } else {
        [self _setBottomGroupId:groupId index:index];
    }
}

- (void) _addGroupHeadViewForIndex:(ListViewIndex)index withGroupId:(ListGroupId)groupId atLocation:(ListViewLocation)location {
    UIView* view = [[UIView alloc] initWithFrame:[self _frameForGroupHead]];
    if ([_delegate respondsToSelector:@selector(listPopulateView:forGroupHead:withIndex:)]) {
        [_delegate listPopulateView:view forGroupHead:groupId withIndex:index];
    }
    
    CGRect frame = view.bounds;
    if (_orientation == Vertical) {
        frame.size.height += _groupMargins.top;
    } else {
        frame.size.width += _groupMargins.left;
    }
    ListContentView* groupView = [ListContentView withFrame:frame headGroupId:groupId];
    [groupView addSubview:view];
    
    [self _addContentView:groupView at:location];
    if (location == ListViewLocationTop) {
        [self _setTopGroupId:groupId index:index];
    } else {
        [self _setBottomGroupId:groupId index:index];
    }
}

- (void)_addContentView:(ListContentView*)view at:(ListViewLocation)location {
    [self _addView:view at:location];
    for (FunListViewStickyGroup* stickyGroup in _stickyGroups) {
        [stickyGroup onDidAddView:view location:location];
    }
}

- (void)_addView:(ListContentView*)view at:(ListViewLocation)location {
    if (location == ListViewLocationTop) {
        if (_orientation == Vertical) {
            _topEdge -= view.height;
            view.y = _topEdge;
        } else {
            _topEdge -= view.width;
            view.x = _topEdge;
        }
        [_scrollView insertSubview:view atIndex:0];
    } else {
        if (_orientation == Vertical) {
            view.y = _bottomEdge;
            _bottomEdge += view.height;
        } else {
            view.x = _bottomEdge;
            _bottomEdge += view.width;
        }
        [_scrollView addSubview:view];
    }
}

////////////////
// Misc stuff //
////////////////

- (ListGroupId)_groupIdForIndex:(ListViewIndex)index {
    if ([_delegate respondsToSelector:@selector(listGroupIdForIndex:)]) {
        return [_delegate listGroupIdForIndex:index];
    } else {
        return @1;
    }
}

- (void)_setTopGroupId:(ListGroupId)topGroupId index:(ListViewIndex)index {
    ListGroupId previousTopGroupId = _topGroupId;
    _topGroupId = topGroupId;
    if ([_delegate respondsToSelector:@selector(listTopGroupDidChangeTo:withIndex:from:)]) {
        [_delegate listTopGroupDidChangeTo:topGroupId withIndex:index from:previousTopGroupId];
    }
}

- (void)_setBottomGroupId:(ListGroupId)bottomGroupId index:(ListViewIndex)index {
    ListGroupId previousBottomGroupId = _bottomGroupId;
    _bottomGroupId = bottomGroupId;
    if ([_delegate respondsToSelector:@selector(listBottomGroupDidChangeTo:withIndex:from:)]) {
        [_delegate listBottomGroupDidChangeTo:bottomGroupId withIndex:index from:previousBottomGroupId];
    }
}

- (void)_onDidReachTheVeryBottom {
    _hasReachedTheVeryBottom = YES;
    if (_orientation == Vertical) {
        _scrollView.contentSize = CGSizeMake(_scrollView.width, [self _bottomView].y2);
    } else {
        _scrollView.contentSize = CGSizeMake([self _bottomView].x2, _scrollView.height);
    }
}

- (void)_onDidReachTheVeryTop {
    _hasReachedTheVeryTop = YES;
    CGFloat change = (_orientation == Vertical ? [self _topView].y : [self _topView].x);
    if (change == 0) { return; }
    [self _fixTopEdgeByAdding:-change];
}

- (void)_fixTopEdgeByAdding:(CGFloat)change {
    _topEdge += change;
    _bottomEdge += change;
    _previousContentOffset += change;
    [self _withoutScrollEvents:^{
        [self _addOrientedContentOffset:change animated:NO];
        [self _addOrientedContentSize:change];
        CGFloat dx = (_orientation == Vertical ? 0 : change);
        CGFloat dy = (_orientation == Vertical ? change : 0);
        for (UIView* subView in self._views) {
            [subView moveByX:dx y:dy];
        }
    }];
    for (FunListViewStickyGroup* stickyGroup in _stickyGroups) {
        [stickyGroup onListViewChangeInHeight:change];
    }
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
    if (_scrollViewPurgedCount < 2) {
        for (UIView* view in _scrollView.subviews) {
            if (![view isKindOfClass:[ListContentView class]]) {
                [view removeAndClean];
                _scrollViewPurgedCount += 1;
            }
        }
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

- (BOOL)isAtBottom {
    return _scrollView.contentOffset.y >= _scrollView.contentSize.height - _scrollView.height;
}

@end

//////////////
// Stickies //
//////////////

@interface ListStickyView : UIView
@property CGFloat naturalOffset;
@property ListStickyView* viewAbove;
@property ListStickyView* viewBelow;
@end
@implementation ListStickyView
@end

@implementation FunListViewStickyGroup {
    ListStickyView* _topmost;
    ListStickyView* _current;
    ListStickyView* _bottommost;
    NSMutableArray*  _stickiesAddedForView;
    UIView* _stickiesContainerNonInteractive;
    CGFloat _y1;
    CGFloat _y2;
    CGFloat _height;
    CGFloat _viewOffset;
    FunListView* __weak _listView;
}

- (id)initWithListView:(FunListView *)listView point:(CGFloat)y height:(CGFloat)height viewOffset:(CGFloat)viewOffset {
    _listView = listView;
    _y1 = y;
    _y2 = y + height;
    _height = height;
    _viewOffset = viewOffset;
    _stickiesAddedForView = [NSMutableArray array];
    _stickiesContainerNonInteractive = [UIView.appendTo(_listView) render];
    return self;
}

- (UIView *)newView {
    CGFloat left = _listView.groupMargins.left + _listView.itemMargins.left;
    CGFloat right = _listView.groupMargins.right + _listView.itemMargins.right;
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(left, 0, _listView.width - left - right, 0)];
    [_stickiesAddedForView addObject:view];
    return view;
}

- (void)onDidAddView:(ListContentView*)view location:(ListViewLocation)location {
    if (!view.isItemView) { return; } // TODO Handle stickies for group views
    if (!_stickiesAddedForView.count) { return; }
    ListStickyView* stickyView = [ListStickyView.appendTo(_stickiesContainerNonInteractive).h(_height) render];
    for (UIView* view in _stickiesAddedForView) {
        [stickyView addSubview:view];
    }
    stickyView.naturalOffset = view.y + _viewOffset;
    stickyView.y = stickyView.naturalOffset - _listView.scrollView.contentOffset.y;
    [_stickiesAddedForView removeAllObjects];
    
    if (!_hasContent) {
        // First sticky
        [self _stickyMakeTopmost:stickyView];
        [self _stickyMakeBottommost:stickyView];
        _hasContent = YES;
    } else if (location == ListViewLocationTop) {
        [self _stickyMakeTopmost:stickyView];
    } else if (location == ListViewLocationBottom) {
        [self _stickyMakeBottommost:stickyView];
    }
}

- (void)onInitialContentRendered {
    if (!_hasContent) {
        if (_y1 || _y2) {
            [NSException raise:@"Error" format:@"Expected at least one sticky to be rendered in list view"];
        }
        return;
    }
    // Elect a first sticky
    ListStickyView* closest = _topmost;
    CGFloat distance = 999999;
    CGFloat point = _y1 + (_y2 - _y1)/2;
    ListStickyView* view = closest;
    while ((view = view.viewBelow)) {
        if (abs(view.center.y - point) < distance) {
            distance = abs(view.center.y - point);
            closest = view;
        }
    }
    _current = closest;
    _current.y = _y1;
}

- (void)onContentMoved:(ListViewDirection)contentMoved {
    CGFloat offset = _listView.scrollView.contentOffset.y;
    
    ListStickyView* stickyView = _topmost;
    while (stickyView) {
        if (stickyView != _current) {
            stickyView.y = stickyView.naturalOffset - offset;
        }
        stickyView = stickyView.viewBelow;
    }
    
    ListStickyView* enroaching;
    
    // From below
    enroaching = _current.viewBelow;
    while (enroaching && enroaching.y < _y2) {
        // a view from below is overlapping with the current
        if (enroaching.y > _y1) {
            // the enroaching view is partially overlapping the current
            _current.y2 = enroaching.y;
        } else {
            // the enroaching view is completely pushing out the current
            _current.naturalOffset = offset + _y1 - _height;
            _current.y = _current.naturalOffset - offset;
            _current = enroaching;
            _current.y = _y1;
        }
        enroaching = enroaching.viewBelow;
    }
    // From above
    enroaching = _current.viewAbove;
    while (enroaching && enroaching.y2 > _y1) {
        // a view from above is overlapping with the current
        if (enroaching.y2 < _y2) {
            // the enroaching view is partially overlapping the current
            _current.y = enroaching.y2;
        } else {
            // the enroaching view is completely pushing out the current
            _current.naturalOffset = offset + _y2;
            _current.y = _current.naturalOffset - offset;
            _current = enroaching;
            _current.y = _y1;
        }
        enroaching = enroaching.viewAbove;
    }
    
    if (contentMoved == ListViewDirectionUp) {
        [self _stickiesCleanupTop];
        
    } else if (contentMoved == ListViewDirectionDown) {
        [self _stickiesCleanupBottom];
    }
}

- (void)onListViewChangeInHeight:(CGFloat)changeInHeight {
    ListStickyView* stickyView = _topmost;
    while (stickyView) {
        stickyView.naturalOffset += changeInHeight;
        stickyView = stickyView.viewBelow;
    }
}

// Stickies linked list
///////////////////////
- (void)_stickyMakeBottommost:(ListStickyView*)stickyView {
    _bottommost.viewBelow = stickyView;
    stickyView.viewAbove = _bottommost;
    _bottommost = stickyView;
}
- (void)_stickyMakeTopmost:(ListStickyView*)stickyView {
    stickyView.viewBelow = _topmost;
    _topmost.viewAbove = stickyView;
    _topmost = stickyView;
}
- (void)_stickiesCleanupTop {
    CGFloat targetY = 0;
    while (_topmost != _current && _topmost.y2 < targetY) {
        [_topmost removeAndClean];
        _topmost = _topmost.viewBelow;
        _topmost.viewAbove = nil;
        if (!_topmost) {
            [NSException raise:@"Error" format:@"Should always have a _topmost"];
        }
    }
}
- (void)_stickiesCleanupBottom {
    CGFloat targetY = _listView.y2;
    while (_bottommost != _current && _bottommost.y > targetY) {
        [_bottommost removeAndClean];
        _bottommost = _bottommost.viewAbove;
        _bottommost.viewBelow = nil;
        if (!_bottommost) {
            [NSException raise:@"Error" format:@"Should always have a _bottommost"];
        }
    }
}

@end
