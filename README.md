--- Instructions 
Run code.py
Input username
Run code.py again
Input a different username
Invite someone (not yourself)
Accept the Invite

This launches the game which is written in lua, should launch 2 instances

Choose a loadout
Once you choose a loadout you will be put into the game
Choose a loadout for both users 

Once you are in the game, you can press the left and right arrow to move around

Right now, there are about 15 "entities" that you can buy
Only the first 1 has functionality, it moves to the enemy tower to attack it
All the rest are just barriers for now
Entity 1 tries to get to the enemy tower
It pathfinds around the entities if they are in the way
If there is no possible route to the enemy tower, then it just tries to get as close as possible
If it reaches the enemy tower, the enemy loses health and gets damaged
To place down an entity, click buy, and then click a location on the map to place it
You will see that the entity should appear on the opposite screen

--- Instructions to play with someone on a different device
Enable hotspot on windows
Choose a network name
Choose a network password
Tell everyone who you want to play with your network name and password
Get these people to join your network
Do the above instruction set after this
You may have to disable your firewall
