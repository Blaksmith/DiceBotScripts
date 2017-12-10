-- *******************************************************
-- Martingale with logging  
-- Use any of these ref links to support this code: 
-- http://faucetgame.com/r/6490808
-- https://bitvest.io?r=91567
--
-- Script name: Martingale-logging.lua
-- 
--  
-- *******************************************************

-- Default logging goes to the directory where DiceBot is run from.
-- To specify a different log location, you need to edit the 2 lines below.  
-- The two files must be in the same directory!  
filename = "Martingale.log"
csvfile = "Martingale.csv"
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
autotune = true
slowdown = 0.5 -- In seconds.  Set this to 0.0 to run at full speed.  Need to slow down for FreeBitco.in 
basebet = 0.00000001 -- Your starting bet
maxSlots = 21 -- Need to win by this loss run
logroll = 10 -- Only make a log entry after this many or more rolls per win
minmult = 1.75

-- If you want to just play steady, put this at 2.0
multiplier = 2.125 -- Might need to fine tune this one

basechance = 45

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
SeedResetMax = 100 -- Bitsler does not reset the seed anymore anyway
-- SeedResetMax = (98.5 / chance) / 2 -- Just testing for the shorter reset times
seedResets = 0
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

-- Call this routine while it is running to auto-set the multiplier without restarting
-- maxSlots must be set to 0 or autotune set to false for this to stick
function setmult(newmult)
	multiplier = newmult
end

-- Call this routine while it is running to set the number of losses + win in a row 
-- for the multiplier.
-- set to 0 to use use the manually set setmult() routine
function setslots(newslots)
	maxSlots = newslots
end

if(autotune) then
	tempstr = "Setting multiplier for xxx roll loss streak"
	tempstr = string.gsub(tempstr, "xxx", maxSlots)
	print(tempstr)	
end

-- auto calculate the multiplier per the slots requested
function tunemult()
	if(autotune and maxSlots > 0) then
		newmult = multiplier
		oldmult = multiplier
		tuned = false
		-- print("Tuning the multiplier.  Please wait")
		while(tuned == false) do -- start with our current multiplier and test
			-- tempstr = "testing: newmult"
			-- tempstr = string.gsub(tempstr, "newmult", newmult)
			-- print(tempstr)
			-- templow = (newmult ^ (maxSlots + 5)) * (basebet) * 0.1
			-- temphigh = (newmult ^ (maxSlots + 6)) * (basebet) * 0.1
			templow = (newmult * basebet * 100000000) ^ (maxSlots + 1)
			temphigh = (newmult * basebet * 100000000) ^ (maxSlots + 2)
			templow /= 100000000
			temphigh /= 100000000
			tempstr = "Balance: bal, Low: low, High: high"
			tempcalc = string.format("%.8f", balance)
			tempstr = string.gsub(tempstr, "bal", tempcalc)
			tempcalc = string.format("%.8f", templow)
			tempstr = string.gsub(tempstr, "low", tempcalc)
			tempcalc = string.format("%.8f", temphigh)
			tempstr = string.gsub(tempstr, "high", tempcalc)
			-- print(tempstr)
			if(templow <= balance and temphigh >= balance) then
				multiplier = newmult
				-- round to 0.000 instead of 0.0000000000000000				
				multiplier *= 1000 
				multiplier = math.floor(multiplier)
				multiplier /= 1000
				if(multiplier != oldmult) then
					tempstr = "New Multiplier: newmult"
					tempstr = string.gsub(tempstr, "newmult", multiplier)
					print(tempstr)				
				end
				tuned = true
			else
				if(templow >= balance) then -- multiplier is too high
					newmult -= 0.001 -- step down till we find a good value
				end
				if(temphigh <= balance) then -- multiplier is too low
					newmult += 0.001 -- step up till we find a good value
				end 
			end
			if(newmult <= minmult) then -- Lowest we can go for now and still make some profit
				if(oldmult != minmult) then
					print("Lowest multiplier we can go and still profit")
					multiplier = minmult
					tempstr = "New Multiplier: newmult"
					tempstr = string.gsub(tempstr, "newmult", minmult)
					print(tempstr)
				end				
				tuned = true 
			end
			
		end
	end
end

-- Start the actual betting 
function dobet()

	tunemult()

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
		if(rollCount > logroll) then
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
		
		rollCount = 0 -- reset for next rolling
		oppositeRolls = 0
		rollSeedCount = 0 -- Keep this seed for now
		rollHighHigh = 0 -- reset counters
		rollHighLow = 0 -- reset counters
		rollLowHigh = 0 -- reset counters
		rollLowLow = 0 -- reset counters
		seedResets = 0
		roundSpent = 0
		chance = basechance
		nextbet = basebet
	end
	
	-- Let's use the averages from previous rolls to see if the bet needs to be changed
	if(!win) then
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
		nextbet = nextbet * multiplier -- Increment bet
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
