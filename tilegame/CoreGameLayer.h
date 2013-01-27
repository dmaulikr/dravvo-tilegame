//
//  HelloWorldLayer.h
//  tutorial_TileGame
//
//  Created by Jeremiah Anderson on 12/10/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//
// SEE: http://www.raywenderlich.com/1163/how-to-make-a-tile-based-game-with-cocos2d
// Note: 2 class declarations in this file


#import <GameKit/GameKit.h>
#import "cocos2d.h" // When you import this file, you import all the cocos2d classes
#import "DVAPIWrapper.h"
//#import "Entity.h"
#import "Bat.h"
#import "Player.h"
//#import "Opponent.h"
#import "CoreGameHudLayer.h"

// maybe not needed
typedef enum {
    DVPlayerMode_Moving,
    DVPlayerMode_Shooting,
} DVPlayerMode;

@class CoreGameHudLayer;
@class Player;

// HelloWorldLayer
@interface CoreGameLayer : CCLayer <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate>
{
    CCTMXTiledMap* _tileMap;
    // these layers are part of the _tileMap
    CCTMXLayer* _background;  // background layer is the constant background layer (walls, roads, bushes, etc)
    CCTMXLayer* _meta;  // meta layer is NOT seen by player, just used to specify collidable, collectible tiles
    CCTMXLayer* _foreground;  // foreground layer is seen by player but is modifiable, like collectible items
    CCTMXLayer* _destruction;  // destruction under-layer, for when terrain is devastated
//    CCSprite* _player;
//    NSMutableArray* _enemies;
    NSMutableArray* _projectiles;
    NSMutableArray* _missiles;
//    NSMutableArray* _bats;
    NSMutableArray* _actionRecordDictionaries;
    NSMutableArray* _playerMinionList;
    
    int _numKills;
    int _numCollected;
    CoreGameHudLayer* _hud; // keep a pointer to the HUD labels/stats layer
    int _mode;  // game mode variable - shooting or moving
    int _numShurikens;
    int _numMissiles;
    BOOL isSwipe;
    BOOL isTouchMoveStarted;
    NSMutableArray* myToucharray;
    int _timeStepIndex; // should count up to 10 or 20, to get to a 10 second round
    Player* player;
//    Opponent* opponent;
    
    DVAPIWrapper* _apiWrapper;
}

@property (nonatomic, strong) CCTMXTiledMap* tileMap;
@property (nonatomic, strong) CCTMXLayer* background;
@property (nonatomic, strong) CCTMXLayer* meta;
@property (nonatomic, strong) CCTMXLayer* foreground;
@property (nonatomic, strong) CCTMXLayer* destruction;
//@property (nonatomic, strong) CCSprite* player;

// change const if you ever rename this because they are used in KVO
@property (nonatomic, assign) int numCollected;
#define kDVNumMelonsKVO @"numCollected"
@property (nonatomic, assign) int numKills;
#define kDVNumKillsKVO @"numKills"
@property (nonatomic, assign) int numShurikens;
#define kDVNumShurikensKVO @"numShurikens"
@property (nonatomic, assign) int numMissiles;
#define kDVNumMisslesKVO @"numMissiles"
@property (nonatomic, assign) float timer;
#define kDVNumTimerKVO @"timer"

@property (nonatomic, strong) CoreGameHudLayer* hud;
@property (nonatomic, assign) DVPlayerMode playerMode;
@property (nonatomic, assign) int timeStepIndex;
@property (nonatomic, strong) NSMutableArray* playerMinionList;
@property (nonatomic, strong) Player* player;
@property (nonatomic, strong) NSMutableDictionary* historicalEventsDict;
//@property (nonatomic, strong) Opponent* opponent;

//@property (nonatomic, strong) NSMutableArray* bats;

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;
//+(HelloWorldLayer*) helloWorldLayerGetter;
-(void) mainGameLoop:(ccTime)deltaTime;
-(void) sampleCurrentPositions:(ccTime)deltaTime; // scheduled callback
-(void) setViewpointCenter:(CGPoint) position;
-(CGPoint) tileCoordForPosition:(CGPoint) position;
-(void) setPlayerPosition:(CGPoint) position;
//-(void) addEnemyAtX:(int)x y:(int)y;
-(void) projectileMoveFinished:(id) sender;
-(void) enemyMoveFinished:(id)sender;
-(void) missileMoveFinished:(id) sender;
-(void) animateEnemy:(CCSprite*) enemy;
-(void) win;
-(void) lose;
-(void) missileExplodes:(CGPoint) hitLocation;
-(void) missileExplodesFinished:(id) sender;
-(CGPoint) pixelToPoint:(CGPoint) pixelPoint;
-(CGSize) pixelToPointSize:(CGSize) pixelSize;
-(void) roundFinished;
-(void) enemyPlayback;
-(void) enemyPlaybackLoop:(ccTime)deltaTime;

@end