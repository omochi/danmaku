//
//  OGMMacro.h
//  Danmaku
//
//  Created by おもちメタル on 13/06/11.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#pragma once

#import "OGMCommon.h"

#ifdef __cplusplus
#	define OGM_EXTERN_C_BEGIN extern "C" {
#	define OGM_EXTERN_C_END }
#else
#	define OGM_EXTERN_C_BEGIN
#	define OGM_EXTERN_C_END
#endif

#define OGM_PP_STR(x) #x
