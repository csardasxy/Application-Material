local _M = class("ChapterLevel")

function _M:ctor(cityChapterInfo)
    self._chapterId = cityChapterInfo._chapter
    self._chapterInfo = cityChapterInfo
    
    self._conditions = {}
    local conditionIds = cityChapterInfo._condition 
    for i = 1, #conditionIds do
        local condition = Data._conditionInfo[conditionIds[i]]
        table.insert(self._conditions, condition)
    end
    
    -- Generate troop cards
    self._troopCards = {}
    local troopId = cityChapterInfo._opponentTroopID
    local troopInfo = Data._troopInfo[troopId]
    local equips = {}
    for i = 1, #troopInfo._infoId do
        local card = require("Card").create(troopInfo._infoId[i])
        card._id = 1        -- It belongs to some troop
        card._level = troopInfo._level[i]
        if card:isMonster() then
            card._weaponId = troopInfo._weapon[i]
            card._armorId = troopInfo._armor[i]
            table.insert(self._troopCards, card)
        elseif card._type == Data.CardType.weapon or card._type == Data.CardType.armor then
            card._newSkillId = troopInfo._newSkillId[i]
            card._newSkillLevel = troopInfo._newSkillLevel[i]
            equips[troopInfo._cardId[i]] = card
        else            
            table.insert(self._troopCards, card)
        end
    end
    
    for i = 1, #self._troopCards do
        local card = self._troopCards[i]
        if card:isMonster() then
            card._weapon = equips[card._weaponId]
            card._armor = equips[card._armorId]
            if card._weapon then card._weapon._ownerData = card end
            if card._armor then card._armor._ownerData = card end

            card._weaponId = 0
            card._armorId = 0
        end
        card._troop = self._troopCards
    end 
    self._troopNameSid = troopInfo._nameSid

    -- Append event cards troop
    if self._chapterId == 1 then
        self:appendEventTroop()
    end
end

function _M:appendEventTroop()
    local cityChapterInfo = self._chapterInfo

    local createCard = function(data)
        local card = require("Card").create(data.id)
        card._evel = data.lv or 1
        
        if data.si then card._newSkillId = data.si end
        if data.sa then card._newSkillLevel = data.sa end

        return card
    end

    for _, eventId in ipairs(cityChapterInfo._oppoEventId) do
        local eventInfo = Data._eventInfo[eventId]
        if eventInfo then
            for i, effectId in ipairs(eventInfo._effect) do
                if effectId == 2 then
                    local val = eventInfo._effectValue[i]
                    if val.c.troop and val.c.troop == 1 then
                        local card = createCard(val.c)

                        if val.w then
                            local weapon = createCard(val.w)
                            card._weapon = weapon
                            weapon._ownerData = card
                        end
    
                        if val.a then
                            local armor = createCard(val.a)
                            card._armor = armor
                            armor._ownerData = card
                        end

                        table.insert(self._troopCards, card)
                    end
                end
            end
        end
    end
end

function _M:getConditions()
    return self._conditions
end

function _M:getDrops(isFirst)
    if isFirst then
        return self._chapterInfo._firstPid
    else
        return self._chapterInfo._pid
    end
end

function _M:getTroopCards()
    return self._troopCards
end

function _M:getTroopName()
    return Str(self._troopNameSid)
end

return _M
