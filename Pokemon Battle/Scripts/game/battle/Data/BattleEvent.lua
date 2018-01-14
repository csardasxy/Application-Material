local _M = class("BattleEvent")
BattleEvent = _M

_M.EventType = 
{
    battle_start    = 1,
    battle_end      = 2,
    all_cards_died  = 10,
    fortress_died   = 11,
    
    round_begin     = 3,
    round_end       = 4,
    
    try_use_card    = 5,
    do_use_card     = 6,
    
    after_status_change = 7,
    before_status_change = 8,
}

function _M:ctor(player, events)
    self._player = player

    self._events = {}
    if next(events) then
        for i = 1, #events do
            local id = events[i]
            local eventInfo = Data._eventInfo[id]
            if eventInfo then
                table.insert(self._events, {_id = id, _info = eventInfo})
            end
        end
    end
    
    self:reset()
end

----------------------------------------------------
-- function to call
----------------------------------------------------

function _M:reset()
    for i = 1, #self._events do
        local event = self._events[i]
        event._owner = self._player
        event._isCasted = false
    end
end

function _M:getSatisfiedEvents(eventType)
    local events = {}
    
    for i = 1, #self._events do
        local event = self._events[i]
        if event._info._status == eventType and self:isEventSatisfied(event) then
            table.insert(events, event)
        end
    end

    return events
end

function _M:isEventSatisfied(event)
    local isSatisfied = true

    for i = 1, #event._info._condition do
        local condition, vals = event._info._condition[i], event._info._conditionValue[i]
        if (event._info._isOnce == 1 and event._isCasted) or (not self:isSatisfied(condition, vals)) then
            isSatisfied = false
            break
        end
    end

    return isSatisfied
end

function _M:getEventById(id)
    for i = 1, #self._events do
        local event = self._events[i]
        if event._id == id then
            return event
        end
    end
    
    return nil
end

function _M:isSatisfied(id, vals)
    local isSatisfied = false

    local vals = vals or {}
    local val = vals[1]
    local player, opponent = self._player, self._player._opponent
    local actionCard = player._actionCard or opponent._actionCard

    if id == 1 then
        isSatisfied = true

    elseif id == 2 then
        if actionCard._infoId == val and actionCard._sourceStatus == vals[2] and actionCard._destStatus == vals[3] then
            return true
        end

    elseif id == 11 or id == 13 then
        if #player:getBattleCardsByInfoId('B', val) > 0 then
            isSatisfied = true
        end

    elseif id == 12 or id == 14 then
        if #player:getBattleCardsByInfoId('B', val) == 0 then
            isSatisfied = true
        end
    
    elseif id == 15 then
        if #player:getBattleCardsByInfoId('B', val) == 0 and #opponent:getBattleCardsByInfoId('B', val) == 0 then
            isSatisfied = true
        end
    
    elseif id == 16 then
        if #player:getBoardCardByEventId(vals[10]) ~= nil then
            isSatisfied = true
        end
    
    elseif id == 17 or id == 18 then
        if #player:getBattleCardsByInfoId('B', val) > 0 or #opponent:getBattleCardsByInfoId('B', val) > 0 then
            isSatisfied = true
        end

    elseif id == 19 then
        
    elseif id == 20 then
        
    elseif id == 21 or id == 23 then
        if #player:getBattleCardsByInfoId('H', val) > 0 then
            isSatisfied = true
        end 
        
    elseif id == 22 or id == 24 then
        if #player:getBattleCardsByInfoId('H', val) == 0 then
            isSatisfied = true
        end
    
    elseif id == 31 then
        if actionCard ~= nil and actionCard._infoId == val then
            isSatisfied = true
        end
    
    elseif id == 32 then
        if actionCard ~= nil and actionCard._infoId == val then
            isSatisfied = true
        end
    
    elseif id == 33 then
        if actionCard ~= nil and actionCard:isMonster() and actionCard._owner == player then
            isSatisfied = true
        end
    
    elseif id == 34 then
        if player._cardToTryUse ~= nil then
            local usedCard = player._cardToTryUse._card
            if (usedCard ~= nil and usedCard._infoId == val) or (usedCard == nil and val == 0) then
                isSatisfied = true
            end
        end
        
    elseif id == 41 then
        if player._round == val then
            isSatisfied = true
        end
    
    elseif id == 42 then
        if player._round >= val then
            isSatisfied = true
        end

    elseif id == 43 then
        if player._round <= val then
            isSatisfied = true
        end
        
    elseif id == 44 then
        if player:getActionPlayer() == player then
            isSatisfied = true
        end
    
    elseif id == 45 then
        
    elseif id == 51 then
        if player._isAttacker and player:getResult() == Data.BattleResult.win then
            isSatisfied = true
        elseif player._opponent._isAttacker and player._opponent:getResult() == Data.BattleResult.win then
            isSatisfied = true
        end
        
    elseif id == 52 then
        if player._isAttacker and (player:getResult() == Data.BattleResult.lose) then
            isSatisfied = true
        elseif player._opponent._isAttacker and (player._opponent:getResult() == Data.BattleResult.lose) then
            isSatisfied = true
        end
    
    elseif id == 53 then
        local event = self:getEventById(val)
        if event ~= nil and (not event._isCasted) then
            isSatisfied = true
        end

    elseif id == 61 then
        if val == player._gem then
            isSatisfied = true
        end

    elseif id == 71 then
        if (not player._isUsedCard) and (not player._opponent._isUsedCard) then
            isSatisfied = true
        end

    
    end
    
    return isSatisfied
end

function _M:castEffect(id, vals, event)
    local isCasted = false
    
    local player, opponent = self._player, self._player._opponent
    local actionCard = player._actionCard or opponent._actionCard

    local vals = vals or {}
    if id == 1 then
        isCasted = true
            
    elseif id == 2 then
        local card = B.createCardByEvent(vals)
        if card ~= nil then
            player:addCardToCards(card)
            if card:isMonster() then
                if player:getEmptyBoardPos(card) ~= nil then
                    player:changeCardStatus(card, BattleData.CardStatus.leave, BattleData.CardStatus.board)
                elseif #player._handCards < Data.MAX_CARD_COUNT_IN_HAND then
                    player:changeCardStatus(card, BattleData.CardStatus.leave, BattleData.CardStatus.hand, BattleData.CardStatusVal.e2h_self_new)
                else
                    player:changeCardStatus(card, BattleData.CardStatus.leave, BattleData.CardStatus.pile)
                end
            else
                player:changeCardStatus(card, BattleData.CardStatus.leave, BattleData.CardStatus.board)
            end
            isCasted = true
        end

    elseif id == 3 then
        local card = B.createCardByEvent(vals)
        if card ~= nil then
            player:addCardToCards(card)
            if #player._handCards < Data.MAX_CARD_COUNT_IN_HAND then
                player:changeCardStatus(card, BattleData.CardStatus.leave, BattleData.CardStatus.hand, BattleData.CardStatusVal.e2h_self_new)
            else
                player:changeCardStatus(card, BattleData.CardStatus.leave, BattleData.CardStatus.pile)
            end
            isCasted = true
        end
        
    elseif id == 4 then
        local card = player:getBattleCardsByInfoId('H', vals.c.id)[1]
        if card ~= nil then
            player:changeCardStatus(card, BattleData.CardStatus.hand, BattleData.CardStatus.board)
            isCasted = true
        end
        
    elseif id == 5 then
        local card = player:getBattleCardsByInfoId('B', vals.c.id)[1]
        if card ~= nil then
            player:changeCardStatus(card, BattleData.CardStatus.board, BattleData.CardStatus.grave)
            isCasted = true
        end
        
    elseif id == 6 or id == 17 then
        
    elseif id == 7 then
        isCasted = true
            
    elseif id == 8 then
        
    
    elseif id == 9 then
        isCasted = true
    
    elseif id == 10 then
        isCasted = true
        
    elseif id == 11 then
        isCasted = true
   
    elseif id == 12 then
        local card = B.createCardByEvent(vals)
        if card ~= nil then
            player:addCardToCards(card)
            player:changeCardStatus(card, BattleData.CardStatus.leave, BattleData.CardStatus.pile)
            isCasted = true
        end
    
    elseif id == 13 then
        isCasted = true
        
    elseif id == 14 then
        isCasted = true
    
    elseif id == 15 then
        isCasted = true
    
    elseif id == 16 then
        isCasted = true
        
    elseif id == 18 then
        local card = player._fortress
        card._hpInc = card._hpInc + vals.hp
        card._maxHpInc = card._hpInc > 0 and card._hpInc or 0
        card._haloedMaxHpInc = card._maxHpInc
        card._hp = math.max(card._maxHp + card._hpInc, 0)
        
    elseif id == 19 then
        isCasted = true
    
    elseif id == 20 then
        isCasted = true
    
    elseif id == 21 then
        isCasted = true

    elseif id == 22 then
        isCasted = true

    elseif id == 51 or id == 52 or id == 53 or id == 54 or id == 55 then
        isCasted = true

    elseif id == 61 then
        isCasted = true

    elseif id == 81 then
        self._player:loadUnitTest()
        isCasted = true

    end
    
    if isCasted then
        event._isCasted = true
    end
end

---------------------------------------------------
-- method
---------------------------------------------------

function _M:getEventById(id)
    for i = 1, #self._events do
        local event = self._events[i]
        if event._id == id then
            return event
        end
    end
    
    return nil
end

return _M