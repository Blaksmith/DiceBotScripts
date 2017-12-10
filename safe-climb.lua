-- 
-- Based upon the Pluscoup script by chilly2k and grendel25
-- Safe-Climb script, edited by Blaksmith 
-- 
stopOnLoss = false -- Set this to true to stop, otherwise it will reset, and try again

-- Use the autotune feature to let this script determine your betting levels.
--
-- autoDivisor setting resets your bet on every win recovery.  
-- 	Formula is: basebet = balance / autoDivisor.  
-- 	The higher the divisor, the lower the bet.
-- 	Example: Balance = 20000 satoshi, autoDivisor = 5000, result = 4.
-- 				Balance = 200000 satoshi, autodivisor = 5000, result = 40.
-- 				Balance = 20000 satoshi, autodivisor = 50000, result = 0.4 (rounded to 1)
-- 				Balance = 200000 satoshi, autodivisor = 50000, result = 4
autotune = false -- Set this to false if you want to use the entries below as your settings
autoDivisor = 10000 -- Need to tweak this number a little more  Higher = lower bets

-- If you do not wish to use the auto tune, you will need to verify these few entries
basebet = 1 -- enter as a single satoshi value
maxwin = 10000000 -- Enter as a single satoshi value
maxloss= 10000 -- Enter as a single satoshi value
maxbet = basebet * 500 -- Max bet % from your basebet setting.  Default is set to 500% (I.E. 0.00000001 * 500)
lossPercent = 50 -- Percent of your current balance you are willing to lose before reset

-- *************************************************
-- Should not need to edit anything below this line!
-- *************************************************

satoshi = 0.00000001
maxRollLoss = maxbet -- Maximum number of rolls while below, before reset
basebet = basebet * satoshi
maxwin = maxwin * satoshi
maxloss = maxloss * satoshi
maxbet = maxbet * satoshi

seedCounter = 0
roundprofit = 0
chance = 50

-- Initialize variables if autotune is enabled, before actually running 
if(autotune == true) then
	basebet = balance / autoDivisor 
	if basebet < (1 * satoshi) then -- 1 satoshi is the lowest you can bet 
		basebet = 1 * satoshi
		maxRollLoss = basebet * 1000 * 10000000 
	end
	maxwin = 1000 -- Why limit it? 
	maxloss = balance - (balance * (lossPercent / 100)) -- Calculate new max loss value
	maxbet = basebet * 500 -- 500% of your base roll
end

nextbet = basebet

minbal = balance-maxloss	-- Max coin you are willing to let it lose before stopping
maxbal = balance+maxwin 	-- Max coin you want to win before stopping

highLowAverage = {}
averageCount = 0
averageIndex = 0
averageMax = 4 -- High / Low average switching.  How many rolls do you want to average? 

rollCount = 0

-- Initialize the array
for i=0, averageMax do
	highLowAverage[i] = 0
end


function dobet()

if(autotune == true and roundprofit >= 0) then
	basebet = balance / autoDivisor 
	if basebet < (1 * satoshi) then -- 1 satoshi is the lowest you can bet 
		basebet = 1 * satoshi
		maxRollLoss = basebet * 1000 * 10000000 -- Convert to whole number
	end
	maxloss = balance - (balance * (lossPercent / 100))
	maxbet = basebet * 500 -- 500% of your base roll
end

roundprofit += currentprofit
rollCount += 1

-- We got a win, let's check some things
if (win) then
	if (roundprofit < 0) then
		if(currentstreak < 2) then -- Only increase if coming back from a loss
			nextbet = previousbet + basebet
			nextbet = nextbet * 1.5 -- Just for the hell of it.
		end
		if (nextbet > maxbet) then
			nextbet = maxbet
		end
	else
		nextbet = basebet 
	end

	-- Are we up above where we started?
	if roundprofit > 0 then 
		minbal += roundprofit 
		roundprofit = 0
		chance = 50 -- reset the winning chance
		rollCount = 0 -- Reset the roll counter for the reset on loss
		-- print(minbal)
	end
end

-- We got a loss, let's check some things
if (!win) then
	nextbet = previousbet
	chance = chance + 0.125 -- Testing 
	if (chance >= 88) then
		chance = 88
	end
	if (chance >= 78 and currentstreak == -1) then -- Allow it to travel up higher until a hit first.
		-- Decide wtf to do to mitigate sharp losses
		-- Reset routine
		if(stopOnLoss == false) then
			print("Resetting due to > 78% losing streak")
			tempstr1 = "Balance: newbal"
			tempstr = string.gsub(tempstr1, "newbal", balance)
			print(tempstr)
			if(autotune == true) then
				basebet = balance / autoDivisor
				if basebet < (1 * satoshi) then -- 1 satoshi is the lowest you can bet 
					basebet = 1 * satoshi
					maxloss = balance - (balance * (lossPercent / 100))
				end
			end
			nextbet = basebet -- Reset.  
			roundprofit = 0 -- Reset 
			rollCount = 0 -- Reset the roll counter for the reset on loss
			maxRollLoss = basebet * 1000 * 10000000 
			maxwin = 1000 -- Why limit it? 
			maxbet = basebet * 500 -- 500% of your base roll
			minbal = balance-maxloss	-- Max coin you are willing to let it lose before stopping
			maxbal = balance+maxwin 	-- Max coin you want to win before stopping
		else
			print("Stopping due to too many losses")
			stop()
		end
		
		-- Slow recovery routine
		-- No code yet
	end
	-- See if we had 100 losses, and then reset the seed
	seedCounter += 1
	if (seedCounter > 100) then
		resetseed()
		seedCounter = 0
	end
end

-- Check for reset conditions
if (rollCount >= maxRollLoss) then
	if(stopOnLoss == false) then
		print("Resetting due to too many losses")
		if(autotune == true) then
			basebet = balance / autoDivisor
			if basebet < (1 * satoshi) then -- 1 satoshi is the lowest you can bet 
				basebet = 1 * satoshi
				maxloss = balance - (balance * (lossPercent / 100))
			end
		end
		nextbet = basebet -- Reset.  
		roundprofit = 0 -- Reset 
		rollCount = 0 -- Reset the roll counter for the reset on loss
		maxRollLoss = basebet * 1000 * 10000000 
		maxwin = 1000 -- Why limit it? 
		maxbet = basebet * 500 -- 500% of your base roll
		minbal = balance-maxloss	-- Max coin you are willing to let it lose before stopping
		maxbal = balance+maxwin 	-- Max coin you want to win before stopping
	else
		print("Stopping due to too many losses")
		stop()
	end
end

-- Calculate the average, and then change high / low accordingly
if(lastBet.Roll >= 50) then
	highLowAverage[averageIndex] = 1	
else
	highLowAverage[averageIndex] = 0
end
averageIndex += 1
averageCount += 1
if(averageIndex >= averageMax) then
	averageIndex = 0
end
if(averageCount > averageMax) then
	averageCount = averageMax
end
average = 0.00
for i=0, averageCount do
	average += highLowAverage[i]
end
average = average / averageCount
-- print (average)
if average >= 0.5 then
	bethigh = true
else
	bethigh = false
end

-- Check to see if we need to stop due to hitting min balance
if balance<minbal then
	if(stopOnLoss == true) then
		print("Stopping due to minimum balance hit")
		stop()
	else
		print("Resetting due to minimum balance hit")
		nextbet = basebet -- Reset.  
		roundprofit = 0 -- Reset 
		rollCount = 0 -- Reset the roll counter for the reset on loss
		if(autotune == true) then
			basebet = balance / autoDivisor 
			if basebet < (1 * satoshi) then -- 1 satoshi is the lowest you can bet 
				basebet = 1 * satoshi
				maxRollLoss = basebet * 500 * 10000000 
				maxloss = balance - (balance * (lossPercent / 100))
			end
		end
		maxwin = 1000 -- Why limit it? 
		maxbet = basebet * 500 -- 500% of your base roll
		minbal = balance-maxloss	-- Max coin you are willing to let it lose before stopping
		maxbal = balance+maxwin 	-- Max coin you want to win before stopping
	end
end

-- Check to see if we made as much as we wanted, then stop
if balance>maxbal then
	print("Stopping due to maximum win amount")
	stop()
end


-- This is needed at the end of the script
end