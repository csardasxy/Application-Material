local _M = BattleUi

function _M:updateCardZOrder(pCard)
    local cardSprites = {}
    
    for index = 1, 2 do
        local playerUi = index == 1 and self._playerUi or self._opponentUi
       
        local totalCount = Data.MAX_CARD_COUNT_ON_BOARD + #playerUi._pGraveCards + #playerUi._pHandCards
        for i = 1, totalCount do
            local cardSprite = nil
            if totalCount <= Data.MAX_CARD_COUNT_ON_BOARD then
                cardSprite = playerUi._pBoardCards[i]
            elseif totalCount <= Data.MAX_CARD_COUNT_ON_BOARD + #playerUi._pGraveCards then
                cardSprite = playerUi._pGraveCards[i - Data.MAX_CARD_COUNT_ON_BOARD]
            else
                cardSprite = playerUi._pHandCards[i - Data.MAX_CARD_COUNT_ON_BOARD - #playerUi._pGraveCards]
            end

            if cardSprite then
                cardSprite:updateZOrder(cardSprite == pCard)
            end
        end
    end
end

function _M:createParticle(str, pos, parent, isGrouped, zOrder)
    if parent == nil or str == nil then return end

    local par = Particle.create(str)
    par:setPosition(pos)
    parent:addChild(par, zOrder or 0)
    
    if isGrouped then
        par:setPositionType(cc.POSITION_TYPE_GROUPED) 
    end

    self._scene:seenByCamera3D(parent)
    
    return par
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




-----------------------------------
-- function for battle show
-----------------------------------

function _M:showResult()
    lc.Director:updateTouchTimestamp()
    cc.Director:getInstance():getScheduler():setTimeScale(1)
    
    local result = self._result or {}
    local type = BattleResultDialog.Type.battle_result
    if self._baseBattleType == Data.BattleType.base_replay or (self._battleType == Data.BattleType.PVP_room and self._isObserver) then
        type = BattleResultDialog.Type.replay_result
    elseif self._battleType == Data.BattleType.PVP_dark then
        type = BattleResultDialog.Type.dark_result
    elseif self._baseBattleType == Data.BattleType.base_guidance then
        result._resultType = Data.BattleResult.win
        type = BattleResultDialog.Type.guide_result
    end

    -- beginner train
    if self._battleType == (Data.BattleType.PVP_room and self._isObserver) or self._battleType == Data.BattleType.recommend_train then
		result = { _resultType = self._player._resultType, _player = self._player, _opponent = self._opponent, _battleType = Data.BattleType.PVP_room}
    elseif self._battleType == Data.BattleType.PVP_dark then
        result._battleType = Data.BattleType.PVP_dark
        result._winScore = P._playerFindDark._winScore
        result._loseScore = P._playerFindDark._loseScore
        if type == BattleResultDialog.Type.replay_result then
            result._hideButton = true
        end
    elseif self._baseBattleType == Data.BattleType.base_PVP or self._baseBattleType == Data.BattleType.base_PVE then
        if result._resultType == Data.BattleResult.lose then
            if result._trophy ~= nil and result._trophy > 0 then result._trophy = - result._trophy end
        end
        
        if self._needTask then
            result._isTask = true
            result._tasks = self._player._battleCondition:getConditionDesc()
            result._taskResults = result._taskResult
        elseif result._curRank ~= nil and result._curRank ~= 0 then
            result._isRank = true
            result._rank = (result._preRank or 0) - (result._curRank or 0)
            result._curRank = result._curRank or 0
        end
    
    elseif self._baseBattleType == Data.BattleType.base_replay then
        if self._input._replayingLog then
            local log = self._input._replayingLog
			if log._player ~= nil then
				result = { _resultType = log._resultType, _isAttacker = log._isAttack, _city = log._city, _trophy = log._trophy, _gold = log._gold, _log = log,
                        _player = log._player, _opponent = log._opponent, _battleType = log._battleType == 17 and Data.BattleType.PVP_ladder or nil}
			elseif log._attacker ~= nil then
				result = { _resultType = log._resultType, _isAttacker = true, _log = log,
                        _player = log._attacker, _opponent = log._defender}
			else
				result = { }
			end
        else
            result = { _resultType = Data.BattleResult.win }
        end
        
    elseif self._baseBattleType == Data.BattleType.base_test then
        result = {_resultType = self._player:getResult(), _exp = 100, _preExp = 0, _curExp = 50, _preLevel = 4, _curLevel = 4,
            _gold = 600, _score = self._player._damageScore[PlayerBattle.KEY_TOTAL], _trophy = 1, _cards = {{_infoId = 11001, _count = 1}, {_infoId = 11001, _count = 2}}}

        if false then
            result._isTask = true
            result._tasks = self._player._battleCondition:getConditionDesc()
            result._taskResults = self._player._battleCondition:getTaskResult()
        elseif false then
            result._isOccupyCity = true
            result._levelId = self._input._levelId
        else
            result._isRank = true
            result._rank = 10
            result._curRank = 98760
        end

    elseif self._battleType == Data.BattleType.teach then
        result = {_resultType = self._player:getResult(), _exp = 0}

        result._isTask = true
        result._tasks = self._player._battleCondition:getConditionDesc()
        result._taskResults = self._player._battleCondition:getTaskResult()
        
        local teachingId = self._input._teachingId
        local teaching = Data._teachInfo[teachingId]
        local bonus = P._playerBonus._bonusTeach[teaching._bonusId]
        if bonus ~= nil and result._resultType == Data.BattleResult.win and result._taskResults[1] == true then
            bonus._value = bonus._info._val
            ClientData.sendTeachingFinish(teachingId)
        end
    end
        
    local dialog =  BattleResultDialog.create(self, type, result)
    self._layer:addChild(dialog, BattleScene.ZOrder.form)
    self._resultDialog = dialog    
end

function _M:hideResult()
    if self._resultDialog ~= nil then
        self._resultDialog:hide()
        self._resultDialog = nil
    end
end

function _M:showThinking()
    local dialog =  BattlePVPDialog.create(self, BattlePVPDialog.Type.thinking)
    self._layer:addChild(dialog, BattleScene.ZOrder.dialog)
    self._thinkingLayer = dialog
end

function _M:hideThinking()
    if self._thinkingLayer ~= nil then
        self._thinkingLayer:hide()
        self._thinkingLayer = nil
    end
end

function _M:reverseThinking()
    if self._thinkingLayer ~= nil then
        self._thinkingLayer:reverse()
    end
end

function _M:showWaiting()
    local indicator = V.getActiveIndicator()
    self._layer:addChild(indicator, BattleScene.ZOrder.dialog)
    indicator:show(Str(STR.WAITING))
end

function _M:hideWaitting()
    V.getActiveIndicator():hide()
end

function _M:showSetting()
    local dialog = BattleSettingDialog.create(self)
    self._layer:addChild(dialog, BattleScene.ZOrder.form)
    self._settingLayer = dialog
end

function _M:hideSetting()
    if self._settingLayer ~= nil then
        self._settingLayer:hide()
        self._settingLayer = nil
    end
end

function _M:showTask()
    local dialog = BattleTaskDialog.create(self)
    self._layer:addChild(dialog, BattleScene.ZOrder.form)
    self._taskLayer = dialog
end

function _M:hideTask()
    if self._taskLayer ~= nil then
        self._taskLayer:hide()
        self._taskLayer = nil

        if P._guideID < 100 then
            self._player:getActionPlayer():step()

        else        
            if self._isWaitToStart then
                self._isWaitToStart = false
            
                local widget = ccui.Layout:create()
                widget:setContentSize(V.SCR_SIZE)
                widget:setTouchEnabled(true)
                widget:setAnchorPoint(0, 0)
                widget:setPosition(0, 0)
                self._layer:addChild(widget, BattleScene.ZOrder.form)
            
                local time = cc.Director:getInstance():getScheduler():getTimeScale()
                self:runAction(cc.Sequence:create(
                    cc.DelayTime:create(0.6 * time),
                    cc.CallFunc:create(
                        function ()
                            if self._battleType == Data.BattleType.task then
                                self:startBattle()
                            end
                            widget:removeFromParent()
                        end)
                ))
            
            elseif self._isWaitToShowResult then
                self._isWaitToShowResult = false
            
                local time = cc.Director:getInstance():getScheduler():getTimeScale()
                self:runAction(cc.Sequence:create(
                    cc.DelayTime:create(0.6 * time),
                    cc.CallFunc:create(function () self:showResult() end)
                ))
            end
        end
    end
end

function _M:createBattleTitle(title)
    local titleBg = lc.createSprite("bat_story_title_bg")
    
    local par = Particle.create("par_story_title")
    par:setPositionType(cc.POSITION_TYPE_GROUPED) 
    lc.addChildToCenter(titleBg, par, -1)

    local title = V.createTTF(title, V.FontSize.S1, lc.Color3B.yellow)
    lc.addChildToPos(titleBg, title, cc.p(lc.w(titleBg) / 2, 30))

    return titleBg
end

function _M:showEvent(type, val, delayFinger)
    local dialog = BattleEventDialog.create(self, type, val, delayFinger)
    self._layer:addChild(dialog, BattleScene.ZOrder.dialog)
    self._eventLayer = dialog
    
    if self._cardInfoLayer then
        self:hideCardInfo()
    end 
end

function _M:hideEvent()
    if self._eventLayer then
        self._eventLayer:hide()
        self._eventLayer = nil 
        
        self:hideTip()

        if self._baseBattleType == Data.BattleType.base_guidance then
            self:setGuideHelpButtonVisible(false)
        end

        GuideManager.releaseFinger()

        local player = self._player:getActionPlayer()
        return player:step()
    end
end

function _M:showCardInfo(pCard, card)
    local statusStrs = pCard and pCard:getCardStatusStrs()
    
    local CardInfoPanel = require("CardInfoPanel")
    local cardInfoPanel = CardInfoPanel.create(card._infoId, 1, CardInfoPanel.OperateType.na, card, statusStrs)
    cardInfoPanel:show()
end

function _M:hideCardInfo()
    if self._cardInfoLayer then
        self._cardInfoLayer:hide()
        self._cardInfoLayer = nil

        if self._eventLayer then
            self._eventLayer._ignoreTouch = nil
        end
    end
end

function _M:showCardAttack(pCard)
    self._showingAttackCard = pCard

    local card = pCard._card

    pCard:updateZOrder(true)
    pCard:updateBoardActive()

    local duration = 0.3
    local action = lc.spawn(lc.moveTo(duration, cc.p(530, 364)), lc.rotateTo(duration, 15, 15, -10), lc.scaleTo(duration, card._pos == 1 and 2 or 3.2))
    action._dontFixPos = true
    pCard:runAction(action)

    pCard._pFrame._weaknessBg:setVisible(false)
    pCard._pFrame._drawBackBg:setVisible(false)

    local node = lc.createNode(pCard._pFrame:getContentSize())
    lc.addChildToCenter(pCard._pFrame, node, 3)
    pCard._attackNode = node

    if card._pos == 1 then
        local drawBackBtn = V.createShaderButton('bat_drawback_frame', function() 
            if not self:canOperateCard(pCard) then return end
            self._playerUi:showChoiceSwapMonsters(card._owner:getBattleCards('B', Data.CARD_MAX_LEVEL, card), false)
        end)
        local pos = cc.p(84, 60)
        lc.addChildToPos(node, drawBackBtn, pos, 5)
        local drawBackValue = V.createTTFBold(card._info._retreatCost, V.FontSize.S3, V.COLOR_TEXT_DARK)
        lc.addChildToPos(drawBackBtn, drawBackValue, cc.p(200, lc.ch(drawBackBtn)))
        local shadow = lc.createSprite('bat_drawback_shadow')
        lc.addChildToPos(node, shadow, cc.p(pos.x - 10, pos.y - 10), 3)
        drawBackBtn:setEnabled(card._owner:canDrawbackCard(card))
        if drawBackBtn:isEnabled() then
            local spine = V.createSpine("kpcz")
            lc.addChildToPos(node, spine, cc.p(pos.x - lc.cw(drawBackBtn) - 4, pos.y - lc.ch(drawBackBtn) - 2), 4)
            spine:setAnimation(0, "animation", true)
        end
        pCard._drawBackBtn = drawBackBtn
    end
    
    local skillBtns = {}
    local size = cc.size(574, 100)
    local y = 160
    for i = #card._skills, 1, -1 do
        local skill = card._skills[i]
        local skillBtn = V.createShaderButton(nil, function() 
            if not self:canOperateCard(pCard) then return end
            local isChooseCardsSkill, cards, count = card._owner:isChooseCardsSkill(skill)
            if isChooseCardsSkill then
                self._playerUi:showChoiceCards(pCard, cards, count, {card._id, skill._id})
            else
                self._playerUi:showChoiceSkill(pCard, {card._id, skill._id})
                --self._playerUi:sendEvent(self._playerUi.EventType.send_use_card, {_type = BattleData.UseCardType.spell, _ids = {card._id, card._skills[i]._id}})
            end
        end)
        skillBtn:setContentSize(size)
        local pos = cc.p(lc.cw(node), y)
        lc.addChildToPos(node, skillBtn, pos, 5)
        local frame = lc.createSprite({_name = 'bat_skill_frame', _crect = cc.rect(13, 13, 1, 1), _size = size})
        lc.addChildToCenter(skillBtn, frame)
        local texture = lc.createSprite('bat_skill_texture')
        texture:setScale(1, size.height / lc.h(texture))
        lc.addChildToCenter(frame, texture, -2)
        local shadow = lc.createSprite({_name = 'bat_skill_shadow', _crect = cc.rect(24, 24, 1, 1), _size = cc.size(size.width + 8, size.height + 16)})
        lc.addChildToPos(node, shadow, cc.p(pos.x - 10, pos.y - 10), 3)
        local skillInfo = V.createMonsterSkill(skill._id, cc.size(size.width - 10, size.height - 10), false)
        local info = Data._skillInfo[skill._id]
        if info._power > 0 then
            local extra = card._owner._extraPowerCost[card._owner._round] or 0
            if extra ~= 0 then
                skillInfo._powerLabel:setString('x'..math.max(0, info._power + extra))
                skillInfo._powerLabel:setColor(extra < 0 and cc.c3b(133, 235, 3) or cc.c3b(255, 100, 100))
            end
        end
        lc.addChildToCenter(frame, skillInfo, -1)
        
        skillBtn:setDisabledShader(V.SHADER_DISABLE)
        local canUse = card._owner:canUseMonsterSpell(card, skill)
        skillBtn:setEnabled(canUse)
        if canUse then
            local spine = V.createSpine("kpcz")
            lc.addChildToPos(node, spine, cc.p(pos.x - lc.cw(skillBtn) - 10, pos.y - lc.ch(skillBtn) - 20), 4)
            spine:setAnimation(0, "animation2", true)
        end

        skillBtns[#skillBtns + 1] = skillBtn
        y = y + size.height + 12

        pCard._pFrame._monsterSkills[i]:setVisible(false)
    end
    pCard._skillBtns = skillBtns

    node:setCameraMask(ClientData.CAMERA_3D_FLAG)
end

function _M:hideCardAttack()
    if self._showingAttackCard == nil then return end

    local pCard = self._showingAttackCard
    self._showingAttackCard = nil

    pCard._ownerUi:updateBoardCardsActive()

    pCard._pFrame._weaknessBg:setVisible(true)
    pCard._pFrame._drawBackBg:setVisible(true)
    for i = 1, #pCard._skillBtns do
        pCard._pFrame._monsterSkills[i]:setVisible(true)
    end

    pCard._attackNode:removeFromParent()
    
    local pos = pCard._ownerUi:calBoardCardPos(pCard)
    local duration = 0.3
    action = lc.spawn(lc.moveTo(duration, pos), lc.rotateTo(duration, 0, 0, 0), lc.scaleTo(duration, 1))
    pCard:runAction(action)

    pCard:runAction(lc.sequence(duration, function() pCard:updateZOrder(false) end))
end



function _M:showTip(vals)
    self:hideTip()

    if vals.t.story == 0 then return end

    self:setGuideHelpButtonVisible(false)
    self._guideTipVals = vals

    local tipText = Str(Data._storyInfo[vals.t.story]._nameSid)
    local npcStr, tipStr
    if tipText[1] == '/' then
        tipStr = string.sub(tipText, 2)
    else
        local parts = string.splitByChar(tipText, '/')
        npcStr, tipStr = parts[1], parts[2]
    end

    if vals.t.guide ~= 0 then
        if self._btnGuideHelp then
            self._btnGuideHelp._text = npcStr
        end
    end

    local guideBg = self._guideHelp
    if guideBg then
        if guideBg._text then
            guideBg._text:removeFromParent()
            guideBg._text = nil
        end

        if tipStr then
            -- Update important guide text
            local text = V.createBoldRichText(tipStr, {_normalClr = V.COLOR_TEXT_LIGHT, _boldClr = V.COLOR_TEXT_GREEN_DARK, _fontSize = V.FontSize.M1})

            local w = lc.w(text) + 40
            guideBg:setContentSize(w, 60)
            guideBg:setPositionX(lc.cw(guideBg) + 10)
            guideBg._text = text

            lc.addChildToPos(guideBg, text, cc.p(w / 2, 30))

            --[[
            local par = guideBg._par
            par:setScaleX(w / 214)      -- 214 is the default width of the particle
            par:setPositionX(w / 2)
            ]]
        end
    elseif tipStr then
        if self:isGuideWorldBattle() then
            local bg = lc.createImageView{_name = "img_com_bg_11", _crect = V.CRECT_COM_BG11, _size = cc.size(290, 120)}
            lc.addChildToPos(self, bg, cc.p(lc.w(self) / 2 + 350, 180))
            self._freeTip = bg

            local tip = V.createBoldRichText(tipStr, {_normalClr = V.COLOR_TEXT_DARK, _boldClr = V.COLOR_TEXT_GREEN_DARK, _fontSize = V.FontSize.S1, _width = 210})
            lc.addChildToPos(bg, tip, cc.p(lc.w(bg) / 2, lc.h(bg) / 2 + 2))
        end
    end

    if npcStr then
        local isNeedTap = (vals.t.touch == 1)
        local tip = GuideManager.createNpcTipLayer(Data._storyInfo[vals.t.story], isNeedTap, vals.t.left == 1, true, vals.t.width)
        if isNeedTap then
            if self._eventLayer then
                self._eventLayer._blockTouch = nil
            end

            tip._closeHandler = function()
                if self._eventLayer and self._eventLayer._delayFinger then
                    self._eventLayer:showFinger()
                end

                self:setGuideHelpButtonVisible(true)
                self._player:getActionPlayer():step()
            end
        else
            tip._canCloseHandler = function()
                if self._eventLayer and self._eventLayer._delayFinger then
                    self._eventLayer:showFinger()
                end
            end
        end

        -- Check highlighted object
        local hlType, rect = vals.t.hl_type
        if hlType then
            local param
            if hlType == GuideManager.HighlightType.battle_setting_btn then
                param = self._btnSetting
            end

            rect = GuideManager.addHighlightEffect(hlType, param)
        end
        tip = GuideManager.addContainerLayer(tip, BattleScene.ZOrder.dialog, rect)

        tip:setPosition((V.SCR_W - lc.w(tip)) / 2, 0)

        if self:getChildByTag(_M.Tag.help_dialog) or self:getChildByTag(_M.Tag.retreat_dialog) then
            tip:setVisible(false)
        end
    else
        if self._eventLayer and self._eventLayer._delayFinger then
            self._eventLayer:showFinger()
        end

        self:setGuideHelpButtonVisible(true)
    end
end

function _M:hideTip()
    if GuideManager._tipLayer then
        GuideManager.closeNpcTipLayer()

        self:setGuideHelpButtonVisible(true)
    end

    if self._freeTip then
        self._freeTip:removeFromParent()
        self._freeTip = nil
    end
end

function _M:setGuideHelpButtonVisible(isVisible)
    if self._btnGuideHelp then
        self._btnGuideHelp:setVisible(isVisible and self._btnGuideHelp._text ~= nil)
        self._guideHelp:setVisible(isVisible and self._guideHelp._text ~= nil)

        if isVisible and self._guideTipVals then
            -- play audio
            local audioId = AUDIO[string.format("E_STORY_%d_1", self._guideTipVals.t.story)]
            if audioId then
                lc.Audio.playAudio(audioId)
            end
        end
    end
end

function _M:getEventDrag()
    if self._eventLayer ~= nil and self._eventLayer._val ~= nil then
        local type = self._eventLayer._type
        if type == BattleEventDialog.Type.guide_drag_to_card or
           type == BattleEventDialog.Type.guide_drag_to_pos or
           type == BattleEventDialog.Type.guide_drag_to_attack or
           type == BattleEventDialog.Type.guide_drag_to_defend or
           type == BattleEventDialog.Type.guide_drag then
            return self._eventLayer._val[1]
        end
    end
    
    return nil
end

function _M:getEventDragTo()
    if self._eventLayer ~= nil and self._eventLayer._val ~= nil then
        local type = self._eventLayer._type
        if type == BattleEventDialog.Type.guide_drag_to_card or
           type == BattleEventDialog.Type.guide_drag_to_pos or
           type == BattleEventDialog.Type.guide_drag_to_attack then 
            return self._eventLayer._val[2], type
        elseif type == BattleEventDialog.Type.guide_drag_to_defend then 
            return nil, type
        end
    end
    
    return nil, nil
end

function _M:showDialog(type, val)
    local dialog =  BattleDialog.create(self, type, val)
    self._layer:addChild(dialog, BattleScene.ZOrder.dialog)
    return dialog
end

function _M:showRetreat()
    local dialog
    
    if self._retreatReturn then
        dialog =  require("Dialog").showDialog(Str(STR.BATTLE_DIALOG_RETRY))
    else
        dialog =  require("Dialog").showDialog(Str(STR.BATTLE_DIALOG_RETREAT))
    end

    dialog._okHandler = function()
        -- beginner train
        if self._battleType == Data.BattleType.teach then
            self:exitScene()
        elseif self._baseBattleType ~= Data.BattleType.base_PVP then
            self:resume()
        end
        self:retreat(self._player)
    end

    if self._baseBattleType ~= Data.BattleType.base_PVP then
        dialog._cancelHandler = function()
            self:resume()
        end
        self:pause()
    end

    dialog:setTag(_M.Tag.retreat_dialog)
    dialog:setLocalZOrder(BattleScene.ZOrder.form)
end

function _M:showShare(logId)
    local dialog = require("ShareForm").create(logId)
    dialog:show()
end

function _M:showChat(isController)
    if self._chatCDScheduler then
        ToastManager.push(Str(STR.BATTLE_CHAT_CD))
        return
    end

    local dialog = BattleChatDialog.create(self, isController)
    self._layer:addChild(dialog, BattleScene.ZOrder.form)
end

function _M:showOppoOnline()
    --[[
    local dialog =  BattlePVPDialog.create(BattlePVPDialog.Type.online)
    self:addChild(dialog, BattleScene.ZOrder.dialog)
    --]]

    ToastManager.push(Str(STR.OPPONENT_ONLINE))
end

function _M:showOppoOffline()
    --[[
    local dialog =  BattlePVPDialog.create(BattlePVPDialog.Type.offline)
    self._layer:addChild(dialog, BattleScene.ZOrder.dialog)
    --]]

    ToastManager.push(Str(STR.OPPONENT_OFFLINE))
end

function _M:showOppoOnline()
    ToastManager.push(Str(STR.PLAYER_ONLINE))
end

function _M:showOppoOffline()
    ToastManager.push(Str(STR.PLAYER_OFFLINE))
end

-----------------------------------
-- function for effects
-----------------------------------

function _M:setBattleSpeed(speed)
    speed = speed or self._battleSpeed

    local speedTime
    if self._baseBattleType == Data.BattleType.base_replay then
        speedTime = (speed > #_M.BattleSpeed and 3.0 or _M.BattleSpeed[speed])
    
    else
        if speed == nil or speed < 1 or speed > #_M.BattleSpeed then
            speed = 1
        end

        if speed > 1 then
            local playerLevel, playerVip = P._id ~= 0 and P:getMaxCharacterLevel() or self._player._level, P._vip or self._player._vip
            if playerLevel < Data._globalInfo._2xSpeedLevel and playerVip < Data._globalInfo._2xSpeedVip then
                speed = 1
            elseif playerLevel < Data._globalInfo._3xSpeedLevel and playerVip < Data._globalInfo._3xSpeedVip then
                speed = 2
            end
        end

        speedTime = (self._isTesting and speed ~= 1) and _M.BattleSpeed[speed] * self._speedFactor or _M.BattleSpeed[speed]
    end

    self._battleSpeed = speed
    self._btnSpeed._icon:setString(string.format("x%d", speed))

    cc.Director:getInstance():getScheduler():setTimeScale(speedTime)
end

function _M:updatePile(playerUi)
    local player = playerUi._player
    local count = #player._pileCards
    
    for i = 1, count do
        playerUi._pPileCards[i]:initBack()
        playerUi._pPileCards[i]:setPosition(playerUi._isController and PlayerUi.Pos.attacker_pile or PlayerUi.Pos.defender_pile)
        playerUi._pPileCards[i]._pCardArea:setScale(0.15)
        playerUi._pPileCards[i]:setRotation3D({x = 0, y = 0, z = 0})
        self._scene:seenByCamera3D(playerUi._pPileCards[i])
    end

    playerUi._pPileLabel:setVisible(count > 0) 
    playerUi._pPileLabel:setString(count)
    
    --[[
    local pileSpr = playerUi._pile
    local label = pileSpr._label
    label:setString(count)
    label:stopAllActions()
    label:runAction(cc.Sequence:create(
        cc.ScaleTo:create(0.2, 1.5), 
        cc.ScaleTo:create(0.2, 1.0)
    ))
    ]]
end

function _M:updateRound()
    local round = math.max(1, math.max(self._player._round, self._opponent._round))
    
    self._pRoundLabel:setString(round)
end

function _M:updateRoundButton()
    local isAddParticle = false
    
    -- dropping card
    if self._dropLayer then
        self._btnEndRound:setTouchEnabled(false)

    -- attacker round begin
    elseif self._player._macroStatus == BattleData.Status.round_begin then 
        self._btnEndRound:setTouchEnabled(false)
        self._btnEndRound:loadTextureNormal("bat_btn_6", ccui.TextureResType.plistType)
        self._pRoundTitle:setSpriteFrame("bat_label_atk")
    
    -- defender round begin
    elseif self._opponent._macroStatus == BattleData.Status.round_begin then
        self._btnEndRound:setTouchEnabled(false)
        self._btnEndRound:loadTextureNormal("bat_btn_6", ccui.TextureResType.plistType)
        self._pRoundTitle:setSpriteFrame("bat_label_def")
            
    -- attacker round
    elseif self._player == self._player:getActionPlayer() then
        if self._isOperating then
            if self._isAddingBoardCard then
                self._btnEndRound:setTouchEnabled(false)
                self._btnEndRound:loadTextureNormal("bat_btn_6", ccui.TextureResType.plistType)
                self._pRoundTitle:setSpriteFrame("bat_label_atk")
            elseif not self._playerUi:getIsMoreOperation() then
                self._btnEndRound:setTouchEnabled(true)
                self._btnEndRound:loadTextureNormal("bat_btn_5", ccui.TextureResType.plistType)
                self._pRoundTitle:setSpriteFrame("bat_label_end_2")

                isAddParticle = true

                if self:isGuideWorldBattle() then
                    self:addSoftGuide(0)
                end
            else
                self._btnEndRound:setTouchEnabled(true)
                self._btnEndRound:loadTextureNormal("bat_btn_4", ccui.TextureResType.plistType)
                self._pRoundTitle:setSpriteFrame("bat_label_end")
            end
        else
            self._btnEndRound:setTouchEnabled(false)
            self._btnEndRound:loadTextureNormal("bat_btn_6", ccui.TextureResType.plistType)
            self._pRoundTitle:setSpriteFrame("bat_label_atk")
        end
    
    -- defender round
    else
        self._btnEndRound:setTouchEnabled(false)
        self._btnEndRound:loadTextureNormal("bat_btn_6", ccui.TextureResType.plistType)
        self._pRoundTitle:setSpriteFrame("bat_label_atk")
    end
end

function _M:shakeScreen(type, playerUi, value)
    local isController = playerUi._isAttacker == self._isAttacker
    local dir = isController and 1 or -1
    
    local action = nil
    if type == _M.ShakeScreenType.fortress_hurt then
        local time, val = 0.1, 12
        action = cc.Sequence:create(
                    cc.EaseInOut:create(cc.MoveBy:create(time, cc.p(0, val)), 2.5),
                    cc.EaseInOut:create(cc.MoveBy:create(time, cc.p(-val, 0)), 2.5),
                    cc.EaseInOut:create(cc.MoveBy:create(time, cc.p(0, -val)), 2.5),
                    cc.EaseInOut:create(cc.MoveBy:create(time, cc.p(val, 0)), 2.5)
                    )
    
    elseif type == _M.ShakeScreenType.fortress_die then
        local time, val = 0.05, 12
        action = cc.Repeat:create(cc.Sequence:create(
                    cc.EaseInOut:create(cc.MoveBy:create(time, cc.p(0, val)), 2.5),
                    cc.EaseInOut:create(cc.MoveBy:create(time, cc.p(-val, 0)), 2.5),
                    cc.EaseInOut:create(cc.MoveBy:create(time, cc.p(0, -val)), 2.5),
                    cc.EaseInOut:create(cc.MoveBy:create(time, cc.p(val, 0)), 2.5),
                    cc.EaseInOut:create(cc.MoveBy:create(time, cc.p(0, -val)), 2.5),
                    cc.EaseInOut:create(cc.MoveBy:create(time, cc.p(-val, 0)), 2.5),
                    cc.EaseInOut:create(cc.MoveBy:create(time, cc.p(0, val)), 2.5),
                    cc.EaseInOut:create(cc.MoveBy:create(time, cc.p(val, 0)), 2.5)
                    ), 2)
                
    elseif type == _M.ShakeScreenType.retreat then
        local time, val = 0.05, 10 * dir
        action = cc.Sequence:create(
                    cc.EaseInOut:create(cc.MoveBy:create(time, cc.p(0, val)), 2.5),
                    cc.EaseInOut:create(cc.MoveBy:create(time, cc.p(-val, 0)), 2.5),
                    cc.EaseInOut:create(cc.MoveBy:create(time, cc.p(0, -val)), 2.5),
                    cc.EaseInOut:create(cc.MoveBy:create(time, cc.p(val, 0)), 2.5)
                    )
                    
    elseif type == _M.ShakeScreenType.to_board then
        local startPos, endPos = value._startPos, value._endPos
        local len, angle = playerUi:calLengthAndAngle(startPos, endPos)
        local pos = cc.p(math.cos(math.rad(angle)) * 8, math.sin(math.rad(angle)) * 8)
        action = cc.Sequence:create(
                    cc.EaseInOut:create(cc.Spawn:create(cc.ScaleTo:create(0.08, 0.975 * self._scale), cc.MoveBy:create(0.08, cc.p(pos.x, pos.y))), 2.5),
                    cc.EaseInOut:create(cc.Spawn:create(cc.ScaleTo:create(0.1, 1.01 * self._scale), cc.MoveBy:create(0.1, cc.p(-pos.x * 1.05, -pos.y * 1.05))), 2.5),
                    cc.EaseInOut:create(cc.Spawn:create(cc.ScaleTo:create(0.1, 1.0 * self._scale), cc.MoveBy:create(0.1, cc.p(pos.x * 0.05, -pos.y * 0.05))), 2.5)
                    )
                    
    elseif type == _M.ShakeScreenType.equip_book then
        if isController then
            action = cc.Sequence:create(
                        cc.EaseInOut:create(cc.MoveBy:create(0.06, cc.p(4, 8)), 2.5),
                        cc.EaseInOut:create(cc.MoveBy:create(0.08, cc.p(-4, -8)), 2.5),
                        cc.EaseInOut:create(cc.MoveBy:create(0.1, cc.p(5, 5)), 2.5),
                        cc.EaseInOut:create(cc.MoveBy:create(0.1, cc.p(-5, -5)), 2.5),
                        cc.EaseInOut:create(cc.MoveBy:create(0.1, cc.p(2, 3)), 2.5),
                        cc.EaseInOut:create(cc.MoveBy:create(0.1, cc.p(-2, -3)), 2.5)
                        )
        else
            action = cc.Sequence:create(
                        cc.EaseInOut:create(cc.MoveBy:create(0.06, cc.p(5, 5)), 2.5),
                        cc.EaseInOut:create(cc.MoveBy:create(0.1, cc.p(-6, -5)), 2.5),
                        cc.EaseInOut:create(cc.MoveBy:create(0.1, cc.p(2, 3)), 2.5),
                        cc.EaseInOut:create(cc.MoveBy:create(0.1, cc.p(-1, -3)), 2.5)
                        )
        end
    
    elseif type == _M.ShakeScreenType.attack_card then
        local startPos, endPos = value._startPos, value._endPos
        local len, angle = playerUi:calLengthAndAngle(startPos, endPos)
        local pos = cc.p(math.cos(math.rad(angle)) * 10, math.sin(math.rad(angle)) * 10)
        action = cc.Sequence:create(
                        cc.EaseInOut:create(cc.MoveBy:create(0.08, cc.p(pos.x, pos.y)), 2.5),
                        cc.EaseInOut:create(cc.MoveBy:create(0.1, cc.p(-pos.x * 1.05, -pos.y * 1.05)), 2.5),
                        cc.EaseInOut:create(cc.MoveBy:create(0.1, cc.p(pos.x * 0.05, pos.y * 0.05)), 2.5)
                        )
        
    end

    self:resetAction()
    self:runAction(action)
end

function _M:cameraTo(isAttacker, delayTime)
    local dPos = cc.p(0, -180)
    local sPos = cc.p(-dPos.x, -dPos.y)

    self:resetAction()
    self:runAction(lc.sequence({lc.moveBy(0.15, dPos), lc.scaleTo(0.15, 1.3 * self._scale)}, delayTime, {lc.moveBy(0.15, sPos), lc.scaleTo(0.15, 1.0 * self._scale)}))

    local mask = self._mask
    mask:resetAction()
    mask:setVisible(true)
    mask:runAction(lc.sequence(0.15 + delayTime, lc.fadeOut(0.15), lc.hide()))
end

function _M:showDropHand()
    local player = self._player:getActionPlayer()
    local playerUi = player == self._player and self._playerUi or self._opponentUi
    
    local maskLayer = lc.createMaskLayer(200, lc.Color3B.black, cc.size(V.SCR_W, V.SCR_H + 100))
    maskLayer:setAnchorPoint(cc.p(0.5, 0.5))
    lc.addChildToPos(self, maskLayer, cc.p(V.SCR_CW, V.SCR_CH - self._offsetY), _M.ZOrder.card_hand)
    maskLayer:setRotation3D({x = V.BATTLE_ROTATION_X, y = 0, z = 0})
    maskLayer:setScale(1 / self:getScale())
    self._dropLayer = maskLayer

    local str = string.format(lc.str(STR.DISCARD_HAND_TIP_1), #player._handCards - Data.MAX_CARD_COUNT_IN_HAND_AFTER_DROP)
    local tip1 = V.createTTF(str, V.FontSize.M1, V.COLOR_LABEL_LIGHT)
    lc.addChildToPos(maskLayer, tip1, cc.p(V.SCR_CW, 300))

    local tip2 = V.createTTF(lc.str(STR.DISCARD_HAND_TIP_2), V.FontSize.M2, V.COLOR_LABEL_LIGHT)
    lc.addChildToPos(maskLayer, tip2, cc.p(V.SCR_CW, V.SCR_CH + 140))
    
    self._scene:seenByCamera3D(maskLayer)

    self._btnSetting:setTouchEnabled(false)
    self._btnReplay:setTouchEnabled(false)
    self._btnAuto:setTouchEnabled(false)
    self._btnSpeed:setTouchEnabled(false)
    self:updateRoundButton()

    -- rese
    self._isEnableDrap = true

    for i = 1, #playerUi._pHandCards do
        local cardSprite = playerUi._pHandCards[i]
        if cardSprite then
            cardSprite:updateActive(true)
        end
    end

    -- touch
    maskLayer:setTouchEnabled(false)
    maskLayer.onTouchBegan = function (maskLayer, touch) 
        local touchCard = self:getTouchedCard(touch)
        if touchCard then
            if not (touchCard._isController and touchCard._card._status == BattleData.CardStatus.hand) then
                touchCard = nil
            end
        end

        maskLayer._touchCard = touchCard
        if touchCard then
            touchCard:onTouchBegan(touch)
        end

        return true
     end

    maskLayer.onTouchMoved = function (maskLayer, touch) 
        if maskLayer._touchCard then
            maskLayer._touchCard:onTouchMoved(touch)
        end
    end

    maskLayer.onTouchEnded = function (maskLayer, touch) 
        if not maskLayer._touchCard then
            if cc.pGetDistance(touch:getLocation(), touch:getStartLocation()) <= lc.Gesture.BUDGE_LIMIT then
                self._isEnableDrap = false
                self:hideDropHand()
            end

        elseif maskLayer._touchCard then
            maskLayer._touchCard:onTouchEnded(touch)

            if (not self._isAddingBoardCard) and touch:getLocation().y >= PlayerUi.Pos.use_area then
                playerUi:sendEvent(PlayerUi.EventType.send_use_card, {_type = BattleData.UseCardType.drop, _ids = {maskLayer._touchCard._card._id}})
                self:hideDropHand()
            else
                playerUi:playAction(maskLayer._touchCard, PlayerUi.Action.replace_hand_card, 0, 1)
            end
        end
    end

     maskLayer.onTouchCanceled = function (maskLayer) 
        self:hideDropHand()
    end
end

function _M:hideDropHand()
    if self._dropLayer then
        self._dropLayer:removeFromParent()
        self._dropLayer = nil

        local player = self._player:getActionPlayer()
        local playerUi = player == self._player and self._playerUi or self._opponentUi
        playerUi:updateCardsActive()

        self._btnSetting:setTouchEnabled(true)
        self._btnReplay:setTouchEnabled(true)
        self._btnAuto:setTouchEnabled(true)
        self._btnSpeed:setTouchEnabled(true)
        self:updateRoundButton()
    end
end

function _M:finishDropHand()
    self:onButtonEvent(self._btnEndRound)
end

function _M:showStartCoin()
    local spine = V.createSpine('ryb')
    spine:setAutoRemoveAnimation()
    spine:setAnimation(0, self._player._isAttacker and "z2" or "f2", false)
    lc.addChildToCenter(self, spine)
    return 4.0
end

function _M:canOperateCard(pCard)
    local card = pCard._card
    if card._owner:getActionPlayer() ~= card._owner then
        self._playerUi:sendEvent(PlayerUi.EventType.dialog_not_your_round)
        return false
    end
    if self._isAddingBoardCard then 
        self._playerUi:sendEvent(PlayerUi.EventType.dialog_adding_board_card)
        return false
    end
    return true
end