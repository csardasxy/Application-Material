local _M = class("BattleTestUi", function() return cc.Node:create() end)
BattleTestUi = _M

_M.ZOrder = 
{
    -- parent
    normal          = 0,
    action          = 1,
    
    -- battle
    ui              = 0,

    card            = 10,   -- board and hand and action
    card_board      = 20,
    card_hand       = 30,
    card_action     = 40,
    card_touch      = 200,

    effect          = 100,
    label           = 110,
    skill_label     = 120,
}


_M.TouchTarget = {
    player_grave = 1,
    player_hand = 3,
    player_pile = 4,
    opponent_grave = 11,
    opponent_hand = 13,
    opponent_pile = 14,
}

local SCALE = V.SCR_H / 768
_M.POS = {
    BTN_PLAYER_GRAVE = {
        X = V.SCR_CW - 542 * SCALE,
        Y = V.SCR_CH - 59 * SCALE
    },
    BTN_OPPONENT_GRAVE = {
        X = V.SCR_CW - 542 * SCALE,
        Y = V.SCR_CH + 59 * SCALE
    },
    BTN_PLAYER_ADD_HAND_CARD = {
        X = V.SCR_CW + 596 * SCALE,
        Y = V.SCR_CH - 51 * SCALE
    },
    BTN_OPPONENT_ADD_HAND_CARD = {
        X = V.SCR_CW + 596 * SCALE,
        Y = V.SCR_CH + 61 * SCALE
    },
    BTN_PLAYER_EDIT_HAND_CARD = {
        X = V.SCR_CW + 596 * SCALE,
        Y = V.SCR_CH - 120 * SCALE
    },
    BTN_OPPONENT_EDIT_HAND_CARD = {
        X = V.SCR_CW + 596 * SCALE,
        Y = V.SCR_CH + 130 * SCALE
    }
}



-- battle scene: no need for param_input
--function _M.create(scene, nameTag)
function _M.create(scene, nameTag)
    local battleLayoutUI = _M.new()

    battleLayoutUI:init(scene, nameTag)
    -- battle test
    battleLayoutUI:setScale(0.8)

    battleLayoutUI:registerScriptHandler(function(evtName)
       if evtName == "enter" then
            battleLayoutUI:onEnter()
        elseif evtName == "exit" then
            battleLayoutUI:onExit()
        elseif evtName == "cleanup" then
            battleLayoutUI:onCleanup()
        end
    end)
    
    return battleLayoutUI
end

--[[--
init ui, not including events, touch, action etc.
--]]--
function _M:init(scene, nameTag)
    -- battle scene
    self._scene = scene
    -- init the size and anchor of battle ui
    self:setContentSize(V.SCR_SIZE)
    self:setAnchorPoint(cc.p(0.5, 0.5))

    -- offsetY: 21x64: 100, 20x64: 0.96, ... , 16*64: 80
    -- scale: 21x64: 1, 20x64: 0.96, ... , 16*64: 0.8


    local gridWidth = math.min(math.max(16, math.floor(V.SCR_W / 64)), 21)
--    self._scale = (1 - (21 - gridWidth) * 0.04)
    self._scale = 1
    -- battle test
--    self._offsetY = 120 - (21 - gridWidth) * 4
    self._offsetY = 0

    -- battle test start: make battleui center in battle scene
    self:setPosition(cc.p(V.SCR_CW, V.SCR_CH))
--    self:setPosition(cc.p(V.SCR_CW, V.SCR_CH + self._offsetY))
--    self:setScale(self._scale)
--    self:setRotation3D({x = -V.BATTLE_ROTATION_X, y = 0, z = 0})
    -- battle test end

    -- audio
    self._audioEngine = BattleAudio.new(self)

    -- init data and ui
    self._nameTag = nameTag

    self:initData()
    self:initBackground()
    self:initUiControl()

    -- Add player UI: create ui layout
    self._playerUi = PlayerUi.new(self, self._player, self._sceneType, self._input._player._cardBackId)
    self._opponentUi = PlayerUi.new(self, self._opponent, self._sceneType, self._input._opponent._cardBackId)
    self._playerUi._opponentUi = self._opponentUi
    self._opponentUi._opponentUi = self._playerUi

    -- reset the cards, make it clear
    self._playerUi:resetWhenBattleStart()
    self._opponentUi:resetWhenBattleStart()

    self._scene:seenByCamera3D(self)

    return true
end

function _M:onEnter()

        -- init touch event
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(function(touch, event) return self:onTouchBegan(touch, self._isInitCards) end, cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(function(touch, event) return self:onTouchMoved(touch, self._isInitCards) end, cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(function(touch, event) return self:onTouchEnded(touch, self._isInitCards) end, cc.Handler.EVENT_TOUCH_ENDED )
    listener:registerScriptHandler(function(touch, event) return self:onTouchCanceled() end, cc.Handler.EVENT_TOUCH_CANCELLED )
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, self)

    -- load data from battleui first, if not exist then data (first entered), load from config.json
    if BattleTestData._singleFileName ~= nil and BattleTestData._singleFileName ~= "" then
        self:importTestCards(BattleTestData._singleFileName)
    elseif TEST_BATTLE_PARAM ~= '' then
        local filename = lc.File:fullPathForFilename(TEST_BATTLE_PARAM..'.ygo')
        self:importTestCards(filename)
    end

end

function _M:onExit()
    self:getEventDispatcher():removeEventListenersForTarget(self)
end

function _M:onCleanup()
    if self._playerUi ~= nil then self._playerUi:resetCardSprites() end
    if self._opponentUi ~= nil then self._opponentUi:resetCardSprites() end
end



-----------------------------------
-- init
-----------------------------------

function _M:initData()

--    -- battle test
    self._isInitCards = true
    input = {
        _battleType = Data.BattleType.layout,
        _sceneType = Data.BattleSceneType.country_scene_wei,
        _timestamp = math.random(65536),
        _isAttacker = true,
        _player = {
            _name = Str(Data._characterInfo[3]._nameSid),
            _troopCards = {
                _infoId = 10001,
                _num = 3,
            },
            _troopLevels = {},
            _troopSkins = {},
            _level = 1,
            _avatar = 1,
            _fortressHp = 8000,
            _usedCards = {},
        },
        _opponent = {
            _name = Str(Data._characterInfo[2]._nameSid),
            _troopCards = {},
            _troopLevels = {},
            _troopSkins = {},
            _level = 1,
            _avatar = 2,
            _fortressHp = 8000,
            _usedCards = {},
        },
        _levelId = 10102,
    }
    
    self._input = input
    self._battleType = input._battleType
    self._baseBattleType = math.floor(self._battleType / Data.BattleType.base_type)
    self._sceneType = input._sceneType or Data.BattleTestSceneType.stone_scene
    self._timestamp = math.floor(input._timestamp / 1000)

    self._isAttacker = input._isAttacker
	self._needForward = input._needForward
    self._isBattleEndSended = false

    -- battle test : false
    if input._replayBattleType then
        self._replayType = input._replayBattleType
        self._replayBaseType = math.floor(input._replayBattleType / Data.BattleType.base_type)
    end

    -- auto and battleSpeed
    self._timeOutTimes = 0
    self._autoConfig = false

    -- battle test: set battle speed static
    self._battleSpeed = 3

    -- init player and opponent
    local playerInfo = 
    {
        _isClient = true,
        _isAttacker = input._isAttacker,
        _randomSeed = input._randomSeed,
        _usedCards = input._player._usedCards or {},
        _fortressHp = input._player._fortressHp,
        _troopCards = input._player._troopCards,
        _troopLevels = input._player._troopLevels,
        _troopSkins = input._player._troopSkins,
        _events = self._needEvents and input._eventIds or {},
        _conditions = (self._needTask or P._guideID < 100) and {_conditionIds = input._conditionIds or {}, _conditionValues = input._conditionValues or {}} or {},
        _atkLevel = input._isAttacker and input._player._level or input._opponent._level,
        _fortressSkill = input._player._fortressSkill,
        
        _battleType = self._replayType or self._battleType,
        _isNpc = input._player._isNpc,
    }

    local opponentInfo = 
    {
        _isClient = true,
        _isAttacker = not input._isAttacker,
        _randomSeed = input._randomSeed,
        _usedCards = input._opponent._usedCards or {},
        _fortressHp = input._opponent._fortressHp,
        _troopCards = input._opponent._troopCards,
        _troopLevels = input._opponent._troopLevels,
        _troopSkins = input._opponent._troopSkins,
        _events = self._needEvents and input._oppoEventIds or {},
        _conditions = {},
        _atkLevel = input._isAttacker and input._player._level or input._opponent._level,
        _fortressSkill = input._opponent._fortressSkill,
        
        _battleType = self._replayType or self._battleType,
        _isNpc = input._opponent._isNpc,
    }

    -- init player data
    self._player = PlayerBattle.new(playerInfo)
    self._opponent = PlayerBattle.new(opponentInfo)
    self._player._opponent, self._opponent._opponent = self._opponent, self._player
    self:resetBattle()


    if self._nameTag == 'normal' then
        ClientData._reportBattleDebugLog = true
        -- battle test: set player id 001
        ClientData._battleDebugLog = ''
--        ClientData._battleDebugLog = ''..P._id..': '
        for i = 1, #playerInfo._usedCards do
            ClientData.addBattleDebugLog((playerInfo._isAttacker and 'AU' or 'DU')..playerInfo._usedCards[i]..',')
        end
        for i = 1, #opponentInfo._usedCards do
            ClientData.addBattleDebugLog((opponentInfo._isAttacker and 'AU' or 'DU')..opponentInfo._usedCards[i]..',')
        end
        ClientData.addBattleDebugLog('\n\n')
    end

    -- init
    self._player._name, self._opponent._name = input._player._name, input._opponent._name
    self._player._level, self._opponent._level = input._player._level, input._opponent._level
    self._player._vip, self._opponent._vip = input._player._vip, input._opponent._vip
    self._player._avatar, self._opponent._avatar = input._player._avatar, input._opponent._avatar
    self._player._crown, self._opponent._crown = input._player._crown, input._opponent._crown
end

function _M:initBackground()
    -- init bg
    local index = self._sceneType
    if index < 11 or index > 15 then index = 1 end
--    local str = string.format("res/bat_scene/bat_scene_%d_bg.jpg", index)
    local str = "res/bat_scene/bat_scene_11_bg.jpg"
    local skySpr = cc.Sprite:create(str)
    lc.addChildToCenter(self._scene, skySpr, -1)
    self._scene:seenByCamera3D(skySpr)
    self._skySpr = skySpr

    -- bg
    local battleRact = lc.createSpriteWithMask('res/jpg/battle_board_bg.jpg')
    -- battle test
    lc.addChildToCenter(self, battleRact)
    
end

function _M:initUiControl()
    -- layer containing piles, avatars, opbtns
    local layer = cc.Node:create()
    layer:setContentSize(V.SCR_SIZE)
    layer:setAnchorPoint(0.5, 0.5) 
    lc.addChildToCenter(self._scene, layer, BattleScene.ZOrder.ui) 
    self._layer = layer

    --<< Add buttons >>--
    local addButton = function(btnName, iconName, iconStr, titleStr, isExIm)
        local btn = V.createShaderButton(btnName, function(sender) self:onButtonEvent(sender) end)

        local icon
        if iconName then
            icon = lc.createSprite(iconName)    
        elseif iconStr then
            if type(iconStr) == "table" then
                icon = V.createBMFont(iconStr._font, iconStr._str)
            else
                icon = V.createBMFont(V.BMFont.huali_32, iconStr)
            end
        end
        if icon then
            lc.addChildToPos(btn, icon, cc.p(lc.w(btn) / 2, lc.h(btn) / 2))
            btn._icon = icon
        end

        if titleStr then
            local title = V.createBMFont(V.BMFont.huali_26, titleStr)
            title:setColor(V.COLOR_BUTTON_TITLE)
            if isExIm then
                lc.addChildToPos(btn, title, cc.p(lc.w(btn) / 2, lc.h(btn) / 2))
            else
                lc.addChildToPos(btn, title, cc.p(lc.w(btn) / 2, -6))
            end
            btn._title = title
        end

        layer:addChild(btn)
        return btn
    end

    local gap = 12

    self._btnReturn = addButton("bat_btn_2", "bat_btn_icon_back")
    self._btnReturn:setPosition(lc.cw(self._btnReturn) + gap, V.SCR_H - 80 - lc.ch(self._btnReturn))

    self._btnExport = addButton("bat_btn_2", nil, nil, Str(STR.EXPORT), true)
    self._btnExport:setTouchRect(cc.rect(-6, -6, lc.w(self._btnExport) + 12, lc.h(self._btnExport) + 12))
    self._btnExport:setPosition(gap + lc.w(self._btnExport) / 2, lc.bottom(self._btnReturn) - lc.ch(self._btnExport))

    self._btnImport = addButton("bat_btn_2", nil, nil, Str(STR.LOAD), true)
    self._btnImport:setTouchRect(cc.rect(-6, -6, lc.w(self._btnImport) + 12, lc.h(self._btnImport) + 12))
    self._btnImport:setPosition(gap + lc.w(self._btnImport) / 2, lc.bottom(self._btnExport) - lc.ch(self._btnImport))
    
    self._btnStart = addButton("bat_btn_2", nil, nil, Str(STR.RUN_FREE), true)
    self._btnStart:setTouchRect(cc.rect(-6, -6, lc.w(self._btnStart) + 12, lc.h(self._btnStart) + 12))
    self._btnStart:setPosition(gap + lc.w(self._btnStart) / 2, lc.bottom(self._btnImport) - lc.ch(self._btnStart))

    self._btnClear = addButton("bat_btn_2", nil, nil, Str(STR.CLEAR), true)
    self._btnClear:setTouchRect(cc.rect(-6, -6, lc.w(self._btnClear) + 12, lc.h(self._btnClear) + 12))
    self._btnClear:setPosition(gap + lc.w(self._btnClear) / 2, lc.bottom(self._btnStart) - lc.ch(self._btnClear))

end

-----------------------------------
-- handle events
-----------------------------------

function _M:onButtonEvent(sender)
    if sender == self._btnReturn then
        ClientData._unitTestFile = nil
        cc.Director:getInstance():popScene()

    elseif sender == self._btnEndRound then
        if self:isGuideWorldBattle(10101) and (self._guide10101Round == nil or self._guide10101Round < self._player._round) then
            self._guide10101Round = self._player._round
            if self._player:canUseHandCard() then
                self:showTip{t = {story = 201, touch = 1, left = 1}}
                return
            end
        end

        local player = self._player:getActionPlayer()
        if player:isNeedDrop() then
            self:showDropHand()
        else
            self._timeOutTimes = 0
            self:operateEnd()

            self:hideTip()
            self:setGuideHelpButtonVisible(false)
        end

    -- battle test: export button envent
    elseif sender == self._btnExport then
        local filename = lc.App:getSaveFileName()
        if filename ~= nil and filename ~= "" then
            self:exportTestCards(filename)
        end

    elseif sender == self._btnImport then
        local filename = lc.App:getOpenFileName()
        if filename ~= nil and filename ~= "" then
            BattleTestData._singleFileName = filename
            self:importTestCards(filename)
        end

    elseif sender == self._btnStart then
        self:exportTestCards(BattleTestData.DEFAULT_FILE)
        ClientData._unitTestFile = BattleTestData.DEFAULT_FILE
        BattleTestData._singleFileName = ClientData._unitTestFile
        BattleTestData.resetUsedCards()
        cc.Director:getInstance():popScene()

    elseif sender == self._btnClear then
        BattleTestData._singleFileName = nil
        self:reset()
    end
end

function _M:addSprites(playerUi, player, infoIds, flag)
    for i = 1, #infoIds do
        if infoIds[i] ~= nil then
            local pos = i
            local card
            local isDefence = false
            if infoIds[i] < 0 then
                isDefence = true
                infoIds[i] = -infoIds[i]
            end
            card = B.createCard(infoIds[i], 1)
            player:addCardToCards(card)

            if flag == "P" then
                card._saved._pos = pos
                player:addCardToPile(card)
--                local cardSprite = playerUi:createCardSprite(card)
--                self:addChild(cardSprite)
--                playerUi:addCardToPile(card, 0, 0)
                self:updatePile(playerUi)
            elseif flag == "B" then
                if infoIds[i] > 0 then
                    card._pos = pos
                    player._boardCards[pos] = card
                    local cardSprite = playerUi:createCardSprite(card)
                    self:addChild(cardSprite)
--                    playerUi:addCardToBoard(card, 0, 0)
                    -- fast
                    playerUi:addCardToBoardFast(card)
                end
            elseif flag == "G" then
                player:addCardToGrave(card)
                local cardSprite = playerUi:createCardSprite(card)
                self:addChild(cardSprite)
                playerUi:addCardToGrave(card, 0, 0)
            elseif flag == "H" then
                card._pos = pos
                player:addCardToHand(card)
                local cardSprite = playerUi:createCardSprite(card)
                self:addChild(cardSprite)
--                playerUi:addCardToHand(card, 0, 0)
                -- fast
                playerUi:addCardToHandFast(card)
            end
        end
    end
end

function _M:resetBattle()
    PlayerBattle._randomSeed = PlayerBattle._originRandomSeed
    if self._player._isAttacker then
        self._player:resetWhenBattleStart()
        self._opponent:resetWhenBattleStart()
    else
        self._opponent:resetWhenBattleStart()   
        self._player:resetWhenBattleStart()
    end
end

function _M:createDragonBones(str, pos, parent, aniName, isRemovable, scale, zOrder)
    if parent == nil or str == nil then return end
    
    aniName = aniName or "effect"
    if isRemovable == nil then isRemovable = true end
    
    local bones = DragonBones.create(str)
    bones:setPosition(pos)
    bones:setScale(scale or 1)
    parent:addChild(bones, zOrder or 0)
    
    self._scene:seenByCamera3D(parent)         -- Must call before gotoAndPlay()
    bones:gotoAndPlay(aniName)
    
    if isRemovable then
        local time = bones:getAnimationDuration(aniName)
        bones:runAction(lc.sequence(time, lc.remove()))
    end
    
    return bones
end

function _M:updatePile(playerUi)
    local player = playerUi._player
    local pileSpr = playerUi._pile
    local label = pileSpr._label
    
    local count = #player._pileCards
    label:setString(count)
    
    label:stopAllActions()
--    label:runAction(cc.Sequence:create(
--        cc.ScaleTo:create(0.2, 1.5), 
--        cc.ScaleTo:create(0.2, 1.0)
--    ))
end

function _M:exportTestCards(filename)
    local battleData = {}
    battleData.attackerHP = self._playerUi._pHpLabel:getString()
    battleData.attackerP = self._player._pileCards
    battleData.attackerH = self._player._handCards
    battleData.attackerB = self._player._boardCards
    battleData.attackerG = self._player._graveCards
    battleData.defenderHP = self._opponentUi._pHpLabel:getString()
    battleData.defenderP = self._opponent._pileCards
    battleData.defenderH = self._opponent._handCards
    battleData.defenderB = self._opponent._boardCards
    battleData.defenderG = self._opponent._graveCards

    BattleTestData.exportTestCardsData(filename, battleData)
end

function _M:importTestCards(filename)
    BattleTestData.resetUsedCards()
    local battleInfoIds = BattleTestData.importBattleTestData(filename)
    self:reset()

    -- update hp
    self._playerUi:setFortressHp(battleInfoIds.AttackerFields.HP)
    self._opponentUi:setFortressHp(battleInfoIds.DefenderFields.HP)

    -- add sprites: _M:addSprites(playerUi, player, infoIds, flag)
    self:addSprites(self._playerUi, self._player, battleInfoIds.AttackerFields.P, "P")
    self:addSprites(self._playerUi, self._player, battleInfoIds.AttackerFields.H, "H")
    self:addSprites(self._playerUi, self._player, battleInfoIds.AttackerFields.B, "B")
    self:addSprites(self._playerUi, self._player, battleInfoIds.AttackerFields.G, "G")
    self:addSprites(self._opponentUi, self._opponent, battleInfoIds.DefenderFields.P, "P")
    self:addSprites(self._opponentUi, self._opponent, battleInfoIds.DefenderFields.H, "H")
    self:addSprites(self._opponentUi, self._opponent, battleInfoIds.DefenderFields.B, "B")
    self:addSprites(self._opponentUi, self._opponent, battleInfoIds.DefenderFields.G, "G")
end

return _M