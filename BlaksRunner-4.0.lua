-- Blak's Runner V4.0
-- Constant Profit on every win with tipping and logging
--
-- This script tries to win at least "Payout X Amount" over what has been spent for every win.
--
-- For example, basechance of 1.2345 = 96.680 payout X, so every win will be "Around" 96 above what was spent.
-- Due to the decimal point resolution, it will never be exact.  It may be more or less than the Payout X.
-- 
-- basechance > 25, may result in negative payouts on long red runs, but short runs will still be positive.
--
-- basechance can be used in the console during run-time to change your payout after the next win.
-- Example: basechance = 0.2048
-- That will change your payout to 483.3984 after the next win.
--
-- incDivisor variable: Controls winMult calculation based on your balance
-- Changing this variable is not advisable
-- Any balance under 1 million sats (or 1 million tokens on Bitvest) will result in a starting bet of 1
-- Any balance over 1 million will result in a starting run bet of 1 + balance / incDivisor
-- Example: balance = 1125678, winMult would be 1.12 ... or balance = 2345678, winmult would be 2.34
--
-- If there are more than Payout X number of losing rolls, then the winMult is set to 1, to just get 
-- through this streak without busting, but will still profit around Payout X amount.
--
-- Example: balance = 2345678, basechance = 9.9 = Payout X of 10.00, First 10 rolls, winMult = 2.34.    
-- after 10 losing rolls, the winMult value will be forced to 1.0, resulting in an overall profit of around 10, instead of 23.4
--
-- Version 4.0 additions:
-- chanceInc = how much to increase your chance % per roll after Payout X of losing rolls.  
-- 
-- Varying chance depending on the value of the last 8 wins (Adjustable by changing the value of "averageMax")
-- Chance is currently capped at 1.5 X basechance
-- Chance is only changed upon every win.
-- Using default basechance of 9.9, The first streak will be 9.9, but the next few will most likely be around 14.85, until 
-- the average win result amount is below basechance.
--
-- High / Low betting switches every Payout X loss rolls.  Counter resets after a win.
--
-- siteMaxProfit is a new variable to cap the bet so that the win amount will be less or equal to this value.  
-- Not all sites need this, but is mainly for new sites that have low bankroll, and low max profit values.


isTokens = false -- Used for Bitvest tokens
basechance = 9.9 -- The starting chance that you would like use. 
chanceInc = 0.0010 -- How much to increase chance on a bad run
incDivisor = 1000000 -- When to start raising winMult (12.5 million seems safe so far)
siteMaxProfit = 0.00000000 -- Set to the max profit of the site.  Set to 0 to disable.  This will make sure the profit of the bet will never go above this value if set
-- ***************** IMPORTANT TO CHANGE THESE SETTINGS BEFORE ENABLING OR YOU WILL TIP ME ***********************
autotip = false -- If the isTokens is true, tipping is automatically turned off
-- With auto tip enabled, It will auto tip to your named 
-- alt account when your balance is above bankroll + tipamount 
-- On BitVest, minimum 10k BTC, 50k ETH, and 100k LTC
bankroll = 0 -- Minimum you want to keep rolling with.  Set to 0 to use your current balance 
tipamount = 0.0001 -- How much to tip
bankappend = 0.10 -- How much of your tip amount to add to your bankroll over time in %.  0.10 = 10% Set to 0 for no addition to the bankroll 
receiver = "BlaksBank" -- Who gets the tip? **** CHANGE THIS ****
-- ^^^^^^ CHANGE THE ABOVE VALUE!!!!! ^^^^^^

restTime = 0.0 -- How long to wait in seconds before the next bet.  Some sites need this
			   -- Bitvest setting 0.75 for low bet values



maxWinMult = 256 -- Max multiplier to hit.  siteMaxProfit can lower this value Set to 0 to disable

housePercent = 1 -- Set this according to the site you are on.
-- Known site percentages
-- Freebitco.in = 5%
-- Bitsler = 1.5%
-- Bitvest = 1.0% 

maxbet = 0 -- raise for higher betting.  10x basebet seems good so far.  Set to 0 to disable
minbet = 1 -- Use whole integers
basebet = 1 -- Use whole integers

tippedOut = 0

-- *************** This will create a log file in the directory where dicebot is run from! *****************

enableLogging = true -- Set to false for no logging
appendlog = false -- This must be set to false for the very first run!
filename = "martingale.csv" -- Default to the directory where dicebot is run from.
tempfile = "tempfile.log" -- You can add an absolute directory if wanted with: C:\directory etc
rollLog = 50 -- Use 0 for dynamic long streak logging, otherwise put in a value to log after X losing streak

-- Should not need to change anything below this line

chanceMult = 1.6666
chanceMax = 1.5

tempCalc = balance
if(isTokens == false) then
	tempCalc = tempCalc * 100000000
end
tempMult = tempCalc / incDivisor
if(tempMult < 1) then tempMult = 1 end		
winMult = tempMult

totalProfit = 0
winMult = 1 -- Multiplier for X times over chance win
tempWinMult = winMult
incroll = 0
startBalance = balance

print(string.format("Starting Win Multiplier: %.2f", tempWinMult))
if(bankroll == 0) then
	bankroll = balance
end

if(isTokens == false) then
	minbet = minbet * 0.00000001
	basebet = basebet * 0.00000001
	maxbet = maxbet * 0.00000001
	-- minWinAmount = minWinAmount * 0.00000001
end

local clock = os.clock
function sleep(n)  -- seconds
	local t0 = clock()
	while clock() - t0 <= n do end
end

oldBaseChance = 0
currentStep = 0
lossCount = 0
stepCount = 0
spent = 0

highLowLossCount = 0
highLowAverage = {}
averageCount = 0
averageIndex = 0
averageMax = 8 -- High / Low average switching. 
	
rollCount = 0
rollSeedCount = 0
profit = 0

if(appendlog != true) then
	fin = assert(io.open(filename, "w"))
	fin:write("Timestamp, Bet ID, Streak, Bet, Chance, Spent, Win Amount, Win Profit\n")
	fin:close()
end
	
-- Initialize the array
for i=0, averageMax do
	highLowAverage[i] = basechance
end

function calcChance()
	if(oldBaseChance == 0) then oldBaseChance = basechance end
		if(win) then
		if(lastBet.Roll >= 50) then 
			target = 100 - lastBet.Roll
		else
			target = lastBet.Roll
		end
		highLowAverage[averageCount] = target
		averageCount = averageCount + 1
		if(averageCount >= averageMax) then averageCount = 0 end
		tempAverage = 0
		for i=0, averageMax do
			tempAverage = tempAverage + highLowAverage[i]
		end
		tempAverage = tempAverage / averageMax
		chance = tempAverage * chanceMult 
		if(chance > (oldBaseChance * chanceMax)) then chance = oldBaseChance * chanceMax end
		tempcalc = string.format("Temp Average: %.4f / chance: %.4f", tempAverage, chance)
		print(tempcalc)
	else
		winAmount = (100 - (100 * (housePercent / 100))) / chance -- how much you will win for a 1 bet
		if(lossCount > winAmount) then
			chance = chance + chanceInc
			tempcalc = string.format("New chance: %.4f", chance)
			-- print(tempcalc)
		end
	end
end

function autoTune()
	-- Auto tune to win at least minWinAmount
	tempstr = "Win Amount: winAmount, Needed: amtNeeded, Next Mult: nextmult, Next Bet: nextbet"
	winAmount = (100 - (100 * (housePercent / 100))) / chance -- how much you will win for a 1 bet
	if(isTokens == false) then
		winAmount = winAmount * 0.00000001
	end
	tempcalc = string.format("%.8f", winAmount)
	tempstr = string.gsub(tempstr, "winAmount", tempcalc)
	tempcalc = 1 + ((chance / 100) * ((100 - housePercent) / ((100 - housePercent) / 2)))
	needed = (winAmount * tempWinMult) + (nextbet * tempcalc) + spent -- No need to go by balance for next bet.  Only how much has been spent.  Will allow tipping and not accidentally bust
	
	
	tempcalc = string.format("%.8f", needed)
	tempstr = string.gsub(tempstr, "amtNeeded", tempcalc)
	-- print(string.format("%.8f", needed))
	nextMult = needed / winAmount
	tempcalc = string.format("%.8f", nextMult)
	tempstr = string.gsub(tempstr, "nextmult", tempcalc)
	-- print(string.format("%.8f", nextMult))
	if(nextMult < 1) then nextMult = 1 end
	nextbet = basebet * nextMult
	if((winAmount * nextbet) - nextbet > siteMaxProfit and siteMaxProfit != 0) then
		nextbet = siteMaxProfit / winAmount
	end
	tempcalc = string.format("%.8f", nextbet)
	tempstr = string.gsub(tempstr, "nextbet", tempcalc)
	-- print(tempstr)
	if nextbet > maxbet and maxbet != 0 then
		nextbet = maxbet
	end
	if(tippedOut == 1) then
		nextbet = basebet
		tippedOut = 0
		startBalance = balance
	end
end

chance = basechance
nextbet=basebet
autoTune()

function dobet()

	if(enableLogging == true) then
		if(lastBet.Roll >= 99.9 or lastBet.Roll <= 0.10) then
			tempstr = "year-0month-0day 0hour:0minute:0second, betid, roll, highlo\n"
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
			-- fout:write(oppositeOut)
			
			fout:close()
			os.remove(filename) 
			os.rename(tempfile, filename)
		end
	end
	
	if win then
		logTest = rollLog
		if(rollLog == 0) then
			logTest = (100 - (100 * (housePercent / 100))) / chance
		end
		-- print(logTest)
		tipvalue = bankroll + tipamount + (tipamount * bankappend)
		pct = ((balance - bankroll) / (tipvalue - bankroll)) * 100
		if isTokens == false and autotip == true then
			print(string.format("Percent of next tip won: %.2f", pct))
		end
		if(enableLogging == true and lossCount >= logTest) then
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

		totalProfit = totalProfit + (lastBet.Profit - spent)
		print(string.format("Total Profit: %.8f", totalProfit))

		stepCount = 0 -- reset
		spent = 0
		highLowLossCount = 0
		startBalance = balance
		tempCalc = balance
		if(isTokens == false) then
			tempCalc = tempCalc * 100000000
		end
		tempMult = tempCalc / incDivisor

		if(tempMult < 1) then tempMult = 1 end		
		winMult = tempMult
		if(winMult > maxWinMult and maxWinMult != 0) then winMult = maxWinMult end
		if(tempWinMult != winMult) then
			print(string.format("New Win Multiplier: %.2f", winMult))
			tempWinMult = winMult
		end
		nextbet = basebet
		calcChance()
		autoTune()
	else -- if lose
		lossCount += 1
		highLowLossCount += 1
		spent += nextbet

		winTemp = (100 - (100 * (housePercent / 100))) / chance -- how much you will win for a 1 bet
		if(highLowLossCount >= winTemp) then
			if(bethigh == true) then
				bethigh = false
			else
				bethigh = true
			end
			if(lossCount >= winTemp * 2) then
			-- if(tempWinMult > 1) then
				-- tempWinMult = tempWinMult - 1
				-- tempWinMult = tempWinMult / 2
				if(tempWinMult > 1) then
					tempWinMult = 1 -- Abort the high value, and go minimum for now
					if(tempWinMult < 1) then tempWinMult = 1 end
					print(string.format("New Win Multiplier: %.2f", tempWinMult))
				end
			end
			highLowLossCount = 0
		end
		calcChance()
		autoTune()
				
		if nextbet >= balance then -- Keep rolling, without completely busting.  May add flag to disable
			if(enableLogging == true) then
				tempstr = "year-0month-0day 0hour:0minute:0second, betid, streak, bet, chance, spent, winamount, profit, roll, highlo *******LOSING STOP*******\n"
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
			print("Balance too low for the bet.  Stopping.")
			stop()
			print("Resetting")
			chance = basechance
			lossCount = 0 -- reset
			nextbet = basebet -- reset
			stepCount = 0 -- reset
			spent = 0
			
		end
	end

	if(autotip == true and isTokens == false) then
		if(balance > bankroll + tipamount + (tipamount * bankappend)) then
			preTipBalance = balance
			tip(receiver, balance - bankroll - (tipamount * bankappend))
			sleep(5)
			bankroll += (tipamount * bankappend)
			tempstr = "New Bankroll: banker"
			tempstr = string.gsub(tempstr, "banker", bankroll)
			print(tempstr)
			tippedOut = 1			
		end 
	end

	sleep(restTime)

end