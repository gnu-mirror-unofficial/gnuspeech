//  This file is part of Gnuspeech, an extensible, text-to-speech package, based on real-time, articulatory, speech-synthesis-by-rules. 
//  Copyright 1991-2012 David R. Hill, Leonard Manzara, Craig Schock

#import "MWindowController.h"

@class MMCategory, MModel, MMParameter, MMSymbol;

@interface MDataEntryController : MWindowController

- (id)initWithModel:(MModel *)aModel;

- (MModel *)model;
- (void)setModel:(MModel *)newModel;

- (NSUndoManager *)undoManager;

- (void)updateViews;
- (void)_selectFirstRows;
- (void)_updateCategoryComment;
- (void)_updateParameterComment;
- (void)_updateMetaParameterComment;
- (void)_updateSymbolComment;

// Actions
- (IBAction)addCategory:(id)sender;
- (IBAction)removeCategory:(id)sender;

- (IBAction)addParameter:(id)sender;
- (IBAction)removeParameter:(id)sender;

- (IBAction)addMetaParameter:(id)sender;
- (IBAction)removeMetaParameter:(id)sender;

- (IBAction)addSymbol:(id)sender;
- (IBAction)removeSymbol:(id)sender;

// NSTableView data source
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;

// NSTableView delegate
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;

// NSTextView delegate
- (void)textDidEndEditing:(NSNotification *)aNotification;

- (MMCategory *)selectedCategory;
- (MMParameter *)selectedParameter;
- (MMParameter *)selectedMetaParameter;
- (MMSymbol *)selectedSymbol;

@end
