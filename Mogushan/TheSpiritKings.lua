
--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("The Spirit Kings", 896, 687)
if not mod then return end
mod:RegisterEnableMob(
	60701, 61421, -- Zian of the Endless Shadows
	60708, 61429, -- Meng the Demented
	60709, 61423, -- Qiang the Merciless
	60710, 61427 -- Subetai the Swift
)

--------------------------------------------------------------------------------
-- Locals
--

local spellReflect = mod:SpellName(69901)

local meng = EJ_GetSectionInfo(5835)
local qiang = EJ_GetSectionInfo(5841)
local subetai = EJ_GetSectionInfo(5846)
local zian = EJ_GetSectionInfo(5852)

local bossActivated = {}
local bossWarned = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.shield_removed = "Shield removed! (%s)"
	L.casting_shields = "Casting shields"
	L.casting_shields_desc = "Warnings for when shields are casted for all bosses."
	L.casting_shields_icon = 871

	L.cowardice = EJ_GetSectionInfo(5838) .." (".. spellReflect ..")"
	L.cowardice_desc = select(2, EJ_GetSectionInfo(5838))
	L.cowardice_icon = 117756
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"ej:5841", 117921, 119521, 117910, {117961, "FLASHSHAKE"}, -- Qiang
		"ej:5852", {118303, "SAY", "ICON"}, {117697, "FLASHSHAKE"}, -- Zian
		"ej:5846", 118047, 118122, 118094, {118162, "FLASHSHAKE"}, -- Subetai
		"ej:5835", "cowardice", 117708, 117837, -- Meng
		"proximity", "casting_shields", "berserk", "bosskill",
	}, {
		["ej:5841"] = qiang,
		["ej:5852"] = zian,
		["ej:5846"] = subetai,
		["ej:5835"] = meng,
		proximity = "general",
	}
end

function mod:OnBossEnable()
	-- Qiang
	self:Log("SPELL_CAST_START", "Annihilate", 119521, 117948) -- Heroic, Norm/LFR
	self:Log("SPELL_CAST_SUCCESS", "FlankingOrders", 117910)
	self:Log("SPELL_CAST_START", "ImperviousShield", 117961)
	self:Log("SPELL_AURA_REMOVED", "ShieldRemoved", 117961)
	self:Log("SPELL_DAMAGE", "MassiveAttack", 117921)
	self:Log("SPELL_MISSED", "MassiveAttack", 117921)

	-- Zian
	self:Log("SPELL_AURA_APPLIED", "Fixate", 118303)
	self:Log("SPELL_CAST_START", "ShieldofDarkness", 117697)
	self:Log("SPELL_AURA_REMOVED", "ShieldRemoved", 117697)

	-- Subetai
	self:Log("SPELL_CAST_SUCCESS", "Pillage", 118047)
	self:Log("SPELL_AURA_APPLIED", "PinnedDown", 118135)
	self:Log("SPELL_CAST_START", "SleightofHand", 118162)
	self:Log("SPELL_CAST_START", "Volley", 118094)

	-- Meng
	self:Log("SPELL_CAST_START", "MaddeningShout", 117708)
	self:Log("SPELL_AURA_APPLIED", "CowardiceApplied", 117756)
	self:Log("SPELL_AURA_REMOVED", "CowardiceRemoved", 117756)
	self:Log("SPELL_AURA_APPLIED", "Delirious", 117837)

	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "EngageCheck")

	self:Death("Win", 60701, 60708, 60709, 60710)
end

function mod:OnEngage()
	self:Berserk(600)
	wipe(bossActivated)
	if self:Heroic() then
		self:Bar(117961, 117961, 40, 117961) -- Impervious Shield
		self:RegisterEvent("UNIT_HEALTH_FREQUENT")
		bossWarned = 0
	end
	self:Bar(119521, 119521, 10, 119521) -- Annihilate
	self:Bar(117910, 117910, 25, 117910) -- Flanking Orders
	self:Message("ej:5841", qiang, "Positive", 117920)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

local function isBossActiveById(bossId, bossIdTwo)
	for i=1, 5 do
		local unitId = ("boss%d"):format(i)
		if UnitExists(unitId) then
			local id = mod:GetCID(UnitGUID(unitId))
			if id == bossId or id == bossIdTwo then
				return true
			end
		end
	end
	return false
end

-- meng
do
	local prevPower = 0
	function mod:CowardiceApplied()
		prevPower = 0
		self:RegisterEvent("UNIT_POWER_FREQUENT")
	end
	function mod:CowardiceRemoved(_, spellId)
		self:UnregisterEvent("UNIT_POWER_FREQUENT")
		prevPower = 0
		self:Message("cowardice", CL["over"]:format(spellReflect), "Positive", spellId)
	end
	function mod:UNIT_POWER_FREQUENT(_, unitId)
		if not unitId:find("boss", nil, true) then return end
		local id = self:GetCID(UnitGUID(unitId))
		if id == 60708 or id == 61429 then
			local power = UnitPower(unitId)
			if power > 74 and prevPower == 0 then
				prevPower = 75
				self:Message("cowardice", ("%s (%d%%)"):format(spellReflect, power), "Attention", 117756)
			elseif power > 84 and prevPower == 75 then
				prevPower = 85
				self:Message("cowardice", ("%s (%d%%)"):format(spellReflect, power), "Urgent", 117756)
			elseif power > 89 and prevPower == 85 then
				prevPower = 90
				self:Message("cowardice", ("%s (%d%%)"):format(spellReflect, power), "Personal", 117756)
			elseif power > 92 and prevPower == 90 then
				prevPower = 93
				self:Message("cowardice", ("%s (%d%%)"):format(spellReflect, power), "Personal", 117756)
			elseif power > 96 and prevPower == 93 then
				prevPower = 97
				self:Message("cowardice", ("%s (%d%%)"):format(spellReflect, power), "Personal", 117756)
			end
		end
	end
end

function mod:MaddeningShout(_, spellId, _, _, spellName)
	self:Message(spellId, spellName, "Urgent", spellId, "Alarm")
	if isBossActiveById(60708, 61429) then
		self:Bar(spellId, "~"..spellName, 46.7, spellId)
	else
		self:Bar(spellId, "~"..spellName, 76, spellId)
	end
end

function mod:Delirious(_, spellId, _, _, spellName)
	if self:Dispeller("enrage", true) then
		self:LocalMessage(spellId, spellName, "Urgent", spellId, "Alert")
		self:Bar(spellId, spellName, 20, spellId)
	end
end

-- Subetai
do
	local pinnedTargets, scheduled = mod:NewTargetList(), nil
	local function warnPinned(spellName)
		mod:TargetMessage(118122, spellName, pinnedTargets, "Important", 118122, "Alarm")
		scheduled = nil
	end
	function mod:PinnedDown(player, _, _, _, spellName)
		pinnedTargets[#pinnedTargets + 1] = player
		if not scheduled then
			scheduled = self:ScheduleTimer(warnPinned, 0.1, spellName)
		end
	end
end

function mod:Pillage(_, spellId, _, _, spellName)
	self:Message(spellId, spellName, "Urgent", spellId, "Alarm")
	if isBossActiveById(60710, 61427) then
		self:Bar(spellId, "~"..spellName, 40, spellId)
	else
		self:Bar(spellId, spellName, 75.5, spellId)
	end
end

function mod:Volley(_, spellId, _, _, spellName)
	self:Message(spellId, spellName, "Urgent", spellId)
	self:Bar(spellId, spellName, 41, spellId)
end

function mod:SleightofHand(_, spellId, _, _, spellName)
	self:Message(spellId, spellName, "Important", spellId, "Alert")
	self:Bar(spellId, spellName, 42, spellId)
	self:FlashShake(spellId)
end

-- Zian
function mod:Fixate(player, spellId, _, _, spellName)
	self:PrimaryIcon(spellId, player)
	if UnitIsUnit("player", player) then
		self:LocalMessage(spellId, spellName, "Personal", spellId, "Info")
		self:Say(spellId, CL["say"]:format(spellName))
	end
end

function mod:ShieldofDarkness(_, spellId, _, _, spellName)
	self:Message(spellId, spellName, "Important", spellId, "Alert")
	self:Bar(spellId, spellName, 42, spellId)
	self:Bar("casting_shields", CL["cast"]:format(spellName), 2, spellId)
	self:FlashShake(spellId)
end

-- Qiang
function mod:FlankingOrders(_, spellId, _, _, spellName)
	self:Message(spellId, spellName, "Attention", spellId, "Long")
	if isBossActiveById(60709, 61423) then
		self:Bar(spellId, spellName, self:Heroic() and 45.7 or 41, spellId)
	else
		self:Bar(spellId, spellName, 75, spellId)
	end
end

function mod:Annihilate(_, _, _, _, spellName)
	self:Message(119521, spellName, "Urgent", 119521, "Alarm")
	self:Bar(119521, spellName, self:Difficulty() == 6 and 32 or 39, 119521)
	self:Bar(117921, 117921, 8, 117921) -- Massive Attack
end

function mod:MassiveAttack(_, spellId, _, _, spellName)
	self:Bar(spellId, spellName, 5, spellId)
end

function mod:ImperviousShield(_, spellId, _, _, spellName)
	self:Message(spellId, spellName, "Important", spellId, "Alert")
	self:Bar(spellId, spellName, self:Difficulty() == 5 and 62 or 42, spellId)
	self:Bar("casting_shields", CL["cast"]:format(spellName), 2, spellId)
	self:FlashShake(spellId)
end

function mod:ShieldRemoved(_, spellId, _, _, spellName)
	self:Message(spellId, L["shield_removed"]:format(spellName), "Positive", spellId, "Info")
end

function mod:EngageCheck()
	self:CheckBossStatus()
	for i=1, 5 do
		local unitId = ("boss%d"):format(i)
		if UnitExists(unitId) then
			local id = self:GetCID(UnitGUID(unitId))
			-- this is needed because of heroic
			if (id == 60701 or id == 61421) and not bossActivated[60701] then -- Zian
				bossActivated[60701] = true
				if self:Heroic() then
					self:Bar(117697, 117697, 40, 117697) -- Shield of Darkness
				end
				self:OpenProximity(8)
				self:Message("ej:5852", zian, "Positive", 117628)
			elseif (id == 60710 or id == 61427) and not bossActivated[60710] then -- Subetai
				bossActivated[60710] = true
				if self:Heroic() then
					self:Bar(118162, 118162, 15, 118162) -- Sleight of Hand
				end
				self:OpenProximity(8)
				self:Bar(118094, 118094, 5, 118094) -- Volley
				self:Bar(118047, 118047, 26, 118047) -- Pillage
				self:Bar(118122, 118122, self:Heroic() and 40 or 15, 118122) -- Rain of Arrows
				self:Message("ej:5846", subetai, "Positive", 118122)
			elseif (id == 60708 or id == 61429) and not bossActivated[60708] then -- Meng
				bossActivated[60708] = true
				self:Bar(117708, "~"..self:SpellName(117708), self:Heroic() and 40 or 21, 117708) -- Maddening Shout, on heroic: 44.2, 19.8, 48.7, 49.2, 40.2
				if self:Heroic() and self:Dispeller("enrage", true) then
					self:Bar(117837, 117837, 20, 117837) -- Delirious
				end
				self:Message("ej:5835", meng, "Positive", 117833)
			end
		end
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(_, unitId, spellName, _, _, spellId)
	if unitId:find("boss", nil, true) then
		if spellId == 118205 then -- Inactive Visual
			local id = self:GetCID(UnitGUID(unitId))
			if (id == 60709 or id == 61423) then -- Qiang
				self:StopBar(119521) -- Annihilate
				self:StopBar(117961) -- Impervious Shield
				self:StopBar(117921) -- Massive Attack
				self:Bar(117910, 117910, 30, 117910) -- Flanking Orders
			elseif (id == 60701 or id == 61421) then -- Zian
				self:StopBar(117697) -- Shield of Darkness
				if not isBossActiveById(60710, 61427) then -- don't close if Subetai is active
					self:CloseProximity()
				end
			elseif (id == 60710 or id == 61427) then -- Subetai
				self:StopBar(118162) -- Sleight of Hand
				self:StopBar(118094) -- Volley
				self:StopBar(self:Heroic() and 118122 or ("~"..self:SpellName(118122))) -- Rain of Arrows
				self:StopBar("~"..self:SpellName(118047)) -- Pillage
				self:Bar(118047, 118047, 30, 118047) -- Pillage
				if not isBossActiveById(60701, 61421) then -- don't close if Zian is active
					self:CloseProximity()
				end
			elseif (id == 60708 or id == 61429) then -- Meng
				self:StopBar(117837)
				self:Bar(117708, "~"..self:SpellName(117708), 30, 117708) -- Maddening Shout
			end
		elseif spellId == 118121 then -- Rain of Arrows for Pinned Down
			local hc = self:Heroic()
			self:Bar(118122, hc and 118122 or ("~"..self:SpellName(118122)), hc and 41 or 51, 118122) -- Rain of Arrows, exact on heroic, 50-60 on norm
		end
	end
end

function mod:UNIT_HEALTH_FREQUENT(_, unitId)
	if unitId:find("boss", nil, true) then
		local hp = UnitHealth(unitId) / UnitHealthMax(unitId) * 100
		if hp < 38 then -- next boss at 30% (Qiang -> Subetai -> Zian -> Meng)
			local id = self:GetCID(UnitGUID(unitId))
			if bossWarned == 0 and (id == 60709 or id == 61423) then -- Qiang
				self:Message("ej:5846", CL["soon"]:format(subetai), "Positive", nil, "Info")
				bossWarned = 1
			elseif bossWarned == 1 and (id == 60710 or id == 61427) then -- Subetai
				self:Message("ej:5852", CL["soon"]:format(zian), "Positive", nil, "Info")
				bossWarned = 2
			elseif bossWarned == 2 and (id == 60701 or id == 61421) then -- Zian
				self:Message("ej:5835", CL["soon"]:format(meng), "Positive", nil, "Info")
				self:UnregisterEvent("UNIT_HEALTH_FREQUENT")
			end
		end
	end
end

