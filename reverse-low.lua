-- Reverse Low strategy

startingBet = 1 -- Enter as whole satoshi
startingChance = 42
minimumChance = 0.45
lossChanceChange = 2.50 -- may need to change a little faster
maxBet = 500 -- Enter as whole satoshi.  Also used for a reset after maxLosscount losses in a row at this value.  
maxLossCount = 3 -- Used with maxBet.  If maxBet has been bet this many times in a row, it resets.
multiplier = 1.75 -- multiplier to increment the bet per loss
useMult = false -- Set this to false to increment each bet by 1, true to use the above multiplier
autoTune = true -- Set to false to use the maxBet value defined above. 
autoPercent = 0.0099 -- Percent of your current balance for maxBet for autoTune (x 100.  0.015 = 1.5%)

-- No need to change anything after this 

filename = "reverse-low.log"
csvfile = "reverse-low.csv"
tempfile = "tempfile.log"

satoshi = 0.00000001

oppositeRolls = 0
oppositeArray = {}
oppositeArrayCount = {}
lastWinRollCount = 0
currentRollCount = 0
rollCount = 0
rollCountAverage = {}
rollAverageCount = 0
rollAverageIndex = 0
rollAverageMax = 4 -- Average roll count before a win.  How many wins do you want to average? 
maxLossCounter = 0
startingBet *= satoshi
maxBet *= satoshi
chance = startingChance
nextbet = startingBet

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

function dobet()

	currentRollCount += 1
	rollCount += 1
	roundSpent += lastBet.Amount


	-- auto tuning routine
	if(autoTune) then
		maxBet = balance * autoPercent
	end

	-- Win 
	if(win) then

		if(rollAverageCount == 0) then -- Initialize so we get a good starting average
			for i=0, rollAverageMax do
				rollCountAverage[i] = rollCount
			end
			rollAverageIndex += 1
		else
			rollCountAverage[rollAverageIndex] = rollCount
			rollAverageIndex += 1
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


		-- reset everything
		chance = startingChance
		nextbet = startingBet -- should never need to change for now
		maxLossCounter = 0
		rollCount = 0 -- reset for next rolling
		oppositeRolls = 0
	end
	
	-- Loss
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

			oppositeTemp = ", , Roll #, Value, , , , , , , , , , , , , , , " 
			csvtemp = "Num Rolls, Opposites, High Bets, High High Rolls, High Low Rolls, Low Bets, Low High Rolls, Low Low Rolls, Seed Resets, Last Bet, Winning Chance, Winning Roll, Spent, Win Amount, Win Profit, Balance, Run Profit\r\n"
			tempstr = "*********************************** Loss ************************************\r\n"
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
			tempstr1 = "Spent Out:  replace\r\n"
			tempcalc = string.format("%.8f", roundSpent)
			tempstr = string.gsub(tempstr1, "replace", tempcalc)
			csvtemp = string.gsub(csvtemp, "Spent", tempcalc)
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
