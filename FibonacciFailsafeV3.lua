-- CttCJim's Self-watching Fibonacci V3
-- Special thanks to Blaksmith for edits
-- After panic level, resets on first win.
-- If no win after panicReset, resets to base bet
-- Future versions may aim for a particular balance and incorporate minimum balances.
-- no-bs-faucet.com has more info and if you want to tip me, just head there!

-- bethigh=true -- bet high when true, bet low when false

enablezz=false -- set to true to use high/low switching 
-- settings from advanced mode

enablesrc=false -- set to true to use stop/reset conditions 
-- settings from advanced mode


-- constants

minbet = 0.00000001 -- Set this according to the coin / token you are on!
restTime = 0.0 -- How long to wait in seconds before the next bet.  Some sites need this
 
basebet = 0.00000001
nextbet=basebet
basechance=34.75 -- changed by Blaksmith
paniclevel = 5 -- where we try to recover
panicflag = 0
prevbet = basebet

fibstep = 1.0 -- step multiplier. change to 1 for classic fibonacci sequence.
				  -- can also enter: fibstep = x.xx while it is running to take a bigger risk!

dynStep = 600000 --determines dynamic bet. bet = balance / dynStep
-- Added by Blaksmith
dynamicBase = true -- Set this to false to *not* calculate the base bet according to your balance
smoothPanic = false -- Set this to false to *not* raise the chance to soften the blow before resetting completely.
panicReset = 50 -- Set this to how many times it can roll after hitting panic, before completely resetting
panicCounter = 0
panicOffset = 1.0 -- Increment chance by this much on every loss beyond paniclevel  
-- End Added by Blaksmith

onwin = -2
onlose = 1
fibdex=0
currbet=basebet

panicnumber = 1 -- this too
i=0

-- Added by Blaksmith
local clock = os.clock
function sleep(n)  -- seconds
	local t0 = clock()
	while clock() - t0 <= n do end
end
-- End Added by Blaksmith

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

-- initialization
function initialize()
	if dynamicBase == true then
		basebet = balance / dynStep
		if basebet < minbet then
			basebet = minbet
		end
	end
	panicnumber=basebet
	nextbet = basebet
	chance = basechance -- Added by Blaksmith
	temp=0
	prevtemp=0
	fibdex=0

	panicnumber=myfib(paniclevel)

	tempstr = "Panic Number: panicnumber"
	tempcalc = string.format("%.8f", panicnumber)
	tempstr = string.gsub(tempstr, "panicnumber", tempcalc)

	print (tempstr)
	
	highLowAverage = {}
	averageCount = 0
	averageIndex = 0
	averageMax = panicReset -- High / Low average switching. 
	
	rollCount = 0
	rollSeedCount = 0
	
	-- Initialize the array
	for i=0, averageMax do
		highLowAverage[i] = 0
	end
	

end


initialize()

function dobet()

	if win then
	
		-- print("win")
		
		if panicflag==1 then
			nextbet=basebet
			fibdex=0
			print("panic over, reset")
		else
			
			fibdex=fibdex+onwin
			
			if fibdex < 0 then -- lets not get negative index numbers
				fibdex=0
			end
			
			nextbet=myfib(fibdex)
		end
		if dynamicBase == true then
			basebet = balance / dynStep
			if basebet < minbet then
				basebet = minbet
			end
			panicnumber = myfib(paniclevel)
		end
		panicCounter=0
		panicflag=0
		chance = basechance
		
	else -- if lose
		-- print("lose")
		if prevbet >= panicnumber then
			print("bet over limit, PANIC")
			panicflag=1
		end
		fibdex=fibdex+onlose
		nextbet=myfib(fibdex)

-- Added by Blaksmith		
		if panicflag == 1 then
			panicCounter += 1
			if smoothPanic == true then
				chance += panicOffset -- Needs to be tweaked. 
			end
		end

		if panicCounter >= panicReset then -- Completely reset
			nextbet = basebet
			fibdex=0
			panicflag = 0
			chance = basechance
			panicCounter = 0 -- Added by Blaksmith
			print("Too many panic rolls!  Resetting!")
		end
-- End Added by Blaksmith

	end
	
	prevbet=nextbet

-- Added by Blaksmith	
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
-- End Added by Blaksmith
	sleep(restTime)

end
