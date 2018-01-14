

----------------------------------This is one of Sun Xiangyu's game production - "Pokemon Battle"-----------------------------------------------




======   1. Description    ======------------------------------------------------------------------------------------------------------------------

	*  "Pokemon Battle" is a 2D TCG(Trade Card Game), developed on mobile platform by cocos2d and LUA.
	
	*  In this game, players can explore the world of pokemons and experience exciting battle with other pokemon trainers. 
	   During this period, they will get more powerful pokemons and develop their own duel tacnic.
	   
	*  The cards in "Pokemon Battle" can be categorized into two types: pokemon cards and command cards. 
	   Both of them highly reconstruct the settings of the pokemon's world, including skills, natruals, and so on.
    
	*  every pokemon card's evolutionary tree, weakness and resistance are carefully designed, in order to make every round in the duel filled with uncertainty.
	
	
======   2. Directory Structure    ======----------------------------------------------------------------------------------------------------------

	*  Scripts 				-- Include some logical source code files of the game
		©Á base				-- This can enable player aim enemies by moving mouse, and shoot enemies by clicking the mouse's left button. 
		©Á com				-- This script is related to allies' behaviour in the first scene 	
		©Á extend			-- This script is related to allies' behaviour in the second scene.
		©Á game				-- This script is related to the commander's behaviour in the second scene.
		|  ©Á battle			-- Battle logic and display effect
		|  ©Á ClientData		-- Data layer related
		|  ©Á ClientView		-- Display layer related
		|  ©Á data			-- game's data related
		|  ©Á pb				-- network related
		|  ©Á scene			-- Basic code of game scenes
		|  ©¹ ui				-- Basic code of UI elements
		©Á network			-- This script related to the final scene. 3 different UI events are attached to different game objects in the scene.
		©¹ main.lua			-- This controls the auto-displaying of the dialogue in the final scene.
		
	*  Images      			-- Include some screenshot of gameplay and other image materials.
	
	*  If you want to see more details, see "Code Structure.jpg" in "Images" folder.
	
	
======   3. Guide    ======------------------------------------------------------------------------------------------------------------------------

	*  This game can be played in mobile phone platform
	
	*  In "Pokemon Battle", players can purchase card packages of different cahracters and personalize their own handful card group.

	*  All of the adventure levels in game have three difficulties: normal, medium, and difficult. By challenging adventure levels, 
	   players can obtain exp and gold coin as bonus.
	   
	*  In the PVP mode, players can be arranged to have online battle with well-matched opponents. After their winning this duel, they can receive
	   luxury rewards, which can further strengthen their card groups.
	   
	*  There also has a set of social system in "Pokemon Battle". Players can join unions, chat with their friends, and share their battle experience
	   with each other.

======   4. Others    ======----------------------------------------------------------------------------------------------------------------------- 

	*  This game was started in September, 2017, and will start closed beta in january, 2018.
	
	*  As a front-end game development engineer intern, I worked with the art designer and game designer in the ¡°Pokemon Battle¡± card game to 
	   independently complete all of the front-end page development work.
	
	*  Because of my experience in Art, Design and Programming, I am lucky to take part in every aspect of the game development, and also made some contributions in different degree, 
	   like my improved scheme for skill display design and PVP matching interface was adopted. 
	
	*  Restricted by the space request, the whole files (resources, plugins, etc) cannot be uploaded to the site, so I just choosed these important code script and 
	   added them into the zip file.
	   
	*  Want more information? see: https://csardasxy.github.io/homepage


---------------------------------------------------------------------------------------------------------------------------------------------------