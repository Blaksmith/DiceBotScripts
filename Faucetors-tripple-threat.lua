-- Faucetor's Triple Threat Streak Squasher v.0.1.0.0.1.0
-- Special thanks to CttCJim & Blaksmith
-- the code is heavily leveraged from their scripts they both built - without them this Frankenscript would not have been possible
-- Additional thanks to Blaksmith for his input & support -without it this script would likely have never seen completion
-- If you win a bunch with this and...
-- 	You want to tip Jim BTC:			1JP3tHhToThgS81Wu8P8wD7Ymu29YB3upT
-- 	You want to tip Blaksmith BTC: 		1BLAKSMTjnME4ZJX7VzzUyEgbQYLShvqgi
--    You want to tip Faucetor LTC: 	LYEKMdAdAh2BKo2uSxVBoPsax3mdoeKTrL

isTokens = false -- Set to false for satoshi betting, true for tokens 
rollDelay = 0.75 -- Sleep period in seconds.  Some sites need this

-- Set Your Chances
basechance = 36.9 	-- sets your chance for placing a bet during primary betting mode
recoverychance = 40.5 -- sets your chance during the first recovery mode
martingalechance = 49.5 -- sets your chance during the second (martingale) recovery mode
recovery3chance = 1 -- sets your chance during the third recovery mode
recovery3ChanceStep = 0.5 -- used by recovery mode 3, gradually steps the % chance to win up on loss

-- Set Your Bets
basebet = 1		-- Base bet in whole numbers.
recoverybasebet = 2.5 -- Base bet for loss streak recover in whole numbers; likely should be more than basebet
martingalebasebet = 5 -- Base bet for martingale recovery mode
recovery3basebet	= 1 -- Basebet for third recovery mode
resetbasebet = 1 -- amount to bet while in reset mode waiting for win this should always be 1 - this *is* the loss streak squashing portion of the script

-- Set Your Multipliers
fibstep = .875 -- Stepping for the fibonacci bet increments for the base chance
recoveryfibstep = 1.50 -- Stepping for the fibonacci bet increments for recovery mode
martingalemult = 2 -- multiplier setting for martingale recovery mode
recovery3fibstep = .425 -- Stepping for the fibonacci bet increments for the third recovery mode

-- Loss Streak Settings
LossStreakMax = 5 -- how many losses in a row before switching to reset mode during primary betting mode
recoveryLossStreakMax = 4 -- sets losses in a row before abandoning the first recovery mode - can set really high to effectively disable, it will automatically end if it wins back above loss streak 
martingaleLossStreakMax = 6 -- sets losses in a row before abandoning martingale recovery mode
recovery3LossStreakMax = 9999 -- sets losses in a row before abandoning the 3rd recovery mode - can set really high to effectively disable, it will automatically end if it wins back above loss streak

			  
housePercent = 1.0 -- Used by 3rd recovery mode - Set this according to the site you are on
-- Known site percentages
-- Freebitco.in = 5%
-- Bitsler = 1.5%
-- Bitvest = 1%


-- Init variables
nextbet = basebet -- sets your first bet.
chance = basechance -- sets the chance to play at
stepcount = 0 -- stepcounter for basebet fibonacci
streakStartBalance = 0 -- for capturing the balance at the start of a loss streak during normal betting
recoverychance = recoverychance -- sets chance during recovery
recoverystepcount = 0 -- stepcounter for recoverybasebet fibonacci
recovery = 0 -- flag for turning recovery on/off
lossStreak = 0 -- counter for loss streaks during normal betting
recoveryLossStreak = 0 -- counter for loss streaks while in first recovery mode
reset = 0	-- flag for turning reset on/off
reset2 = 0 -- flag for turning 2nd reset on/off
reset3 = 0 -- flag for turning 3rd reset on/off
martingale = 0 -- flag for turning martingale recovery mode on/off
martingaleLossStreak = 0 -- counter for loss streaks while in martingale (2nd) recovery mode)
recovery3 = 0 -- flag for turning recovery mode 3 on/off
recovery3LossStreak = 0 -- counter for loss streaks while in third recovery mode
recovery3StepCount = 0 -- stepcounter for recovery3basebet fibonacci
recovery3Chance=recovery3chance -- sets chance during third recovery mode


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

function myrecovery3fib(level)
	fibno=recovery3basebet
	temp=0
	prevfibno=0
	if level == 0 then
		fibno= recovery3basebet
	else
		for j=0,level-1,1 do
			
			temp=fibno
			fibno=fibno + (prevfibno * recovery3fibstep)
			prevfibno=temp
		end
	end
	return fibno	
end

function dobet()
	if win then
		if (reset == 1 and reset2 == 0 and reset3 == 0 and recovery == 0 and martingale == 0 and recovery3 == 0) then
				reset = 0
				reset2 = 0
				reset3 = 0
				recovery = 1
				martingale = 0
				recovery3 = 0
				end
		if (reset == 0 and reset2 == 1 and reset3 == 0 and recovery == 0 and martingale == 0 and recovery3 == 0) then
				reset = 0
				reset2 = 0
				reset3 = 0
				recovery = 0
				martingale = 1
				recovery3 = 0
				end
		if (reset == 0 and reset2 == 0 and reset3 == 1 and recovery == 0 and martingale == 0 and recovery3 == 0) then
				reset = 0
				reset2 = 0
				reset3 = 0
				recovery = 0
				martingale = 0
				recovery3 = 1
				end
		if (reset == 0 and reset2 == 0 and reset3 == 0 and recovery == 0 and martingale == 0 and recovery3 == 0 ) then -- win, regular roll, reset things
				recoverystepcount = 0
				recovery3StepCount = 0
				streakStartBalance = 0
				lossStreak = 0
				recoveryLossStreak = 0 
				martingaleLossStreak	= 0				
				recovery3LossStreak	= 0
				stepcount = 0
				reset = 0				
				reset2 = 0
				reset3 = 0
				chance = basechance
				nextbet = myfib(stepcount)
				end
		if (reset == 0 and reset2 == 0 and reset3 == 0 and recovery == 1 and martingale == 0 and recovery3 == 0 and (balance > streakStartBalance)) then -- win, first recovery mode roll, if we have recovered our initial balance reset everything				
				stepcount = 0 
				streakStartBalance = 0 
				recoverystepcount = 0 
				recovery = 0
				martingale = 0
				recovery3 = 0 
				reset = 0				
				reset2 = 0
				reset3 = 0
				lossStreak = 0
				recoveryLossStreak = 0 
				martingaleLossStreak	= 0		
				recovery3LossStreak	= 0
				chance = basechance
				nextbet = basebet
				end
		if (reset == 0 and reset2 == 0 and reset3 == 0 and recovery == 0 and martingale == 1 and recovery3 == 0 and (balance > streakStartBalance)) then -- win, martingale recovery roll, if we have recovered our initial balance reset everything				
				recoverystepcount = 0
				recovery3StepCount = 0
				streakStartBalance = 0
				lossStreak = 0
				recoveryLossStreak = 0 
				martingaleLossStreak	= 0		
				recovery3LossStreak = 0
				stepcount = 0  
				recovery = 0
				martingale = 0
				recovery3 = 0 
				reset = 0				
				reset2 = 0
				reset3 = 0 
				chance = basechance
				nextbet = basebet
				end
		if (reset == 0 and reset2 == 0 and reset3 == 0 and recovery == 0 and martingale == 0 and recovery3 == 1 and (balance > streakStartBalance)) then -- win, martingale recovery roll, if we have recovered our initial balance reset everything				
				stepcount = 0
				recovery3stepCount = 0
				streakStartBalance = 0 
				recoverystepcount = 0 
				recovery = 0
				martingale = 0 
				recovery3 = 0				
				lossStreak = 0
				recoveryLossStreak = 0
				martingaleLossStreak = 0
				recovery3LossStreak = 0				 
				reset = 0
				reset2 = 0
				reset3 = 0
				chance = basechance
				nextbet = basebet
				end
		if (reset == 0 and reset2 == 0 and reset3 == 0 and recovery == 1 and martingale == 0 and recovery3 == 0 and (balance <= streakStartBalance)) then -- continue recovery mode if initial streak balance is not recovered				
				lossStreak = 0
				recoveryLossStreak = 0
				martingaleLossStreak = 0
				recovery3LossStreak = 0
				reset = 0
				reset2 = 0
				reset3 = 0
				recovery = 1
				martingale = 0
				recovery3 = 0				
				recoverystepcount = recoverystepcount - 1
				if (recoverystepcount < 1) then -- we don't want negative number stepcounts
					recoverystepcount = 0
				end
				chance = recoverychance			
				nextbet = myrecoveryfib(recoverystepcount)
				end
		if (reset == 0 and reset2 == 0 and reset3 == 0 and recovery == 0 and martingale == 1 and recovery3 == 0 and (balance <= streakStartBalance)) then -- continue martingale recovery mode if initial streak balance is not recovered
				lossStreak = 0
				recoveryLossStreak = 0
				martingaleLossStreak = 0
				recovery3LossStreak = 0
				reset = 0
				reset2 = 0
				reset3 = 0
				recovery = 0				
				martingale = 1
				recovery3 = 0				
				nextbet = martingalebasebet				
				end
		if (reset == 0 and reset2 == 0 and reset3 == 0 and recovery == 0 and martingale == 0 and recovery3 == 1 and (balance <= streakStartBalance)) then -- continue recovery mode 3 if initial streak balance is not recovered				
				lossStreak = 0
				recoveryLossStreak = 0
				martingaleLossStreak = 0
				recovery3LossStreak = 0
				reset = 0
				reset2 = 0
				reset3 = 0
				recovery = 0
				martingale = 0				
				recovery3 = 1
				recovery3StepCount = recovery3StepCount - 2
				recovery3ChanceStep = recovery3chance			
				nextbet = myrecovery3fib(recovery3StepCount)
				end  
  
    
else -- lost last roll
	  lossStreak = lossStreak + 1
		if (streakStartBalance == 0) then -- Get initial balance at the start of this run
                    streakStartBalance = (balance + previousbet * 2 + recoverybasebet * 2.5 + martingalebasebet * 2.5 + recovery3basebet* 2.5)	-- adding extra junk on the balance to make tokens actually work with this script
		    end
		if (lossStreak == LossStreakMax) then -- We reached our max loss streak settings, time to reset until the loss streak is over
                reset = 1
                nexbet = resetbasebet       
           end
		if (recovery == 1 and martingale == 0 and recovery3 == 0) then -- if we're in first recovery mode 
            lossStreak = 0
			recoveryLossStreak = recoveryLossStreak + 1
           recoverystepcount = recoverystepcount + 1
            chance = recoverychance
            nextbet = myrecoveryfib(recoverystepcount)
            if (recoveryLossStreak >= recoveryLossStreakMax) then  -- if we reached our recovery loss streak max then give up
					 reset = 0                
                reset2 = 1
                reset3 = 0
                recovery = 0
                martingale = 0
                recovery3 = 0
            end
        end
        if (recovery == 0 and martingale == 1 and recovery3 == 0) then -- if we're in martingale recovery mode 
            lossStreak = 0
				martingaleLossStreak = martingaleLossStreak + 1
            chance = martingalechance
            nextbet = previousbet * martingalemult
            if (martingaleLossStreak >= martingaleLossStreakMax) then  -- if we reached our recovery loss streak max then give up
               reset = 0
               reset2 = 0
					reset3 = 1               
					recovery = 0               
               martingale = 0
               recovery3 = 0
            end
          end
		if (recovery == 0 and martingale == 0 and recovery3 == 1) then -- if we're in third recovery mode 
				chance = recovery3chance         	
         	lossStreak = 0
				recovery3LossStreak = recovery3LossStreak + 1
				recovery3ChanceStep = recovery3ChanceStep + 1				
				chance = recovery3ChanceStep
				recovery3StepCount = recovery3StepCount + 1
         	nextbet = myrecovery3fib(recovery3StepCount)
				end            
            if (recovery3LossStreak >= recovery3LossStreakMax) then  -- if we reached our recovery loss streak max then give up
					 reset = 1                
                reset2 = 0
                reset3 = 0
					recovery = 0					
					martingale = 0                
                recovery3 = 0
            end
        end
        if (reset == 1) then -- if we're in reset mode bet the reset basebet and reset a bunch of stuff
				reset2 = 0            
            recoverystepcount = 0
            lossStreak = 0
            recoveryLossStreak = 0
            stepcount = 0
            recoverystepcount = 0
            nextbet = resetbasebet
          end
        if (reset2 == 1) then -- if we're in reset mode bet the reset basebet and reset a bunch of stuff
            recoverystepcount = 0
            lossStreak = 0
            recoveryLossStreak = 0
            martingaleLossStreak = 0
				reset = 0           
            stepcount = 0
            recoverystepcount = 0
            nextbet = resetbasebet
             end
        if (reset3 == 1) then -- if we're in reset mode bet the reset basebet and reset a bunch of stuff
            recoverystepcount = 0
            recovery3StepCount = 0 
            lossStreak = 0
            recoveryLossStreak = 0
            martingaleLossStreak = 0
            recovery3LossStreak = 0
				reset = 0           
            stepcount = 0
            nextbet = resetbasebet
             end            
     		if (recovery == 0 and martingale == 0 and recovery3 == 0 and reset == 0 and reset2 == 0 and reset3 == 0) then -- we're in normal mode betting
            stepcount = stepcount + 1
            nextbet = myfib(stepcount)
            end
	end
	sleep(rollDelay)
end