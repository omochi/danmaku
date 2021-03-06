//
//  OGMLog.h
//  Danmaku
//
//  Created by おもちメタル on 13/06/05.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//
#pragma once

#import "OGMPPMacro.h"

OGM_EXTERN_C_BEGIN

void _OGMLog(NSString *format,...) NS_FORMAT_FUNCTION(1, 2);
void _OGMLogv(NSString *format,va_list args) NS_FORMAT_FUNCTION(1, 0);

#if OGM_LOG_ENABLE
#	define OGMLog(format,...) _OGMLog(format,##__VA_ARGS__)
#else
#	define OGMLog(format,...)
#endif

OGM_EXTERN_C_END