//
//  NewGameScene.h
//  tutorial_TileGame
//
//  Created by Jeremiah Anderson on 1/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "DVAPIWrapper.h"

#define kCountdownFrom 3
#define kLabelFormat @"%d"

@interface CountdownLayer : CCLayerColor {
    id _labelAction;
}

@property (nonatomic, assign) int countdownCount;
@property (nonatomic, strong) CCLabelTTF* label;

-(void) updateLabel:(ccTime) delta;
+(CCScene *) scene;

@end