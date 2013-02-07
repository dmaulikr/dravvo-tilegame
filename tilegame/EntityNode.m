//
//  EntityNode.m
//  tilegame
//
//  Created by mogura on 1/26/13.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCSequence+Helper.h"
#import <GameKit/GameKit.h>
#import "EntityNode.h"
#import "CoreGameLayer.h"
#import "GameConstants.h"
#import "DVMacros.h"
//#import "CCSequence+Helper.h"
#import "CCSequenceHelper.h"

static NSMutableArray* _eventHistory;  // the entire event history of all Entitiy's
//static int _numAnimationsPlaying;

// Entity's include Bat, Missile, Shuriken, Player?
// IN the very least, make sure that all previous time step actions and animations are finished before performing the next time step's actions from main
@implementation EntityNode

@synthesize gameLayer = _gameLayer;
@synthesize sprite = _sprite;
@synthesize uniqueID = _uniqueID;
@synthesize hitPoints = _hitPoints;
@synthesize isAlive = _isAlive;
@synthesize spawnPoint = _spawnPoint;
@synthesize lastPoint = _lastPoint;
@synthesize actionsToBePlayed = _actionsToBePlayed;

+(NSMutableArray*) eventHistory  // the entire event history of all Entitiy's getter method
{
    if(!_eventHistory) // this should only run once
    {
        _eventHistory = [[NSMutableArray alloc] init];
    }
    return _eventHistory;
}

/*
+(int) numAnimationsPlaying
{
    return _numAnimationsPlaying;
}

+(void) callbackAnimationsFinished
{
    _numAnimationsPlaying--;
    if(_numAnimationsPlaying == 0)
        [CoreGameLayer repeatMe];
}
*/
 
+(void) animateDeathForEntityType:(NSString*) theEntityType at:(CGPoint) deathPoint  // TO DO Takes a position and an EntityType
{
    // TO DO
}

-(id)initInLayer:(CCNode *)layer atSpawnPoint:(CGPoint)spawnPoint
{
    if (self = [super init]) {
        _actionsToBePlayed = [[NSMutableArray alloc] init];

        self->_gameLayer = layer;
        self->_spawnPoint = _lastPoint = spawnPoint;
    }
    return self;
}

-(id)initInLayerWithoutCache:(CCNode *)layer atSpawnPoint:(CGPoint)spawnPoint
{
    if (self = [super init]) {
        _actionsToBePlayed = [[NSMutableArray alloc] init];

        self->_gameLayer = layer;
        self->_spawnPoint = _lastPoint = spawnPoint;
    }
    return self;
}
// All event types but wounded:
//  kDVEventKey_TimeStepIndex, kDVEventKey_EventType, kDVEventKey_OwnerID, kDVEventKey_EntityType, kDVEventKey_EntityID, kDVEventKey_CoordX, kDVEventKey_CoordY
// "wounded" event type only:
//  kDVEventKey_TimeStepIndex, kDVEventKey_EventType, kDVEventKey_OwnerID, kDVEventKey_EntityType, kDVEventKey_EntityID, kDVEventKey_HPChange

-(NSMutableDictionary *)cacheStateForEvent:(DVEventType)event
{
    DLog(@"cacheStateForEvent...");
    CoreGameLayer* layer = (CoreGameLayer *)self.gameLayer;
    NSMutableDictionary* eventData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:layer.timeStepIndex], kDVEventKey_TimeStepIndex,
                                      self.entityType, kDVEventKey_EntityType,
                                      [NSNumber numberWithInt:self.uniqueID], kDVEventKey_EntityID,
                                      [NSNumber numberWithInt:event], kDVEventKey_EventType,
                                      nil];
    switch (event) {
        case DVEvent_Spawn:
        case DVEvent_Respawn:
        case DVEvent_Move:
            [eventData addEntriesFromDictionary:
             [NSDictionary dictionaryWithObjectsAndKeys:
              [NSNumber numberWithFloat:self.sprite.position.x], kDVEventKey_CoordX,
              [NSNumber numberWithFloat:self.sprite.position.y], kDVEventKey_CoordY,
              nil]];
            break;
            
        case DVEvent_Wound:
            [eventData addEntriesFromDictionary:
             [NSDictionary dictionaryWithObjectsAndKeys:
              [NSNumber numberWithInt:self.hitPoints], kDVEventKey_HPChange,
              nil]];
            break;
            
        case DVEvent_InitStats:
        case DVEvent_Kill:
        default:
            break;
    }
    
    // Now put this dictionary onto the object's NSMuttableArray
    DLog(@"[eventData count] = %d",[eventData count]);

    [[EntityNode eventHistory] addObject:eventData];
//    layer.eventHistory
    DLog(@"[layer.eventHistory count] = %d", [[EntityNode eventHistory] count]);
    return eventData;
}

// for sampling during real actions, this should be called (callbacked) once every kTimeStepSeconds for later animation on
-(void)sampleCurrentPosition
{
    DLog(@"Cacheing in sampleCurrentPosition for DVEvent_Move: entityType= %@, uniqueID= %d...", self.entityType, self.uniqueID);
    [self cacheStateForEvent:DVEvent_Move];

    /*
     // generate a "move" event string entry from last point to current point with a time differential of kPlaybackTickLengthSeconds
     NSString* activityEntry = [NSString stringWithFormat:@"%d aniMove %@ %d %d %d",
     myLayer.timeStepIndex, ownerAndEntityID, uniqueIntID, (int)sprite.position.x, (int)sprite.position.y];
     
     [self.historicalEventsList_local addObject:activityEntry];
     DLog(@"sample...%@",activityEntry);
     */
}


-(void)takeDamage:(int)damagePoints
{
    self.hitPoints -= damagePoints;
    [self cacheStateForEvent:DVEvent_Wound];
    
    /*
     NSString* activityEntry = [NSString stringWithFormat:@"%d wound %@ %d %d -1",
     myLayer.timeStepIndex, ownerAndEntityID, uniqueIntID, hpLost];
     //[Bat uniqueIntIDCounter]
     
     [self.historicalEventsList_local addObject:activityEntry];
     DLog(@"wound...%@",activityEntry);
     */
    
    //  There's concurrency problems here so we have to wait for kill to be called from HelloWorldLayer first FIX
    //    if(hitPoints < 1)
    //        [self kill];
}

// push all animations onto the NSMuttable Actions array
// done in sub-classes since we don't know speed of movement of each entity at top level
// for later animation re-play on player2's side
// each minion has it's own list of animations that can be performed on it, such as exploding, moving, attacking,
// push all animations onto the NSMuttable Actions array

-(void)animateMove:(CGPoint) targetPoint  // will animate a historical move over time interval kTimeStepSeconds
{
    // test the CCSequence+Helper shit
    
    
    // make an action for moving from current point to targetPoint
    //rotate to face the direction of movement
//    CGPoint diff = ccpSub(targetPoint, self.sprite.position);  // Change to this for multiplay
//    DLog(@"Starting animateMove for ID %d", self.uniqueID);
    CGPoint diff = ccpSub(targetPoint, self.lastPoint);  // temporary DEBUG for multiplay
    self.lastPoint = targetPoint;
    float angleRadians = atanf((float)diff.y / (float)diff.x);
    float angleDegrees = CC_RADIANS_TO_DEGREES(angleRadians);
    float cocosAngle = -1 * angleDegrees;
    if(diff.x < 0)
        cocosAngle += 180;
    self.sprite.rotation = cocosAngle;
    
    id actionMove = [CCMoveTo actionWithDuration:kReplayTickLengthSeconds position:targetPoint];
    
    DLog(@"BEFORE push [_actionsToBePlayed count] = %d",[_actionsToBePlayed count]);
    
    [_actionsToBePlayed addObject:actionMove];  // change to this for multiplay

    DLog(@"AFTER push [_actionsToBePlayed count] = %d",[_actionsToBePlayed count]);
    
    DLog(@"Move from %f,%f to %f,%f", self.sprite.position.x, self.sprite.position.y, targetPoint.x, targetPoint.y);

    // only temporary
//    self.sprite.position = self.spawnPoint;
//    [self.sprite runAction:actionMove];  // temporary DEBUG
    
}

-(void)animateTakeDamage:(int)damagePoints
{
    self.hitPoints -= damagePoints;   
}

-(void)animateKill
{
    [self removeChild:self.sprite cleanup:YES];
}

-(void)animateExplode:(CGPoint) targetPoint  // animate it exploding TODO this should move to weapon
{
    
}

-(void)playActionsInSequenceAndCallback_tryEnemyPlayback  // Adds all the actions in the NSMutableArray to a CCSequence and plays them
{
/*
    if([_actionsToBePlayed count] == 0)
    {
        DLog(@"No actions to be played. Returning...");
        return;
    }
*/
    DLog(@"Pushing actions sequence!!!");
//    _numAnimationsPlaying++;
//    CCSequence *seq = [CCSequence actionMutableArray:_actionsToBePlayed];

//    [self.sprite runAction:[CCSequence actionMutableArray:_actionsToBePlayed]];
    
    // increment CoreGameLayer's animations running counter
    CoreGameLayer* theLayer = (CoreGameLayer *) self.gameLayer;
    
    // push a callback action on the actionMutableArray
    id actionCallFunc = [CCCallFunc actionWithTarget:theLayer selector:@selector(tryEnemyPlayback)];

    [_actionsToBePlayed addObject:actionCallFunc];  // change to this for multiplay

    [self.sprite runAction:[CCSequenceHelper actionMutableArray:self->_actionsToBePlayed]];
    
    DLog(@"Finished pushing actions sequence!!!");
    //    [self.sprite runAction:actionMove];
}

-(void)realUpdate
{

}
-(void)realSetBehaviour:(int) newBeahavior
{
    
}
-(void)realMove:(CGPoint) targetPoint
{
    
}
-(void)realExplode:(CGPoint) targetPoint
{
    
}
-(void)kill
{
    
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInt:self.uniqueID forKey:EntityNodeUniqueID];
    [coder encodeInt:self.hitPoints forKey:EntityNodeHitPoints];
//    [coder encodeBool:self.isAlive forKey:EntityNodeIsAlive];
    [coder encodeCGPoint:self.spawnPoint forKey:EntityNodeSpawnPoint];
    [coder encodeCGPoint:self.sprite.position forKey:EntityNodePosition];
//    [coder encodeObject:self.entityType forKey:EntityNodeEntityType];
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super init]) {
        _actionsToBePlayed = [[NSMutableArray alloc] init];
        
        _uniqueID = [coder decodeIntForKey:EntityNodeUniqueID];
        _hitPoints = [coder decodeIntForKey:EntityNodeHitPoints];
//        _isAlive = [coder decodeBoolForKey:EntityNodeIsAlive];
        _spawnPoint = [coder decodeCGPointForKey:EntityNodeSpawnPoint];
        self.sprite.position = [coder decodeCGPointForKey:EntityNodePosition];
//        _entityType = [coder decodeObjectForKey:EntityNodeEntityType];
        
        _lastPoint = self.sprite.position;

    }
    return self;
}
@end