/*******************************************************************************
 * Copyright (c) 2012, Jean-David Gadina <macmade@eosgarden.com>
 * All rights reserved
 ******************************************************************************/
 
/* $Id$ */

/*!
 * @file        ...
 * @copyright   eosgarden 2012 - Jean-David Gadina <macmade@eosgarden.com>
 * @abstract    ...
 */

#import "UIImage+FS.h"
#import <ImageIO/ImageIO.h>

@implementation UIImage( FS )

+ ( UIImage * )thumbnailForImageAtPath: ( NSString * )path maxSize: ( NSUInteger )maxSize
{
    CGImageSourceRef source;
    CFDictionaryRef  options;
    CGImageRef       cgImage;
    UIImage        * image;

    source = CGImageSourceCreateWithURL( ( CFURLRef )[ NSURL fileURLWithPath: path ], NULL );
    
    if( source == NULL )
    {
        return nil;
    }
    
    options = ( CFDictionaryRef )[ NSDictionary dictionaryWithObjectsAndKeys:   ( id )kCFBooleanTrue,                           ( id )kCGImageSourceCreateThumbnailWithTransform,
                                                                                ( id )kCFBooleanTrue,                           ( id )kCGImageSourceCreateThumbnailFromImageIfAbsent,
                                                                                ( id )[ NSNumber numberWithFloat: maxSize ],    ( id )kCGImageSourceThumbnailMaxPixelSize,
                                                                                nil
              ];
    cgImage = CGImageSourceCreateThumbnailAtIndex( source, 0, options );
    image   = [ UIImage imageWithCGImage: cgImage ];

    CGImageRelease( cgImage );
    CFRelease( source );

    return image;
}

@end
