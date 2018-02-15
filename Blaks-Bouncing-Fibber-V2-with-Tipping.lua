-- Blak's Bouncing Fibber (Fibonacci)
-- constants

isTokens = false
autotune = false -- Set to false to use static settings below
smoothRecover = false -- set this to false to just stop betting when nextbet is greater than your balance
resetOnBust = true -- Set this to false to just let it stop betting on bust

-- ***************** IMPORTANT TO CHANGE THESE SETTINGS OR YOU WILL TIP ME ***********************
autotip = true -- If the isTokens is true, tipping is automatically turned off
-- With auto tip enabled, It will auto tip to your named 
-- alt account when your balance is above bankroll + tipamount 
-- On BitVest, minimum 10k BTC, 50k ETH, and 100k LTC
bankroll = 0 -- Minimum you want to keep rolling with.  Set to 0 to use your current balance 
tipamount = 0.0001 -- How much to tip
bankappend = 0.10 -- How much of your tip amount to add to your bankroll over time in %.  0.10 = 10% Set to 0 for no addition to the bankroll 
receiver = "BlaksBank" -- Who gets the tip? **** CHANGE THIS ****

restTime = 0.0 -- How long to wait in seconds before the next bet.  Some sites need this
			   -- Bitvest setting 0.75 for low bet values

maxbet = 0 -- raise for higher betting.  10x basebet seems good so far.  Set to 0 to disable
minbet = 1 -- Use whole integers
basebet = 1 -- Use whole integers
basechance = 1 -- The chance that you would like use.  7 seems to be a good starting point
housePercent = 1 -- Set this according to the site you are on.
-- Known site percentages
-- Freebitco.in = 5%
-- Bitsler = 1.5%
-- Bitvest = 1.0% 

runPercent = 0.15 -- How much of the pre-roll run to actually do before kicking in fibstep
-- 1.0 = 100%.  0.95 = 95% etc..
 
fibstep = 0.350 -- Fibonacci stepping amount
chanceStep = 0.45 -- Chance stepping amount

enableLogging = true -- Set to false for no logging
appendlog = true -- This must be set to false for the very first run!
filename = "bouncer.csv" -- Default to the directory where dicebot is run from.
tempfile = "tempfile.log" -- You can add an absolute directory if wanted with: C:\directory etc
rollLog = 25 -- Use 0 for dynamic long streak logging, otherwise put in a value to log after X losing streak

-- Should not need to change anything below this line

if(bankroll == 0) then
	bankroll = balance
end

if(isTokens == false) then
	minbet = minbet * 0.00000001
	basebet = basebet * 0.00000001
	maxbet = maxbet * 0.00000001
end

local clock = os.clock
function sleep(n)  -- seconds
	local t0 = clock()
	while clock() - t0 <= n do end
end

currentStep = 0
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

if(appendlog != true) then
	fin = assert(io.open(filename, "w"))
	fin:write("Timestamp, Bet ID, Streak, Bet, Chance, fibstep, Spent, Win Amount, Win Profit\n")
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

	if(autotip == true and isTokens == false) then
		if(balance > bankroll + tipamount + (tipamount * bankappend)) then
			tip(receiver, balance - bankroll - (tipamount * bankappend))
			bankroll += (tipamount * bankappend)
			tempstr = "New Bankroll: banker"
			tempstr = string.gsub(tempstr, "banker", bankroll)
			print(tempstr)
		end 
	end
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
		if(enableLogging == true and lossCount >= logTest) then
			tempstr = "year-0month-0day 0hour:0minute:0second, betid, streak, bet, chance, fibstep, spent, winamount, profit, roll, highlo\n"
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
			tempstr = string.gsub(tempstr, "fibstep", fibstep)
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
		nextbet = basebet -- reset
		stepCount = 0 -- reset
		spent = 0
	else -- if lose
		lossCount += 1
		spent += nextbet
		winAmount = (100 - (100 * (housePercent / 100))) / chance
		if lossCount > (winAmount * runPercent) then
			stepCount += 1
			chance += chanceStep
			nextbet = myfib(stepCount)  
		end
		if nextbet > maxbet and maxbet != 0 then
			nextbet = maxbet
		end
		if nextbet >= balance then -- Keep rolling, without completely busting.  May add flag to disable
			if(smoothRecover == true) then
				nextbet = balance / 2 -- Don't completely bust, but try and recover something
			else
				if(enableLogging == true) then
					if(resetOnBust == true) then
						tempstr = "year-0month-0day 0hour:0minute:0second, betid, streak, bet, chance, fibstep, spent, winamount, profit, roll, highlo *******LOSING RESET*******\n"
					else
						tempstr = "year-0month-0day 0hour:0minute:0second, betid, streak, bet, chance, fibstep, spent, winamount, profit, roll, highlo *******LOSING STOP*******\n"
					end
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
					tempstr = string.gsub(tempstr, "fibstep", fibstep)
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
				if(resetOnBust == false or balance <= 0) then
					print("Balance too low for the bet.  Stopping.")
					stop()
				else
					print("Balance too low for the bet.  Resetting.")
					chance = basechance
					lossCount = 0 -- reset
					nextbet = basebet -- reset
					stepCount = 0 -- reset
					spent = 0
					bankroll = balance
				end

			end
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