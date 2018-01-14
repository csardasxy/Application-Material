

----------------------------------This is one of Sun Xiangyu's game production - "Put Down Your Gun"-----------------------------------------------




======   1. Description    ======------------------------------------------------------------------------------------------------------------------

	*  Put Down Your Gun is a 2D shooting PC game with horizontal scroll world map, which was developed by unity3d, C#. 

	*  In the story of "Put Down Your Gun", player acts as a soldier, who was forced to join the army and invade other countries. 
	And at the end of the game, when he was commanded to kill an innocent little girl, he made a choice that forever changed three peoples' destiny ...
	
	*  I adopted a diary-form narrator in this game, to make players experience the story from a first-person angle.
	
	*  This game was created by myself in 12 hours, to show how bloody and cruel the war is and the brilliance of humanity. 
	
	*  In addition, every image and video resource in the game was made by myself, using PhotoShop and AfterEffect. 
	
	
======   2. Directory Structure    ======----------------------------------------------------------------------------------------------------------

	*  Scripts 					-- Include some logical source code files of the game
		�� AimShoot				-- This can enable player aim enemies by moving mouse, and shoot enemies by clicking the mouse's left button. 
		�� AllyBehavior1			-- This script is related to allies' behaviour in the first scene 	
		�� AllyBehavior2			-- This script is related to allies' behaviour in the second scene.
		�� AllyBehavior3			-- This script is related to the commander's behaviour in the second scene.
		�� AllyHealth			-- This controls ally's heath change during the gameplay.
		�� AutoDestroy			-- Auto destroy useless objects in scene
		�� BackGroundScroll		-- This script controls the scroll action of the background iamge.
		�� ButtonEvent			-- This contains all the button listeners' functions in this game.
		�� Camera2DFollow		-- This script can make the camera follow the character with an offset and delay.
		�� CharacterController	-- This script contains basic control methods of the character.
		�� CharacterHealth		-- This controls the character's health value change.
		�� EnemyBehavior			-- This script is related to enemies' AI
		�� EnemyHealth			-- This contains functions related to enemy's health (get damaged and die).
		�� FadeOff				-- It controls the images to fade out from the view.
		�� FightersGenerator		-- This script can generate fighters in the background of game's scene.
		�� Health				-- This is the basic class of character, ally and enemy's health. 
		�� LevelSwitch			-- This script ensures the smooth change between different game scenes.
		�� MoviePlayer			-- This script controls the movie playing at the end of the game.
		�� UIEvent1				-- This script related to the final scene. 3 different UI events are attached to different game objects in the scene.
		�� UIEvent2				-- This script related to the final scene. 3 different UI events are attached to different game objects in the scene.
		�� UIEvent3				-- This script related to the final scene. 3 different UI events are attached to different game objects in the scene.
		�� Words					-- This controls the auto-displaying of the dialogue in the final scene.
		
	*  Images      		-- Include some screenshot of gameplay
	
	*  Materials   		-- Include materials(icons) of game's development
	
	
======   3. Guide    ======------------------------------------------------------------------------------------------------------------------------

	*  WASD keys      		-- move 
	*  left mouse button 	-- shoot
	*  Shift key 			-- charge
	
	*  This game's start interface includes "start" and "config" options.
	And	in the "config" option's view, player can set the volume and sound effect in the game.
	
	*  Since the whole length of this game's experience is short (about 10 ~ 30 mins), this game cannot be saved. 
	
	*  Though short the game's story is, it still has two different endings to be explored by players.
	

======   4. Others    ======----------------------------------------------------------------------------------------------------------------------- 

	*  This game was completed in September, 2016
	
	*  ALL the Character's 2D sprite, item icons, and UI resources were made by MYSELF
	
	*  Restricted by the space request, the whole files (resources, plugins, etc) cannot be uploaded to the site, so I just choosed these important code script and 
	   added them into the zip file.
	   
	*  Want more information? see: https://csardasxy.github.io/homepage


---------------------------------------------------------------------------------------------------------------------------------------------------