//
//  Player.h
//  tilegame2
//
//  Created by Jeremiah Anderson on 1/24/13.
//
//

#import <Foundation/Foundation.h>
#import "EntityNode.h"

// change properties if you chane this KVO constants
#define kDVNumMelonsKVO     @"numMelons"
#define kDVNumKillsKVO      @"numKills"
#define kDVNumShurikensKVO  @"numShurikens"
#define kDVNumMisslesKVO    @"numMissiles"

// action modes the player can be in
typedef NS_ENUM(NSInteger, PlayerMode) {
    PlayerMode_Moving,
    PlayerMode_Shooting,
};

typedef NS_ENUM(NSInteger, PlayerRole) {
    PlayerRole_Host = 1,
    PlayerRole_Guest,
};

@class CoreGameLayer;

@interface Player : EntityNode <NSCoding>

#define PlayerMinionsKey @"minions"
#define PlayerNumMelons @"numMelons"
#define PlayerNumKills @"numKills"
#define PlayerNumShurikens @"numShurikens"
#define PlayerNumMissiles @"numMissiles"
#define PlayerEnemyPlayer @"enemyPlayer"
#define PlayerDeviceToken @"playerDeviceToken"

//@property (nonatomic, readonly) NSMutableArray* minions;
@property (nonatomic, strong) NSMutableDictionary* minions;  // was strong
@property (nonatomic, strong) NSMutableDictionary* missiles;  // was strong
@property (nonatomic, strong) NSMutableDictionary* shurikens;  // was strong
@property (nonatomic, assign) PlayerMode mode;

// change related consts if you ever any of these properties used in KVO
@property (nonatomic, assign) int numMelons;
@property (nonatomic, assign) int numKills;
@property (nonatomic, assign) int numShurikens; // FIX should be able just to count objects in array
@property (nonatomic, assign) int numMissiles; // FIX should be able just to count objects in array
@property (nonatomic, strong) Player* enemyPlayer;  // later, upgrade this to a list of enemyPlayers FIX for > 2 multiplay
// used to know who is who in gamestatus objects from server
@property (nonatomic, strong) NSString* deviceToken; // FIX should be more clever about this

// constructors
-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withUniqueIntID:(int)intID;
-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withUniqueIntID:(int)intID withShurikens:(int)numShurikens withMissles:(int)numMissles;
-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withUniqueIntID:(int)intID withShurikens:(int)numShurikens withMissles:(int)numMissles withKills:(int)numKills withMelons:(int)numMelons;

@end
