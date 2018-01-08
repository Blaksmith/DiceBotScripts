-- Faucetor's Streak Squasher v.0.0.1
-- Special thanks to CttCJim & Blaksmith - the code is heavily leveraged from their scripts
-- If you win a bunch with this and...
-- 	You want to tip Jim BTC:			1JP3tHhToThgS81Wu8P8wD7Ymu29YB3upT
-- 	You want to tip Blaksmith BTC: 		1BLAKSMTjnME4ZJX7VzzUyEgbQYLShvqgi
--		You want to tip Faucetor LTC: 	LYEKMdAdAh2BKo2uSxVBoPsax3mdoeKTrL

isTokens = false -- Set to false for satoshi betting, true for tokens 
basechance = 49.5 	-- sets your chance for placing a bet
basebet = 2		-- Base bet in whole numbers.
resetbasebet = 1 -- amount to bet while waiting for win this should pretty much always be 1
fibstep = .755 -- Stepping for the fibonacci bet increments
LossStreakMax = 4 -- how many losses in a row before switching to reset mode

recoverychance = 49.5 -- sets your chance during recovery mode
recoverybasebet = 2 -- Base bet for loss streak recover in whole numbers
recoveryfibstep = .755 --Stepping for the fibonacci bet increments for recovery mode
recoveryLossStreakMax = 999 -- sets losses in a row before abandoning recovery mode - can set really high to effectively disable
                          -- Note recovery mode will automatically turn off if successful
rollDelay = 0.7 -- Sleep period in seconds.  Some sites need this						  

-- Init variables
nextbet = basebet -- sets your first bet.
chance = basechance -- sets the chance to play at
stepcount = 0 -- stepcounter for basebet fibonacci
streakStartBalance = 0 -- for capturing the balance at the start of a loss streak during normal betting
recoverychance = recoverychance -- sets chance during recovery
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
		if (reset == 1 and recovery == 0) then
				reset = 0
				recovery = 1
			end
		if (recovery == 0) then -- win, regular roll, reset almost all the things!
				recoverystepcount = 0
				streakStartBalance = 0
				lossStreak = 0
				recoveryLossStreak = 0
				stepcount = 0
				reset = 0
				chance = basechance
				nextbet = myfib(stepcount)
		else
			if (balance > streakStartBalance) then -- win, recovery roll, if we have recovered our initial balance reset everything
				print (balance)
				print(streakStartBalance)
				stepcount = 0 
				streakStartBalance = 0 
				recoverystepcount = 0 
				recovery = 0 
				lossStreak = 0
				recoveryLossStreak = 0 
				reset = 0
				chance = basechance
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
				chance = recoverychance			
			nextbet = myrecoveryfib(recoverystepcount)
			end
		end
	else -- lost last roll
	lossStreak += 1
		if (streakStartBalance == 0) then -- Get initial balance at the start of this run
                    streakStartBalance = balance
					print(streakStartBalance)			
		end
		if (lossStreak == LossStreakMax) then -- We reached our max loss streak settings, time to reset until the loss streak is over
                reset = 1
                nexbet = resetbasebet       
        end
		if (recovery == 1) then -- if we're in recovery mode 
            lossStreak = 0
			recoveryLossStreak += 1
           recoverystepcount += 1
            chance = recoverychance
            nextbet = myrecoveryfib(recoverystepcount)
            if (recoveryLossStreak >= recoveryLossStreakMax) then  -- if we reached our recovery loss streak max then give up
                recovery = 0
            end
        end
        if (reset == 1) then -- if we're in reset mode bet the reset basebet and reset a bunch of stuff
            recoverystepcount = 0
            lossStreak = 0
            recoveryLossStreak = 0
            stepcount = 0
            recoverystepcount = 0
            nextbet = resetbasebet
        end
        if (recovery == 0 and reset == 0) then -- we're in normal mode betting
            stepcount += 1
            nextbet = myfib(stepcount)
        end
    end
	
	sleep(rollDelay)
end
