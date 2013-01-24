//
//  Bat.h
//  dravvo-tilegame_master
//
//  Created by Jeremiah Anderson on 1/22/13.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Entity.h"
#import "CCSequence+Helper.h"
#import "HelloWorldLayer.h"


@interface Bat : CCNode <Entity>

@property (nonatomic, unsafe_unretained) HelloWorldLayer* myLayer;
@property (nonatomic, assign) int hitPoints;
@property (nonatomic, assign) int speedInPixelsPerSec;
@property (nonatomic, strong) CCSprite* sprite;
@property (nonatomic, assign) int behavior;

// required METHODS
-(id)initWithLayer:(HelloWorldLayer*) layer andSpawnAt:(CGPoint) spawnPoint withBehavior:(int) initBehavior;
-(void)spwan:(CGPoint) spawnPoint;
// for sampling during real actions
-(void)sampleCurrentPosition:(CGPoint) currentPoint;  // this should be called (callbacked) once every kTimeStepSeconds for later animation on player2's side
// state changes like decreasing HP or killing a creature
-(void)wound:(int) hpLost;
-(void)kill; // possibly animate a death then remove this minion

// List of real actions the entity can do to interact with the environment state changes
-(void)realSetBehaviour:(int) newBeahavior;
-(void)realMove:(CGPoint) targetPoint;
-(void)realExplode:(CGPoint) targetPoint;

// List of historical animations that simluate past actions without any environment state changes, for later animation re-play on player2's side
// each minion has it's own list of animations that can be performed on it, such as exploding, moving, attacking,
-(void)animateMove:(CGPoint) targetPoint;  // will animate a historical move over time interval kTimeStepSeconds
-(void)animateExplode:(CGPoint) targetPoint;  // animate it exploding

-(void) takeActions;

@end