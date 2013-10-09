//
//  State.h
//  ivyq
//
//  Created by Marcus Westin on 9/22/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface State : NSObject <NSCoding>
+ (instancetype) withDict:(NSDictionary*)dict;
+ (instancetype) fromDict:(NSDictionary*)dict;
- (BOOL)archiveToDocument:(NSString*)archiveDocName;
- (NSDictionary*)toDictionary;
+ (State*)fromArchiveDocument:(NSString*)archiveDocName;
- (instancetype) copyWithDictionary:(NSDictionary*)dict;
@end

