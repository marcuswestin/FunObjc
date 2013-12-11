//
//  FunBase.h
//  Dogo-iOS
//
//  Created by Marcus Westin on 6/25/13.
//  Copyright (c) 2013 Flutterby Labs Inc. All rights reserved.
//


id GetProperty(id obj, NSString* key);
void SetProperty(id obj, NSString* key, id val);
void SetPropertyCopy(id obj, NSString* key, id val);
void SetPropertyAssign(id obj, NSString* key, id val);
void RemoveRuntimeProperties(id obj);
NSArray* GetPropertyNames(Class cls);
NSDictionary* GetClassProperties(Class cls);