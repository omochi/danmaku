//
//  OGMTypeBuffer.h
//  Danmaku
//
//  Created by おもちメタル on 13/06/06.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//
#pragma once

#import "OGMCommon.h"
#import "OGMPPMacro.h"

#ifdef __cplusplus
extern "C" {
#endif

#define _NS(name) OGM##name
	
#define OGM_TYPEBUFFER_PTR(type,tb) (type *)([(tb) ptrWithTypeAssert:@encode(type)])
	
#define OGM_TYPEBUFFER_MAKE(T,...) (^OGMTypeBuffer *(){\
	T p[] = { __VA_ARGS__ };\
	return [[OGMTypeBuffer alloc]initWithObjCType:@encode(T) \
		ptr:p size:OGM_ARRAY_SIZE(p)];\
}() )
	
//
//	

@interface _NS(TypeBuffer) : NSObject

-(id)initWithObjCType:(const char *)type;
-(id)initWithObjCType:(const char *)type size:(uint32_t)size;
-(id)initWithObjCType:(const char *)type ptr:(const void *)ptr size:(uint32_t)size;

//要素型について
-(const char *)objCType;
-(size_t)typeSize;
-(void)assertType:(const char *)objCType;

//要素数
@property(nonatomic,assign)uint32_t size;
//内部確保要素数
-(uint32_t)allocSize;
//typeSize x size
-(uint32_t)byteSize;


-(void *)ptr;
-(void *)ptrAt:(uint32_t)index;

-(void *)ptrWithTypeAssert:(const char *)objCType;

-(void)reserve:(uint32_t)size;

-(void)spliceAt:(uint32_t)index len:(uint32_t)len items:(void *)items itemsNum:(uint32_t)itemsNum;
-(void)removeAt:(uint32_t)index len:(uint32_t)len;
-(void)removeAt:(uint32_t)index;
-(void)insertAt:(uint32_t)index items:(void *)items itemsNum:(uint32_t)itemsNum;
-(void)insertAt:(uint32_t)index item:(void *)item;
-(void)add:(void *)item;

@end

#undef _NS
	
#ifdef __cplusplus
}
#endif