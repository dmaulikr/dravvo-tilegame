//
//  Player.h
//  tilegame2
//
//  Created by Jeremiah Anderson on 1/24/13.
//
//

#import <Foundation/Foundation.h>
#import "EntityNode.h"
#import "CoreGameLayer.h"

#define kDVPlayerOne 1
#define kDVPlayerTwo 2

// change properties if you chane this KVO constants
#define kDVNumMelonsKVO     @"numMelons"
#define kDVNumKillsKVO      @"numKills"
#define kDVNumShurikensKVO  @"numShurikens"
#define kDVNumMisslesKVO    @"numMissiles"

// action modes the player can be in
typedef enum {
    DVPlayerMode_Moving,
    DVPlayerMode_Shooting,
} DVPlayerMode;

@class CoreGameLayer;

@interface Player : EntityNode <NSCoding>

#define PlayerMinionsKey @"minions"
#define PlayerNumMelons @"numMelons"
#define PlayerNumKills @"numKills"
#define PlayerNumShurikens @"numShurikens"
#define PlayerNumMissiles @"numMissiles"
#define PlayerEnemyPlayer @"enemyPlayer"

//@property (nonatomic, readonly) NSMutableArray* minions;
@property (nonatomic, strong) NSMutableDictionary* minions;  // was strong
@property (nonatomic, assign) DVPlayerMode mode;

// change related consts if you ever any of these properties used in KVO
@property (nonatomic, assign) int numMelons;
@property (nonatomic, assign) int numKills;
@property (nonatomic, assign) int numShurikens; // FIX should be able just to count objects in array
@property (nonatomic, assign) int numMissiles; // FIX should be able just to count objects in array
@property (nonatomic, strong) Player* enemyPlayer;  // later, upgrade this to a list of enemyPlayers FIX for > 2 multiplay

// constructors
-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withUniqueIntID:(int)intID;
-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withUniqueIntID:(int)intID withShurikens:(int)numShurikens withMissles:(int)numMissles;
-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withUniqueIntID:(int)intID withShurikens:(int)numShurikens withMissles:(int)numMissles withKills:(int)numKills withMelons:(int)numMelons;

@end
