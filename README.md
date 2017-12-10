# DiceBotScripts
Misc scripts I have written or modified for DiceBot

Faucetors-idea.lua
	Martingale type, which ignores the first X amount of losses before starting to do a martingale.
	
Fibonacci-with-failsafe.lua
	Fibonacci method, with a double cut-off for resetting, so you won't lose the farm.  Original design by CttCJim.
	
Martingale-logging.lua
	Auto tuning martingale to allow you to have X amount of slots (losses), before you go bust
	Built-in commands:
		setslots(X) Replace X with how many slots, use 0 to disable auto-calculate
		setmult(X.XX) Replace X.XX with the multipler per loss, until a win
		This script will log every win after X streak has hit (default to 10)

reverse-low.lua 
	Been a while, so I forgot what it does HAH.  It has logging  
	
reverse-low-no-log.lua 
	Same as the above, but with no logging
	
roxy-style.lua
	This is the style that I use on Roll of Chance on FaucetGame.com  I mainly use it for lotto tickets.
	
safe-climb.lua
	It is supposed to climb safely, but doesn't do as expected.  
	
streak-counter.lua
	similar to Martingale-logging.lua
	Will need to re-visit the code to double check.  


Use any of these scripts at your own risk!  I claim no responsibility for your loss in your dice rolling!