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

static inline void PixelSwap(uint8_t px[4]){
	uint8_t tmp[4] = { px[3],px[2],px[1],px[0] };
	px[0] = tmp[0];
	px[1] = tmp[1];
	px[2] = tmp[2];
	px[3] = tmp[3];
}
static inline void PixelRotL(uint8_t px[4]){
	uint8_t tmp[4] = { px[1],px[2],px[3],px[0] };
	px[0] = tmp[0];
	px[1] = tmp[1];
	px[2] = tmp[2];
	px[3] = tmp[3];
}

static inline BOOL AlphaInfoIsFirst(CGImageAlphaInfo alphaInfo){
	return alphaInfo == kCGImageAlphaFirst ||
	alphaInfo == kCGImageAlphaPremultipliedFirst ||
	alphaInfo == kCGImageAlphaNoneSkipFirst;
}
static inline BOOL AlphaInfoIsPremultiplied(CGImageAlphaInfo alphaInfo){
	return alphaInfo == kCGImageAlphaPremultipliedFirst ||
	alphaInfo == kCGImageAlphaPremultipliedLast;
}
static inline BOOL AlphaInfoIsNone(CGImageAlphaInfo alphaInfo){
	return alphaInfo == kCGImageAlphaNoneSkipFirst ||
	alphaInfo == kCGImageAlphaNoneSkipLast ||
	alphaInfo == kCGImageAlphaNone;
}

@implementation OGMGLImage

-(id)initWithWidth:(uint32_t)width height:(uint32_t)height format:(GLenum)format data:(NSData *)data{
	self = [super init];
	if(self){
		_width = width;
		_height = height;
		_format = format;
		_data = data;
	}
	return self;
}

-(id)initWithUIImage:(UIImage *)image{
	self = [self initWithCGImage:image.CGImage];
	if(self){
	}
	return self;
}
-(id)initWithCGImage:(CGImageRef)image{
	self = [super init];
	if(self){
		uint32_t width = CGImageGetWidth(image);
		uint32_t height = CGImageGetHeight(image);
		GLenum format = 0;
		NSData *data = nil;
		
		
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
			BOOL alphaPremultiplied = AlphaInfoIsPremultiplied(alphaInfo);
			BOOL alphaFirst = AlphaInfoIsFirst(alphaInfo);
			BOOL alphaNone = AlphaInfoIsNone(alphaInfo);
			
			BOOL swapByteOrder = NO;
			
			if(byteOrder == kCGBitmapByteOrderDefault)byteOrder = kCGBitmapByteOrder32Big;//あってるん？
			if(byteOrder == kCGBitmapByteOrder16Big ||
			   byteOrder == kCGBitmapByteOrder16Little){
				@throw OGMExceptionMake(NSGenericException,@"unsupported");
			}
			if(byteOrder == kCGBitmapByteOrder32Little){
				swapByteOrder = YES;
			}
			
			OGMLog(@"bpp=%d,byteOrder=%x,alphaFirst=%d,alphaPremultiplied=%d,alphaNone=%d\n",
				   bpp,byteOrder,alphaFirst,alphaPremultiplied,alphaNone);
			
			NSData *imageData = CFBridgingRelease(CGDataProviderCopyData(CGImageGetDataProvider(image)));
			
			if(alphaNone){
				format = GL_RGB;
				data = [NSMutableData dataWithLength:width*height*3];
			}else{
				format = GL_RGBA;
				data = [NSMutableData dataWithLength:width*height*4];
			}
			
			uint8_t *s = (uint8_t *)imageData.bytes;
			uint8_t *d = (uint8_t *)data.bytes;
			
			for(int y=0;y<height;y++){
				uint8_t * row = s;
				for(int x=0;x<width;x++){
					uint8_t pixel[4] = { s[0],s[1],s[2],s[3] };
					if(swapByteOrder)PixelSwap(pixel);
					if(alphaFirst)PixelRotL(pixel);
					
					if(alphaNone){
						d[0] = pixel[0];
						d[1] = pixel[1];
						d[2] = pixel[2];
						d+=3;
					}else{
						if(alphaPremultiplied){
							d[0] = MIN((int)pixel[0] * 255 / pixel[3],0xFF);
							d[1] = MIN((int)pixel[1] * 255 / pixel[3],0xFF);
							d[2] = MIN((int)pixel[2] * 255 / pixel[3],0xFF);
						}else{
							d[0] = pixel[0];
							d[1] = pixel[1];
							d[2] = pixel[2];
						}
						d[3] = pixel[3];
						d+=4;
					}
					s += 4;
				}
				s = row + bytesPerRow;
			}
			
			self = [self initWithWidth:width height:height format:format data:data];
			
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
			
			format = GL_RGB;
			data = [NSMutableData dataWithLength:width*height*3];
			
			uint8_t *s = (uint8_t *)imageData.bytes;
			uint8_t *d = (uint8_t *)data.bytes;
	
			for(int y=0;y<height;y++){
				uint8_t * row = s;
				for(int x=0;x<width;x++){
					d[0] = s[0];
					d[1] = s[1];
					d[2] = s[2];
					
					d+=3;
					s+=3;
				}
				s = row + bytesPerRow;
			}
			
			self = [self initWithWidth:width height:height format:format data:data];
		}else{
			@throw OGMExceptionMake(NSGenericException,@"unsupported bpp: %d",bpp);
		}
	}
	return self;
}

-(id)initWithWidth:(uint32_t)width height:(uint32_t)height color:(glm::vec4)color{
	NSMutableData * data = [NSMutableData dataWithLength:width*height*4];
	uint8_t * d = (uint8_t *)data.bytes;
	uint32_t area = width*height;
	for(int i=0;i<area;i++){
		d[0] = 255 * color.r;
		d[1] = 255 * color.g;
		d[2] = 255 * color.b;
		d[3] = 255 * color.a;
		d+=4;
	}
	self = [self initWithWidth:width height:height format:GL_RGBA data:data];
	return self;
}

@end
