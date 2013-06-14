//
//  OGMGLImage.m
//  Danmaku
//
//  Created by おもちメタル on 13/06/14.
//  Copyright (c) 2013年 com.omochimetaru. All rights reserved.
//

#import "OGMGLImage.h"

#import "OGMErrorUtil.h"
#import "OGMLog.h"

static inline uint32_t U32Swap(uint32_t x){
	return (x << 24) | ((x & 0xFF00) << 8) | ((x >> 8) & 0xFF00) | (x >> 24);
};
static inline uint32_t U32RotLeft8(uint32_t x){
	return (x << 8) | (x >> 24);
};

@implementation OGMGLImage

-(id)initWithUIImage:(UIImage *)image{
	self = [self initWithCGImage:image.CGImage];
	if(self){
	}
	return self;
}
-(id)initWithCGImage:(CGImageRef)image{
	self = [super init];
	if(self){
		_width = CGImageGetWidth(image);
		_height = CGImageGetHeight(image);
		
		CGColorSpaceRef colorSpace = CGImageGetColorSpace(image);
		CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(colorSpace);
		if(colorSpaceModel != kCGColorSpaceModelRGB){
			@throw OGMExceptionMake(NSGenericException, @"unsupported color space model: %d",colorSpaceModel);
		}
		
		CGBitmapInfo info = CGImageGetBitmapInfo(image);
		uint32_t bpc = CGImageGetBitsPerComponent(image);
		uint32_t bpp = CGImageGetBitsPerPixel(image);
		uint32_t bytesPerRow = CGImageGetBytesPerRow(image);
		
		uint32_t byteOrder = info & kCGBitmapByteOrderMask;
		CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(image);
		
		if(bpc!=8){
			@throw OGMExceptionMake(NSGenericException, @"unsupported bpc: %d",bpc);
		}
		
		if(info & kCGBitmapFloatComponents){
			@throw OGMExceptionMake(NSGenericException,@"float components unsupported");
		}
		
		if(bpp == 32){
			BOOL alphaPremultiplied = NO;
			BOOL alphaFirst = NO;
			BOOL swapByteOrder = NO;
			BOOL alphaNone = NO;
			
			if(byteOrder == kCGBitmapByteOrderDefault)byteOrder = kCGBitmapByteOrder32Host;//あってるん？
			if(byteOrder == kCGBitmapByteOrder16Big ||
			   byteOrder == kCGBitmapByteOrder16Little){
				@throw OGMExceptionMake(NSGenericException,@"unsupported");
			}
			if(byteOrder == kCGBitmapByteOrder32Little){
				swapByteOrder = YES;
			}
			
			switch (alphaInfo) {
				case kCGImageAlphaPremultipliedFirst:
					alphaFirst = YES;
					alphaPremultiplied = YES;
					break;
				case kCGImageAlphaFirst:
					alphaFirst = YES;
					break;
				case kCGImageAlphaNoneSkipFirst:
					alphaFirst = YES;
					alphaNone = YES;
					break;
				case kCGImageAlphaPremultipliedLast:
					alphaPremultiplied = YES;
					break;
				case kCGImageAlphaLast:
					break;
				case kCGImageAlphaNoneSkipLast:
					alphaNone = YES;
					break;
				default:
					@throw OGMExceptionMake(NSGenericException,@"inconsistent alpha info for bpp32: %d",alphaInfo);
			}
			
			OGMLog(@"bpp=%d,byteOrder=%x,alphaFirst=%d,alphaPremultiplied=%d,alphaNone=%d\n",
				   bpp,byteOrder,alphaFirst,alphaPremultiplied,alphaNone);
			
			NSData *imageData = CFBridgingRelease(CGDataProviderCopyData(CGImageGetDataProvider(image)));
			
			if(alphaNone){
				_format = GL_RGB;
				_data = [NSData dataWithBytes:NULL length:_width*_height*3];
			}else{
				_format = GL_RGBA;
				_data = [NSData dataWithBytes:NULL length:_width*_height*4];
			}
			
			uint8_t *s = (uint8_t *)imageData.bytes;
			uint8_t *d = (uint8_t *)_data.bytes;
			
			//リトルエンディアンならキャスト時点でスワップするので
			long hostByteOrder = NSHostByteOrder();
			if(hostByteOrder == NS_UnknownByteOrder){
				@throw OGMExceptionMake(NSGenericException,@"unsupported host byte order");
			}
			if(hostByteOrder == NS_LittleEndian){
				swapByteOrder = !swapByteOrder;
			}
			
			for(int y=0;y<_height;y++){
				uint8_t * row = s;
				for(int x=0;x<_width;x++){
					uint32_t ss = *(uint32_t *)s;
					if(swapByteOrder)ss = U32Swap(ss);
					if(alphaFirst)ss = U32RotLeft8(ss);
					
					if(alphaNone){
						d[0] = (ss >> 24);
						d[1] = (ss >> 16) & 0xFF;
						d[2] = (ss >> 8) & 0xFF;
						d+=3;
					}else{
						d[0] = (ss >> 24);
						d[1] = (ss >> 16) & 0xFF;
						d[2] = (ss >> 8) & 0xFF;
						d[3] = ss & 0xFF;
						if(alphaPremultiplied){
							d[0] = ((int)d[0] * 255 / d[3]) & 0xFF;
							d[1] = ((int)d[1] * 255 / d[3]) & 0xFF;
							d[2] = ((int)d[2] * 255 / d[3]) & 0xFF;
						}
						d+=4;
					}
					s += 4;
				}
				s = row + bytesPerRow;
			}
		}else if(bpp == 24){
		
			uint32_t byteOrder = info & kCGBitmapByteOrderMask;
			if(byteOrder != kCGBitmapByteOrderDefault){
				@throw OGMExceptionMake(NSGenericException,@"unsupported byteorder: %x",byteOrder);
			}
			if(alphaInfo != kCGImageAlphaNone){
				@throw OGMExceptionMake(NSGenericException,@"inconsistent alpha info for bpp24: %d",alphaInfo);
			}
			
			NSData *imageData = CFBridgingRelease(CGDataProviderCopyData(CGImageGetDataProvider(image)));
			
			OGMLog(@"bpp=%d\n",bpp);
			
			_format = GL_RGB;
			_data = [NSData dataWithBytes:NULL length:_width*_height*3];
			
			uint8_t *s = (uint8_t *)imageData.bytes;
			uint8_t *d = (uint8_t *)_data.bytes;
	
			for(int y=0;y<_height;y++){
				uint8_t * row = s;
				for(int x=0;x<_width;x++){
					d[0] = s[0];
					d[1] = s[1];
					d[2] = s[2];
					
					d+=3;
					s+=3;
				}
				s = row + bytesPerRow;
			}
		}else{
			@throw OGMExceptionMake(NSGenericException,@"unsupported bpp: %d",bpp);
		}
	}
	return self;
}


@end
