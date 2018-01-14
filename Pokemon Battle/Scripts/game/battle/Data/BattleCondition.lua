local _M = class("BattleCondition")
BattleCondition = _M

function _M:ctor(player, conditions)
    self._player = player

    self._conditions = {}
    if next(conditions) ~= nil then
        for i = 1, #conditions._conditionIds do
            local conditionInfo = Data._conditionInfo[conditions._conditionIds[i]]
            if conditionInfo ~= nil then
                local condition = {_id = conditionInfo._id, _info = conditionInfo, _value = conditions._conditionValues[i]}
                table.insert(self._conditions, condition)
            end
        end
    end
end

---------------------------------------------------
-- method
---------------------------------------------------

function _M:reset()
    self._results = {}
end

function _M:getTaskResult()
    if next(self._results) == nil then
        for i = 1, #self._conditions do
            local condition = self._conditions[i]
            local result = self:castCondition(condition._id, condition._value)
            table.insert(self._results, result)
        end
    end
    
    return self._results
end

function _M:isAllSatisfied()
    local results = self:getTaskResult()
    
    for i = 1, #results do
        if not results[i] then
            return false
        end
    end
    
    return true
end

function _M:getIsWin()
    for i = 1, #self._conditions do
        local condition = self._conditions[i]
        if condition._id == 15 and self._player._macroStatus == BattleData.Status.round_begin and self._player._round > condition._value then
            return true
        elseif condition._id == 28 and self:castCondition(condition._id, condition._value) then
            return true
        end
    end
    return false
end

function _M:castCondition(id, val)
    local isSatisfied = false
    
    local player, opponent = self._player, self._player._opponent
    
    if id == 1 then
        if player:getResult() == Data.BattleResult.win then
            isSatisfied = true
        end
        
    elseif id == 2 then
        if #opponent._pileCards == 0 and #opponent:getBattleCards('B') == 0 then
            local count = 0
            for i = 1, #opponent._handCards do
                local handCard = opponent._handCards[i]
                if handCard ~= nil and handCard:isMonster() then
                    count = count + 1
                end
            end
            if count == 0 then
                isSatisfied = true
            end
        end
        
    elseif id == 3 then
        local round = math.max(player._round, opponent._round)
        if player:getResult() == Data.BattleResult.win and round <= val then
            isSatisfied = true
        end
    
    elseif id == 4 then
        if player:getResult() == Data.BattleResult.win and #player._graveCards <= val then
            isSatisfied = true
        end
        
    elseif id == 5 then
        if player:getResult() == Data.BattleResult.win and (player._fortress._hp / player._fortress._maxHp) >= (val / 100) then
            isSatisfied = true
        end
        
    elseif id == 6 then
        if self:getCardCountByType() >= val then
            isSatisfied = true
        end
    
    elseif id >= 7 and id <= 9 then
        if self:getCardCountByType(id - 6) >= val then
            isSatisfied = true
        end

    elseif id == 10 then
        if self:getCardCountByMinStar(val) == 0 then 
            isSatisfied = true
        end
    
    elseif id == 11 then
        if self:getCardCountByNature(val) == 0 then 
            isSatisfied = true
        end

    elseif id == 12 then
        
    elseif id == 13 then
        
    elseif id == 14 then
        local event = player._battleEvent:getEventById(val) or opponent._battleEvent:getEventById(val)
        if event ~= nil and event._isCasted then
            isSatisfied = true
        end

    elseif id == 15 then
        if player._round >= val then
            isSatisfied = true
        end

    elseif id == 16 then
        if self:getCardCountByType() <= val then
            isSatisfied = true
        end

    elseif id >= 17 and id <= 19 then
        if self:getCardCountByType(id - 16) <= val then
            isSatisfied = true
        end

    elseif id == 21 then
        if opponent._cards[val] ~= nil and B.isAlive(opponent._cards[val]) then
           isSatisfied = true
        end

    elseif id >= 22 and id <= 25 then
        
    elseif id == 26 then
        
    elseif id == 27 then
        if opponent._fortress._hp <= 0 then
            isSatisfied = true
        end

    elseif id == 28 then
        if self._player._isAttacker and (self._player._destroyMonsterCount[0] or 0) >= val then
            isSatisfied = true
        end

    elseif id == 29 then
        local infoId = val % 100000
        local count = math.floor(val / 100000)
        if self._player._isAttacker and (self._player._destroyMonsterCount[infoId] or 0) >= count then
            isSatisfied = true
        end

    end
    
    return isSatisfied
end

---------------------------------------------------
-- function
---------------------------------------------------

function _M:getCardCountByType(cardType)
    local count = 0
    
    for i = 1, #self._player._troopCards do
        local card = self._player._troopCards[i]
        local type = Data.getType(card.info_id)
        if (cardType ~= nil and type == cardType) or (cardType == nil) then
            count = count + 1
        end
    end
    
    return count
end

function _M:getCardCountByMinStar(minStar)
    local count = 0
    
    for i = 1, #self._player._troopCards do
        local card = self._player._troopCards[i]
        local info, type = Data.getInfo(card.info_id)
        if type == Data.CardType.monster and info._star >= minStar then
            count = count + 1
        end
    end
    
    return count
end

function _M:getCardCountByNature(nature)
    local count = 0
    
    for i = 1, #self._player._troopCards do
        local card = self._player._troopCards[i]
        local info, type = Data.getInfo(card.info_id)
        if type == Data.CardType.monster and info._nature == nature then
            count = count + 1
        end
    end
    
    return count
end

function _M:getConditionDesc()
    if self._desc == nil then
        local strs = {}
        for i = 1, #self._conditions do
            local task = self._conditions[i]
            local str = string.format("%s", Str(task._info._descSid))
            local pos1, pos2, curVal = string.find(str, "%[(.-)%]")
            if task._value ~= nil and pos1 ~= nil and pos2 ~= nil and curVal ~= nil then
                local tempStr, suffixStr = nil, ''
                if task._id == 11 then
                    tempStr = Str(STR.NATURE_NONE + task._value)
                elseif task._id == 13 then
                    local info = Data._monsterInfo[task._value] or Data._bookInfo[task._value] or Data._horseInfo[task._value]
                    tempStr = Str(info._nameSid)
                elseif task._id == 14 then
                    tempStr = Str(Data._eventInfo[task._value]._nameSid)
                elseif task._id == 29 then
                    local infoId = task._value % 100000
                    local count = math.floor(task._value / 100000)
                    tempStr = ''..count
                    local info = Data.getInfo(infoId)
                    suffixStr = Str(info._nameSid)
                else
                    tempStr = task._value
                end
                str = string.gsub(str, "%["..curVal.."%]", tempStr)..suffixStr
            end
            table.insert(strs, str)
        end
        
        self._desc = strs
    end
    
    return self._desc
end

return _M
