#import "IntonationView.h"

#import <AppKit/AppKit.h>
#import "NSBezierPath-Extensions.h"
#import "NSString-Extensions.h"

#import "Event.h"
#import "EventList.h"
#import "GSXMLFunctions.h"
#import "IntonationPoint.h"
#import "MonetList.h"
#import "MMPosture.h"

#define TOP_MARGIN 65
#define BOTTOM_MARGIN 5
#define LEFT_MARGIN 1

#define SECTION_COUNT 15

NSString *IntonationViewSelectionDidChangeNotification = @"IntonationViewSelectionDidChangeNotification";

@implementation IntonationView

- (id)initWithFrame:(NSRect)frameRect;
{
    if ([super initWithFrame:frameRect] == nil)
        return nil;

    postureTextFieldCell = [[NSTextFieldCell alloc] initTextCell:@""];
    timesFont = [[NSFont fontWithName:@"Times-Roman" size:12] retain];
    timesFontSmall = [[NSFont fontWithName:@"Times-Roman" size:10] retain];

    [postureTextFieldCell setFont:timesFont];

    timeScale = 2.0;
    mouseBeingDragged = 0;

    eventList = nil;

    selectedPoints = [[NSMutableArray alloc] init];

    [self setNeedsDisplay:YES];

    return self;
}

- (void)dealloc;
{
    [postureTextFieldCell release];
    [timesFont release];
    [timesFontSmall release];
    [eventList release];
    [selectedPoints release];

    [super dealloc];
}

- (BOOL)acceptsFirstResponder;
{
    return YES;
}

- (void)setEventList:(EventList *)newEventList;
{
    if (newEventList == eventList)
        return;

    [eventList release];
    eventList = [newEventList retain];

    [self setNeedsDisplay:YES];
}

- (BOOL)shouldDrawSmoothPoints;
{
    return shouldDrawSmoothPoints;
}

- (void)setShouldDrawSmoothPoints:(BOOL)newFlag;
{
    if (newFlag == shouldDrawSmoothPoints)
        return;

    shouldDrawSmoothPoints = newFlag;
    [self setNeedsDisplay:YES];
}

- (id)delegate;
{
    return nonretained_delegate;
}

- (void)setDelegate:(id)newDelegate;
{
    nonretained_delegate = newDelegate;
}

- (void)drawRect:(NSRect)rect;
{
    NSRect clipRect;
    Event *lastEvent;
    float timeValue;

    NSLog(@"%s", _cmd);
    // TODO (2004-03-15): Changing the view frame in drawRect: can cause problems.  Should do before drawRect:
    clipRect = [[self superview] frame];
    lastEvent = [[eventList events] lastObject];
    timeValue = [lastEvent time] / timeScale;
    if (clipRect.size.width < timeValue)
        clipRect.size.width = timeValue;
    [self setFrame:clipRect];

    [self drawBackground];
    [self drawGrid];
    [self drawPhoneLabels];
    [self drawRules];
    [self drawIntonationPoints];

    if (shouldDrawSmoothPoints == YES && mouseBeingDragged == NO)
        [self drawSmoothPoints];

    [[self enclosingScrollView] reflectScrolledClipView:(NSClipView *)[self superview]];
}

- (void)drawBackground;
{
    [[NSColor whiteColor] set];
    NSRectFill([self bounds]);
}

- (void)drawGrid;
{
    NSBezierPath *bezierPath;
    NSRect bounds;
    NSPoint graphOrigin;
    int sectionHeight;
    int index;

    bounds = NSIntegralRect([self bounds]);
    graphOrigin = [self graphOrigin];
    sectionHeight = [self sectionHeight];

    [[NSColor blackColor] set];

    bezierPath = [[NSBezierPath alloc] init];
    [bezierPath setLineWidth:2];
    [bezierPath appendBezierPathWithRect:NSMakeRect(graphOrigin.x, graphOrigin.y, bounds.size.width - 2, SECTION_COUNT * sectionHeight)];
    [bezierPath stroke];
    [bezierPath release];

    /* Draw in best fit grid markers */

    [[NSColor lightGrayColor] set];

    bezierPath = [[NSBezierPath alloc] init];
    [bezierPath setLineWidth:1];
    for (index = 0; index < SECTION_COUNT; index++) {
        NSPoint aPoint;

        aPoint.x = 2;
        aPoint.y = graphOrigin.y + 0.5 + index * sectionHeight;
        [bezierPath moveToPoint:aPoint];

        aPoint.x = bounds.size.width - 2;
        [bezierPath lineToPoint:aPoint];
    }
    [bezierPath stroke];
    [bezierPath release];
}

// Put phone label on the top
- (void)drawPhoneLabels;
{
    int count, index;
    MMPosture *currentPosture;
    NSRect bounds;
    float currentX;
    int phoneIndex = 0;
    NSArray *events;

    bounds = [self bounds];

    [[NSColor blackColor] set];
    [timesFont set];

    events = [eventList events];
    count = [events count];
    for (index = 0; index < count; index++) {
        currentX = ((float)[[events objectAtIndex:index] time] / timeScale);
        if (currentX > bounds.size.width - 20.0)
            break;
        if (currentX < 5.0)
            currentX = 5.0;

        if ([[events objectAtIndex:index] flag]) {
            currentPosture = [eventList getPhoneAtIndex:phoneIndex++];
            if (currentPosture != nil) {
                NSLog(@"[currentPosture symbol]: %@", [currentPosture symbol]);
#if 0
                [[NSColor blueColor] set];
                NSRectFill(NSMakeRect(currentX - 5.0, bounds.size.height - 62, 10, 20));
#endif
                [[NSColor blackColor] set];
                [[currentPosture symbol] drawAtPoint:NSMakePoint(currentX - 5.0, bounds.size.height - 62.0) withAttributes:nil];
                //[postureTextFieldCell setStringValue:[currentPosture symbol]];
            }
        }
    }
}

// Put Rules on top
- (void)drawRules;
{
    NSBezierPath *bezierPath;
    float currentX;
    int count, index;
    NSRect bounds;
    NSPoint graphOrigin;
    int sectionHeight;
    struct _rule *rule;

    bounds = [self bounds];
    graphOrigin = [self graphOrigin];
    sectionHeight = [self sectionHeight];

    [timesFontSmall set];

    bezierPath = [[NSBezierPath alloc] init];
    [bezierPath setLineWidth:1];
    currentX = 0;

    count = [eventList numberOfRules];
    for (index = 0; index < count; index++) {
        NSString *str;
        NSPoint aPoint;
        NSRect drawFrame;

        rule = [eventList getRuleAtIndex:index];
        drawFrame.origin.x = currentX;
        drawFrame.origin.y = bounds.size.height - 40.0;
        drawFrame.size.height = 30.0;
        drawFrame.size.width = (float)rule->duration / timeScale;
        NSDrawWhiteBezel(drawFrame, drawFrame);
        [[NSColor blackColor] set];

        str = [NSString stringWithFormat:@"%d", rule->number];
        [str drawAtPoint:NSMakePoint(currentX + (float)rule->duration / (3 * timeScale), bounds.size.height - 21.0) withAttributes:nil];

        str = [NSString stringWithFormat:@"%.2f", rule->duration];
        [str drawAtPoint:NSMakePoint(currentX + (float)rule->duration / (3 * timeScale), bounds.size.height - 35.0) withAttributes:nil];

        aPoint.x = floor((float)rule->beat / timeScale) + 0.5;
        aPoint.y = graphOrigin.y + SECTION_COUNT * sectionHeight;
        [bezierPath moveToPoint:aPoint];

        aPoint.y = graphOrigin.y;
        [bezierPath lineToPoint:aPoint];

        currentX += (float)rule->duration / timeScale;
    }

    [[NSColor darkGrayColor] set];
    [[NSColor blackColor] set];
    [[NSColor greenColor] set];
    [bezierPath stroke];
    [bezierPath release];
}

- (void)drawIntonationPoints;
{
    NSBezierPath *bezierPath;
    int count, index;
    NSPoint currentPoint;
    NSRect bounds;
    NSPoint graphOrigin;
    NSArray *intonationPoints = [eventList intonationPoints];

    bounds = [self bounds];
    graphOrigin = [self graphOrigin];

    [[NSColor blackColor] set];
    [[NSColor redColor] set];

    bezierPath = [[NSBezierPath alloc] init];
    [bezierPath setLineWidth:1];
    [bezierPath moveToPoint:graphOrigin];

    count = [intonationPoints count];
    for (index = 0; index < count; index++) {
        currentPoint.x = (float)[[intonationPoints objectAtIndex:index] absoluteTime] / timeScale;
        currentPoint.y = (float)(([[intonationPoints objectAtIndex:index] semitone] + 20.0) * (bounds.size.height - TOP_MARGIN - BOTTOM_MARGIN)) / 30.0 + 5.0;

        currentPoint.y = rint(currentPoint.y) + 0.5;
        [bezierPath lineToPoint:currentPoint];

        [NSBezierPath drawCircleMarkerAtPoint:currentPoint];
    }
    [bezierPath stroke];
    [bezierPath release];

    count = [selectedPoints count];
    for (index = 0; index < count; index++) {
        currentPoint.x = (float)[[selectedPoints objectAtIndex:index] absoluteTime] / timeScale;
        currentPoint.y = (float)(([[selectedPoints objectAtIndex:index] semitone] + 20.0) * (bounds.size.height - TOP_MARGIN - BOTTOM_MARGIN)) / 30.0 + 5.0;
        [NSBezierPath highlightMarkerAtPoint:currentPoint];
    }
}

// TODO (2004-03-15): See if we can just use the code from -applyIntonationSmooth instead.
- (void)drawSmoothPoints;
{
    double a, b, c, d;
    double x1, y1, m1, x12, x13;
    double x2, y2, m2, x22, x23;
    double denominator;
    double x, y, xx,yy;
    int i, j;
    id point1, point2;
    NSBezierPath *bezierPath;
    NSArray *intonationPoints = [eventList intonationPoints];

    if ([intonationPoints count] < 2)
        return;

    for (j = 0; j < [intonationPoints count] - 1; j++) {
        point1 = [intonationPoints objectAtIndex:j];
        point2 = [intonationPoints objectAtIndex:j + 1];

        x1 = [point1 absoluteTime];
        y1 = [point1 semitone] + 20.0;
        m1 = [point1 slope];

        x2 = [point2 absoluteTime];
        y2 = [point2 semitone] + 20.0;
        m2 = [point2 slope];

        x12 = x1*x1;
        x13 = x12*x1;

        x22 = x2*x2;
        x23 = x22*x2;

        denominator = (x2 - x1);
        denominator = denominator * denominator * denominator;

        d = ( -(y2*x13) + 3*y2*x12*x2 + m2*x13*x2 + m1*x12*x22 - m2*x12*x22 - 3*x1*y1*x22 - m1*x1*x23 + y1*x23) / denominator;
        c = ( -(m2*x13) - 6*y2*x1*x2 - 2*m1*x12*x2 - m2*x12*x2 + 6*x1*y1*x2 + m1*x1*x22 + 2*m2*x1*x22 + m1*x23) / denominator;
        b = ( 3*y2*x1 + m1*x12 + 2*m2*x12 - 3*x1*y1 + 3*x2*y2 + m1*x1*x2 - m2*x1*x2 - 3*y1*x2 - 2*m1*x22 - m2*x22) / denominator;
        a = ( -2*y2 - m1*x1 - m2*x1 + 2*y1 + m1*x2 + m2*x2) / denominator;

        NSLog(@"\n===\n x1 = %f y1 = %f m1 = %f", x1, y1, m1);
        NSLog(@"x2 = %f y2 = %f m2 = %f", x2, y2, m2);
        NSLog(@"a = %f b = %f c = %f d = %f", a, b, c, d);

        xx = (float)x1 / timeScale;
        yy = ((float)y1 * ([self frame].size.height - 70.0)) / 30.0 + 5.0;

        [[NSColor blackColor] set];

        bezierPath = [[NSBezierPath alloc] init];
        [bezierPath moveToPoint:NSMakePoint(xx,yy)];
        for (i = (int) x1; i <= (int)x2; i++) {
            x = (double) i;
            y = x*x*x*a + x*x*b + x*c + d;

            xx = (float)i/timeScale;
            yy = (float) ((float)y * ([self frame].size.height - 70.0)) / 30.0 + 5.0;
            //NSLog(@"x = %f y = %f  yy = %f", (float)i, y, yy);
            [bezierPath lineToPoint:NSMakePoint(xx,yy)];
        }
        [bezierPath stroke];
        [bezierPath release];
    }
}

//
// Event handling
//

- (void)mouseEntered:(NSEvent *)theEvent;
{
#ifdef PORTING
    NSEvent *nextEvent;
    NSPoint position;
    int time;

    [[self window] setAcceptsMouseMovedEvents:YES];
    while (1) {
        nextEvent = [[self window] nextEventMatchingMask:NSAnyEventMask];
        if (([nextEvent type] != NSMouseMoved) && ([nextEvent type] != NSMouseExited))
            [NSApp sendEvent:nextEvent];

        if ([nextEvent type] == NSMouseExited)
            break;

        if (([nextEvent type] == NSMouseMoved) && [[self window] isKeyWindow]) {
            position.x = [nextEvent locationInWindow].x;
            position.y = [nextEvent locationInWindow].y;
            position = [self convertPoint:position fromView:nil];
            time = (int)((position.x - 80.0) * timeScale);
//            if ((position.x<80.0) || (position.x>frame.size.width-20.0))
//                [mouseTimeField setStringValue:"--"];
//            else
//                [mouseTimeField setIntValue: (int)((position.x-80.0)*timeScale)];
        }

    }
    [[self window] setAcceptsMouseMovedEvents:NO];
#endif
}

- (void)keyDown:(NSEvent *)theEvent;
{
    int i, numRules, pointCount;
    IntonationPoint *tempPoint;
    //NSLog(@"KeyDown %d", theEvent->data.key.keyCode);

    NSLog(@" > %s", _cmd);

    numRules = [eventList numberOfRules];
    pointCount = [selectedPoints count];

    switch ([theEvent keyCode]) {
      case NSDeleteFunctionKey:
          NSLog(@"delete");
          [self deletePoints];
          break;

      case NSLeftArrowFunctionKey:
          NSLog(@"left arrow");
          for (i = 0; i < pointCount; i++) {
              if ([[selectedPoints objectAtIndex:i] ruleIndex] - 1 < 0) {
                  NSBeep();
                  return;
              }
          }

          for (i = 0; i < pointCount; i++) {
              tempPoint = [selectedPoints objectAtIndex:i];
              [tempPoint setRuleIndex:[tempPoint ruleIndex] - 1];
              [eventList addIntonationPoint:tempPoint];
          }
          break;

      case NSRightArrowFunctionKey:
          NSLog(@"right arrow");
          for (i = 0; i < pointCount; i++) {
              if ([[selectedPoints objectAtIndex:i] ruleIndex] + 1 >= numRules) {
                  NSBeep();
                  return;
              }
          }

          for (i = 0; i < pointCount; i++) {
              tempPoint = [selectedPoints objectAtIndex:i];
              [tempPoint setRuleIndex:[tempPoint ruleIndex] + 1];
              [eventList addIntonationPoint:tempPoint];
          }
          break;

      case NSUpArrowFunctionKey:
          NSLog(@"up arrow");
          for (i = 0; i < pointCount; i++) {
              if ([[selectedPoints objectAtIndex:i] semitone] +1.0 > 10.0) {
                  NSBeep();
                  return;
              }
          }

          for (i = 0; i < pointCount; i++) {
              tempPoint = [selectedPoints objectAtIndex:i];
              [tempPoint setSemitone:[tempPoint semitone] + 1.0];
          }
          break;

      case NSDownArrowFunctionKey:
          NSLog(@"down arrow");
          for (i = 0; i < pointCount; i++) {
              if ([[selectedPoints objectAtIndex:i] semitone] - 1.0 < -20.0) {
                  NSBeep();
                  return;
              }
          }

          for (i = 0; i < pointCount; i++) {
              tempPoint = [selectedPoints objectAtIndex:i];
              [tempPoint setSemitone:[tempPoint semitone] - 1.0];
          }
          break;
    }

    [self setNeedsDisplay:YES];

    NSLog(@"<  %s", _cmd);
}

// Single click selects an intonation point
// Control clicking and then dragging adjusts the scale
// Rubberband selection of multiple points
// Double-clicking adds intonation point?
- (void)mouseDown:(NSEvent *)theEvent;
{
#ifdef PORTING
    float row, column;
    float row1, column1;
    float row2, column2;
    float temp, distance, distance1, tally = 0.0, tally1 = 0.0;
    float semitone;
    NSPoint mouseDownLocation = [theEvent locationInWindow];
    NSEvent *newEvent;
    int i, ruleIndex = 0;
    struct _rule *rule;
    IntonationPoint *iPoint;
    id tempPoint;

    [[self window] setAcceptsMouseMovedEvents:YES];

    /* Get information about the original location of the mouse event */
    mouseDownLocation = [self convertPoint:mouseDownLocation fromView:nil];
    row = mouseDownLocation.y;
    column = mouseDownLocation.x;

    /* Single click mouse events */
    if ([theEvent clickCount] == 1) {
        for (i = 0; i < [intonationPoints count]; i++) {
            tempPoint = [intonationPoints objectAtIndex:i];
            row1 = (([tempPoint semitone]+20.0) * ([self frame].size.height-70.0) / 30.0)+5.0;
            column1 = [tempPoint absoluteTime] / timeScale;

            if ( ((row1-row)*(row1-row) + (column1-column)*(column1-column)) < 100.0) {
                [selectedPoints removeAllObjects];
                [selectedPoints addObject:tempPoint];
                [self _selectionDidChange];
                [self setNeedsDisplay:YES];

                return;
            }
        }

        if (([theEvent modifierFlags] && NSControlKeyMask) || ([theEvent modifierFlags] && NSControlKeyMask)) {
            mouseBeingDragged = 1;
            [self lockFocus];
            [self updateScale:(float)column];
            [self unlockFocus];
            mouseBeingDragged = 0;
            [self setNeedsDisplay:YES];
        } else {
            NSPoint loc;

            [self lockFocus];
            //PSsetinstance(TRUE);
            while (1) {
                NSBezierPath *bezierPath;

                newEvent = [NSApp nextEventMatchingMask:NSAnyEventMask
                                  untilDate:[NSDate distantFuture]
                                  inMode:NSEventTrackingRunLoopMode
                                  dequeue:YES];
                //PSnewinstance();
                if ([newEvent type] == NSLeftMouseUp)
                    break;

                loc = [self convertPoint:[newEvent locationInWindow] fromView:nil];

                [[NSColor darkGrayColor] set];
                bezierPath = [[NSBezierPath alloc] init];
                [bezierPath moveToPoint:NSMakePoint(column, row)];
                [bezierPath lineToPoint:NSMakePoint(column, loc.y)];
                [bezierPath lineToPoint:NSMakePoint(loc.x, loc.y)];
                [bezierPath lineToPoint:NSMakePoint(loc.x, row)];
                [bezierPath lineToPoint:NSMakePoint(column, row)];
                [bezierPath stroke];
                [bezierPath release];

                [[self window] flushWindow];

            }
            //PSsetinstance(FALSE);
            loc = [self convertPoint:[newEvent locationInWindow] fromView:nil];

            if (row < [newEvent locationInWindow].y)
                row1 = loc.y;
            else {
                row1 = row;
                row = loc.y;
            }

            if (column < loc.x)
                column1 = loc.x;
            else {
                column1 = column;
                column = loc.x;
            }

            [selectedPoints removeAllObjects];
            for (i = 0; i < [intonationPoints count]; i++) {
                tempPoint = [intonationPoints objectAtIndex:i];
                column2 = [tempPoint absoluteTime] / timeScale;

                row2 = (([tempPoint semitone]+20.0) * ([self frame].size.height-70.0) / 30.0)+5.0;

                if ((row2 < row1) && (row2 > row))
                    if ((column2 < column1) && (column2 > column))
                        [selectedPoints addObject:tempPoint];
            }

            [self unlockFocus];
            [self _selectionDidChange];
            [self setNeedsDisplay:YES];
        }
    }

    /* Double Click mouse events */
    if ([theEvent clickCount] == 2) {
        if (![eventList numberOfRules])
            return;

        temp = column * timeScale;
        semitone = (double) (((row-5.0)/([self frame].size.height-70.0))*30.0)-20.0;

        distance = 1000000.0;

        tally = tally1 = 0.0;

        for (i = 0; i < [eventList numberOfRules]; i++) {
            rule = [eventList getRuleAtIndex:i];
            distance1 = (float) fabs(temp - rule->beat);
            //NSLog(@"temp: %f  beat: %f  dist: %f  distance1: %f", temp, rule->beat, distance, distance1);
            if (distance1 <= distance) {
                distance = distance1;
                ruleIndex = i;
            } else {
                rule = [eventList getRuleAtIndex:ruleIndex];
                //NSLog(@"Selecting Rule: %d phone index %d", ruleIndex, rule->lastPhone);

                // TODO (2004-08-09): Should just use -[EventList addPoint:offsetTime:slope:ruleIndex:]
                iPoint = [[IntonationPoint alloc] initWithEventList:eventList];
                [iPoint setRuleIndex:ruleIndex];
                [iPoint setOffsetTime:(double)temp - rule->beat];
                [iPoint setSemitone:semitone];
                [self addIntonationPoint:iPoint];
                [iPoint release];

                [self setNeedsDisplay:YES];
                // TODO (2004-03-31): Select new point.
                return;
            }
        }
    }
#endif
}

- (void)updateScale:(float)column;
{
#ifdef PORTING
    NSPoint mouseDownLocation;
    NSEvent *newEvent;
    float delta, originalScale;

    originalScale = timeScale;

    [[self window] setAcceptsMouseMovedEvents:YES];
    while (1) {
        newEvent = [NSApp nextEventMatchingMask:NSAnyEventMask
                          untilDate:[NSDate distantFuture]
                          inMode:NSEventTrackingRunLoopMode
                          dequeue:YES];
        mouseDownLocation = [newEvent locationInWindow];
        mouseDownLocation = [self convertPoint:mouseDownLocation fromView:nil];
        delta = column-mouseDownLocation.x;
        timeScale = originalScale + delta / 20.0;
        if (timeScale > 10.0)
            timeScale = 10.0;
        if (timeScale < 0.1)
            timeScale = 0.1;
        //[self clearView];
        [self drawGrid];
        [[self window] flushWindow];

        if ([newEvent type] == NSLeftMouseUp)
            break;
    }

    [[self window] setAcceptsMouseMovedEvents:NO];
#endif
}

- (void)deselectAllPoints;
{
    [selectedPoints removeAllObjects];
    [self setNeedsDisplay:YES];
    [self _selectionDidChange];
}

- (void)deletePoints;
{
    int i;
    id tempPoint;

    if ([selectedPoints count]) {
        for (i = 0; i < [selectedPoints count]; i++) {
            tempPoint = [selectedPoints objectAtIndex:i];
            [eventList removeIntonationPoint:tempPoint];
            [tempPoint release];
        }

        [selectedPoints removeAllObjects];
        [self setNeedsDisplay:YES];
        [self _selectionDidChange];
    } else {
        NSBeep();
    }
}

- (IntonationPoint *)selectedIntonationPoint;
{
    if ([selectedPoints count] == 0)
        return nil;

    return [selectedPoints objectAtIndex:0];
}

- (void)selectIntonationPoint:(IntonationPoint *)anIntonationPoint;
{
    [selectedPoints removeAllObjects];
    if (anIntonationPoint != nil)
        [selectedPoints addObject:anIntonationPoint];
    [self setNeedsDisplay:YES];
    [self _selectionDidChange];
}

- (void)_selectionDidChange;
{
    NSNotification *aNotification;

    aNotification = [NSNotification notificationWithName:IntonationViewSelectionDidChangeNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotification:aNotification];

    if ([[self delegate] respondsToSelector:@selector(intonationViewSelectionDidChange:)] == YES)
        [[self delegate] intonationViewSelectionDidChange:aNotification];
}

//
// View geometry
//

- (int)sectionHeight;
{
    NSRect bounds;
    int sectionHeight;

    bounds = [self bounds];
    sectionHeight = (bounds.size.height - TOP_MARGIN - BOTTOM_MARGIN) / SECTION_COUNT;

    return sectionHeight;
}

- (NSPoint)graphOrigin;
{
    NSPoint graphOrigin;

    graphOrigin.x = LEFT_MARGIN;
    graphOrigin.y = [self bounds].size.height - TOP_MARGIN - SECTION_COUNT * [self sectionHeight];

    return graphOrigin;
}

- (void)updateEvents;
{
    [self deselectAllPoints];
    // TODO (2004-08-09): And select the first point again?
    [self setNeedsDisplay:YES];
}

@end
