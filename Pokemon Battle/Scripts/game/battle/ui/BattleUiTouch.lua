local _M = BattleUi


function _M:onTouchBegan(touch)
    if (not self:isVisible()) or self._isTouching or touch:getId() ~= 0 then return false end

    if P._guideID < 20 then return false end

    if self._dropLayer then
        self._isTouching = self._dropLayer:onTouchBegan(touch)
        return self._isTouching 
    end

    local touchedCard = self:getTouchedCard(touch)
    
    if touchedCard then
        if self._showingAttackCard and touchedCard ~= self._showingAttackCard then self:hideCardAttack() end

        --[[
        -- Guide check. Only the guide card can be moved and dragged to the borad
        if self._eventLayer and self._guideNode ~= touchedCard._pFrame then
            return false
        end
            ]]

        --if P._guideID < 100 and self._guideNode ~= touchedCard._pFrame then return false end

        if touchedCard._status == CardSprite.Status.back then
            if touchedCard._ownerUi._isController then
                touchedCard._ownerUi:sendEvent(PlayerUi.EventType.dialog_attacker_hand_cards)
            else
                touchedCard._ownerUi:sendEvent(PlayerUi.EventType.dialog_defender_hand_cards)
            end
            return false
            
        else
            self._isTouching = true
            self._touchCard = touchedCard
            touchedCard:onTouchBegan(touch)

            touchedCard._targetCard = nil
            local card = touchedCard._card
            local player = touchedCard._card._owner
            
            --[[
            if touchedCard._isController and card._status == BattleData.CardStatus.board and card:canAction() then
                self._arrow = BattleLine.create(touchedCard:convertToWorldSpace3D(cc.p(0, 0), ClientData._camera3D))
                self._layer:addChild(self._arrow)
            end
            ]]
            
            return true
        end
    end

    if self._showingAttackCard then self:hideCardAttack() end
    return false
end

function _M:onTouchMoved(touch)
    if (not self._isTouching) then return end

    if self._showingAttackCard then return end

    if self._dropLayer then return self._dropLayer:onTouchMoved(touch) end

    if (not self._touchCard) then return end

    -- Check whether touch is really moving
    local beganPos, curPos = touch:getStartLocation(), touch:getLocation()
    if cc.pGetDistance(beganPos, curPos) <= lc.Gesture.BUDGE_LIMIT then
        return
    end

    local touchedCard = self._touchCard
    local card = touchedCard._card
    local player = card._owner
    local playerUi = touchedCard._ownerUi

    -- Close tip if exists
    if (self._guideTipVals and self._guideTipVals.t.touch == 0) or self._freeTip then
        self:hideTip()
    end

    if self._selectTargetLayer then
        return self._selectTargetLayer:onTouchMoved(touch)
    end

    touchedCard:onTouchMoved(touch)

    if self._isOperating then
        -- operating
        if touchedCard._touchEvent._touchCardType == CardSprite.TouchCardType.self_hand_card then
            -- hand card 

            local isExit = false
            if self._isAddingBoardCard then
                isExit = true 
                playerUi:sendEvent(PlayerUi.EventType.dialog_adding_board_card)
            elseif card:isMonster() then 
                if not player:canUseMonster(card, false) then
                    isExit = true
                    playerUi:sendEvent(PlayerUi.EventType.dialog_not_enough_gem)
                end
            elseif card._type == Data.CardType.magic then
                if not player:canUseMagic(card, false) then
                    isExit = true
                    playerUi:sendEvent(PlayerUi.EventType.dialog_cannot_effect, card._type)    
                end
            elseif card._type == Data.CardType.trap then
                local canUse, errorStr = player:canUseTrap(card, false)
                if not canUse then
                    isExit = true
                    playerUi:sendEvent(errorStr == 'existed' and PlayerUi.EventType.dialog_trap_existed or PlayerUi.EventType.dialog_cannot_effect, card._type)    
                end
            end
                
            if isExit then 
                self:hidePreview(touchedCard)
                touchedCard:onTouchEnded(touch)
                self._touchCard = nil
                playerUi:playAction(touchedCard, PlayerUi.Action.replace_hand_card, 0, 1)
                return
            end
            
            if (card:isMonster() and card._info._level > 0)
                or (card._type == Data.CardType.magic and (card._info._type == Data.MagicTrapType.equip or card._info._type == Data.MagicTrapType.power)) then
                self:showSelectTarget(touchedCard, touch)
                return
            end

            if card:isMonster() then
                local targetCard = self:getTouchedBoardCard(touch, touchedCard, true, playerUi)

                local dragToCard, dragType = self:getEventDragTo()
                if (dragType == BattleEventDialog.Type.guide_drag_to_card and dragToCard ~= nil and dragToCard ~= targetCard)
                    or ((dragType == BattleEventDialog.Type.guide_drag_to_pos or dragType == BattleEventDialog.Type.guide_drag_to_attack or dragType == BattleEventDialog.Type.guide_drag_to_defend) and dragToCard ~= targetCard) then
                    targetCard = nil
                end
                
                if targetCard ~= nil and targetCard ~= touchedCard._targetCard then 
                    self:hidePreview(touchedCard)
                    self:preview(touchedCard, targetCard)
                elseif targetCard == nil then
                    self:hidePreview(touchedCard)
                end
            end
            

        elseif (not self._isAddingBoardCard) and card._owner._macroStatus == BattleData.Status.use and touchedCard._touchEvent._touchCardType == CardSprite.TouchCardType.board_card and card:canAction() then
            -- board card

            
        end

    else
        -- not operating

        if touchedCard._touchEvent._touchCardType == CardSprite.TouchCardType.self_hand_card then
            -- hand card
            if touch:getLocation().y >= PlayerUi.Pos.use_area and touch:getPreviousLocation().y < PlayerUi.Pos.use_area then 
                if player:getActionPlayer() == player then
                    playerUi:sendEvent(PlayerUi.EventType.dialog_adding_board_card)
                else
                    playerUi:sendEvent(PlayerUi.EventType.dialog_not_your_round)
                end
                touchedCard:onTouchEnded(touch)
                self._touchCard = nil
                playerUi:playAction(touchedCard, PlayerUi.Action.replace_hand_card, 0, 1)
            end
        end
         
    end
end

function _M:onTouchEnded(touch)
    if not self._isTouching then return end

    -- reset
    self._isTouching = false

    if self._showingAttackCard then return end

    if self._dropLayer  then 
        return self._dropLayer:onTouchEnded(touch) 
    end
    

    if self._touchCard then
        local pCard = self._touchCard
        local card = pCard._card
        local player = card._owner
        local playerUi = pCard._ownerUi

        pCard:onTouchEnded(touch)
        self._touchCard = nil
        
        if self._isOperating then
            if pCard._touchEvent._touchCardType == CardSprite.TouchCardType.self_hand_card then
                if self._selectTargetLayer then
                    return self._selectTargetLayer:onTouchEnded(touch)
                end

                local targetCard = pCard._targetCard
                self:hidePreview(pCard)

                local isExit = false
                if self._isAddingBoardCard then
                    isExit = true 
                elseif card:isMonster() then 
                    if not player:canUseMonster(card, false) then
                        isExit = true
                    end
                elseif card._type == Data.CardType.magic then
                    if not player:canUseMagic(card, false) then
                        isExit = true
                    end
                elseif card._type == Data.CardType.trap then
                    local canUse, errorStr = player:canUseTrap(card, false)
                    if not canUse then
                        isExit = true
                    end
                end

                if isExit then
                    playerUi:playAction(pCard, PlayerUi.Action.replace_hand_card, 0, 1)
                    return
                end
                
                -- using card
                if (not self._isAddingBoardCard) and touch:getLocation().y >= PlayerUi.Pos.use_area then
                    local dragCard = self:getEventDrag()
                    if dragCard ~= nil and dragCard ~= pCard then
                        playerUi:playAction(pCard, PlayerUi.Action.replace_hand_card, 0, 1)
                        return
                    end 
                    local dragToCard, dragType = self:getEventDragTo()
                    if ((dragType == BattleEventDialog.Type.guide_drag_to_pos or dragType == BattleEventDialog.Type.guide_drag_to_attack or dragType == BattleEventDialog.Type.guide_drag_to_defend) and dragToCard ~= targetCard) then
                        playerUi:sendEvent(PlayerUi.EventType.dialog_card_need_aim, 0)
                        playerUi:playAction(pCard, PlayerUi.Action.replace_hand_card, 0, 1)
                        return
                    end 
                    
                    if card:isMonster() then
                        if card._info._level == 0 then
                            playerUi:sendEvent(playerUi.EventType.send_use_card, {_type = BattleData.UseCardType.h2b, _ids = {card._id}})
                        end
                    elseif card._type == Data.CardType.magic or card._type == Data.CardType.trap then
                        local skill = card._skills[1]
                        local isChooseCardsSkill, cards, count = card._owner:isChooseCardsSkill(skill)
                        if isChooseCardsSkill then
                            playerUi:showChoiceCards(pCard, cards, count, {card._id, skill._id})
                        else
                            playerUi:showChoiceSkill(pCard, {card._id, skill._id})
                        end
                    end
                -- reset card move
                else
                    playerUi:playAction(pCard, PlayerUi.Action.replace_hand_card, 0, 1)
                end

            elseif card._owner._macroStatus == BattleData.Status.use and pCard._touchEvent._touchCardType == CardSprite.TouchCardType.board_card and card:canAction() then
                
            end

        elseif (not self._isOperating) and pCard._touchEvent._touchCardType == CardSprite.TouchCardType.self_hand_card then
            playerUi:playAction(pCard, PlayerUi.Action.replace_hand_card, 0, 1)
        end
    end
end

function _M:onTouchCanceled()
    if not self._isTouching then return end
    self._isTouching = false

    if self._dropLayer then 
        return self._dropLayer:onTouchCanceled() 
    end
    
    if self._touchCard then
        local pCard = self._touchCard
        local player = pCard._card._owner
        local playerUi = pCard._ownerUi

        pCard:onTouchCanceled()
        self._touchCard = nil

        if self._selectTargetLayer then
            return self._selectTargetLayer:onTouchCanceled()
        end
        
        if pCard._touchEvent._touchCardType == CardSprite.TouchCardType.self_hand_card then
            if self._isOperating then
                self:hidePreview(pCard)
                playerUi:playAction(pCard, PlayerUi.Action.replace_hand_card, 0, 1)   
                         
            else
                playerUi:playAction(pCard, PlayerUi.Action.replace_hand_card, 0, 1)          
            end
            
        elseif pCard._touchEvent._touchCardType == CardSprite.TouchCardType.board_card then
            self:hidePreview(pCard)
            self:removeExchangeArrow()   
        end
    end
end

function _M:getTouchedCard(touch)
    if self._touchCard and self._touchCard:isVisible() and self._touchCard:getOpacity() > 0 and self._touchCard:containsTouchLocation(touch:getLocation().x, touch:getLocation().y) then
        return self._touchCard
    end
    
    for index = 1, 2 do
        local playerUi = index == 1 and self._playerUi or self._opponentUi

        -- touch hand cards (from right to left)
        for i = #playerUi._pHandCards, 1, -1 do
            local pCard = playerUi._pHandCards[i]
            if pCard ~= nil and pCard:containsTouchLocation(touch:getLocation().x, touch:getLocation().y) then
                return pCard
            end
        end
    
        -- touch board cards
        for i = Data.MAX_CARD_COUNT_ON_BOARD, 1, -1 do
            local pCard = playerUi._pBoardCards[i]
            if pCard ~= nil and pCard:containsTouchLocation(touch:getLocation().x, touch:getLocation().y) then
                return pCard
            end
        end

        -- touch grave cards
        for i = #playerUi._pGraveCards, 1, -1 do
            local pCard = playerUi._pGraveCards[i]
            if pCard ~= nil and pCard:containsTouchLocation(touch:getLocation().x, touch:getLocation().y) then
                return pCard
            end
        end
    end
    
    return nil
end


function _M:getTouchedBoardCard(touch, pCard, isInsert, playerUi)
    if playerUi._isController and touch:getLocation().y >= PlayerUi.Pos.attacker_area then return nil end
    if (not playerUi._isController) and touch:getLocation().y <= PlayerUi.Pos.attacker_area then return nil end

    if isInsert then
        
    else
        for i = Data.MAX_CARD_COUNT_ON_BOARD, 1, -1 do
            local pBoardCard = playerUi._pBoardCards[i]
            if pBoardCard ~= nil and pBoardCard:containsTouchLocation(touch:getLocation().x, touch:getLocation().y) then
                return pBoardCard
            end
        end
    end
end

function _M:removeExchangeArrow()
    if self._arrow then
        self._arrow:removeFromParent()
        self._arrow = nil
    end   
end

function _M:previewInsertBoardCard(pTargetCard, pCard)
    if pTargetCard ~= nil then
        local playerUi = pTargetCard._ownerUi
        local boardPos = pTargetCard._card._pos
        local step = playerUi:calBoardCardStep()

        for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
            local boardCardSprite = playerUi._pBoardCards[i]
            if boardCardSprite ~= nil then
                local pos = boardCardSprite._default._position
                local offsetx = (i < boardPos) and 0 or step
                boardCardSprite:stopAllActions()
                boardCardSprite:runAction(cc.MoveTo:create(0.2, cc.p(pos.x + offsetx, pos.y)))
            end
        end
    end

    if pCard ~= nil then
        pCard:setScale(CardSprite.Scale.normal)
    end
end

function _M:hidePreviewInsertBoardCard(pTargetCard, pCard)
    if pTargetCard ~= nil then
        local playerUi = pTargetCard._ownerUi

        for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
            local boardCardSprite = playerUi._pBoardCards[i]
            if boardCardSprite ~= nil then
                local pos = boardCardSprite._default._position
                boardCardSprite:stopAllActions()
                boardCardSprite:runAction(cc.MoveTo:create(0.2, pos))
            end
        end
    end

    if pCard ~= nil then
        pCard:setScale(CardSprite.Scale.hd)
    end
end

function _M:preview(pCard, pTargetCard)
    local player = pCard._card._owner

    if pCard._targetCard ~= nil then self:hidePreviewInsertBoardCard(pCard._targetCard) end
    pCard._targetCard = pTargetCard
    self:previewInsertBoardCard(pTargetCard, pCard)
end

function _M:hidePreview(pCard)
    if pCard._targetCard ~= nil then
        local player = pCard._card._owner

        self:hidePreviewInsertBoardCard(pCard._targetCard, pCard)
        pCard._targetCard = nil
    end
end

function _M:showSelectTarget(pCard, touch)
    local battleUi = self
    local playerUi = self._playerUi
    local player = playerUi._player
    local card = pCard._card

    local maskLayer = lc.createMaskLayer(0, lc.Color3B.black, V.SCR_SIZE)
    lc.addChildToPos(self._scene, maskLayer, cc.p(0, 0), BattleScene.ZOrder.form)
    maskLayer._pCard = pCard
    self._selectTargetLayer = maskLayer

    maskLayer.onTouchMoved = function(self, touch)
        local targetCard = battleUi:getTouchedBoardCard(touch, pCard, false, battleUi._playerUi)

        if card:isMonster() then
            if targetCard ~= nil and not player:canEvolveCard(card, targetCard._card) then
                targetCard = nil
            end
        elseif card._type == Data.CardType.magic then
            if targetCard ~= nil and not player:canEquipCard(card, targetCard._card) then
                targetCard = nil
            end
        end
        
        local dragToCard, dragType = battleUi:getEventDragTo()
        if (dragType == BattleEventDialog.Type.guide_drag_to_card and dragToCard ~= nil and dragToCard ~= targetCard)
            or ((dragType == BattleEventDialog.Type.guide_drag_to_pos or dragType == BattleEventDialog.Type.guide_drag_to_attack or dragType == BattleEventDialog.Type.guide_drag_to_defend) and dragToCard ~= targetCard) then
            targetCard = nil
        end
           
        pCard._targetCard = targetCard     
        self._arrow:directTo(touch:getLocation(), targetCard)
    end

    maskLayer.onTouchEnded = function(self, touch)
        battleUi:hideSelectTarget(self)

        local targetCard = pCard._targetCard

        if card:isMonster() then
            if targetCard and player:canEvolveCard(card, targetCard._card) then
                playerUi:sendEvent(playerUi.EventType.send_use_card, {_type = BattleData.UseCardType.h2b, _ids = {card._id, targetCard._card._id}})
            else
                battleUi._playerUi:sendEvent(PlayerUi.EventType.dialog_card_need_target, 0)
            end
        elseif card._type == Data.CardType.magic then
            if targetCard and player:canEquipCard(card, targetCard._card) then
                playerUi:sendEvent(playerUi.EventType.send_use_card, {_type = BattleData.UseCardType.spell, _ids = {card._id, card._skills[1]._id, targetCard._card._id}})
            else
                battleUi._playerUi:sendEvent(PlayerUi.EventType.dialog_card_need_target, 0)
            end
        end
    end

    maskLayer.onTouchCanceled = function (self)
        battleUi:hideSelectTarget(self)
    end

    pCard:setPosition(pCard._default._position)
    pCard:hideLargePic()
    pCard:onTouchEnded(touch)

    --[[
    local skillItem = V.createBattleSkillItem(self._player, skill, cc.p(0, 0))
    skillItem:setScale(0.8)
    lc.addChildToPos(maskLayer, skillItem, cc.p(pCard._default._position.x >= lc.w(self) / 2 and (lc.sw(skillItem) / 2 + 20) or (lc.w(maskLayer) - lc.sw(skillItem) / 2 - 20), lc.sh(skillItem) / 2 + 20), 1)

    local bones = self._playerUi:efcDragonBones2("xuanzhong", "effect5", 2.0, false)
    lc.addChildToCenter(skillItem, bones, -1)

    local skillInfo = Data._skillInfo[skill._id]
    local title = V.createTTF(Str(STR.SELECT_TARGET_TITLE_01 + skillInfo._targetType - 1), V.FontSize.M2)
    title:runAction(lc.rep(lc.sequence(lc.scaleTo(1.5, 1.05), lc.scaleTo(1.5, 1.0))))
    lc.addChildToPos(maskLayer, title, cc.p(lc.x(skillItem), lc.top(skillItem) + lc.h(title) / 2 + 10))
    ]]

    local arrow = BattleLine.create(pCard:getParent():convertToWorldSpace3D(cc.p(pCard:getPosition()), ClientData._camera3D))
    maskLayer._arrow = arrow
    maskLayer:addChild(arrow)
    arrow:directTo(touch:getLocation(), nil)
end

function _M:hideSelectTarget(maskLayer)
    local pCard = maskLayer._pCard
    self._playerUi:playAction(pCard, PlayerUi.Action.replace_hand_card, 0, 1)
    maskLayer:removeFromParent() 

    self._selectTargetLayer = nil
end

