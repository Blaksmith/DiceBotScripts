huntBet = 100 -- Use whole numbers
minbet = 1 -- Use whole numbers
maxbet =  0 -- Use whole numbers

huntMult = 5
maxLossCount = 0 -- Max number of Payout X rolls before aborting

seekChance = 98 -- Change for the site's max chance
lowChance = 0.0001 -- lowest chance the site can go down to

-- minChance = 2.50
chanceInc = 0.010 -- How much to increase chance on a bad run
incDivisor = 1000000 -- When to start raising winMult (12.5 million seems safe so far)
siteMaxProfit = 0.0000000 -- Set to the max profit of the site.  Set to 0 to disable.  This will make sure the profit of the bet will never go above this value if set

isTokens = false -- Set to true for Bitvest tokens
toggleHiLo = false -- Auto toggle high / low hunting
startHigh = false -- Start high or low
abortHuntFlag = false

logWins = true -- Set to false to not store wins to a file
enableLogging = true -- Set to false for no logging
appendlog = false -- This must be set to false for the very first run!

filename = "hunting.csv" -- Default to the directory where dicebot is run from.
tempfile = "tempfile.log" -- You can add an absolute directory if wanted with: C:\directory etc

simSkip = 1 -- Set higher for long-term simulation testing
resetCount = 1
-- ***************** IMPORTANT TO CHANGE THESE SETTINGS BEFORE ENABLING OR YOU WILL TIP ME ***********************
autotip = false -- If the isTokens is true, tipping is automatically turned off
-- With auto tip enabled, It will auto tip to your named 
-- alt account when your balance is above bankroll + tipamount 
-- On BitVest, minimum 10k BTC, 50k ETH, and 100k LTC
bankroll = 0.00-- Minimum you want to keep rolling with.  Set to 0 to use your current balance 
tipamount = 0.001 -- How much to tip
bankappend = 0.10 -- How much of your tip amount to add to your bankroll over time in %.  0.10 = 10% Set to 0 for no addition to the bankroll 
receiver = "BlaksBank" -- Who gets the tip? **** CHANGE THIS ****
-- ^^^^^^ CHANGE THE ABOVE VALUE!!!!! ^^^^^^

-- Initialize rutime variables
roundCount = 0
rollCount = 0
runProfit = 0
biggestArray = {}
isHunting = false
startHunt = 24.42
stopHunt = 42.27
abortHunt = 4.27
abortLoss = 10000
huntCount = 0
basebet = huntBet
basechance = seekChance
baseHuntMult = huntMult
roundLowest = 99.9999
-- targetAverage = 100 -- starting value

winCount = 0
spent = 0
roundSpent = 0
housePercent = 1
winMult = 1
maxWinMult = 1024 -- Balance * 0.002 -- 512 -- Max multiplier to hit.  siteMaxProfit can lower this value Set to 0 to disable
lossCount = 0
highLowLossCount = 0
highLowAverage = {}
averageCount = 0
averageIndex = 0
averageMax = 8 -- High / Low average switching. 

lastStoredBet = 0

rollHistory = {}
rollHistoryCount = 7 -- How many to store / show
rollHistoryLoc = 0

rollAverage = {}
rollAverageCount = 64
rollAverageIndex = 0 

runState = 0 -- Starting state 
totalWager = 0
oldBaseChance = 0
chanceMult = 1.6666
chanceMax = 1.5
-- tempWinMult = 0
tempCalc = balance
tippedOut = 0
totalTipped = 0
pct = 0
toTip = 0
lastUpdate = false
if(isTokens == false) then
	tempCalc = tempCalc * 100000000
	minbet = minbet * 0.00000001
	basebet = basebet * 0.00000001
	maxbet = maxbet * 0.00000001
	-- minWinAmount = minWinAmount * 0.00000001
end

-- Initialize the array
for i=0, averageMax do
	highLowAverage[i] = basechance
end

for i=0, rollAverageCount do
	rollAverage[i] = 100
end

if(appendlog != true) then
	fin = assert(io.open(filename, "w"))
	fin:write("Timestamp, Bet ID, Streak, Bet, Chance, Spent, Win Amount, Win Profit\n")
	fin:close()
end

for i=0, 7 do
	biggestArray[i] = {}
	biggestArray[i][0] = 0 -- Biggest Win Amount
	biggestArray[i][1] = 0 -- Biggest Win Bet ID
	biggestArray[i][2] = 0 -- Biggest Win roll Count
	biggestArray[i][3] = 0 -- Last win Chance
	if(i == 4) then biggestArray[i][0] = 99.9999 end
end

for i = 0, rollHistoryCount do
	rollHistory[i] = {}
	rollHistory[i][0] = 0 -- Roll ID
	rollHistory[i][1] = 0 -- Roll Amount
	rollHistory[i][2] = 0 -- Roll Chance
	rollHistory[i][3] = 0 -- Roll High
	rollHistory[i][4] = 0 -- Roll Profit
	rollHistory[i][5] = 0 -- Roll Result
end

nextbet=basebet
chance=basechance
bethigh=startHigh
print(string.format("Amount: %.8f Chance: %.4f", nextbet, chance))

local clock = os.clock
function sleep(n)  -- seconds
	local t0 = clock()
	while clock() - t0 <= n do end
end

function updateRoundStats()

	if(lastBet.Profit + lastBet.Amount >= biggestArray[1][0] and isHunting == true) then  
		biggestArray[1][0] = lastBet.Profit + lastBet.Amount
		if(lastBet.Currency != "simulation") then biggestArray[1][1] = lastBet.Id end
		biggestArray[1][2] = lossCount
	end

	if(lastBet.Amount >= biggestArray[0][0] and isHunting == true) then  
		biggestArray[0][0] = lastBet.Amount
		if(lastBet.Currency != "simulation") then biggestArray[0][1] = lastBet.Id end
		biggestArray[0][2] = lossCount
	end

	if(lastBet.Profit <= biggestArray[2][0] and isHunting == true) then  
		biggestArray[2][0] = lastBet.Profit
		if(lastBet.Currency != "simulation") then biggestArray[2][1] = lastBet.Id end
		biggestArray[2][2] = lossCount
	end
	
	if(lastBet.Profit > 0 and isHunting == true) then  
		biggestArray[3][0] = lastBet.Profit + lastBet.Amount
		if(lastBet.Currency != "simulation") then biggestArray[3][1] = lastBet.Id end
		biggestArray[3][2] = lossCount
		biggestArray[3][3] = lastBet.Chance
	end

	if(lastBet.Roll <= biggestArray[4][0] and isHunting == true) then  
		biggestArray[4][0] = lastBet.Roll
		if(lastBet.Currency != "simulation") then biggestArray[4][1] = lastBet.Id end
		biggestArray[4][2] = lossCount
	end

	if(lastBet.Profit >= biggestArray[5][0] and isHunting == true) then  
		biggestArray[5][0] = lastBet.Profit
		if(lastBet.Currency != "simulation") then biggestArray[5][1] = lastBet.Id end
		biggestArray[5][2] = lossCount
	end

	if(roundSpent >= biggestArray[6][0]) then  
		biggestArray[6][0] = roundSpent
	end
	
	if(lossCount >= biggestArray[7][0]) then
		biggestArray[7][0] = lossCount
	end
	
	if(lastBet.Roll < roundLowest) then
		roundLowest = lastBet.Roll
	end
end

function logWin()
	tempstr = "year-0month-0day 0hour:0minute:0second, betid, streak, bet, chance, spent, winamount, profit, roll, highlo\n"
	tempstr = string.gsub(tempstr, "year", lastBet.date.year)
	if (lastBet.date.month >= 10) then tempstr = string.gsub(tempstr, "0month", "month") end 	
	if (lastBet.date.day >= 10) then tempstr = string.gsub(tempstr, "0day", "day") end 	
	if (lastBet.date.hour >= 10) then tempstr = string.gsub(tempstr, "0hour", "hour") end 	
	if (lastBet.date.minute >= 10) then tempstr = string.gsub(tempstr, "0minute", "minute") end 	
	if (lastBet.date.second >= 10) then tempstr = string.gsub(tempstr, "0second", "second") end 	
	tempstr = string.gsub(tempstr, "month", lastBet.date.month)			
	tempstr = string.gsub(tempstr, "day", lastBet.date.day)			
	tempstr = string.gsub(tempstr, "hour", lastBet.date.hour)			
	tempstr = string.gsub(tempstr, "minute", lastBet.date.minute)			
	tempstr = string.gsub(tempstr, "second", lastBet.date.second)
	tempstr = string.gsub(tempstr, "betid", lastBet.Id)
	if(lossCount < 1000) then tempstr = string.gsub(tempstr, "streak", " streak") end
	if(lossCount < 100) then tempstr = string.gsub(tempstr, "streak", " streak") end
	if(lossCount < 10) then tempstr = string.gsub(tempstr, "streak", " streak") end
	tempstr = string.gsub(tempstr, "streak", lossCount)
	tempcalc = string.format("%.8f", nextbet)
	tempstr = string.gsub(tempstr, "bet", tempcalc)
	tempcalc = string.format("%.2f", chance)
	tempstr = string.gsub(tempstr, "chance", tempcalc)
	tempcalc = string.format("%.8f", spent)
	tempstr = string.gsub(tempstr, "spent", tempcalc)
	tempcalc = string.format("%.8f", lastBet.Profit)
	tempstr = string.gsub(tempstr, "winamount", tempcalc)
	profit = lastBet.Profit - spent
	tempcalc = string.format("%.8f", profit)
	tempstr = string.gsub(tempstr, "profit", tempcalc)
	tempstr = string.gsub(tempstr, "roll", lastBet.Roll)
	if(bethigh == true) then
		tempstr = string.gsub(tempstr, "highlo", "Betting High")
	else
		tempstr = string.gsub(tempstr, "highlo", "Betting Low")
	end

	fin = assert(io.open(filename, "r"))
	content = fin:read("*a")
	fin:close()
	
	fout = assert(io.open(tempfile, "w"))
	fout:write(content)
	fout:write(tempstr)
	
	fout:close()
	os.remove(filename) 
	os.rename(tempfile, filename)
end

function autoTune()
	winAmount = (100 - (100 * (housePercent / 100))) / chance -- how much you will win for a 1 bet
	winWhole = winAmount
	
	if(lastBet.Roll >= 50) then 
		target = 100 - lastBet.Roll
	else
		target = lastBet.Roll
	end

	rollAverage[rollAverageIndex] = target
	rollAverageIndex = rollAverageIndex + 1
	if(rollAverageIndex >= rollAverageCount) then rollAverageIndex = 0 end
	
	targetAverage = 0
	for i=0, rollAverageCount do
		targetAverage = targetAverage + rollAverage[i]
	end
	targetAverage = targetAverage / rollAverageCount
	
	if(isTokens == false) then
		winAmount = winAmount * 0.00000001
	end
	if(isHunting == false) then
		-- sleep(0.125)
		if(Win == false) then
			tempcalc = 1 + ((chance / 100) * ((100 - housePercent) / ((100 - housePercent) / 2)))
			needed = (winAmount * 1) + (nextbet * tempcalc) + spent -- No need to go by balance for next bet. 
			nextMult = needed / winAmount
			
			if(nextbet >= balance) then 
				resetCount = resetCount * 2
				nextbet = basebet * resetCount
				print(string.format("Seek bet too large!  resetting. ResetCount: %d", resetCount))
				-- sleep(10)
			end
		else
			if(targetAverage < startHunt) then
					tempcalc = startHunt / lowChance
					chance = targetAverage / startHunt / tempcalc * (abortHunt * 80) -- 5000 -- Use average to determine how big of a hunt chance
					chance = roundLowest -- biggestArray[4][0]
					if(chance < lowChance) then chance = lowChance end
					nextbet = minbet * huntMult
					-- print(string.format("starting hunt - huntMult: %d               ", huntMult))
					isHunting = true
					spent = 0
					huntCount = 0
			else
				chance = seekChance
				huntCount = 0
				
			end
			if(isHunting == false) then nextbet = basebet * resetCount end
			
			
		end
	else
		resetCount = 1
		if(win == true) then -- reset? 
			isHunting = false
			roundCount = roundCount + 1
			for i=0, rollAverageCount do
				rollAverage[i] = 100
			end
			nextbet = basebet * resetCount
			chance = seekChance
			roundCount = roundCount + 1
			roundLowest = 99.999 -- reset for next round
			if(lastBet.Amount == minbet * huntMult) then
				-- huntMult = huntMult + 1
			else
				-- huntMult = baseHuntMult
			end
			-- print(string.format("huntMult: %d               ", huntMult))
			
		else
			-- Add code to not dig too deep before trying to hunt again 
			winTemp = (100 - (100 * (housePercent / 100))) / chance -- how much you will win for a 1 bet
			winTemp = winTemp * minbet -- * huntMult
			if(spent >= winTemp * maxLossCount and maxLossCount != 0 and abortHuntFlag == true) then
				isHunting = false
				for i=0, rollAverageCount do
					rollAverage[i] = 100
				end
				huntCount = 0
				chance = seekChance
				nextbet = basebet * resetCount
				roundCount = roundCount + 1
				print("Aborting hunt roll count               ")
				sleep(10)
			end
			if(targetAverage >= stopHunt and isHunting == true and abortHuntFlag == true) then -- reset to seeking
				chance = seekChance
				nextbet = basebet * resetCount
				isHunting = false
				for i=0, rollAverageCount do
					rollAverage[i] = 100
				end
				huntCount = 0
				roundCount = roundCount + 1
				print("Aborting hunt: target average               ")
				sleep(10)
			else
				huntCount = huntCount + 1
				huntAmount = huntCount / winWhole
				-- huntWhole = huntAmount
				if(huntAmount > abortHunt and abortHuntFlag == true) then
					chance = seekChance
					nextbet = basebet * resetCount
					isHunting = false
					for i=0, rollAverageCount do
						rollAverage[i] = 100
					end
					huntCount = 0
					print("Aborting hunt: huntAmount               ")
					sleep(10)
				else
					-- print(string.format("winTemp: %.8f           ", winTemp))
					tempBet = spent / winTemp * 0.25
					if(tempBet < 1) then tempBet = 1 end
					if(isTokens == false) then huntAmount = huntAmount * 0.00000001 end
					if(huntAmount < minbet) then huntAmount = minbet end
					-- huntAmount = huntAmount * abortHunt -- change later
					huntAmount = minbet * tempBet * huntMult
					nextbet = huntAmount --  * huntMult -- change later?
					if(chance <= lowChance) then 
						chance = lowChance
						-- Possibly add abort code here
					end
					if(huntAmount >= maxbet and maxbet != 0) then 
						chance = seekChance
						nextbet = basebet * resetCount
						isHunting = false
						for i=0, rollAverageCount do
							rollAverage[i] = 100
						end
						huntCount = 0
						print("Aborting hunt: Max Bet               ")
					end
					chance = chance + 0.0001 -- May tweak this later.
				end
			end
		end
	end
	if((winWhole * nextbet) > siteMaxProfit and siteMaxProfit != 0) then
		nextbet = siteMaxProfit / winWhole
	end
	if nextbet > maxbet and maxbet != 0 and isHunting == true then
		nextbet = maxbet
	end
	if nextbet > balance then
		lastUpdate = true
		stop() -- Abort and stop betting
	end
end

function checkTip()
	if(bankroll == 0 or tippedOut == 1) then 
		tippedOut = 0
		bankroll = balance 
		tempstr = string.format("\r\nNew bankroll set to: %.8f", bankroll)
		print(tempstr)
	end
	if(autotip == true and isTokens == false and bankroll != 0) then
		if(balance > bankroll + tipamount + (tipamount * bankappend)) then
			toTip = balance - bankroll - (tipamount * bankappend)
			totalTipped = totalTipped + toTip
			preTipBalance = balance
			tip(receiver, toTip)
			postTipBalance = balance
			bankroll = bankroll + (tipamount * bankappend)
			tempstr = string.format("\r\n\r\nWould have Tipped %.8f to %s!\r\nTotal Tipped: %.8f", toTip, receiver, totalTipped)
			tippedOut = 1
		end 
		tipvalue = bankroll + tipamount + (tipamount * bankappend)
		pct = ((balance - bankroll) / (tipvalue - bankroll)) * 100
		if(win and isHunting == true) then
			tempstr = string.format("Percent towards tip: %.2f to %s! ... Total Tipped: %.8f", pct, receiver, totalTipped)
			print(tempstr)
		end
	end
end


function dobet()

	spent = spent + nextbet
	updateRoundStats(PreviousBet)
	checkTip()

	if win then -- Process a win
		
		-- Reset counters
		if(isHunting == true) then
			logWin()
		else
			roundSpent = 0 
		end

		spent = 0
		winCount = winCount + 1
		lossCount = 0
		startBalance = balance
	
	else -- Process a loss
		lossCount = lossCount + 1
		highLowLossCount = highLowLossCount + 1

		-- Toggle high/low code
		if(toggleHiLo == true) then
			highLowAverage[averageCount] = lastBet.Roll
			averageCount = averageCount + 1
			if(averageCount >= averageMax) then averageCount = 0 end
			tempAverage = 0
			for i=0, averageMax do
				tempAverage = tempAverage + highLowAverage[i]
			end
			tempAverage = tempAverage / averageMax
			if(tempAverage > 50) then
				bethigh = true
			else
				bethigh = false
			end
		end
	end
	
	rollCount = rollCount + 1
 	autoTune()
end

