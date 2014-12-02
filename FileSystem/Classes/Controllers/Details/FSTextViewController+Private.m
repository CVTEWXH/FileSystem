/*******************************************************************************
 * Copyright (c) 2013, Jean-David Gadina - www.xs-labs.com
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *  -   Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 *  -   Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 *  -   Neither the name of 'Jean-David Gadina' nor the names of its
 *      contributors may be used to endorse or promote products derived from
 *      this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 ******************************************************************************/
 
/* $Id$ */

/*!
 * @file        ...
 * @copyright   (c) 2013, Jean-David Gadina - www.xs-labs.com
 * @abstract    ...
 */

#import "FSTextViewController+Private.h"
#import "FSTextViewController+UIDocumentInteractionControllerDelegate.h"
#import "FSFile.h"
#import "FSHUDView.h"
#import "FSFileInfosViewController.h"

#define HEX_BUFFER_LENGTH 4096

@implementation FSTextViewController( Private )

- ( void )loadText: ( UISegmentedControl * )segment
{
    NSData   * data;
    NSString * text;
    
    @autoreleasepool
    {
        _hasText = NO;
        _hasHex  = NO;
        
        data = [ [ NSFileManager defaultManager ] contentsAtPath: _file.path ];
        text = [ [ NSString alloc ] initWithData: data encoding: NSASCIIStringEncoding ];
        
        [ _textView performSelectorOnMainThread: @selector( setText: ) withObject: text waitUntilDone: YES ];
        [ text release ];
        
        dispatch_async
        (
            dispatch_get_main_queue(),
            ^( void )
            {
                [ UIView animateWithDuration: 1
                         animations: ^( void )
                         {
                            _hud.alpha = ( CGFloat )0;
                         }
                         completion: ^( BOOL finished )
                         {
                            ( void )finished;
                            
                            [ _hud removeFromSuperview ];
                            [ segment setEnabled: YES ];
                            
                            _hasText = YES;
                         }
                ];
            }
        );
    }
}

- ( void )loadHex: ( UISegmentedControl * )segment
{
    size_t            length;
    unsigned int      i;
    unsigned int      j;
    unsigned int      fileSize;
    char              ascii;
    char              buffer[ HEX_BUFFER_LENGTH ];
    FILE            * f;
    NSMutableString * hex;
    NSUInteger        hexLineLength;
    
    @autoreleasepool
    {
        _hasText = NO;
        _hasHex  = NO;
        
        f = fopen( [ _file.path cStringUsingEncoding: NSASCIIStringEncoding ], "r" );
        
        if( f == NULL )
        {
            return;
        }
        
        if( [ [ UIDevice currentDevice ] userInterfaceIdiom ] == UIUserInterfaceIdiomPad )
        {
            hexLineLength = 25;
        }
        else if( [ [ [ UIDevice currentDevice ] systemVersion ] integerValue ] >= 5 )
        {
            hexLineLength = 10;
        }
        else
        {
            hexLineLength = 9;
        }
        
        fseek( f, 0, SEEK_END );
        
        fileSize = ( unsigned int )ftell( f );
        
        fseek( f, 0, SEEK_SET );
        
        hex = [ NSMutableString stringWithCapacity: ( fileSize * 5 ) ];
        
        while( ( length = fread( buffer, sizeof( char ), HEX_BUFFER_LENGTH, f ) ) )
        {
            for( i = 0; i < length; i += hexLineLength )
            {
                for( j = 0; j < hexLineLength; j++ )
                {
                    if( ( i + j ) < length )
                    {
                        [ hex appendFormat: @"%02x ", ( unsigned char )buffer[ i + j ] ];
                    }
                    else
                    {
                        [ hex appendString: @"   " ];
                    }
                }
                
                [ hex appendString: @": " ];
                
                for( j = 0; j < hexLineLength; j++ )
                {
                    ascii = ' ';
                    
                    if( ( i + j ) < length )
                    {
                        ascii = buffer[ i + j ];
                    }
                    
                    [ hex appendFormat: @"%c", ( ( ( ascii & 0x80 ) == 0 ) && isprint( ( int )ascii ) ) ? ascii : '.' ];
                }
                
                [ hex appendString: @"\n" ];
            }
        }
        
        fclose( f );
        
        [ _textView performSelectorOnMainThread: @selector( setText: ) withObject: hex waitUntilDone: YES ];
        
        dispatch_async
        (
            dispatch_get_main_queue(),
            ^( void )
            {
                [ UIView animateWithDuration: 1
                         animations: ^( void )
                         {
                            _hud.alpha = ( CGFloat )0;
                         }
                         completion: ^( BOOL finished )
                         {
                            ( void )finished;
                            
                            [ _hud removeFromSuperview ];
                            [ segment setEnabled: YES ];
                            
                            _hasHex = YES;
                         }
                ];
            }
        );
    }
}

- ( IBAction )openIn: ( id )sender
{
    UIAlertView                     * alert;
    UIDocumentInteractionController * controller;
    
    ( void )sender;
    
    controller          = [ UIDocumentInteractionController interactionControllerWithURL: [ NSURL fileURLWithPath: _file.path ] ];
    controller.delegate = self;
    
    [ controller retain ];
    
    if( [ controller presentOpenInMenuFromBarButtonItem: sender animated: YES ] == NO )
    {
        alert = [ [ UIAlertView alloc ] initWithTitle: NSLocalizedString( @"OpenInAlertTitle", @"OpenInAlertTitle" ) message: NSLocalizedString( @"OpenInAlertText", @"OpenInAlertText" ) delegate: nil cancelButtonTitle: NSLocalizedString( @"OK", @"OK" ) otherButtonTitles: nil ];
        
        [ alert show ];
        [ alert autorelease ];
    }
}

- ( IBAction )showInfos: ( id )sender
{
    UIViewController * controller;
    FSFile           * file;
    
    ( void )sender;
    
    file       = ( _file.targetFile == nil ) ? _file : _file.targetFile;
    controller = [ [ FSFileInfosViewController alloc ] initWithFile: file ];
    
    if( controller != nil )
    {
        [ self.navigationController pushViewController: controller animated: YES ];
    }
    
    [ controller release ];
}

- ( IBAction )toggleDisplay: ( id )sender
{
    UISegmentedControl * segment;
    
    if( [ sender isKindOfClass: [ UISegmentedControl class ] ] == NO )
    {
        return;
    }
    
    segment = ( UISegmentedControl * )sender;
    
    [ segment setEnabled: NO ];
    
    _hud.alpha = ( CGFloat )1;
    
    [ self.view addSubview: _hud ];
    
    if( segment.selectedSegmentIndex == 0 )
    {
        [ NSThread detachNewThreadSelector: @selector( loadText: ) toTarget: self withObject: segment ];
    }
    else if( segment.selectedSegmentIndex == 1 )
    {
        [ NSThread detachNewThreadSelector: @selector( loadHex: ) toTarget: self withObject: segment ];
    }
}

@end
