#define MODE_DEV 1
#define MODE_TESTFLIGHT 2
#define MODE_DISTRIBUTION 3
#if defined TESTFLIGHT
    #define MODE MODE_TESTFLIGHT
#elif defined DEBUG
    #define MODE MODE_DEV
#else
    #define MODE MODE_DISTRIBUTION
#endif
#define IS_DISTRIBUTION (MODE == MODE_DISTRIBUTION)


#ifdef MODE_DEV
    NSMutableSet* __AUTOs;
    #define ENABLE_AUTO(AUTO_NAME)\
        DLog(@"Activate AUTO: %@", AUTO_NAME);\
        if (!__AUTOs) { __AUTOs=[NSMutableSet set]; }\
        [__AUTOs addObject:AUTO_NAME.lowercaseString];
    #define AUTO(AUTO_NAME, AUTO_CODE)\
        if ([__AUTOs containsObject:AUTO_NAME.lowercaseString]) {\
            [__AUTOs removeObject:AUTO_NAME.lowercaseString];\
            DLog(@"Run AUTO: %@", AUTO_NAME);\
            after(0.6, ^{ AUTO_CODE ; });\
        }
#else
#define ENABLE_AUTO(AUTO_NAME) // NOOP
#define AUTO(AUTO_NAME, AUTO_CODE) // NOOP
#endif


#define CLIP(X,min,max) MIN(MAX(X, min), max)

#if defined __MAC_OS_X_VERSION_MAX_ALLOWED
#define PLATFORM_OSX
#define UIApplicationDelegate NSApplicationDelegate
#define UIView NSView
#define UIApplication NSApplication

#elif defined __IPHONE_OS_VERSION_MAX_ALLOWED
#define PLATFORM_IOS
#endif

#include "TargetConditionals.h"

#if TARGET_IPHONE_SIMULATOR
static const BOOL isSimulator = YES;
#else
static const BOOL isSimulator = NO;
#endif

typedef void (^Block)();
typedef void (^StopBlock)(BOOL* stop);
typedef void (^Callback)(NSError* err, NSDictionary* res);
typedef void (^StringErrorCallback)(NSError* err, NSString* res);
typedef void (^StringCallback)(NSString* res);
typedef void (^ArrayErrorCallback)(NSError* err, NSArray* res);
typedef void (^ArrayCallback)(NSArray* array);
typedef void (^DataCallback)(NSError* err, NSData* data);
typedef void (^ImageCallback)(NSError* err, UIImage* image);
typedef void (^ViewCallback)(NSError* err, UIView* view);
typedef void (^CGPointBlock)(CGPoint point);
typedef void (^CGPointVectorBlock)(CGPoint point, CGPoint vector);
typedef void (^NSUIntegerBlock)(NSUInteger i);
typedef void (^ErrorCallback)(NSError* err);
typedef void (^AuthorizeCallback)(NSError* err, BOOL authorized);

void error(NSError* err);
void fatal(NSError* err);
NSError* makeError(NSString* localMessage);
void after(NSTimeInterval delayInSeconds, Block block);
void every(NSTimeInterval delayInSeconds, StopBlock block);
void async(Block block);
void asyncDefault(Block block);
void asyncHigh(Block block);
void asyncLow(Block block);
void asyncMain(Block block);
void asyncBackground(Block block);
void vibrateDevice();
NSString* concat(id arg1, ...);
void repeat(NSUInteger times, NSUIntegerBlock block);

NSRange NSRangeMake(NSUInteger location, NSUInteger length);
NSString* NSStringFromRange(NSRange range);

#define num(i) [NSNumber numberWithLongLong:i]
#define numf(f) [NSNumber numberWithDouble:f]
