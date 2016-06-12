#import "STApplication.h"


@interface STAppDelegate ()

@property (nonatomic, strong, readwrite) NSStatusItem *statusItem;
@property (nonatomic, strong, readwrite) NSTimer *updateTimer;
@property (nonatomic, strong, readwrite) XGSyncthing *syncthing;
@property (strong) STPreferencesWindowController *preferencesWindow;

@end

@implementation STAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.syncthing = [[XGSyncthing alloc] init];
    
    [self applicationLoadConfiguration];
    [self.syncthing runExecutable];
    
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateStatusFromTimer) userInfo:nil repeats:YES];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

- (void) awakeFromNib {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self updateStatusIcon:@"StatusIconNotify"];

    self.statusItem.menu = self.Menu;
}

- (void)applicationLoadConfiguration
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSString *cfgExecutable  = [defaults stringForKey:@"Executable"];
    if (cfgExecutable) {
        [self.syncthing setExecutable:cfgExecutable];
    } else {
        [self.syncthing setExecutable:[NSString stringWithFormat:@"%@/%@",
                                       [[NSBundle mainBundle] resourcePath],
                                       @"syncthing/syncthing"]];
    }

    NSString *cfgURI         = [defaults stringForKey:@"URI"];
    if (cfgURI) {
        [self.syncthing setURI:cfgURI];
    } else {
        [self.syncthing setURI:@"http://localhost:8384"];
        [defaults setObject:[self.syncthing URI] forKey:@"URI"];
    }

    NSString *cfgApiKey      = [defaults stringForKey:@"ApiKey"];
    if (cfgApiKey) {
        [self.syncthing setApiKey:cfgApiKey];
    } else {
        [self.syncthing setApiKey:@""];
        [defaults setObject:[self.syncthing ApiKey] forKey:@"ApiKey"];
    }
}

- (void) sendNotification:(NSString *) text
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"Syncthing";
    notification.informativeText = text;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (void) updateStatusIcon:(NSString *) icon
{
    self.statusItem.button.image = [NSImage imageNamed:icon];
}

- (void)updateStatusFromTimer
{
    if ([self.syncthing ping]) {
        [self updateStatusIcon:@"StatusIconDefault"];
        [self.statusItem setToolTip:[
                                     NSString stringWithFormat:@"Syncthing - Connected\n%@\nUptime %@",
                                     [self.syncthing URI],
                                     [self.syncthing getUptime]
                                     ]];
    } else {
        [self updateStatusIcon:@"StatusIconNotify"];
        [self.statusItem setToolTip:@"Syncthing - Not connected"];
    }
}

- (IBAction)clickedOpen:(id)sender
{
    NSURL *URL = [NSURL URLWithString:[self.syncthing URI]];
    [[NSWorkspace sharedWorkspace] openURL:URL];
}

- (IBAction)clickedQuit:(id)sender
{
    // Stop update timer
    [self.updateTimer invalidate];
    self.updateTimer = nil;
    
    // Set icon and remove menu
    [self updateStatusIcon:@"StatusIconNotify"];
    [self.statusItem setToolTip:@""];
    self.statusItem.menu = nil;
    
    [self.syncthing stopExecutable];
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:1.0];
}

- (IBAction)clickedPreferences:(NSMenuItem *)sender
{
    self.preferencesWindow = [[STPreferencesWindowController alloc] init];
    [self.preferencesWindow.window setLevel:NSFloatingWindowLevel];
    [self.preferencesWindow showWindow:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(preferencesWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:[self.preferencesWindow window]];
}

- (void)preferencesWillClose:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSWindowWillCloseNotification
                                                  object:[self.preferencesWindow window]];
    self.preferencesWindow = nil;
}

@end