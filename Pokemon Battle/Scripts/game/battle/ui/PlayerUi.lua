local _M = class("PlayerUi")
PlayerUi = _M

_M.GRAVE_WIDTH = 54
_M.GRAVE_COUNT = 3

local BOARD_AX = V.SCR_CW - 134 + 2
local BOARD_DX = V.SCR_CW + 138 - 2
local BOARD_AY = V.SCR_CH - 170
local BOARD_DY = V.SCR_CH + 180
local BOARD_S = 142
local BOARD_S2 = 184

_M.Pos = 
{
    boss = cc.p(V.SCR_CW, V.SCR_CH + 180),
    attacker_fortress = cc.p(V.SCR_CW, V.SCR_CH - 250),
    defender_fortress = cc.p(V.SCR_CW, V.SCR_CH + 250),
    attacker_pile = cc.p(V.SCR_CW + 498, V.SCR_CH - 210),
    defender_pile = cc.p(V.SCR_CW - 498, V.SCR_CH + 220),
    attacker_grave = cc.p(V.SCR_CW + 492, V.SCR_CH - 75),
    defender_grave = cc.p(V.SCR_CW - 492, V.SCR_CH + 84),
    attacker_gems = {cc.p(V.SCR_CW - 458, V.SCR_CH - 86), cc.p(V.SCR_CW - 458, V.SCR_CH - 150), cc.p (V.SCR_CW - 458, V.SCR_CH - 218)},
    defender_gems = {cc.p(V.SCR_CW - 458, V.SCR_CH + 86), cc.p(V.SCR_CW - 458, V.SCR_CH + 154), cc.p (V.SCR_CW - 458, V.SCR_CH + 218)},
    attacker_hand_y = V.SCR_CH - 370,
    defender_hand_y = V.SCR_CH + 400,
    attacker_board_y = {BOARD_AY + 50, BOARD_AY, BOARD_AY, BOARD_AY, BOARD_AY, BOARD_AY},
    defender_board_y = {BOARD_DY - 50, BOARD_DY, BOARD_DY, BOARD_DY, BOARD_DY, BOARD_DY},
    attacker_board_x = {BOARD_AX - 2, BOARD_AX - BOARD_S2 - BOARD_S, BOARD_AX - BOARD_S2, BOARD_AX + BOARD_S2, BOARD_AX + BOARD_S2 + BOARD_S, BOARD_AX + BOARD_S2 + 2 * BOARD_S, BOARD_AX + BOARD_S2 + 3 * BOARD_S},
    defender_board_x = {BOARD_DX + 2, BOARD_DX + BOARD_S2 + BOARD_S, BOARD_DX + BOARD_S2, BOARD_DX - BOARD_S2, BOARD_DX - BOARD_S2 - BOARD_S, BOARD_DX - BOARD_S2 - 2 * BOARD_S, BOARD_DX - BOARD_S2 - 3 * BOARD_S},
    attacker_power = cc.p(V.SCR_CW - 462, V.SCR_CH - 42),
    defender_power = cc.p(V.SCR_CW + 466, V.SCR_CH + 46),
    attacker_coin = cc.p(V.SCR_CW + 334, V.SCR_CH - 35),
    defender_coin = cc.p(V.SCR_CW - 332, V.SCR_CH + 34),

    use_area = 210,
    attack_fortress_area = 500,
    defend_fortress_area = 200,
    attacker_area = V.SCR_CH + 70,
}

_M.Action =
{
    -- base move action
    replace_hand_card = 31,
    replace_board_card = 32,
    
    -- narmol action
    attack_fortress = 211,
    attack_card = 213,
    
    fortress_hurt = 221,
    card_hurt = 222,
    fortress_die = 224,
    
    fortress_hp_update = 311,
    fortress_atk_update = 312,
    hp_update = 313,
    atk_update = 314,
    
    fortress_hp_inc = 321,
    fortress_hp_dec = 322,
    fortress_atk_inc = 323,
    fortress_atk_dec = 324,
    hp_inc = 325,
    hp_dec = 326,
    atk_inc = 327,
    atk_dec = 328,

    update_positive_status = 331,
    update_negative_status = 332,
    update_bind = 333,
    
    avoid_attack = 341,

    change_nature = 351,
}

_M.EventType = 
{
    -- show dialog
    dialog_defender_hand_cards = 1,
    dialog_not_enough_gem = 2,
    dialog_board_card_full = 3,
    dialog_not_your_round = 4,
    dialog_card_need_aim = 5,
    dialog_card_need_target = 6,
    dialog_special_summon_invalid = 7,
    dialog_cannot_effect = 8,
    dialog_adding_board_card = 9,
    dialog_trap_existed = 10,
    dialog_target_unattackable = 11,
    dialog_cannot_attack = 12,
    dialog_attacker_hand_cards = 14,
    
    -- effect
    efc_screen_to_board = 101,
    efc_screen_equip_book = 102,
    efc_screen_attack_card = 103,
    efc_screen_fortress_die = 104,
    efc_screen_fortress_hurt = 105,
    
    -- camera
    efc_camera_to = 201,
    
    -- ui change
    update_card_pile_count = 301,

    -- network
    send_use_card = 401,
}

_M.EVENT                = "PLAYER_UI_EVENT"

-- Reference to battle scene
function _M:ctor(battleUi, player, sceneType, cardBackId)
    self._scene = ClientData._battleScene
    self._battleUi = battleUi
    self._audioEngine = battleUi._audioEngine

    self._player = player
    self._isAttacker = player._isAttacker
    self._isController = self._isAttacker == self._battleUi._isAttacker
    self._sceneType = sceneType

    self._cardBackId = cardBackId

    self._hideHandCards = not self._isController
    if self._battleUi._isObserver then
        self._hideHandCards = true
    end

    self._handPos = self._isAttacker and _M.Pos.attacker_hand_y or _M.Pos.defender_hand_y
    if self._isAttacker then
        self._handPos = self._handPos - (1 - self._battleUi._scale) * 320
    end

    --if self._isAttacker then
    if false then
        local dn = cc.DrawNode:create()
        dn:setContentSize(self._scene:getContentSize())
        lc.addChildToCenter(self._battleUi, dn)
        for i = 1, 22 do
            dn:drawRect(cc.p((i - 1) * 64, 0), cc.p((i - 1) * 64, 768), cc.c4f(1, 1, 1, 0.2))
        end
        for j = 1, 12 do
            dn:drawRect(cc.p(0, (j - 1) * 64), cc.p(1366, (j - 1) * 64), cc.c4f(1, 1, 1, 0.2))
        end
    end

    self:initUIControl()
end

function _M:initUIControl()
    local uiLayer = self._battleUi._layer

    -- HP and ATK
    local avatarFrame = lc.createSprite('bat_avatar_bg_01')
    local node = lc.createNode(avatarFrame:getContentSize(), self._isController and cc.p(38, 38) or cc.p(V.SCR_W - 38, V.SCR_H - 12), self._isController and cc.p(0, 0) or cc.p(1, 1))
    node._battleUi = self._battleUi
    node._statusEfc = {}
    uiLayer:addChild(node)
    self._avatarFrame = node

    --avatarFrame:setFlippedX(not self._isController)
    --avatarFrame:setFlippedY(not self._isController)
    lc.addChildToCenter(node, avatarFrame)
    node._frame1 = avatarFrame

    if self._player._level >= 0 then
        --[[
        local avatarFrame2 = lc.createSprite('bat_avatar_bg_02')
        lc.addChildToPos(node, avatarFrame2, self._isController and cc.p(112, 18) or cc.p(lc.w(node) - 112, lc.h(node) - 18), 2)
        node._frame2 = avatarFrame2

        self._pLevelLabel = V.createBMFont(V.BMFont.huali_26, self._player._level)
        lc.addChildToPos(avatarFrame2, self._pLevelLabel, cc.p(lc.cw(avatarFrame2), lc.ch(avatarFrame2) + 2))
        ]]
    end

    if self._player._crown ~= nil then
        local infoId = self._player._crown._infoId
        local num = self._player._crown._num

        local names = {'jin', 'yin', 'tong', 'jin', 'yin', 'tong'}
        local name = names[infoId - 7200]
        
        if infoId == 7204 and num > 9 then
            name = 'zs'
        end

        local crownBtn = V.createShaderButton(nil, function(sender)
            require("DescForm").create({_infoId = infoId}):show()
        end)
        crownBtn:setContentSize(cc.size(50, 50))
        lc.addChildToPos(node, crownBtn, self._isController and cc.p(-10, 24) or cc.p(lc.w(node) + 10, 24), 2)
        local crown = V.createSpine(infoId - 7200 > 3 and 'jiangbei' or 'huangguan')
        crown:runAction(
            lc.sequence(
                function()
                    crown:setAnimation(0, name, true)
                end
            )
        )
        lc.addChildToCenter(crownBtn, crown)
        node._crown = crownBtn

        if infoId == 7204 and num > 9 then
            if num > 10 then
                local label = cc.Label:createWithBMFont(V.BMFont.num_24, num - 10)
                lc.addChildToPos(crown, label, cc.p(lc.cw(crown) + 1, lc.ch(crown)))
            end
        else
            local label = cc.Label:createWithBMFont(V.BMFont.num_24, num)
            lc.addChildToPos(crown, label, cc.p(lc.cw(crown) - 1, lc.ch(crown)))
        end
    end

    local avatarFrame3 = lc.createSprite('bat_avatar_bg_03')
    lc.addChildToPos(node, avatarFrame3, cc.p(lc.cw(node), -10), 1)
    node._frame3 = avatarFrame3

    if self._player._name then
        local name = cc.Label:createWithTTF(self._player._name, V.TTF_FONT, 20)
        lc.addChildToCenter(avatarFrame3, name)
        node._name = name
    end

    local avatarName = string.format("avatar_%04d", self._player._avatar)
    if lc.FrameCache:getSpriteFrame(avatarName) == nil then avatarName = string.format("avatar_%02d", self._player._avatar) end
    if lc.FrameCache:getSpriteFrame(avatarName) == nil then avatarName = 'avatar_00' end
    
    local battleType = self._battleUi._battleType
    local avatar
    if not self._battleUi._isObserver and (self._battleUi._isOnlinePvp) then
        avatar = V.createShaderButton(nil, function() self._battleUi:showChat(self._isController) end)
        local avatarImg = lc.createSprite(avatarName)
        avatarImg:setScale((lc.w(avatarFrame) - 10) / lc.w(avatarImg))
        lc.addChildToCenter(avatar, avatarImg)
        avatar:setZoomScale(0)
    else
        avatar = lc.createSprite(avatarName)
        avatar:setScale((lc.w(avatarFrame) - 10) / lc.w(avatar))
    end
    lc.addChildToCenter(avatarFrame, avatar, -1)
    node._avatar = avatar

    -- ball
    local icon = lc.createSprite('bat_ball')
    lc.addChildToPos(node, icon, self._isController and cc.p(4, 126) or cc.p(70, -62))

    local label = V.createTTFBold(0, V.FontSize.M2)
    label:enableOutline(lc.Color4B.black, 2)
    lc.addChildToPos(icon, label, cc.p(lc.w(icon) + 6, 14))
    self._ballLabel = label
        
    self._pHpLabel = cc.Label:createWithBMFont(V.BMFont.num_43, 0)
    local labelPos = self._isController and cc.p(90, 104) or cc.p(220, 40)
    self._pHpLabel:setPosition(labelPos)
    self._pHpLabel:setRotation(14)
    self._pHpLabel:setVisible(false)
    avatarFrame3:addChild(self._pHpLabel)
    self._avatarFrame._labelPos = labelPos
        
    self:updateFortressHp()

    if self._player._playerType == BattleData.PlayerType.observe then
    		local hideBtn = V.createShaderButton("bat_btn_2", function(sender) self:hideHandCards(sender) end)
        lc.addChildToPos(uiLayer, hideBtn, cc.p(lc.left(pile) - 40, lc.y(pile)))
        local eyeSpr = lc.createSprite("eye_open")
        lc.addChildToCenter(hideBtn, eyeSpr)
        hideBtn._eyeSpr = eyeSpr
        node._hideBtn = hideBtn
    elseif self._player._opponent._playerType == BattleData.PlayerType.observe then
        local hideBtn = V.createShaderButton("bat_btn_2", function(sender) self:hideHandCards(sender) end)
        lc.addChildToPos(uiLayer, hideBtn, cc.p(lc.right(pile) + 40, lc.y(pile)))
        hideBtn:setVisible(false)
        local eyeSpr = lc.createSprite("eye_close")
        lc.addChildToCenter(hideBtn, eyeSpr)
        hideBtn._eyeSpr = eyeSpr
        node._hideBtn = hideBtn
    end

    -- pile
    local label = V.createTTFBold(0, V.FontSize.M1)
    label:enableOutline(lc.Color4B.black, 2)
    lc.addChildToPos(self._battleUi, label, self._isController and _M.Pos.attacker_pile or _M.Pos.defender_pile, BattleUi.ZOrder.effect)
    self._pPileLabel = label

    --[[
    for i = 1, 4 do
        cardBack = lc.createSprite("card_back")
        cardBack:setScale(scale)
        lc.addChildToPos(pile, cardBack, cc.p(lc.w(pile) / 2 + i * 1, lc.h(pile) / 2 + i * 2))
    end
    ]]
    
    -- grave scroll view
    --local graveBg = lc.createSprite(self._isController and 'bat_grave_atk' or 'bat_grave_def')
    --lc.addChildToPos(self._battleUi, graveBg, self._isController and _M.Pos.attacker_grave or _M.Pos.defender_grave)
    
    --local graveCountBg = lc.createSprite(self._isController and 'bat_grave_count_atk' or 'bat_grave_count_def')
    --lc.addChildToPos(graveBg, graveCountBg, cc.p(lc.w(graveBg) / 2, self._isController and (lc.h(graveBg) + lc.h(graveCountBg) / 2) or (-lc.h(graveCountBg) / 2)))

    -- grave
    local label = V.createTTFBold(0, V.FontSize.M1)
    label:enableOutline(lc.Color4B.black, 2)
    label:setVisible(false)
    lc.addChildToPos(self._battleUi, label, self._isController and _M.Pos.attacker_grave or _M.Pos.defender_grave, BattleUi.ZOrder.effect)
    self._pGraveLabel = label

    -- fortress skill
    self:updateFortressSkill()

    --[[
    -- power
    self._powerLabel = V.createTTFBold(0, V.FontSize.M1, V.COLOR_TEXT_DARK)
    lc.addChildToPos(self._battleUi, self._powerLabel, self._isController and _M.Pos.attacker_power or _M.Pos.defender_power, BattleUi.ZOrder.card + 1)
    ]]

    -- coin
    self._coin = V.createSpine('ryb')
    lc.addChildToPos(self._battleUi, self._coin, self._isController and _M.Pos.attacker_coin or _M.Pos.defender_coin, BattleUi.ZOrder.card + 1)
    self._coin:setAnimation(0, "f0", true)

    -- board lock 
    self._boardLockIcons = {}
    for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
        local icon = lc.createSprite('efc_board_lock')
        local posY = self._isController and _M.Pos.attacker_board_y or _M.Pos.defender_board_y
        local posX = self._isController and _M.Pos.attacker_board_x or _M.Pos.defender_board_x 
        lc.addChildToPos(self._battleUi, icon, cc.p(posX[i], posY[i]))
        icon:setVisible(false)
        self._boardLockIcons[i] = icon
    end
    

end

function _M:hideHandCards(sender)
    self._hideHandCards = not self._hideHandCards
    if self._avatarFrame._hideBtn then
        self._avatarFrame._hideBtn._eyeSpr:setSpriteFrame(not self._hideHandCards and "eye_open" or "eye_close")
    end
    for _,card in ipairs(self._pHandCards) do
        if self._hideHandCards then
            card:initBack()
            card:updateZOrder(false)
        else
            card:initNormal()
--            card:updateZOrder(true)
        end
    end
    
    self:updateHandCardsPos()
end

function _M:updateHandCardsPos()
    for _, card in ipairs(self._pHandCards) do
        local pos, rotation = self:calHandCardPosAndRot(card)
        card:setPosition(pos)
        card:setRotation3D(rotation)
    end
end

function _M:updateBoardCardsPos()
    for _, card in ipairs(self._pBoardCards) do
        local pos = self:calBoardCardPos(card)
        card:setPosition(pos)
        card._default._rotation = {x = 0, y = 0, z = 0}
        card:setScale(1)
        card:setRotation3D(card._default._rotation)
    end
end

-----------------------------------
-- handle touch event
-----------------------------------

function _M:sendEvent(type, val)
    local eventCustom = cc.EventCustom:new(_M.EVENT)
    eventCustom._sender = self
    eventCustom._type = type
    eventCustom._val = val
    lc.Dispatcher:dispatchEvent(eventCustom)
end

-----------------------------------
-- reset functions
-----------------------------------

function _M:createCardSprite(card)
    local cardSprite = CardSprite.create(card, self)
    cardSprite._ownerUi = self
    cardSprite:retain()
    
    if self._cardSprites[card._id] ~= nil then 
        self:removeCardSprite(self._cardSprites[card._id]) 
    end
    self._cardSprites[card._id] = cardSprite

    if card._status == BattleData.CardStatus.board then
        if card:isMonster() then
            -- status
            cardSprite:initFight()
        end
        
    elseif card._status == BattleData.CardStatus.grave and card._sourceStatus ~= BattleData.CardStatus.pile then
        self:addGraveCard(cardSprite)

    end
    
    return cardSprite
end

function _M:createMaskCardSprite(card)
    if card == nil then return nil end

    local cardSprite = CardSprite.create(card, self)
    cardSprite._ownerUi = self
    cardSprite:retain()
    
    cardSprite:initFight()

    cardSprite._isMask = true

    return cardSprite
end

function _M:removeCardSprite(cardSprite)
    if cardSprite == nil then return end
    
    if cardSprite:getParent() ~= nil then
        cardSprite:removeFromParent()
    end
    cardSprite:release()
end

function _M:hideCardSprite(cardSprite)
    if cardSprite == nil then return end
    cardSprite:setVisible(false)
end

function _M:resetCardSprites()
    if self._cardSprites == nil then
        self._cardSprites = {}
        return
    end
    
    for _, cardSprite in pairs(self._cardSprites) do
        self:removeCardSprite(cardSprite)
    end
    
    self._cardSprites = {}
end

function _M:resetCard(cardSprite)
    cardSprite._pHorse = nil
    cardSprite._pHero = nil
end

function _M:resetWhenBattleStart()
    self._actionDelay = 0
    
    self._pPileCards = {}
    self._pHandCards = {}
    self._pBoardCards = {}
    self._pGraveCards = {}

    self:resetCardSprites()
    self:updateFortressSkill()
    self:updatePower()
    self:updateBall()

    -- pile cards 
    for i = 1, #self._player._pileCards do
        local card = self._player._pileCards[i]
        local cardSprite = self:createCardSprite(card)
        
        self._pPileCards[card._pos] = cardSprite
        self._battleUi:addChild(cardSprite)
	end

end

function _M:resetWhenRoundBegin()
end

function _M:resetWhenInitialDeal()
    -- grave cards
    for i = 1, #self._pGraveCards do
        local pGraveCard = self._pGraveCards[i]
        if pGraveCard ~= nil then
            pGraveCard:removeFromParent()
        end
    end
    self._pGraveCards = {}

	for i = 1, #self._player._graveCards do
	   local card = self._player._graveCards[i]
       if card ~= nil then
	      local cardSprite = self:getCardSprite(card)
	      self._pGraveCards[i] = cardSprite
       end
	end

    -- fortress
    self:updateFortressHp()
    local color = self:getLabelColor(self._player._fortress._hp, self._player._fortress._maxHp)
    self._pHpLabel:setColor(color)

    -- ui
    self:updateGraveArea()
end

-----------------------------------
-- battle start and finish
-----------------------------------

function _M:start()
    
end

function _M:finish(delay)
    local resultType = self._player:getResult()
    if resultType == Data.BattleResult.lose then
        delay = self:playAction(nil, _M.Action.fortress_die, delay)
    elseif resultType == Data.BattleResult.win then
        delay = self._opponentUi:playAction(nil, _M.Action.fortress_die, delay)
    end
    
    return delay
end

function _M:forward()
	self._battleUi:stopAllActions()

    -- pile cards 
    for i = 1, #self._player._pileCards do
        local card = self._player._pileCards[i]
        local cardSprite = self:createCardSprite(card)
        
        self._pPileCards[card._pos] = cardSprite
        self._battleUi:addChild(cardSprite)
	end

    -- hand cards
	for i = 1, #self._player._handCards do
        local card = self._player._handCards[i]
        local cardSprite = self:createCardSprite(card)
        
        self._pHandCards[card._pos] = cardSprite
        self._battleUi:addChild(cardSprite)
	end
    self:doReorderHand()
	
	-- board cards
	for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
        local card = self._player._boardCards[i]
        if card ~= nil then
            local cardSprite = self:createCardSprite(card)
           
            self._pBoardCards[card._pos] = cardSprite
            self._battleUi:addChild(cardSprite)
            cardSprite:updateZOrder()
        end
	end
	self:doReorderBoard()
    self._opponentUi:doReorderBoard()
	
	-- grave cards
	for i = 1, #self._player._graveCards do
	   local card = self._player._graveCards[i]
	   local cardSprite = self:createCardSprite(card)
	   self._battleUi:addChild(cardSprite)
	   self._pGraveCards[i] = cardSprite
	end

    -- fortress
	self:updateFortressHp()
    local color = self:getLabelColor(self._player._fortress._hp, self._player._fortress._maxHp)
    self._pHpLabel:setColor(color)
    self:updateFortressSkill()
    
    -- gem
    if self._player == self._player:getActionPlayer() then
        self:updatePower()
        self:updateBall()
    end
    
    -- pile count
    self:sendEvent(_M.EventType.update_card_pile_count)
    
    --zorder
    self._battleUi:updateCardZOrder()

    self:updateGraveArea()
    
    self:updateBoardCardsActive()
end

function _M:roundBegin()
    self:resetWhenRoundBegin()
    
    --self:updatePower()
    self:updateFortressHp()
end

function _M:roundEnd(delay)
    --self:updatePower()
    
    return delay
end

function _M:action()
    --self:updatePower()
end

------------------------------------
-- helper

function _M:getCardSprite(card)
    if card == nil then
        return nil 
    end
    
    return self._cardSprites[card._id]
end

function _M:getPileCardSprite(card)
    for i = 1, #self._pPileCards do
        local cardSprite = self._pPileCards[i]
        if cardSprite ~= nil and cardSprite._card == card then
            return cardSprite, i
        end 
    end
    
    return nil, 0
end

function _M:getHandCardSprite(card)
    for i = 1, Data.MAX_CARD_COUNT_IN_HAND do
        local cardSprite = self._pHandCards[i]
        if cardSprite ~= nil and cardSprite._card == card then
            return cardSprite, i
        end 
    end
    
    return nil, 0
end

function _M:getBoardCardSprite(card)
    for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
        local cardSprite = self._pBoardCards[i]
        if cardSprite ~= nil and cardSprite._card == card then
            return cardSprite, i
        end 
    end
    
    return nil, 0
end

function _M:getGraveCardSprite(card)
    for i = 1, #self._pGraveCards do
        local cardSprite = self._pGraveCards[i]
        if cardSprite and cardSprite._card == card then
            return cardSprite, i
        end
    end
    
    return nil, 0
end

function _M:getHandCardSpriteByInfoId(infoId)
    for i = 1, Data.MAX_CARD_COUNT_IN_HAND do
        local cardSprite = self._pHandCards[i]
        if cardSprite ~= nil and cardSprite._card._infoId == infoId then
            return cardSprite
        end
    end
    
    return nil
end

function _M:getBoardCardSpriteByInfoId(infoId)
    for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
        local cardSprite = self._pBoardCards[i]
        if cardSprite ~= nil and cardSprite._card._infoId == infoId then
            return cardSprite
        end
    end
    
    return nil
end

function _M:getIsEndAllOperation()
    return false
end

function _M:getIsMoreOperation()
    -- adding board card
    if self._battleUi._isAddingBoardCard then
        return false
    end
    
    if self._player:canUseHandCard() then return true end

    local cards = self._player:getBattleCards('B')
    for i = 1, #cards do
        local card = cards[i]
        if card:canAction() then return true end
    end

    return false
end

function _M:getIsShowHandCardActive()
    -- is operating
    if not self._battleUi._isOperating then
        return false
    end
    
    -- adding board card
    if self._battleUi._isAddingBoardCard then
        return false
    end
    
    return self._player:canUseHandCard()
end

function _M:calHandCardPosAndRot(pCard)
    local count = #self._pHandCards
    
    local index = 0
    for i = 1, Data.MAX_CARD_COUNT_IN_HAND do
        local handCardSprite = self._pHandCards[i]
        if handCardSprite ~= nil and handCardSprite._card._id == pCard._card._id then
            index = i
            break
        end
    end
    
    ----------------- card pos ---------------------
    local margin = 292 - (1 - self._battleUi._scale) * 500
    local leftMargin, rightMargin, minGap = margin, margin, -4
    local maxWidth = V.SCR_W - leftMargin - rightMargin
    local cardWidth = V.CARD_SIZE.width * CardSprite.Scale.normal
    local cardHeight = V.CARD_SIZE.height * CardSprite.Scale.normal
    local gap = (maxWidth - (count * cardWidth)) / (count + 1)

    local posX = leftMargin + cardWidth / 2 + gap
    local posY = self._isController and _M.Pos.attacker_hand_y or _M.Pos.defender_hand_y
    if self._isController then
        posY = posY - (1 - self._battleUi._scale) * 320
    end

    local maxY = (V.SCR_H - cardHeight * self._battleUi._scale) / math.cos(V.BATTLE_ROTATION_X * math.pi / 360) / self._battleUi._scale

    if self._battleUi._isObserver or self._battleUi._battleType == Data.BattleType.replay then
        if not self._isController and not self._battleUi._isReverse then
--            posY = math.min(lc.ch(self._battleUi) + 290 + cardHeight / 2, maxY)
--            posY = lc.ch(self._battleUi) + 290 + cardHeight / 2
        elseif not self._isController and self._battleUi._isReverse then
            posY = V.SCR_H - 13
            
        elseif self._isController and not self._battleUi._isReverse then
            posY = 13
        elseif self._isController and self._battleUi._isReverse then
--            posY = math.max(lc.ch(self._battleUi) - 290 - cardHeight / 2, V.SCR_H - maxY)
            posY = lc.ch(self._battleUi) - 328 - cardHeight / 2
        end
    end

    if gap > minGap then
        posX = posX + ((gap - minGap) * (count - 1)) / 2
        gap = minGap
    else
        posX = posX - gap
        gap = gap * (count + 1) / (count - 1)
    end

    ------------------------------------------------
    --pCard._default._position = cc.p(512 + radius * math.sin(math.rad(angle)), posY - radius * dir * (1 - math.cos(math.rad(angle))))
    

    pCard._default._position = cc.p(posX + (index - 1) * (cardWidth + gap), posY)
    --pCard._default._rotation = angle * dir
    --pCard._default._rotation = 0
    pCard._default._rotation = {x = self._battleUi._battleType == Data.BattleType.layout and 0 or (self._battleUi._isReverse and -V.BATTLE_ROTATION_X or V.BATTLE_ROTATION_X), y = 0, z = 0}
    
    return pCard._default._position, pCard._default._rotation
end

function _M:calBoardCardCount()
    local count = Data.MAX_CARD_COUNT_ON_BOARD
    for i = Data.MAX_CARD_COUNT_ON_BOARD, 1, -1 do
        if self._pBoardCards[i] == nil then
            count = count - 1 
        else
            break
        end
    end

    return count
end

function _M:calBoardCardStep()
    local count = self:calBoardCardCount()
    if count == 1 then return 76
    else return 180 + (5 - count) * 20
    end
end

function _M:calBoardCardPos(pCard)
    local index = 0
    for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
        local boardCardSprite = self._pBoardCards[i]
        if boardCardSprite and boardCardSprite._card._id == pCard._card._id then
            index = i
            break
        end
    end
    
    local posY = self._isController and _M.Pos.attacker_board_y or _M.Pos.defender_board_y
    local posX = self._isController and _M.Pos.attacker_board_x or _M.Pos.defender_board_x
    pCard._default._position = cc.p(posX[index], posY[index])
    --pCard._default._rotation = 0
    
    return pCard._default._position
end

function _M:calLengthAndAngle(startPos, endPos)
    local len = math.sqrt((startPos.x - endPos.x) * (startPos.x - endPos.x) + (startPos.y - endPos.y) * (startPos.y - endPos.y))
    if len == 0 then
        return 0, 0
    end
    
    local rot = math.deg(math.asin((endPos.y - startPos.y) / len))
    if endPos.x < startPos.x then
        if endPos.y >= startPos.y then
            rot = 180 - rot
        else
            rot = -180 - rot
        end
    end
    
    return len, rot
end

function _M:updateFortressHp(val)
    val = (val or self._player._fortress._hp)
    
    if self._player._fortressHp == 0 then
        self._pHpLabel:setString('???')
    else
        V.updateValueLabel(self._pHpLabel, val, nil, 1.4)
        
        --self._pHpLabel:setString(val)
    end
end

function _M:updateFortressAtk(val)
    val = val ~= nil and val or self._player._fortress._atk
    
    self._pAtkLabel:setString(val)
end

function _M:updateFortressSkill()
    --[[
    if self._player._fortressSkill then
        if self._fortressSkillLabel == nil then
            local skillBottomSize = lc.frameSize("bat_scene_round_bottom")
            local skillBottom = ccui.Scale9Sprite:createWithSpriteFrameName("bat_scene_round_bottom", cc.rect(0, skillBottomSize.width / 2 - 1, skillBottomSize.width, 1))
            skillBottom:setContentSize(skillBottomSize.width, lc.makeEven(skillBottomSize.height * 2.6))
            local pos = self._isController and _M.Pos.attacker_gems[1] or _M.Pos.defender_gems[3]
            skillBottom:setPosition(pos.x - 56, pos.y - (self._isController and 40 or 30))
            self._battleUi:addChild(skillBottom, BattleUi.ZOrder.ui)

            local widget = ccui.Layout:create()
            widget:setContentSize(skillBottom:getContentSize())
            widget:setTouchEnabled(true)
            skillBottom:addChild(widget)
            widget:addTouchEventListener(function (sender, type) if type == ccui.TouchEventType.ended then self._battleUi:showDialog(BattleDialog.Type.fortress_skill, self) end end)

            local label = V.createTTF('', V.FontSize.S1, V.COLOR_TEXT_DARK, cc.size(24, 0), cc.TEXT_ALIGNMENT_CENTER, cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
            label:setLineHeight(26)
            lc.addChildToPos(skillBottom, label, cc.p(lc.w(skillBottom) / 2, lc.h(skillBottom) / 2 + 4))

            self._fortressSkillLabel = label
        end

        local skillName = Str(Data._skillInfo[self._player._fortressSkill._id]._nameSid)
        self._fortressSkillLabel:setString(skillName)
    else
        if self._fortressSkillLabel then
            self._fortressSkillLabel:getParent():removeFromParent()
            self._fortressSkillLabel = nil
        end
    end
    ]]
end

function _M:updatePower()
    --[[
    if self._powerLabel._value ~= self._player._power then
        self._powerLabel._value = self._player._power
        self._powerLabel:setString(self._player._power)

        local spine = V.createSpine("chxh")
        spine:setAutoRemoveAnimation()
        spine:setCameraMask(ClientData.CAMERA_3D_FLAG)
        local icon = self._powerLabel:getParent()
        lc.addChildToPos(icon, spine, cc.p(lc.x(self._powerLabel) - 6, lc.y(self._powerLabel)))
        spine:setAnimation(0, "animation", false)
    end 
    ]]

end

function _M:updateBall()
    if self._ballLabel._value ~= self._player._ball then
        self._ballLabel._value = self._player._ball
        self._ballLabel:setString(self._player._ball)
        
        local spine = V.createSpine("wjkx")
        spine:setAutoRemoveAnimation()
        local icon = self._ballLabel:getParent()
        lc.addChildToPos(icon, spine, cc.p(lc.cw(icon), lc.ch(icon)), -1)
        spine:setAnimation(0, "animation", false)
    end
end

function _M:updateBoardLocks()
    local values = self._player._fortress:getBuffValue(false, BattleData.NegativeType.boardLock)
    local visible = {}
    if type(values) == 'table' then
        for i = 1, #values do
            local pos = values[i]
            visible[pos] = true
        end
    end

    for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
        if visible[i] then
            if not self._boardLockIcons[i]:isVisible() then
                local bones = self:efcDragonBones2("cdtx", "effect", 1.0, true)
                local x, y = self._boardLockIcons[i]:getPosition()
                lc.addChildToPos(self._battleUi, bones, cc.p(x + 20, y - 20))

                self._boardLockIcons[i]:setOpacity(255)
                self._boardLockIcons[i]:setVisible(true)
            end
        else
            if self._boardLockIcons[i]:isVisible() then
                self._boardLockIcons[i]:runAction(lc.sequence(lc.fadeOut(0.5), lc.hide()))
            end
        end
    end
end

function _M:updateCardsActive()
    if not self._isController then return end
    
    if self:getIsShowHandCardActive() then
        local player = self._player
        
        for _, pCard in ipairs(self._pHandCards) do
            local card = pCard._card
            if card:isMonster() then
                pCard:updateActive(player:canUseMonster(card, false))
            elseif card._type == Data.CardType.magic then
                pCard:updateActive(player:canUseMagic(card, false))
            elseif card._type == Data.CardType.trap then
                pCard:updateActive(player:canUseTrap(card, false))
            else
                pCard:updateActive(true)
            end
        end
    else
        for _, pCard in ipairs(self._pHandCards) do
            pCard:updateActive(false)
        end
    end
end

function _M:updateBoardCardsActive()
    for _, pCard in pairs(self._pBoardCards) do
        pCard:updateBoardActive()
    end
end

function _M:updateFortressActive(isActive)
    if isActive then
        if self._boardGlow == nil then
            local layer = lc.createNode()
            lc.addChildToCenter(self._avatarFrame, layer, -1)
            
            self._battleUi:createDragonBones("gjxz", cc.p(100, 60), layer, "effect", false, 1.0)
            --[[
            self._battleUi:createDragonBones("xuanzhong", cc.p(5, 8), layer, gemEnough and "effect2" or "effect4", false, 2.0)
            for i = -1, 1, 2 do
                self:efcParticle("par_kpxz_x", cc.p(0, (self._pFrame:getContentSize().height / 2 - 15)* i), false, true, layer)
                self:efcParticle("par_kpxz_y", cc.p((self._pFrame:getContentSize().width / 2 - 15) * i, 0), false, true, layer)
            end
            ]]
            self._boardGlow = layer

            local action = lc.rep(lc.sequence(cc.ScaleTo:create(0.4, 1.03),
                cc.ScaleTo:create(0.4, 1.0)))
            action:setTag(0xff)
            self._avatarFrame:runAction(action)
        end
    else
        if self._boardGlow ~= nil then
            self._boardGlow:removeFromParent()
            self._boardGlow = nil
                
            self._avatarFrame:stopActionByTag(0xff)
            self._avatarFrame:setScale(1)
        end
    end
end

function _M:getMaskCardSprites()
    local sprites = {}
    for i = 1, Data.MAX_CARD_COUNT_ON_BOARD do
        local pCardSprite = self._pBoardCards[i]
        if pCardSprite ~= nil and pCardSprite._mask then
            table.insert(sprites, pCardSprite._mask)
        end
    end
    return sprites
end

function _M:updateGraveArea()
    local count = #self._pGraveCards

    --self._pGraveLabel:setVisible(count > 0) 
    self._pGraveLabel:setString(count)
    for i = 1, count do
        self._pGraveCards[i]:setVisible(i == count)
    end
end

-----------------------------------
-- choice

function _M:createChoiceMaskLayer(pCard, skill, ids)
    local maskLayer = lc.createMaskLayer(200, lc.Color3B.black, V.SCR_SIZE)
    lc.addChildToPos(self._scene, maskLayer, cc.p(0, 0), BattleScene.ZOrder.form)
    maskLayer._pCard = pCard
    maskLayer._skill = skill
    maskLayer._ids = ids
    maskLayer:addTouchEventListener(function (maskLayer, type) 
        if type == ccui.TouchEventType.ended then
            maskLayer:cancelChoice(sender)
        end 
    end)
    self._battleUi._choiceMaskLayer = maskLayer

    maskLayer.cancelChoice = function(maskLayer)
        local pCard, pTargetCard = maskLayer._pCard, maskLayer._pTargetCard
        pCard:setVisible(true)
        self:playAction(pCard, _M.Action.replace_hand_card, 0, 1)

        maskLayer:endChoice()
    end

    maskLayer.endChoice = function (maskLayer)
        self._battleUi._choiceMaskLayer = nil
        maskLayer:removeFromParent() 
    end

    pCard:setVisible(false)
    self._choiceBtns = {}

    return maskLayer
end

----------
-- Stage 1: summon type: 1. normal; 2. sepcial; 3. specific
-- Stage 2: card selection: a) sacrifice: 1 ~ 31; b) merge: 1 ~ x; c) grave: 1 ~ x 
-- Stage 3: skill selection

-- choice: grave

function _M:showChoiceCards(pCard, cards, count, ids)
    --[[
    --count = math.min(#cards, count)
    local mode, str 
    if pCard._card:hasSkills({4048}) then
        mode = BattleListDialog.Mode.merge
        str = string.format(Str(STR.CHOICE_TITLE_MERGE_COMPONENT), count)
    elseif pCard._card:hasSkills({4095}) then
        mode = BattleListDialog.Mode.exchange
        str = Str(STR.CHOICE_TITLE_EXCHANGE)
    elseif pCard._card:hasSkills({4117}) then
        mode = BattleListDialog.Mode.choice
        str = Str(choiceParam == nil and STR.CHOICE_TITLE_4117_1 or STR.CHOICE_TITLE_4117_2)
    else
    ]]
        mode = BattleListDialog.Mode.choice
        str = string.format(Str(STR.CHOICE_TITLE_CHOICE), count)
    --end
    
    local dialog = BattleListDialog.create(self, cards, mode, str)
    dialog._ids = ids
    dialog:setChoiceFunction(function (sender) return self:checkChoiceCards(sender, pCard, count) end, 
        function (sender) return self:onChoiceCards(sender, pCard) end, 
        function (sender) return self:cancelChoiceCards(sender, pCard) end)
    dialog:show()
end

function _M:onChoiceCards(dialog, pCard)
    local cards = dialog:getSelectedCards()
    
    --[[
    local choice = 0 

    if pCard._card:hasSkills({4048}) then
        for i = 1, #dialog._cardInfos do dialog._cardInfos[i]._tempIndex = i end
        for i = 1, #cards do
            choice = choice + (2 ^ (cards[i]._tempIndex - 1))
        end
        for i = 1, #dialog._cardInfos do dialog._cardInfos[i]._tempIndex = nil end
        
        local rareCard = dialog._choiceParam
        if rareCard then
            local hasChoiceSkill, skill = rareCard:hasChoiceSkill()
            if hasChoiceSkill and B.isSkillChoiceSkill(skill) then
                
            end
        end

    elseif pCard._card:hasSkills({4095}) then
        for i = 1, #cards do
            choice = choice + (2 ^ (cards[i]._pos - 1))
        end

    elseif pCard._card:hasSkills({4091}) and dialog._choiceParam == nil then
        -- select board cards
        for i = 1, #cards do
            choice = choice + (2 ^ (cards[i]._pos - 1))
        end
        local info = Data._skillInfo[4091]
        return self:showChoiceGrave(pCard, pTargetCard, self._player:filterCanChangeToBoardCards(B.filterInCategoryCards(self._player:getBattleCardsByStar('P', info._val[1]), info._refCards[1])), 1, dialog._choiceBase, choice)

    elseif pCard._card:hasSkills({4117}) and dialog._choiceParam == nil then
        -- select first card
        choice = cards[1]._id
        local info = Data._skillInfo[4117]
        return self:showChoiceGrave(pCard, pTargetCard, B.filterAtkEqualCards(self._player:getBattleCards('B', Data.CARD_MAX_LEVEL, cards[1]), cards[1]._atk), 1, dialog._choiceBase, choice)

    elseif pCard._card:hasSkills({4124}) then
        for i = 1, #cards do
            choice = choice + (2 ^ (cards[i]._pos - 1))
        end
 
    else
        if pCard._card:hasSkills({4091, 4117}) and dialog._choiceParam ~= nil then
            -- select pile card
            choice = dialog._choiceParam
        end

        if #cards == 1 and pCard._card:hasSkills({3084, 4022, 4053, 4088, 4091, 4094, 4111, 5037}) then
            local choiceCard = cards[1]
            local hasChoiceSkill, skill = choiceCard:hasChoiceSkill()
            if hasChoiceSkill and B.isSkillChoiceSkill(skill) then
                
            end
        end
    end
    ]]

    local ids = {}
    for i = 1, #dialog._ids do
        ids[#ids + 1] = dialog._ids[i]
    end
    for i = 1, #cards do
        ids[#ids + 1] = cards[i]._id
    end

    self._battleUi:hideCardAttack()
    self:sendEvent(self.EventType.send_use_card, {_type = BattleData.UseCardType.spell, _ids = ids})
end

function _M:cancelChoiceCards(dialog, pCard)
    local card = pCard._card
    if card._type == Data.CardType.magic then
        self:playAction(pCard, _M.Action.replace_hand_card, 0, 1)
    end
end

function _M:checkChoiceCards(dialog, pCard, count)
    local selectedCount = dialog:getSelectedCount()

    if selectedCount ~= count then return false end

    return true

    --[[
    if pCard._card:hasSkills({4095}) then return selectedCount > 0 
    end

    if selectedCount ~= count then return false end

    if pCard._card:hasSkills({4124}) then
        local cards = dialog:getSelectedCards()
        local hCount = 0
        for i = 1, #cards do
            if cards[i]._infoId == Data._skillInfo[4124]._refCards[1] then
                hCount = hCount + 1
            end
        end
        return hCount == 2
    else
        return true
    end
    ]]
end

-- choice: skill

function _M:showChoiceSkill(pCard, ids)
    local card = pCard._card

    local skill = card:getSkillById(ids[2])    
    local info = Data._skillInfo[skill._id]
    if not B.skillHasMode(skill, Data.SkillMode.choice) then
        return self:sendEvent(_M.EventType.send_use_card, {_type = BattleData.UseCardType.spell, _ids = ids})
    end
        
    local maskLayer = self:createChoiceMaskLayer(pCard, skill, ids)

    local title = V.createTTF(Str(STR.CHOICE_TITLE_SKILL), V.FontSize.M1)
    title:runAction(lc.rep(lc.sequence(lc.scaleTo(1.5, 1.05), lc.scaleTo(1.5, 1.0))))
    lc.addChildToPos(maskLayer, title, cc.p(lc.w(maskLayer) / 2, 600))

    for i = 1, 2 do
        local btn = V.createShaderButton(nil, function(sender) self:onChoiceSkill(sender, maskLayer) end)
        btn._index = i - 1
        btn:setContentSize(346, 178)
        self._choiceBtns[#self._choiceBtns + 1] = btn

        local skill = B.createSkill(info._refSkills[i], maskLayer._skill._level, card)
        local skillItem = V.createBattleSkillItem(self._player, skill, cc.p(0, 0))
        skillItem:setTouchEnabled(false)
        skillItem:setCameraMask(1)
        lc.addChildToCenter(btn, skillItem)

        local bones = self:efcDragonBones2("xuanzhong", "effect5", 2.0, false)
        lc.addChildToCenter(skillItem, bones, -1)
    end
    lc.addNodesToCenterH(maskLayer, self._choiceBtns, 200)
end

function _M:onChoiceSkill(choiceBtn, maskLayer)
    local choice = choiceBtn._index

    local pCard, skill, ids = maskLayer._pCard, maskLayer._skill, maskLayer._ids
    pCard:setVisible(true)
    maskLayer:endChoice()

    local newIds = {}
    for i = 1, #ids do
        newIds[#newIds + 1] = ids[i]
    end
    newIds[#newIds + 1] = choice

    self._battleUi:hideCardAttack()
    self:sendEvent(_M.EventType.send_use_card, {_type = BattleData.UseCardType.spell, _ids = newIds})
end

-- choice: initial

function _M:showChoiceInitialMonstersMain(cards)  
    local mode = BattleListDialog.Mode.single_choice
    local str = Str(STR.INITIAL_CHOOSE_MAIN)
    
    local dialog = BattleListDialog.create(self, cards, mode, str)
    dialog._ignoreCancel = true
    dialog:setChoiceFunction(function (sender) return self:checkChoiceInitialMonstersMain(sender, count) end, 
        function (sender) return self:onChoiceInitialMonstersMain(sender, pCard, pTargetCard) end, 
        function (sender) end)
    dialog:show()
end

function _M:onChoiceInitialMonstersMain(dialog)
    local cards = dialog:getSelectedCards()
    self:sendEvent(_M.EventType.send_use_card, {_type = BattleData.UseCardType.init_b1, _ids = {cards[1]._id}})
end

function _M:checkChoiceInitialMonstersMain(dialog)
    local cards = dialog:getSelectedCards()
    return #cards == 1 and cards[1]._info._level == 0
end

-- choice: initial backup

function _M:showChoiceInitialMonstersBackup(cards)  
    local mode = BattleListDialog.Mode.choice
    local str = Str(STR.INITIAL_CHOOSE_BACKUP)
    
    local dialog = BattleListDialog.create(self, cards, mode, str)
    dialog._ignoreCancel = true
    dialog:setChoiceFunction(function (sender) return self:checkChoiceInitialMonstersBackup(sender, count) end, 
        function (sender) return self:onChoiceInitialMonstersBackup(sender, pCard, pTargetCard) end, 
        function (sender) end)
    dialog:show()
end

function _M:onChoiceInitialMonstersBackup(dialog)
    local cards = dialog:getSelectedCards()
    local ids = {}
    for i = 1, #cards do
        ids[#ids + 1] = cards[i]._id
    end
    self:sendEvent(_M.EventType.send_use_card, {_type = BattleData.UseCardType.init_bx, _ids = ids})
end

function _M:checkChoiceInitialMonstersBackup(dialog)
    return true
end

-- choice: swap

function _M:showChoiceSwapMonsters(cards, ignoreCancel)  
    local mode = BattleListDialog.Mode.single_choice
    local str = Str(STR.SWAP_CHOOSE)
    
    local dialog = BattleListDialog.create(self, cards, mode, str)
    dialog._ignoreCancel = ignoreCancel
    dialog:setChoiceFunction(function (sender) return self:checkChoiceSwapMonsters(sender, count) end, 
        function (sender) return self:onChoiceSwapMonsters(sender, pCard) end, 
        function (sender) return self:cancelChoiceSwapMonsters(sender, pCard) end)
    dialog:show()
end

function _M:onChoiceSwapMonsters(dialog)
    local cards = dialog:getSelectedCards()
    self:sendEvent(_M.EventType.send_use_card, {_type = BattleData.UseCardType.swap, _ids = {cards[1]._id}})
end

function _M:checkChoiceSwapMonsters(dialog)
    local cards = dialog:getSelectedCards()
    return #cards == 1
end

function _M:cancelChoiceSwapMonsters(dialog, pCard)
end

-- choice: round end main

function _M:showChoiceSelectMain(cards)  
    local mode = BattleListDialog.Mode.single_choice
    local str = Str(STR.INITIAL_CHOOSE_MAIN)
    
    local dialog = BattleListDialog.create(self, cards, mode, str)
    dialog._ignoreCancel = true
    dialog:setChoiceFunction(function (sender) return self:checkChoiceSelectMain(sender, count) end, 
        function (sender) return self:onChoiceSelectMain(sender, pCard, pTargetCard) end, 
        function (sender) end)
    dialog:show()
end

function _M:onChoiceSelectMain(dialog)
    local cards = dialog:getSelectedCards()
    self:sendEvent(_M.EventType.send_use_card, {_type = BattleData.UseCardType.swap, _ids = {cards[1]._id}})
end

function _M:checkChoiceSelectMain(dialog)
    local cards = dialog:getSelectedCards()
    return #cards == 1
end

-------------------------------------------

function _M:reverse(isReverse)
    local node = self._avatarFrame
    if not isReverse then
        node:setPosition(self._isController and cc.p(0, 0) or cc.p(V.SCR_W, V.SCR_H))
        node:setAnchorPoint(self._isController and cc.p(0, 0) or cc.p(1, 1))
        node._frame1:setFlippedX(not self._isController)
        node._frame1:setFlippedY(not self._isController)
        --node._frame2:setPosition(self._isController and cc.p(112, 18) or cc.p(lc.w(node) - 112, lc.h(node) - 18))
        if node._crown then
            node._crown:setPosition(self._isController and cc.p(112, 48) or cc.p(lc.w(node) - 112, lc.h(node) - 48))
        end
        node._name:setPosition(self._isController and cc.p(210, 30) or cc.p(lc.w(node) - 210, lc.h(node) - 30))
        node._frame3:setSpriteFrame('bat_avatar_bg_03')
        local labelPos = self._isController and cc.p(90, 104) or cc.p(220, 40)
        self._pHpLabel:setPosition(labelPos)
        if self._player._playerType == BattleData.PlayerType.observe then
            node._hideBtn:setPosition(cc.p(40, lc.y(self._btnEndRound)))
            node._hideBtn:setVisible(true)
        elseif self._player._opponent._playerType == BattleData.PlayerType.observe then
            node._hideBtn:setPosition(cc.p(40, lc.y(self._btnEndRound)))
            node._hideBtn:setVisible(false)
        end
    else
        node:setPosition(self._isController and cc.p(V.SCR_W, V.SCR_H) or cc.p(0, 0))
        node:setAnchorPoint(self._isController and cc.p(1, 1) or cc.p(0, 0))
        node._frame1:setFlippedX(self._isController)
        node._frame1:setFlippedY(self._isController)
        --node._frame2:setPosition(self._isController and cc.p(lc.w(node) - 112, lc.h(node) - 18) or cc.p(112, 18))
        if node._crown then
            node._crown:setPosition(self._isController and cc.p(lc.w(node) - 112, lc.h(node) - 48) or cc.p(112, 48))
        end
        node._name:setPosition(self._isController and cc.p(lc.w(node) - 210, lc.h(node) - 30) or cc.p(210, 30))
        node._frame3:setSpriteFrame('bat_avatar_bg_03')
        local labelPos = self._isController and cc.p(220, 40) or cc.p(90, 104)
        self._pHpLabel:setPosition(labelPos)
        if self._player._playerType == BattleData.PlayerType.observe then
            node._hideBtn:setPosition(cc.p(40, lc.y(self._btnEndRound)))
            node._hideBtn:setVisible(false)
        elseif self._player._opponent._playerType == BattleData.PlayerType.observe then
            node._hideBtn:setPosition(cc.p(40, lc.y(self._btnEndRound)))
            node._hideBtn:setVisible(true)
        end
    end
    self._pRareLabel:setScaleY(-self._pRareLabel:getScaleY())
    self._pGraveLabel:setScaleY(-self._pGraveLabel:getScaleY())
end

function _M:clear()
    self._avatarFrame:removeFromParent()
    self._pile:removeFromParent()
    self._pGraveLabel:removeFromParent()
    self._pRareLabel:removeFromParent()
end

return _M