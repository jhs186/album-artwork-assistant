//
//  QuickLookImageBrowserView.m
//  Album Artwork Assistant
//
//  Created by Marc Liyanage on 22.07.08.
//

// Info and code taken from
// http://www.macresearch.org/cocoa-tutorial-image-kit-cover-flow-and-quicklook-doing-things-we-shouldnt-are-too-fun-resist
// http://ciaranwal.sh/2007/12/07/quick-look-apis


#import "QuickLookImageBrowserView.h"
#import "QuickLook.h"
#import "GoogleImageItem.h"
#import "StatusDelegateProtocol.h"
#import "IKImageBrowserFileUrlDataSource.h"

@implementation QuickLookImageBrowserView

- (void)awakeFromNib {
	[self setupQuickLook];
}

- (void)setupQuickLook {
	if(![[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/QuickLookUI.framework"] load]) {
		NSLog(@"Unable to load Quick Look");
		return;
	}

	quickLookPanelClass = NSClassFromString(@"QLPreviewPanel");

	[self setQuickLookPanelDelegate:self];

//	NSLog(@"Quick Look loaded");
}



- (void)keyDown:(NSEvent *)event {	
	if([[event charactersIgnoringModifiers] characterAtIndex:0] == ' ') {
		[self userDidPressSpaceInImageBrowserView:self];
	} else {
		[super keyDown:event];
	}
}


- (void)userDidPressSpaceInImageBrowserView:(id)aBrowser {
	if (!quickLookPanelClass) return;
	// If the user presses space when the preview panel is open then we close it
	if([[quickLookPanelClass sharedPreviewPanel] isOpen])
		[[quickLookPanelClass sharedPreviewPanel] closeWithEffect:2];
	else {
		[self updateQuicklook];
	}
}


- (void)updateQuicklook {
	// Otherwise, set the current items
	NSIndexSet *selected = [self selectionIndexes];
	if (![selected count]) return;
	int index = [selected firstIndex];
	[self quickLookSelectedItems:index];

	NSMutableArray* URLs = [NSMutableArray array];
	[[quickLookPanelClass sharedPreviewPanel] setURLs:URLs currentIndex:0 preservingDisplayState:YES];

	// Restore the focus to our window to demo the selection changing, scrolling 
	// (left/right) and closing (space) functionality
	[[self window] makeKeyWindow];
}


- (void)quickLookSelectedItems:(int)itemIndex {
	GoogleImageItem *item = [[self dataSource] imageBrowser:self itemAtIndex:itemIndex];
	[[self delegate] startBusy:@"Loading Image"];
	[self performSelector:@selector(quickLookSelectedItems2:) withObject:[item url] afterDelay:0.1];
}


- (void)quickLookSelectedItems2:(NSString *)urlString {
	int index = [[self selectionIndexes] firstIndex];
	NSURL *fileUrl = [[self dataSource] fileUrlForItemAtIndex:index];
	
	[[self delegate] clearBusy];

	if (!fileUrl) {
		NSLog(@"unable to get item file url for quicklook");
		[[quickLookPanelClass sharedPreviewPanel] close];
		return;
	}

	NSMutableArray* URLs = [NSMutableArray arrayWithCapacity:1];
	[URLs addObject:fileUrl];
	[[quickLookPanelClass sharedPreviewPanel] setURLs:URLs currentIndex:0 preservingDisplayState:YES];
	[[quickLookPanelClass sharedPreviewPanel] makeKeyAndOrderFrontWithEffect:2];
}

 
- (void)setQuickLookPanelDelegate:(id)delegate {
	if (!quickLookPanelClass) return;
	[[[quickLookPanelClass sharedPreviewPanel] windowController] setDelegate:delegate];
}


#pragma mark QuickLook Panel delegate methods

- (NSRect)previewPanel:(NSPanel*)panel frameForURL:(NSURL*)URL {
	NSIndexSet *selected = [self selectionIndexes];
	NSAssert([selected count] > 0, @"no items selected");
	int index = [selected firstIndex];

	NSRect itemFrame = [self convertRectToBase:[self itemFrameAtIndex:index]];
	itemFrame.origin = [[self window] convertBaseToScreen:itemFrame.origin];
	return itemFrame;
}







@end