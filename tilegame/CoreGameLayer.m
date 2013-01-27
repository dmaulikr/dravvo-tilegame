//
//  HelloWorldLayer.m
//  tutorial_TileGame
//
//  Created by Jeremiah Anderson on 12/10/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//
// SEE: http://www.raywenderlich.com/1163/how-to-make-a-tile-based-game-with-cocos2d

// Import the interfaces
#import "CoreGameLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"
#import "SimpleAudioEngine.h"
#import "GameOverScene.h"
#import "DVMacros.h"
#import "DVConstants.h"
#import "gameConstants.h"
#import "CCSequence+Helper.h"
#import "Libs/SBJSON/SBJson.h"

#import "Bat.h"
#import "Player.h"
#import "Opponent.h"
#import "RoundFinishedScene.h"
#import "CountdownLayer.h"

#pragma mark - CoreGameLayer

static BOOL _isEnemyPlaybackRound = NO;

@implementation CoreGameLayer

@synthesize hud = _hud;
@synthesize timeStepIndex = _timeStepIndex;
@synthesize player = _player;
@synthesize historicalEventsDict = _historicalEventsDict;

@synthesize roundTimer = _roundTimer;

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
// What calls this class??
+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
	CoreGameLayer *layer = [CoreGameLayer node];
    CoreGameHudLayer* hud = [[CoreGameHudLayer alloc] initWithCoreGameLayer:layer];
    
    layer.hud = hud;  // store a member var reference to the hud so we can refer back to it to reset the label strings!
    
 	[scene addChild:layer];
    [scene addChild:hud];
    
    CountdownLayer* cdlayer = [[CountdownLayer alloc] initWithCountdownFrom:3 AndCallBlockWhenCountdownFinished:^(id status) {
        [layer startRound];
    }];

    [scene addChild:cdlayer];
	return scene;
}

#pragma mark - Game Lifecycle

-(id) init
{
	if(self=[super init]) {
        
        // init the wrapper class for the api
        self->_apiWrapper = [[DVAPIWrapper alloc] init];
        
        _timeStepIndex = 0; // step index for caching events
        self.isTouchEnabled = YES;  // set THIS LAYER as touch enabled so user can move character around with callbacks
		_isSwipe = NO; // what does this do?
        _touches = [[NSMutableArray alloc ] init]; // store the touches for missile launching

        _roundHasStarted = NO; // wait for startRound()
        self.roundTimer = (float) kTurnLengthSeconds;
        
        _shurikens = [[NSMutableArray alloc] init];
        _missiles =  [[NSMutableArray alloc] init];
        
        // sound effects pre-load
        [SimpleAudioEngine sharedEngine].backgroundMusicVolume = 0.70;
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"DMMainTheme.m4r"];

        [SimpleAudioEngine sharedEngine].effectsVolume = 1.0;
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"DMLifePack.m4r"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"hit.caf"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"move.caf"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"missileSound.m4a"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"missileExplode.m4a"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"shurikenSound.m4a"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"DMPlayerDies.m4r"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"DMZombie.m4r"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"DMZombiePain.m4r"];
        
        // load the TileMap and the tile layers
        _tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"TileMap.tmx"];
        _background = [_tileMap layerNamed:@"Background"];
        _meta = [_tileMap layerNamed:@"Meta"];
        _foreground = [_tileMap layerNamed:@"Foreground"];
        _destruction = [_tileMap layerNamed:@"Destruction"];
        _meta.visible = NO;
        
        // get the objectGroup objects layer from the tileMap, it contains spawn point objects for player and enemy sprites
        CCTMXObjectGroup* objects = [_tileMap objectGroupNamed:@"Objects"];
        NSAssert(objects != nil, @"'Objects' object group not found");
        
        // extract the "SpawnPoint" object from the tileMap object
        NSDictionary* spawnPointsDict = [objects objectNamed:@"SpawnPoint"];
        NSAssert(spawnPointsDict != nil, @"SpawnPoint object not found");

        CGPoint playerSpawnPoint = [self pixelToPoint:
            ccp([[spawnPointsDict valueForKey:@"x"] intValue],
                [[spawnPointsDict valueForKey:@"y"] intValue])];

        _player = [[Player alloc] initInLayer:self
                                 atSpawnPoint:playerSpawnPoint
                                withShurikens:kInitShurikens
                                  withMissles:kInitMissiles];
        
        // draw the enemy sprites
        // iterate through tileMap dictionary objects, finding all enemy spawn points
        // create an enemy for each one
        //        NSMutableDictionary* spawnPoint;
        
        // objects method returns an array of objects (in this case dictionaries) from the ObjectGroup
        for(spawnPointsDict in [objects objects])
        {
            if([[spawnPointsDict valueForKey:@"Enemy"] intValue] == 1)
            {

                CGPoint enemySpawnPoint = [self pixelToPoint:
                    ccp([[spawnPointsDict valueForKey:@"x"] intValue],
                        [[spawnPointsDict valueForKey:@"y"] intValue])];

                Bat *bat = [[Bat alloc] initInLayer:self
                                       atSpawnPoint:enemySpawnPoint
                                       withBehavior:DVCreatureBehaviorDefault
                                            ownedBy:_player];
                
                [self.player.minions addObject:bat]; // just in case KVO is used in future
            }
        }

        // set the view position focused on player
        [self setViewpointCenter:_player.sprite.position];
        [self addChild:_tileMap z:-1];
//        [self startRound];
    }
	return self;
}

-(void) startRound {
    _roundHasStarted = YES; // turn on touch processing
    
    // turn on all the event loops
    [self schedule:@selector(testCollisions:)];
    [self schedule:@selector(mainGameLoop:) interval:kTickLengthSeconds];
    [self schedule:@selector(sampleCurrentPositions:) interval:kReplayTickLengthSeconds];
}

-(void) roundFinished
{
    ////    [NSString stringWithFormat:@"%@_%@",opponent.playerID,kDVChangeableObjectName_bat];
    ////    // here we should make one fat NSDictionary (kDVChangeableObjectName_*) of Arrays of NSDictionarys of all the local history arrays and send it to server
    ////    NSMutableArray* playerBatsActions = [[NSMutableArray alloc] init];
    ////    for (Bat* bat in player.playerMinionList) {
    ////        [playerBatsActions addObject:bat.historicalEventsList_local];
    ////    }
    ////
    ////    historicalEventsDict = [NSDictionary dictionaryWithObjectsAndKeys:
    ////                            player.historicalEventsList_local, player.playerID,
    ////                            playerBatsActions, [NSString stringWithFormat:@"%@_%@",player.playerID, kDVChangeableObjectName_bat],
    ////                            nil];
    //    // GO JSON!
    //
    //    // unschedule the loops and everything (collision detection, etc)
    //    // [self unscheduleAllSelectors];
    //
    //    // DEBUG
    //    // now try re-playing all the historical activities from the list
    //
    //    _isEnemyPlaybackRound = YES;  // DEBUG
    //
    ///*
    //    // should force kill all the projectiles so they don't keep going off infinitly
    //    for (CCSprite *projectile in _projectiles) {
    //        // FIX LATER - need to add [projectile kill] so that a historical record is made of killing all projectile entities
    //        [_projectiles removeObject:projectile];
    //        [self removeChild:projectile cleanup:YES];
    //    }
    //
    //    for (CCSprite *missile in _missiles) {
    //        // FIX LATER - need to add [projectile kill] so that a historical record is made of killing all projectile entities
    //        [_missiles removeObject:missile];  // remove our reference to this shuriken from the projectiles array of sprite objects
    //        [self removeChild:missile cleanup:YES];
    //    }
    //*/
    //
    //    // FIX for now, remove all sprites too so we can playback Player1's turn for DEBUG
    //
    //
    //    // [self enemyPlayback];
    //    [self->_apiWrapper postUpdateGameWithUpdates:_historicalEventsDict ThenCallBlock:^(NSError *error) {
    //        if (error != nil) {
    //            ULog([error localizedDescription]);
    //        }
    //        DLog(@"success");
    //    }];
    //
    
    [self unscheduleAllSelectors];
    
    // transition to a waiting for opponent scene, ideally displaying current stats (maybe keep HUD up)
    GameOverScene *gameOverScene = [GameOverScene node];
    [gameOverScene.layer.label setString:@"Round Finished!"];
    [[CCDirector sharedDirector] replaceScene:gameOverScene];
}

- (void) win {
    GameOverScene *gameOverScene = [GameOverScene node];
    [gameOverScene.layer.label setString:@"You Win!"];
    [[CCDirector sharedDirector] replaceScene:gameOverScene];
}

- (void) lose {
    // delete the player, re-init and re-spawn him back at the beginning,
    // then idle him there until turn is finished (no moving or attacking allowed)
    
    [self.player takeDamage:2];
    [self.player kill];
    
    // [self scheduleOnce:@selector(roundFinished) delay:3.0];
    
    //    GameOverScene *gameOverScene = [GameOverScene node];
    //    [gameOverScene.layer.label setString:@"You Lose!"];
    //    [[CCDirector sharedDirector] replaceScene:gameOverScene];
}

#pragma mark - Callbacks
-(void) mainGameLoop:(ccTime)deltaTime
{
    // update the minions
    for (Bat *theMinion in _player.minions) {
        [theMinion realUpdate];
    }
}

// at the end of the tick, we find out where the sprites travelled to and then we insert the "move" activity to the SECOND index
// of each local activityReport list, so as not to precede a possible "spawn" activity and therefore have a re-play issue
-(void) sampleCurrentPositions:(ccTime)deltaTime
{
    // get the reports before incrementing _timeStepIndex
    
    // sample player
    [_player sampleCurrentPosition];
    
    // sample minions
    for (EntityNode *minion in _player.minions)
    {
        [minion sampleCurrentPosition];
    }

    // TODO sample the other entities
    
    self.roundTimer -= kReplayTickLengthSeconds;

    _timeStepIndex++;
    if((float)_timeStepIndex * kReplayTickLengthSeconds >= kTurnLengthSeconds)
    {
        [self roundFinished];
    }
}

-(void) enemyPlayback
{
//    _timeStepIndex = 0;
//    
//    // prelod sounds
//    // sound effects pre-load
//    [SimpleAudioEngine sharedEngine].effectsVolume = 1.0;
//    [SimpleAudioEngine sharedEngine].backgroundMusicVolume = 0.70;
//    
//    //        [[SimpleAudioEngine sharedEngine] preloadEffect:@"pickup.caf"];
//    [[SimpleAudioEngine sharedEngine] preloadEffect:@"DMLifePack.m4r"];
//    [[SimpleAudioEngine sharedEngine] preloadEffect:@"hit.caf"];
//    [[SimpleAudioEngine sharedEngine] preloadEffect:@"move.caf"];
//    [[SimpleAudioEngine sharedEngine] preloadEffect:@"missileSound.m4a"];
//    [[SimpleAudioEngine sharedEngine] preloadEffect:@"missileExplode.m4a"];
//    [[SimpleAudioEngine sharedEngine] preloadEffect:@"shurikenSound.m4a"];
//    [[SimpleAudioEngine sharedEngine] preloadEffect:@"DMPlayerDies.m4r"];  // preload creature sounds
//    //        [[SimpleAudioEngine sharedEngine] preloadEffect:@"juliaRoar.m4a"];  // preload creature sounds
//    [[SimpleAudioEngine sharedEngine] preloadEffect:@"DMZombie.m4r"];  // preload creature sounds
//    [[SimpleAudioEngine sharedEngine] preloadEffect:@"DMZombiePain.m4r"];  // preload creature sounds
//    
//    //        [[SimpleAudioEngine sharedEngine] preloadEffect:@"juliaRoar.m4a"];
//    //        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"TileMap.caf"];
//    //        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"montersoundtrack2.m4a"];
//    [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"DMMainTheme.m4r"];
//    
//    
//    // load the TileMap and the tile layers
//    self.tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"TileMap.tmx"];
//    self.background = [_tileMap layerNamed:@"Background"];
//    self.meta = [_tileMap layerNamed:@"Meta"];
//    self.foreground = [_tileMap layerNamed:@"Foreground"];
//    self.destruction = [_tileMap layerNamed:@"Destruction"];
//    _meta.visible = NO;
//
//    [self addChild:_tileMap z:-1];
//    
//    self.roundTimer = (float) kTurnLengthSeconds;
//    // schedule the playback loops
//    
//    [self schedule:@selector(enemyPlaybackLoop:) interval:kReplayTickLengthSeconds];
//    _isEnemyPlaybackRound = NO;
}

-(void) enemyPlaybackLoop:(ccTime)deltaTime
{
    // FIX for multiplayer, need a function to have previously filled all the local arrays with the needed goods
    // loop through the player and each player's minionsList, calling 
/*
    NSMutableArray *minionsToDelete = [[NSMutableArray alloc] init];
    for(Bat *theMinion in player.playerMinionList)
    {
        [theMinion performHistoryAtTimeStepIndex: _timeStepIndex];
        if(theMinion == nil)
            [targetsToDelete addObject:theMinion];
    }
    

    // if the minion was just killed, delete it from the player list
    for (Bat *theMinion in player.playerMinionList) {
        if(theMinion == nil)

        [[SimpleAudioEngine sharedEngine] playEffect:@"DMZombiePain.m4r"];
        // _numKills += 1; // only in case of oppononet's minions
        // [_hud numKillsChanged:_numKills];
        [player.playerMinionList removeObject:theMinion];
        }
    }
*/
    // normally would put opponent here, then player next
//    [opponent performHistory: atTimeStepIndex: _timeStepIndex]; // instantiate opponent in layer's init

    // sample player
//    [player performHistoryAtTimeStepIndex: atTimeStepIndex: _timeStepIndex];

//    _timeStepIndex++;
}

-(void) testCollisions:(ccTime) dt
{
    // First, see if lose condition is met locally
    // itterate over the enemies to see if any of them are in contact with player (dead)
    for (Bat *target in _player.minions) {
        CGRect targetRect = target.sprite.boundingBox; //CGRectMake(
        //           target.position.x - (target.contentSize.width/2),
        //           target.position.y - (target.contentSize.height/2),
        //           target.contentSize.width,
        //           target.contentSize.height );
        
        if (CGRectContainsPoint(targetRect, _player.sprite.position)) {
            [self lose];
        }
    }
    
    // shurikens hitting enemies?
    NSMutableArray* shurikensToDelete = [[NSMutableArray alloc] init];
    
    for (CCSprite *shuriken in _shurikens) {
        
        NSMutableArray *targetsToDelete = [[NSMutableArray alloc] init];
        
        // iterate through enemies, see if any intersect with current projectile
        for (Bat *target in _player.minions) {
            // enemy down!
            if(CGRectIntersectsRect(shuriken.boundingBox, target.sprite.boundingBox))
            {
                [target takeDamage:1];
                //                self.player.numKills += 1;
                //                [_hud numKillsChanged:_numKills];
                [targetsToDelete addObject:target];
                //                [[SimpleAudioEngine sharedEngine] playEffect:@"juliaRoar.m4a"];
            }
        }
        
        // delete all hit enemies
        for (Bat *target in targetsToDelete) {
            if(target.hitPoints < 1)
            {
                [[SimpleAudioEngine sharedEngine] playEffect:@"DMZombie.m4r"];
                
                [target kill];
                self.player.numKills += 1;
                //                [_hud numKillsChanged:_numKills];
                [self.player.minions removeObject:target];
                [self removeChild:target cleanup:YES];
            }
        }
        if (targetsToDelete.count > 0) {
            // add the projectile to the list of ones to remove
            [shurikensToDelete addObject:shuriken];
        }
    }
    
    // remove all the projectiles that hit.
    for (CCSprite *shuriken in shurikensToDelete) {
        [_shurikens removeObject:shuriken];
        [self removeChild:shuriken cleanup:YES];
    }
    // Finally, destroy all BACKGROUND layer tiles that were here
}

#pragma mark - Helpers
- (void) setViewpointCenter:(CGPoint) position
{
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    int x = MAX(position.x, winSize.width/2);
    int y = MAX(position.y, winSize.height/2);
    x = MIN(x, (_tileMap.mapSize.width * [self pixelToPointSize:_tileMap.tileSize].width) - winSize.width/2);
    y = MIN(y, (_tileMap.mapSize.height * [self pixelToPointSize:_tileMap.tileSize].height) - winSize.height/2);
    CGPoint actualPosition = ccp(x, y);
    
    CGPoint centerOfView = ccp(winSize.width/2, winSize.height/2);
    CGPoint viewPoint = ccpSub(centerOfView, actualPosition);
    self.position = viewPoint;
}

-(void) setPlayerPosition:(CGPoint) position
{
    CGPoint tileCoord = [self tileCoordForPosition:position];
    int tileGid = [_meta tileGIDAt:tileCoord];  // GID is the ID for this kind of tile
    if(tileGid)
    {
        NSDictionary* properties = [_tileMap propertiesForGID:tileGid];
        //
        if(properties)
        {
            // IS this tile a "collidable" tile?
            // if the target move tile is collidable, then simply return and don't set player position to the target
            NSString* collision = [properties valueForKey:@"Collidable"];
            if(collision && [collision compare:@"True"] == NSOrderedSame)
            {
                // ran into a wall sound
                [[SimpleAudioEngine sharedEngine] playEffect:@"hit.caf"];
                return;
            }
            // IS this tile a "collectable" tile?
            NSString *collectable = [properties valueForKey:@"Collectable"];
            if (collectable && [collectable compare:@"True"] == NSOrderedSame)
            {
                // got the item sound
                [[SimpleAudioEngine sharedEngine] playEffect:@"DMLifePack.m4r"];
                // removing from both meta layer AND foreground means we can no longer see OR "collect" the item
                [_meta removeTileAt:tileCoord];
                [_foreground removeTileAt:tileCoord];
                
                self.player.numMelons++;
                //                [_hud numCollectedChanged:_numCollected];
                
                // check win condition then end game if win
                // put the number of melons on your map in place of the '2'
                if (self.player.numMelons == kMaxMelons)
                    [self win];
            }
        }
    }
    
    self.player.sprite.position = position;
}

// there are iOS coordinates coresponding to the pixels starting with 0,0 at BOTTOM left corner...
// then there are tile index coordinates starting from 0,0 at TOP left corner
// we will need the tile coordinate for some purposes:
-(CGPoint) tileCoordForPosition:(CGPoint) position
{
    int x = position.x / [self pixelToPointSize:_tileMap.tileSize].width;
    // gotta flip in y-direction
    int y = ((_tileMap.mapSize.height * [self pixelToPointSize:_tileMap.tileSize].height) - position.y) / [self pixelToPointSize:_tileMap.tileSize].height;
    return ccp(x,y);
}

-(CGPoint) pixelToPoint:(CGPoint) pixelPoint{
    return ccpMult(pixelPoint, 1/CC_CONTENT_SCALE_FACTOR());
}

-(CGSize) pixelToPointSize:(CGSize) pixelSize{
    return CGSizeMake((pixelSize.width / CC_CONTENT_SCALE_FACTOR()), (pixelSize.height / CC_CONTENT_SCALE_FACTOR()));
}

#pragma mark - Touch Handling
// registering ourself as the as the listener for touch events, meaning ccTouchBegan and ccTouchEnded will be called back
-(void) registerWithTouchDispatcher
{
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
    //depricated call: [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    return YES;
}

 - (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    _isSwipe = YES;
    
    // otherwise, test for can test for another kind of move gesture

//    UITouch *touch = [touches anyObject];
//    CGPoint new_location = [touch locationInView: [touch view]];
//    new_location = [[CCDirector sharedDirector] convertToGL:new_location];
    
//    CGPoint oldTouchLocation = [touch previousLocationInView:touch.view];
//    oldTouchLocation = [[CCDirector sharedDirector] convertToGL:oldTouchLocation];
//    oldTouchLocation = [self convertToNodeSpace:oldTouchLocation];
    
    // add my touches to the naughty touch array
//    [myToucharray addObject:NSStringFromCGPoint(new_location)];
//    [myToucharray addObject:NSStringFromCGPoint(oldTouchLocation)];
    
 
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (_roundHasStarted != YES)
        return;
    
    if((_isSwipe == YES) && (self.player.numMissiles > 0))
    {
        DLog(@"GOT MISSILES");
        
        _isSwipe = NO; // finger swipe bool for touchesMoved callback
     
        CGPoint touchLocation = [touch locationInView: [touch view]];
        touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];
//        isSwipe = NO; // finger swipe bool for touchesMoved callback

        // Create a missile and put it at the player's location
        CCSprite* missile = [CCSprite spriteWithFile:@"missile.png"];
        // draw a line between player and last touch
        
        missile.position = _player.sprite.position;
        [self addChild:missile];
        
        // send it on a line from player position to new_location
        
        
        // Determine where we want to shoot the projectile to
        int realX, realY;

        // Are we shooting to the left or right?
        CGPoint diff = ccpSub(touchLocation, _player.sprite.position);
        realX = missile.position.x + diff.x;
        realY = missile.position.y + diff.y;
/*
        if(diff.x > 0)
            realX = (_tileMap.mapSize.width * [self pixelToPointSize:_tileMap.tileSize].width) + (missile.contentSize.width/2);
        else
            realX = -(_tileMap.mapSize.width * [self pixelToPointSize:_tileMap.tileSize].width) - (missile.contentSize.width/2);
*/
//        float ratio = (float) diff.y / (float) diff.x;
//        realY = ((realX - missile.position.x) * ratio) + missile.position.y;
        CGPoint realDest = ccp(realX, realY);
        
        // Determine the length of how far we're shooting
        int offRealX = realX - missile.position.x;
        int offRealY = realY - missile.position.y;
        float length = sqrtf((offRealX*offRealX) + (offRealY*offRealY));
        float velocity = 240/1; // 480pixels/1sec
        float realMoveDuration = length/velocity;
        
        // Determine angle for the missile to face
        // basic trig stuff using touch info a character position calculations from above
        float angleRadians = atanf((float)offRealY / (float)offRealX);
        float angleDegrees = CC_RADIANS_TO_DEGREES(angleRadians);
        float cocosAngle = -1 * angleDegrees - 90;
        if(touchLocation.x > missile.position.x)
            cocosAngle += 180;
//        [missile setRotation:cocosAngle];
        missile.rotation = cocosAngle;
            
            
        // Move projectile to the last touch position
        id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(missileMoveFinished:)];
        [missile runAction:[CCSequence actionOne:
                            [CCMoveTo actionWithDuration:realMoveDuration position:realDest]
                                                 two:actionMoveDone]];
        [[SimpleAudioEngine sharedEngine] playEffect:@"missileSound.m4a"];
        // we need to keep a reference to each shuriken so we can delete it if it makes a collision with a target
        [_missiles addObject:missile];
        self.player.numMissiles--;
//        [_hud numMissilesChanged:_numMissiles];
    }
    else if(_player.mode == DVPlayerMode_Moving)
    {
        CGPoint touchLocation = [touch locationInView: [touch view]];
        touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];
        // calling convertToNodeSpace method offsets the touch based on how we have moved the layer
        // for example, This is because the touch location will give us coordinates for where the user tapped inside the viewport (for example 100,100). But we might have scrolled the map a good bit so that it actually matches up to (800,800) for example.
        
        //CGSize tileSize = [self pixelToPointSize:tileMap.tileSize];
        
        // this just moves sprite by the one tile of pixels
        CGPoint playerPos = _player.sprite.position;
        CGPoint diff = ccpSub(touchLocation, playerPos);
        if (abs(diff.x) > abs(diff.y)) {
            if (diff.x > 0) {
                playerPos.x += [self pixelToPointSize:_tileMap.tileSize].width;
                //playerPos.x += _tileMap.tileSize.width;
            } else {
                playerPos.x -= [self pixelToPointSize:_tileMap.tileSize].width;
            }
        } else {
            if (diff.y > 0) {
                playerPos.y += [self pixelToPointSize:_tileMap.tileSize].height;
            } else {
                playerPos.y -= [self pixelToPointSize:_tileMap.tileSize].height;
            }
        }
        
        if (playerPos.x <= (_tileMap.mapSize.width * [self pixelToPointSize:_tileMap.tileSize].width) &&
            playerPos.y <= (_tileMap.mapSize.height * [self pixelToPointSize:_tileMap.tileSize].height) &&
            playerPos.y >= 0 &&
            playerPos.x >= 0 )
        {
            // moved the player sound
            [[SimpleAudioEngine sharedEngine] playEffect:@"move.caf"];
            [self setPlayerPosition:playerPos];
        }
        
        [self setViewpointCenter:_player.sprite.position];
    }
    // else if throw shuriken mode
    else if (_player.mode == DVPlayerMode_Shooting && self.player.numShurikens > 0) {
        // Find where the touch point is
        CGPoint touchLocation = [touch locationInView:[touch view]];
        touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];
        
        // Create a projectile and put it at the player's location
        CCSprite* shuriken = [CCSprite spriteWithFile:@"Projectile.png"];
        shuriken.position = _player.sprite.position;
        [self addChild:shuriken];
        
        // Determine where we want to shoot the projectile to
        int realX;
        
        // Are we shooting to the left or right?
        CGPoint diff = ccpSub(touchLocation, _player.sprite.position);
        if(diff.x > 0)
            realX = (_tileMap.mapSize.width * [self pixelToPointSize:_tileMap.tileSize].width) + (shuriken.contentSize.width/2);
        else
            realX = -(_tileMap.mapSize.width * [self pixelToPointSize:_tileMap.tileSize].width) - (shuriken.contentSize.width/2);
        
        float ratio = (float) diff.y / (float) diff.x;
        int realY = ((realX - shuriken.position.x) * ratio) + shuriken.position.y;
        CGPoint realDest = ccp(realX, realY);
        
        // Determine the length of how far we're shooting
        int offRealX = realX - shuriken.position.x;
        int offRealY = realY - shuriken.position.y;
        float length = sqrtf((offRealX*offRealX) + (offRealY*offRealY));
        float velocity = 480/1; // 480pixels/1sec
        float realMoveDuration = length/velocity;
        
        // Move projectile to actual endpoint
        id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(shurikenMoveFinished:)];
        [shuriken runAction:[CCSequence actionOne:
                             [CCMoveTo actionWithDuration:realMoveDuration position:realDest]
                                              two:actionMoveDone]];
        [[SimpleAudioEngine sharedEngine] playEffect:@"shurikenSound.m4a"];
        // we need to keep a reference to each shuriken so we can delete it if it makes a collision with a target
        [_shurikens addObject:shuriken];

        self.player.numShurikens--;
    }
}


/*
-(void) addEnemyAtX:(int)x y:(int)y
{
    CCSprite* enemy = [CCSprite spriteWithFile:@"bat.png"];
    enemy.position = ccp(x, y);
    [self addChild:enemy];
    
    // Use our animation method and start the enemy moving toward the player
    [self animateEnemy:enemy];
    [_enemies addObject:enemy];
}
*/

-(void) animateEnemy:(CCSprite*) enemy
{
    //immediately before creating the actions in animateEnemy
    //rotate to face the player
    CGPoint diff = ccpSub(_player.sprite.position, enemy.position);
    float angleRadians = atanf((float)diff.y / (float)diff.x);
    float angleDegrees = CC_RADIANS_TO_DEGREES(angleRadians);
    float cocosAngle = -1 * angleDegrees;
    if(diff.x < 0)
        cocosAngle += 180;
    enemy.rotation = cocosAngle;
    
    // 10 pixels per 0.3 seconds -> speed = 33 pixels / second
    // speed of the enemy
    ccTime actualDuration = 0.3;
    
    // create the actions
    // ccpMult, ccpSub multiplies, subtracts two point coordinates (vectors) to give one resulting point
    // ccpNormalize calculates a unit vector given 2 point coordinates,...
    // and gives a hypotenous of length 1 with appropriate x,y
    id actionMove = [CCMoveBy actionWithDuration:actualDuration position:ccpMult(ccpNormalize(ccpSub(_player.sprite.position,enemy.position)), 10)];
    id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(enemyMoveFinished:)];
    [enemy runAction:[CCSequence actions:actionMove, actionMoveDone, nil]];
}

// callback that starts another iteration of enemy movement.
// we know which sprite called us here because sender is a CCSprite - the sprite that just finished animating
-(void) enemyMoveFinished:(id)sender
{
    CCSprite* enemy = (CCSprite*) sender;
    
    [self animateEnemy: enemy];
}

-(void) shurikenMoveFinished:(id) sender
{
    CCSprite* sprite = (CCSprite*) sender;
    [self removeChild:sprite cleanup:YES];
    
    [_shurikens removeObject:sprite];  // remove our reference to this shuriken from the projectiles array of sprite objects
}

-(void) missileMoveFinished:(id) sender
{
    CCSprite* sprite = (CCSprite*) sender;
    [self missileExplodes:sprite.position];
    [self removeChild:sprite cleanup:YES];

    [_missiles removeObject:sprite];  // remove our reference to this shuriken from the projectiles array of sprite objects

}

-(void) missileExplodes:(CGPoint) hitLocation
{
    [[SimpleAudioEngine sharedEngine] playEffect:@"missileExplode.m4a"];

    // explode, killing anything in 4 box radius
    CCSprite* explosion = [CCSprite spriteWithFile:@"nuked.png"];
    explosion.position = hitLocation;
    [self addChild:explosion];
 
    // Move projectile to actual endpoint
    id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(shurikenMoveFinished:)];

//    [explosion runAction:CC]
    id scaleUpAction =  [CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:1 scaleX:2.0 scaleY:2.5] rate:2.0];
    [explosion runAction:[CCSequence actionOne:scaleUpAction two:actionMoveDone]];

    // make a rectangle that is 2*2 tiles wide, kill everything collided with it (including destructable tiles from tilemap)
    // anything within 2 * the explosion images bounding box gets killed (explosion will expand to 2 times size)
    CGRect explosionArea = CGRectMake(explosion.position.x - (explosion.contentSize.width/2)*2, explosion.position.y - (explosion.contentSize.height/2)*2, explosion.contentSize.width*2, explosion.contentSize.height*2);

    // First, if the explosion hit YOU then you're dead
    if(CGRectIntersectsRect(explosionArea, _player.sprite.boundingBox))
    {
        [self lose];
        // [self schedule:@selector(lose) interval:0.75];
    }

    
    // iterate through enemies, see if any intersect with current projectile
    NSMutableArray *targetsToDelete = [[NSMutableArray alloc] init];
    for (Bat *target in _player.minions) {
        // enemy down!
        if(CGRectIntersectsRect(explosionArea, target.sprite.boundingBox))
        {
            [target takeDamage:2];
//            self.player.numKills += 1;
//            [_hud numKillsChanged:_numKills];
            [targetsToDelete addObject:target];
//            [[SimpleAudioEngine sharedEngine] playEffect:@"juliaRoar.m4a"];
        }
    }
    
    // delete all hit enemies
    for (Bat *target in targetsToDelete) {
        if(target.hitPoints < 1)
        {
            [[SimpleAudioEngine sharedEngine] playEffect:@"DMZombiePain.m4r"];
            [target kill];
            self.player.numKills += 1;
//            [_hud numKillsChanged:_numKills];
            [_player.minions removeObject:target];
            // [self removeChild:target cleanup:YES];
        }
    }
    
    // Finally, detroy any background layer tiles that were here, scorched earth! Everything anhialated!

    CGPoint bottomLeft = CGPointMake(explosionArea.origin.x + explosionArea.size.width * 0.26, explosionArea.origin.y + explosionArea.size.height * 0.26);
    CGPoint bottomRight = CGPointMake(explosionArea.origin.x + explosionArea.size.width * 0.74, explosionArea.origin.y + explosionArea.size.height * 0.26);
    CGPoint topLeft = CGPointMake(explosionArea.origin.x + explosionArea.size.width * 0.26, explosionArea.origin.y + explosionArea.size.height * 0.74);
    CGPoint topRight = CGPointMake(explosionArea.origin.x + explosionArea.size.width * 0.74, explosionArea.origin.y + explosionArea.size.height * 0.74);

    [_background removeTileAt:[self tileCoordForPosition:bottomLeft]];
    [_background removeTileAt:[self tileCoordForPosition:bottomRight]];
    [_background removeTileAt:[self tileCoordForPosition:topLeft]];
    [_background removeTileAt:[self tileCoordForPosition:topRight]];
    
    [_foreground removeTileAt:[self tileCoordForPosition:bottomLeft]];
    [_foreground removeTileAt:[self tileCoordForPosition:bottomRight]];
    [_foreground removeTileAt:[self tileCoordForPosition:topLeft]];
    [_foreground removeTileAt:[self tileCoordForPosition:topRight]];

    [_meta removeTileAt:[self tileCoordForPosition:bottomLeft]];
    [_meta removeTileAt:[self tileCoordForPosition:bottomRight]];
    [_meta removeTileAt:[self tileCoordForPosition:topLeft]];
    [_meta removeTileAt:[self tileCoordForPosition:topRight]];
}

// this might not be necessary since children of our node are cleaned up after the node deallocates itself
-(void) missileExplodesFinished:(id) sender
{
    CCSprite* sprite = (CCSprite*) sender;
    [self removeChild:sprite cleanup:YES];

}

// on "dealloc" you need to release all your retained objects

#pragma mark GameKit delegate

-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}
@end
