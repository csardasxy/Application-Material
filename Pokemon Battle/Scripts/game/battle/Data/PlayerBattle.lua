local _M = class("PlayerBattle")
PlayerBattle = _M
B = PlayerBattle

_M.EVENT                = "BATTLE_EVENT"
_M.KEY_TOTAL            = 'TOTAL'

function _M:ctor(info)
    -- base info
    self._isClient = info._isClient
    self._isAttacker = info._isAttacker
    self._fortressHp = info._fortressHp
    self._troopCards = info._troopCards
    self._troopLevels = info._troopLevels
    self._troopSkins = info._troopSkins
    self._battleType = info._battleType
    self._baseBattleType = math.floor(self._battleType / 100)
    self._isOnlinePvp = self._battleType == Data.BattleType.PVP_clash or self._battleType == Data.BattleType.PVP_ladder or self._battleType == Data.BattleType.PVP_room or self._battleType == Data.BattleType.PVP_group or self._battleType == Data.BattleType.PVP_dark
    self._maxRound = self._isOnlinePvp and 30 or self:getMaxRound(info._atkLevel)
    self._isNpc = info._isNpc

    _M._originRandomSeed = info._randomSeed
    
    -- npc
    self._battleCondition = BattleCondition.new(self, info._conditions)
    self._ops = B.parseOperations(info._usedCards, false)
    
    -- event
    --if info._events == nil then info._events = {} end
    --table.insert(info._events, 17001)
    if self._isClient and self._isAttacker and (self._battleType == Data.BattleType.unittest or self._battleType == Data.BattleType.teach) then 
        table.insert(info._events, 65101) 
        self._ops[1] = {_id = BattleData.UseCardType.round, _ids = {1}}
    end
    self._battleEvent = BattleEvent.new(self, info._events)


    -- fortress skill
    if self._isClient and ClientData._isAutoTesting then
        info._fortressSkill = {_id = 60000, _level = 20}
    else
        --info._fortressSkill = {_id = 8033, _level = 20}
    end
    self._fortressSkillInfo = info._fortressSkill 

    -- ai
    self._ai = BattleAi.new(self)

    --room
    self._idInRoom = info._idInRoom

    -- log
    if #self._ops > 0 then
        self:battleLog("")
        self:battleLog("[BATTLE] <USED CARDS>")
        local roundOps = {}
        for i = 1, #self._ops do
            local op = self._ops[i]
            table.insert(roundOps, op)
            if op._type == BattleData.UseCardType.round or op._type == BattleData.UseCardType.retreat then
                local str = ""
                for j = 1, #roundOps do
                    local op = roundOps[j]
                    str = str..'('..op._timestamp..','..op._type
                    for k = 1, #op._ids do
                        str = str..','..op._ids[k]
                    end
                    str = str..')'
                end
                self:battleLog("[BATTLE] %s", str)
                roundOps = {}
            end
        end
    end
end


-----------------------------------
-- skill cast functions 
-----------------------------------

-- disable skill

function _M:getUnderSkillCards(cid, sid)
    local cards = self:getAllCards()
    local underSkillCards = {}
    for i = 1, #cards do
        local card = cards[i]

        for j = 1, #card._underSkills do
            local underSkill = card._underSkills[j]
            if underSkill._cid == cid and underSkill._sid == sid and not (underSkill._positiveType or underSkill._negativeType) then
                table.insert(underSkillCards, card)
                break
            end
        end
    end
    
    return underSkillCards
end

function _M:getUnderChangedCards()
    local cards = self:getAllCards()
    local underChangedCards = {}
    for i = 1, #cards do
        local card = cards[i]
        if next(card._changed) ~= nil then
            table.insert(underChangedCards, card)
        end
    end
    
    return underChangedCards
end

-----------------------------------------------
-- add to under skills
----------------------------------------------

function _M:dealCard(count, cid, sid, mode)
    local isDealed = false
    local curHandCount = #self._handCards
    
    for i = 1, count do
        if curHandCount >= Data.MAX_CARD_COUNT_IN_HAND or self._pileCards[i] == nil then break end
        local card = self._pileCards[i]
        self:setCardStatus(card, BattleData.CardStatus.hand, cid, sid, mode)
        curHandCount = curHandCount + 1
        isDealed = true
    end
    
    return isDealed
end

function _M:setCardStatus(card, status, cid, sid, mode, statusVal, futureSourceStatus)
    table.insert(card._underSkills, {_cid = cid, _sid = sid, _mode = mode, _status = status, _statusVal = statusVal, _futureSourceStatus = futureSourceStatus})
end

function _M:setCardPosChange(card, posChange, cid, sid, mode)
    table.insert(card._underSkills, {_cid = cid, _sid = sid, _mode = mode, _posChange = posChange})
end

function _M:addDamage(card, damage, cid, sid, mode)
    if card._type == Data.CardType.fortress and damage > 0 and self._isClient and ClientData._isAutoTesting then
        damage = 1
    end

    if damage > 0 then
        --damage = 1
    end

    table.insert(card._underSkills, {_cid = cid, _sid = sid, _mode = mode, _damage = damage, _removable = false})
end

function _M:addSpellDamage(card, damage, cid, sid, mode, fromCard)
    local spellDamage = damage
    spellDamage = spellDamage + fromCard:getBuffValue(true, BattleData.PositiveType.spellMaster) + fromCard:getBuffValue(true, BattleData.PositiveType.spellMaster2)
    self:addDamage(card, spellDamage, cid, sid, mode)
end

function _M:incAtk(card, inc, removable, cid, sid, mode)
    table.insert(card._underSkills, {_cid = cid, _sid = sid, _mode = mode, _atkInc = inc, _removable = removable})
    table.insert(card._underSkills, {_cid = cid, _sid = sid, _mode = mode, _maxAtkInc = inc, _removable = removable})
end

function _M:decAtk(card, dec, removable, cid, sid, mode)
    table.insert(card._underSkills, {_cid = cid, _sid = sid, _mode = mode, _atkInc = -dec, _removable = removable})
end

function _M:recAtk(card, rec, cid, sid, mode)
    if rec < 0 or card._atk >= card._maxAtk + card._haloedMaxAtkInc then return false end
		table.insert(card._underSkills, {_cid = cid, _sid = sid, _mode = mode, _atkInc = math.min(rec, card._maxAtk + card._haloedMaxAtkInc - card._atk)})
    return true
end

function _M:incActionCount(card, count, cid, sid, mode)
    table.insert(card._underSkills, {_cid = cid, _sid = sid, _mode = mode, _actionCount = count})
end

function _M:incHp(card, inc, removable, cid, sid, mode)
    table.insert(card._underSkills, {_cid = cid, _sid = sid, _mode = mode, _hpInc = inc, _removable = removable})
    table.insert(card._underSkills, {_cid = cid, _sid = sid, _mode = mode, _maxHpInc = inc, _removable = removable})
end

function _M:decHp(card, dec, removable, cid, sid, mode)
    local fromCard = self:getCardById(cid)
    
    if B.isMonsterSkill(sid) then dec = B.getDamageByMonster(fromCard, card, sid, dec)
    elseif B.isEffectSkill(sid) then dec = B.getDamageByEffect(fromCard, card, sid, dec)
    end
    
    table.insert(card._underSkills, {_cid = cid, _sid = sid, _mode = mode, _hpInc = -dec, _removable = removable})
end

function _M:recHp(card, rec, cid, sid, mode)
	if rec < 0 or card._hp >= card._maxHp + card._haloedMaxHpInc then return false end
	table.insert(card._underSkills, {_cid = cid, _sid = sid, _mode = mode, _hpInc = math.min(rec, card._maxHp + card._haloedMaxHpInc - card._hp)})
    return true
end

function _M:addDamageMark(card, val, removable, cid, sid, mode)
    table.insert(card._underSkills, {_cid = cid, _sid = sid, _mode = mode, _hpInc = -val * 10, _removable = removable, _directDamageMark = true})
end

function _M:incSkillLevel(card, inc, removable, cid, sid, mode)
    table.insert(card._underSkills, {_cid = cid, _sid = sid, _mode = mode, _skillLevelInc = inc, _removable = removable})
end

function _M:incNegativeStatus(card, inc, removable, cid, sid, mode)
    if card:hasBuff(true, BattleData.PositiveType.ignoreNegative) then return end

    if type(inc) == 'table' then
        for i = 1, #inc do
            self:incNegativeStatus(card, inc[i], removable, cid, sid, mode)
        end
        return
    end
    if inc == 0 then return end
    table.insert(card._underSkills, {_cid = cid, _sid = sid, _mode = mode, _incNegative = inc, _removable = removable})
end

function _M:decNegativeStatus(card, dec, removable, cid, sid, mode)
    if type(dec) == 'table' then
        for i = 1, #dec do
            self:decNegativeStatus(card, dec[i], removable, cid, sid, mode)
        end
        return
    end
    table.insert(card._underSkills, {_cid = cid, _sid = sid, _mode = mode, _decNegative = dec, _removable = removable})
end

function _M:incPositiveStatus(card, inc, removable, cid, sid, mode)
    if type(inc) == 'table' then
        for i = 1, #inc do
            self:incPositiveStatus(card, inc[i], removable, cid, sid, mode)
        end
        return
    end
    if inc == 0 then return end
    table.insert(card._underSkills, {_cid = cid, _sid = sid, _mode = mode, _incPositive = inc, _removable = removable})
end

function _M:decPositiveStatus(card, dec, removable, cid, sid, mode)
    if type(dec) == 'table' then
        for i = 1, #dec do
            self:decPositiveStatus(card, dec[i], removable, cid, sid, mode)
        end
        return
    end
    table.insert(card._underSkills, {_cid = cid, _sid = sid, _mode = mode, _decPositive = dec, _removable = removable})
end

function _M:incNegativeValue(card, negativeType, val, aggregateType, cid, sid, mode, independent)
    if card:hasBuff(true, BattleData.PositiveType.ignoreNegative) then return end

    table.insert(card._underSkills, {_cid = cid, _sid = sid, _mode = mode, _negativeType = negativeType, _value = val, _aggregateType = aggregateType, _removable = true})
    if not independent then
        card._underSkills[#card._underSkills - 1]._follower = card._underSkills[#card._underSkills]
        local buffType = card._underSkills[#card._underSkills - 1]._incNegative
        if mode ~= Data.SkillMode.halo and buffType >= BattleData.NegativeType.haloSkillBegin and buffType <= BattleData.NegativeType.haloSkillEnd then
            card._underSkills[#card._underSkills - 1]._ignoreDisable = true
            card._underSkills[#card._underSkills]._ignoreDisable = true
        end 
    end
end

function _M:incPositiveValue(card, positiveType, val, aggregateType, cid, sid, mode, independent)
    table.insert(card._underSkills, {_cid = cid, _sid = sid, _mode = mode, _positiveType = positiveType, _value = val, _aggregateType = aggregateType, _removable = true})
    if not independent then
        card._underSkills[#card._underSkills - 1]._follower = card._underSkills[#card._underSkills]
        local buffType = card._underSkills[#card._underSkills - 1]._incPositive
        if mode ~= Data.SkillMode.halo and buffType >= BattleData.PositiveType.haloSkillBegin and buffType <= BattleData.PositiveType.haloSkillEnd then
            card._underSkills[#card._underSkills - 1]._ignoreDisable = true
            card._underSkills[#card._underSkills]._ignoreDisable = true
        end 
    end
end

function _M:incShield(card, skillIds, isSingleRound, removable, cid, sid, mode)
    for i = 1, #skillIds do
        local shieldType = skillIds[i] < 12000 and (BattleData.PositiveType.shieldBegin + skillIds[i] - 11001) or ((removable and BattleData.PositiveType.shieldHaloBegin or BattleData.PositiveType.shieldExBegin) + skillIds[i] - 12001)
        local target = (shieldType == BattleData.PositiveType.shieldHp or shieldType == BattleData.PositiveType.shieldExHp) and self._fortress or card
        self:incPositiveStatus(target, shieldType, removable, cid, sid, mode)
        self:incPositiveValue(target, shieldType, (isSingleRound and 0x10000 or 0) +1, Data.AggregateType.table, cid, sid, mode)
    end
end

function _M:decShield(card, skillIds, removable, cid, sid, mode)
    local shieldTypes = {}
    for i = 1, #skillIds do
        local shieldType = skillIds[i] < 12000 and (BattleData.PositiveType.shieldBegin + skillIds[i] - 11001) or ((removable and BattleData.PositiveType.shieldHaloBegin or BattleData.PositiveType.shieldExBegin) + skillIds[i] - 12001)
        shieldTypes[#shieldTypes + 1] = shieldType
    end
    self:decPositiveStatus(card, shieldTypes, removable, cid, id, mode)
end

function _M:addGivenSkillToOppo(card, skill, cid, sid, mode)
    table.insert(card._underSkills, {_cid = cid, _sid = sid, _mode = mode, _givenSkill = skill})
end

function _M:bindCard(coverCard, boardCard, cid, sid, mode)
    if B.isAlive(boardCard) then
        table.insert(coverCard._underSkills, {_cid = cid, _sid = sid, _mode = mode, _bind = boardCard, _removable = removable})
        table.insert(boardCard._underSkills, {_cid = cid, _sid = sid, _mode = mode, _bind = coverCard, _removable = removable, _trigger = coverCard._underSkills[#coverCard._underSkills]})
    else
        self:setCardStatus(coverCard, BattleData.CardStatus.grave, cid, sid, mode)
    end
end

function _M:incPower(count, cid, sid, mode)
    table.insert(self._fortress._underSkills, {_cid = cid, _sid = sid, _mode = mode, _incPower = count})
end

function _M:incBall(count, cid, sid, mode)
    table.insert(self._fortress._underSkills, {_cid = cid, _sid = sid, _mode = mode, _incBall = count})
end

-----------------------------------------------
-- add to gem under skills
----------------------------------------------

function _M:addGemUnderSkill(val, singleRound, count, cid, sid, mode)
    self._gemUnderSkills[#self._gemUnderSkills + 1] = {_cid = cid, _sid = sid, _mode = mode, _val = val, _singleRound = singleRound, _count = count}
end

function _M:removeGemUnderSkillsByRound()
    local newUnderSkills = {}
    for i = 1, #self._gemUnderSkills do
        local underSkill = self._gemUnderSkills[i]
        if not underSkill._singleRound then
            newUnderSkills[#newUnderSkills + 1] = underSkill
        end
    end
    self._gemUnderSkills = newUnderSkills
end

--------------------------------------------------------
-- account functions
-------------------------------------------------------

function _M:account()
    local cards = self:getAllCards()

    local advanceCards = {}
    local normalCards = {}
    local delayCards = {}

    for i = 1, #cards do
        local card = cards[i]
        if card._status == BattleData.CardStatus.board or next(card._underSkills) ~= nil then
            if card:isV12() then 
                delayCards[#delayCards + 1] = card
            elseif card:hasAdvanceUnderSkill() then
                advanceCards[#advanceCards + 1] = card
            else
                normalCards[#normalCards + 1] = card
            end
        end
    end

    for i = 1, #advanceCards do
        local card = advanceCards[i]
        card._owner:accountTarget(card)
    end
    for i = 1, #normalCards do
        local card = normalCards[i]
        card._owner:accountTarget(card)
    end
    for i = 1, #delayCards do
        local card = delayCards[i]
        card._owner:accountTarget(card)
    end
end

function _M:accountTarget(card)
    -- 1. save old properties
    local old = {}
    old._hp = card._hp
    old._atk = card._atk
    old._actionCount = card._actionCount
    old._skillLevelInc = card._skillLevelInc
    old._negativeStatus = {}
    old._negativeValues = {}
    for i = 1, BattleData.NegativeType.count do
        old._negativeStatus[i] = card._negativeStatus and card._negativeStatus[i]
        old._negativeValues[i] = card._negativeValues and card._negativeValues[i]
        if card._negativeStatus and i >= BattleData.NegativeType.haloSkillBegin and i <= BattleData.NegativeType.haloSkillEnd then 
            card._negativeStatus[i] = false
        end
    end
    old._positiveStatus = {}
    old._positiveValues = {}
    for i = 1, BattleData.PositiveType.count do
        old._positiveStatus[i] = card._positiveStatus and card._positiveStatus[i]
        old._positiveValues[i] = card._positiveValues and card._positiveValues[i]
        if card._positiveStatus and i >= BattleData.PositiveType.haloSkillBegin and i <= BattleData.PositiveType.haloSkillEnd then 
            card._positiveStatus[i] = false
        end
    end
    old._binds = {}
    for i = 1, #card._binds do
        old._binds[i] = card._binds[i]
    end
    --old._power = self._power

    -- 3. re-calculate new properties
    local maxHpInc, hpInc = card._maxHpInc, card._hpInc
    local maxAtkInc, atkInc = card._maxAtkInc, card._atkInc
    local incNegative, decNegative = {}, {}
    local incPositive, decPositive = {}, {}
    local skillLevelInc = card._skillLevelInc
    local damage = 0
    
    --print ('-------- under skill of', Str(card._type ~= Data.CardType.fortress and card._info._nameSid or STR.FORTRESS), card._id, card._infoId)
    --lc.dumpTable(card._underSkills, 2)

    -- 3.1 cast shield under skills (not include shieldAttack)
    local isShieldBuff = function(n) 
        return n >= BattleData.PositiveType.shieldHaloBegin and n <= BattleData.PositiveType.shieldExEnd 
    end

    for i = 1, #card._underSkills do
        local skill = card._underSkills[i]
        if skill._disabled ~= true then
            for k, v in pairs(skill) do
                if k == "_incPositive"      then if isShieldBuff(v) then incPositive[v] = true end 
                elseif k == "_decPositive"  then if isShieldBuff(v) then decPositive[v] = true end 
                end
            end
        end 
    end

    -- 3.2 shield buff
    if card._positiveStatus ~= nil then
        for i = BattleData.PositiveType.shieldHaloBegin, BattleData.PositiveType.shieldExEnd do
            if isShieldBuff(i) then
                if decPositive[i] then card._positiveStatus[i] = false
                elseif incPositive[i] then card._positiveStatus[i] = true
                end

                if card._positiveStatus[i] == false then
                    card:resetBuffByType(true, i)
                elseif card._positiveStatus[i] == true then
                    card:accountBuffValue(true, i)
                end
            end
        end
    end

    -- 3.3 cast other under skills
    for i = 1, #card._underSkills do
        local skill = card._underSkills[i]
        if skill._disabled ~= true and not self:isHaloUnderSkillDisabledByShield(card, skill) then
            for k, v in pairs(skill) do
                if k == "_incNegative"      then incNegative[v] = true
                elseif k == "_decNegative"  then decNegative[v] = true
                elseif k == "_incPositive"  then if not isShieldBuff(v) then incPositive[v] = true end
                elseif k == "_decPositive"  then if not isShieldBuff(v) then decPositive[v] = true end
                elseif k ==  "_maxHpInc"    then maxHpInc = maxHpInc + v if not skill._removable then card._maxHpInc = card._maxHpInc + v end
                elseif k == "_hpInc"        then hpInc = hpInc + v if not skill._removable then card._hpInc = card._hpInc + v end
                elseif k == "_maxAtkInc"    then maxAtkInc = maxAtkInc + v if not skill._removable then card._maxAtkInc = card._maxAtkInc + v end
                elseif k == "_atkInc"       then atkInc = atkInc + v if not skill._removable then card._atkInc = card._atkInc + v end
                elseif k == "_skillLevelInc"     then skillLevelInc = skillLevelInc + v if not skill._removable then card._skillLevelInc = card._skillLevelInc + v end
                elseif k == "_actionCount"  then card._actionCount = card._actionCount + v if card._actionCount > 2 and card:hasSkills({3191}) then card._actionCount = 2 end
                elseif k == "_damage"       then damage = damage + v
                elseif k == "_status"       then self:changeCardStatus(card, skill._futureSourceStatus or card._status, v, skill._statusVal, self:getCardById(skill._cid))
                elseif k == "_posChange"    then self:changeCardPos(card, v)
                elseif k == "_givenSkill"   then card:removeSkills(BattleData.SkillProvider.given) card:addSkill(v % 0x10000, math.floor(v / 0x10000), BattleData.SkillProvider.given)
                elseif k == "_bind"         then card:addBind(v)
                --elseif k == "_incPower"     then self._power = math.max(0, math.min(BattleData.MAX_POWER_COUNT, self._power + v))
                elseif k == "_incBall"      then self._ball = math.max(0, math.min(BattleData.MAX_POWER_COUNT, self._ball + v))
                end
            end
        end 
    end

    -- 3.4 other buff
    if card._negativeStatus ~= nil then
        for i = 1, BattleData.NegativeType.count do
            if decNegative[i] then card._negativeStatus[i] = false 
            elseif incNegative[i] then card._negativeStatus[i] = true 
            end

            if card._negativeStatus[i] == false then
                card:resetBuffByType(false, i)
            elseif card._negativeStatus[i] == true then
                card:accountBuffValue(false, i)
            end
        end
    end
    if card._positiveStatus ~= nil then
        for i = 1, BattleData.PositiveType.count do
            if not isShieldBuff(i) then
                if decPositive[i] then card._positiveStatus[i] = false
                elseif incPositive[i] then card._positiveStatus[i] = true
                end

                if card._positiveStatus[i] == false then
                    card:resetBuffByType(true, i)
                elseif card._positiveStatus[i] == true then
                    card:accountBuffValue(true, i)
                    if i == BattleData.PositiveType.magicMark and card:getBuffValue(true, i) == 0 then
                        -- recheck for specific positive types
                        card._positiveStatus[i] = false
                        card:resetBuffByType(true, i)
                    end
                end

                -- update attack target
                if i == BattleData.PositiveType.extraSkill then
                    card:accountExtraSkill()
                end
            end
        end
    end

    -- 3.5 remove under skills
    local i = 1
    while true do
        local skill = card._underSkills[i]
        if skill == nil then break end
        if not skill._removable then
--            if skill._damage ~= nil and skill._damage > 0 and skill._sid == 0 then killedByAtk = true end
            -- set follower to ignoreDisable for removable and non-disabled underSkill
            if skill._disabled ~= true and skill._follower ~= nil and skill._follower._disabled ~= true then
                skill._follower._ignoreDisable = true
            end
            table.remove(card._underSkills, i)
        else
            i = i + 1
        end
    end

    -- 3.6 account to fortress
    if card._type == Data.CardType.fortress 
         and (self._stepStatus == BattleData.Status.account_attack or self._opponent._stepStatus == BattleData.Status.account_attack) then
         if card._accountedDamage == nil then
            card._accountedDamage = damage
         end
    end
    
    -- 3.7 hp & atk
    local minHp, minAtk = 0, 0
    --if old._hp ~= nil and old._hp > 0 and damage == 0 then minHp = 1 end
    --if old._atk ~= nil and old._atk > 0 and card._maxAtk > 0 then minAtk = 1 end

    if damage ~= 0 then hpInc = hpInc - damage card._hpInc = card._hpInc - damage end
    if card._hp ~= nil then 
        if card._type == Data.CardType.fortress and card._owner._fortressHp == 0 then
            card._hp = card._maxHp
        else
            local maxHp = (card:hasBuff(false, BattleData.NegativeType.atkDefSwapHalo) or card:hasBuff(false, BattleData.NegativeType.atkDefSwap)) and card._maxAtk or card._maxHp
            local hp = maxHp + hpInc
            card._hp = math.max(math.min(hp, maxHp + maxHpInc), minHp)
            if card:isV12() then
                local maxAtkCard = B.getMaxAtkCard(B.filterNotEqualInfoIdCards(B.mergeTable({self:getBattleCards('B'), self._opponent:getBattleCards('B')}), card._infoId))
                card._hp = (maxAtkCard ~= nil and maxAtkCard._atk or 0) + Data._skillInfo[6074]._val[1]
            end
            card._hpInc = card._hpInc + (card._hp  - hp)
        end
        card._haloedMaxHpInc = maxHpInc
    end
    
    if card._atk ~= nil then 
        local maxAtk = (card:hasBuff(false, BattleData.NegativeType.atkDefSwapHalo) or card:hasBuff(false, BattleData.NegativeType.atkDefSwap)) and card._maxHp or card._maxAtk
        local atk = maxAtk + atkInc
        card._atk = math.max(math.min(atk, maxAtk + maxAtkInc), minAtk) 
        if card:isV12() then
            card._atk = card._hp
        elseif card:hasBuff(true, BattleData.PositiveType.lockAtk) then
            card._atk = card:getBuffValue(true, BattleData.PositiveType.lockAtk) 
        end
        card._atkInc = card._atkInc + (card._atk - atk)
        card._haloedMaxAtkInc = maxAtkInc
    end
    
    -- 3.8 skill
    if card:isMonster() then
        for i = 1, #card._skills do 
            local skill = card._skills[i]
            skill._level = math.min(skill._maxLevel + skillLevelInc, CardHelper.getSkillMaxLevel(skill._id)) 
        end 
    end
    
    -- 3.9 others
    
    -- 3.10 score
    if damage ~= 0 then 
        if card._type == Data.CardType.fortress and card._owner._fortressHp == 0 then
            -- donot add score
        else
            card:getOriginOwner()._opponent:addDamageScore(damage)  
        end
    end
    
    -- 4. get changed
    card._changed = {}
    if card._atk ~= old._atk then card._changed._atk = card._atk - old._atk end
    if card._type ~= Data.CardType.fortress then
        if card._hp ~= nil and card._hp ~= old._hp then card._changed._hp = card._hp - old._hp end
    else
        if card._hp ~= nil and card._hp ~= old._hp and card._hp > 0 and (card._hp ~= old._hp - damage) then 
            card._changed._hp = card._hp - old._hp + damage 
        end
    end
    if damage ~= 0 then 
        card._changed._damage = damage 
        if card._type == Data.CardType.fortress then
            card._lastDamage = damage
            self:changeCardStatus(card, card._status, card._status, BattleData.CardStatusVal.f2f_fortress_damaged)
        end
    end
    if card._actionCount ~= old._actionCount then card._changed._actionCount = card._actionCount - old._actionCount end
    if card._skillLevelInc ~= old._skillLevelInc then card._changed._skillLevelInc = card._skillLevelInc - old._skillLevelInc end 
    if card:isMonster() or card._type == Data.CardType.fortress or card._type == Data.CardType.magic or card._type == Data.CardType.trap then
        if B.isStatusChange(BattleData.NegativeType.count, card._negativeStatus, card._negativeValues, old._negativeStatus, old._negativeValues) then card._changed._negativeStatus = {} end
        if B.isStatusChange(BattleData.PositiveType.count, card._positiveStatus, card._positiveValues, old._positiveStatus, old._positiveValues) then card._changed._positiveStatus = {} end
    end
    if #card._binds ~= #old._binds then card._changed._bind = {} end
    --if old._power ~= self._power then card._changed._power = self._power - old._power end
    
    if card._hp ~= old._hp then
        self:battleLog("[BATTLE] %s\tHP\t%4d -> %4d", Str(card._type ~= Data.CardType.fortress and card._info._nameSid or STR.FORTRESS), old._hp, card._hp)
    end
    if card._atk ~= old._atk then
        self:battleLog("[BATTLE] %s\tATK\t%4d -> %4d", Str(card._info._nameSid), old._atk, card._atk)
    end

    return next(card._changed) ~= nil
end

function _M:getActionPlayer()
    return self._stepStatus ~= BattleData.Status.wait_opponent and self or self._opponent
end

function _M:getActionCard()
    return self._actionCard or self._opponent._actionCard
end

function _M:getEvents(type)
    local events = {}

    local selfEvents = self._battleEvent:getSatisfiedEvents(type)
    for i = 1, #selfEvents do
        table.insert(events, selfEvents[i])
    end

    --self:battleLog("Round = %d, Event type = %d, Event count = %d", self._round, type, #selfEvents)

    if type == BattleEvent.EventType.battle_start or type == BattleEvent.EventType.battle_end or 
        type == BattleEvent.EventType.card_deal or type == BattleEvent.EventType.card_use or type == BattleEvent.EventType.card_die then
        local oppoEvents = self._opponent._battleEvent:getSatisfiedEvents(type)
        for i = 1, #oppoEvents do
            table.insert(events, oppoEvents[i])
        end
    end
    
    return events
end

function _M:getIsEventSatisfied(event)
    return self._battleEvent:isEventSatisfied(event)
end

function _M:getActionEffect(event, index)
    return event._info._effect[index], event._info._effectValue[index]
end

function _M:getActionStory(event, index)
    return event._info._storyId[index]
end

function _M:getHaloModeSkills(mode)
    local skills = {}
    local cards = B.mergeTable({self:getBattleCards('BS'), self:getBattleCardsBySkillMode('G', Data.SkillMode.in_grave)})
    for i = 1, #cards do
        local card = cards[i]
        for j = 1, #card._skills do
            local skill = card._skills[j]
            if B.skillHasMode(skill, mode) then
                skills[#skills + 1] = skill
            end
        end
    end
    return skills
end

function _M:isHaloUnderSkillDisabledByShield(card, underSkill)
    if underSkill._mode ~= Data.SkillMode.halo then return false end
    if Data._skillInfo[underSkill._sid]._isIgnoreDefend == 1 then return false end
    local castCard = self:getCardById(underSkill._cid)
    if castCard == nil then return false end
    if castCard:isMonster() and (card:hasBuff(true, BattleData.PositiveType.shieldExMonster) or card:hasBuff(true, BattleData.PositiveType.shieldHaloMonster)) then return true end
    if castCard._type == Data.CardType.magic and (card:hasBuff(true, BattleData.PositiveType.shieldExMagic) or card:hasBuff(true, BattleData.PositiveType.shieldHaloMagic)) then return true end
    if castCard._type == Data.CardType.trap and (card:hasBuff(true, BattleData.PositiveType.shieldExTrap) or card:hasBuff(true, BattleData.PositiveType.shieldHaloTrap)) then return true end
    return false
end

function _M:getSkillPowerCost(power)
    return math.max(0, power + (self._extraPowerCost[self._round] or 0))
end


return _M

