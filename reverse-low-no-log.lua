-- Reverse Low strategy

startingBet = 1 -- Enter as whole satoshi
startingChance = 42
minimumChance = 0.45
lossChanceChange = 2.25 -- may need to change a little faster
maxBet = 25 -- Enter as whole satoshi.  Also used for a reset after maxLosscount losses in a row at this value.  
maxLossCount = 10 -- Used with maxBet.  If maxBet has been bet this many times in a row, it resets.
multiplier = 1.75 -- multiplier to increment the bet per loss
useMult = false -- Set this to false to increment each bet by 1, true to use the above multiplier
autoTune = true -- Set to false to use the maxBet value defined above. 
autoPercent = 0.0099 -- Percent of your current balance for maxBet for autoTune (x 100.  0.015 = 1.5%)

-- No need to change anything after this 
satoshi = 0.00000001
highLowAverage = {}
averageIndex = 0
averageCount = 0
averageMax = 4
for i=0, averageMax do
	highLowAverage[i] = 0
end
rollCountAverage = {}
rollAverageCount = 0
rollAverageIndex = 0
rollAverageMax = 4 -- Average roll count before a win.  How many wins do you want to average? 
maxLossCounter = 0
startingBet *= satoshi
maxBet *= satoshi
chance = startingChance
nextbet = startingBet

function dobet()

	-- auto tuning routine
	if(autoTune) then
		maxBet = balance * autoPercent
	end

	-- Win 
	if(win) then
		-- reset everything
		chance = startingChance
		nextbet = startingBet -- should never need to change for now
		maxLossCounter = 0
	end
	
	-- Loss
	if(!win) then
		-- Check to see if the last bet was max.
		-- This check must be before the check at the bottom for max bet
		if(nextbet >= maxBet) then
			maxLossCounter += 1
		end		
		chance -= lossChanceChange
		if(chance < minimumChance) then
			chance = minimumChance
		end
		if(useMult == true) then
			nextbet *= multiplier
		else
			nextbet += satoshi
		end
		if(nextbet > maxBet) then
			nextbet = maxBet
		end
		-- Need to check for reset 
		if(maxLossCounter >= maxLossCount) then -- Reset.  Too many losses
			chance = startingChance
			nextbet = startingBet 
			maxLossCounter = 0
		end
	end

	-- Calculate the high/low roll result average, and then change high/low accordingly
	-- The below variables need to be defined before the dobet() call
	-- rollCountAverage = {}
	-- rollAverageCount = 0
	-- rollAverageIndex = 0
	-- rollAverageMax = 4 -- Average roll count before a win.  How many wins do you want to average? 

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


end