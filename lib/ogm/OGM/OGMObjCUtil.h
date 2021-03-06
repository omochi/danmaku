//
//  OGMObjCUtil.h
//  Danmaku
//
//  Created by おもちメタル on 13/06/12.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import "OGMPPMacro.h"

OGM_EXTERN_C_BEGIN
void OGMAbstractClassNotAllocCheck(id self,Class aClass);
uint32_t OGMObjCTypeSize(const char * type);
void OGMClassAssert(id obj,Class aClass);

NSString * OGMNSStringFromPath(NSString * path);

OGM_EXTERN_C_END

