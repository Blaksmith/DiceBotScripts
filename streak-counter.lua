-- *******************************************************
-- Martingale with logging  
-- Use this ref link to support this code: http://faucetgame.com/r/6490808
--
-- Script name: Roxy-style.lua
-- 
--  
-- *******************************************************

-- Default logging goes to the directory where DiceBot is run from.
-- To specify a different log location, you need to edit the 2 lines below.  
-- The two files must be in the same directory!  
filename = "streak.log"
csvfile = "streak.csv"
tempfile = "tempfile.log"
timeStart = os.time()

-- ************************************
-- Comment these next 3 lines if you want to append to the old file.
-- These 3 lines must be un-commented on the very first run, otherwise
-- the script will crash with a LUA error, due to the file not existing.
-- ************************************
fin = assert(io.open(filename, "w"))
fin:write("\n")
fin:close()
-- ************************************
-- Comment the above 3 lines if you want to append to the old file
-- These 3 lines must be un-commented on the very first run, otherwise
-- the script will crash with a LUA error, due to the file not existing.
-- ************************************

-- ************************************
-- Comment these next 3 lines if you want to append to the old file.
-- These 3 lines must be un-commented on the very first run, otherwise
-- the script will crash with a LUA error, due to the file not existing.
-- ************************************
fin = assert(io.open(csvfile, "w"))
fin:write("Rolls, Opposites, High Bets, High Rolls, Low Rolls, Low Bets, High Rolls, Low Rolls, Multiplier, Last Bet, Winning Chance, Winning Roll, Spent, Win Amount, Win Profit, Balance, Run Profit\n")
fin:close()
-- ************************************
-- Comment the above 3 lines if you want to append to the old file
-- These 3 lines must be un-commented on the very first run, otherwise
-- the script will crash with a LUA error, due to the file not existing.
-- ************************************

-- initialize custom settings
slowdown = 0.5 -- In seconds.  Set this to 0.0 to run at full speed.  Need to slow down for FreeBitco.in
lossStreak = 3
winStreak = 4 
stoploss = 5
basebet = 0.00000001 -- Your starting bet
lossBet = 0.00000010 -- What to bet after lossStreak bets
winBet =  0.00000050 -- What to bet after winStreak bets
multiplier = 2.0 -- What multiplier you want for the martingale
-- If you want to just play steady, put this at 2.0
basechance = 45 -- Might need to fine tune this one per site

winStreakCount = 0
lossStreakCount = 0

lastWinRollCount = 0
currentRollCount = 0
balanceLastWin = balance
startingBalance = balance
oppositeRolls = 0
oppositeArray = {}
oppositeArrayCount = {}
winCount = 0
rollHighHigh = 0
rollHighLow = 0
rollLowHigh = 0
rollLowLow = 0
roundSpent = 0

-- Initialize system settings
nextbet = basebet
chance = basechance
satoshi = 0.00000001

-- set up the logging for this run.
-- timestamps are screwed up, otherwise I would have added them
fin = assert(io.open(filename, "r"))
content = fin:read("*a")
fin:close()
fout = assert(io.open(tempfile, "w"))
fout:write(content)
tempstr = "********************************** New run **********************************\r\n"
fout:write(tempstr)
tempstr1 = "Starting balance: replace\r\n"
tempcalc = string.format("%.8f", balance)
tempstr = string.gsub(tempstr1, "replace", tempcalc)
fout:write(tempstr)
fout:close()
os.remove(filename) 
os.rename(tempfile, filename)

rollCountAverage = {}
rollAverageCount = 0
rollAverageIndex = 0
rollAverageMax = 3 -- Average roll count before a win.  How many wins do you want to average? 

-- Initialize the array
for i=0, rollAverageMax do
	rollCountAverage[i] = 0
end

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


local clock = os.clock
function sleep(n)  -- seconds
	local t0 = clock()
	while clock() - t0 <= n do end
end

-- Start the actual betting 
function dobet()

	currentRollCount += 1
	rollCount += 1
	roundSpent += lastBet.Amount
	
	-- Store statistics for high / low rolls
	if(lastBet.Roll > 50 and bethigh == true) then -- High roll and was high
		rollHighHigh += 1
	end
	if(lastBet.Roll <= 50 and bethigh == true) then -- High roll and was low
		rollHighLow += 1
	end
	if(lastBet.Roll > 50 and bethigh == false) then -- Low roll and was high
		rollLowHigh += 1
	end
	if(lastBet.Roll <= 50 and bethigh == false) then -- Low roll and was low
		rollLowLow += 1
	end

	-- We got a win, let's store some averages
	if(win) then
		-- roundSpent -= lastBet.Amount -- You get your bet back on win
		winCount += 1
		winStreakCount += 1
		if(rollAverageCount == 0) then -- Initialize so we get a good starting average
			for i=0, rollAverageMax do
				rollCountAverage[i] = rollCount
			end
			rollAverageIndex += 1
		else
			rollCountAverage[rollAverageIndex] = rollCount
			rollAverageIndex += 1
		end
		
		rollAverageCount += 1
		if(rollAverageCount >= rollAverageMax) then
			rollAverageCount = rollAverageMax -- no need to keep this one climbing
		end
		if(rollAverageIndex >= rollAverageMax) then
			rollAverageIndex = 0 -- reset 
		end
		if(nextbet >= winBet or nextbet >= lossBet) then
			-- Write to the log file for review
			fin = assert(io.open(filename, "r"))
			content = fin:read("*a")
			-- print(content)
			fin:close()
			
			fout = assert(io.open(tempfile, "w"))
			fout:write(content)
			
			oppositeTemp = ", , Roll #, Value, , , , , , , , , , , , , , , " 
			csvtemp = "Num Rolls, Opposites, High Bets, High High Rolls, High Low Rolls, Low Bets, Low High Rolls, Low Low Rolls, Multiplier, Last Bet, Winning Chance, Winning Roll, Spent, Win Amount, Win Profit, Balance, Run Profit\r\n"
			tempstr = "************************************ Win ************************************\r\n"
			fout:write(tempstr)
			tempstr1 = "Win #: replace\r\n"
			tempstr = string.gsub(tempstr1, "replace", winCount)
			fout:write(tempstr)
			tempstr1 = "Rolls: replace\r\n"
			tempstr = string.gsub(tempstr1, "replace", rollCount)
			csvtemp = string.gsub(csvtemp, "Num Rolls", rollCount)
			fout:write(tempstr)
			tempstr1 = "Opposites: replace\r\n"
			tempstr = string.gsub(tempstr1, "replace", oppositeRolls)
			csvtemp = string.gsub(csvtemp, "Opposites", oppositeRolls)
			fout:write(tempstr)
			oppositeOut = ""
			-- if(oppositeRolls > 0) then
			-- 	for i=0, oppositeRolls - 1 do
			-- 		oppositeOut = oppositeOut .. oppositeTemp
			-- 		tempstr1 = "-- Roll#: rollcount, Value: opposite\r\n"
			-- 		tempstr = string.gsub(tempstr1, "rollcount", oppositeArrayCount[i])
			-- 		oppositeOut = string.gsub(oppositeOut, "Roll #", oppositeArrayCount[i])				
			-- 		tempstr = string.gsub(tempstr, "opposite", oppositeArray[i])
			-- 		oppositeOut = string.gsub(oppositeOut, "Value", oppositeArray[i])
			-- 		oppositeOut = oppositeOut .. "\r\n"
			-- 		fout:write(tempstr)
			-- 	end
			-- end
			tempstr = "High Bets: hightotal, High Rolls: highrolls, Low Rolls: lowrolls\r\n"
			tempstr = string.gsub(tempstr, "hightotal", rollHighHigh + rollHighLow)
			csvtemp = string.gsub(csvtemp, "High Bets", rollHighHigh + rollHighLow)
			tempstr = string.gsub(tempstr, "highrolls", rollHighHigh)
			csvtemp = string.gsub(csvtemp, "High High Rolls", rollHighHigh)
			tempstr = string.gsub(tempstr, "lowrolls", rollHighLow)
			csvtemp = string.gsub(csvtemp, "High Low Rolls", rollHighLow)
			fout:write(tempstr)
			tempstr = "Low Bets: lowtotal, High Rolls: highrolls, Low Rolls: lowrolls\r\n"
			tempstr = string.gsub(tempstr, "lowtotal", rollLowHigh + rollLowLow)
			csvtemp = string.gsub(csvtemp, "Low Bets", rollLowHigh + rollLowLow)
			tempstr = string.gsub(tempstr, "highrolls", rollLowHigh)
			csvtemp = string.gsub(csvtemp, "Low High Rolls", rollLowHigh)
			tempstr = string.gsub(tempstr, "lowrolls", rollLowLow)
			csvtemp = string.gsub(csvtemp, "Low Low Rolls", rollLowLow)
			fout:write(tempstr)
			tempstr1 = "Multiplier: replace / Slots: slots\r\n"
			tempstr = string.gsub(tempstr1, "replace", multiplier)
			tempstr = string.gsub(tempstr, "slots", maxSlots)
			csvtemp = string.gsub(csvtemp, "Multiplier", multiplier)
			fout:write(tempstr)
			tempstr1 = "Last Bet: replace\r\n"
			tempcalc = string.format("%.8f", nextbet)
			tempstr = string.gsub(tempstr1, "replace", tempcalc)
			csvtemp = string.gsub(csvtemp, "Last Bet", tempcalc)
			fout:write(tempstr)
			
			tempstr1 = "Winning Chance: replace\r\n"
			tempcalc = string.format("%.2f", chance)
			tempstr = string.gsub(tempstr1, "replace", tempcalc)
			csvtemp = string.gsub(csvtemp, "Winning Chance", tempcalc)
			fout:write(tempstr)
			tempstr1 = "Winning Roll: replace\r\n"
			tempcalc = string.format("%.2f", lastBet.Roll)
			tempstr = string.gsub(tempstr1, "replace", tempcalc)
			csvtemp = string.gsub(csvtemp, "Winning Roll", tempcalc)
			fout:write(tempstr)
			tempstr1 = "Spent Out:  replace\r\n"
			tempcalc = string.format("%.8f", roundSpent)
			tempstr = string.gsub(tempstr1, "replace", tempcalc)
			csvtemp = string.gsub(csvtemp, "Spent", tempcalc)
			fout:write(tempstr)
			tempstr1 = "Win Amount: replace\r\n"
			tempcalc = string.format("%.8f", lastBet.Profit)
			tempstr = string.gsub(tempstr1, "replace", tempcalc)
			csvtemp = string.gsub(csvtemp, "Win Amount", tempcalc)
			fout:write(tempstr)
			tempstr1 = "Win Profit: replace\r\n"
			tempcalc = string.format("%.8f", lastBet.Profit - roundSpent + lastBet.Amount)
			tempstr = string.gsub(tempstr1, "replace", tempcalc)
			csvtemp = string.gsub(csvtemp, "Win Profit", tempcalc)
			fout:write(tempstr)
			tempstr1 = "Balance: replace\r\n"
			tempcalc = string.format("%.8f", balance)
			tempstr = string.gsub(tempstr1, "replace", tempcalc)
			csvtemp = string.gsub(csvtemp, "Balance", tempcalc)
			fout:write(tempstr)
			tempstr1 = "Run Profit: replace\r\n"
			tempcalc = string.format("%.8f", balance - startingBalance)
			tempstr = string.gsub(tempstr1, "replace", tempcalc)
			csvtemp = string.gsub(csvtemp, "Run Profit", tempcalc)
			fout:write(tempstr)
	
			fout:close()
			os.remove(filename) 
			os.rename(tempfile, filename)
	
			fin = assert(io.open(csvfile, "r"))
			content = fin:read("*a")
			-- print(content)
			fin:close()
			
			fout = assert(io.open(tempfile, "w"))
			fout:write(content)
			fout:write(csvtemp)
			-- fout:write(oppositeOut)
			
			fout:close()
			os.remove(csvfile) 
			os.rename(tempfile, csvfile)
		end
		if(winStreakCount== winStreak) then
			nextbet = winbet
		else
			nextbet = basebet
		end
		
		
		rollCount = 0 -- reset for next rolling
		oppositeRolls = 0
		rollHighHigh = 0 -- reset counters
		rollHighLow = 0 -- reset counters
		rollLowHigh = 0 -- reset counters
		rollLowLow = 0 -- reset counters
		roundSpent = 0
		chance = basechance
		lossStreakCount =0
	end
	
	-- Let's use the averages from previous rolls to see if the bet needs to be changed
	if(!win) then
		lossStreakCount += 1
		if(lossStreakCount == lossStreak) then
			nextbet = lossBet
		end
		if(lossStreakCount > lossStreak) then 
			nextbet = nextbet * multiplier -- Increment bet
		end
		if(lossStreakCount >= stoploss) then
			nextbet = basebet 
		end
		
		oppositeTest = lastBet.Roll
		if(oppositeTest > (100 - chance) and bethigh == false) then -- Test if we were rolling high
			-- print(oppositeTest)
			oppositeArray[oppositeRolls] = oppositeTest
			oppositeArrayCount[oppositeRolls] = rollCount
			oppositeRolls += 1
		end
		if(oppositeTest < chance and bethigh == true) then -- Test if we were rolling low
			-- print(oppositeTest)
			oppositeArray[oppositeRolls] = oppositeTest
			oppositeArrayCount[oppositeRolls] = rollCount
			oppositeRolls += 1
		end
		-- Reset the seed if too long of a losing streak
		rollSeedCount += 1
		if(rollSeedCount > SeedResetMax) then
			-- resetseed()
			rollSeedCount = 0
			seedResets += 1
			-- nextbet = nextbet + basebet -- Increment bet
			-- check to see if we are at our absolute max bet allowed
		end
		
		winStreakCount = 0
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
	sleep(slowdown)

end
