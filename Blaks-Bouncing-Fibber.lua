-- Blak's Bouncing Fibber (Fibonacci)
-- constants

minbet = 0.00000001 -- Set this according to the coin / token you are on!
restTime = 0.0 -- How long to wait in seconds before the next bet.  Some sites need this
 
basebet = 0.00000001
basechance=7 -- The chance that you would like use.  7 seems to be a good starting point
housePercent = 5 -- Set this according to the site you are on.
-- Known site percentages
-- Freebitco.in = 5%
-- Bitsler = 1.5%
-- Bitvest = 1.5% 

fibstep = 0.1125 -- Fibonacci stepping amount
chanceStep = 0.01 -- Chance stepping amount 

local clock = os.clock
function sleep(n)  -- seconds
	local t0 = clock()
	while clock() - t0 <= n do end
end

lossCount = 0
stepCount = 0

highLowAverage = {}
averageCount = 0
averageIndex = 0
averageMax = 4 -- High / Low average switching. 
	
rollCount = 0
rollSeedCount = 0
	
-- Initialize the array
for i=0, averageMax do
	highLowAverage[i] = 0
end

chance = basechance
nextbet=basebet

-- The myfib routine was written by CttCJim 
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
-- End The myfib routine was written by CttCJim 

function dobet()

	if win then
		chance = basechance
		lossCount = 0 -- reset
		nextbet = basebet -- reset
		stepCount = 0
	else -- if lose
		lossCount += 1
		winAmount = (100 - (100 * (housePercent / 100))) / chance
		if lossCount > winAmount then
			stepCount += 1
			chance += chanceStep
			nextbet = myfib(stepCount)  
		end
	end
	
	-- Calculate the average, and then change high / low accordingly
	if(lastBet.Roll >= 50) then
		highLowAverage[averageIndex] = 1	
	else
		highLowAverage[averageIndex] = 0
	end
	averageIndex += 1
	if(averageIndex >= averageMax) then
		averageIndex = 0
	end
	if(averageCount < averageMax) then
		averageCount += 1
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
	sleep(restTime)

end
