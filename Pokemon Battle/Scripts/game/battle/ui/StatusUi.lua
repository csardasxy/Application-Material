local _M = PlayerUi

-----------------------------------
-- account function
-----------------------------------

function _M:removeCardFromLeave(card)
    local cardSprite = self:createCardSprite(card)
    cardSprite:setPosition(-100, V.SCR_CH + (self._isController and -200 or 200))
    self._battleUi:addChild(cardSprite)
    return cardSprite
end

function _M:removeCardFromPile(card)
    local cardSprite, pos = self:getPileCardSprite(card)
    table.remove(self._pPileCards, pos)
    --[[
    local cardSprite = self:createCardSprite(card)
    cardSprite:setPosition(V.SCR_W + 100, V.SCR_CH + (self._isController and -200 or 200))
    self._battleUi:addChild(cardSprite)
    ]]
    
    self:sendEvent(_M.EventType.update_card_pile_count)
    return cardSprite
end

function _M:removeCardFromHand(card)
    local cardSprite, pos = self:getHandCardSprite(card)
    table.remove(self._pHandCards, pos)
end

function _M:removeCardFromBoard(card)
    if card:isMonster() then
        local _, pos = self:getBoardCardSprite(card)
        self._pBoardCards[pos] = nil

        if card:isV12() then
            if #card._owner:getBattleCardsByInfoId('B', card._infoId) + #card._owner._opponent:getBattleCardsByInfoId('B', card._infoId) == 0 then
                lc.Audio.playAudio(AUDIO.M_BATTLE)
            end
        end
    end
end

function _M:removeCardFromGrave(card)
    local cardSprite, pos = self:getGraveCardSprite(card)
    table.remove(self._pGraveCards, pos)
    
    cardSprite:setVisible(false)
    self:updateGraveArea()
end

function _M:addCardToLeave(card, tempDelay, delay)
    local cardSprite = self:getCardSprite(card)
    
    --self:removeCardFromSprites(cardSprite)
    
    if card._sourceStatus == BattleData.CardStatus.board then
        delay = cardSprite:playBoardToLeave(delay)
    
    elseif card._sourceStatus == BattleData.CardStatus.grave then
        --delay = cardSprite:playGraveRetriev(delay)
        delay = cardSprite:playRetrievToLeave(delay)

    else
        delay = cardSprite:playToLeave(delay)

    end
    
    return delay, delay
end

function _M:addCardToPile(card, tempDelay, delay)
    local cardSprite = self:getCardSprite(card)

    self._pPileCards = {}
    for i = 1, #self._player._pileCards do
        local pileCard = self._player._pileCards[i]
        self._pPileCards[pileCard._pos] = self:getCardSprite(pileCard)
    end
    
    --self:removeCardFromSprites(cardSprite)
    self:sendEvent(_M.EventType.update_card_pile_count)

    -- fast
    if card._statusVal == BattleData.CardStatusVal.e2x_fast or card._statusVal == BattleData.CardStatusVal.g2p_fast then
        delay = cardSprite:fastToPile(delay)

    elseif card._sourceStatus == BattleData.CardStatus.board then
        delay = cardSprite:playBoardRetriev(delay)
        delay = cardSprite:playRetrievToPile(delay)

    elseif card._sourceStatus == BattleData.CardStatus.grave then
        delay = cardSprite:playGraveRetriev(delay)
        delay = cardSprite:playRetrievToPile(delay)

    elseif card._sourceStatus == BattleData.CardStatus.leave then
        cardSprite:setPosition(cc.p(V.SCR_CW, V.SCR_CH))
        delay = cardSprite:playToPile(delay)

    else
        delay = cardSprite:playToPile(delay)

    end
    
    return delay, delay
end

function _M:addCardToHand(card, tempDelay, delay)
    local cardSprite = self:getCardSprite(card) or self._opponentUi:getCardSprite(card)
    self._pHandCards[card._pos] = cardSprite
    self:calHandCardPosAndRot(cardSprite)
    
    -- action
    if card._statusVal == BattleData.CardStatusVal.e2x_fast then
        delay = cardSprite:fastToHand(delay, false)
    elseif card._sourceStatus == BattleData.CardStatus.board then
        delay = cardSprite:playBoardRetriev(delay)
        delay = cardSprite:playRetrievToHand(delay)
        tempDelay = delay

    elseif card._sourceStatus == BattleData.CardStatus.grave then
        delay = cardSprite:playGraveRetriev(delay)
        delay = cardSprite:playRetrievToHand(delay)
        tempDelay = delay

    
    elseif card._sourceStatus == BattleData.CardStatus.leave then
        cardSprite:setPosition(cc.p(V.SCR_CW, V.SCR_CH))
        cardSprite:setScale(1 / CardSprite.Scale.normal)
        tempDelay, delay = cardSprite:playRetrievToHand(delay)

    else
        if card._statusVal == BattleData.CardStatusVal.p2h_show then
            tempDelay, delay = cardSprite:playToHand(delay, true)
        else
            tempDelay, delay = cardSprite:playToHand(delay, false)
        end

    end
    
    return tempDelay, delay
end

function _M:addCardToBoard(card, tempDelay, delay)
    -- only monster or rare
    local cardSprite = self:getCardSprite(card)
    
    if card:isMonster() then
        self._pBoardCards[card._pos] = cardSprite
        self:calBoardCardPos(cardSprite)

        if card:isV12() then
            lc.Audio.playAudio(AUDIO.M_BATTLE)
        end
    end
    
    -- actions
    if card._statusVal == BattleData.CardStatusVal.e2x_fast or card._statusVal == BattleData.CardStatusVal.e2x_fast_def then
        delay = cardSprite:fastToBoard(delay)
    elseif card._sourceStatus == BattleData.CardStatus.leave then
         delay = cardSprite:playEmptyToBoard(delay)

    elseif card._sourceStatus == BattleData.CardStatus.grave then
        delay = cardSprite:playGraveRetriev(delay)
        delay = cardSprite:playToBoard(delay)
        
    elseif card._sourceStatus == BattleData.CardStatus.board then
        delay = cardSprite:playBoardToBoard(delay)


    else
        delay = cardSprite:playToBoard(delay)
    end

    return delay, delay
end

function _M:addCardToGrave(card, tempDelay, delay)
    local cardSprite = self:getCardSprite(card)
    table.insert(self._pGraveCards, cardSprite)

    -- action
    if card._statusVal == BattleData.CardStatusVal.e2x_fast or card._statusVal == BattleData.CardStatusVal.p2g_fast then
        delay = cardSprite:fastToGrave(delay)

    elseif card._sourceStatus == BattleData.CardStatus.board then
        delay = cardSprite:playBoardToGrave(delay)

    elseif card._sourceStatus == BattleData.CardStatus.hand or card._sourceStatus == BattleData.CardStatus.pile then
        if card._statusVal == BattleData.CardStatusVal.h2g_magic then
            self:replaceHandCards(delay)
            self:addGraveCard(cardSprite)
            cardSprite:updateZOrder()

        else
            delay = cardSprite:playToGrave(delay)
        end

    else    
        self:addGraveCard(cardSprite)
        cardSprite:updateZOrder()

    end
        
    return delay, delay
end

function _M:accountHalo(delay, type, card)
    local playerUi = card._owner._isAttacker == self._isAttacker and self or self._opponentUi

    if card:isMonster() and 
        (card._sourceStatus == BattleData.CardStatus.leave or card._sourceStatus == BattleData.CardStatus.pile or card._sourceStatus == BattleData.CardStatus.hand or card._sourceStatus == BattleData.CardStatus.grave) and
        card._destStatus == BattleData.CardStatus.board then
        local cardSprite = playerUi:getCardSprite(card)
        for i = 1, #card._skills do
            local skill = card._skills[i]
            if B.skillHasMode(skill, Data.SkillMode.halo) then
                local actionDelay, _ = playerUi:castSkillAction(cardSprite, type, skill, Data.SkillMode.halo)
                if delay < actionDelay then delay = actionDelay end
            end
        end
    end
    
    return delay
end

function _M:accountStatus(card, delay)
    local tempDelay = delay

    local cardSprite = self:getCardSprite(card) or self._opponentUi:getCardSprite(card)
    if cardSprite ~= nil and (cardSprite == self._battleUi._touchCard) then 
        self._battleUi:onTouchCanceled()
    end

    local sourceStatus = card._sourceStatus
    local destStatus = card._destStatus

    self:updateBall()

    ------------------------ remove card from ---------------------------------
    if sourceStatus == BattleData.CardStatus.leave then
        cardSprite = self:removeCardFromLeave(card)
    elseif sourceStatus == BattleData.CardStatus.pile then
        cardSprite = self:removeCardFromPile(card)
    elseif sourceStatus == BattleData.CardStatus.hand then
        cardSprite._ownerUi:removeCardFromHand(card)
    elseif sourceStatus == BattleData.CardStatus.board then
        cardSprite._ownerUi:removeCardFromBoard(card)
    elseif sourceStatus == BattleData.CardStatus.grave then
        cardSprite._ownerUi:removeCardFromGrave(card)
    end

    -- check ownerui
    if cardSprite and cardSprite._ownerUi._player ~= card._owner then
        cardSprite._ownerUi:removeCardToOppo(cardSprite)
    end 

    
    ----------------------- add card to ------------------------------------
    if destStatus == BattleData.CardStatus.leave then
        tempDelay, delay = self:addCardToLeave(card, tempDelay, delay)
    elseif destStatus == BattleData.CardStatus.pile then
        tempDelay, delay = self:addCardToPile(card, tempDelay, delay)
    elseif destStatus == BattleData.CardStatus.hand then
        tempDelay, delay = self:addCardToHand(card, tempDelay, delay)
    elseif destStatus == BattleData.CardStatus.board then
        tempDelay, delay = self:addCardToBoard(card, tempDelay, delay)
    elseif destStatus == BattleData.CardStatus.grave then
        tempDelay, delay = self:addCardToGrave(card, tempDelay, delay)
    end
    
    ---------------------- update ui -------------------------------------
    if sourceStatus == BattleData.CardStatus.hand and destStatus == BattleData.CardStatus.board then
        --self:updatePower()
    end

	if (self._player._saved and self._player._saved._cardStatusToChange and #self._player._saved._cardStatusToChange > 0) or 
        (self._player._opponent._saved and self._player._opponent._saved._cardStatusToChange and #self._player._opponent._saved._cardStatusToChange > 0) then
		delay = tempDelay
	end
    
    return delay
end

function _M:accountReorder(delay)
    for index = 1, 2 do
        local playerUi = (index == 1) and self or self._opponentUi
        local player = (index == 1) and self._player or self._player._opponent
        local cards = {}
        for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
            local card = player._boardCards[i]
            if card ~= nil then
                for j = 1, Data.MAX_CARD_COUNT_ON_BOARD do
                    local cardSprite = playerUi._pBoardCards[j]
                    if cardSprite ~= nil and cardSprite._card == card then
                        cards[card._pos] = cardSprite
                        break
                    end
                end
            end
        end
        playerUi._pBoardCards = cards
    end

    local delay1 = self:replaceBoardCards(delay)
    local delay2 = self._opponentUi:replaceBoardCards(delay)
    delay = delay1 > delay2 and delay1 or delay2

    return delay
end

function _M:accountPosChange(delay)
    self._battleUi:hideCardAttack()
    self:updatePower()

    local boardCardSprites = {{}, {}}
    
    for playerIndex = 1, 2 do
        local player = playerIndex == 1 and self._player or self._player._opponent
        local playerUi = playerIndex == 1 and self or self._opponentUi
        local opponentUi = playerIndex == 1 and self._opponentUi or self
        local boardSprites = boardCardSprites[playerIndex]
        
        for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
            local boardCard = player._boardCards[i]
            if boardCard ~= nil then
                local cardSprite = playerUi:getBoardCardSprite(boardCard)
                if cardSprite == nil then
                    cardSprite = opponentUi:getBoardCardSprite(boardCard)
                    if cardSprite ~= nil then
                        opponentUi:removeCardToOppo(cardSprite)
                    end
                end
                boardSprites[i] = cardSprite
            end
        end
    end

    self._pBoardCards = boardCardSprites[1]
    self._opponentUi._pBoardCards = boardCardSprites[2]
    
    local delay1 = self:replaceBoardCards(delay)
    local delay2 = self._opponentUi:replaceBoardCards(delay)
    delay = delay1 > delay2 and delay1 or delay2
    
    if self._player:getActionPlayer()._macroStatus == BattleData.Status.use and self._player:getActionPlayer()._actionCard._status == BattleData.CardStatus.hand then
        return 0
    else
        return delay
    end
end

function _M:accountAction(delay, type, actionCard)
    local cards = self._player:getAllCards()

    -- play attack or skill action
    local actionDelay = 0
    for _, srcCard in ipairs(cards) do
        if next(srcCard._castedSkills) ~= nil then            
            local playerUi = srcCard._owner._isAttacker == self._isAttacker and self or self._opponentUi

            local cardSprite = self:getCardSprite(srcCard) or self._opponentUi:getCardSprite(srcCard)

            local castedSkills = srcCard._castedSkills or {}
            
            -- reset
            srcCard._castedSkills = {}
            
            for _, castedSkill in ipairs(castedSkills) do
                if castedSkill._id == 0 then
                    local target = actionCard._atkTargets[1]
                    if target._type == Data.CardType.fortress then
                        delay, actionDelay = playerUi:playAction(cardSprite, _M.Action.attack_fortress, delay, target)
                    else
                        delay, actionDelay = playerUi:playAction(cardSprite, _M.Action.attack_card, delay, target)
                    end
                else
                    delay, actionDelay = playerUi:castSkillAction(cardSprite, type, castedSkill, Data.SkillMode.spelling)
                end
            end
        end
    end

    -- account data
    for _, dstCard in ipairs(cards) do
        local playerUi = dstCard._owner._isAttacker == self._isAttacker and self or self._opponentUi
        local cardSprite = self:getCardSprite(dstCard) or self._opponentUi:getCardSprite(dstCard)

        if next(dstCard._changed) ~= nil then
            local changed = dstCard._changed or {}

            -- reset
            dstCard._changed = {}

            for k, v in pairs(changed) do
                if k == '_damage' then
                    if dstCard._type == Data.CardType.fortress then playerUi:playAction(nil, _M.Action.fortress_hurt, delay, v)
                    else playerUi:playAction(cardSprite, _M.Action.card_hurt, delay, v) end
                elseif k == '_hp' then
                    if dstCard._type == Data.CardType.fortress then playerUi:playAction(nil, v > 0 and _M.Action.fortress_hp_inc or _M.Action.fortress_hp_dec, delay, v)
                    else playerUi:playAction(cardSprite, v > 0 and _M.Action.hp_inc or _M.Action.hp_dec, delay, v) end
                elseif k == '_atk' then
                    playerUi:playAction(cardSprite, v > 0 and _M.Action.atk_inc or _M.Action.atk_dec, delay, v)
                elseif k == '_nature' then
                    playerUi:playAction(cardSprite, _M.Action.change_nature, delay, v)
                elseif k == '_actionCount' then
                    cardSprite:updateBoardActive()
                elseif k == '_skillLevelInc' then
                    -- display something
                elseif k == '_positiveStatus' then
                    playerUi:playAction(cardSprite, _M.Action.update_positive_status, delay)
                elseif k == '_negativeStatus' then
                    playerUi:playAction(cardSprite, _M.Action.update_negative_status, delay)
                elseif k == '_bind' then
                    playerUi:playAction(cardSprite, _M.Action.update_bind, delay)
                elseif k == '_power' then
                    playerUi:updatePower()
                elseif k == '_ball' then
                    playerUi:updateBall()
                else
                    lc.log("[BATTLE] !!!!!!!!!!!!!!! unhandled property change: %s", k)
                end
            end
        end
    end

    -- actionDelay
    if type == BattleData.Status.attacking or type == BattleData.Status.spelling then 
        self._actionDelay = actionDelay
    elseif type == BattleData.Status.account_attack or type == BattleData.Status.account_spell then
        delay = delay + (self._actionDelay or 0)
        self._actionDelay = 0
    elseif type == BattleData.Status.under_spell or type == BattleData.Status.under_defend_spell or type == BattleData.Status.under_spell_damage or type == BattleData.Status.under_counter_spell or 
        type == BattleData.Status.under_attack or type == BattleData.Status.under_defend_attack or type == BattleData.Status.under_attack_damage or type == BattleData.Status.under_counter_attack or type == BattleData.Status.ac_under_attack_damage then 
        delay = 0 
        if self._actionDelay < actionDelay then self._actionDelay = actionDelay end
    else 
        delay = actionDelay + delay
    end

    return delay
end

function _M:accountEvent(delay)
    local player = self._player
    
    local event = player._actionEvent
    local effect, effectVals = player:getActionEffect(event, player._eventIndex)
    local playerUi = event._owner == self._player and self or self._opponentUi
        
    -- event label
    if player._effectIndex == 0 then
        -- Simply skip the event label, do nothing

    -- event story dialog
    elseif player._effectIndex == 1 then
        local story = player:getActionStory(event, player._eventIndex)
        if story ~= nil and story[1] ~= 0 then
            self:castEventStory(event, story)
            delay = nil
        end
        
    -- event effect
    elseif player._effectIndex == 2 then
        delay = playerUi:castEventAction(event, effect, effectVals)
        
    end
    
    -- delay == nil means stop battle step
    return delay
end

function _M:castEventStory(event, storyIds)
    self._battleUi:showEvent(BattleEventDialog.Type.story, storyIds)
end

function _M:castEventAction(event, id, vals)
    local time = 0
    
    local vals = vals or {}
    local player = self._player
    local actionCard = player:getActionCard()
    
    if id >= 1 and id <= 6 or id == 8 or id == 12 or id == 17 then
        time = 0
    
    elseif id == 7 then
        local cardSprite = self:getBoardCardSpriteByInfoId(vals.id, true)
        if cardSprite ~= nil then
            self:efcDragonBones(cardSprite, "jinu", cc.p(0, -10), true, false, "effect", 1.8)
            time = 1.0
        end
        
    elseif id == 9 then
        self._battleUi:showEvent(BattleEventDialog.Type.info_help)
        time = nil
        
    elseif id == 10 then
        local cardSprite, targetCardSprite = self:getHandCardSpriteByInfoId(vals.id), vals.ti and self:getBoardCardSpriteByInfoId(vals.ti) or nil
        if cardSprite then
            self._battleUi:showEvent(BattleEventDialog.Type.guide_drag_to_pos, {cardSprite, targetCardSprite}, vals.df ~= nil)
            time = 0
        end
        
    elseif id == 11 then
        self._battleUi:showEvent(BattleEventDialog.Type.guide_tap, self._battleUi._btnEndRound, vals.df ~= nil)
        time = 0
        
    elseif id == 13 then
        
        
    elseif id == 14 then
        local cardSprite, targetCardSprite = self:getBoardCardSpriteByInfoId(vals.id, false), vals.ti and self._opponentUi:getBoardCardSpriteByInfoId(vals.ti, false) or nil
        if cardSprite then
            self._battleUi:showEvent(BattleEventDialog.Type.guide_drag_to_attack, {cardSprite, targetCardSprite}, vals.df ~= nil, id)
            time = 0
        end
        
    elseif id == 15 then
        self._battleUi:hideEvent()
        time = nil
    
    elseif id == 16 then
        self._battleUi:exitScene()
        time = nil
    
    elseif id == 18 then
        self:playAction(nil, _M.Action.fortress_hp_inc, 0, vals.hp)
        time = 1.0
    
    elseif id == 19 then
        self._battleUi:showTip(vals)
        if vals.t.touch == 1 then
            time = nil
        else
            time = 0
        end
        
    elseif id == 20 then
        self._battleUi:showEvent(BattleEventDialog.Type.guide_tap, ui._btnAuto, vals.df ~= nil)
        time = 0
       
    elseif id == 21 then
        local cardSprite = self:getHandCardSpriteByInfoId(vals.id, false)
        if cardSprite then
            self._battleUi:showEvent(BattleEventDialog.Type.guide_drag, cardSprite, vals.df ~= nil)
            time = 0
        end

    elseif id == 22 then
        local cardSprite, targetCardSprite = self:getBoardCardSpriteByInfoId(vals.id), self:getBoardCardSpriteByInfoId(vals.ti)
        if cardSprite and targetCardSprite then
            self._battleUi:showEvent(BattleEventDialog.Type.guide_drag_to_card, {cardSprite, targetCardSprite}, vals.df ~= nil)
            time = 0
        end

    elseif id == 23 then
        local cardSprite = self:getBoardCardSpriteByInfoId(vals.id, false)
        if cardSprite then
            self._battleUi:showEvent(BattleEventDialog.Type.guide_drag_to_defend, {cardSprite}, vals.df ~= nil)
            time = 0
        end

    elseif id == 51 then
        --[[
        local cardSprite = self:getBoardCardSpriteByInfoId(vals.id, false)
        if cardSprite then
            cardSprite:runAction(lc.ease(lc.scaleTo(1.0, 0.8 / CardSprite.Scale.normal), "ElasticO", 0.6))
            time = 0
        end
        ]]

    elseif id == 52 then
        --[[
        local cardSprite = self:getBoardCardSpriteByInfoId(vals.id, false)
        if cardSprite then
            cardSprite:runAction(lc.scaleTo(0.2, 1))
            time = 0
        end
        ]]

    elseif id == 53 then
        self._battleUi:showTask()
        time = nil

    elseif id == 54 then
        local cardSprite = self:getHandCardSpriteByInfoId(vals.id)
        if cardSprite then
            self._battleUi:onTouchCanceled()

            self._isTouching = false

            cardSprite:onTouchEnded()
            cardSprite:onTouchBegan()
            cardSprite:setPositionX(V.SCR_CW)
            time = 0
        end

    elseif id == 55 then
        local cardSprite = self:getHandCardSpriteByInfoId(vals.id)
        if cardSprite then
            
            cardSprite:onTouchEnded()
            self:playAction(cardSprite, _M.Action.replace_hand_card, 0, 1)
            time = 0
        end

    elseif id == 71 then
        lc.Audio.playAudio(AUDIO.M_GUIDE1)

    end
    
    return time
end

function _M:playAction(pCard, actionId, delay, val)
    if delay == nil then delay = 0 end
    local card = (pCard ~= nil) and pCard._card or nil
    
    ---------------------------------------------
    -- base action
    ---------------------------------------------
    if actionId == _M.Action.replace_hand_card then
        local pos, rot = pCard._default._position, pCard._default._rotation
        
        if cc.p(pCard:getPosition()).x == pos.x and cc.p(pCard:getPosition()).y == pos.y and pCard:getRotation() == rot and pCard:getScale() == 1 then return delay end
        local ran = 0.2 * val / Data.MAX_CARD_COUNT_IN_HAND
        
        pCard:runAction(lc.sequence(
            lc.delay(delay + ran), 
            lc.call(function() pCard:updateZOrder() end), 
            cc.EaseOut:create(lc.spawn(lc.moveTo(0.4, pos), lc.rotateTo(0.4, rot), lc.scaleTo(0.4, 1)), 2.5)
            ))
            
        return delay + 0.4
                
    elseif actionId == _M.Action.replace_board_card then
        local pos = pCard._default._position
        if pCard:getPosition() == pos and pCard:getRotation() == 0 and pCard:getScale() == 1 then return delay end
        
        pCard:runAction(lc.sequence(
            lc.delay(delay), 
            lc.call(function() pCard:updateZOrder() end),
            cc.EaseOut:create(lc.spawn(lc.moveTo(0.5, pos), lc.rotateTo(0.5, 0), lc.scaleTo(0.5, 1)), 2.5),
            lc.call(function() 
                pCard._pCardArea:setScale(card._pos == 1 and CardSprite.Scale.normal_main or CardSprite.Scale.normal) 
                pCard:setRotation3D({x = 0, y = 0, z = 0})
                pCard:updateBoardActive()
            end)
            ))
        
        return delay + 0.5
            
    ---------------------------------------------
    -- normal action
    ---------------------------------------------
    elseif actionId == _M.Action.attack_card then
        local cardImage = pCard._pFrame._image:getOpacity() ~= 0 and pCard._pFrame._image or pCard._pFrame._bones
        local parent = cardImage:getParent()
        local oppoPlayer = val._owner._isAttacker == self._isAttacker and self or self._opponentUi 

        local srcPos = cc.p(cardImage:getPosition())
        local destPos
        local targetImage = oppoPlayer._pBoardCards[val._pos]._pFrame._image
        destPos = cardImage:getParent():convertToNodeSpace(targetImage:getParent():convertToWorldSpace(cc.p(targetImage:getPosition())))
        -- action
        pCard:updateZOrder(true)

        cardImage:stopAllActions()
        cardImage:runAction(lc.sequence(
            delay,
            lc.ease(lc.moveTo(0.2, destPos), 'I', 2.5),
            function () 
                self:sendEvent(_M.EventType.efc_screen_attack_card, {_startPos = srcPos, _endPos = destPos})
                if actionId == _M.Action.attack_card then self:efcCardHurt(oppoPlayer._pBoardCards[val._pos]) end
                self._audioEngine:playEffect("e_card_hurt") 
            end,
            lc.ease(lc.moveTo(0.2, srcPos), 'BackO', 2.5),
            function() 
                pCard:updateZOrder()

                self:updateBoardCardsActive()
            end
        ))

        return delay + 0.4, 0.4

    elseif actionId == _M.Action.attack_fortress then  
        local cardImage = pCard._pFrame._image:getOpacity() ~= 0 and pCard._pFrame._image or pCard._pFrame._bones
        local parent = cardImage:getParent()

        local oppoPlayer = val._owner == self._player and self or self._opponentUi 
        local posInPlayerUi
        if not self._battleUi._isReverse then
            posInPlayerUi = oppoPlayer._isController and _M.Pos.attacker_fortress or _M.Pos.defender_fortress
        else
            posInPlayerUi = oppoPlayer._isController and _M.Pos.defender_fortress or _M.Pos.attacker_fortress
        end

        -- attack self fortress
        if card._owner == val._owner then
            if not self._battleUi._isReverse then
                posInPlayerUi = oppoPlayer._isController and cc.p(0, 0) or cc.p(V.SCR_W, V.SCR_H)
            else
                posInPlayerUi = oppoPlayer._isController and cc.p(V.SCR_W, V.SCR_H) or cc.p(0, 0)
            end
        end

        local srcPos = cc.p(cardImage:getPosition())
        local destPos = parent:convertToNodeSpace3D(posInPlayerUi, ClientData._camera3D)

        pCard:updateZOrder(true)

        cardImage:stopAllActions()
        cardImage:runAction(lc.sequence(
            delay + 0.4,
            lc.ease(lc.moveTo(0.2, destPos), 'I', 2.5),
            function () 
                self:sendEvent(_M.EventType.efc_screen_fortress_hurt)

                self._audioEngine:playEffect("e_card_hurt") 
            end,
            lc.ease(lc.moveTo(0.2, srcPos), 'BackO', 2.5),
            function() 
                pCard:updateZOrder()

                self:updateBoardCardsActive()
            end
            ))

        return delay + 0.6, 0.4
            
    elseif actionId == _M.Action.fortress_hurt then
        self:playAction(pCard, _M.Action.fortress_hp_update, delay)
        self._battleUi:runAction(lc.sequence(
            lc.delay(delay),
            lc.call(function() self:efcFortressHurt(val) end)
            ))
            
        return delay
    
    elseif actionId == _M.Action.card_hurt then
        local dir = self._isController and -1 or 1
        
        self:playAction(pCard, _M.Action.hp_update, delay)
        pCard:runAction(lc.sequence(
            lc.delay(delay),
            lc.call(function() 
                self:efcCardHurt(pCard, val) 
                pCard:updateZOrder()
            end),
            cc.MoveBy:create(0.12, cc.p(0, 15 * dir)),
            cc.MoveBy:create(0.12, cc.p(0, -15 * dir))
            ))
       
        return delay
            
    elseif actionId == _M.Action.fortress_die then
        self._battleUi:runAction(lc.sequence(
            lc.delay(delay),
            lc.call(function () self:efcFortressDie() end)
            ))
        
        return delay + 2.0
   
    ---------------------------------------------
    -- value changed
    ---------------------------------------------
    elseif actionId == _M.Action.fortress_hp_update then
        if self._player._fortressHp == 0 then return delay end

        local pText = self._pHpLabel
        local endColor = self:getLabelColor(self._player._fortress._hp, self._player._fortress._maxHp)
        local color = lc.Color3B.white
        if self._player._fortress._hp > tonumber(pText:getString()) then color = lc.Color3B.green
        elseif self._player._fortress._hp < tonumber(pText:getString()) then color = lc.Color3B.red end
        
        pText:runAction(lc.sequence(
            lc.delay(delay),
            lc.call(function () pText:setColor(color); self:updateFortressHp() end),
            lc.scaleTo(0.16, 0.8), lc.scaleTo(0.12, 1.1), lc.scaleTo(0.08, 0.9), lc.scaleTo(0.04, 1),
            cc.TintTo:create(1.0, endColor.r, endColor.g, endColor.b)
            ))
        
        return delay
    
    elseif actionId == _M.Action.fortress_atk_update then
        local pText = self._pAtkLabel
        local endColor = self:getLabelColor(self._player._fortress._atk, self._player._fortress._maxAtk)
        local color = lc.Color3B.white
        if self._player._fortress._atk > tonumber(pText:getString()) then color = lc.Color3B.green
        elseif self._player._fortress._atk < tonumber(pText:getString()) then color = lc.Color3B.red end
        
        pText:runAction(lc.sequence(
            lc.delay(delay),
            lc.call(function () pText:setColor(color); self:updateFortressAtk() end),
            lc.scaleTo(0.16, 0.8), lc.scaleTo(0.12, 1.1), lc.scaleTo(0.08, 0.9), lc.scaleTo(0.04, 1),
            cc.TintTo:create(1.0, endColor.r, endColor.g, endColor.b)
            ))
        
        return delay
        
    elseif actionId == _M.Action.atk_update then
        return delay
        
    elseif actionId == _M.Action.hp_update then
        if pCard._pHpSpr ~= nil then
            local defaultScale = 1.0

            pCard._pHpSpr:runAction(lc.sequence(
                lc.delay(delay),
                lc.call(function () pCard:updateAtkHp() end)
                ))
            pCard._pHpSpr:runAction(lc.sequence(
                lc.delay(delay),
                lc.scaleTo(0.16, defaultScale * 0.8), lc.scaleTo(0.12, defaultScale * 1.2), lc.scaleTo(0.08, defaultScale * 0.9), lc.scaleTo(0.04, defaultScale)
                ))
        end
        
        return delay
    
    elseif actionId == _M.Action.fortress_hp_inc or actionId == _M.Action.fortress_hp_dec then
        self:playAction(pCard, _M.Action.fortress_hp_update, delay)    
        if val ~= 0 then   
            self._battleUi:runAction(lc.sequence(
                lc.delay(delay),
                lc.call(function () self:efcFortressHpLabel(val) end)
                ))
        end
        return delay
    
    elseif actionId == _M.Action.fortress_atk_inc or actionId == _M.Action.fortress_atk_dec then
        self:playAction(pCard, _M.Action.fortress_atk_update, delay)     
        if val ~= 0 then  
            self._battleUi:runAction(lc.sequence(
                lc.delay(delay),
                lc.call(function () self:efcFortressAtkLabel(val) end)
                ))
        end
        return delay
        
    elseif actionId == _M.Action.hp_inc or actionId == _M.Action.hp_dec then
        if pCard and pCard._pHpSpr ~= nil then
            self:playAction(pCard, _M.Action.hp_update, delay)
            self._battleUi:runAction(lc.sequence(
                lc.delay(delay),
                lc.call(function () self:efcCardHpLabel(pCard, val) end)
                ))
        end
        
        return delay
           
    elseif actionId == _M.Action.atk_inc or actionId == _M.Action.atk_dec then
        return delay

    elseif actionId == _M.Action.change_nature then
        return delay
    
    ---------------------------------------------
    -- skill status
    ---------------------------------------------
    elseif actionId == _M.Action.update_positive_status then
        if pCard ~= nil then
            self._battleUi:runAction(lc.sequence(
                lc.delay(delay), 
                lc.call(function () 
                    if pCard._card:isMonster() or pCard._card._type == Data.CardType.magic or pCard._card._type == Data.CardType.trap then
                        pCard:updatePositiveStatus() 
                    end
                end)
                ))
        else
            self:efcFortressPositiveStatus(self._avatarFrame, self._player._fortress)
        end
        
        return delay
        
    elseif actionId == _M.Action.update_negative_status then
        if pCard ~= nil then
            self._battleUi:runAction(lc.sequence(
                lc.delay(delay),
                lc.call(function () pCard:updateNegativeStatus() end)
                ))
        else
            self:efcFortressNegativeStatus(self._avatarFrame, self._player._fortress)
        end
       
        return delay

    elseif actionId == _M.Action.avoid_attack then
        local dir = self._isController and -1 or 1

        pCard:runAction(lc.sequence(
            cc.EaseOut:create(lc.spawn(
                                cc.MoveBy:create(0.2, cc.p(-50 * dir, 30 * dir)), 
                                cc.RotateBy:create(0.2, -10 * dir)
                              ), 3),
            cc.EaseIn:create(lc.spawn(
                                cc.MoveBy:create(0.1, cc.p(50 * dir, -30 * dir)), 
                                cc.RotateBy:create(0.1, 10 * dir)
                              ), 3)
            ))
        pCard._pShadowArea:runAction(lc.sequence(
            cc.EaseOut:create(cc.MoveBy:create(0.2, cc.p(-60, -30)), 3),
            cc.EaseOut:create(cc.MoveBy:create(0.1, cc.p(60, 30)), 3)
            ))
        
        return delay

    elseif actionId == _M.Action.update_bind then
        if card:isMonster() then
            pCard:updateBuffIcons()
            return delay 
        end
        
    else
        lc.log("[PLAYER UI] UNHANDLED ACTION!!!")
        return delay
        
    end
end

function _M:showHandCards()
    local count = #self._pHandCards
    local step = 130 + (8 - count) * 15
    
    if self._isController then
        for i, handCard in ipairs(self._pHandCards) do
            local pos = cc.p(V.SCR_CW + (i - (count / 2 + 0.5)) * step, _M.Pos.attacker_board_y[1] - 150)
            local sPos, sRot = handCard._default._position, handCard._default._rotation
            
            handCard:runAction(lc.sequence(
                lc.delay(i * 0.2),
                lc.call(function () handCard:updateZOrder(true) end),
                cc.EaseBackOut:create(lc.spawn(lc.moveTo(0.3, pos), lc.rotateTo(0.3, 0), lc.scaleTo(0.3, 1.3))),
                lc.delay((count - i) * 0.2 + 1.0),
                cc.EaseBackOut:create(lc.spawn(lc.moveTo(0.3, sPos), lc.rotateTo(0.3, sRot), lc.scaleTo(0.3, 1.0))),
                lc.call(function () handCard:updateZOrder() end)
                ))
        end
        
        return count * 0.2 + 1.8
        
    else
        for i, handCard in ipairs(self._pHandCards) do
            local pos = cc.p(V.SCR_CW + (i - (count / 2 + 0.5)) * step, _M.Pos.defender_board_y + 35)
            local sPos, sRot = handCard._default._position, handCard._default._rotation
            
            handCard:runAction(lc.sequence(
                lc.delay(i * 0.2),
                lc.call(function () handCard:updateZOrder(true) end),
                cc.EaseBackOut:create(lc.spawn(lc.moveTo(0.3, pos), lc.rotateTo(0.3, 0), lc.scaleTo(0.3, 1.3))),
                cc.RotateBy:create(0.2, {x = 0, y = 90, z = 0}),
                lc.call(function () handCard:initNormal(); handCard:setRotation3D({x = 0, y = -90, z = 0}) end),
                cc.RotateBy:create(0.2, {x = 0, y = 90, z = 0}),
                lc.delay((count - i) * 0.2 + 1.4),
                cc.RotateBy:create(0.2, {x = 0, y = 90, z = 0}),
                lc.call(function () handCard:initBack(); handCard:setRotation3D({x = 0, y = -90, z = 0}) end),
                cc.RotateBy:create(0.2, {x = 0, y = 90, z = 0}),
                cc.EaseBackOut:create(lc.spawn(lc.moveTo(0.3, sPos), lc.rotateTo(0.3, sRot), lc.scaleTo(0.3, 1.0))),
                lc.call(function () handCard:updateZOrder() end)
            ))
        end
        
        return count * 0.2 + 3.0
    end
end

function _M:replaceHandCards(delay, card)
    local addDelay = 0
    for index, pCard in ipairs(self._pHandCards) do
        if pCard and  pCard._card ~= card then
            self:calHandCardPosAndRot(pCard)
            
            if pCard._status ~= CardSprite.Status.large and pCard._status ~= CardSprite.Status.info then
                local curPos, destPos = cc.p(pCard:getPosition()), pCard._default._position
                if curPos.x ~= destPos.x or curPos.y ~= destPos.y then
                    pCard:stopAllActions()
                    addDelay = self:playAction(pCard, _M.Action.replace_hand_card, delay, index)
                end
            end
        end
    end
    
    return delay + addDelay
end

function _M:replaceBoardCards(delay, card)
    local addDelay = 0
    if delay == nil then delay = 0 end

    for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
        local pCard = self._pBoardCards[i]
        if pCard and pCard._card ~= card then
            self:calBoardCardPos(pCard)
            
            local curPos, destPos = cc.p(pCard:getPosition()), pCard._default._position
            if curPos.x ~= destPos.x or curPos.y ~= destPos.y then
                pCard:stopAllActions()
                addDelay = self:playAction(pCard, _M.Action.replace_board_card, delay, i)
            end
         end
    end
    
    return delay + addDelay
end

function _M:addGraveCard(pCard)
    pCard:stopAllActions()
    pCard:setVisible(true)
    pCard:setOpacity(255)

    pCard:setRotation(0)
    pCard._pCardArea:setScale(pCard.Scale.grave)
    --pCard:setPosition(27, 27)

    pCard._pShadowArea:stopAllActions()
    pCard._pShadowArea:setPosition(0, 0)
    pCard._pShadowArea:setRotation(0)
    
    self:resetCard(pCard)
    pCard:initDead()
    pCard:setTag(1)

    -- Must remove children after initDead()
    pCard._pEffectArea:removeAllChildren()
    pCard._pBottomEffectArea:removeAllChildren()

    pCard:setPosition(self._isController and _M.Pos.attacker_grave or _M.Pos.defender_grave)
    
    self:updateGraveArea()
end

------------------------------------------
-- action call function
------------------------------------------

function _M:removeCardToOppo(cardSprite)
    self:removeCardFromSprites(cardSprite)
    self._opponentUi:addCardToSprites(cardSprite)

    cardSprite:setPlayerUi(self._opponentUi)

    local card = cardSprite._card
    if card:isMonster() and card._status == BattleData.CardStatus.board then
        cardSprite:reloadAllStatus()
    end
end

function _M:removeCardFromSprites(cardSprite)
    if cardSprite == nil then return end

    local card = cardSprite._card
    self._cardSprites[card._id] = nil
end

function _M:addCardToSprites(cardSprite)
    if cardSprite == nil then return end

    local card = cardSprite._card
    self._cardSprites[card._id] = cardSprite
    cardSprite._isAttacker = self._battleUi._isAttacker
    cardSprite._isController = (self._isAttacker == self._battleUi._isAttacker)

    if cardSprite._pHorse ~= nil then
        self:addCardToSprites(cardSprite._pHorse)
    end
end

function _M:doReorderHand()
    for index, cardSprite in ipairs(self._pHandCards) do
        local pos, rot = self:calHandCardPosAndRot(cardSprite)
        cardSprite:setPosition(pos)
        cardSprite:setRotation3D(rot)
    end
end

function _M:doReorderBoard()
    for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
        local cardSprite = self._pBoardCards[i]
        if cardSprite ~= nil then
            local pos = self:calBoardCardPos(cardSprite)
            cardSprite:setPosition(pos)
         end
    end
end

