#import "CategoryInspector.h"

#import <AppKit/AppKit.h>
#import "CategoryNode.h"
#import "Inspector.h"

@implementation CategoryInspector

- (id)init;
{
    if ([super init] == nil)
        return nil;

    return self;
}

- (void)inspectCategory:(CategoryNode *)aCategory;
{
    currentCategory = aCategory;
    [mainInspector setPopUpListView:categoryPopUpListView];
    [self setUpWindow:categoryPopUpList];
}

- (void)setUpWindow:(NSPopUpButton *)sender;
{
    NSString *str;

    str = [[sender selectedCell] title];
    if ([str hasPrefix:@"C"]) {
        /* Comment Window */
        [mainInspector setGeneralView:commentView];

        [setButton setTarget:self];
        [setButton setAction:@selector(setComment:)];

        [revertButton setTarget:self];
        [revertButton setAction:@selector(revertComment:)];

        [commentText setString:[currentCategory comment]];
    }
}

- (void)beginEditting;
{
    NSString *str;

    str = [[categoryPopUpList selectedCell] title];
    if ([str hasPrefix:@"C"]) {
        /* Comment Window */
        [commentText selectAll:self];
    }
}

- (IBAction)setComment:(id)sender;
{
    [currentCategory setComment:[commentText string]];
}

- (IBAction)revertComment:(id)sender;
{
    [commentText setString:[currentCategory comment]];
}


@end
