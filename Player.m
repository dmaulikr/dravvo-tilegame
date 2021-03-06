//
//  Player.m
//  tilegame2
//
//  Created by Jeremiah Anderson on 1/24/13.
//
//

#import "Player.h"
#import "CoreGameLayer.h"
#import "cocos2d.h"
#import "GameConstants.h"
#import "SimpleAudioEngine.h"

// static int _nextPlayer = kDVPlayerOne;

@implementation Player

@synthesize minions = _minions;
@synthesize mode = _mode;
@synthesize numMelons = _numMelonsCollected;
@synthesize numKills = _numKills;
@synthesize numShurikens = _numShurikens;
@synthesize numMissiles = _numMissiles;
@synthesize enemyPlayer = _enemyPlayer;
@synthesize missiles = _missiles;
@synthesize shurikens = _shurikens;
@synthesize deviceToken = _deviceToken;
/*
+(int)nextUniqueID {
    if (_nextPlayer == kDVPlayerOne) {
        _nextPlayer = kDVPlayerTwo;
        return kDVPlayerOne;
    }
    return kDVPlayerTwo;
}
*/
 
-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withUniqueIntID:(int)intID
{
    if(self = [super initInLayer:layer atSpawnPoint:spawnPoint])
    {
        self.entityType = kEntityTypePlayer;
        self.uniqueID = intID; // [Player nextUniqueID];
//        self->_playerMinionList = [[NSMutableArray alloc] init];
        self->_minions = [[NSMutableDictionary alloc] init];
        self->_missiles = [[NSMutableDictionary alloc] init];
        self->_shurikens = [[NSMutableDictionary alloc] init];
        self.mode = PlayerMode_Moving;
        
        // set Player's initial stats
        [self initStats];
        
        if(self.uniqueID == 1)
            self.sprite = [CCSprite spriteWithFile:@"PlayerGreen.png"];
        else
            self.sprite = [CCSprite spriteWithFile:@"PlayerRed.png"];
        self.sprite.position = spawnPoint;

        // Player spawning is not initially reported (spawning is automatic on both sides on game initialization) - FIX later
//        [self cacheStateForEvent:DVEvent_Spawn];

        [self addChild:self.sprite];
        [self.gameLayer addChild:self];
    }
    return self;
}

-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withUniqueIntID:(int)intID withShurikens:(int)numShurikens withMissles:(int)numMissles
{
    if (self = [self initInLayer:layer atSpawnPoint:spawnPoint withUniqueIntID:intID]) {
//        self.uniqueID = intID;
        self.numShurikens = numShurikens;
        self.numMissiles = numMissles;
    }
    return self;
}

-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withUniqueIntID:(int)intID withShurikens:(int)numShurikens withMissles:(int)numMissles withKills:(int)numKills withMelons:(int)numMelons
{
    if (self = [self initInLayer:layer atSpawnPoint:spawnPoint withUniqueIntID:intID withShurikens:numShurikens withMissles:numMissles]) {
//        self.uniqueID = intID;
        self.numKills = numKills;
        self.numMelons = numMelons;
    }
    return self;
}

-(void)kill // possibly animate a death then remove this minion
{
//    [[SimpleAudioEngine sharedEngine] playEffect:@"juliaRoar.m4a"];
    //myLayer.numKills += 1;
    //[myLayer.hud numKillsChanged:myLayer.numKills];

    self.isDead = YES;
    
    // kill sound
//    DMPlayerDies.m4r
    [[SimpleAudioEngine sharedEngine] playEffect:@"DMPlayerDies.m4r"];  // preload creature sounds

    // now load the dead image
    // Don't keep a handle for it, let it remain there until the game is over (messy field of battle
    CCSprite* deadSprite = [CCSprite spriteWithFile:@"bloodSplat.png"];
    deadSprite.opacity = 175; // 0 to 255, transparent to opaque
    deadSprite.position = self.sprite.position;
    
    deadSprite.scaleX = 0.50;
    deadSprite.scaleY = 0.50;

    [self addChild:deadSprite];
    
    id scaleUpAction = [CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:1 scaleX:3.0 scaleY:3.0] rate:1.0];
    [deadSprite runAction:scaleUpAction];

    [self cacheStateForEvent:DVEvent_Kill];
 
/*
    NSString* activityEntry = [NSString stringWithFormat:@"%d kill %@ -1 -1 -1",
                               myLayer.timeStepIndex, playerID];
    
    [self.historicalEventsList_local addObject:activityEntry];
    DLog(@"kill...%@",activityEntry);
*/
    // regenerate but remain isAlive = NO until start of next round
    self.sprite.opacity = 0;  // 0 - totally transparent, 255 - opaque

    // Don't remove the sprite, just re-position back to spawn point (not a MOVE action, will need to register different history
    [self regenerate];
    
}

// called in HelloWorldLayer after if(player.isAlive == NO) { [player regenerate] }
-(void)regenerate
{
    self.sprite.position = self.spawnPoint;
    
    self.sprite.opacity = 100;
    // set Player's initial stats
    [self initStats];
    
//    [self cacheStateForEvent:DVEvent_Respawn];  // don't cache for now
    
/*
    // need to report on re-appearance
    // record an event entry for spawning
    NSString* activityEntry = [NSString stringWithFormat:@"%d regenerate %@ -1 %d %d",
                               myLayer.timeStepIndex, playerID, (int)sprite.position.x, (int)sprite.position.y];
    [self.historicalEventsList_local addObject:activityEntry];
    DLog(@"spawn...%@",activityEntry);
*/
    
}

-(void)initStats
{
    // respawn sound
    [[SimpleAudioEngine sharedEngine] playEffect:@"DMRespawn.m4r"];  // preload creature sounds

    self.isDead = NO;
    self.hitPoints = 1;

//    [self cacheStateForEvent:DVEvent_InitStats];  // don't cache for now
    
/*
    NSString* activityEntry = [NSString stringWithFormat:@"%d initStats %@ -1 -1 -1",
                               myLayer.timeStepIndex, playerID];
    //[Bat uniqueIntIDCounter]
    
    [self.historicalEventsList_local addObject:activityEntry];
    DLog(@"initStats...%@",activityEntry);
*/
}

// override has no rotation for Player like Entity
-(void)animateMove:(CGPoint) targetPoint  // will animate a historical move over time interval kTimeStepSeconds
{
    // DON'T call super
    
    // make an action for moving from current point to targetPoint
    //rotate to face the direction of movement
    //    CGPoint diff = ccpSub(targetPoint, self.sprite.position);  // Change to this for multiplay
    //    DLog(@"Starting animateMove for ID %d", self.uniqueID);
    if(targetPoint.x == self.lastPoint.x && targetPoint.y == self.lastPoint.y)
    {
        // the action is to pause the sprite for kReplayTickLengthSeconds time
        id actionStall = [CCActionInterval actionWithDuration:kReplayTickLengthSeconds];  // DEBUG does this work??
        [self.actionsToBePlayed addObject:actionStall];  // change to this for multiplay
        return;
    }
    self.lastPoint = targetPoint;
    
    id actionMove = [CCMoveTo actionWithDuration:kReplayTickLengthSeconds position:targetPoint];
    
    DLog(@"BEFORE push [_actionsToBePlayed count] = %d",[self.actionsToBePlayed count]);
    
    [self.actionsToBePlayed addObject:actionMove];  // change to this for multiplay
    
    DLog(@"AFTER push [_actionsToBePlayed count] = %d",[self.actionsToBePlayed count]);
    
    DLog(@"Move from %f,%f to %f,%f", self.sprite.position.x, self.sprite.position.y, targetPoint.x, targetPoint.y);
        
}

-(void)animateKill:(CGPoint)killPosition
{
//    [super animateKill:killPosition];  // puts any necessary sprint to last location action into the actionsToBePlayed queue
    self.isDead = YES;

    // do NOT call super, since super will remove us from the layer and we will lose minions, etc
    // instead, just re-locate to spawn point and change state variables
    
    // kill sound
    //    DMPlayerDies.m4r
    [[SimpleAudioEngine sharedEngine] playEffect:@"DMPlayerDies.m4r"];  // preload creature sounds
    
    // now load the dead image
    // Don't keep a handle for it, let it remain there until the game is over (messy field of battle
    CCSprite* deadSprite = [CCSprite spriteWithFile:@"bloodSplat.png"];
    deadSprite.opacity = 175; // 0 to 255, transparent to opaque
    deadSprite.position = self.sprite.position;
    
    deadSprite.scaleX = 0.50;
    deadSprite.scaleY = 0.50;
    
    [self addChild:deadSprite];
    
    id scaleUpAction = [CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:1 scaleX:3.0 scaleY:3.0] rate:1.0];
    [deadSprite runAction:scaleUpAction];

//    self.sprite.opacity = 0;  // 0 - totally transparent, 255 - opaque
    
    // Don't remove the sprite, just re-position back to spawn point (not a MOVE action, will need to register different history
    self.sprite.position = self.spawnPoint;
    
//    self.sprite.opacity = 100;
    // set Player's initial stats
    [[SimpleAudioEngine sharedEngine] playEffect:@"DMRespawn.m4r"];  // preload creature sounds
    
    self.isDead = NO;
    self.hitPoints = 1;

}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeObject:_minions forKey:PlayerMinionsKey];
    [coder encodeInt:_numMelonsCollected forKey:PlayerNumMelons];
    [coder encodeInt:_numKills forKey:PlayerNumKills];
    [coder encodeInt:_numShurikens forKey:PlayerNumShurikens];
    [coder encodeInt:_numMissiles forKey:PlayerNumMissiles];
    [coder encodeObject:_deviceToken forKey:PlayerDeviceToken];
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder])
    {
        self.entityType = kEntityTypePlayer;
        
        self->_minions = [coder decodeObjectForKey:PlayerMinionsKey];
        self->_missiles = [[NSMutableDictionary alloc] init];
        self->_shurikens = [[NSMutableDictionary alloc] init];
        
        // init stats
        [[SimpleAudioEngine sharedEngine] playEffect:@"DMRespawn.m4r"];  // preload creature sounds
        self.isDead = NO;
       
        self.mode = PlayerMode_Moving;
       
        if(self.uniqueID == 1)
            self.sprite = [CCSprite spriteWithFile:@"PlayerGreen.png"];
        else
            self.sprite = [CCSprite spriteWithFile:@"PlayerRed.png"];
        
        self.sprite.position = self.lastPoint = [coder decodeCGPointForKey:EntityNodePosition];
        
        _numMelonsCollected = [coder decodeIntForKey:PlayerNumMelons];
        _numKills = [coder decodeIntForKey:PlayerNumKills];
        _numShurikens = [coder decodeIntForKey:PlayerNumShurikens];
        _numMissiles = [coder decodeIntForKey:PlayerNumMissiles];
        
        [self addChild:self.sprite];
    }
    return self;
}

@end
