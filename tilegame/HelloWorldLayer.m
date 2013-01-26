//
//  HelloWorldLayer.m
//  tutorial_TileGame
//
//  Created by Jeremiah Anderson on 12/10/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//
// SEE: http://www.raywenderlich.com/1163/how-to-make-a-tile-based-game-with-cocos2d

// Import the interfaces
#import "HelloWorldLayer.h"

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

#import "Libs/SBJSON/SBJson.h"

#pragma mark - HelloWorldLayer

//static HelloWorldLayer* theHelloWorldLayer;

// HelloWorldLayer implementation
@implementation HelloWorldLayer

@synthesize tileMap = _tileMap;
@synthesize background = _background;
@synthesize meta = _meta;
@synthesize foreground = _foreground;
@synthesize destruction = _destruction;
@synthesize numCollected = _numCollected;
@synthesize numKills = _numKills;
@synthesize numShurikens = _numShurikens;
@synthesize numMissiles = _numMissiles;
@synthesize hud = _hud;
@synthesize mode = _mode;
@synthesize timeStepIndex = _timeStepIndex;
@synthesize playerMinionList = _playerMinionList;
@synthesize player;
@synthesize timer;

//@synthesize bats = _bats;
//@synthesize isTouchMoveStarted, isTouchEnabled;
/*
+(HelloWorldLayer*) helloWorldLayerGetter
{
    return theHelloWorldLayer;
}
*/

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
// What calls this class??
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *theScene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	[theScene addChild: layer];
//    [theScene addChild: theHelloWorldLayer];
    
    // create and add the HUD label/stats layer!
    CoreGameHudLayer* hud = [CoreGameHudLayer node];
    [theScene addChild:hud];
    
    [theScene addChild:[CountdownLayer node]];
    
    layer.hud = hud;  // store a member var reference to the hud so we can refer back to it to reset the label strings!
    hud.gameLayer = layer;  // 2-way references
	
	// return the scene
	return theScene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super's" return value
	if( (self=[super init]) ) {
        
        self->apiWrapper = [[DVAPIWrapper alloc] init];
<<<<<<< Updated upstream

=======
        
        SBJsonWriter* jwriter = [[SBJsonWriter alloc] init];
        
        NSMutableArray* array = [[NSMutableArray alloc] initWithObjects:[NSDate date],
                                 nil];

        NSString* updatesAsJSON = [jwriter stringWithObject:[NSArray arrayWithArray:array]];
        
        NSArray* newArray = [updatesAsJSON JSONValue];
        int exy = 1;
        
>>>>>>> Stashed changes
        // test create new game
        //        [self->apiWrapper postCreateNewGameThenCallBlock:^(NSError *error, DVGameStatus *status) {
        //            if (error != nil) {
        //                ULog([error localizedDescription]);
        //            }
        //            else {
        //                [[NSUserDefaults standardUserDefaults] setObject:[status gameID] forKey:kCurrentGameIDKey];
        //                DLog(@"CREATED NEW GAME, saved GameID '%@'to NSUserDefaults", [status gameID]);
        //            }
        //        }];
        
        // test getting current game's status
        //        [self->apiWrapper getGameStatusThenCallBlock:^(NSError *error, DVGameStatus *status) {
        //            if (error != nil) {
        //                ULog([error localizedDescription]);
        //            }
        //            else {
        //                DLog(@"GOT GAME STATUS");
        //            }
        //        }];
        
        // test sending game update
        //        NSDictionary* updates = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:5], @"melonsEaten", [NSNumber numberWithInt:2], @"enemiesKilled", [NSNumber numberWithInt:6], @"starsThrown", @"false", kIsGameOver, nil];
        //        [self->apiWrapper postUpdateGameWithUpdates:updates ThenCallBlock:^(NSError* error) {
        //            if (error != nil) {
        //                ULog([error localizedDescription]);
        //            }
        //            else {
        //                DLog(@"UPDATED GAME GAME STATUS");
        //            }
        //        }];
                
        _timeStepIndex = 0;
        self.isTouchEnabled = YES;  // set THIS LAYER as touch enabled so user can move character around with callbacks
		isSwipe = NO;
        myToucharray =[[NSMutableArray alloc ] init]; // store the touches for missile launching
        
        _numShurikens = kInitShurikens;
        _numMissiles = kInitMissiles;
        _mode = 0;  // default game mode = 0, move mode (mode = 1, shoot mode)
        
//        _enemies = [[NSMutableArray alloc] init];
        _bats = [[NSMutableArray alloc] init];
        _projectiles = [[NSMutableArray alloc] init];
        _missiles = [[NSMutableArray alloc] init];
        [self schedule:@selector(testCollisions:)];
        
        // sound effects pre-load
        [SimpleAudioEngine sharedEngine].effectsVolume = 1.0;
        [SimpleAudioEngine sharedEngine].backgroundMusicVolume = 0.70;
        
//        [[SimpleAudioEngine sharedEngine] preloadEffect:@"pickup.caf"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"DMLifePack.m4r"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"hit.caf"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"move.caf"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"missileSound.m4a"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"missileExplode.m4a"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"shurikenSound.m4a"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"DMPlayerDies.m4r"];  // preload creature sounds
//        [[SimpleAudioEngine sharedEngine] preloadEffect:@"juliaRoar.m4a"];  // preload creature sounds
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"DMZombie.m4r"];  // preload creature sounds
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"DMZombiePain.m4r"];  // preload creature sounds
        
//        [[SimpleAudioEngine sharedEngine] preloadEffect:@"juliaRoar.m4a"];
//        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"TileMap.caf"];
//        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"montersoundtrack2.m4a"];
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"DMMainTheme.m4r"];

        // load the TileMap and the tile layers
        self.tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"TileMap.tmx"];
        self.background = [_tileMap layerNamed:@"Background"];
        self.meta = [_tileMap layerNamed:@"Meta"];
        self.foreground = [_tileMap layerNamed:@"Foreground"];
        self.destruction = [_tileMap layerNamed:@"Destruction"];
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

        // IF we are the host, playerID gets P1; if we were invited to a game, we get P2
        player = [[Player alloc] initWithLayer:self andPlayerID:@"P1" andSpawnAt:playerSpawnPoint];
        
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

                Bat *aBat = [[Bat alloc] initWithLayer:self
                                            andSpawnAt:enemySpawnPoint
                                          withBehavior:kBehavior_default
                                       withPlayerOwner:[NSMutableString stringWithString:player.playerID]];
                // add the bat to the bats NSMuttableArray
                [_bats addObject:aBat];
                //[self addChild:aBat];
            }
        }

        // set the view position focused on player

        [self setViewpointCenter:player.sprite.position];
        
        [self addChild:_tileMap z:-1];

        timer = (float) kTurnLengthSeconds;
        // start up the main game loops
        [self schedule:@selector(mainGameLoop:) interval:kTickLengthSeconds];
        [self schedule:@selector(sampleCurrentPositions:) interval:kPlaybackTickLengthSeconds];
                
        /*
        // DEBUG section
        // test CCSequence helper category
        CCSprite* missile = [CCSprite spriteWithFile:@"missile.png"];
        id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(missileMoveFinished:)];
        missile.position = _player.position;
        [self addChild:missile];
        
        // iphone coords is 320 x 480
        id actionMove1 = [CCMoveTo actionWithDuration:4.0 position:ccp(1, 1)];
        id actionMove2 = [CCMoveTo actionWithDuration:1.0 position:ccp(319, 479)];
        id actionMove3 = [CCMoveTo actionWithDuration:1.0 position:ccp(100, 100)];
        id actionMove4 = [CCMoveTo actionWithDuration:4.0 position:_player.position];
        NSMutableArray* actionArray = [[NSMutableArray alloc] initWithCapacity:1];
        [actionArray addObject:actionMove1];
        [actionArray addObject:actionMove2];
        [actionArray addObject:actionMove3];
        [actionArray addObject:actionMove4];
        [actionArray addObject:actionMoveDone];
        CCSequence *seq = [CCSequence actionMutableArray: actionArray];
        
        [missile runAction:seq];
        // COOL! end DEBUG
        */
        
        
    }
	return self;
}

-(void) mainGameLoop:(ccTime)deltaTime
{
    // update the minions
    for (Bat *theMinion in _bats) {
        [theMinion realUpdate];
    }
   
}

// at the end of the tick, we find out where the sprites travelled to and then we insert the "move" activity to the SECOND index
// of each local activityReport list, so as not to precede a possible "spawn" activity and therefore have a re-play issue
-(void) sampleCurrentPositions:(ccTime)deltaTime
{
    // get the reports before incrementing _timeStepIndex
    // player position report
    
    // sample minions
    for (Bat *theMinion in _bats) {
        [theMinion sampleCurrentPosition];
    }
    
    // sample player
    [player sampleCurrentPosition];
    
    timer -= kPlaybackTickLengthSeconds;
    // update the label every second
    if((int)timer % 1 == 0)  // FIX cheating by hardcoding for now, fix this to allow time periods to change just in constants
        [_hud timerChanged:timer];
    
    _timeStepIndex++;
    if((float)_timeStepIndex * kPlaybackTickLengthSeconds >= kTurnLengthSeconds)
    {
        [self roundFinished];
    }
}

-(void) roundFinished
{
    // unschedule the loops and everything (collision detection, etc)
    // [self unscheduleAllSelectors];
    
    // DEBUG
    // now try re-playing all the historical activities from the list
    
    
    
    // transition to a waiting for opponent scene, ideally displaying current stats (maybe keep HUD up)
    GameOverScene *gameOverScene = [GameOverScene node];
    [gameOverScene.layer.label setString:@"Round Finished!"];
    [[CCDirector sharedDirector] replaceScene:gameOverScene];
}


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

                self.numCollected++;
                [_hud numCollectedChanged:_numCollected];
                
                // check win condition then end game if win
                // put the number of melons on your map in place of the '2'
                if (_numCollected == kMaxMelons)
                    [self win];
            }
        }
    }
    
    player.sprite.position = position;
}

- (void) win {
    GameOverScene *gameOverScene = [GameOverScene node];
    [gameOverScene.layer.label setString:@"You Win!"];
    [[CCDirector sharedDirector] replaceScene:gameOverScene];
}


 - (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    isSwipe = YES;
    
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
    // if move mode
    
    if((isSwipe == YES) && (_numMissiles > 0))
    {
        DLog(@"GOT MISSILES");
        
        isSwipe = NO; // finger swipe bool for touchesMoved callback
     
        CGPoint touchLocation = [touch locationInView: [touch view]];
        touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];
//        isSwipe = NO; // finger swipe bool for touchesMoved callback

        // Create a missile and put it at the player's location
        CCSprite* missile = [CCSprite spriteWithFile:@"missile.png"];
        // draw a line between player and last touch
        
        missile.position = player.sprite.position;
        [self addChild:missile];
        
        // send it on a line from player position to new_location
        
        
        // Determine where we want to shoot the projectile to
        int realX, realY;

        // Are we shooting to the left or right?
        CGPoint diff = ccpSub(touchLocation, player.sprite.position);
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
        self.numMissiles--;
        [_hud numMissilesChanged:_numMissiles];
    }
    else if(_mode == 0)
    {
        CGPoint touchLocation = [touch locationInView: [touch view]];
        touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];
        // calling convertToNodeSpace method offsets the touch based on how we have moved the layer
        // for example, This is because the touch location will give us coordinates for where the user tapped inside the viewport (for example 100,100). But we might have scrolled the map a good bit so that it actually matches up to (800,800) for example.
        
        //CGSize tileSize = [self pixelToPointSize:tileMap.tileSize];
        
        // this just moves sprite by the one tile of pixels
        CGPoint playerPos = player.sprite.position;
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
        
        [self setViewpointCenter:player.sprite.position];
    }
    // else if throw shuriken mode
    else if (self.numShurikens > 0) {
        // Find where the touch point is
        CGPoint touchLocation = [touch locationInView:[touch view]];
        touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];
        
        // Create a projectile and put it at the player's location
        CCSprite* projectile = [CCSprite spriteWithFile:@"Projectile.png"];
        projectile.position = player.sprite.position;
        [self addChild:projectile];
        
        // Determine where we want to shoot the projectile to
        int realX;
        
        // Are we shooting to the left or right?
        CGPoint diff = ccpSub(touchLocation, player.sprite.position);
        if(diff.x > 0)
            realX = (_tileMap.mapSize.width * [self pixelToPointSize:_tileMap.tileSize].width) + (projectile.contentSize.width/2);
        else
            realX = -(_tileMap.mapSize.width * [self pixelToPointSize:_tileMap.tileSize].width) - (projectile.contentSize.width/2);
        
        float ratio = (float) diff.y / (float) diff.x;
        int realY = ((realX - projectile.position.x) * ratio) + projectile.position.y;
        CGPoint realDest = ccp(realX, realY);
        
        // Determine the length of how far we're shooting
        int offRealX = realX - projectile.position.x;
        int offRealY = realY - projectile.position.y;
        float length = sqrtf((offRealX*offRealX) + (offRealY*offRealY));
        float velocity = 480/1; // 480pixels/1sec
        float realMoveDuration = length/velocity;
        
        // Move projectile to actual endpoint
        id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(projectileMoveFinished:)];
        [projectile runAction:[CCSequence actionOne:
                               [CCMoveTo actionWithDuration:realMoveDuration position:realDest]
                                                two:actionMoveDone]];
        [[SimpleAudioEngine sharedEngine] playEffect:@"shurikenSound.m4a"];
        // we need to keep a reference to each shuriken so we can delete it if it makes a collision with a target
        [_projectiles addObject:projectile];
        self.numShurikens--;
        [_hud numShurikensChanged:_numShurikens];

    }
    
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
    CGPoint diff = ccpSub(player.sprite.position, enemy.position);
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
    id actionMove = [CCMoveBy actionWithDuration:actualDuration position:ccpMult(ccpNormalize(ccpSub(player.sprite.position,enemy.position)), 10)];
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

-(void) projectileMoveFinished:(id) sender
{
    CCSprite* sprite = (CCSprite*) sender;
    [self removeChild:sprite cleanup:YES];
    
    [_projectiles removeObject:sprite];  // remove our reference to this shuriken from the projectiles array of sprite objects
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
    id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(projectileMoveFinished:)];

//    [explosion runAction:CC]
    id scaleUpAction =  [CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:1 scaleX:2.0 scaleY:2.5] rate:2.0];
    [explosion runAction:[CCSequence actionOne:scaleUpAction two:actionMoveDone]];

    // make a rectangle that is 2*2 tiles wide, kill everything collided with it (including destructable tiles from tilemap)
    // anything within 2 * the explosion images bounding box gets killed (explosion will expand to 2 times size)
    CGRect explosionArea = CGRectMake(explosion.position.x - (explosion.contentSize.width/2)*2, explosion.position.y - (explosion.contentSize.height/2)*2, explosion.contentSize.width*2, explosion.contentSize.height*2);

    // First, if the explosion hit YOU then you're dead
    if(CGRectIntersectsRect(explosionArea, player.sprite.boundingBox))
    {
        [self lose];
        // [self schedule:@selector(lose) interval:0.75];
    }

    
    // iterate through enemies, see if any intersect with current projectile
    NSMutableArray *targetsToDelete = [[NSMutableArray alloc] init];
    for (Bat *target in _bats) {
        // enemy down!
        if(CGRectIntersectsRect(explosionArea, target.sprite.boundingBox))
        {
            [target wound:2];
//            self.numKills += 1;
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
            _numKills += 1;
            [_hud numKillsChanged:_numKills];
            [_bats removeObject:target];
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

-(void) testCollisions:(ccTime) dt
{
    // First, see if lose condition is met locally
    // itterate over the enemies to see if any of them are in contact with player (dead)
    for (Bat *target in _bats) {
        CGRect targetRect = target.sprite.boundingBox; //CGRectMake(
                            //           target.position.x - (target.contentSize.width/2),
                            //           target.position.y - (target.contentSize.height/2),
                            //           target.contentSize.width,
                            //           target.contentSize.height );
        
        if (CGRectContainsPoint(targetRect, player.sprite.position)) {
            [self lose];
        }
    }
    
    // shurikens hitting enemies?
    NSMutableArray* projectilesToDelete = [[NSMutableArray alloc] init];
    
    for (CCSprite *projectile in _projectiles) {
        
        NSMutableArray *targetsToDelete = [[NSMutableArray alloc] init];
        
        // iterate through enemies, see if any intersect with current projectile
        for (Bat *target in _bats) {
            // enemy down!
            if(CGRectIntersectsRect(projectile.boundingBox, target.sprite.boundingBox))
            {
                [target wound:1];
//                self.numKills += 1;
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
                _numKills += 1;
                [_hud numKillsChanged:_numKills];
                [_bats removeObject:target];
                [self removeChild:target cleanup:YES];
            }
        }        
        if (targetsToDelete.count > 0) {
            // add the projectile to the list of ones to remove
            [projectilesToDelete addObject:projectile];
        }
    }
    
    // remove all the projectiles that hit.
    for (CCSprite *projectile in projectilesToDelete) {
        [_projectiles removeObject:projectile];
        [self removeChild:projectile cleanup:YES];
    }
    
    // Finally, destroy all BACKGROUND layer tiles that were here

}

- (void) lose {
    // delete the player, re-init and re-spawn him back at the beginning,
    // then idle him there until turn is finished (no moving or attacking allowed)

    [player wound:2];
    [player kill];

    [self scheduleOnce:@selector(roundFinished) delay:3.0];

//    GameOverScene *gameOverScene = [GameOverScene node];
//    [gameOverScene.layer.label setString:@"You Lose!"];
//    [[CCDirector sharedDirector] replaceScene:gameOverScene];
}

// NEW
-(CGPoint) pixelToPoint:(CGPoint) pixelPoint{
    return ccpMult(pixelPoint, 1/CC_CONTENT_SCALE_FACTOR());
}
-(CGSize) pixelToPointSize:(CGSize) pixelSize{
    return CGSizeMake((pixelSize.width / CC_CONTENT_SCALE_FACTOR()), (pixelSize.height / CC_CONTENT_SCALE_FACTOR()));
}
// END

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
