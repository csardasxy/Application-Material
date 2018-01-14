local _M = class("BattleUi", function() return ccui.Widget:create() end)
BattleUi = _M

_M.PVP_ROUND_DURATION = 45
_M.PVP_ROUND_OFFLINE_DURATION = 2
_M.PVP_ROPE_DURATION = 15
_M.PVP_RETREAT_DURATION = 90

_M.BattleSpeed = 
{
    1.1,
    1.5,
    2.0
}

_M.ShakeScreenType = 
{
    to_board = 1,
    equip_book = 2,
    attack_card = 3,
    
    fortress_die = 12,
    fortress_hurt = 13,

    retreat = 21,
}

_M.Tag = 
{
    help_dialog = 1000,
    retreat_dialog = 1001,

    remove_when_reset = 2000,
}

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

function _M.create(scene, input, nameTag)
    local battleUI = _M.new()
    battleUI:init(scene, input, nameTag)
    
    battleUI:registerScriptHandler(function(evtName)
       if evtName == "enter" then
            battleUI:onEnter()
        elseif evtName == "exit" then
            battleUI:onExit()
        elseif evtName == "cleanup" then
            battleUI:onCleanup()
        end
    end)
    
    return battleUI
end

function _M:init(scene, input, nameTag)
    self._scene = scene

    self._isReverse = false

    self:setContentSize(V.SCR_SIZE)
    self:setAnchorPoint(cc.p(0.5, 0.5))

    -- offsetY: 21x64: 100, 20x64: 0.96, ... , 16*64: 80
    -- scale: 21x64: 1, 20x64: 0.96, ... , 16*64: 0.8

    local gridWidth = math.min(math.max(16, math.floor(V.SCR_W / 64)), 21)
    self._scale = (1.0 - (21 - gridWidth) * 0.04)
    self._offsetY = 100 - (21 - gridWidth) * 4

    self:setPosition(cc.p(V.SCR_CW, V.SCR_CH + self._offsetY))
    self:setScale(self._scale)
--    if self._isReverse then
--        self:setScaleY(-self:getScaleY())
--    end
    self:setRotation3D({x = -V.BATTLE_ROTATION_X, y = 0, z = 0})

    -- check debug config
    if ClientData._cfg then
        if ClientData._cfg.battleSpeed and ClientData._cfg.battleSpeed > 0 then
            _M.BattleSpeed[1] = ClientData._cfg.battleSpeed
        end
    end

    -- audio
    self._audioEngine = BattleAudio.new(self)

    -- init data and ui
    self._nameTag = nameTag

    self:initData(input)
    self:initBackground()
    self:initUiControl()

    -- Add player UI
    self._playerUi = PlayerUi.new(self, self._player, self._sceneType, self._input._player._cardBackId)
    self._opponentUi = PlayerUi.new(self, self._opponent, self._sceneType, self._input._opponent._cardBackId)
    self._playerUi._opponentUi = self._opponentUi
    self._opponentUi._opponentUi = self._playerUi

    self._playerUi:resetWhenBattleStart()
    self._opponentUi:resetWhenBattleStart()

    self._scene:seenByCamera3D(self)

    return true
end

function _M:onEnter()
    if not self._playVideo then

        if self._isBattleFinished and self._battleType ~= Data.BattleType.unittest then
            return
        end

        -- fast
        if self._battleType == Data.BattleType.teach then
            require "BattleTestExtend"
        end

        -- init touch event
        local listener = cc.EventListenerTouchOneByOne:create()
        listener:setSwallowTouches(true)
        listener:registerScriptHandler(function(touch, event) return self:onTouchBegan(touch) end, cc.Handler.EVENT_TOUCH_BEGAN )
        listener:registerScriptHandler(function(touch, event) return self:onTouchMoved(touch) end, cc.Handler.EVENT_TOUCH_MOVED )
        listener:registerScriptHandler(function(touch, event) return self:onTouchEnded(touch) end, cc.Handler.EVENT_TOUCH_ENDED )
        listener:registerScriptHandler(function(touch, event) return self:onTouchCanceled() end, cc.Handler.EVENT_TOUCH_CANCELLED )
        self:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, self)

        self._battleListener = lc.addEventListener(PlayerBattle.EVENT, function(event) return self:onBattleEvent(event) end)
        self._playerUiListener = lc.addEventListener(PlayerUi.EVENT, function(event) return self:onPlayerUiEvent(event) end)
        self._cardSpriteListener = lc.addEventListener(CardSprite.EVENT, function(event) return self:onCardSpriteEvent(event) end)
        if self._battleType == Data.BattleType.PVP_room then
            self._roomListener = lc.addEventListener(Data.Event.room_exit_dirty, function(event) return lc.replaceScene(require("ResSwitchScene").create(self._scene._sceneId, ClientData.SceneId.find)) end)
        end
    
        -- battle speed
        self:setBattleSpeed()
        
        -- add use card
        if self._isOnlinePvp then
            self:setOppoOnline(false)
        end

        self:runAction(lc.sequence(
            self._battleType == Data.BattleType.unittest and 0 or 3,
            function() 
                -- start
                self:resetWhenBattleStart()
    
                if self._needForward then
                    if P._guideID < 100 then
                        self:forwardToRound(true, 5)
                    else
                        self:forwardToCurRound()
                    end
                elseif self._needTask then
                    self._isWaitToStart = true
                    -- beginner train start
                    if self._battleType == Data.BattleType.teach then
                        self._scene:seenByCamera3D(self)
                        self._player._playerType = BattleData.PlayerType.player
                        -- only load once
                        if Data._teachYgoInfo == nil or #Data._teachYgoInfo == 0 then 
                            local teachRes = lc.App:loadRes("res/teach.lcres")
                            for i = 1, #teachRes do
                                local resName = teachRes[i]
                                if string.hasSuffix(resName, ".bin") then
                                    local content = lc.App:getBinData(resName)
                                    Data.parseTeach(resName, content)
                                    lc.App:unloadRes(resName)
                                end
                            end
                        end
                        local index = tonumber(self._input._teachingId)
                        if index ~= nil then
                            self:loadYgoContent(Data._teachYgoInfo[index])
                            ClientData._battleFromTeach = index
                        end
                    end
                    -- beginner train end
                    self:showTask()
                
                else
                    if self._battleType == Data.BattleType.unittest then
                        if not self._unittestEntered then
                            self._unittestEntered = true
                            lc.pushScene(require("BattleTestScene").create(self._scene))
                        else
                            self._scene:seenByCamera3D(self)
                            if ClientData._unitTestFile ~= nil then
                                BattleTestData._curOpType = BattleTestData.OperationType._load
                                self:loadUnitTestFile(ClientData._unitTestFile)
                                self._testMaskLayer:setVisible(false)
                                self._player._playerType = BattleData.PlayerType.player
                            end
                        end
                        return
                    else
                        if self._needShowInning then
                            self:runAction(lc.sequence(function()
                                self._btnSetting:setVisible(false)
                                for _, btn in ipairs(self._showButtons) do
                                    btn:setVisible(false)
                                end
                                self:showDialog(BattleDialog.Type.inning, P._playerFindDark._inning)
                            end, 2.7, function()
                                self._btnSetting:setVisible(true)
                                for _, btn in ipairs(self._showButtons) do
                                    btn:setVisible(true)
                                end
                                self:startBattle()
                            end))
                        else
                            self:startBattle()
                        end
                    end
                end
                
                if P._guideID == 11 and ClientData.isPlayVideo() then
                    self:playVideo()
                else
                    self:openVS()
                end    
            end
         ))

     else
        self._playVideo = false
        self:openVS()
        local player = self._player:getActionPlayer()
        player:step()
     end
end

function _M:onExit()
    if not self._playVideo then
        GuideManager.stopGuide()

        lc.Dispatcher:removeEventListener(self._battleListener)
        lc.Dispatcher:removeEventListener(self._playerUiListener)
        lc.Dispatcher:removeEventListener(self._cardSpriteListener)
        if self._roomListener then
            lc.Dispatcher:removeEventListener(self._roomListener)
        end
        self:getEventDispatcher():removeEventListenersForTarget(self)
    
        if self._baseBattleType ~= Data.BattleType.base_PVP and self._baseBattleType ~= Data.BattleType.base_guidance and self._baseBattleType ~= Data.BattleType.base_replay and lc._configs ~= nil then
            lc.writeConfig(ClientData.ConfigKey.battle_speed, self._battleSpeed)
        end
        cc.Director:getInstance():getScheduler():setTimeScale(1)
    
        if self._statusScheduler ~= nil then lc.Scheduler:unscheduleScriptEntry(self._statusScheduler) end
        self:removeSoftGuide()
        if self._isOnlinePvp then
            self:stopPvpTiming()
            self:removePvpTimingRope()
        end
    end
end

function _M:onCleanup()
    if self._chatCDScheduler then
        lc.Scheduler:unscheduleScriptEntry(self._chatCDScheduler)
    end

    if self._playerUi ~= nil then self._playerUi:resetCardSprites() end
    if self._opponentUi ~= nil then self._opponentUi:resetCardSprites() end
end

function _M:onMsg(msg)
    local msgType = msg.type
    local msgStatus = msg.status

    if msgType == SglMsgType_pb.PB_TYPE_BATTLE_OP_USECARD then
        self:oppoTryUseCard()
        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_BATTLE_USECARD then
        self:observeTryUseCard()
        return true
        
    elseif msgType == SglMsgType_pb.PB_TYPE_BATTLE_OP_ONLINE then
        ClientData.addBattleDebugLog('ONLINE')
        self:setOppoOnline(true)
        return true
        
    elseif msgType == SglMsgType_pb.PB_TYPE_BATTLE_OP_OFFLINE then
        ClientData.addBattleDebugLog('OFFLINE')
        self:setOppoOnline(true)
        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_BATTLE_ONLINE then
        ClientData.addBattleDebugLog('PLAYER ONLINE')
        self:setPlayerOnline(true)
        return true
        
    elseif msgType == SglMsgType_pb.PB_TYPE_BATTLE_OFFLINE then
        ClientData.addBattleDebugLog('PLAYER OFFLINE')
        self:setPlayerOffline(true)
        return true
        
    elseif msgType == SglMsgType_pb.PB_TYPE_BATTLE_CHAT then
        local resp = msg.Extensions[Battle_pb.SglBattleMsg.battle_chat_resp]
        self:addChat(self._player, resp)
        return true
    
    elseif msgType == SglMsgType_pb.PB_TYPE_BATTLE_OP_CHAT then
        local resp = msg.Extensions[Battle_pb.SglBattleMsg.battle_chat_resp]
        if not self._isIgnoreChat then
            self:addChat(self._opponent, resp)
        end
        return true
        
    end
    
    return false
end

function _M:exitScene(toSceneId)
    toSceneId = toSceneId or ClientData._fromSceneId

    if self._battleType == Data.BattleType.PVP_room and P._playerRoom:getMyRoom() then
        toSceneId = ClientData.SceneId.in_room
    end

    if P._playerFindDark:isInDarkBattle() then
        toSceneId = ClientData.SceneId.find
    end

    self:stopAllActions()

    cc.Director:getInstance():getScheduler():setTimeScale(1)
    ClientData._replayInBattle = false

    if P._guideID < 100 then
        local guideGroup = math.floor(P._guideID / 10) + 1
        if guideGroup > 5 then
            GuideManager.setGuideIDandSave(101)

            local lightMask = cc.LayerColor:create(cc.c4b(255, 255, 255, 0), V.SCR_W, V.SCR_H)
            lc.addChildToCenter(self._layer, lightMask)

            lc.Audio.playAudio(AUDIO.E_FLASH)

            lightMask:runAction(lc.sequence(lc.fadeIn(1.0), function()
                lc.replaceScene(require("ResSwitchScene").create(self._scene._sceneId, ClientData.SceneId.city))
            end))
        else
            GuideManager.setGuideIDandSave(guideGroup * 10 + 1, true)

            local input = ClientData.genInputFromGuidance(guideGroup)
            self._scene:onBattleRecover(input)
        end

    else
        if self._baseBattleType == Data.BattleType.base_guidance then
            toSceneId = ClientData.SceneId.city
        elseif GuideManager._hasNewCityGuide then
            toSceneId = ClientData.SceneId.city
        end

        lc.replaceScene(require("ResSwitchScene").create(ClientData.SceneId.battle, toSceneId))
    end
end

-----------------------------------
-- init
-----------------------------------

function _M:initData(input)
    self._input = input
    self._battleType = input._battleType
    self._baseBattleType = math.floor(self._battleType / Data.BattleType.base_type)
    self._sceneType = input._sceneType or Data.BattleSceneType.stone_scene
    self._timestamp = math.floor(input._timestamp / 1000)

    -- replay test
    if self._isReverse then
        self._isAttacker = not input._isAttacker
    else 
        self._isAttacker = input._isAttacker
    end
--    self._isAttacker = input._isAttacker
	self._needForward = input._needForward
    self._isBattleEndSended = false

    if input._replayBattleType then
        self._replayType = input._replayBattleType
        self._replayBaseType = math.floor(input._replayBattleType / Data.BattleType.base_type)
    end

    -- auto and battleSpeed
    self._timeOutTimes = 0
    self._autoConfig = false

    local getSpeed = function(level, vip)
        if level >= Data._globalInfo._3xSpeedLevel or vip >= Data._globalInfo._3xSpeedVip then
            return 3
        elseif level >= Data._globalInfo._2xSpeedLevel or vip >= Data._globalInfo._2xSpeedVip then
            return 2
        else
            return 1
        end
    end

    if self._nameTag ~= 'normal' then
        self._battleSpeed = 1

    elseif self._baseBattleType == Data.BattleType.base_guidance then
        self._battleSpeed = 1

    elseif self._baseBattleType == Data.BattleType.base_PVP then
        local speed1, speed2 = getSpeed(input._player._level, input._player._vip), getSpeed(input._opponent._level, input._opponent._vip)
        if self._battleType == Data.BattleType.PVP_clash or self._battleType == Data.BattleType.PVP_ladder or self._battleType == Data.BattleType.PVP_room or self._battleType == Data.BattleType.PVP_group or self._battleType == Data.BattleType.PVP_dark then
            --self._battleSpeed = math.min(speed1, speed2)
            self._battleSpeed = 1
        else
            self._battleSpeed = speed1
        end

    elseif self._baseBattleType == Data.BattleType.base_replay then
        self._battleSpeed = getSpeed(P._level, P._vip)

    elseif lc._configs ~= nil then
        if self:isGuideWorldBattle() then            
            self._battleSpeed = 1
        else            
            self._battleSpeed = lc.readConfig(ClientData.ConfigKey.battle_speed, 1)
            if self._battleSpeed == nil or self._battleSpeed < 1 or self._battleSpeed > #_M.BattleSpeed then 
                self._battleSpeed = 1
            end
        end
    else
        self._battleSpeed = 1
    end

    -- battle type design
    self._isObserver = input._isWatcher
    self._needSendEvent     = self._baseBattleType == Data.BattleType.base_PVP or 
                                self._baseBattleType == Data.BattleType.base_PVE
    self._needOperation     = self._baseBattleType == Data.BattleType.base_PVP or 
                                self._baseBattleType == Data.BattleType.base_PVE or 
                                self._baseBattleType == Data.BattleType.base_guidance or 
                                self._baseBattleType == Data.BattleType.base_test
    self._needRetreat       = (self._baseBattleType == Data.BattleType.base_PVP or 
                                self._baseBattleType == Data.BattleType.base_PVE or 
                                self._baseBattleType == Data.BattleType.base_test
                                -- beginner guide
                                or self._battleType == Data.BattleType.teach) and not self._isObserver
    self._needReturn        = (self._baseBattleType == Data.BattleType.base_replay or
                                self._battleType == Data.BattleType.recommend_train) and not self._isObserver
    
    self._needTask          = (self._battleType == Data.BattleType.task or
                                input._replayBattleType == Data.BattleType.task or
                                self._battleType == Data.BattleType.teach) and not self._isObserver
    self._needEvents        = self._baseBattleType == Data.BattleType.base_PVP or
                                self._replayBaseType == Data.BattleType.base_PVP or
                                self._battleType == Data.BattleType.task or 
                                self._battleType == Data.BattleType.guidance or
                                self._battleType == Data.BattleType.recommend_train or
                                self._battleType == Data.BattleType.test or
                                self._battleType == Data.BattleType.replay

    self._needShowInning = self._battleType == Data.BattleType.PVP_dark
    
    -- Do not need soft guide (Red arrow animation)
    self._needSoftGuide     = false --self._nameTag == 'normal' and P._guideID >= 500 and P._level < 10

    self._isTesting = input._isTesting
    self._speedFactor = input._speedFactor or 1
    if self._isTesting or self._isObserver then
        self._needSendEvent = false
    end

    
    local isAttacker = input._isAttacker
    if self._isReverse == true then
        isAttacker = not input._isAttacker
    end
    -- init player and opponent
    local playerInfo = 
    {
        _isClient = true,
        -- replay test
        _isAttacker = isAttacker,
--        _isAttacker = input._isAttacker,
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

        _idInRoom = input._player._idInRoom,
    }
    local opponentInfo = 
    {
        _isClient = true,
        -- replay test
        _isAttacker = not isAttacker,
--        _isAttacker = not input._isAttacker,
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

        _idInRoom = input._opponent._idInRoom
    }

    -- init player data
    self._player = PlayerBattle.new(playerInfo)
    self._opponent = PlayerBattle.new(opponentInfo)
    self._player._opponent, self._opponent._opponent = self._opponent, self._player
    self:resetBattle()


    if self._nameTag == 'normal' then
        ClientData._reportBattleDebugLog = true
        ClientData._battleDebugLog = ''..P._id..': '
        for i = 1, #playerInfo._usedCards do
            ClientData.addBattleDebugLog((playerInfo._isAttacker and 'AU' or 'DU')..playerInfo._usedCards[i]..',')
        end
        for i = 1, #opponentInfo._usedCards do
            ClientData.addBattleDebugLog((opponentInfo._isAttacker and 'AU' or 'DU')..opponentInfo._usedCards[i]..',')
        end
        ClientData.addBattleDebugLog('\n\n')
    end

    self._isOnlinePvp       = self._battleType == Data.BattleType.PVP_clash or 
                                self._battleType == Data.BattleType.PVP_ladder or
                                    self._battleType == Data.BattleType.PVP_room or
                                    self._battleType == Data.BattleType.PVP_group or
                                    self._battleType == Data.BattleType.PVP_dark

    -- set player type
    if self._baseBattleType == Data.BattleType.base_replay then
        self._player._playerType = BattleData.PlayerType.replay
        self._opponent._playerType = BattleData.PlayerType.replay
    elseif self._baseBattleType == Data.BattleType.base_guidance then
        self._player._playerType = P._guideID < 21 and BattleData.PlayerType.replay or BattleData.PlayerType.player
        self._opponent._playerType = BattleData.PlayerType.replay
    elseif self._baseBattleType == Data.BattleType.base_PVP then
        if self._battleType == Data.BattleType.PVP_room and self._isObserver then
            self._player._playerType = BattleData.PlayerType.observe
        else
            self._player._playerType = BattleData.PlayerType.player
        end
        if self._isOnlinePvp then self._opponent._playerType = BattleData.PlayerType.opponent
        else self._opponent._playerType = BattleData.PlayerType.ai
        end
    elseif self._baseBattleType == Data.BattleType.base_PVE then
        self._player._playerType = BattleData.PlayerType.player
        self._opponent._playerType = BattleData.PlayerType.ai

    elseif self._battleType == Data.BattleType.test then
        self._player._playerType = ClientData._isAutoTesting and BattleData.PlayerType.ai or BattleData.PlayerType.player
        self._opponent._playerType = BattleData.PlayerType.ai
    elseif self._battleType == Data.BattleType.recommend_train then
        self._player._playerType = ClientData._isAutoTesting and BattleData.PlayerType.ai or BattleData.PlayerType.player
        self._opponent._playerType = BattleData.PlayerType.ai
    elseif self._battleType == Data.BattleType.unittest then
        self._player._playerType = BattleData.PlayerType.player
        self._opponent._playerType = BattleData.PlayerType.ai
    elseif self._battleType == Data.BattleType.teach then
        self._player._playerType = BattleData.PlayerType.player
        self._opponent._playerType = BattleData.PlayerType.ai
    end

    
    
    
    -- init
    self._player._name, self._opponent._name = input._player._name, input._opponent._name
    self._player._level, self._opponent._level = input._player._level, input._opponent._level
    self._player._vip, self._opponent._vip = input._player._vip, input._opponent._vip
    self._player._avatar, self._opponent._avatar = input._player._avatar, input._opponent._avatar
    self._player._crown, self._opponent._crown = input._player._crown, input._opponent._crown
    
    -- pvp timing
    if self._isOnlinePvp then
        self:stopPvpTiming()
        self:removePvpTimingRope()
    end
end

function _M:resetAction()
    self:setPosition(cc.p(V.SCR_CW, V.SCR_CH + self._offsetY))
    self:setScale(self._scale)
--    if self._isReverse then
--        self:setScaleY(-self:getScaleY())
--    end

    self:stopAllActions()
end

function _M:initBackground()
    -- init bg
    local index = self._sceneType
    if (index ~= 21 and (index < 11 or index > 15)) then index = 1 end
    local str = string.format("res/bat_scene/bat_scene_%d_bg.jpg", index)
    local skySpr = cc.Sprite:create(str)
    lc.addChildToCenter(ClientData._battleScene, skySpr, -1)
    self._scene:seenByCamera3D(skySpr)
    self._skySpr = skySpr

    -- bg
    local battleRact = lc.createSpriteWithMask('res/jpg/battle_board_bg.jpg')
    lc.addChildToCenter(self, battleRact)
end

function _M:initUiControl()
    local layer = cc.Node:create()
    layer:setContentSize(V.SCR_SIZE)
    layer:setAnchorPoint(0.5, 0.5) 
    lc.addChildToCenter(self._scene, layer, BattleScene.ZOrder.ui)   
    self._layer = layer

    --<< Pile >>--
    local createInfoArea = function(info, isBottom)
        local name, level, region = info._name, info._level, info._region

        local battleType = (self._battleType == Data.BattleType.replay and self._replayType or self._battleType)
        local isRegionBattle = (battleType == Data.BattleType.PVP_clash or battleType == Data.BattleType.PVP_clash_npc)

        local area = ccui.Widget:create()
        area:setContentSize(140, 86)
        area:setTouchEnabled(true)
        area:addTouchEventListener(function (sender, type)
            if type == ccui.TouchEventType.ended then
                self:showDialog(isBottom and BattleDialog.Type.your_card_pile or BattleDialog.Type.oppo_card_pile)
            end
        end)

        local name = V.createTTF(name or "")
        local nameBg = lc.createSprite{_name = "img_com_bg_2", _crect = V.CRECT_COM_BG2, _size = cc.size(lc.w(name) + 24, 30)}
        nameBg:setColor(lc.Color3B.black)
        nameBg:setOpacity(150)
        nameBg:setFlippedX(true)
        lc.addChildToPos(area, nameBg, cc.p(lc.w(area) - lc.w(nameBg) / 2 - 2, isBottom and lc.h(nameBg) / 2 or lc.h(area) - lc.h(nameBg) / 2))
        lc.addChildToPos(area, name, cc.p(nameBg:getPosition()))

        local levelArea
        if level and level > 0 then
            levelArea = V.createLevelArea(level)
            lc.addChildToPos(area, levelArea, cc.p(lc.w(area) - lc.w(levelArea) / 2, lc.y(name)))

            lc.offset(nameBg, -18)
            lc.offset(name, -24)

            if self._battleType == Data.BattleType.PVP_clash and not isBottom then
                levelArea._level:setString("?")
            end
        end

        if region and region > 0 and isRegionBattle and (not isBottom or self._battleType == Data.BattleType.replay) then
            local str = string.format(Str(STR.BRACKETS_S), ClientData.genChannelRegionName(region))
            local regionLabel = V.createTTF(str, nil, V.COLOR_TEXT_GREEN)
            lc.addChildToPos(area, regionLabel, cc.p(lc.left(name) - lc.w(regionLabel) / 2 - 4, lc.y(name)))
        end

        local pile = V.createIconLabelArea("img_icon_cardnum", "", lc.w(area))
        lc.addChildToPos(area, pile, cc.p(lc.w(pile) / 2, isBottom and lc.h(area) - lc.h(pile) / 2 - 4 or lc.h(pile) / 2))
        area._pile = pile
        
        if isRegionBattle then
            local trophy = V.createIconLabelArea("img_icon_res6_s", info._trophy, lc.w(area))
            lc.addChildToPos(area, trophy, cc.p(lc.w(trophy) / 2, isBottom and lc.top(pile) + 4 + lc.h(trophy) / 2 or lc.bottom(pile) - 4 - lc.h(trophy) / 2))            
        end

        return area
    end

    --[[
    local selfInfoArea = createInfoArea(self._input._player, true)
    lc.addChildToPos(self._layer, selfInfoArea, cc.p(lc.w(selfInfoArea) / 2 + 12, lc.h(selfInfoArea) / 2 + 12), BattleScene.ZOrder.ui)
    self._atkPile = selfInfoArea._pile

    local oppoInfoArea = createInfoArea(self._input._opponent, false)
    lc.addChildToPos(self._layer, oppoInfoArea, cc.p(lc.x(selfInfoArea), lc.h(self) - lc.h(oppoInfoArea) / 2 - 12), BattleScene.ZOrder.ui)
    self._defPile = oppoInfoArea._pile
    ]]

    --<< Add buttons >>--
    local addButton = function(btnName, iconName, iconStr, titleStr)
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
            lc.addChildToPos(btn, title, cc.p(lc.w(btn) / 2, -6))
            btn._title = title
        end

        layer:addChild(btn)
        return btn
    end

    local gap = 12

    -- end round
    local rot = 20

    local btnEndRoundBg = lc.createSprite('bat_btn_bg')
    lc.addChildToPos(layer, btnEndRoundBg, cc.p(V.SCR_W - 80, 50))

    self._btnEndRound = addButton("bat_btn_6")
    self._btnEndRound:setPosition(btnEndRoundBg:getPosition())
    self._btnEndRound:setTouchEnabled(false)

    self._pRoundTitle = lc.createSprite('bat_label_atk')
    lc.addChildToCenter(self._btnEndRound, self._pRoundTitle)

    local roundBg = lc.createSprite('bat_scene_round_bottom')
    lc.addChildToPos(btnEndRoundBg, roundBg, cc.p(-10, lc.ch(btnEndRoundBg)), -1)
    
    self._pRoundLabel = V.createBMFont(V.BMFont.huali_26, '0')
    lc.addChildToPos(roundBg, self._pRoundLabel, cc.p(lc.cw(roundBg) - 10, lc.ch(roundBg)))
    
    -- Setting
    self._btnSetting = addButton("bat_btn_2", "bat_btn_set")
    self._btnSetting:setPosition(lc.cw(self._btnSetting) + gap, V.SCR_H - gap - lc.ch(self._btnSetting))

    -- Music, sound effect and help
    self._btnMusic = addButton(ClientData._isMusicOn and "bat_btn_2" or "bat_btn_3", nil, Str(ClientData._isMusicOn and STR.ON or STR.OFF), Str(STR.AUDIO_MUSIC))
    self._btnSndEffect = addButton(ClientData._isEffectOn and "bat_btn_2" or "bat_btn_3", nil, Str(ClientData._isMusicOn and STR.ON or STR.OFF), Str(STR.AUDIO_EFFECT))
    self._btnHelp = addButton("bat_btn_2", "bat_btn_icon_help", nil, Str(STR.HELP))
    
    self._btnMusic:setVisible(false)
    self._btnSndEffect:setVisible(false)
    self._btnHelp:setVisible(false)
    
    -- Task, retreat and back
    self._btnTask = addButton("bat_btn_2", "bat_btn_icon_task", nil, string.sub(Str(STR.PASS_CONDITION), 7))
    self._btnRetreat = addButton("bat_btn_2", "bat_btn_icon_retreat", nil, self._retreatReturn and Str(STR.BATTLE_RETURN) or Str(STR.BATTLE_RETREAT))
    self._btnReturn = addButton("bat_btn_2", "bat_btn_icon_back", nil, Str(STR.RETURN))

    self._btnTask:setVisible(false)
    self._btnRetreat:setVisible(false)
    self._btnReturn:setVisible(false)

    -- Auto/Manual and Play/Pause
    local btnReplay = addButton("bat_btn_2", "bat_btn_icon_pause")
    btnReplay:setPosition(gap + lc.w(btnReplay) / 2, lc.bottom(self._btnSetting) - lc.ch(btnReplay) - 8)
    self._btnReplay = btnReplay

    local btnAuto = addButton("bat_btn_2", "bat_btn_icon_auto", nil, Str(STR.AUTO))
    btnAuto:setPosition(btnReplay:getPosition())
    --btnAuto._icon:setLocalZOrder(2)
    lc.offset(btnAuto._title, 0, 16)
    self._btnAuto = btnAuto
    self:setBtnAuto(self._autoConfig)

    -- Speed
    local btnSpeed = addButton("bat_btn_2", nil, string.format("x%d", self._battleSpeed))
    btnSpeed:setTouchRect(cc.rect(-6, -6, lc.w(btnSpeed) + 12, lc.h(btnSpeed) + 12))
    -- beginner guide
    if self._battleType == Data.BattleType.teach then
        btnSpeed:setPosition(gap + lc.w(btnSpeed) / 2, lc.bottom(self._btnSetting) - lc.ch(btnSpeed) - 8)
    else
        btnSpeed:setPosition(gap + lc.w(btnSpeed) / 2, lc.bottom(btnReplay) - lc.ch(btnSpeed) - 8)
    end
    self._btnSpeed = btnSpeed

    -- switch view of player
    local btnSwitchView = addButton("bat_btn_2", "bat_btn_icon_switch")
    btnSwitchView:setTouchRect(cc.rect(-6, -6, lc.w(btnSwitchView) + 12, lc.h(btnSwitchView) + 12))
    btnSwitchView:setPosition(gap + lc.w(btnSwitchView) / 2, lc.bottom(self._btnSetting) - lc.ch(btnSwitchView))
    self._btnSwitchView = btnSwitchView

    
    -- Skip
    --[[
    local btnSkip = addButton("bat_btn_2", nil, {_str = Str(STR.SKIP), _font = V.BMFont.huali_26})
    btnSkip:setTouchRect(cc.rect(-6, -6, lc.w(btnSkip) + 12, lc.h(btnSkip) + 12))         
    btnSkip:setPosition(lc.right(btnAuto) + gap + lc.w(btnSkip) / 2, gap + lc.h(btnSkip) / 2)
    self._btnSkip = btnSkip
    ]]

    --[[
    -- Chat
    local btnChat = addButton("bat_btn_2", "bat_btn_icon_chat")
    btnChat:setTouchRect(cc.rect(-6, -6, lc.w(btnChat) + 12, lc.h(btnChat) + 12))
    btnChat:setPosition(btnSpeed:getPosition())
    self._btnChat = btnChat
    ]]
    
    -- Hide some buttons according to the battle type
    local addGuideHelpButton = function()
        -- Create guide help button 
        local btn = addButton("bat_btn_4", "bat_icon_guide_npc", nil, Str(STR.TIP))
        btn:setPosition(gap + lc.w(btn) / 2, gap + lc.h(btn) / 2)
        lc.offset(btn._icon, -9, 7)
        btn:setVisible(false)
        self._btnGuideHelp = btn

        local guideBg = lc.createImageView{_name = "img_com_bg_11", _crect = V.CRECT_COM_BG11}
        guideBg:setVisible(false)
        lc.addChildToPos(self._layer, guideBg, cc.p(V.SCR_CW, 740), BattleScene.ZOrder.ui)

        --[[
        local par = Particle.create("par_story_title")
        par:setPositionType(cc.POSITION_TYPE_GROUPED)
        par:setScale(2.4)
        lc.addChildToCenter(guideBg, par, -1)
        guideBg._par = par
        ]]

        self._guideHelp = guideBg
    end

    local buttons = {btnAuto, btnReplay, btnSpeed, btnSwitchView}
    local showButtons = {}
    if self._baseBattleType == Data.BattleType.base_PVP then
        if (lc.PLATFORM == cc.PLATFORM_OS_WINDOWS) then
            btnReplay:setPositionX(btnReplay:getPosition() + 100)
            if self._battleType == Data.BattleType.PVP_clash or self._battleType == Data.BattleType.PVP_friend or self._battleType == Data.BattleType.PVP_ladder or self._battleType == Data.BattleType.PVP_room or self._battleType == Data.BattleType.PVP_group or self._battleType == Data.BattleType.PVP_dark then
                if self._isObserver then
                    showButtons = {btnSwitchView}
                else
                    showButtons = {btnAuto, btnReplay}
                end
            else
                showButtons = {btnAuto, btnSpeed, btnReplay}
            end
        else
            if self._battleType == Data.BattleType.PVP_clash or self._battleType == Data.BattleType.PVP_friend or self._battleType == Data.BattleType.PVP_ladder or self._battleType == Data.BattleType.PVP_room or self._battleType == Data.BattleType.PVP_group or self._battleType == Data.BattleType.PVP_dark then
                if self._isObserver then
                    showButtons = {btnSwitchView}
                else
                    showButtons = {btnAuto}
                end
            else
                showButtons = {btnAuto, btnSpeed}
            end
        end
    elseif self._baseBattleType == Data.BattleType.base_PVE then
        if self._isObserver then
            showButtons = {btnSwitchView}
        else
            showButtons = {btnAuto, btnSpeed}
        end
    elseif self._baseBattleType == Data.BattleType.base_replay then
        showButtons = {btnReplay, btnSpeed, btnSwitchView}
    elseif self._baseBattleType == Data.BattleType.base_guidance then
        addGuideHelpButton()
        showButtons = {}
    elseif self._battleType == Data.BattleType.test then
        showButtons = {btnReplay, btnSpeed}
    elseif self._battleType == Data.BattleType.unittest then
        showButtons = {btnSpeed, btnAuto}
    elseif self._battleType == Data.BattleType.recommend_train then
        showButtons = {btnSpeed, btnAuto}
    elseif self._battleType == Data.BattleType.teach then
        showButtons = {btnSpeed}
    end
    self._showButtons = showButtons
    for _, btn in ipairs(buttons) do btn:setVisible(false) end
    for _, btn in ipairs(showButtons) do btn:setVisible(true) end

   --TODO
   btnSwitchView:setVisible(false)

    -- score
    --[[self._score = V.createResIconLabel(120, string.format("img_icon_score", 1))
    self._score._label:setString("0")
    self._score._label._value = 0

    if P._guideID < 100 then
        self._score:setVisible(false)
    end

    local pos = cc.p((btnSetting:isVisible() and lc.right(btnSetting) or 0) + 32 + lc.w(self._score) / 2, lc.h(self) - 68 - lc.h(self._score) / 2)
    lc.addChildToPos(layer, self._score, pos)]]

    -- Add camera action mask
    local mask = lc.createMaskLayer(200, lc.Color3B.black, cc.size(V.SCR_W + 50, V.SCR_H + 50))
    mask:setAnchorPoint(0.5, 0.5)
    self._mask = mask
    self._layer:addChild(mask, BattleScene.ZOrder.form)

    mask.resetAction = function(mask)
        mask:setPosition(V.SCR_CW, V.SCR_CH)
        mask:setVisible(false)
        mask:setOpacity(200)
        mask:stopAllActions()
    end
    mask:resetAction()

    -- vs
    if P._guideID >= 21 and self._battleType ~= Data.BattleType.unittest then
        local spine = V.createSpine('VS')
        lc.addChildToPos(self._scene, spine, cc.p(V.SCR_CW, V.SCR_CH), BattleScene.ZOrder.top)
        spine:setAnimation(0, "animation", false)
        spine:runAction(lc.sequence(1, function() 
            spine:setAnimation(0, "animation2", true)
        end))
        --bone:setScale(1.2 * math.max(1, V.SCR_W / 1366))
        self._vsSpine = spine
        --self._audioEngine:playEffect("e_vs")
    end

    if self._battleType == Data.BattleType.unittest then
        self._testMaskLayer = lc.createMaskLayer(128)
        lc.addChildToCenter(layer, self._testMaskLayer)

        self._btnBatch = addButton("bat_btn_2", "bat_btn_icon_play", nil, Str(STR.BATCH))
        self._btnLayout = addButton("bat_btn_2", "bat_btn_set", nil, Str(STR.LAYOUT))
        self._btnLoad = addButton("bat_btn_2", "bat_btn_icon_back", nil, Str(STR.LOAD))
        self._btnRunFree = addButton("bat_btn_2", "bat_btn_icon_manual", nil, Str(STR.RUN_FREE))
        self._btnExport = addButton("bat_btn_2", "bat_btn_icon_retreat", nil, Str(STR.EXPORT))
        self._btnRunTest = addButton("bat_btn_2", "bat_btn_icon_play", nil, Str(STR.RUN_TEST))
        
        local btns = {self._btnBatch, self._btnLayout, self._btnLoad, self._btnRunFree, self._btnExport, self._btnRunTest}
        for i = 1, #btns do
            lc.offset(btns[i]._title, 0, 20)
            btns[i]:setPosition(66 + 108 * i, lc.h(layer) - lc.ch(btns[i]) - 12)
            btns[i]:setVisible(i <= 3)
        end

        self:createTestProgress()
    end

end

-----------------------------------
-- reset
-----------------------------------

function _M:resetWhenBattleStart()
    self._isAutoAuto = false
    self._isAuto = self._autoConfig
    self._isPaused = false
    
    self._isOperating = false
    self._isAddingBoardCard = false
    self._isBattleFinished = false
    
    self._isWaitting = false

    self:removeChildrenByTag(_M.Tag.remove_when_reset)
end

function _M:resetWhenBattleEnd()
    if self._statusScheduler ~= nil then lc.Scheduler:unscheduleScriptEntry(self._statusScheduler) end
    --self:removeTimeOutRope()
    self:removeSoftGuide()
    self:hideThinking()

    if self._isOnlinePvp then
        self:stopPvpTiming()
        self:removePvpTimingRope()
    end
end

function _M:resetWhenRoundBegin()
    self._isOperating = false
    self._isEndOperating = false
    self._isAddingBoardCard = false
    self._isEnableDrap = false
    
    self:updateRoundButton()
    self:updateRound() 
end

function _M:resetWhenInitialDeal()
    self._playerUi:resetWhenInitialDeal()
    self._opponentUi:resetWhenInitialDeal()
end

-----------------------------------
-- battle start finish and skip 
-----------------------------------

function _M:startBattle()
    if self._isAttacker then
        return self._player:start()
    else
        return self._opponent:start()
    end
end

function _M:start(delay)
    -- update ui
    self:updatePile(self._playerUi)
    self:updatePile(self._opponentUi)
    self:updateRound()

    delay = delay + self:showStartCoin()
    
    return delay
end

function _M:finish()
    if self._isBattleFinished then return end
    
    self:resetWhenBattleEnd()
    self._isBattleFinished = true
    
    -- show dialog
    local delay = 0.5
    local battleResult = self._player:getResult()
    if battleResult ~= Data.BattleResult.draw then
        if self._player._isRetreat or self._opponent._isRetreat then
            self:addChat(self._player._isRetreat and self._player or self._opponent, Str(STR.BATTLE_CHAT_RETREAT))
            delay = 0.5
        elseif self._player._isRemainUnusable or self._opponent._isRemainUnusable then
            self:addChat(self._player._isRemainUnusable and self._player or self._opponent, Str(STR.BATTLE_CHAT_REMAIN_UNUSABLE))
            delay = 0.5
        elseif self._baseBattleType == Data.BattleType.base_PVP then
            self:addChat(battleResult == Data.BattleResult.win and self._opponent or self._player, Str(STR.BATTLE_CHAT_LOSE))
            delay = 0.5
        elseif self._player:getIsRoundExceed() or self._opponent:getIsRoundExceed() then
            self:addChat(battleResult == Data.BattleResult.win and self._opponent or self._player, Str(STR.BATTLE_CHAT_ROUND_EXCEED))
            delay = 0.5
        -- beginner train
        elseif self._battleType == Data.BattleType.teach then
            -- do nothing, just avoid empty pile
        elseif self._player:getIsPileEmpty() or self._opponent:getIsPileEmpty() then
            self:addChat(battleResult == Data.BattleResult.win and self._opponent or self._player, Str(STR.BATTLE_CHAT_PILE_EMPTY))
            delay = 0.5
        end
    end
    
    delay = self._playerUi:finish(delay)
    
    return delay
end

function _M:sendBattleEnd()
    if self._needSendEvent then
        if self._isBattleEndSended then
            return
        else
            self._isBattleEndSended = true
            self:showWaiting()

            if self:isGuideWorldBattle() then
                local guideId = P._guideID
                while true do
                    if Data._guideInfo[guideId]._stepName == 'in battle' then break end
                    guideId = guideId + 1
                end
                if self._player:getResult() == Data.BattleResult.win then
                    P._guideID = guideId + 1
                    ClientData.sendBattleEnd(true)
                    P._isGuideBattleLose = nil
                else
                    P._guideID = guideId - 6
                    ClientData.sendBattleEnd()
                    P._isGuideBattleLose = true
                end
            else                
                ClientData.sendBattleEnd()
            end
        end
    elseif not self._isObserver then
        self:showResult()
    end
end

function _M:retry()
    if not P:checkBattleCost(nil, nil, self._input._levelId) then
        ToastManager.push(Str(STR.NOT_ENOUGH_GRAIN), ToastManager.DURATION_LONG)
        return
    end

    local troop = P._playerCard:getTroop(P._curTroopIndex)
    if troop == nil or #troop == 0 then
        ToastManager.push(Str(STR.EMPTY_IN_TROOP))
        return
    end

    V.getActiveIndicator():show(Str(STR.WAITING))
    ClientData.sendBattleAgain()
end

function _M:replay()
    self:hideResult()
    
    self._playerUi:efcFortressDieRemove()
    self._opponentUi:efcFortressDieRemove()

    self:resetBattle()
    
    self._playerUi:resetWhenBattleStart()
    self._opponentUi:resetWhenBattleStart()
    self:resetWhenBattleStart()
    
    self:setBattleSpeed()

    return self:startBattle()
end 

function _M:retreat(player)
    if self._player._isFinished or self._opponent._isFinished then return end
    
    if self._statusScheduler ~= nil then
        lc.Scheduler:unscheduleScriptEntry(self._statusScheduler)
        self._statusScheduler = nil
    end

    self._scene:removeChildrenByTag(BattleData.TAG_BATTLE_LIST_DIALOG)
    
    if self._needSendEvent and player._isAttacker == self._isAttacker then
        if self._retreatReturn then
            ClientData.sendBattleRetry()
            self:exitScene()
            return true
        else
            ClientData.sendBattleUseCard(player, BattleData.UseCardType.retreat, {player._fortress._id})
        end
    end

    return player:retreat()
end

function _M:pause()
    self._isPaused = true

    GuideManager.pauseGuide()
    
    self._player:pause()
    self._opponent:pause()
end

function _M:resume()
    self._isPaused = false
    
    GuideManager.resumeGuide()

    self._player:resume()
    self._opponent:resume()
end

function _M:forwardToRound(isOpponent, round)
	self._player:beginForward((not isOpponent) and round or nil)
    self._opponent:beginForward(isOpponent and round or nil)
	
	self:startBattle()

    self._player:endForward()
    self._opponent:endForward()

    if self._battleType == Data.BattleType.teach or self._battleType == Data.BattleType.unittest then
        self._player._fortress._hp = tonumber(self._player._unitTestData.AttackerFields.HP) and tonumber(self._player._unitTestData.AttackerFields.HP) or 8000
        self._opponent._fortress._hp = tonumber(self._player._unitTestData.DefenderFields.HP) and tonumber(self._player._unitTestData.DefenderFields.HP) or 8000
        self._player._fortress._maxHp = self._player._fortress._hp
        self._opponent._fortress._maxHp = self._opponent._fortress._hp
        self._player._fortress._updateInitHp = self._player._fortress._hp
        self._opponent._fortress._updateInitHp = self._opponent._fortress._hp
    end

	self._playerUi:forward()
	self._opponentUi:forward()
    
    self:updateRound()
    --self:updateScoreDamage()

	local player = self._player:getActionPlayer()
    if self._player._isFinished or self._opponent._isFinished then
        self:finish()
        return self:sendBattleEnd()
    end

    player:step()
end

function _M:forwardToCurRound()
    self._player:beginForward()
    self._opponent:beginForward()
    
    self:startBattle()
    
    self._player:endForward()
    self._opponent:endForward()

    self._playerUi:forward()
    self._opponentUi:forward()
    
    self:updateRound()
    --self:updateScoreDamage()
    
    local player = self._player:getActionPlayer()
    
    if self._player._isFinished or self._opponent._isFinished then
        self:finish()
        return self:sendBattleEnd()
    end

    player:step()
end

-----------------------------------
-- handle battle event
-----------------------------------

function _M:initialDeal(player, delay)
    self:resetWhenInitialDeal()

    self:showDialog(BattleDialog.Type.initial_deal)
    return 0.6
end

function _M:initialDealChooseMain(player)
    if self._playerUi._player == player then
        self._playerUi:showChoiceInitialMonstersMain(player:getBattleCardsByLevel('H', 0))
    else
        if player._playerType == BattleData.PlayerType.opponent then
            self:waitOppoUseCard()
        else
            local type, ids = player._ai:aiChooseMainWhenInitialDeal()
            self._opponentUi:sendEvent(self._playerUi.EventType.send_use_card, {_type = type, _ids = ids})
        end
    end
end

function _M:initialDealChooseBackup(player)
    if self._playerUi._player == player then
        self._playerUi:showChoiceInitialMonstersBackup(player:getBattleCardsByLevel('H', 0, Data.CARD_MAX_LEVEL, player._boardCards[1]))
    else
        if player._playerType == BattleData.PlayerType.opponent then
            self:waitOppoUseCard()
        else
            local type, ids = player._ai:aiChooseBackupWhenInitialDeal()
            self._opponentUi:sendEvent(self._playerUi.EventType.send_use_card, {_type = type, _ids = ids})
        end
    end
end

function _M:roundEndChooseMain(player)
    if self._playerUi._player == player then
        self._playerUi:showChoiceSelectMain(player:getBattleCards('B'))
    else
        if player._type == BattleData.PlayerType.opponent then
            self:waitOppoUseCard()
        else
            local type, ids = player._ai:aiChooseMainWhenRoundEnd()
            self._opponentUi:sendEvent(self._playerUi.EventType.send_use_card, {_type = type, _ids = ids})
        end
    end
end

function _M:roundBegin(player, delay)
    local playerUi = (player._isAttacker == self._isAttacker) and self._playerUi or self._opponentUi
    
    -- reset
    self:resetWhenRoundBegin()
    playerUi:roundBegin()
    
    -- show dialog
    if player._round == 0 then
        delay = 0.2
    else
        local pvpDelay = 0
        --[[
        if player._enhanceLevel == -1 and player._round == 5 then
            pvpDelay = 1.5
            local bones = DragonBones.create("szsj")
            bones:gotoAndPlay("effect")
            bones:runAction(lc.sequence(bones:getAnimationDuration("effect"), lc.remove()))
            lc.addChildToPos(self._layer, bones, cc.p(lc.w(self) / 2, lc.h(self) / 2 + 50), BattleScene.ZOrder.dialog + 1)
        end
        ]]

        if player._isAttacker and player._round >= (player._maxRound - 5) then
            if player._maxRound - player._round >= 0 then
                performWithDelay(self, function() self:showDialog(BattleDialog.Type.remain_round, player._maxRound - player._round) end, pvpDelay)
            end
        else
            performWithDelay(self, function() self:showDialog(player._isAttacker == self._isAttacker and BattleDialog.Type.your_round or BattleDialog.Type.oppo_round) end, pvpDelay)
        end
        delay = 0.6 + pvpDelay
    end

    if self._battleType == Data.BattleType.PVP_room then
        if player._round == 1 then
            if self._exchangeDialog == nil then
                self._exchangeDialog = self:showDialog(BattleDialog.Type.exchange)
            end
        else
            if self._exchangeDialog ~= nil then
                self._exchangeDialog:removeFromParent()
                self._exchangeDialog = nil
            end
            
        end
    end
    
    return delay
end

function _M:roundEnd(player, delay)
    local playerUi = (player._isAttacker == self._isAttacker) and self._playerUi or self._opponentUi
    
    delay = playerUi:roundEnd(delay)

    if (not self._isTesting) and P._guideID < 100 then
        P._guideID = P._guideID + 1
        ClientData.sendGuideID(P._guideID)
    end
    
    return delay
end

function _M:action(player)
    local playerUi = (player._isAttacker == self._isAttacker) and self._playerUi or self._opponentUi
    
    playerUi:action()
end

function _M:onBattleEvent(event)
    local player = event._sender
    if player ~= self._player and player ~= self._opponent then return end

    if self._statusScheduler ~= nil then
        lc.Scheduler:unscheduleScriptEntry(self._statusScheduler)
        self._statusScheduler = nil
    end

    local type = event._type
    local param = event._param
    local arrayParam = event._arrayParam

    local card = player._actionCard
    local playerUi = (player._isAttacker == self._isAttacker) and self._playerUi or self._opponentUi
    local cardOwnerUi = card ~= nil and (card._owner._isAttacker == self._isAttacker and self._playerUi or self._opponentUi) or nil
    local delay = 0

    -- macro status
  
    -- battle end
    if type == BattleData.Status.battle_start then
        delay = self:start(delay)
    elseif type == BattleData.Status.battle_end then
        delay = self:finish()
    elseif type == BattleData.Status.round_begin then
        delay = self:roundBegin(player, delay)
        delay = playerUi:accountAction(delay, type, card)
    elseif type == BattleData.Status.round_end then
        local needDelay = #player:getUnderChangedCards() > 0
        delay = self:roundEnd(player, delay)
        delay = playerUi:accountAction(delay, type, card)
        if needDelay then
            delay = delay + 0.5
        end
    elseif type == BattleData.Status.deal then
        -- deal card begin
        playerUi:updatePower()
    elseif type == BattleData.Status.use then
        -- use card
        self._playerUi:updateBoardCardsActive()
        self._opponentUi:updateBoardCardsActive()
    elseif type == BattleData.Status.action then
        self:action(player)
        -- action begin
    elseif type == BattleData.Status.initial_deal then
        if player._initialDealIndex == 1 then
            delay = self:initialDeal(player, delay)
        elseif player._initialDealIndex == 3 then
            return self:initialDealChooseMain(player)
        elseif player._initialDealIndex == 4 then
            return self:initialDealChooseBackup(player)
        elseif player._initialDealIndex == 5 then
            delay = delay + 3
        end
    elseif type == BattleData.Status.select_main then
        return self:roundEndChooseMain(player)
    
    -- normal status
    elseif type == BattleData.Status.spelling or 
            type == BattleData.Status.under_spell or 
            type == BattleData.Status.under_defend_spell or 
            type == BattleData.Status.under_spell_damage or 
            type == BattleData.Status.under_counter_spell or 
            type == BattleData.Status.account_spell or 
            type == BattleData.Status.after_spell or
            type == BattleData.Status.end_spell then
        delay = playerUi:accountAction(delay, type, card)
    
    elseif type == BattleData.Status.account_status then
        delay = cardOwnerUi:accountStatus(card, delay) 
    elseif type == BattleData.Status.account_reorder then
        delay = playerUi:accountReorder(delay)
    elseif type == BattleData.Status.account_pos_change then
        delay = playerUi:accountPosChange(delay)
    elseif type == BattleData.Status.account_halo then
        delay = playerUi:accountHalo(delay, type, card)
        delay = playerUi:accountAction(delay, type, card)
    elseif type == BattleData.Status.account_event then
        delay = playerUi:accountEvent(delay)
        if delay == nil then return end
    
    -- use card
    elseif type == BattleData.Status.try_use_card then
        return self:tryUseCard(player)
    elseif type == BattleData.Status.wait_oppo_use_card then
        return self:waitOppoUseCard(player)
    elseif type == BattleData.Status.wait_observe_use_card then
        return self:waitObserveUseCard(player)
    elseif type == BattleData.Status.send_battle_end then
        return self:sendBattleEnd()    
    
    elseif type == BattleData.Status.use_card then
        local useCardType = param
        local ids = arrayParam

        if useCardType ~= BattleData.UseCardType.round then
            self:addBoardCardBegan(player)
            delay = self:prepareAction(player, card)
        else
            if self._isOnlinePvp then
                self:stopPvpTiming()
                self:removePvpTimingRope()
            end
        end

        if self._needSendEvent then
            if player._playerType == BattleData.PlayerType.player then
                ClientData.sendBattleUseCard(player, useCardType, ids) 
            elseif player._playerType == BattleData.PlayerType.opponent then
            elseif player._playerType == BattleData.PlayerType.ai then
                ClientData.sendBattleOppoUseCard(player, useCardType, ids)
            end
        end
    
    -- score
    elseif type == BattleData.Status.update_score_damage then
        if player._isAttacker then
            --self:updateScoreDamage()
        end

    elseif type == BattleData.Status.update_score_destroy_card then    
        --[[local key = 'R'..math.max(player._round, player._opponent._round)
        local count = player._destroyCardScore[key]
        if player._isAttacker and count ~= nil and count > 1 
        end]]

    -- fortress skill
    elseif type == BattleData.Status.change_fortress_skill then
        playerUi:updateFortressSkill()

    -- pvp timing
    elseif type == BattleData.Status.pvp_timing_begin then
        --TODO
        --self:pvpTimingWhenRoundBegin(player)

    end

    -- scheduler
    self._battleEvent = {}
    self._battleEvent._type = event._type
    self._battleEvent._sender = event._sender
    self._statusScheduler = lc.Scheduler:scheduleScriptFunc(function(dt) self:onBattleEventFinished() end, delay or 0, false)
end

function _M:onBattleEventFinished()
    if self._statusScheduler ~= nil then
        lc.Scheduler:unscheduleScriptEntry(self._statusScheduler)
        self._statusScheduler = nil
    end
    
    local player = self._battleEvent._sender
    
    return player:step()
end

-----------------------------------
-- use card status
-----------------------------------

function _M:tryUseCard(player)
    if not self._isEndAllOperation then
        self._isEndAllOperation = self._nameTag == 'normal' and self._playerUi:getIsEndAllOperation() or false
        
        if self._isEndAllOperation then
            -- skip button
            --[[
            if (not self._btnSkip:isVisible()) and (self._baseBattleType == Data.BattleType.base_PVE) then
                self._btnSkip:setVisible(not self:isGuideWorldBattle())
            end
            --]]
            
            --  auto
            if (not self._isAuto) and (self._baseBattleType ~= Data.BattleType.base_replay) then
                self._isAuto = true
                self._isAutoAuto = true
                self:setBtnAuto(self._isAuto)
            end
        end
        
    elseif self._isAutoAuto then
        self._isEndAllOperation = self._playerUi:getIsEndAllOperation()
        
        if (not self._isEndAllOperation) then
            self._isAuto = false
            self._isAutoAuto = false
            self:setBtnAuto(self._isAuto)
        end
    end

    if player._isMonsterActioned then
        local usedCard, targetCard, choice = player._ai:aiUseCard()
        return player:doUseCard(usedCard, targetCard, choice)
    end

    if player._boardCards[1] == nil then
        return self._playerUi:showChoiceSwapMonsters(player:getBattleCards('B'), true)
    end
    
    if self._isAuto then
        local usedCard, targetCard, choice = player._ai:aiUseCard()
        return player:doUseCard(usedCard, targetCard, choice)

    elseif self._isPvpTimeout then
        if player:isNeedDrop() then
            local type ids = player._ai:aiDropCard()
            return player:doUseCard(type, ids)
        else
            return player:doUseCard()
        end

    else
        if self._isOperating then
            self:addBoardCardEnded(player)
        else
            self:operateBegin()
        end

        if self._isEnableDrap then
            local player = self._player:getActionPlayer()
            if player:isNeedDrop() then
                self:showDropHand()
            else
                self:finishDropHand()
            end
        end
    end
end

function _M:waitOppoUseCard(player)
    self._isWaitting = true
    if not self:oppoTryUseCard() then
        self:showThinking()
    end
end

function _M:waitObserveUseCard()
    self._isWaitting = true
    if not self:observeTryUseCard() then
        self:showThinking()
    end
end

function _M:operateBegin()
    if self._isOperating then return end
    
    local player = self._player
    local playerUi = self._playerUi

    self._isOperating = true
    
    playerUi:updateCardsActive()
    self:updateRoundButton()
    
    --soft guide
    if self._needSoftGuide then
        self:addSoftGuide()
    end
end

function _M:operateEnd()
    if not self._isOperating then return end
    
    local player = self._player
    
    self._isOperating = false
    self._isEndOperating = true
    
    if self._isTouching then
        self:onTouchCanceled(true)
    end
    if self._dropLayer then
        self:hideDropHand()
    end
    if self._choiceMaskLayer then
        self._choiceMaskLayer:cancelChoice()
    end

    --[[if self._playerUi._touchCard ~= nil then
        local pCard = self._playerUi._touchCard
        self:hidePreview(pCard)
        pCard:onTouchEnded()
        self._playerUi._touchCard = nil
        self._playerUi:playAction(pCard, self._playerUi.Action.replace_hand_card, 0, 1)
    end]]
    self._playerUi:updateCardsActive()
    self:updateRoundButton()
    
    self:removeExchangeArrow()
    self:removeSoftGuide()
    
    -- time out: auto button
    if self._timeOutTimes >= 3 and (not self._isAuto) then
        self._timeOutTimes = 0
        self._isAuto = true
        
        self:setBtnAuto(self._isAuto)
    end
    
    if not self._isAddingBoardCard then
        if self._isAuto then
            return self:tryUseCard(self._player)
        elseif self._isPvpTimeout then
            return self:tryUseCard(self._player)
        else
            return self._player:doUseCard(BattleData.UseCardType.round, {self._player._round})
        end
    end
end

function _M:autoOperate(isAuto)
    self._isAuto = isAuto

    if isAuto then
        if self._isOperating then
            self:operateEnd()
        end
    else
        if self._isAddingBoardCard then
            self:operateBegin()
        end
    end

    self:setBtnAuto(self._isAuto)
end

function _M:addBoardCardBegan(player)
    if not self._isOperating then return end
    
    local playerUi = player._isAttacker == self._isAttacker and self._playerUi or self._opponentUi
    
    self._isAddingBoardCard = true
    
    playerUi:updateCardsActive()
    
    self:updateRoundButton()
    
    -- soft guide
    if self._needSoftGuide then
        self:removeSoftGuide()
    end
end

function _M:addBoardCardEnded(player)
    if not self._isAddingBoardCard then return end
    
    local playerUi = player._isAttacker == self._isAttacker and self._playerUi or self._opponentUi
    
    self._isAddingBoardCard = false
    
    playerUi:updateCardsActive()
    self:updateRoundButton()
    
    if self._isOperating then
        if self._needSoftGuide then
            self:addSoftGuide()
        end
    end
end

function _M:setOppoOnline(needShowDialog)    
    needShowDialog = needShowDialog and (not self._isBattleFinished)

    if ClientData._isOppoOnline then
        if needShowDialog then
            self:showOppoOnline()
        end
    else        
        if needShowDialog then
            self:showOppoOffline()
        end

        if self._battleType == Data.BattleType.PVP_friend and self._isWaitting then
            self._isWaitting = false
            self:hideThinking()
            self._opponent:use()
        end
    end
end

function _M:setPlayerOnline(needShowDialog)    
    needShowDialog = needShowDialog and (not self._isBattleFinished)

    if ClientData._isPlayerOnline then
        if needShowDialog then
            self:showPlayerOnline()
        end
    else        
        if needShowDialog then
            self:showPlayerOffline()
        end
    end
end

-----------------------------------
-- handle events
-----------------------------------

function _M:onButtonEvent(sender)

    if sender == self._btnReturn then
        self:tryExitScene()

    elseif sender == self._btnEndRound then
        --[[
        if self:isGuideWorldBattle(10101) and (self._guide10101Round == nil or self._guide10101Round < self._player._round) then
            self._guide10101Round = self._player._round
            if self._player:canUseHandCard() then
                self:showTip{t = {story = 201, touch = 1, left = 1}}
                return
            end
        end
        ]]

        local player = self._player:getActionPlayer()
        if player:isNeedDrop() then
            self:showDropHand()
        else
            self._timeOutTimes = 0
            self:operateEnd()

            self:hideTip()
            self:setGuideHelpButtonVisible(false)
        end

    elseif sender == self._btnSpeed then
        local playerLevel, playerVip = P._id ~= 0 and P:getMaxCharacterLevel() or self._player._level, P._vip or self._player._vip
        local speed = self._battleSpeed

        if self._baseBattleType == Data.BattleType.base_replay then
            speed = (speed == 4 and 1 or (speed + 1))

        else
            if speed == 1 and (playerLevel < Data._globalInfo._2xSpeedLevel and playerVip < Data._globalInfo._2xSpeedVip) then
                ToastManager.push(string.format(Str(STR.LORD_UNLOCK_LEVEL), Data._globalInfo._2xSpeedLevel)..Str(STR.BATTLE_SPEED_2X))

            elseif speed == 2 and (playerLevel < Data._globalInfo._3xSpeedLevel and playerVip < Data._globalInfo._3xSpeedVip) then
                ToastManager.push(string.format(Str(STR.LORD_UNLOCK_LEVEL), Data._globalInfo._3xSpeedLevel)..Str(STR.BATTLE_SPEED_3X))
                speed = 1

            else
                speed = (speed == 3 and 1 or (speed + 1))
            end
        end

        self:setBattleSpeed(speed)
        self:updatePvpTimingRope()
    
    elseif sender == self._btnReplay then
        self._isPaused = (not self._isPaused)
        if self._isPaused then
            self:pause()
            self._btnReplay._icon:setSpriteFrame("bat_btn_icon_play")
            --self._btnReplay._title:setString(Str(STR.RESUME))
        else
            self:resume()
            self._btnReplay._icon:setSpriteFrame("bat_btn_icon_pause")
            --self._btnReplay._title:setString(Str(STR.PAUSE))
        end

    elseif sender == self._btnAuto then
        local playerLevel, validLevel = P._id ~= 0 and P:getMaxCharacterLevel() or self._player._level, 10
        if playerLevel < validLevel then
            local str = string.format(Str(STR.LORD_UNLOCK_LEVEL), validLevel)..Str(STR.BATTLE_AUTO)
            ToastManager.push(str)
        else
            self._autoConfig = not self._autoConfig
            self:autoOperate(not self._isAuto)
        end

    elseif sender == self._btnSetting then
        if self._settingLayer == nil then
            self:showSetting()
        else
            self:hideSetting()
        end

    elseif sender == self._btnMusic then
        ClientData.toggleAudio(lc.Audio.Behavior.music, not ClientData._isMusicOn)

        self._btnMusic._icon:setString(Str(ClientData._isMusicOn and STR.ON or STR.OFF))
        self._btnMusic:loadTextureNormal(ClientData._isMusicOn and "bat_btn_2" or "bat_btn_3", ccui.TextureResType.plistType)

    elseif sender == self._btnSndEffect then
        ClientData.toggleAudio(lc.Audio.Behavior.effect, not ClientData._isEffectOn)

        self._btnSndEffect._icon:setString(Str(ClientData._isEffectOn and STR.ON or STR.OFF))
        self._btnSndEffect:loadTextureNormal(ClientData._isEffectOn and "bat_btn_2" or "bat_btn_3", ccui.TextureResType.plistType)

        if not ClientData._isEffectOn then
            cc.SimpleAudioEngine:getInstance():stopAllEffects()
        end

    elseif sender == self._btnRetreat then
        self:hideSetting()
        self:showRetreat()

    elseif sender == self._btnHelp then
        self:hideSetting()
        require("BattleHelpForm").create():show()

    elseif sender == self._btnGuideHelp then
        if self._guideTipVals then
            self._guideTipVals.t.touch = 1
            if self._guideTipVals.t.hl_type == GuideManager.HighlightType.battle_skill then
                self._guideTipVals.t.hl_type = nil
            end
            self:showTip(self._guideTipVals)
        end
        
    elseif sender == self._btnTask then
        self:hideSetting()
        self:showTask()
    
    --[[
    elseif sender == self._btnChat then
        self:showChat()
    ]]

    elseif sender == self._btnLayout then
        self:hideTestProgress()
        self:setLoadRelativeButtonsVisbile(false)
        ClientData._unitTestFile = nil
        lc.pushScene(require("BattleTestScene").create(self._scene))

    elseif sender == self._btnLoad then
        self:hideTestProgress()
        local filename = lc.App:getOpenFileName()
        if filename ~= nil and filename ~= '' then
            ClientData._unitTestFile = nil
            ClientData._battleDebugLog = ""
            BattleTestData._curOpType = BattleTestData.OperationType._load
            BattleTestData._singleFileName = filename
            BattleTestData.resetUsedCards()
            self:loadUnitTestFile(filename)
        end

    elseif sender == self._btnBatch then
--        local filename = lc.App:getSaveFileName()
--        print (filename)
        self:showTestProgress()
        self:setLoadRelativeButtonsVisbile(false)
        
        local filename = lc.App:getOpenFileName()

        if filename ~= nil and filename ~= "" then
            ClientData._unitTestFile = nil
            local index = string.find(string.reverse(filename), "\\")
            local folder = string.sub(filename, 1, #filename - index + 1)
            local result = io.popen("dir \"" .. folder .. "\"")
            local resStr = result:read("*all")
            BattleTestData._batch._filenames = self:parseFileList(resStr, folder)

            BattleTestData._batch._batchCount = #BattleTestData._batch._filenames
            BattleTestData._batch._callback = function() self:startBatchSingle() end
            self:startBatchSingle()
        end

    elseif sender == self._btnRunFree then
        self:hideTestProgress()
        self._testMaskLayer:setVisible(false)
        self._player._playerType = BattleData.PlayerType.player

    elseif sender == self._btnRunTest then
        if ClientData._unitTestFile == BattleTestData.DEFAULT_FILE then
            ToastManager.push("EXPORT FIRST")
        else
            self:hideTestProgress()
            BattleTestData._curOpType = BattleTestData.OperationType._runTest
            self._testMaskLayer:setVisible(false)
            self._player._playerType = BattleData.PlayerType.ai
            self._player:step()
        end


    elseif sender == self._btnExport then
        self:hideTestProgress()
        self:onExportUnitTestData() 

    elseif sender == self._btnSwitchView then
        self:reverse()

    end
end

function _M:onSwitchView()
    self._isReverse = not self._isReverse
        
        self:hideResult()
    
        self._playerUi:efcFortressDieRemove()
        self._opponentUi:efcFortressDieRemove()

        self:resetBattle()
    
        self._playerUi:resetWhenBattleStart()
        self._opponentUi:resetWhenBattleStart()
        self:resetWhenBattleStart()
    
        self:setBattleSpeed()

        self._playerUi:clear()
        self._opponentUi:clear()

        local player = self._input._player
        self._input._player = self._input._opponent
        self._input._opponent = player
        self:initData(self._input)


        self._playerUi = PlayerUi.new(self, self._player, self._sceneType, self._input._player._cardBackId)
        self._opponentUi = PlayerUi.new(self, self._opponent, self._sceneType, self._input._opponent._cardBackId)
        self._playerUi._opponentUi = self._opponentUi
        self._opponentUi._opponentUi = self._playerUi

        self._playerUi:resetWhenBattleStart()
        self._opponentUi:resetWhenBattleStart()
        self:resetWhenBattleStart()

        self:startBattle()

        self._scene:seenByCamera3D(self)
end

function _M:addChild(child, zOrder, tag)
    if zOrder then
        cc.Node.addChild(self, child, zOrder)
    elseif tag then
        cc.Node.addChild(self, child, zOrder, tag)
    else
        cc.Node.addChild(self, child)
    end
    local scale = child:getScaleY()
    if child.setFlippedY then
        child:setFlippedY(self._isReverse)
    elseif self._isReverse and scale > 0 then
        child:setScaleY(-scale)
    end
end

function _M:tryExitScene()
    if ClientData._replayInBattle then
        ClientData._replayInBattle = false
        self._isBattleFinished = true

        self._battleType = ClientData._replayInBattleType
        self._baseBattleType = Data.BattleType.base_PVE

        local dialog = BattleResultDialog.create(self, BattleResultDialog.Type.battle_result, {_resultType = Data.BattleResult.lose})
        self._scene:addChild(dialog, BattleScene.ZOrder.form)
        self._resultDialog = dialog

        self:hideSetting()
        self:pause()

    else
        self:exitScene()
    end
end

function _M:reverse()
    self._isReverse = not self._isReverse
    self:setFlippedY(self._isReverse)
    local rot = self:getRotation3D()
--    self:setRotation3D({x = 180 - rot.x, y = rot.y, z = rot.z})
    self._playerUi:reverse(self._isReverse)
    self._opponentUi:reverse(self._isReverse)
    for i, child in ipairs(self:getChildren()) do
--        child:setPositionY(V.SCR_H - lc.y(child))
        if child.setFlippedY then
            child:setFlippedY(self._isReverse)
        end
--        if child.getRotation3D then
--            local rot = child:getRotation3D()
--            if child._default and child._default._rotation then
--                rot = child._default._rotation
--                child._default._rotation = {x = -rot.x, y = rot.y, z = rot.z}
--            end
--            child:setRotation3D({x = -rot.x, y = rot.y, z = rot.z})
--        end
    end

    self._playerUi:updateHandCardsPos()
    self._playerUi:updateBoardCardsPos()
    self._opponentUi:updateHandCardsPos()
    self._opponentUi:updateBoardCardsPos()

    if self._playerUi._hideHandCards ~= self._opponentUi._hideHandCards then
        self._playerUi:hideHandCards()
        self._opponentUi:hideHandCards()
    end

    self:reverseThinking()
end

function _M:onPlayerUiEvent(event)
    local playerUi = event._sender
    if playerUi._battleUi ~= self then return end

    local player = playerUi._player
    local type = event._type
    local val = event._val

    -- show dialog event
    if type == PlayerUi.EventType.dialog_defender_hand_cards then
        self:showDialog(BattleDialog.Type.defender_hand_cards)

    elseif type == PlayerUi.EventType.dialog_attacker_hand_cards then
        self:showDialog(BattleDialog.Type.attacker_hand_cards)

    elseif type == PlayerUi.EventType.dialog_not_enough_gem then
        self:showDialog(BattleDialog.Type.not_enough_gem)

    elseif type == PlayerUi.EventType.dialog_board_card_full then
        self:showDialog(BattleDialog.Type.board_card_full)

    elseif type == PlayerUi.EventType.dialog_not_your_round then
        self:showDialog(BattleDialog.Type.not_your_round)

    elseif type == PlayerUi.EventType.dialog_card_need_aim then
        self:showDialog(BattleDialog.Type.card_need_aim, val)

    elseif type == PlayerUi.EventType.dialog_card_need_target then
        self:showDialog(BattleDialog.Type.card_need_target)

    elseif type == PlayerUi.EventType.dialog_cannot_effect then
        self:showDialog(BattleDialog.Type.cannot_effect, val)

    elseif type == PlayerUi.EventType.dialog_special_summon_invalid then
        self:showDialog(BattleDialog.Type.special_summon_invalid)

    elseif type == PlayerUi.EventType.dialog_trap_existed then
        self:showDialog(BattleDialog.Type.trap_existed, val)
    
    elseif type == PlayerUi.EventType.dialog_adding_board_card then
        self:showDialog(BattleDialog.Type.adding_board_card)

    elseif type == PlayerUi.EventType.dialog_target_unattackable then
        self:showDialog(BattleDialog.Type.target_unattackable)
    
    elseif type == PlayerUi.EventType.dialog_cannot_attack then
        self:showDialog(BattleDialog.Type.cannot_attack)

    -- screen event
    elseif type == PlayerUi.EventType.efc_screen_fortress_die then
        self:shakeScreen(_M.ShakeScreenType.fortress_die, playerUi, val or {})

    elseif type == PlayerUi.EventType.efc_screen_fortress_hurt then
        self:shakeScreen(_M.ShakeScreenType.fortress_hurt, playerUi, val or {})

    elseif type == PlayerUi.EventType.efc_screen_to_board then
        self:shakeScreen(_M.ShakeScreenType.to_board, playerUi, val or {})
    
    elseif type == PlayerUi.EventType.efc_screen_equip_book then
        self:shakeScreen(_M.ShakeScreenType.equip_book, playerUi, val or {})
    
    elseif type == PlayerUi.EventType.efc_screen_attack_card then
        self:shakeScreen(_M.ShakeScreenType.attack_card, playerUi, val or {})
    
    elseif type == PlayerUi.EventType.efc_camera_to then
        self:cameraTo(event._val._isAttacker, event._val._delayTime)

        -- update ui control event    
    elseif type == PlayerUi.EventType.update_card_pile_count then
        self:updatePile(playerUi)

    elseif type == PlayerUi.EventType.send_use_card then
        player:doUseCard(val._type, val._ids)
    end
end

function _M:onCardSpriteEvent(event)
    local pCard = event._sender
    local card = pCard._card
    if pCard._battleUi ~= self then return end

    local type = event._type
    local val = event._val

    if type == CardSprite.EventType.show_card_info then
        if pCard._mask ~= nil then
            self:showCardInfo(pCard, pCard._mask._card)
        else
            if self._showingAttackCard then
            elseif pCard._ownerUi._isController and pCard._card._status == BattleData.CardStatus.board then
                self:showCardAttack(pCard)
            else
                self:showCardInfo(pCard, pCard._card)
            end
        end

    elseif type == CardSprite.EventType.hide_card_info then
        self:hideCardInfo()

    elseif type == CardSprite.EventType.show_grave_list then
        local cards = pCard._card._owner._graveCards

        local cardSprite = self._playerUi:getCardSprite(cards[1]) or self._playerUi._opponentUi:getCardSprite(cards[1])
        
        BattleListDialog.create(self, cards, BattleListDialog.Mode.list, lc.str(STR.BATTLE_GRAVE)):show()

    end
end

-----------------------------------
-- handle button event
-----------------------------------

function _M:softGuide()
    self:removeSoftGuide()
    
    local bones = nil
    local usedCard, targetCard, choice = self._player._ai:aiUseCard()
    if usedCard == nil then
        local pos = self._layer:convertToNodeSpace(self._btnEndRound:convertToWorldSpace(cc.p(54, 40)))
        print(pos.x, pos.y)
        bones = self:createDragonBones("jiantou", pos, self._layer, "tap", false, 2.0, BattleUi.ZOrder.effect)
        
    elseif usedCard._status == BattleData.CardStatus.hand then
        local pos = cc.p(self._playerUi._pHandCards[usedCard._pos]._default._position.x, 100)
        bones = self._playerUi:efcDragonBones(nil, "jiantou", pos, false, false, "drag", 2.0)
    end
    
    self._softGuideLayer = bones
end

function _M:addSoftGuide(time)
    self:removeSoftGuide()
    
    if self._battleType == Data.BattleType.teach then return end

    time = (P._level <= 3 and 3 or (P._level <= 5 and 5 or 10)) * cc.Director:getInstance():getScheduler():getTimeScale()
   
    self._softGuideScheduler = lc.Scheduler:scheduleScriptFunc(function(dt) self:softGuide() end, time, false)
end

function _M:removeSoftGuide()
    if self._softGuideScheduler ~= nil then
        lc.Scheduler:unscheduleScriptEntry(self._softGuideScheduler)
        self._softGuideScheduler = nil
    end
    
    if self._softGuideLayer ~= nil then
        self._softGuideLayer:removeFromParent()
        self._softGuideLayer = nil
    end
end

function _M:addChat(player, str)
    if player._isAttacker == self._isAttacker then
        self:showDialog(BattleDialog.Type.chat_dialog, str)
    else
        self:showDialog(BattleDialog.Type.oppo_chat_dialog, str)
    end
    
    --[[local chatInfo
    for _, info in pairs(Data._pvpChatInfo) do        
        if str == Str(info._nameSid) then
            chatInfo = info
            break
        end
    end
    
    if chatInfo then
        local isMale = true
        if player._avatar and player._avatar then
            local info = Data.getInfo(player._avatar)
            if info then
                isMale = (info._gender == 1)
            end 
        end
        
        self._audioEngine:playEffect(isMale and chatInfo._voice1 or chatInfo._voice2)
    end]]
end

-----------------------------------
-- function for data
-----------------------------------

function _M:changeResource(result)
    local resultType = result._resultType
    local isWin = resultType == Data.BattleResult.win
    
    -- remove grain
    if self._baseBattleType == Data.BattleType.base_PVE then
        if self._battleType == Data.BattleType.expedition_ex then
            if ClientData._expeditionNpcInfos[ClientData._expeditionCurNpc]._challengeCount == 0 then
                local costs = {Data._globalInfo._expeditionSimpleNPCCost, Data._globalInfo._expeditionMediumNPCCost, Data._globalInfo._expeditionHardNPCCost}
                P:changeResource(Data.ResType.gold, -costs[ClientData._expeditionNpcInfos[ClientData._expeditionCurNpc]._level + 1])
            end

        else
            if not self:isGuideWorldBattle() or isWin then
                local cost = P:getBattleCost(nil, resultType == Data.BattleResult.lose, self._input._levelId)
                P:changeResource(Data.ResType.grain, -cost)
            end
        end
    end

    if self._battleType == Data.BattleType.PVP_room then
        local members = P._playerRoom:getMyRoom()._members
        for i = 1, 3 do
            local member = members[i]
            if member and member._idInRoom == self._player._idInRoom then
                member._win = member._win + (isWin and 1 or 0)
            elseif member and member._idInRoom == self._opponent._idInRoom then
                member._win = member._win + (isWin and 0 or 1)
            end
        end
    end
    
    -- add resource
    local character = P._characters[P:getCharacterId()]
    result._preExp = character._exp
    result._preLevel = character._level
    P:changeExp(result._exp, result._timestamp / 1000)
    result._curExp = character._exp
    result._curLevel = character._level

    P:changeResource(Data.ResType.gold, result._gold)
    P:changeResource(Data.ResType.grain, result._grain)
    P:changeResource(Data.ResType.ingot, result._ingot)

    local isClash = (self._battleType == Data.BattleType.PVP_clash or self._battleType == Data.BattleType.PVP_clash_npc)
    if result._trophy then
        local trophy = isWin and result._trophy or -result._trophy
        if isClash then
            P._playerFindClash:changeTrophy(trophy)

        else
            P:changeTrophy(trophy)
            P._dailyTrophy = P._dailyTrophy + trophy
        end
    end

    if result._unionBattleTrophy then
        P:changeResource(Data.ResType.union_battle_trophy, result._unionBattleTrophy)
    end

    if result._darkTrophy then
        P:changeResource(Data.ResType.dark_trophy, result._darkTrophy)
    end
    
    if result._yubi then
        P._propBag:changeProps(Data.PropsId.yubi, result._yubi)
    end

    if result._activePoint then
        P:changeResource(Data.ResType.union_personal_power, result._activePoint)
    end

    if result._loseSkinCrystal then
        P._propBag:changeProps(Data.PropsId.skin_crystal, result._loseSkinCrystal)
    end

    if result._ladderChest then
        P._playerFindLadder:changeChest(result._ladderChest)
    end

    -- add card
    local infoIds = {}
    local counts = {}
    local levels = {}
    local isFragments = {}
    for _, card in ipairs(result._cards) do
        table.insert(infoIds, card._infoId)
        table.insert(counts, card._count)
        table.insert(levels, card._level)
        table.insert(isFragments, card._isFragment)
    end
    P:addResources(infoIds, levels, counts, isFragments)
    
    -- add log
    if result._logPb then
        local logType, isAttacker
        if self._battleType == Data.BattleType.PVP_clash or self._battleType == Data.BattleType.PVP_clash_npc then
            logType = Battle_pb.PB_BATTLE_WORLD_LADDER
        else
            logType = Battle_pb.PB_BATTLE_PLAYER
            isAttacker = true
        end
        
        local log = require("Log").new(isAttacker, result._logPb)
        P._playerLog:addLog(log, logType)
        P._playerLog:sendLogDirty(require("PlayerLog").Event.attack_log_dirty)
        result._log = log
    end
    
    if isWin then
        local copyId = self._input._copyId

        if self._battleType == Data.BattleType.task then
--            P._playerAchieve:dailyTaskDone(Data.DailyTaskType.city_battle_win)

        elseif self._battleType == Data.BattleType.PVP_clash or self._battleType == Data.BattleType.PVP_clash_npc then
            --P._playerAchieve:activityTaskDone(Data._activityTaskInfo._pvp._id)            

        end

        if copyId and copyId > 0 then
            P._copyPassTimes[copyId] = P._copyPassTimes[copyId] + 1
        end
    end
    
    if isClash then
        if resultType == Data.BattleResult.win then
            if P._ladderContLose > 0 then
                P._dailyClashWin = 0
                P._ladderContWin = 0
            end
            P._dailyClashWin = P._dailyClashWin + 1
            P._ladderContWin = P._ladderContWin + 1
            P._ladderContLose = 0
        elseif resultType == Data.BattleResult.lose then
            P._ladderContLose = P._ladderContLose + 1
            if P._ladderContLose > 1 then -- do not change win count if just one lose
                P._dailyClashWin = 0
                P._ladderContWin = 0
            end
        end

    elseif self._battleType == Data.BattleType.PVP_ladder or self._battleType == Data.BattleType.PVP_ladder_npc then
        if resultType == Data.BattleResult.win then
            P._playerFindLadder._winCount = math.min(12, P._playerFindLadder._winCount + 1)
            P._playerFindClash._ladderTrophy = P._playerFindClash._ladderTrophy + Data._globalInfo._ladderExTrophy[P._playerFindLadder._winCount]
        elseif resultType == Data.BattleResult.lose then
            P._playerFindLadder._loseCount =  P._playerFindLadder._loseCount + 1
        end
    end
    
    -- unlock city, try change city status
    if self._battleType == Data.BattleType.task then
        if isWin then
            local taskDone = true
            for i = 1, #result._taskResult do
                if not result._taskResult[i] then
                    taskDone = false
                    break
                end
            end
            if taskDone then
                local levelId = self._input._levelId
                local difficulty = math.floor(levelId / 10000)
                local nextLevelId = levelId + 1
                if Data._levelInfo[nextLevelId] == nil then
                    nextLevelId = (math.floor(levelId / 100) + 1) * 100 + 1
                end
                P._playerWorld._curLevel[difficulty] = math.max(P._playerWorld._curLevel[difficulty], nextLevelId)

                local eventCustom = cc.EventCustom:new(Data.Event.chapter_level_dirty)
                eventCustom._levelId = levelId
                lc.Dispatcher:dispatchEvent(eventCustom)
            end
        else
            --[[
            if self:isGuideWorldBattle() then
                local userData = {cityChapterId = self._input._levelId}
                ClientData.sendUserEvent(userData)
            end
            ]]
        end
    end 
end

function _M:initResource(result)
    if result == nil then
        result = {_trophy = 0, _preRank = 0, _curRank = 0, _exp = 0, _gold = 0, _grain = 0, _ingot = 0, _cards = {}}
        result._resultType = self._player:getResult()
        self._result = result
    end

    result._preExp = 0
    result._curExp = 0
    result._exp = 0
    result._preLevel = self._player._level > 0 and self._player._level or 1
    result._curLevel = self._player._level > 0 and self._player._level or 1
    
    return result
end

function _M:onBattleEnd(resp)
    V.getActiveIndicator():hide()

    local respRes = resp.resource or {}
    local logPb
    if resp:HasField("log") then
        logPb = resp.log
    end

    local result = {_timestamp = resp.timestamp, _trophy = resp.trophy, _preRank = resp.rank1, _curRank = resp.rank2, _exp = 0, _gold = 0, _grain = 0, _ingot = 0, _cards = {}, _logPb = logPb, _levelId = resp.city}
    for i = 1, #respRes do
        local item = respRes[i]
        if item.info_id == Data.ResType.gold then result._gold = item.num
        elseif item.info_id == Data.ResType.grain then result._grain = item.num
        elseif item.info_id == Data.ResType.ingot then result._ingot = item.num
        elseif item.info_id == Data.ResType.exp or item.info_id == Data.ResType.character_exp then result._exp = item.num
        elseif item.info_id == Data.ResType.union_personal_power then
            result._activePoint = item.num  
        elseif item.info_id == Data.ResType.union_battle_trophy then
            result._unionBattleTrophy = item.num  
        elseif item.info_id == Data.ResType.dark_trophy then
            result._darkTrophy = item.num  
        elseif item.info_id == Data.PropsId.skin_crystal and item.num < 0 then
            result._loseSkinCrystal = item.num  
        elseif item.info_id == Data.PropsId.yubi then
            result._yubi = item.num   
        elseif item.info_id >= Data.PropsId.ladder_chest and item.info_id <= Data.PropsId.ladder_chest_end then
            result._ladderChest = item.info_id 
        else
            table.insert(result._cards, {_infoId = item.info_id, _count = item.num, _isFragment = item.is_fragment, _level = item.level})
            if item.info_id == Data.PropsId.flag then result._flag = item.num end
        end
    end

    --TODO RESULTYPE
    result._resultType = resp.type
    result._taskResult = resp.task_result
    result._expeditionResult = {_player = {[1] = resp.atk_expend.hero, [2] = resp.atk_expend.horse, [3] = resp.atk_expend.book}, 
        _opponent = {[1] = resp.def_expend.hero, [2] = resp.def_expend.horse, [3] = resp.def_expend.book}, }
    
    result._score = self._player._damageScore[PlayerBattle.KEY_TOTAL]
    if resp:HasField("score") then result._score = resp.score end

    result._battleType = self._battleType
    result._player = self._player
    result._opponent = self._opponent

    -- boss prop id
    if resp:HasField("param") then result._propId = resp.param end
    
    self:hideWaitting()
    if ((self._baseBattleType == Data.BattleType.base_PVP and self._battleType ~= Data.BattleType.PVP_friend) or self._baseBattleType == Data.BattleType.base_PVE) then
        self:changeResource(result)
    else
        self:initResource(result)
    end

    self._player:genResult(result._resultType)
    self._result = result
    self:showResult()
end

function _M:checkUnlockModule()
    if self._isTesting then return end
    local curLevel = P._level
    local prevLevel = lc.readConfig(ClientData.ConfigKey.lock_level_battle, curLevel)                

    local strs = {}
    if prevLevel < Data._globalInfo._2xSpeedLevel and curLevel >= Data._globalInfo._2xSpeedLevel then
        table.insert(strs, Str(STR.BATTLE_SPEED_2X)..Str(STR.UNLOCKED))
        lc.writeConfig(ClientData.ConfigKey.lock_level_battle, curLevel)
    elseif curLevel < Data._globalInfo._2xSpeedLevel then
        local curVIP = P._vip
        local prevVIP = lc.readConfig(ClientData.ConfigKey.lock_level_vip, curVIP)

        if prevVIP < Data._globalInfo._2xSpeedVip and curVIP >= Data._globalInfo._2xSpeedVip then
            table.insert(strs, Str(STR.BATTLE_SPEED_2X)..Str(STR.UNLOCKED))
            lc.writeConfig(ClientData.ConfigKey.lock_level_vip, curVIP)
        end        
    end

    if #strs > 0 then
        ToastManager.pushArray(strs)
    end
end

function _M:isGuideWorldBattle(index)
    return self._battleType == Data.BattleType.task and GuideManager.isGuideEnabled() and
            ((index and self._input._levelId == index) or (index == nil and self._input._levelId <= 10101))
end

function _M:oppoTryUseCard()
    if #ClientData._usedCardsToAdd > 0 then
        local ops = B.parseOperations(ClientData._usedCardsToAdd, false)
        for i = 1, #ops do
            table.insert(self._opponent._ops, ops[i])
        end
        ClientData._usedCardsToAdd = {}
    end

    if self._opponent._replayIndex > #self._opponent._ops then return false end

    local op = self._opponent._ops[self._opponent._replayIndex]
    local type, ids = op._type, op._ids
    if type == BattleData.UseCardType.retreat then
        self:hideThinking()
        self:retreat(self._opponent)
        return true
    end

    if self._isWaitting == false then return false end

    self._isWaitting = false
    self:hideThinking()

    if type == BattleData.UseCardType.init_b1 or type == BattleData.UseCardType.init_bx then
        self._opponent._replayIndex = self._opponent._replayIndex + 1
        self._opponent:useCard(type, ids)
    else
        self._opponent:use()
    end
    
    return true
end

function _M:observeTryUseCard()
    if not ClientData._observeUsedCards then ClientData._observeUsedCards = {} end

    if #ClientData._observeUsedCards > 0 then
        local ops = B.parseOperations(ClientData._observeUsedCards, false)
        for i = 1, #ops do
            table.insert(self._player._ops, ops[i])
        end
        ClientData._observeUsedCards = {}
    end
    
--    table.insert(self._player._ops, {_card=usedCard, _target=targetCard, _choice=usedChoice, _timestamp=ClientData.getCurrentTime()})
    
--    todo delete

    if self._player._replayIndex > #self._player._ops then return false end

    if self._player._ops[self._player._replayIndex]._type == BattleData.UseCardType.retreat then
        self:hideThinking()
        self:retreat(self._player)
        return true
    end

    if self._isWaitting == false then return false end

    self._isWaitting = false
    self:hideThinking()
    self._player:use()
    
    return true
end

-- score

function _M:updateScoreDamage()
    if self._scoreSchedulerID ~= nil then
        lc.Scheduler:unscheduleScriptEntry(self._scoreSchedulerID)
    end
    
    local interval = 0.05
    local value = self._player._damageScore[PlayerBattle.KEY_TOTAL]
    local label = self._score._label
    local icon = self._score._ico
    self._scoreSchedulerID = lc.Scheduler:scheduleScriptFunc(function(dt) 
        local isStop = true
        if value ~= label._value and label._value ~= nil then
            isStop = false
                
            local delta = (value - label._value) / 2
            if delta > 0 then     
                delta = math.ceil(delta)
            else
                delta = math.floor(delta)
            end
            label._value = label._value + delta
            if (value - label._value) * delta < 0 then
                label._value = value
            end
            label:setString(ClientData.formatNum(label._value, 9999999))
            
            if label:getNumberOfRunningActions() == 0 then                
                local scale = cc.EaseSineInOut:create(cc.ScaleBy:create(0.1, 1.2))
                label:runAction(cc.Sequence:create(scale, scale:reverse()))
            end
            if icon:getNumberOfRunningActions() == 0 then
                local scale = cc.EaseSineInOut:create(cc.ScaleBy:create(0.1, 1.2))
                icon:runAction(cc.Sequence:create(scale, scale:reverse()))                    
            end              
        end
        
        if isStop then
            if self._scoreSchedulerID ~= nil then
                lc.Scheduler:unscheduleScriptEntry(self._scoreSchedulerID)  
                self._scoreSchedulerID = nil  
            end
        end
    end, interval, false)
end

function _M:setBtnAuto(isAuto)
    self._btnAuto._title:setString(Str(isAuto and STR.MANUAL or STR.AUTO))

    self._btnAuto._icon:setSpriteFrame(isAuto and 'bat_btn_icon_auto' or 'bat_btn_icon_manual')

    --[[
    if self._btnAuto._autoBone ~= nil then
        self._btnAuto._autoBone:removeFromParent()
    end

    self._btnAuto._autoBone = DragonBones.create("zidongzhong")
    self._btnAuto._autoBone:setPosition(lc.w(self._btnAuto) / 2,lc.h(self._btnAuto) / 2)
    self._btnAuto._autoBone:gotoAndPlay(isAuto and "effect" or "effect2")
    self._btnAuto:addChild(self._btnAuto._autoBone)
    ]]
end

-- pvp timing

function _M:pvpTimingWhenRoundBegin(player)
    self:stopPvpTiming()
    self:removePvpTimingRope()
    self._isPvpTimeout = false
    self._pvpPlayer = player

    local lastRoundEndTimestamp = self._timestamp
    local lastPlayerRoundEndTimestamp = nil
    local players = {self._player, self._opponent}
    for j = 1, 2 do
        local player = players[j]
        for i = 1, #player._ops do
            local op = player._ops[i]
            if op._type == BattleData.UseCardType.round then
                local timestamp = math.abs(op._timestamp)
                if lastRoundEndTimestamp < timestamp then
                    lastRoundEndTimestamp = timestamp
                end
                if player == self._pvpPlayer then
                    lastPlayerRoundEndTimestamp = op._timestamp
                end
            end
        end
    end

    local passedSecond = math.max(0, math.floor(ClientData.getCurrentTime()) - lastRoundEndTimestamp)
    local roundDuration = (lastPlayerRoundEndTimestamp ~= nil and lastPlayerRoundEndTimestamp < 0) and _M.PVP_ROUND_OFFLINE_DURATION or _M.PVP_ROUND_DURATION
    if passedSecond < roundDuration then
        local timingDuration = roundDuration - passedSecond
        self._roundEndTimestamp = ClientData.getCurrentTime() + timingDuration + _M.PVP_ROPE_DURATION
        self:startPvpTiming(timingDuration)
    else
        local timingDuration = math.max(1, roundDuration + _M.PVP_ROPE_DURATION - passedSecond)
        self._roundEndTimestamp = ClientData.getCurrentTime() + timingDuration
        self:showPvpTimingRope(timingDuration)
    end
end

function _M:startPvpTiming(duration)
    self:stopPvpTiming()
    self._pvpTimingScheduler = lc.Scheduler:scheduleScriptFunc(function(dt)
        self:stopPvpTiming()
        self:showPvpTimingRope(_M.PVP_ROPE_DURATION)     
    end, duration * cc.Director:getInstance():getScheduler():getTimeScale(), false)    
end

function _M:stopPvpTiming()
    if self._pvpTimingScheduler ~= nil then
        lc.Scheduler:unscheduleScriptEntry(self._pvpTimingScheduler)
        self._pvpTimingScheduler = nil
    end
end

function _M:showPvpTimingRope(duration)
    local roundSpr = self._pRoundLabel:getParent()

    local progressBar = ccui.LoadingBar:create()
    progressBar:loadTexture("bat_scene_wick_rope", ccui.TextureResType.plistType)
    progressBar:setDirection(ccui.LoadingBarDirection.RIGHT)
    progressBar:setPosition(lc.cw(self) - 26, lc.ch(self))
    progressBar:setPercent(duration * 100 / _M.PVP_ROPE_DURATION)
    self:addChild(progressBar)
    self._pvpTimingRope = progressBar
    
    local bg = lc.createSprite('bat_scene_wick_bg')
    lc.addChildToCenter(progressBar, bg, -1)

    self._scene:seenByCamera3D(progressBar)

    self:updatePvpTimingRope()
end

function _M:updatePvpTimingRope()
    if self._pvpTimingRope == nil then return end
    
    local progressBar = self._pvpTimingRope
    local width = progressBar:getContentSize().width
    local height = progressBar:getContentSize().height / 2 + 4
    
    local timeStep = _M.PVP_ROPE_DURATION / 100 * cc.Director:getInstance():getScheduler():getTimeScale()
    local step = progressBar:getPercent()
    progressBar:stopAllActions()
    progressBar:runAction(lc.rep(lc.sequence(timeStep,
        function ()
            local percent = progressBar:getPercent() - 1
            if percent <= 0 then 
                self:pvpTimeout()
            else
                progressBar:setPercent(percent)
            end
        end
    )))
end

function _M:removePvpTimingRope()
    if self._pvpTimingRope ~= nil then 
        self._pvpTimingRope:removeFromParent()
        self._pvpTimingRope = nil 
    end
end

function _M:pvpTimeout()
    local attacker = self._player._isAttacker and self._player or self._opponent
    if self._pvpPlayer == (self._isAttacker and attacker or attacker._opponent) then
        -- self timeout
        self:removePvpTimingRope()

        self._isPvpTimeout = true
        self:operateEnd()

    elseif not self._isObserver then
        -- opponent timeout
        if ClientData._isOppoOnline then
            -- do nothing
        else
            self:removePvpTimingRope()

            if self._pvpPlayer:isNeedDrop() then
                local type, ids = self._pvpPlayer._ai:aiDropCard()

                ClientData.sendBattleOppoUseCard(self._pvpPlayer, type, ids)

                table.insert(ClientData._usedCardsToAdd, -math.floor(ClientData.getCurrentTime()))
                table.insert(ClientData._usedCardsToAdd, type)
                table.insert(ClientData._usedCardsToAdd, #ids)
                for i = 1, #ids do
                    table.insert(ClientData._usedCardsToAdd, ids[i])
                end
            end

            local type, ids = BattleData.UseCardType.round, {self._pvpPlayer._round}
            ClientData.sendBattleOppoUseCard(self._pvpPlayer, type, ids)

            table.insert(ClientData._usedCardsToAdd, -math.floor(ClientData.getCurrentTime()))
            table.insert(ClientData._usedCardsToAdd, type)
            table.insert(ClientData._usedCardsToAdd, #ids)
            for i = 1, #ids do
                table.insert(ClientData._usedCardsToAdd, ids[i])
            end

            self:oppoTryUseCard()
        end
    end
end

function _M:prepareAction(player, card)
    local playerUi = player == self._playerUi._player and self._playerUi or self._opponentUi

    local target = card._saved._monsterTarget or card._saved._magicTarget or card._atkTarget
    local cardSprite = self._playerUi:getCardSprite(card) or self._opponentUi:getCardSprite(card)
    
    if (not target) or (not cardSprite) then
        return 0
    end

    cardSprite:updatePositiveStatus()

    if playerUi._isController and player._playerType == BattleData.PlayerType.player then
        return 0
    end

    -- start
    local targetSprite = self._playerUi:getCardSprite(target) or self._opponentUi:getCardSprite(target)

    local sourcePos = cc.p(self._layer:convertToNodeSpace(cardSprite:convertToWorldSpace(cc.p(0, 0))))
    local targetPos
    if targetSprite then
        targetPos = cc.p(self._layer:convertToNodeSpace(targetSprite:convertToWorldSpace(cc.p(0, 0))))
    elseif not self._isReverse then
        targetPos = cc.p(self._layer:convertToNodeSpace((playerUi._isController and PlayerUi.Pos.defender_fortress or PlayerUi.Pos.attacker_fortress)))
    else
        targetPos = cc.p(self._layer:convertToNodeSpace((playerUi._isController and PlayerUi.Pos.attacker_fortress or PlayerUi.Pos.defender_fortress)))
    end

    -- show
    local arrow = BattleLine.create(sourcePos)
    self._layer:addChild(arrow)

    arrow:directTo(targetPos, nil)
    arrow:resetToPos(lc.h(arrow) - 250)
    arrow._isAnimation = true

    local delay = 0.8
    arrow:runAction(lc.sequence(lc.delay(delay), lc.remove()))
    
    return delay
end

function _M:openVS()
    ClientData._battleScene:playBgMusic()

    if self._scene._screenShot ~= nil then 
        self._scene._screenShot:setVisible(false)
        self._scene._screenShot = nil
    end
    if not self._vsSpine then return end


    local duration2 = 1
    self._vsSpine:setAnimation(0, "animation3", false)
    self._vsSpine:runAction(lc.sequence(
        duration2,
        function() 
            self._vsSpine:removeFromParent()
            self._vsSpine = nil      
        end
    ))
end

function _M:playVideo()
    self._playVideo = true
    lc.Audio.stopAudio(AUDIO.M_BATTLE)
    local scene = require("VideoScene").create()
    lc.pushScene(scene)
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

function _M:loadUnitTestFile(filename)
    local content = lc.readFile(filename)
    self:loadYgoContent(content)
end

function _M:loadYgoContent(content)
    self._player._playerType = BattleData.PlayerType.player
    self._player._unitTestData = json.decode(content)

    self._playerUi:efcFortressDieRemove()
    self._opponentUi:efcFortressDieRemove()

    self:resetBattle()
    
    self._playerUi:resetWhenBattleStart()
    self._opponentUi:resetWhenBattleStart()
    self:resetWhenBattleStart()
    
    self:setBattleSpeed()

    self:forwardToRound(false, 1)

    -- beginner train start
    if self._testMaskLayer then
        self._testMaskLayer:setVisible(true)
    end
    -- beginner train end
    if BattleTestData._curOpType ~= BattleTestData.OperationType._batch then
        self:setLoadRelativeButtonsVisbile(true)
    end
end

----------------------------
-- unittest
----------------------------

function _M:setLoadRelativeButtonsVisbile(isVisbile)
    -- beginner train start
    if self._battleType == Data.BattleType.unittest then
        self._btnRunFree:setVisible(isVisbile)
        self._btnExport:setVisible(isVisbile)
        self._btnRunTest:setVisible(isVisbile)
    end
    -- beginner train end
end

function _M:startBatchSingle()
    ClientData._battleDebugLog = ""
    self._testOkProgressBar._bar:setPercent(BattleTestData._batch._okCount * 100 / BattleTestData._batch._batchCount)
    self._testOkProgressBar:setLabel(BattleTestData._batch._okCount, BattleTestData._batch._batchCount)

    self._testErrorProgressBar._bar:setPercent(BattleTestData._batch._errorCount * 100 / BattleTestData._batch._batchCount)
    self._testErrorProgressBar:setLabel(BattleTestData._batch._errorCount, BattleTestData._batch._batchCount)

    if BattleTestData._batch._filenames then

        BattleTestData._curOpType = BattleTestData.OperationType._batch
        BattleTestData._singleFileName = BattleTestData._batch._filenames[BattleTestData._batch._curBatch]
        lc.log("+++++++++++++++++++++++++++++++++++++++++++++batch load file:" .. BattleTestData._singleFileName)
        self:loadUnitTestFile(BattleTestData._singleFileName)

        self._testMaskLayer:setVisible(false)
        self._player._playerType = BattleData.PlayerType.ai
        self._player:step()
    end
end

function _M:onExportUnitTestData()
    local tmpFilename = BattleTestData._singleFileName
    if ClientData._unitTestFile == BattleTestData.DEFAULT_FILE then
        local filename = lc.App:getSaveFileName()
        BattleTestData._singleFileName = filename
        if filename ~= nil and filename ~= "" then
            ClientData._unitTestFile = nil
            -- same as exportTestCard, move file content from default file to custom file
            local defaultFileContent = lc.readFile(BattleTestData.DEFAULT_FILE)
            lc.writeFile(BattleTestData._singleFileName, defaultFileContent)
        end
    end
    if BattleTestData._singleFileName ~= nil and BattleTestData._singleFileName ~= "" and BattleTestData._singleFileName ~= BattleTestData.DEFAULT_FILE then
        BattleTestData.exportToBattleLog()
        BattleTestData.exportUsedCards()
        ToastManager.push(Str(STR.EXPORT) .. Str(STR.SUCCESS))
        -- for this condition: layoutScene:genCard->battleScene:export->battleScene:runTest make test success
        -- otherwise, after that, battleScene->layoutScene using same cards, use the filename exported, not reset
        return
    end
    BattleTestData._singleFileName = tmpFilename
end

function _M:createTestProgress()
    if self._testOkProgressBar then return end

    -- unittest progress bar lc.right(self._btnRunTest) + 15 + lc.w(testOkProgressBar) / 2
    local testOkProgressBar = V.createLabelProgressBar(300)
    lc.addChildToPos(self._scene, testOkProgressBar, cc.p(V.SCR_CW, lc.top(self._btnRunTest) - lc.h(self._btnRunFree) / 4), 50)
    self._testOkProgressBar = testOkProgressBar
    self._testOkProgressBar._bar:setColor(lc.Color3B.green)
    self._testOkProgressBar:setVisible(false)

    local testErrorProgressBar = V.createLabelProgressBar(300)
    lc.addChildToPos(self._scene, testErrorProgressBar, cc.p(V.SCR_CW, lc.top(self._btnRunTest) - 3 * lc.h(self._btnRunFree) / 4), 50)
    self._testErrorProgressBar = testErrorProgressBar
    self._testErrorProgressBar._bar:setColor(lc.Color3B.red)
    self._testErrorProgressBar:setVisible(false)
end

function _M:showTestProgress()
    self._testOkProgressBar:setVisible(true)
    self._testErrorProgressBar:setVisible(true)
end

function _M:hideTestProgress()
    BattleTestData.resetBatch()
    self._testOkProgressBar._bar:setPercent(0)
    self._testOkProgressBar:setLabel(0, 0)
    self._testOkProgressBar:setVisible(false)
    self._testErrorProgressBar._bar:setPercent(0)
    self._testErrorProgressBar:setLabel(0, 0)
    self._testErrorProgressBar:setVisible(false)
end

function _M:parseFileList(str, path)
    local result = {}
    if str ~= nil and type(str) == "string" then
        local lines = self:splitString(str, "\n")
        if #lines > 0 then
            for i = 1, #lines do
                local line = lines[i]
                local revLine = string.reverse(line)
                print("{" .. line .. "}")
                local index = string.find(revLine, " ")
                if index then
                    local filename = string.sub(line, #line - index + 2)
                    if string.find(filename, ".ygo") and filename ~= "DEFAULT_TEST_CARDS.ygo" then 
                        print("=============filename ----------", filename)
                        table.insert(result, path .. filename)
                    end
                end
            end
        end
    end
    return result
end

function _M:splitString(str, spl)
    local strs = {}
    while true do
        local index = string.find(str, spl)
        if index then
            local item = string.sub(str, 1, index - 1)
            table.insert(strs, item)
            str = string.sub(str, index + 1)
        else
            break
        end
    end
    
    return strs
end

return _M