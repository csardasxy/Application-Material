local _M = class("BattleCard")
BattleCard = _M

-----------------------------------
-- init, base info
-----------------------------------

function _M:ctor(...)
    self:init(...)
end

function _M:init(infoId, level, owner)
    self._infoId = infoId
    self._level = level
    self._type = Data.getType(infoId)
    self._owner = owner

    self._underSkills = {}
    
    if self:isMonster() then
        self:initMonster()
    elseif self._type == Data.CardType.magic then
        self:initMagic()
    elseif self._type == Data.CardType.trap then
        self:initTrap()
    end
end

function _M:initMonster()
    self._info = Data._monsterInfo[self._infoId]    
end

function _M:initMagic()
    self._info = Data._magicInfo[self._infoId]
end

function _M:initTrap()
    self._info = Data._trapInfo[self._infoId]
end


-----------------------------------
-- reset once when battle start
-----------------------------------

function _M:resetOnce()
    self._skillMaxLevelInc = {}
    self._dieCount = 0
    self:reset()
end


-----------------------------------
-- base reset, relation & command
-----------------------------------

function _M:baseReset()
    self._skills = {}
    
    if self:isMonster() then
        self:baseResetMonster()
    elseif self._type == Data.CardType.magic then
        self:baseResetMagic()
    elseif self._type == Data.CardType.trap then
        self:baseResetTrap()
    elseif self._type == Data.CardType.fortress then
        self:baseResetFortress()
    end
    
    self:testSkills()
end

function _M:baseResetMonster()
    -- atk & hp
    self._maxAtk = self._info._hp
    self._maxHp = self._info._hp
        
    -- skills
    self:baseResetSkills()
end

function _M:baseResetMagic()
    self:baseResetSkills()
end

function _M:baseResetTrap()
    self:baseResetSkills()
end

function _M:baseResetFortress()
    self._maxHp = self._updateInitHp or 99999999
    self._status = BattleData.CardStatus.fortress
end


-----------------------------------
-- reset, battle related
-----------------------------------

function _M:reset()
    self:baseReset()

    self._saved = {}
    self._castedSkills = {}
    self._underSkills = {}
    self._changed = {}
    self._binds = {}
    
    if self:isMonster() then
        self:resetMonster()
    elseif self._type == Data.CardType.magic then
        self:resetMagic()
    elseif self._type == Data.CardType.trap then
        self:resetTrap()
    elseif self._type == Data.CardType.fortress then
        self:resetFortress()
    end
end

function _M:resetMonster()    
    self:resetHp()
    self:resetAtk()

    -- action
    self._actionCount = 1
    self._actionIndex = 1
    self._isBorrowed = false

    -- buff
    self:resetBuff() 

    -- skills
    self._monsterTarget = nil
    self:resetSkills()
    self._skillLevelInc = 0
end

function _M:resetMagic()
    -- action
    self._actionCount = 1
    self._actionIndex = 1

    -- buff
    self:resetBuff() 

    -- skills
    self._magicTarget = nil
    self:resetSkills()
    self._skillLevelInc = 0
end

function _M:resetTrap()
    -- action
    self._actionCount = 1
    self._actionIndex = 1

    -- buff
    self:resetBuff() 
    
    -- skills
    self._trapTarget = nil
    self:resetSkills()
    self._skillLevelInc = 0
end

function _M:resetFortress()
    self:resetHp()

    -- buff
    self:resetBuff() 
end

function _M:resetCardWhenRoundBegin()
    self._isEvolved = nil
end

function _M:resetCardWhenOppoRoundBegin()
    self._isEvolved = nil
end

function _M:saveAndReset()
    local saved = self._saved
    local savedExtraSkills = self:saveExtraSkills()
    local skillCastedTimes = self:saveSkillCastTimes()
    
    self:reset()
    
    self._saved = saved or {}
    self:loadSkillCastTimes(skillCastedTimes)
    self:loadExtraSkills(savedExtraSkills)
end


-----------------------------------
-- hp & atk
-----------------------------------

function _M:resetHp()
    self._hp = self._maxHp
    self._maxHpInc = 0
    self._hpInc = 0
    if self._updateInitHp ~= nil then
        self._hp = math.min(self._hp, self._updateInitHp)
        self._hpInc = self._hp - self._maxHp
        if self._hpInc > 0 then self._maxHpInc = self._hpInc end
    end
    if self._updateHp ~= nil then
        self._hp = math.min(self._hp, self._updateHp)
        self._hpInc = self._hp - self._maxHp
        if self._hpInc > 0 then self._maxHpInc = self._hpInc end
        self._updateHp = nil
    end
    self._haloedMaxHpInc = self._maxHpInc
end

function _M:resetAtk()
    self._atk = self._maxAtk
    self._maxAtkInc = 0
    self._atkInc = 0
    if self._updateInitAtk ~= nil then
        self._atk = math.min(self._atk, self._updateInitAtk)
        self._atkInc = sekf._atk - self._maxAtk
        if self._atkInc > 0 then self._maxAtkInc = self._atkInc end
    end    
    if self._updateAtk ~= nil then
        self._atk = math.min(self._atk, self._updateAtk)
        self._atkInc = self._atk - self._maxAtk
        if self._atkInc > 0 then self._maxAtkInc = self._atkInc end
        self._updateAtk = nil
    end
    self._haloedMaxAtkInc = self._maxAtkInc
end


--------------------------------
-- positive/negative buff related
--------------------------------

function _M:resetBuff(isPositive)
    if isPositive == nil then
        self._positiveStatus = {}
        self._positiveValues = {}
        self._negativeStatus = {}
        self._negativeValues = {}
        self:resetBuff(true)
        self:resetBuff(false)
    else
        local buffCount = isPositive and BattleData.PositiveType.count or BattleData.NegativeType.count
        for i = 1, buffCount do 
            self:resetBuffByType(isPositive, i)
        end 
    end
end

function _M:resetBuffByType(isPositive, buffType)
    local buffStatus = isPositive and self._positiveStatus or self._negativeStatus
    local buffValues = isPositive and self._positiveValues or self._negativeValues

    buffStatus[buffType] = false
    buffValues[buffType] = 0

    local i = 1
    while true do
        local underSkill = self._underSkills[i]
        if underSkill == nil then break end
        if (isPositive and underSkill._positiveType == buffType) or (not isPositive and underSkill._negativeType == buffType) then
            table.remove(self._underSkills, i)
        else
            i = i + 1
        end
    end
end

function _M:accountBuffValue(isPositive, buffType)
    local buffStatus = isPositive and self._positiveStatus or self._negativeStatus
    local buffValues = isPositive and self._positiveValues or self._negativeValues
    
    local val, aggregateType = 0, nil
    for i = 1, #self._underSkills do
        local underSkill = self._underSkills[i]
        if underSkill._disabled ~= true then
            if (isPositive and underSkill._positiveType == buffType) or (not isPositive and underSkill._negativeType == buffType) then
                if aggregateType == nil then
                    aggregateType = underSkill._aggregateType
                    val = (aggregateType == Data.AggregateType.table) and {} or 0
                end
                
                if aggregateType == Data.AggregateType.sum then val = val + underSkill._value
                elseif aggregateType == Data.AggregateType.max then val = math.max(val, underSkill._value)
                elseif aggregateType == Data.AggregateType.min then val = math.min(val, underSkill._value)
                elseif aggregateType == Data.AggregateType.table then 
                    local isExist = false
                    for i = 1, #val do 
                        if val[i] == underSkill._negativeValues then isExist = true break end
                    end
                    if not isExist then table.insert(val, underSkill._value) end
                end 
            end
        end
    end

    buffValues[buffType] = val
end

function _M:getBuffValue(isPositive, buffType)
    local buffValues = isPositive and self._positiveValues or self._negativeValues
    return buffValues and buffValues[buffType] or 0
end

function _M:modifyBuffValue(isPositive, buffType, newValue)
    for i = 1, #self._underSkills do
        local underSkill = self._underSkills[i]
        if (isPositive and underSkill._positiveType == buffType) or (not isPositive and underSkill._negativeType == buffType) then
            underSkill._value = newValue
        end
    end
    self:accountBuffValue(isPositive, buffType)
end


function _M:hasBuff(isPositive, buffType)
    local buffStatus = isPositive and self._positiveStatus or self._negativeStatus
    if buffStatus == nil then return false end

    local buffCount = isPositive and BattleData.PositiveType.count or BattleData.NegativeType.count
    for i = 1, buffCount do
        if (buffType == nil or buffType == i) and buffStatus[i] == true then 
            return true 
        end
    end

    return false
end

function _M:hasBuffGroup(isPositive, buffGroup)
    local buffStatus = isPositive and self._positiveStatus or self._negativeStatus
    if buffStatus == nil then return false end

    local buffCount = isPositive and BattleData.PositiveType.count or BattleData.NegativeType.count
    for i = 1, buffCount do
        for j = 1, #buffGroup do
            if (i == buffGroup[j]) and buffStatus[i] == true then 
                return true 
            end
        end
    end

    return false
end

function _M:resetBuffAfterRemove(isPositive, buffType)
    local i = 1
    local needRemove = true
    while true do
        local underSkill = self._underSkills[i]
        if underSkill == nil then break end
        if (isPositive and underSkill._positiveType == buffType) or (not isPositive and underSkill._negativeType == buffType) then
            needRemove = false
            break
        end
        i = i + 1
    end

    if needRemove then 
        if isPositive then self._owner:decPositiveStatus(self, buffType, false, self._id, 0, Data.SkillMode.once)
        else self._owner:decNegativeStatus(self, buffType, false, self._id, 0, Data.SkillMode.once)
        end
    else 
        self:accountBuffValue(isPositive, buffType)
    end
end

--------------------------------
-- shield related
--------------------------------

function _M:getShieldValue(buffType)
    local buffValues = self:getBuffValue(true, buffType)
    if type(buffValues) ~= 'table' then return 0 end
    local maxValue = 0
    local onlyOneRound = true
    for i = 1, #buffValues do
        maxValue = math.max(maxValue, buffValues[i] % 0x10000)
        if buffValues[i] < 0x10000 then onlyOneRound = false end
    end
    return maxValue, onlyOneRound
end

function _M:hasShield()
    for i = BattleData.PositiveType.shieldHaloBegin, BattleData.PositiveType.shieldExEnd do
        if self:hasBuff(true, i) then
            return true
        end
    end
    return false
end

function _M:hasShieldInType(typeAfterShieldBegin)
    return self:hasBuff(true, typeAfterShieldBegin) 
        or self:hasBuff(true, typeAfterShieldBegin - BattleData.PositiveType.shieldBegin + BattleData.PositiveType.shieldHaloBegin)
        or self:hasBuff(true, typeAfterShieldBegin - BattleData.PositiveType.shieldBegin + BattleData.PositiveType.shieldExBegin)
end

function _M:hasShieldExInType(typeAfterShieldBegin)
    return self:hasBuff(true, typeAfterShieldBegin - BattleData.PositiveType.shieldBegin + BattleData.PositiveType.shieldHaloBegin)
        or self:hasBuff(true, typeAfterShieldBegin - BattleData.PositiveType.shieldBegin + BattleData.PositiveType.shieldExBegin)
end

function _M:decShieldWhenRoundBegin()
    for i = BattleData.PositiveType.shieldBegin, BattleData.PositiveType.shieldExEnd do
        if self:hasBuff(true, i) then
            local removed = false
            local j = 1
            while true do
                local underSkill = self._underSkills[j]
                if underSkill == nil then break end
                if underSkill._positiveType == i and underSkill._value >= 0x10000 then
                    table.remove(self._underSkills, j)
                    removed = true
                    break
                else
                    j = j + 1
                end
            end

            if removed then self:resetBuffAfterRemove(true, i) end
        end
    end
end

--------------------------------
-- mark related
--------------------------------

function _M:addMark(buffType, count, cid, id, mode)
    local addCount = count
    local currentCount = self:getBuffValue(true, buffType)

    if buffType == BattleData.PositiveType.waterMark and self:hasSkills({2005}) then
        addCount = math.max(0, math.min(3 - currentCount, addCount))
    end

    if addCount > 0 then
        --[[
        if (buffType == BattleData.PositiveType.magicMark and self:hasSkills({6055, 6078, 6123}))
            or (buffType == BattleData.PositiveType.deathMark and self:hasSkills({6105})) 
            or (buffType == BattleData.PositiveType.satelliteMark and self:hasSkills({3400})) then
            self._owner:setCardStatus(self._owner._fortress, BattleData.CardStatus.fortress, BattleData.CardStatusVal.f2f_halo, cid, id, mode)
        end
        ]]

        for i = 1, addCount do
            self._owner:incPositiveStatus(self, buffType, false, cid, id, mode)
            self._owner:incPositiveValue(self, buffType, 1, Data.AggregateType.sum, cid, id, mode)
        end
        return true
    else
        return false
    end
end

function _M:removeMark(buffType, count)
    local existCount = self:getBuffValue(true, buffType)
    if existCount <= 0 then return false end

    --[[
    if (buffType == BattleData.PositiveType.magicMark and self:hasSkills({6055, 6078, 6123}))
        or (buffType == BattleData.PositiveType.deathMark and self:hasSkills({6105})) 
        or (buffType == BattleData.PositiveType.satelliteMark and self:hasSkills({3400})) then
        self._owner:setCardStatus(self._owner._fortress, BattleData.CardStatus.fortress, BattleData.CardStatusVal.f2f_halo, cid, id, mode)
    end
    ]]

    local removeCount = 0
    local i = 1
    while true do
        local underSkill = self._underSkills[i]
        if underSkill == nil then break end
        if underSkill._positiveType == buffType then
            table.remove(self._underSkills, i)
            removeCount = removeCount + 1
            if removeCount == count then break end
            i = i - 1
        end
        i = i + 1
    end

    return removeCount
end


-----------------------------------
-- skill helper
-----------------------------------

function _M:baseResetSkills()
    for i = 1, #self._info._skillId do
        local skillId = self._info._skillId[i]
        if skillId == 0 then 
            break 
        end
        local skillInfo = Data._skillInfo[skillId]
        local skill = B.createSkill(skillId, 1, self)
        table.insert(self._skills, skill)
    end
end

function _M:resetSkills()
    for _, skill in ipairs(self._skills) do
        skill._level = skill._maxLevel
        skill._castTimes = 0
        skill._totalCastedTimes = 0
    end
end

function _M:addSkill(infoId, level, provider)
    for i = 1, #self._skills do
        local skill = self._skills[i]
        if skill._id == infoId then
            if skill._maxLevel < level then
                if skill._saved == nil then
                    skill._saved = {_maxLevel = skill._maxLevel, _provider = skill._provider}
                end
                skill._maxLevel = math.min(level, CardHelper.getSkillMaxLevel(infoId))
                skill._provider = provider
                self:updateSkillLevel()
            end
            return skill
        end
    end
    
    -- not exist, add one
    local skill = B.createSkill(infoId, level, self)
    skill._provider = provider
    table.insert(self._skills, skill)
    return skill
end

function _M:removeSkill(infoId, provider)
    for i = 1, #self._skills do
        local skill = self._skills[i]
        if skill._id == infoId and skill._provider == provider then
            if skill._saved ~= nil then
                skill._maxLevel = skill._saved._maxLevel
                skill._provider = skill._saved._provider
                skill._saved = nil
                self:updateSkillLevel()
            else
                table.remove(self._skills, i)
            end
            return
        end
    end
end

function _M:removeSkills(provider)
    local savedTotalCastedTimes = {}

    local i = 1
    while true do
        local skill = self._skills[i]
        if skill == nil then break end
        if skill._provider == provider then
            savedTotalCastedTimes[skill._id] = skill._totalCastedTimes
            if skill._saved ~= nil then
                skill._maxLevel = skill._saved._maxLevel
                skill._provider = nil
                skill._saved = nil
                self:updateSkillLevel()
                i = i + 1
            else
                table.remove(self._skills, i)
            end
        else
            i = i + 1
        end
    end

    return savedTotalCastedTimes
end

function _M:getSkillById(id)
    for i = 1, #self._skills do
        local skill = self._skills[i]
        if skill._id == id then
            return skill
        end
    end
end

function _M:getSkillsByProvider(provider)
    local skills = {}
    for i = 1, #self._skills do
        local skill = self._skills[i]
        if skill._provider == provider then
            table.insert(skills, skill)
        end
    end
    return skills
end

function _M:accountExtraSkill()
    local savedTotalCastedTimes = self:removeSkills(BattleData.SkillProvider.extra)

    local val = self:getBuffValue(true, BattleData.PositiveType.extraSkill)
    if val ~= nil and type(val) == "table" and #val > 0 then
        for i = 1, #val do
            local skillInfoId = val[i] % 0x10000
            local skillLevel = math.floor(val[i] / 0x10000)
            local skill = self:addSkill(skillInfoId, skillLevel, BattleData.SkillProvider.extra)
            if savedTotalCastedTimes[skillInfoId] ~= nil then
                skill._totalCastedTimes = savedTotalCastedTimes[skillInfoId]
            end
        end
    end
end

function _M:updateSkillLevel()
    local skillLevelInc = self._skillLevelInc
    for i = 1, #self._underSkills do
        local underSkill = self._underSkills[i]
        if underSkill._disabled ~= true then 
            if underSkill._skillLevelInc ~= nil then
                skillLevelInc = skillLevelInc + underSkill._skillLevelInc 
            end
        end
    end

    for i = 1, #self._skills do
        local skill = self._skills[i]
        skill._level = math.min(skill._maxLevel + skillLevelInc, CardHelper.getSkillMaxLevel(skill._id))
    end
end

function _M:getSkillByMode(mode, index)
    local skills = {}
    
    if self:isMonster() then
        if mode == Data.SkillMode.initiative then
            if self:hasBuff(false, BattleData.NegativeType.chaos) then
                local skill = B.createSkill(50005, 1, self)
                table.insert(skills, skill)
            end

            table.insert(skills, self:getSkillById(self._ids[2]))
            return skills[index]
        end

        for i = 1, #self._skills do
            local skill = self._skills[i]
            if B.skillHasMode(skill, mode) then
                table.insert(skills, skill)
            end
        end

        if self:isMonster() then
            local bindCard = self._binds[1] or self._prevBindCard
            local skill = bindCard and bindCard._skills[1]
            if skill and B.skillHasMode(skill, mode) then 
                table.insert(skills, skill) 
            end
        end

        if mode == Data.SkillMode.round_begin then
            if self:hasBuff(false, BattleData.NegativeType.sleep) then
                local skill = B.createSkill(50001, 1, self)
                table.insert(skills, skill)
            end
        elseif mode == Data.SkillMode.round_end then
            if self:hasBuff(false, BattleData.NegativeType.poison) then
                local skill = B.createSkill(50002, 1, self)
                table.insert(skills, skill)
            elseif self:hasBuff(false, BattleData.NegativeType.numb) then
                local skill = B.createSkill(50003, 1, self)
                table.insert(skills, skill)
            end
        elseif mode == Data.SkillMode.under_spell_damage then
            if self:hasBuff(true, BattleData.PositiveType.ignoreOppoMonsterSkillDamageHalo) then
                local skill = B.createSkill(51001, 1, self)
                table.insert(skills, skill)
            end
            if self:hasBuff(true, BattleData.PositiveType.ignoreOppoMonsterSkillHalo) then
                local skill = B.createSkill(51002, 1, self)
                table.insert(skills, skill)
            end
        end

        -- fortressSkill
        if self._owner._fortressSkill ~= nil and B.skillHasMode(self._owner._fortressSkill, mode) then
            table.insert(skills, self._owner._fortressSkill)
        end
        -- shields
        for i = BattleData.PositiveType.shieldBegin, BattleData.PositiveType.shieldEnd do
            if self:hasBuff(true, i) then
                local skillInfo = Data._skillInfo[i - BattleData.PositiveType.shieldBegin + 11001]
                local skill = {_id = skillInfo._id, _maxLevel = 1, _level = self._level, _modes = skillInfo._modes, _priority = skillInfo._priority, _count = skillInfo._count, _owner = self, _totalCastedTimes = 0}
                if B.skillHasMode(skill, mode) then
                    table.insert(skills, skill)
                end
            end
        end
        for i = 0, BattleData.PositiveType.shieldExEnd - BattleData.PositiveType.shieldExBegin do
            if self:hasBuff(true, BattleData.PositiveType.shieldExBegin + i) or self:hasBuff(true, BattleData.PositiveType.shieldHaloBegin + i) then
                local skillInfo = Data._skillInfo[i + 12001]
                local skill = {_id = skillInfo._id, _maxLevel = 1, _level = self._level, _modes = skillInfo._modes, _priority = skillInfo._priority, _count = skillInfo._count, _owner = self, _totalCastedTimes = 0}
                if B.skillHasMode(skill, mode) then
                    table.insert(skills, skill)
                end
            end
        end

    elseif self._type == Data.CardType.magic then
        for i = 1, #self._skills do
            local skill = self._skills[i]
            if B.skillHasMode(skill, mode) then table.insert(skills, skill) end
        end

        if mode == Data.SkillMode.round_begin or mode == Data.SkillMode.round_end then
            if self._owner._fortressSkill ~= nil and B.skillHasMode(self._owner._fortressSkill, mode) then
                table.insert(skills, self._owner._fortressSkill)
            end
        end

    elseif self._type == Data.CardType.trap then
        for i = 1, #self._skills do
            local skill = self._skills[i]        
            if B.skillHasMode(skill, mode) then table.insert(skills, skill) end
        end

    elseif self._type == Data.CardType.fortress then
        if mode == Data.SkillMode.round_begin then
            if self:hasBuff(false, BattleData.NegativeType.powerLock) then
                local skill = B.createSkill(50004, 1, self)
                table.insert(skills, skill)
            end
        end

    end

    -- halo mode spell
    local haloType = nil
    if mode == Data.SkillMode.magic then
        haloType = Data.SkillMode.magic_casted
    elseif mode == Data.SkillMode.trap then
        haloType = Data.SkillMode.trap_casted
    elseif mode == Data.SkillMode.fortress_damaged then
        haloType = Data.SkillMode.fortress_damaged
    elseif mode == Data.SkillMode.bcs2gl then
        haloType = Data.SkillMode.card_destroyed_from_bcs
    elseif mode == Data.SkillMode.h2g_by_self or mode == Data.SkillMode.h2g_by_oppo then
        haloType = Data.SkillMode.card_destroyed_from_hand
    elseif mode == Data.SkillMode.p2g_by_self or mode == Data.SkillMode.p2g_by_oppo then
        haloType = Data.SkillMode.card_destroyed_from_pile
    end
    if haloType ~= nil then
        self._haloSkills = self._haloSkills or {}
        if index == 0 then 
            self._haloSkills[haloType] = B.mergeTable({self._owner:getHaloModeSkills(haloType), self._owner._opponent:getHaloModeSkills(haloType + 1)})
        end
        local haloSkills = self._haloSkills[haloType] or {}
        for i = 1, #haloSkills do table.insert(skills, haloSkills[i]) end
    end

    -- sort skills by priority
    table.sort(skills, function(a, b)  
        if a._priority < b._priority then return true
        elseif a._priority > b._priority then return false
        elseif a._id < b._id then return true
        elseif a._id > b._id then return false
        else return a._owner._id < b._owner._id   
        end
    end)

    return skills[index]
end

function _M:saveSkillCastTimes()
    local skillCastTimes = {}
    if self:isMonster() then
        for index, skill in ipairs(self._skills) do
            skillCastTimes[index] = skill._castTimes
        end
    end
    return skillCastTimes
end

function _M:loadSkillCastTimes(skillCastTimes)
    if next(skillCastTimes) ~= nil then
        for index, skill in ipairs(self._skills) do
            skill._castTimes = skillCastTimes[index] or 0
        end
    end
end

function _M:hasSkills(skills)
    for i = 1, #self._skills do
        local skillId = self._skills[i]._id
        for j = 1, #skills do
            if skillId == skills[j] then
                return true
            end
        end
    end
    return false
end

function _M:hasSkillInMode(mode)
    for i = 1, #self._skills do
        local skill = self._skills[i]
        if B.skillHasMode(skill, mode) then
            return true, skill
        end
    end
    return false
end

function _M:hasChoiceSkill()
    for i = 1, #self._skills do
        local skill = self._skills[i]
        if B.skillHasMode(skill, Data.SkillMode.choice) then
            return true, skill
        end
    end
    return false
end

function _M:hasNoGemSkill()
    for i = 1, #self._skills do
        local skill = self._skills[i]
        local info = Data._skillInfo[skill._id]
        if info._needNoGem == 1 then
            return true, skill
        end
    end
    return false
end

function _M:hasNeedExtraGemSkill()
    for i = 1, #self._skills do
        local skill = self._skills[i]
        local skillInfo = Data._skillInfo[skill._id]
        if skillInfo._needExtraGem == 1 then
            return true
        end
    end
    return false
end

function _M:hasDefendRuseSkill()
    --return self:hasSkills({2023, 2045}, true)
    return false
end

function _M:hasTargetUsingSkill()
    for i = 1, #self._skills do
        local skill = self._skills[i]
        local skillInfo = Data._skillInfo[skill._id]
        if skillInfo._targetType ~= 0 then
            return true, skill
        end
    end
    return false
end

function _M:getSkillVal(skillId)
    if self:isMonster() then
        for i = 1, #self._skills do
            if skillId == self._skills[i]._id then
                return Data._skillInfo[skillId]._val[self._skills[i]._level]
            end
        end
    end
    return 0
end

function _M:incSkillMaxLevel(skillId, inc)
    local oldInc = self._skillMaxLevelInc[skillId] or 0
    oldInc = oldInc + inc
    self._skillMaxLevelInc[skillId] = oldInc
end

function _M:getUnderSkillIndex(skillId)
    local skillType = math.floor(skillId / Data.INFO_ID_GROUP_SIZE)
    local skillIds = {}
    for i = 1, #self._underSkills do
        local underSkill = self._underSkills[i]
        local underSkillType = math.floor(underSkill._sid / Data.INFO_ID_GROUP_SIZE)
        if not underSkill._disabled and underSkillType == skillType then
            local isExist = false
            for j = 1, #skillIds do
                if skillIds[j] == underSkill._sid then
                    isExist = true
                    break
                end
            end
            if not isExist then skillIds[#skillIds + 1] = underSkill._sid end 
        end
    end
    local index = 1
    for i = 1, #skillIds do
        if skillIds[i] == skillId then 
            index = i
            break
        end
    end
    return index
end

function _M:saveExtraSkills()
    local savedExtraSkills = {}

    if self:isMonster() then
        for index, skill in ipairs(self._skills) do
            if (skill._provider == BattleData.SkillProvider.extra or skill._provider == BattleData.SkillProvider.given) then
                -- 1. b2g
                if self._sourceStatus == BattleData.CardStatus.board and (self._destStatus == BattleData.CardStatus.grave or self._destStatus == BattleData.CardStatus.leave) then  
                    if B.skillHasMode(skill, Data.SkillMode.bcs2gl) or skill._id == 3067 or skill._id == 6045 then
                        savedExtraSkills[#savedExtraSkills + 1] = skill
                    end

                -- 2. 5096
                elseif self._statusVal == BattleData.CardStatusVal.g2b_5096 then
                    savedExtraSkills[#savedExtraSkills + 1] = skill

                end 

            end
        end
    end

    return savedExtraSkills
end

function _M:loadExtraSkills(savedExtraSkills)
    if #savedExtraSkills ~= 0 then
        for i = 1, #savedExtraSkills do
            self._skills[#self._skills + 1] = savedExtraSkills[i]
        end
    end
end

function _M:getMaxSkillPower()
    local maxPower = 0
    for i = 1, #self._skills do
        local skillId = self._skills[i]._id
        if Data._skillInfo[skillId]._power > maxPower then
            maxPower = Data._skillInfo[skillId]._power
        end
    end
    return maxPower
end

-----------------------------------
-- under skill helper
-----------------------------------

function _M:disableUnderSkill(underSkill, cid, sid, mode)
    if underSkill._ignoreDisable == true then return false end

    -- toggle's diasbled is oppo from parent, trigger's disadbled is same with parent
    table.insert(self._underSkills, {_cid = cid, _sid = sid, _mode = mode, _toggle = underSkill})
    
    underSkill._disabled = true
    if underSkill._trigger ~= nil then
        underSkill._trigger._disabled = true
    end

    if underSkill._toggle ~= nil then
        underSkill._toggle._disabled = false
        if underSkill._toggle._trigger ~= nil then
            underSkill._toggle._trigger._disabled = false
        end
    end

    if underSkill._bind ~= nil and (underSkill._bind._type == Data.CardType.magic or underSkill._bind._type == Data.CardType.trap) then
        self._owner:setCardStatus(underSkill._bind, BattleData.CardStatus.grave, cid, sid, mode)
    end 

    return true
end


function _M:disableUnderSkillByIds(skillIds, skillMode, cid, sid, mode)
    local disabled = false
    
    for i = 1, #self._underSkills do
        local underSkill = self._underSkills[i]
        if underSkill._disabled ~= true then
            for j = 1, #skillIds do
                if underSkill._sid == skillIds[j] and (skillMode == nil or skillMode == underSkill._mode) then
                    if self:disableUnderSkill(underSkill, cid, sid, mode) then
                        disabled = true
                    end
                    break
                end
            end
        end
    end
    
    return disabled
end

function _M:disableUnderSkillByType(skillType, cid, sid, mode)
    local disabled = false
    
    for i = 1, #self._underSkills do
        local underSkill = self._underSkills[i]
        if underSkill._disabled ~= true and (math.floor(underSkill._sid / Data.INFO_ID_GROUP_SIZE)) == skillType and underSkill._mode ~= Data.SkillMode.halo then
            if self:disableUnderSkill(underSkill, cid, sid, mode) then
                disabled = true 
            end
        end
    end
    
    return disabled
end

function _M:disableUnderSkillByOppoMonsterDamage(cid, sid, mode)
    local disabled = false
    
    for i = 1, #self._underSkills do
        local underSkill = self._underSkills[i]
        if underSkill._disabled ~= true and underSkill._directDamageMark ~= true then
            local card = self._owner:getCardById(underSkill._cid)
            if card ~= nil and card:isMonster() and card._owner ~= self._owner then
                if underSkill._hpInc ~= nil and underSkill._hpInc < 0 then
                    if self:disableUnderSkill(underSkill, cid, sid, mode) then
                        disabled = true 
                    end
                end
            end
        end
    end
    
    return disabled
end

function _M:disableUnderSkillByOppoMonster(cid, sid, mode)
    local disabled = false
    
    for i = 1, #self._underSkills do
        local underSkill = self._underSkills[i]
        if underSkill._disabled ~= true then
            local card = self._owner:getCardById(underSkill._cid)
            if card ~= nil and card:isMonster() and card._owner ~= self._owner then
                if self:disableUnderSkill(underSkill, cid, sid, mode) then
                    disabled = true 
                end
            end
        end
    end
    
    return disabled
end

function _M:disableUnderSkillByBuff(isPositive, buffType, cid, sid, mode)
    local disabled = false
    
    for i = 1, #self._underSkills do
        local underSkill = self._underSkills[i]
        if (isPositive and underSkill._incPositive == buffType) or (not isPositive and underSkill._incNegative == buffType) then
            if self:disableUnderSkill(underSkill, cid, sid, mode) then
                disabled = true 
            end
        end
    end
    
    return disabled
end

function _M:removeUnderSkillByRemoveMode(removeMode)
    local index = 1
    while true do
        local underSkill = self._underSkills[index]
        if underSkill == nil then 
            break
        end

        if not (underSkill._sid == 0 or underSkill._mode == Data.SkillMode.halo) and B.skillInfoHasRemoveMode(Data._skillInfo[underSkill._sid], removeMode) then
            table.remove(self._underSkills, index)
        else
            index = index + 1
        end
    end
end

function _M:underSkillHasMode(mode)
    for i = 1, #self._underSkills do
       local underSkill = self._underSkills[i]
       if underSkill._mode == mode then return true end
    end

    return false
end

function _M:underSkillHasType(skillType)
    for i = 1, #self._underSkills do
        local underSkill = self._underSkills[i]
        if (math.floor(underSkill._sid / Data.INFO_ID_GROUP_SIZE)) == skillType then return true end
    end
    
    return false
end

function _M:isUnderSkillHaloedBySelfExtraSkill(underSkill)
    if underSkill._cid ~= self._id or underSkill._mode ~= Data.SkillMode.halo then return false end

    for i = 1, #self._skills do
        local skill = self._skills[i]
        if underSkill._sid == skill._id and 
            ((skill._provider == nil) or 
             (skill._saved and (skill._saved._provider == nil))) then
            return false
        end
    end

    return true
end

function _M:advanceLastUnderSkill(advance)
    local underSkill = self._underSkills[#self._underSkills]
    if underSkill ~= nil then
        underSkill._advance = advance
    end
end

function _M:hasAdvanceUnderSkill()
    for i = 1, #self._underSkills do
        if self._underSkills[i]._advance ~= nil then
            return true
        end
    end
    return false
end

function _M:hasUnderSkillByDamageFrom(fromCard)
   for i = 1, #self._underSkills do
        local underSkill = self._underSkills[i]
        if underSkill._disabled ~= true and underSkill._removable == false 
            and underSkill._hpInc ~= nil and underSkill._hpInc < 0 and underSkill._cid == fromCard._id then
            return true
        end
    end
    return false 
end


-----------------------------------
-- bind
-----------------------------------

function _M:addBind(card)
    for i = 1, #self._binds do
        if self._binds[i] == card then return end
    end
    self._binds[#self._binds + 1] = card
end

function _M:removeBind(card)
    for i = 1, #self._binds do
        if self._binds[i] == card then 
            table.remove(self._binds, i)
            break
        end
    end
end

function _M:removeBinds()
    self._binds = {}
end

function _M:isBinded(infoId)
    for i = 1, #self._binds do
        if self._binds[i]._infoId == infoId then
            return true
        end
    end
    return false
end

function _M:isBindedSkill(skillId)
    for i = 1, #self._binds do
        if self._binds[i]:hasSkills({skillId}) then
            return true
        end
    end
    return false
end

-----------------------------------
-- board helper
-----------------------------------

function _M:isBoardCard()    
    return self._type ~= Data.CardType.fortress
end

function _M:isAlive()
    if self:isMonster() then
        return self._status == BattleData.CardStatus.board and self._hp > 0
    elseif self._type == Data.CardType.fortress then
        return self._hp > 0
    elseif self._type == Data.CardType.magic then
        --
    elseif self._type == Data.CardType.trap then
        --
    end
    
    return false
end

function _M:hasChangeStatusUnderSkill(statusTable)
    for i = 1, #self._underSkills do
        local underSkill = self._underSkills[i]
        for j = 1, #statusTable do
            if underSkill._status == statusTable[j] then
                return true
            end
        end
    end
    return false
end

function _M:isDying()
    return self:isChangingToStatus({BattleData.CardStatus.grave, BattleData.CardStatus.leave})
end

function _M:isUsing()
    return self:isChangingToStatus({BattleData.CardStatus.board})
end

function _M:isToOppoBoard()
    return self:isChangingWithStatusVal({BattleData.CardStatusVal.b2b_oppo_once, BattleData.CardStatusVal.b2b_oppo_forever})    
end

function _M:isChangingToStatus(statusTable)
    local saved = self._owner:getActionPlayer()
    
    while true do
        if saved == nil then break end
        local cardStatusToChange = saved._cardStatusToChange
        if cardStatusToChange == nil then break end

        for i = 1, #cardStatusToChange do
            local statusChangeNode = cardStatusToChange[i]
            for j = 1, #statusTable do
                if statusChangeNode._card == self and statusChangeNode._destStatus == statusTable[j] then
                    return true
                end
            end
        end

        saved = saved._saved
    end

    return false
end

function _M:isChangingWithStatusVal(statusValTable)
    local saved = self._owner:getActionPlayer()
    
    while true do
        if saved == nil then break end
        local cardStatusToChange = saved._cardStatusToChange
        if cardStatusToChange == nil then break end

        for i = 1, #cardStatusToChange do
            local statusChangeNode = cardStatusToChange[i]
            for j = 1, #statusValTable do
                if statusChangeNode._card == self and statusChangeNode._statusVal == statusValTable[j] then
                    return true
                end
            end
        end

        saved = saved._saved
    end

    return false
end

function _M:canAction()
    return self._actionIndex <= self._actionCount --and self._hp > 0
end

function _M:isHurt()
    return self._hp < self._maxHp + self._haloedMaxHpInc
end

function _M:isAtkHide()
    return self._info._option ~= nil and band(self._info._option, Data.CardOption.hide_atk) > 0
end

function _M:isDefHide()
    return self._info._option ~= nil and band(self._info._option, Data.CardOption.hide_def) > 0
end

function _M:setDieStat()
    self._prevBoardPos = self._pos 
    self._prevAtk = self._atk
    self._dieRound = math.max(self._owner._round, self._owner._opponent._round)
    self._dieByEffect = self._statusVal ~= BattleData.CardStatusVal.b2g_sacrifice
    self._dieCount = self._dieCount + 1
end

-----------------------------------
-- getter
-----------------------------------

function _M:getQuality()
    return CardHelper.getCardQuality(self)
end

function _M:getCost()
    return CardHelper.getCardCost(self)
end

function _M:getSkillLevel(index)
    return self._level
end

function _M:getAtk()
    return self._atk
end

function _M:getHp()
    return self._hp
end

function _M:getStar()
    return CardHelper.getCardStar(self)
end

function _M:getOriginOwner()
    return self._isBorrowed == true and self._owner._opponent or self._owner
end

function _M:isMonster()
    return self._type == Data.CardType.monster
end

function _M:getOriginId()
    if self:hasSkills({3113}) and (self._status == BattleData.CardStatus.board or self._status == BattleData.CardStatus.grave) then
        return Data._skillInfo[3113]._refCards[1]
    end
    return Data.getOriginId(self._infoId)
end

function _M:isV12()
    return self._infoId == 10407
end

--------------------------------
-- test
--------------------------------

function _M:testSkills()
    local sids = {}
    if self:isMonster() then
        sids = {}
        --self._skills = {}
        
    elseif self._type == Data.CardType.magic then
        sids = {}
        --self._skills = {}
        --sids = {self._infoId == 20016 and 4021 or 7026}

    elseif self._type == Data.CardType.trap then
        sids = {}
        --self._skills = {}
        --sids = {self._infoId ~= 30001 and 5006 or 5035}

    end

    for _, sid in ipairs(sids) do
        local hasSkill = false 
        for i = 1, #self._skills do
            if self._skills[i]._id == sid then
                hasSkill = true
                break
            end
        end
        if not hasSkill then
            local skillInfo = Data._skillInfo[sid]
            local skill = {_id = sid, _maxLevel = CardHelper.getSkillMaxLevel(sid), _modes = skillInfo._modes, _priority = skillInfo._priority, _count = skillInfo._count, _owner = self}
            table.insert(self._skills, skill)
        end
    end
end



return _M