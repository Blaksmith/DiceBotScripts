-- Blak's Bouncing Fibber (Fibonacci)
-- constants

minbet = 0.00000001 -- Set this according to the coin / token you are on!
autotune = true -- Set to false to use static settings below

restTime = 0.7 -- How long to wait in seconds before the next bet.  Some sites need this
			   -- Bitvest setting 0.7 for low bet values
 
basebet = 0.00000001
basechance=7 -- The chance that you would like use.  7 seems to be a good starting point
housePercent = 1.0 -- Set this according to the site you are on.
-- Known site percentages
-- Freebitco.in = 5%
-- Bitsler = 1.5%
-- Bitvest = 1.5% [Note from Jim: i think this is 1% not 1.5%]

fibstep = 0.0925 -- Fibonacci stepping amount
chanceStep = 0.01 -- Chance stepping amount 

enableLogging = true -- Set to false for no logging
filename = "bouncer.csv" -- Default to the directory where dicebot is run from.
tempfile = "tempfile.log" -- You can add an absolute directory if wanted with: C:\directory etc
rollLog = 0 -- Use 0 for dynamic logging, otherwise put in a value to log after X losing streak

local clock = os.clock
function sleep(n)  -- seconds
	local t0 = clock()
	while clock() - t0 <= n do end
end

lossCount = 0
stepCount = 0
spent = 0

highLowAverage = {}
averageCount = 0
averageIndex = 0
averageMax = 4 -- High / Low average switching. 
	
rollCount = 0
rollSeedCount = 0
profit = 0

if(enableLogging == true) then
	fin = assert(io.open(filename, "w"))
	fin:write("Streak, Bet, Chance, fibstep, Spent, Win Amount, Win Profit\n")
	fin:close()
end
	
-- Initialize the array
for i=0, averageMax do
	highLowAverage[i] = 0
end

function autocalc()
	if(autotune == true) then
		if(lossCount == 0) then
			basebet = balance / 100000
			basebet = basebet / (10 - basechance)
			if basebet < minbet then
				basebet = minbet
			end
		end
	end
end

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

autocalc()
chance = basechance
nextbet=basebet

function dobet()

	autocalc()

	if win then
		logTest = rollLog
		if(rollLog == 0) then
			logTest = (100 - (100 * (housePercent / 100))) / chance
		end
		-- print(logTest)
		if(enableLogging == true and lossCount >= logTest) then
			tempstr = "streak, bet, chance, fibstep, spent, winamount, profit\n"
			tempstr = string.gsub(tempstr, "streak", lossCount)
			tempcalc = string.format("%.8f", nextbet)
			tempstr = string.gsub(tempstr, "bet", tempcalc)
			tempcalc = string.format("%.2f", chance)
			tempstr = string.gsub(tempstr, "chance", tempcalc)
			tempstr = string.gsub(tempstr, "fibstep", fibstep)
			tempcalc = string.format("%.8f", spent)
			tempstr = string.gsub(tempstr, "spent", tempcalc)
			tempcalc = string.format("%.8f", lastBet.Profit)
			tempstr = string.gsub(tempstr, "winamount", tempcalc)
			profit = lastBet.Profit - spent
			tempcalc = string.format("%.8f", profit)
			tempstr = string.gsub(tempstr, "profit", tempcalc)
			-- print(tempstr)

			fin = assert(io.open(filename, "r"))
			content = fin:read("*a")
			fin:close()
			
			fout = assert(io.open(tempfile, "w"))
			fout:write(content)
			fout:write(tempstr)
			-- fout:write(oppositeOut)
			
			fout:close()
			os.remove(filename) 
			os.rename(tempfile, filename)

		end
		chance = basechance
		lossCount = 0 -- reset
		nextbet = basebet -- reset
		stepCount = 0
		spent = 0
	else -- if lose
		lossCount += 1
		spent += nextbet
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
