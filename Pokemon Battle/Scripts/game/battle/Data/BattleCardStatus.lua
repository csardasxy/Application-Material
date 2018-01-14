local _M = PlayerBattle

function _M:changeCardStatus(card, sourceStatus, destStatus, statusVal, triggerCard)
    if destStatus == BattleData.CardStatus.grave and 
        (not card._isTroopCard or 
         (#self:getBattleCardsBySkills('B', {6046}) + #self._opponent:getBattleCardsBySkills('B', {6046}) > 0)) then
        destStatus = BattleData.CardStatus.leave
    elseif sourceStatus == BattleData.CardStatus.board and (destStatus == BattleData.CardStatus.hand or destStatus == BattleData.CardStatus.pile) then
        if not card._isTroopCard then
            destStatus = BattleData.CardStatus.leave
        end
    end
    
    local statusChangeNode = {}
    statusChangeNode._card = card
    statusChangeNode._sourceStatus = sourceStatus
    statusChangeNode._destStatus = destStatus
    statusChangeNode._statusVal = statusVal
    statusChangeNode._triggerCard = triggerCard
    
    local actionPlayer = self:getActionPlayer()
    table.insert(actionPlayer._cardStatusToChange, statusChangeNode)

    if card:isMonster() and sourceStatus == BattleData.CardStatus.board and destStatus ~= BattleData.CardStatus.board then
        local magicCard = card._binds[1]
        if magicCard ~= nil then
            card._prevBindCard = magicCard
            card:removeBind(magicCard)
            magicCard:removeBind(card)
        else
            card._prevBindCard = nil
        end
        
        if magicCard ~= nil and not magicCard:hasChangeStatusUnderSkill({BattleData.CardStatus.grave, BattleData.CardStatus.leave}) then
            self:changeCardStatus(magicCard, magicCard._status, BattleData.CardStatus.grave)
        end

        if statusVal ~= BattleData.CardStatusVal.b2l_evolve then
            local count = card:getBuffValue(true, BattleData.PositiveType.powerMark)
            local cards = card._owner:getLeaveCardsByInfoId(39999)
            for i = 1, count do
                local powerCard = cards[i]
                if powerCard ~= nil then
                    self:changeCardStatus(powerCard, powerCard._status, BattleData.CardStatus.grave)
                end
            end
        end
        
    elseif (card._type == Data.CardType.magic or card._type == Data.CardType.trap) and sourceStatus == BattleData.CardStatus.show and destStatus ~= BattleData.CardStatus.show then
        local boardCard = card._binds[1]
        if B.isAlive(boardCard) then
            card._prevBindCard = boardCard
            card:removeBind(boardCard)
            boardCard:removeBind(card)
        else
            card._prevBindCard = nil
        end
    end
end

function _M:changeCardPos(card, posChange)
    local posChangeNode = {}
    posChangeNode._card = card
    posChangeNode._type = posChange
    
    local actionPlayer = self:getActionPlayer()
    table.insert(actionPlayer._cardPosToChange, posChangeNode)
end

function _M:changeEvent(event, type)
    local eventChangeNode = {}
    eventChangeNode._event = event
    eventChangeNode._type = type
    
    local actionPlayer = self:getActionPlayer()
    table.insert(actionPlayer._eventToChange, eventChangeNode)
end

function _M:removeCardFromPile(card)
    for i = 1, #self._pileCards do
        if self._pileCards[i]._id == card._id then
            table.remove(self._pileCards, i)
            break
        end 
    end
    
    -- reorder pile cards
    for i = 1, #self._pileCards do
        local pileCard = self._pileCards[i]
        pileCard._pos = i
    end
    
    card:saveAndReset()
end

function _M:removeCardFromHand(card)
    table.remove(self._handCards, card._pos)
    
    -- reorder hand cards
    for i = 1, #self._handCards do
        local handCard = self._handCards[i]
        handCard._pos = i
    end
   
    card:saveAndReset()
end

function _M:removeCardFromBoard(card)
    local isBorrowOrReturn = card._statusVal == BattleData.CardStatusVal.b2b_oppo_once or
                                card._statusVal == BattleData.CardStatusVal.b2h_oppo_once
    local isToOppoBoard = card._statusVal == BattleData.CardStatusVal.b2b_oppo_once or 
                            card._statusVal == BattleData.CardStatusVal.b2b_oppo_forever or 
                            card._statusVal == BattleData.CardStatusVal.b2b_oppo_rob_horse 
    local isToOppo = isToOppoBoard or 
                        card._statusVal == BattleData.CardStatusVal.b2h_oppo or 
                        card._statusVal == BattleData.CardStatusVal.b2p_oppo or
                        card._statusVal == BattleData.CardStatusVal.b2h_oppo_once

    if isToOppo then
        card._owner:removeCardToOppo(card) 
    end

    if isBorrowOrReturn then
        if not card._isBorrowed then
            if self._macroStatus ~= BattleData.Status.use and self._opponent._macroStatus ~= BattleData.Status.use then
                card._saved._pos = card._pos
            end
            card._isBorrowed = true
        else
            card._isBorrowed = false
        end
    end

    if card._statusVal == BattleData.CardStatusVal.b2g_sacrifice and card:hasSkills({3206}) then
        card._dinosaurMarkValue = card:getBuffValue(true, BattleData.PositiveType.dinosaurMark)
    end
    
    if card:isMonster() then
        self._boardCards[card._pos] = nil
    end
    
    if not isToOppoBoard then
        -- reset card
        card:saveAndReset()
    end
end

function _M:removeCardFromGrave(card)
    local isToOppo = card._statusVal == BattleData.CardStatusVal.g2h_oppo

    if isToOppo then
        card._owner:removeCardToOppo(card) 
    end

    table.remove(self._graveCards, card._pos)
    
    for i = 1, #self._graveCards do
        local graveCard = self._graveCards[i]
        graveCard._pos = i
    end

    card:saveAndReset()
end

function _M:removeCardFromLeave(card)
    card:saveAndReset()
end

function _M:addCardToPile(card)
    local pos = (card._saved._pos and card._saved._pos > 0 and card._saved._pos <= #self._pileCards + 1) and card._saved._pos or (math.floor(self:getRandom() * (#self._pileCards + 1)) + 1)
    table.insert(self._pileCards, pos, card)

     for i = 1, #self._pileCards do
        self._pileCards[i]._pos = i
    end
    
    card._status = BattleData.CardStatus.pile
    card._saved = {}
end

function _M:addCardToHand(card)
    if #self._handCards == Data.MAX_CARD_COUNT_IN_HAND then
        card._destStatus = BattleData.CardStatus.grave
        self:addCardToGrave(card)
        return
    end

    table.insert(self._handCards, card)
    card._pos = #self._handCards
    
    card._status = BattleData.CardStatus.hand
    card._saved = {}
end

function _M:addCardToBoard(card)
    if card:isMonster() then
        local pos = (card._saved._pos and self:isBoardPosEmpty(card._saved._pos)) and card._saved._pos or self:getEmptyBoardPos(card)
        card._saved._pos = nil
        if pos ~= nil then
            self._boardCards[pos] = card
            card._pos = pos
            if card._saved._bind ~= nil then
                card:addBind(card._saved._bind)
                card._saved._bind:addBind(card)
                card._saved._bind = nil
            end

            if card:isMonster() then
                card._monsterTarget = card._saved._monsterTarget
            end

            if card._saved._addSkills ~= nil then
                for i = 1, #card._saved._addSkills do
                    card:addSkill(card._saved._addSkills[i], 1, BattleData.SkillProvider.given)
                end
                card._saved._addSkills = nil
            end

            if card._saved._powerMark ~= nil and card._saved._powerMark > 0 then
                card._positiveStatus[BattleData.PositiveType.powerMark] = true
                card._positiveValues[BattleData.PositiveType.powerMark] = card._saved._powerMark
                for i = 1, card._saved._powerMark do
                    table.insert(card._underSkills, {_cid = 0, _sid = 0, _mode = 0, _positiveType = BattleData.PositiveType.powerMark, _value = 1, _aggregateType = Data.AggregateType.sum, _removable = true})
                end
            end

            if card:isV12() then
                card._round3232 = card._owner._round + Data._skillInfo[3232]._val[1] - 1
            end

            self._isSummoned = true
            self._summonedMonsterCounts[card._infoId] = (self._summonedMonsterCounts[card._infoId] or 0) + 1
            card._summonStatusVal = card._statusVal
            card._summonRound = self._round
            self._totalSummonedMonsterCount[card._info._level + 1] = self._totalSummonedMonsterCount[card._info._level + 1] + 1
            if card._statusVal ~= BattleData.CardStatusVal.h2b_normal then
                
            else
                
            end

        else
            card._destStatus = BattleData.CardStatus.grave
            self:addCardToGrave(card)
            return
        end
        
    end
    
    card._status = BattleData.CardStatus.board
    if not card._isBorrowed then
        card._saved = {}
    end
end

function _M:addCardToGrave(card)
    if card._sourceStatus == BattleData.CardStatus.board then
        card._owner._ball = math.max(0, card._owner._ball - 1)
    end

    table.insert(self._graveCards, card)
    
    if card._type == Data.CardType.magic then
        card._magicTarget = card._saved._magicTarget
    elseif card._type == Data.CardType.trap then
        card._trapTarget = card._saved._trapTarget
    end
    
    card._status = BattleData.CardStatus.grave

    card._pos = #self._graveCards
    card._saved = {}

    card:setDieStat()
end

function _M:addCardToLeave(card)
    card._status = BattleData.CardStatus.leave
    
    if card._type == Data.CardType.magic then
        card._magicTarget = card._saved._magicTarget
    elseif card._type == Data.CardType.trap then
        card._trapTarget = card._saved._trapTarget
    end
    
    if card._statusVal == BattleData.CardStatusVal.h2l_temp then
        self._tempLeaveCards[#self._tempLeaveCards + 1] = card
    end

    card:setDieStat()
end


