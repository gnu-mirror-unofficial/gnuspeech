#import <Foundation/NSObject.h>

@class EventList, MMSynthesisParameters, MonetList, PhoneList;
@class EventListView, IntonationScrollView, IntonationView;

/*===========================================================================

	Author: Craig-Richard Taube-Schock
		Copyright (c) 1994, Trillium Sound Research Incorporated.
		All Rights Reserved.

=============================================================================
*/

@interface StringParser : NSObject
{
    int cache;

    EventList *eventList;
    PhoneList *phoneList;

    IBOutlet IntonationScrollView *intonationSystem;

    /* Min and Max for each parameter */
    double min[16];
    double max[16];

    IBOutlet NSTextField *stringTextField;
    IBOutlet EventListView *eventListView;
    IBOutlet NSScrollView *intonationView;

    IBOutlet NSTextField *tempoField;

    IBOutlet NSTextField *filenameField;
    IBOutlet NSButton *parametersStore;
    IBOutlet NSMatrix *intonationMatrix;
    IBOutlet NSForm *intonParmsField;
    IBOutlet NSTextField *driftDeviationField;
    IBOutlet NSTextField *driftCutoffField;

    IBOutlet NSButton *smoothIntonationSwitch;

    IBOutlet NSTextField *radiusMultiplyField;

    MMSynthesisParameters *synthesisParameters;
}

+ (NSCharacterSet *)gsStringParserWhitespaceCharacterSet;
+ (NSCharacterSet *)gsStringParserDefaultCharacterSet;

- (id)init;
- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (void)parseStringButton:(id)sender;
- (void)synthesizeWithSoftware:(id)sender;

- (void)setUpDataStructures;

- (void)automaticIntonation:(id)sender;

- (void)parsePhoneString:(NSString *)str;

@end
