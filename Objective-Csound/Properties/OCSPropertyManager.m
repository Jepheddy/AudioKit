//
//  OCSPropertyManager.m
//
//  Created by Adam Boulanger on 6/15/12.
//  Copyright (c) 2012 Hear For Yourself. All rights reserved.
//

#import "OCSPropertyManager.h"

void OCSPropertyManagerReadProc(const MIDIPacketList *pktlist, void *refcon, void *srcConnRefCon);

@implementation OCSPropertyManager
@synthesize propertyList;

- (id)init {
    if(self = [super init]) {
        propertyList = [[NSMutableArray alloc] init];
        for (int i = 0; i<128; i++) {
            [propertyList addObject:[NSNull null]];
        }
        
    [self openMidiIn];
    }
    return self;
}

/*- (void)addProperty:(OCSProperty *)prop forControllerNumber:(int)controllerNumber andChannelName:(NSString *)uniqueIdentifier
{
    if (controllerNumber < 0 || controllerNumber > 127) {
        NSLog(@"Error: Attempted to add a widget with controller number outside of range 0-127: %d", controllerNumber);
        return;
    }
    
    [propertyList replaceObjectAtIndex:controllerNumber withObject:prop];
}*/

- (void)addProperty:(OCSProperty *)prop
{
    [propertyList addObject:prop];
    //[[OCSManager sharedOCSManager] addPropertyParam:prop];
}

/* coremidi callback, called when MIDI data is available */
void OCSPropertyManagerReadProc(const MIDIPacketList *pktlist, void *refcon, void *srcConnRefCon){
    OCSPropertyManager* manager = (__bridge OCSPropertyManager *)refcon;  
	MIDIPacket *packet = &((MIDIPacketList *)pktlist)->packet[0];
	Byte *curpack;
    int i, j;
	
	for (i = 0; i < pktlist->numPackets; i++) {
		for(j=0; j < packet->length; j+=3){
			curpack = packet->data+j;
            
			if ((*curpack++ | 0xB0) > 0) {
                unsigned int controllerNumber = (unsigned int)(*curpack++);
                //unsigned int controllerValue = (unsigned int)(*curpack++);
                
                id param = [manager.propertyList objectAtIndex:controllerNumber];
                
                //NSLog(@"Controller Number: %d Value: %d", controllerNumber, controllerValue);
                
                if (param != [NSNull null]) {
                    //WORKING HERE: setMidiValue
                    //[(id<MidiWidgetWrapper>)wrapper setMIDIValue:controllerValue];
                }
            }
            
		}
		packet = MIDIPacketNext(packet);
	} 
    
}

#pragma mark CoreMidi Code
- (void)openMidiIn {
    int k, endpoints;
    
    CFStringRef name = NULL, cname = NULL, pname = NULL;
    CFStringEncoding defaultEncoding = CFStringGetSystemEncoding();
    MIDIPortRef mport = NULL;
    MIDIEndpointRef endpoint;
    OSStatus ret;
	
    /* MIDI client */
    cname = CFStringCreateWithCString(NULL, "my client", defaultEncoding);
    ret = MIDIClientCreate(cname, NULL, NULL, &myClient);
    if(!ret){
        /* MIDI output port */
        pname = CFStringCreateWithCString(NULL, "outport", defaultEncoding);
        ret = MIDIInputPortCreate(myClient, pname, OCSPropertyManagerReadProc, self, &mport);
        if(!ret){
            /* sources, we connect to all available input sources */
            endpoints = MIDIGetNumberOfSources();
			//NSLog(@"midi srcs %d\n", endpoints); 
            for(k=0; k < endpoints; k++){
                endpoint = MIDIGetSource(k);
                void *srcRefCon = endpoint;
                MIDIPortConnectSource(mport, endpoint, srcRefCon);
                
            }
        }
    }
    if(name) CFRelease(name);
    if(pname) CFRelease(pname);
    if(cname) CFRelease(cname); 
    
}

- (void)closeMidiIn {
    MIDIClientDispose(myClient);
}

- (void)dealloc {
    [propertyList release];
    [super dealloc];
}

@end