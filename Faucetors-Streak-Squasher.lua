-- Faucetor's Streak Squasher v.0.0.1
-- Special thanks to CttCJim & Blaksmith - the code is heavily leveraged from their scripts
-- If you win a bunch with this and...
-- 	You want to tip Jim BTC:			1JP3tHhToThgS81Wu8P8wD7Ymu29YB3upT
-- 	You want to tip Blaksmith BTC: 	1BLAKSMTjnME4ZJX7VzzUyEgbQYLShvqgi
--		You want to tip Faucetor LTC: 	LYEKMdAdAh2BKo2uSxVBoPsax3mdoeKTrL

isTokens = false -- Set to false for satoshi betting, true for tokens 
basechance = 47.0 	--sets your chance for placing a bet
basebet = 1		-- Base bet in whole numbers.
resetbasebet = 1 -- amount to bet while waiting for win this should pretty much always be 1
fibstep = .075 -- Stepping for the fibonacci bet increments
LossStreakMax = 3 -- how many losses in a row before switching to recovery mode

recoverychance = 50 -- sets your chance during recovery mode
recoverybasebet = 2	-- Base bet for loss streak recover in whole numbers
recoveryfibstep = .085 --Stepping for the fibonacci bet increments for recovery mode
recoveryLossStreakMax = 6 -- sets losses in a row before abandoning recovery mode - can set really high to effectively disable
                          -- Note recovery mode will automatically turn off if successful
rollDelay = 0.7 -- Sleep period in seconds.  Some sites need this						  

-- Init variables
nextbet = basebet -- sets your first bet.
chance = basechance -- sets the chance to play at
stepcount = 0 -- stepcounter for basebet fibonacci
Streakstartbalance = 0 -- capturing the balance at the start of a loss streak during normal betting
recoverystepcount = 0 -- stepcounter for recoverybasebet fibonacci
recovery = 0 -- flag for turning recovery on/off
lossStreak = 0 -- counter for loss streaks during normal betting
recoveryLossStreak = 0 -- counter for loss streaks while in recovery mode
reset = 0	-- flag for turning reset on/off



if(isTokens == false) then -- Convert basebet and recoverybasebet to satoshi
	basebet = basebet * 0.00000001
	recoverybasebet = recoverybasebet * 0.00000001
	resetbasebet = resetbasebet * 0.00000001
	nextbet = basebet -- sets your first bet.
end


local clock = os.clock
function sleep(n)  -- seconds
	local t0 = clock()
	while clock() - t0 <= n do end
end

function myfib(level)
	fibno=basebet
	temp=0
	prevfibno=0
	if level == 0 then
		fibno= basebet
	else
		for j=0,level-1,1 do
			
			temp=fibno
			fibno=fibno + (prevfibno * fibstep)
			prevfibno=temp
		end
	end
	return fibno	
end

function myrecoveryfib(level)
	fibno=recoverybasebet
	temp=0
	prevfibno=0
	if level == 0 then
		fibno= recoverybasebet
	else
		for j=0,level-1,1 do
			
			temp=fibno
			fibno=fibno + (prevfibno * recoveryfibstep)
			prevfibno=temp
		end
	end
	return fibno	
end

function dobet()
	if win then
		reset = 0
		if recovery == 0 then -- win, regular roll, reset almost all the things!
				Streakstartbalance = 0 -- capturing the balance at the start of a loss streak during normal betting
				recoverystepcount = 0
				recovery = 0
				lossStreak = 0
				recoveryLossStreak = 0
				stepcount = 0
				recoverystepcount = 0
				nextbet = basebet
		else
			if(balance >= streakStartBalance) then -- win, recovery roll, if we have recovered our initial balance reset everything
				stepcount = 0 
				Streakstartbalance = 0 
				recoverystepcount = 0 
				recovery = 0 
				lossStreak = 0
				recoveryLossStreak = 0 
				reset = 0	
				nextbet = basebet
			else	-- continue recovery if initial streak balance is not recovered
				lossStreak = 0
				recoveryLossStreak = 0
				reset = 0
				recovery = 1
				recoverystepcount -= 1
				if (recoverystepcount < 1) then -- we don't want negative number stepcounts
					recoverystepcount = 1
				end
			nextbet = myrecoveryfib(recoverystepcount)
			end
		end
	else -- lost last roll
		if (reset == 1) then -- if we're in reset mode bet the reset basebet and reset a bunch of stuff
			recoverystepcount = 0
			recovery = 0
			lossStreak = 0
			recoveryLossStreak = 0
			stepcount = 0
			recoverystepcount = 0
			nextbet = resetbasebet
		else
			if (recovery == 1) then -- if we're in recovery mode 
				recoveryLossStreak += 1
				recoverystepcount += 1
				if (recoveryLossStreak >= recoveryLossStreakMax) then  -- if we reached our recovery loss streak max then give up
					recovery = 0	
				end
				nextbet = myrecoveryfib(recoverystepcount)
			else -- we're not in reset mode or recovery mode - just a normal loss
				lossStreak += 1
				stepcount += 1
				if(streakStartBalance == 0) then -- Get initial balance at the start of this run
					streakStartBalance = balance		
					if (lossStreak >= LossStreakMax) then --We reached our max loss streak settings, time to reset until the loss streak is over
						reset = 1
						nexbet = resetbasebet
					end
				else
					nextbet = myfib(stepcount)
				end
			end
		end
	end
	
	sleep(rollDelay)
end
