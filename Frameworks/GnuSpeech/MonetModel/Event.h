//  This file is part of Gnuspeech, an extensible, text-to-speech package, based on real-time, articulatory, speech-synthesis-by-rules. 
//  Copyright 1991-2012 David R. Hill, Leonard Manzara, Craig Schock

#import <Foundation/Foundation.h>

#include <math.h>

// 2015-06-20: <http://www.gnu.org/software/libc/manual/html_node/Infinity-and-NaN.html> Indicates this would be +infinity, not NaN.
#define NaN (1.0/0.0)

@interface Event : NSObject

- (id)initWithTime:(NSUInteger)time;

@property (readonly) NSUInteger time;

// TODO: (2015-06-20) What is this flag used for?  Rename it.
@property (assign) BOOL flag;

- (double)getValueAtIndex:(NSUInteger)index;
- (void)setValue:(double)value atIndex:(NSUInteger)index;

@end
