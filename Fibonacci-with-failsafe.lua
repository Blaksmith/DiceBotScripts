-- CttCJim's Self-watching Fibonacci V2
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

basebet = 1
nextbet=basebet
chance=39.6
paniclevel = 7 -- where we try to recover
panicflag = 0
prevbet = basebet

panicReset = 4 -- Set this to how many times it can roll after hitting panic, before completely resetting
panicCounter = 0

onwin = -2
onlose = 1
fibdex=0
currbet=basebet

panicnumber = 1 -- this too
i=0

function myfib(level)
	fibno=basebet
	temp=0
	prevfibno=0
	if level == 0 then
		fibno= basebet
	else
		for j=0,level-1,1 do
			
			temp=fibno
			fibno=fibno+prevfibno
			prevfibno=temp
		end
	end
	return fibno	
end

-- initialization
function initialize()
	panicnumber=basebet
	nextbet = basebet
	temp=0
	prevtemp=0
	fibdex=0

	panicnumber=myfib(paniclevel)

	print ("")
	print("panicnumber:")
	print(panicnumber)
	print ("")
	
	highLowAverage = {}
	averageCount = 0
	averageIndex = 0
	averageMax = 8 -- High / Low average switching.  How many rolls do you want to average? 
	
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
		panicCounter=0
		panicflag=0
		
	else -- if lose
		-- print("lose")
		if prevbet >= panicnumber then
			print("bet over limit, PANIC")
			panicflag=1
		end
		fibdex=fibdex+onlose
		nextbet=myfib(fibdex)
		
		if panicflag == 1 then
			panicCounter += 1
		end
		if panicCounter >= panicReset then -- Completely reset
			nextbet = basebet
			fibdex=0
			panicflag = 0
			panicCounter = 0
			print("Too many panic rolls!  Resetting!")
		end
	end
	
	prevbet=nextbet
	
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

end