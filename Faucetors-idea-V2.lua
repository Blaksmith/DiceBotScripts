-- Script by CttCJim
-- For seintjie's dicebot, developed on v3.3.9
-- jreinsch@gmail.com
-- Be a bro: BTC 1JP3tHhToThgS81Wu8P8wD7Ymu29YB3upT
--
-- Modified by Blaksmith

isTokens = false -- Set to false for satoshi betting, true for tokens 

basechance=20 	--sets your chance for placing a bet
basebet = 1		-- Base bet in whole numbers.
basegambit = 10 -- base gambit section betting in whole numbers

prerolllimit = 4 -- length of loss set before gambit
gambitlimit = 2 -- number of gambit bets to make

fibstep = 0.1125 -- Stepping for the fibonacci bet increments

rollDelay = 0.7 -- Sleep period in seconds.  Some sites need this


-- Init variables

if(isTokens == false) then -- Convert basebet and basegambit to satoshi
	basebet = basebet * 0.00000001
	basegambit = basegambit * 0.00000001
end

nextbet=basebet -- sets your first bet.
chance = basechance -- sets the chance to play at
losscount = 0 -- to count until set of losses
waitforwin = 0 -- Wait for a win after gambit
gambit = 0 -- flag for when doing 3-bet runs
gambitcount = 0 -- number of gambit bets performed currently
gambitmult = 0 -- gambit multiplier/counter
streakStartBalance = 0
previouscount = 0

local clock = os.clock
function sleep(n)  -- seconds
	local t0 = clock()
	while clock() - t0 <= n do end
end

function myfib(level)
	fibno=basegambit
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


function dobet()

	if win then
		if gambit == 0 then -- win, regular roll
			losscount = 0
			waitforwin = 0
		else -- win, gambit roll; reset everything
			if(balance > streakStartBalance) then -- Reset everything
				gambitcount=0
				previouscount = 0
				gambit=0
				gambitmult = 0
				nextbet = basebet
				losscount = 0
				waitforwin = 0
				streakStartBalance = 0
			else -- continue gambit
				previouscount -= 1
				if(previouscount < 1) then
					previouscount = 1
				end
				nextbet = myfib(previouscount)
			end
		end
	else -- lost last roll
		if(streakStartBalance == 0) then -- Get initial balance at the start of this run
			streakStartBalance = balance
		end
		if gambit == 0 then -- lose, regular roll
			losscount = losscount + 1
			if losscount >= prerolllimit and waitforwin == 0 then -- turn on the gambit
				gambit = 1
				gambitcount = 1
				previouscount += 1
				-- gambitmult = gambitmult + 1
				nextbet = myfib(previouscount)
				-- nextbet = basebet * (multiplier^gambitmult)
				losscount = 0 -- primed for after the gambit
			end
		else -- lose, gambit roll
			if gambitcount<gambitlimit and waitforwin == 0 then -- next bet is another gambit
				gambitcount = gambitcount + 1
				previouscount += 1
				nextbet = myfib(previouscount)
			else -- gambit set over; go back to base bet but preserve previouscount
				nextbet = basebet
				gambitcount = 0
				gambit = 0
				waitforwin = 1
			end		
		end
	end
	
	sleep(rollDelay)

end