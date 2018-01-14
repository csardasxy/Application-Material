local _M = PlayerBattle

-----------------------------------
-- card helper functions
-----------------------------------

function _M:getAllCards()
    local cards = {}
    local cardsById = {}

    local opponent = self._opponent

    local boardCards = self:getBattleCards('B')
    for i = 1, #boardCards do
        local card = boardCards[i]
        cards[#cards + 1] = card
        cardsById[card._id] = card
    end
    local boardCards = opponent:getBattleCards('B')
    for i = 1, #boardCards do
        local card = boardCards[i]
        cards[#cards + 1] = card
        cardsById[card._id] = card
    end
    
    local handCards = self:getBattleCards('H')
    for i = 1, #handCards do
        local card = handCards[i]
        cards[#cards + 1] = card
        cardsById[card._id] = card
    end
    local handCards = opponent:getBattleCards('H')
    for i = 1, #handCards do
        local card = handCards[i]
        cards[#cards + 1] = card
        cardsById[card._id] = card
    end

    for i = 1, #self._cards do
        local card = self._cards[i]
        if cardsById[card._id] == nil then
            cards[#cards + 1] = card
            cardsById[card._id] = card
        end
    end
    for i = 1, #opponent._cards do
        local card = self._opponent._cards[i]
        if cardsById[card._id] == nil then
            cards[#cards + 1] = card
            cardsById[card._id] = card
        end
    end
    
    cards[#cards + 1] = self._fortress
    cards[#cards + 1] = opponent._fortress

    return cards
end

function _M:getCardById(id)
    if id == nil then return nil end

    local opponent = self._opponent

    if id == self._fortress._id then return self._fortress 
    elseif id == opponent._fortress._id then return opponent._fortress
    end

    for i = 1, #self._cards do
        if self._cards[i]._id == id then
            return self._cards[i]
        end
    end
    for i = 1, #opponent._cards do
        if opponent._cards[i]._id == id then
            return opponent._cards[i]
        end
    end

    return nil
end

function _M:addCardToCards(card)
    if card._id == nil then
        self._cardIdBase = self._cardIdBase + 1
        card._id = self._cardIdBase
    end
    self._cards[#self._cards + 1] = card
    card._owner = self
    card._originOwner = card._originOwner or self
end

function _M:addCardByStatusPos(card, status, pos, cid, sid, mode, statusVal)
    self:addCardToCards(card)
    self:setCardStatus(card, status, cid, sid, mode, statusVal)
    if pos ~= nil then card._saved = {_pos = pos} end
end

function _M:removeCardFromCards(card)
    for i = 1, #self._cards do
        if card == self._cards[i] then
            table.remove(self._cards, i)
            break
        end
    end
end

function _M:removeCardToOppo(card)
    self:removeCardFromCards(card) 
    self._opponent:addCardToCards(card)
end

function _M:getGhostCard()
    if self._ghostCard == nil then
        local card = B.createCard(30001, 1)
        self:addCardToCards(card)
        self._ghostCard = card
    end
    return self._ghostCard
end

-----------------------------------
-- aggregate card helper functions
-----------------------------------

function _M:getBattleCards(field, level, except)
    local level = level or Data.CARD_MAX_LEVEL
    local cards = {}
    for j = 1, #field do
        local c = string.sub(field, j, j)
        if c == 'B' then
            for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
                local card = self._boardCards[i]
                if B.isAlive(card) and card ~= except and card._level <= level then cards[#cards + 1] = card end
            end
        elseif c == 'H' then
            for i = 1, Data.MAX_CARD_COUNT_IN_HAND do
                local card = self._handCards[i]
                if card ~= nil and card ~= except and card._level <= level then cards[#cards + 1] = card end
            end
        elseif c == 'P' then
            for i = 1, #self._pileCards do
                local card = self._pileCards[i]
                if card ~= nil and card ~= except and card._level <= level then cards[#cards + 1] = card end
            end
        elseif c == 'G' then
            for i = #self._graveCards, 1, -1 do
                local card = self._graveCards[i]
                if card ~= nil and card ~= except and card._level <= level then cards[#cards + 1] = card end
            end
        end
    end
    return cards
end

function _M:getBattleCardsByInfoId(field, infoId, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card._infoId == infoId then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsByOriginId(field, infoId, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card._info._originId == infoId then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsBySuperId(field, infoId, level, except)
    local type = Data.getType(infoId)
    if type == Data.CardType.nature then return self:getBattleCardsByNature(field, infoId % Data.INFO_ID_GROUP_SIZE, level, except)
    elseif type == Data.CardType.category then return self:getBattleCardsByCategory(field, infoId % Data.INFO_ID_GROUP_SIZE, level, except)
    elseif type == Data.CardType.keyword then return self:getBattleCardsByKeyword(field, infoId % Data.INFO_ID_GROUP_SIZE, level, except)
    end
    return {}
end

function _M:getBattleCardsByInfoIdGroup(field, infoIds, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        for j = 1, #infoIds do
            if card._infoId == infoIds[j] then
                cards[#cards + 1] = card 
                break
            end
        end
    end
    return cards
end

function _M:getBattleCardsByType(field, cardType, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card._type == cardType then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsByLevel(field, evoLevel, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card._info._level == evoLevel then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsByCategory(field, category, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card._info._category == category then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsByKeyword(field, keyword, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card._info._keyword == keyword then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsByNature(field, nature, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card._info._nature == nature then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsByStar(field, star, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card._info._star == star then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsByMaxStar(field, star, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card._info._star ~= nil and card._info._star <= star then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsByMinStar(field, star, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card._info._star ~= nil and card._info._star >= star then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsByMaxAtk(field, atk, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card._atk ~= nil and card._atk <= atk then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsByMinAtk(field, atk, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card._atk ~= nil and card._atk >= atk then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsByMaxHp(field, hp, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card._hp ~= nil and card._hp <= hp then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsByMinHp(field, def, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card._hp ~= nil and card._hp >= def then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsByHurt(field, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card._hp ~= nil and card._hp < card._maxHp then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsByAtkDef(field, atk, def, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card._atk == atk and card._hp == def then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsByMaxOriginAtk(field, atk, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if not card:isAtkHide() and card._maxAtk ~= nil and card._maxAtk <= atk then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsByMaxOriginDef(field, def, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if not card:isDefHide() and card._maxHp ~= nil and card._maxHp <= def then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsByCategoryAndNature(field, category, nature, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card._info._category == category and card._info._nature == nature then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsByBuff(field, isPositive, buffType, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card:hasBuff(isPositive, buffType) then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsBySkills(field, skills, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card:hasSkills(skills) then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsBySkillMode(field, skillMode, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card:hasSkillInMode(skillMode) then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getBattleCardsByNotEnoughCards(field, level, except)
    local allCards = self:getBattleCards(field, level, except)
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card:isMonster() and (card:getBuffValue(true, BattleData.PositiveType.powerMark) < card:getMaxSkillPower()) then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:getLeaveCards()
    local cards = {}
    for i = 1, #self._cards do
        local card = self._cards[i]
        if card._status == BattleData.CardStatus.leave then
            cards[#cards + 1] = card
        end
    end
    return cards
end

function _M:getLeaveCardsByInfoId(infoId)
    local allCards = self:getLeaveCards()
    local cards = {}
    for i = 1, #allCards do
        local card = allCards[i]
        if card._infoId == infoId then
            cards[#cards + 1] = card 
        end
    end
    return cards
end

function _M:isNeedDrop()
    return #self._handCards > Data.MAX_CARD_COUNT_IN_HAND_AFTER_DROP
end
-----------------------------------
-- board card helper functions
-----------------------------------

function _M:getIronyOrShieldBoardCards()
    local boardCards = {}
    for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
        local boardCard = self._boardCards[i] 
        --[[
        if B.isAlive(boardCard) and (boardCard:hasSkills({}) or boardCard:hasShield()) then
            table.insert(boardCards, boardCard)
        end
        ]]
    end
    return boardCards
end

function _M:getMaskCard()
    local cardWithMaskSkillAndMinId = nil
    for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
        local boardCard = self._boardCards[i]
        --[[
        if B.isAlive(boardCard) and boardCard:hasSkills({}) then
            if cardWithMaskSkillAndMinId == nil or cardWithMaskSkillAndMinId._id > boardCard._id then
                cardWithMaskSkillAndMinId = boardCard
            end
        end
        ]]
    end
    return cardWithMaskSkillAndMinId
end

function _M:getCanIncSkillLevelCards()
    local aliveCards = self:getBattleCards('B')
    local index = 1
    while true do
        if index  > #aliveCards then break end
    
        local card = aliveCards[index]
        local canIncLevel = false
        for j = 1, #card._skills do
            local skill = card._skills[j]
            if skill._level < CardHelper.getSkillMaxLevel(skill._id) then
                canIncLevel = true
                break
            end
        end
        
        if not canIncLevel then
            table.remove(aliveCards, index)
        else
            index = index + 1
        end
    end
    return aliveCards
end

function _M:getHasUnderTypeCastedModeCards(skillType, skill)
    local cards = {}
    local underCastedModes = {}

    if #underCastedModes > 0 then
        local boardcards = B.mergeTable({self:getBattleCards('B'), self._opponent:getBattleCards('B')})
        for i = 1, #boardcards do
            local card = boardcards[i]
            for j = 1, #underCastedModes do
                if card:getSkillByMode(underCastedModes[j], 1) ~= nil then
                    table.insert(cards, card)
                    break
                end
            end
        end
    end
    
    return cards, underCastedModes
end

function _M:getUnderSkillTypeCards(skillType)
    local cards = self:getAllCards()
    local underSkillTypeCards = {}
    for i = 1, #cards do
        local card = cards[i]

        for j = 1, #card._underSkills do
            local underSkill = card._underSkills[j]
            if math.floor(underSkill._sid / Data.INFO_ID_GROUP_SIZE) == skillType then
                table.insert(underSkillTypeCards, card)
                break
            end
        end
    end
    
    return underSkillTypeCards
end

function _M:getMagicMarkCards()
    local cards = self:getBattleCards('B')
    local magicMarkCards = {}
    local totalCount = 0
    for i = 1, #cards do
        local card = cards[i]
        local count = card:getBuffValue(true, BattleData.PositiveType.magicMark)
        if count > 0 then
            totalCount = count + totalCount
            magicMarkCards[#magicMarkCards + 1] = card
        end
    end
    return magicMarkCards, totalCount
end

-----------------------------------
-- board helper functions
-----------------------------------

function _M:isBoardPosLocked(pos)
    local values = self._fortress:getBuffValue(false, BattleData.NegativeType.boardLock)
    if type(values) ~= 'table' then return false end
    for i = 1, #values do
        if pos == values[i] then return true end
    end
    return false
end

function _M:isBoardPosEmpty(pos)
    return self._boardCards[pos] == nil and not self:isBoardPosLocked(pos)
end

function _M:getEmptyBoardPosCount()
    local count = 0
    for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
        if self:isBoardPosEmpty(i) then
            count = count + 1
        end
    end
    return count
end

function _M:getEmptyBoardPos(card)
    if card ~= nil and card:hasSkills({6018}) and #self:getBattleCardsByInfoId('B', card._infoId) > 0 then return nil end

    for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
        if self:isBoardPosEmpty(i) then
            return i
        end
    end
    return nil
end

function _M:getEmptyBackupPos(card)
    for i = 2, Data.MAX_CARD_COUNT_ON_BOARD do
        if self:isBoardPosEmpty(i) then
            return i
        end
    end
    return nil
end

function _M:canSpecialSummonAnyCard()
    if self._isSummonDisabled then return false end
    if #self:getBattleCardsBySkills('B', {6069}) + #self._opponent:getBattleCardsBySkills('B', {6069}) > 0 then return false end  

    return true
end

function _M:canSpecialSummon(card, ignoreByAnotherCard, ignoreByCondition)
    if not self:canSpecialSummonAnyCard() then return false end

    if self._isSummonDisabledBySelfStar[card._info._star] or self._isSummonDisabledByOppoStar[card._info._star] then return false end
    
    if card:hasSkillInMode(Data.SkillMode.use_disable) or card:hasSkillInMode(Data.SkillMode.use_special_disable) then return false end 
    if not ignoreByAnotherCard and card:hasSkillInMode(Data.SkillMode.use_specific_by_another_card) then return false end
    if not ignoreByCondition and card:hasSkillInMode(Data.SkillMode.use_specific_by_condition) then return false end

    local hasSkill, skill = card:hasSkillInMode(Data.SkillMode.use_special_disable_except) 
    if hasSkill then
        if skill._id == 3178 then if card._status == BattleData.CardStatus.grave then return false end
        end
    end

    return true
end

function _M:filterCanChangeToBoardCards(cards, ignoreByAnotherCard, ignoreCanSummon)
    if self:getEmptyBoardPos() == nil then return {} end
    
    local filteredCards = {}
    for i = 1, #cards do
        if cards[i]:isMonster() and self:getEmptyBoardPos(cards[i]) then
            filteredCards[#filteredCards + 1] = cards[i]
        end
    end
    
    if ignoreCanSummon then
        return filteredCards
    else
        return B.filterCanSpecialSummonCards(filteredCards, ignoreByAnotherCard)
    end
end

function _M:filterCanChangeToHandCards(cards)
    local filteredCards = {}

    if #self._opponent:getBattleCardsBySkills('B', {6075}) > 0 then return filteredCards end

    for i = 1, #cards do
        filteredCards[#filteredCards + 1] = cards[i]
    end
    
    return filteredCards
end

function _M:filterCanEquipCards(cards, card)
    local filteredCards = {}
    for i = 1, #cards do
        if self:canEquipCard(card, cards[i]) then
            filteredCards[#filteredCards + 1] = cards[i]
        end
    end
    return filteredCards
end

function _M:filterCanEvolveCards(cards, card)
    local filteredCards = {}
    for i = 1, #cards do
        if self:canEvolveCard(card, cards[i]) then
            filteredCards[#filteredCards + 1] = cards[i]
        end
    end
    return filteredCards
end

function _M:isChooseCardsSkill(skill)
    if skill == nil then return false end

    local id = skill._id
    local opponent = self._opponent
    local info = Data._skillInfo[skill._id]
    local val = info._val[1] or 0

    if id == 1015 then
        local cards = opponent:getBattleCards('B')
        return true, cards, math.min(2, #cards)

    elseif id == 1034 then
        local cards = self:filterCanChangeToHandCards(self:getBattleCards('P'))
        return true, cards, 1

    elseif id == 1041 then
        local cards = self:filterCanChangeToHandCards(self:getBattleCardsByNature('P', info._refCards[1]))
        return true, cards, 1

    elseif id == 1061 then
        local cards = self:filterCanChangeToBoardCards(self:getBattleCardsByLevel('P', 0))
        return true, cards, 1

    elseif id == 1072 then
        local cards = self:getBattleCards('B', Data.CARD_MAX_LEVEL, skill._owner)
        return true, cards, 1

    elseif id == 1088 or id == 1089 then
        local cards = opponent:getBattleCards('B')
        return true, cards, 1

    elseif id == 4001 then
        local cards = self:filterCanChangeToHandCards(self:getBattleCardsByType('P', Data.CardType.monster))
        return true, cards, 1

    elseif id == 4004 then
        local cards = self:filterCanChangeToHandCards(self:getBattleCardsByNature('G', info._refCards[1]))
        return true, cards, 1

    elseif id == 5001 or id == 5002 then
        local cards = self:getBattleCardsByHurt('B')
        return true, cards, 1

    elseif id == 7002 then
        local cards = self:filterCanChangeToHandCards(B.filterInMagicTrapTypeCards(self:getBattleCardsByType('P', Data.CardType.magic), Data.MagicTrapType.equip))
        return true, cards, 1

    elseif id == 7005 then
        local cards = B.filterFirstCards(self:filterCanChangeToHandCards(self:getBattleCards('P')), val)
        return true, cards, 1

    end

    
    return false
end

function _M:getSameNameBoardCards()   
    local originIds = {}
    local sameOriginIdCards = {}
    local cards = B.mergeTable({self:getBattleCards('B'), self._opponent:getBattleCards('B')})
    for i = 1, #cards do
        local card = cards[i]
        local originId = card:getOriginId()
        if originIds[originId] ~= nil then
            if originIds[originId] ~= 1 then
                sameOriginIdCards[#sameOriginIdCards + 1] = originIds[originId]
                originIds[originId] = 1
            end
            sameOriginIdCards[#sameOriginIdCards + 1] = card
        else
            originIds[originId] = card
        end
    end
    return sameOriginIdCards
end

-----------------------------------
-- pile helper functions
-----------------------------------

function _M:randomPile()
    self._pileCards = self:randomTable(self._pileCards, #self._pileCards)
    for i = 1, #self._pileCards do
        self._pileCards[i]._pos = i
    end
end

-----------------------------------
-- use card helper functions
-----------------------------------

function _M:canCastNoGemSkill(card, skill)
    local id = skill._id
    local info = Data._skillInfo[id]
    local val = info._val[1] or 0

    if id == 3009 or id == 3149 then
        return #self:getBattleCards('H', Data.CARD_MAX_LEVEL, card) > 0

    elseif id == 3016 then
        return #self:getBattleCardsByCategory('H', Data.CardCategory.dragon, Data.CARD_MAX_LEVEL, card) > 0

    elseif id == 3177 then
        return #B.filterNoShieldCards(self._opponent:getBattleCards('B'), BattleData.PositiveType.shieldMonster) >= 2

    elseif id == 3188 then
        return #B.filterCanActionCards(B.filterNormalSummonCards(self:getBattleCardsByMinStar('B', 5), true)) > 0

    elseif id == 3250 then
        return #self:filterCanChangeToHandCards(B.filterInKeywordCards(self:getBattleCardsByType('P', Data.CardType.magic), info._refCards[1])) > 0

    end

    return true
end

function _M:canUseHandCard()
    if #self._handCards == 0 then return false end
    
    for i = 1, #self._handCards do
        local handCard = self._handCards[i]
        if handCard:isMonster() then
            if self:canUseMonster(handCard, false) then return true end

        elseif handCard._type == Data.CardType.magic then
            if self:canUseMagic(handCard, false) then return true end

        elseif handCard._type == Data.CardType.trap then
            if self:canUseTrap(handCard, false) then return true end

        end
    end
    
    return false
end

-----------------------------------
-- battle helper functions
-----------------------------------

function _M:getMaxRound(level)
    if (not self._isAttacker) or level == nil then
        return BattleData.MaxRound[4]
    elseif level < 30 then
        return BattleData.MaxRound[1]
    elseif level >= 30 and level < 45 then
        return BattleData.MaxRound[2]
    elseif level >= 45 then
        return BattleData.MaxRound[3]
    end
    
    return BattleData.MaxRound[4]
end

-----------------------------------
-- random helper functions
-----------------------------------

function _M:getRandom()
    if self._isClient and P._guideID < 100 then return 0 end

    if self._battleType == Data.BattleType.unittest and _M._randomSeed == nil then
        _M._randomSeed = 0
    end
    _M._randomSeed = (_M._randomSeed * 1103515245 + 12345) % 65536
    return _M._randomSeed / 65536
end

function _M:randomOne(objs)
    if objs == nil then 
        return nil, nil 
    end
    
    local c = #objs 
    if c == 0 then return nil
    elseif c == 1 then return objs[1], 1
    else
        local index = math.min(math.floor(self:getRandom() * c + 1), c)
        return objs[index], index
    end 
end

function _M:randomOneTryExcept(objs, except)
    local newObjs = {}
    for i = 1, #objs do
        if objs[i] ~= except then
            table.insert(newObjs, objs[i])
        end
    end
    return self:randomOne(newObjs) or except
end

function _M:randomTable(objs, count)
    if objs == nil then
        return {}
    end
    
    local ret = {}
    local c = #objs 
    if c < count then 
        for i = 1, c do 
            table.insert(ret, objs[i]) 
        end   
    else
        local selected = {}
        for i = 1, count do
            local index = math.min(math.floor(self:getRandom() * c + 1), c)
            while true do
                if selected[index] ~= true then
                    selected[index] = true
                    table.insert(ret, objs[index])
                    break
                else
                    index = (index % c) + 1
                end
            end
        end 
    end
    return ret
end

-----------------------------------
-- score helper functions
-----------------------------------

function _M:getDamageFactor(key)
    local destroyCardCount = self._destroyCardScore[key] or 0
    local factor = {1.05, 1.1, 1.2, 1.35, 1.55, 1.8, 2.1, 2.45, 2.85, 3.3}
    local f = 1
    for i = 1, destroyCardCount, 1 do
        f = f * factor[math.min(#factor, destroyCardCount)]
    end
    return f
end

function _M:getTotalDamageScore()
    return self._damageScore[_M.KEY_TOTAL]
end

function _M:addDamageScore(damage)
    if self._round < 1 then return end

    local key = 'R'..math.max(self._round, self._opponent._round)
    if self._damageScore[key] == nil then
        self._damageScore[key] = 0
    end

    self._damageScore[key] = self._damageScore[key] + damage * self:getDamageFactor(key)
    self._damageScore[_M.KEY_TOTAL] = self._damageScore[_M.KEY_TOTAL] + damage

    --self:battleLog('         [SCORE -- DAMAGE] %s ROUND %d: %d, TOTAL: %d', Str(self._isAttacker and STR.SELF or STR.OPPONENT), self._round, self._damageScore[key], self._damageScore[_M.KEY_TOTAL])
    if not self._isReviewing then
        self:sendEvent(BattleData.Status.update_score_damage)
    end
end

function _M:addDestroyCardScore(card)
    if self._round < 1 then return end

    local key = 'R'..math.max(self._round, self._opponent._round)

    if self._destroyCardScore[key] == nil then
        self._destroyCardScore[key] = 0
    end
    self._destroyCardScore[key] = self._destroyCardScore[key] + 1
    self._destroyCardScore[_M.KEY_TOTAL] = self._destroyCardScore[_M.KEY_TOTAL] + 1

    if card:isMonster() then
        if self._destroyHeroScore[key] == nil then
            self._destroyHeroScore[key] = 0
        end
        self._destroyHeroScore[key] = self._destroyHeroScore[key] + 1
        self._destroyHeroScore[_M.KEY_TOTAL] = self._destroyHeroScore[_M.KEY_TOTAL] + 1
    end

    if card:isMonster() then
        if self._destroyMonsterCount[card._infoId] == nil then
            self._destroyMonsterCount[card._infoId] = 0
        end
        self._destroyMonsterCount[card._infoId] = self._destroyMonsterCount[card._infoId] + 1
        self._destroyMonsterCount[0] = self._destroyMonsterCount[0] + 1
    end

    --self:battleLog('         [SCORE -- DESOTRY CARD] %s ROUND %d: %d, TOTAL: %d', Str(self._isAttacker and STR.SELF or STR.OPPONENT), self._round, self._destroyCardScore[key], self._destroyCardScore[_M.KEY_TOTAL])
    if not self._isReviewing then
        self:sendEvent(BattleData.Status.update_score_destroy_card)
    end
end


-----------------------------------
-- server helper functions
-----------------------------------

function _M:getTotalRound()
    return self._round
end

function _M:getFortressDamage()
    return {self._fortress._maxHp - self._fortress._hp, self._fortress._hp}
end

function _M:getDestroyMonsterCount(infoId)
    infoId = infoId or 0
    return self._destroyMonsterCount[infoId] or 0
end

function _M:getSummonedMonsterCount()
    return self._totalSummonedMonsterCount
end

function _M:getCastedMagicCount()
    return self._totalCastedMagicCount
end

function _M:getCastedTrapCount()
    return self._totalCastedTrapCount
end

-----------------------------------
-- unittest helper functions
-----------------------------------

function _M:loadUnitTest()
    if self._unitTestData == nil then return end

    local opponent = self._opponent

    local attakerFields = self._unitTestData.AttackerFields
    local defenderFields = self._unitTestData.DefenderFields
    
    -- 1. cards except show area
    self:loadFields(attakerFields, 'PHBGR')
    opponent:loadFields(defenderFields, 'PHBGR')

    -- 2. trap and magic
    self:loadFields(attakerFields, 'S')
    opponent:loadFields(defenderFields, 'S')

    -- 3. used cards
    self:loadUsedCards(self._unitTestData.AttackerUsedCards)
    opponent:loadUsedCards(self._unitTestData.DefenderUsedCards)
end

function _M:loadFields(data, fields)
    for i = 1, #fields do
        local f = string.sub(fields, i, i)
        if f == 'B' then
            for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
                local infoId = data.B[i]
                self:loadCard(infoId, BattleData.CardStatus.board, i)
            end        
        elseif f == 'P' then
            for i = 1, #data.P do
                local infoId = data.P[i]
                self:loadCard(infoId, BattleData.CardStatus.pile, i)
            end 
        elseif f == 'H' then
            for i = 1, #data.H do
                local infoId = data.H[i]
                self:loadCard(infoId, BattleData.CardStatus.hand, i)
            end
        elseif f == 'G' then
            for i = 1, #data.G do
                local infoId = data.G[i]
                self:loadCard(infoId, BattleData.CardStatus.grave, i)
            end
        end
    end
end

function _M:loadCard(infoId, status, pos)
    if infoId == 0 then return end

    local card = B.createCard(math.abs(infoId), 1)
    self:addCardToCards(card)
    card._isTroopCard = true
    card._saved._pos = pos
    
    self:changeCardStatus(card, BattleData.CardStatus.leave, status, infoId < 0 and BattleData.CardStatusVal.e2x_fast_def or BattleData.CardStatusVal.e2x_fast)
end

function _M:loadUsedCards(usedCards)
    if usedCards == nil then return end
    self._ops = B.parseOperations(usedCards, true)
end

-----------------------------------
-- other helper functions
-----------------------------------

function _M:sendEvent(type, param, arrayParam)
    local eventCustom = cc.EventCustom:new(_M.EVENT)
    eventCustom._sender = self
    eventCustom._type = type
    eventCustom._param = param
    eventCustom._arrayParam = arrayParam
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:battleLog(...)
    local str = string.format(...)
    lc.log(str)
    if self._isClient then
        ClientData.addBattleDebugLog(str..'\n')
    end
end

function _M:cardName(card)
    return card._type == Data.CardType.fortress and Str(STR.FORTRESS) or Str(card._info._nameSid)
end


