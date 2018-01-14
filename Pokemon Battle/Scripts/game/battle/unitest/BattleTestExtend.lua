---------------------------
--CardSprite
---------------------------
function CardSprite:fastToBoard(delay)
    local playerUi = self._ownerUi
    local battleUi = playerUi._battleUi

    -- reset 
    self:updateActive(false)

    if playerUi._isController and self._status ~= CardSprite.Status.normal then
        self:initNormal()
    elseif (not playerUi._isController) and self._status ~= CardSprite.Status.back then
        self:initBack()
    end

    if self._card._sourceStatus == BattleData.CardStatus.pile then
        self:setPosition(cc.p(V.SCR_CW, V.SCR_CH))
    elseif self._card._sourceStatus == BattleData.CardStatus.hand then
        playerUi:replaceHandCards(0, self._card)
    end

    -- action with no delay
    self:runAction(lc.sequence(
        lc.call(function () self:updateZOrder(true) end),
        -- using
        lc.call(function () 
            -- audio
            battleUi._audioEngine:playEffect("e_card_using")
            battleUi._audioEngine:playHeroAudio(self._card._infoId, false)

            if self._status ~= CardSprite.Status.normal then
                self:initNormal()
            end
        end),
        -- to board: init fight
        lc.ease(lc.spawn(lc.moveTo(0, self._default._position)), "O", 0.4),
        lc.call(function () 
            -- audio
            battleUi._audioEngine:playEffect("e_card_board")

            self:initFight()
            self:updateZOrder()

            playerUi:updateBoardCardsActive()
        end)
    ))

    return delay
end

function CardSprite:fastToHand(delay, isShowOppo)
    local playerUi = self._ownerUi
    local opponentUi = playerUi._opponentUi
    local battleUi = playerUi._battleUi
    
    -- reset
    self:updateActive(false)

    for index, pCard in ipairs(playerUi._pHandCards) do
        if pCard and  pCard._card ~= card then
            playerUi:calHandCardPosAndRot(pCard)
            
            if pCard._status ~= CardSprite.Status.large and pCard._status ~= CardSprite.Status.info then
                local curPos, destPos = cc.p(pCard:getPosition()), pCard._default._position
                if curPos.x ~= destPos.x or curPos.y ~= destPos.y then
                    pCard:stopAllActions()
                    local pos, rot = pCard._default._position, pCard._default._rotation
        
                    if cc.p(pCard:getPosition()).x == pos.x and cc.p(pCard:getPosition()).y == pos.y and pCard:getRotation() == rot and pCard:getScale() == 1 then 
                        -- do nothing
                    else
                        pCard:runAction(lc.sequence(
                            lc.call(function() pCard:updateZOrder() end), 
                            cc.EaseOut:create(lc.spawn(lc.moveTo(0, pos)), 2.5)
                            ))
                    end
                end
            end
        end
    end

    if isShowOppo then
        self:initNormal()
    elseif playerUi._isController and self._status ~= CardSprite.Status.normal then
        self:initNormal()
    elseif (not playerUi._isController) and self._status ~= CardSprite.Status.back then
        self:initBack()
    end

    return delay
end


---------------------------
--StatusUi
---------------------------

function PlayerUi:addCardToPileFast(card)
    local cardSprite = self:getCardSprite(card)
    
    --self:removeCardFromSprites(cardSprite)
    self:sendEvent(PlayerUi.EventType.update_card_pile_count)

    cardSprite:fastToPile(0)
end

function PlayerUi:addCardToHandFast(card)
    local cardSprite = self:getCardSprite(card) or self._opponentUi:getCardSprite(card)
    self._pHandCards[card._pos] = cardSprite
    self:calHandCardPosAndRot(cardSprite)
    
    cardSprite:fastToHand(0, true)
end

function PlayerUi:addCardToBoardFast(card)
    -- only monster or rare
    local cardSprite = self:getCardSprite(card)
    
    if card:isMonster() then
        self._pBoardCards[card._pos] = cardSprite
        self:calBoardCardPos(cardSprite)
    end

    cardSprite:fastToBoard(0)
end

function PlayerUi:swapCardsInGrave(card1, card2, swapTarget)
    -- swap pos
    local pos = card1._pos
    card1._pos = card2._pos
    card2._pos = pos

    if swapTarget == BattleTestListDialog.SwapTarget.player then
        self._player._graveCards[card1._pos] = card1
        self._player._graveCards[card2._pos] = card2

    elseif swapTarget == BattleTestListDialog.SwapTarget.opponent then
        self._opponent._graveCards[card1._pos] = card1
        self._opponent._graveCards[card2._pos] = card2
    end

    -- get card sprite
    local cardSprite1 = self:getCardSprite(card1)
    local cardSprite2 = self:getCardSprite(card2)
    for i = 1, #self._pGraveCards do
        if cardSprite1 == self._pGraveCards[i] then
            self._pGraveCards[i] = cardSprite2
        elseif cardSprite2 == self._pGraveCards[i] then
            self._pGraveCards[i] = cardSprite1
        end
    end

    self:updateGraveArea()
    
end

function PlayerUi:swapCardsInPile(card1, card2, swapTarget)
    -- swap pos
    local pos = card1._pos
    card1._pos = card2._pos
    card2._pos = pos

    if swapTarget == BattleTestListDialog.SwapTarget.player then
        self._player._pileCards[card1._pos] = card1
        self._player._pileCards[card2._pos] = card2

    elseif swapTarget == BattleTestListDialog.SwapTarget.opponent then
        self._opponent._pileCards[card1._pos] = card1
        self._opponent._pileCards[card2._pos] = card2
    end

    -- not sure: no piles in pile
    self._battleUi:updatePile(self)
end

function PlayerUi:swapCardsInHand(card1, card2, swapTarget)
    -- swap pos
    local pos = card1._pos
    card1._pos = card2._pos
    card2._pos = pos

    if swapTarget == BattleTestListDialog.SwapTarget.player then
        self._player._handCards[card1._pos] = card1
        self._player._handCards[card2._pos] = card2

    elseif swapTarget == BattleTestListDialog.SwapTarget.opponent then
        self._opponent._handCards[card1._pos] = card1
        self._opponent._handCards[card2._pos] = card2
    end

    -- get card sprite
    local cardSprite1 = self:getCardSprite(card1)
    local cardSprite2 = self:getCardSprite(card2)
    for i = 1, #self._pHandCards do
        if cardSprite1 == self._pHandCards[i] then
            self._pHandCards[i] = cardSprite2
        elseif cardSprite2 == self._pHandCards[i] then
            self._pHandCards[i] = cardSprite1
        end
    end
    self:replaceHandCards(0)
end

---------------------------
--PlayerUi
---------------------------

function PlayerUi:setFortressHp(val)
    val = (val or self._player._fortress._hp)
    
    if self._player._fortressHp == 0 then
        self._pHpLabel:setString('???')
    else        
        self._pHpLabel:setString(val)
    end
end

---------------------------
--BattleUi
---------------------------
