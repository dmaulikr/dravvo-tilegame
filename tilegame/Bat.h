//
//  Bat.h
//  dravvo-tilegame_master
//
//  Created by Jeremiah Anderson on 1/22/13.
//
//
//@protocol Entity;

#import <Foundation/Foundation.h>
#import "cocos2d.h"

#import "CCSequence+Helper.h"
//#import "ReplayableEvents.h"
#import "CreatureNode.h"

#define kEntityTypeBat @"bat"
#define kEntityBatHitPoints 1
#define kEntityBatSpeedPPS 33

@class CreatureNode;

@interface Bat : CreatureNode

-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withBehavior:(DVCreatureBehavior)behavior ownedBy:(EntityNode *)player;

@end
