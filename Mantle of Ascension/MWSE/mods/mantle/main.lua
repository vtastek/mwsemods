-- mantle v0.1
-- by vtastek
-- Adds climbing to Morrowind

local climbHeight = 0
local jumpPosition = 0
local cSpeed = 2.0
local uResultz = nil
-- local jumpingState

local jumping = nil
-- local holding = nil

local acroInf = 1 -- acrobatics influence todo
local FatigInf = 1 -- Fatigue influence todo

-- get the ray start pos, from above and slightly front downwards
local function frontDownCast()

	local eyeVec = tes3.getCameraVector()
	local eyePos = tes3.getCameraPosition()

	-- renormalize eyevec with fixed magnitude for zero z
	-- to avoid making a spherical reach
	local vm = math.sqrt(eyeVec.x * eyeVec.x + eyeVec.y * eyeVec.y)

	if (vm > 0) then
		vm = vm
		else
		vm = 1
	end

	return {
		eyePos.x + ( eyeVec.x / vm * 75 ),
		eyePos.y + ( eyeVec.y /vm * 75 ),
		eyePos.z + ( 200 ),
	}
end


local function climbPlayer()
	-- some bias to prevent clipping through floors
	if(uResultz < (tes3.getCameraPosition().z + 20)) then
		return
	end

	local player = tes3.getPlayerRef()

	-- if added directly, it will fight gravity badly
	jumpPosition = jumpPosition + climbHeight / 60 * cSpeed  * FatigInf

	-- equalizing instead gets consistent results
	player.position.z = jumpPosition

	-- tiny amount of velocity cancellation
	-- not zero, zero disables gravity impact
	local velPlayer = tes3.getMobilePlayer()
	velPlayer.velocity.x = 0.01
	velPlayer.velocity.y = 0.01
	velPlayer.velocity.z = 0.01
	velPlayer.impulseVelocity.x = 0.01
	velPlayer.impulseVelocity.y = 0.01
	velPlayer.impulseVelocity.z = 0.01
end


local function playMoan()
	tes3.playSound{sound="corpDRAG", volume=0.4, pitch=0.8}
end

local function playMoan2()
	tes3.playSound{sound="corpDRAG", volume=0.1, pitch=1.3}
end

-- because timer takes functions only ?
local function jumpingNot()
	jumping = 0
end

local function onClimbE(e)

	-- disabled during jumping, by jumping I mean climbing
	if (jumping == 1) then
		return
	end

	if tes3.menuMode() then
		return
	end

	local mobile = tes3.getMobilePlayer()

	if(mobile.levitate > 0) then
		return
	end

	-- dead men can't jump
	if(mobile.health.current < 1) then
		return
	end

	-- disable during chargen, -1 is all done
	if (tes3.getGlobal("ChargenState") ~= -1) then
		return
	end

	-- disabled for 3rd person for now
	if (tes3.is3rdPerson() == true) then
		return
	end

	local statedown = tes3.getMobilePlayer().actionData.animationAttackState

	-- if player is down
	if (statedown == nil or statedown == 1) then
		return
	end

	-- if player is encumbered
	local encumb = tes3.getMobilePlayer().encumbrance
	if (encumb.current > encumb.base) then
		--mwse.log("encumb")
		return
	end

	if (e.pressed == false) then
		return
	end

	-- let's start! finally...

	local velPlayer = tes3.getMobilePlayer().velocity
	local velCurrent = math.abs(velPlayer.x) + math.abs(velPlayer.y)

	-- stationary penalty
	if(velCurrent < 100) then
		cSpeed = 1.0
	end

	-- falling too fast
	if(velPlayer.z < -1000) then
		return
	end


	-- local campos = tes3.getCameraPosition()

	-- upwards raycast so we know there is no blocking
	local uResult = tes3.rayTest{
		position = tes3.getCameraPosition(),
		direction = {0, 0, 1},
	}


	if (uResult == nil) then
		-- mwse.log("uResult is nil")
		uResultz = tes3.getCameraPosition().z + 1000
		else
		uResultz = uResult.intersection.z
	end

	local player = tes3.getPlayerRef()

	-- instead of (camerapos - footpos)
	local pHeight = mobile.height

	-- down raycast
	local result = tes3.rayTest{
		position = frontDownCast(),
		direction = {0, 0, -1},
	}

	--local reference = mwscript.placeAtPC{object="misc_dwrv_ark_cube00"}

	--reference.position = frontDownCast()
	--mwse.log("%f,%f,%f", tes3.getCameraVector().x, tes3.getCameraVector().y, tes3.getCameraVector().z )
	--mwse.log("a %f,%f,%f", reference.position.x, reference.position.y, reference.position.z)

	if (result == nil) then
		return
	end

	-- if there is enough room for PC height go on
	if ( (uResultz - result.intersection.z) < pHeight) then
		--mwse.log("there is no room")
		--mwse.log("ci: %0.2f, %0.2f", uResultz, result.intersection.z)
		return
		--else
		--mwse.log("cix: %0.2f, %0.2f, %0.2f", uResultz, result.intersection.z, pHeight)
	end


	-- if below waist obstacle, do not attempt climbing
	if (result.intersection.z < (tes3.getCameraPosition().z - (pHeight * 0.5))) then
		return
	end

	-- how much to move upwards
	-- bias for player bounding box
	climbHeight = (result.intersection.z  - player.position.z) * acroInf + 70

	-- print(pHeight)

	-- store jump distance for sound fx and fatigue regulation
	-- local jumpPositionC

	if(player.position.z < result.intersection.z) then
		jumpPosition = player.position.z
		--jumpPositionHold = player.position.z
		--jumpPositionC = jumpPosition

		jumping = 1

		timer.start(1/60, climbPlayer, 60/cSpeed)

		-- local jumpDistance = jumpPosition - jumpPositionC

		local jumpBase = tes3.findGMST("fFatigueJumpBase").value
		local jumpMult = tes3.findGMST("fFatigueJumpMult").values
		local fLoss
		if(jumpMult ~= nil and jumpBase ~= nil) then
			fLoss = jumpBase + (encumb.current/encumb.base) * jumpMult

			if( mobile.fatigue.current > fLoss) then
				mobile.fatigue.current = mobile.fatigue.current - fLoss
			else
				mobile.fatigue.current = 0
			end
		end

		--mobilePlayer:exerciseSkill(tes3.skill.acrobatics, 1)

		timer.start(0.1, playMoan)
		timer.start(0.7, playMoan2)
		timer.start(0.9, jumpingNot)
	end
end

-- hotkey = E
event.register("key", onClimbE, {filter = 18})
-- event.register("key", onHoldingKey, { filter = 57 })


-- MCM
