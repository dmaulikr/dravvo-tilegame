//
//  NewGameScene.h
//  tutorial_TileGame
//
//  Created by Jeremiah Anderson on 1/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "DVAPIWrapper.h"

@interface NewGameLayer : CCLayerColor

+(CCScene *) sceneWithBlockCalledOnNewGameClicked:(void (^)(id sender))block;
-(id) initWithBlockCalledOnNewGameClicked:(void (^)(id sender))block;

@end