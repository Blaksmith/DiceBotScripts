-- *******************************************************
-- Roxy Style, from how I play on FaucetGame.  
-- Use this ref link to support this code: http://faucetgame.com/r/6490808
--
-- Script name: Roxy-style.lua
-- 
--  
-- *******************************************************

-- Default logging goes to the directory where DiceBot is run from.
-- To specify a different log location, you need to edit the 2 lines below.  
-- The two files must be in the same directory!  
filename = "roxy-style.log"
csvfile = "roxy-style.csv"
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
fin:write("Rolls, Opposites, High Bets, High Rolls, Low Rolls, Low Bets, High Rolls, Low Rolls, Seed Resets, Last Bet, Winning Chance, Winning Roll, Spent, Win Amount, Win Profit, Balance, Run Profit\n")
fin:close()
-- ************************************
-- Comment the above 3 lines if you want to append to the old file
-- These 3 lines must be un-commented on the very first run, otherwise
-- the script will crash with a LUA error, due to the file not existing.
-- ************************************

-- initialize custom settings
basebet = 0.00000001 -- Your starting bet

-- maxbetReset is where you reset to base bet on a win, if your last bet was over this value
-- This is not a limiter for your actual max bet!
-- This script has no upper limit for the actual bet.
maxbetReset  = 0.00000005 -- Max bet you want to test for the reset to base bet.  

-- maxbet is for the absolute max bet value, and start ramping up the chance.
-- default is 0.1% of your starting balance. 0.001
-- Once that value is hit, it will start raising the chance to try and recover some of it with a win
maxbet = balance * 0.001

-- Make sure this value is at least your maxbetReset value
if(maxbetReset > maxbet) then
	maxbet = maxbetReset
end
recoverPercent = 0.10 -- increase chance by default of 0.01

-- If you want to just play steady, put this at 1.0
-- At 1.0, your bet will never change from your basebet value
multiplyer = 2.0 -- Might need to fine tune this one

-- Change this for harder or easier wins.  Going too big on this number will result in loss
-- chance = 0.4459 -- pays out 219 per single sat bet
-- chance = 0.44 -- pays out 224 per single sat bet
-- chance = 0.40 -- pays out 227 per single sat bet
-- chance = 4.4 -- pays out 22 per single sat bet
basechance = 0.40

-- Set this to false if you want to keep the previous bet amount after a win, if it is not over "maxbetReset" value
resetAfterWin = true 

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
-- SeedResetMax = 100
SeedResetMax = (98.5 / chance) / 2 -- Just testing for the shorter reset times
seedResets = 0
roundSpent = 0

-- Initialize system settings
nextbet = basebet
chance = basechance

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
rollAverageMax = 8 -- Average roll count before a win.  How many wins do you want to average? 

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
		-- Write to the log file for review
		fin = assert(io.open(filename, "r"))
		content = fin:read("*a")
		-- print(content)
		fin:close()
		
		fout = assert(io.open(tempfile, "w"))
		fout:write(content)
		
		oppositeTemp = ", , Roll #, Value, , , , , , , , , , , , , , , " 
		csvtemp = "Num Rolls, Opposites, High Bets, High High Rolls, High Low Rolls, Low Bets, Low High Rolls, Low Low Rolls, Seed Resets, Last Bet, Winning Chance, Winning Roll, Spent, Win Amount, Win Profit, Balance, Run Profit\r\n"
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
		if(oppositeRolls > 0) then
			for i=0, oppositeRolls - 1 do
				oppositeOut = oppositeOut .. oppositeTemp
				tempstr1 = "-- Roll#: rollcount, Value: opposite\r\n"
				tempstr = string.gsub(tempstr1, "rollcount", oppositeArrayCount[i])
				oppositeOut = string.gsub(oppositeOut, "Roll #", oppositeArrayCount[i])				
				tempstr = string.gsub(tempstr, "opposite", oppositeArray[i])
				oppositeOut = string.gsub(oppositeOut, "Value", oppositeArray[i])
				oppositeOut = oppositeOut .. "\r\n"
				fout:write(tempstr)
			end
		end
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
		tempstr1 = "Seed Resets: replace\r\n"
		tempstr = string.gsub(tempstr1, "replace", seedResets)
		csvtemp = string.gsub(csvtemp, "Seed Resets", seedResets)
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
		tempcalc = string.format("%.8f", lastBet.Profit - roundSpent)
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
		if(resetAfterWin == true) then -- Reset to base bet after a win 
			nextbet = basebet
		end
		if(nextbet >= maxbetReset) then -- Keep current bet for an experiment
			nextbet = basebet
		end
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
			resetseed()
			rollSeedCount = 0
			seedResets += 1
			-- nextbet = nextbet + basebet -- Increment bet
			nextbet = nextbet * multiplyer -- Increment bet
			-- check to see if we are at our absolute max bet allowed
			if(nextbet >= maxbet) then
				nextbet = maxbet
			end
		end
		-- start increasing the winning chance until we hit
		if(nextbet == maxbet) then 
			chance = chance + recoverPercent
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


end
