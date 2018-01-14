local _M = class("BattleResultDialog", lc.ExtendUIWidget)
BattleResultDialog = _M

_M.Type = 
{
    battle_result = 1,
    replay_result = 2,
    guide_result = 4,
    dark_result = 6,
}

function _M.create(battleUi, type, result)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(battleUi, type, result)
    
    panel:registerScriptHandler(function(evtName)
        if evtName == "enter" then
            panel:onEnter()
        elseif evtName == "cleanup" then
            panel:onCleanup()
        end
    end)
    
    return panel
end

function _M.createTest()
    ClientData.loadLCRes("res/battle.lcres")

    -- Make fake battle UI
    local ui = {}
    ui.isGuideWorldBattle = function(self) return false end
    ui._nameTag = "normal"
    ui._battleType = Data.BattleType.PVP_clash
    ui._baseBattleType = math.floor(ui._battleType / 100)
    ui._input = {_cityChapterId = 1, _opponent = {}}

    -- Generate fake result
    local result = {_resultType = Data.BattleResult.draw, _isAttacker = true, isRank = false, _isTask = true}
    --result._cards = {{_isFragment = false, _infoId = 7010, _level = 0, _count = 1}, {_isFragment = true, _infoId = 1290, _level = 0, _count = 5}}
    result._cards = {}
    result._curRank = 10
    result._exp = 6
    result._preExp = 380
    result._curExp = 570
    result._gold = 678
    result._score = 234
    result._trophy = 20
    result._taskResults = {{true}}
    result._grain = 10
    result._levelId = 0
    result._preLevel = 20
    result._curLevel = 20
    result._ingot = 10
    result._rank = -10
    result._curRank = 22
    result._tasks = {{}, {}}
    result._taskResults = {true, true}
    result._player = P
    result._opponent = P
    result._log = {}

    return _M.create(ui, _M.Type.replay_result, result)
end

function _M:onEnter()
    if self._result._resultType == Data.BattleResult.win then
        lc.Audio.playAudio(AUDIO.M_BATTLE_WIN)
    --elseif self._result._resultType == Data.BattleResult.lose then
    else
        lc.Audio.playAudio(AUDIO.M_BATTLE_LOSE)    
    end
end

function _M:onCleanup()
    lc.TextureCache:removeTextureForKey("res/jpg/dark_result_bg.jpg")
end

-------------------------------------------------------
-- init
-------------------------------------------------------

function _M:init(battleUi, type, result)
    self._battleUi = battleUi

    self._type = type
    self._result = result
    
    -- filter items which are not to be displayed
    self._rewardItems = {}
    if result._cards then
        for _, card in ipairs(result._cards) do
            if card._infoId ~= Data.PropsId.flag and not (card._infoId >= Data.PropsId.clash_chest and card._infoId <= Data.PropsId.clash_chest_end) then            
                table.insert(self._rewardItems, card)
            end
        end

        P:sortResultItems(self._rewardItems)
    end

    if type == _M.Type.battle_result then
        self:createBattleResult(result)
    elseif type == _M.Type.guide_result then
        self:createGuidanceResult(result)
    elseif type == _M.Type.replay_result then
        self:createReplayResult(result)

    elseif type == _M.Type.dark_result then
        self:createDarkResult(result)
    end

    --if math.floor(P._guideID / 10) == 3 then
        -- The last guide battle
        --battleUi:showTip{t = {story = 77, touch = 0, left = 1}}
    --end

    --[[
    self:addTouchEventListener(function(sender, type) 
        if type == ccui.TouchEventType.ended then
            if self._pBtnExit and self._pBtnExit:isVisible() then
                self:onButtonEvent(self._pBtnExit)
            end
        end
    end)
    ]]
end

function _M:hide()
    if self._type == _M.Type.dark_result then
        P._playerFindDark:clearScore()
    end
    self:removeFromParent()
end

-------------------------------------------------------
-- ui 
-------------------------------------------------------

function _M:createBattleResult(result)    
    local titleLayer, delay = self:createTitle(result._resultType, 1.0)
    local pos = cc.p(V.SCR_CW, V.SCR_CH)
    lc.addChildToPos(self, titleLayer, pos)

    if result._resultType == Data.BattleResult.win then
        pos.x = pos.x
        pos.y = pos.y + 60

        if result._isTask then
            local taskLayer, tempDelay = self:createTask(result._tasks, result._taskResults, delay)
            delay = tempDelay
            pos.y = pos.y - lc.h(taskLayer) / 2
            lc.addChildToPos(self, taskLayer, pos)

            pos.y = lc.bottom(taskLayer) - 20

        elseif result._isRank and P:getMaxCharacterLevel() >= 30 then
            local rankLayer, tempDelay = self:createRank(result._rank, result._curRank, Str(STR.BATTLE_CUR_RANK), delay)
            delay = tempDelay
            pos.y = pos.y - lc.h(rankLayer) / 2
            lc.addChildToPos(self, rankLayer, pos)

            pos.y = lc.bottom(rankLayer) - 20
        end

        local resLayer, tempDelay = self:createResource(result, delay)
        delay = tempDelay
        pos.y = pos.y - lc.h(resLayer) / 2
        lc.addChildToPos(self, resLayer, pos)
        pos.y = lc.bottom(resLayer) - 0
        
        local rewardLayer = self:createReward(delay)
        if rewardLayer then
            pos.y = pos.y - lc.h(rewardLayer) / 2
            lc.addChildToPos(self, rewardLayer, pos)
        end
        
    elseif result._resultType == Data.BattleResult.lose then
        pos.x = pos.x
        pos.y = pos.y + 60

        if (result._trophy ~= nil and result._trophy ~= 0) or (result._gold ~= nil and result._gold ~= 0) or (result._flag ~= nil and result._flag ~= 0) or (result._activePoint ~= nil and result._activePoint ~= 0) or (result._unionBattleTrophy ~= nil and result._unionBattleTrophy ~= 0) then
            local expLayer = self:createResource(result, delay)
            pos.y = pos.y - lc.h(expLayer) / 2
            expLayer:setPosition(pos)
            self:addChild(expLayer)
            pos.y = lc.bottom(expLayer) -20
        end

        local rewardLayer = self:createReward(delay)
        if rewardLayer then
            pos.y = pos.y - lc.h(rewardLayer) / 2
            lc.addChildToPos(self, rewardLayer, pos)
        elseif self._battleUi._battleType ~= Data.BattleType.PVP_ladder and self._battleUi._battleType ~= Data.BattleType.PVP_ladder_npc and self._battleUi._battleType ~= Data.BattleType.teach and self._battleUi._battleType ~= Data.BattleType.PVP_room and self._battleUi._battleType ~= Data.BattleType.PVP_group then
            local pathLayer = self:createEnhancePath(delay, pos.y)
            pos.y = pos.y - lc.h(pathLayer) / 2
            pathLayer:setPosition(pos)
            self:addChild(pathLayer)
        end
    end
    
    self:createButton()
end

function _M:createGuidanceResult(result)
    local pos = cc.p(V.SCR_CW, V.SCR_CH)

    local titleLayer = self:createTitle(result._resultType)
    lc.addChildToPos(self, titleLayer, pos)
    
    if self._battleUi._nameTag == "normal" then
        self:createButton()
        GuideManager.showSoftGuideFinger(self._pBtnExit)
    end
end

function _M:createTitle(resultType, scale)
    local layerW, layerH = 1366, 530
    local layer = lc.createNode(cc.size(layerW, layerH))

    layer:setScale(scale or 1)

    local pos = cc.p(layerW / 2, layerH / 2 + 100)
    local beginName = 'animation'
    local loopName = 'animation2'
    local spine = V.createSpine(resultType == Data.BattleResult.win and 'shengli' or (resultType == Data.BattleResult.lose and 'shibai' or 'pingju'))
    spine:setPosition(pos)
    layer:addChild(spine, 0)
    spine:setAnimation(0, beginName, false)
    local duration = 1
    spine:runAction(lc.sequence(
        duration,
        function () spine:setAnimation(0, loopName, true) end
    ))

    return layer, duration + 0.3
end

function _M:createResource(result, delay)
    local layer = lc.createNode()
    
    local battleType = self._battleUi._battleType
    local isClash = (battleType == Data.BattleType.PVP_clash or battleType == Data.BattleType.PVP_clash_npc)

    local trophy, gold, flag, ingot, personalPower = result._trophy, result._gold, result._flag, result._ingot, result._personalPower

    local items = {}
    if trophy and trophy ~= 0 then table.insert(items, {_num = trophy, _iconName = isClash and "img_icon_res6_s" or "img_icon_res5_s"}) end
    if flag and flag ~= 0 then table.insert(items, {_num = flag, _iconName = ClientData.getPropIconName(7019)}) end
    if gold and gold ~= 0 then table.insert(items, {_num = gold, _iconName = "img_icon_res1_s"}) end
    if personalPower and personalPower ~= 0 then table.insert(items, {_num = personalPower, _iconName = "img_icon_res14_s"}) end
    if result._yubi and result._yubi > 0 then
        table.insert(items, {_num = result._yubi, _iconName = "img_icon_props_s7024"})
    end

    if result._activePoint and result._activePoint > 0 then
        table.insert(items, {_num = result._activePoint, _iconName = "img_icon_res14_s"})
    end
    if result._loseSkinCrystal then
        table.insert(items, {_num = result._loseSkinCrystal, _iconName = "img_icon_props_s7109"})
    end
    if result._unionBattleTrophy and result._unionBattleTrophy ~= 0 then
        table.insert(items, {_num = result._unionBattleTrophy, _iconName = "img_icon_res15_s"})
    end
    if result._darkTrophy and result._darkTrophy ~= 0 then
        table.insert(items, {_num = result._darkTrophy, _iconName = "img_icon_res16_s"})
    end

    if (battleType == Data.BattleType.PVP_ladder or battleType == Data.BattleType.PVP_ladder_npc) and result._resultType == Data.BattleResult.win then
        table.insert(items, {_num = Data._globalInfo._ladderExTrophy[P._playerFindLadder._winCount], _iconName = "img_icon_res5_s"})
    end
    
    local isShowItems = (next(items) ~= nil)
    local isShowLevel = isToad or (result._exp and result._exp > 0)
    
    local layerW, layerH = 512, ((isShowItems and isShowLevel) and 110 or 60)
    if trophy and trophy ~= 0 then
        layerH = layerH + 70
    end
    layer:setContentSize(layerW, layerH)

    local posY = layerH - 10
    -- trophy, gold and flag
    if isShowItems then
        local itemGap, itemW, itemH = 20, 0, 50
        local pos = cc.p(0, itemH / 2)

        local itemArea = lc.createNode(cc.size(itemW, itemH))
        for i, item in ipairs(items) do
            if item._num ~= 0 then
                local width, iconX = 0, pos.x
                if item._label then
                    local label = V.createBMFont(V.BMFont.huali_26, item._label)
                    label:setColor(V.COLOR_TEXT_ORANGE)
                    lc.addChildToPos(itemArea, label, cc.p(pos.x + lc.w(label) / 2, pos.y))
                    width, iconX = lc.w(label) + 6, lc.right(label) + 6
                end

                local icon = lc.createSprite(item._iconName)
                lc.addChildToPos(itemArea, icon, cc.p(iconX + lc.w(icon) / 2, pos.y))

                local str = item._num > 0 and ("+"..item._num) or tostring(item._num)
                local label = V.createBMFont(V.BMFont.huali_32, str)
                lc.addChildToPos(itemArea, label, cc.p(lc.right(icon) + 10 + lc.w(label) / 2, pos.y))

                itemW = itemW + width + lc.w(icon) + 10 + lc.w(label) + itemGap
                pos.x = pos.x + lc.w(icon) + 10 + lc.w(label) + itemGap
            end
        end

        itemW = itemW - itemGap
        itemArea:setContentSize(itemW, itemH)

        lc.addChildToPos(layer, itemArea, cc.p(lc.w(layer) / 2, posY - itemH / 2))
        posY = posY - itemH - 12
    end
    
    -- level up
    if isShowLevel then
        local exp, preExp, preLevel, curLevel =  result._exp, result._preExp, result._preLevel, result._curLevel
        
        local expBar = V.createLevelExpBar(preLevel, preExp, P:getLevelupExp(preLevel), 360)
        lc.addChildToPos(layer, expBar, cc.p(layerW / 2 + 10, posY -  lc.ch(expBar) - 0))

        posY = posY -  lc.h(expBar) - 16

        local expAdd = V.createBMFont(V.BMFont.huali_26, "+"..exp)
        expAdd:setScale(0.9)
        expAdd:setAnchorPoint(1, 0.5)
        expAdd:setColor(V.COLOR_TEXT_GREEN)
        lc.addChildToPos(expBar, expAdd, cc.p(lc.w(expBar) - 10, lc.h(expBar) / 2 + 1))

        local level, step = preLevel, math.max(1, math.floor(exp / 50))
        expBar:scheduleUpdateWithPriorityLua(function()
            if exp < step then
                step = exp
            end
            
            exp = exp - step
            preExp = preExp + step
            
            local levelUpExp = P:getLevelupExp(level)
            if preExp >= levelUpExp then
                level = level + 1
                preExp = preExp - levelUpExp

                expBar._level:setString(level)
            end

            expBar:setLabel(preExp, levelUpExp)
            expBar._bar:setPercent(preExp * 100 / levelUpExp)

            if exp == 0 then
                expBar:unscheduleUpdate()
            end
        end, 0)
        
        if curLevel ~= preLevel then
            local dialog = require("LevelUpPanel").createLord(preLevel, curLevel)
            self:addChild(dialog, 1)
        end

        delay = delay + 0.2
    end

    if trophy and trophy ~= 0 then
        local bar = V.createTrophyProgressBar(360)
        lc.addChildToPos(layer, bar, cc.p(layerW / 2, posY - lc.ch(bar) - 10))
    end

    layer:setVisible(false)
    layer:runAction(lc.sequence(
        delay,
        function() layer:setVisible(true) end
    ))
    
    return layer, delay
end

function _M:createTask(tasks, taskResults, delay)
    local layerW, layerH = 512, #tasks * 40
    local layer = lc.createNode(cc.size(layerW, layerH))
    
    local taskLabels = {}
    local maxW = 0
    for i = 1, #tasks do
        local label = cc.Label:createWithTTF(tasks[i], V.TTF_FONT, V.FontSize.S1)
        label:setColor(lc.Color3B.black)
        taskLabels[#taskLabels + 1] = label
        local icon = lc.createSprite(taskResults[i] and 'img_icon_right' or 'img_icon_wrong')
        label._icon = icon
        if lc.w(label) > maxW then maxW = lc.w(label) end
    end

    local x = (layerW - maxW) / 2
    for i = 1, #taskLabels do
        local star = lc.createSprite(taskResults[i] and 'bat_result_star_02' or 'bat_result_star_01')
        lc.addChildToPos(layer, star, cc.p(x, layerH + 20 - 40 * i))
        lc.addChildToPos(layer, taskLabels[i], cc.p(lc.right(star) + 10 + lc.cw(taskLabels[i]), lc.y(star)))
        lc.addChildToPos(layer, taskLabels[i]._icon, cc.p(lc.right(taskLabels[i]) + 10 + lc.cw(taskLabels[i]._icon), lc.y(star)))
    end

    layer:setVisible(false)
    layer:runAction(lc.sequence(
        delay,
        function() layer:setVisible(true) end
    ))
    
    return layer, delay + 0.2
end

function _M:createReward(delay)
    local items = self._rewardItems
    if items == nil or #items == 0 then
        return nil
    end

    local layerW, layerH = 512, 120
    local layer = lc.createNode(cc.size(layerW, layerH))
        
    for i, item in ipairs(items) do
        -- Do not show flags in the rewards area
        local pos = cc.p(math.floor((i - (#items + 1) / 2) * 120 + layerW / 2), 60)

        lc.log("Battle result item infoId = %d, delay = %f, pos(%d, %d)", item._infoId, delay + 0.2 * i, pos.x, pos.y)

        local icon = IconWidget.create(item)
        icon._name:setColor(V.COLOR_TEXT_LIGHT)
        icon:setTouchEnabled(false)
        icon:setOpacity(0)
        icon:runAction(lc.sequence(delay + 0.2 * i, lc.fadeIn(0.2), function() icon:setTouchEnabled(true) end))
        lc.addChildToPos(layer, icon, pos)
    end
    
    delay = delay + 0.2 * #items

    return layer, delay
end

function _M:createRank(rank, curRank, title, delay)
    local layerW, layerH = 512, 40
    local layer = lc.createNode(cc.size(layerW, layerH))
    
    local label = V.createBMFont(V.BMFont.huali_26, title)
    label:setColor(lc.Color3B.yellow)
    lc.addChildToPos(layer, label, cc.p(layerW / 2 - 50, layerH / 2))
    
    local rankVal = V.createBMFont(V.BMFont.num_48, tostring(curRank))
    lc.addChildToPos(layer, rankVal, cc.p(lc.right(label) + lc.cw(rankVal) + 2, lc.y(label)))
    
    if rank ~= 0 then
        local color = (rank > 0 and V.COLOR_TEXT_GREEN or V.COLOR_TEXT_RED)

        local arrow = lc.createSprite(rank > 0 and "img_arrow_up_1" or "img_arrow_down_1")
        arrow:setColor(color)
        lc.addChildToPos(layer, arrow, cc.p(lc.right(rankVal) + 16, lc.y(rankVal)))

        local diff = V.createBMFont(V.BMFont.huali_26, tostring(math.abs(rank)))
        diff:setColor(color)
        lc.addChildToPos(layer, diff, cc.p(lc.right(arrow) + 4 + lc.w(diff) / 2, lc.y(arrow)))
    end

    return layer, delay + 0.2
end

function _M:createEnhancePath(delay, top)
    local layerW, layerH = 512, 188
    local layer = lc.createNode(cc.size(layerW, layerH))
    
    --[[
    local label = cc.Label:createWithTTF(Str(STR.BATTLE_FAIL_CONTENT_1), V.TTF_FONT, V.FontSize.S1)
    lc.addChildToPos(layer, label, cc.p(layerW / 2, layerH - 20))

    label = cc.Label:createWithTTF(Str(STR.BATTLE_FAIL_CONTENT_2), V.TTF_FONT, V.FontSize.S1)
    lc.addChildToPos(layer, label, cc.p(layerW / 2, layerH - 60))
    ]]

    --[[
    local btn = V.createScale9ShaderButton("img_btn_1", function() 
        self._battleUi:exitScene(ClientData.SceneId.factory_monster)
    end, V.CRECT_BUTTON, 160)
    btn:addLabel(Str(STR.BATTLE_FAIL_TITLE_1))
    lc.addChildToPos(layer, btn, cc.p(layerW / 2 - 100, 48))
    ]]

    if not self._battleUi:isGuideWorldBattle() then
        local btn = V.createShaderButton(nil, function(sender) 
            lc.pushScene(require("HeroCenterScene").create())
        end)
        btn:setContentSize(160, 168)
        lc.addChildToCenter(btn, lc.createSpriteWithMask('res/jpg/enhance_troop.jpg'))
        lc.addChildToPos(layer, btn, cc.p(layerW / 2 - 120, 94))
        self._pBtnTroop = btn

        btn = V.createShaderButton(nil, function(sender) 
            self:onButtonEvent(sender)
        end)
        btn:setContentSize(160, 168)
        lc.addChildToCenter(btn, lc.createSpriteWithMask('res/jpg/enhance_tavern.jpg'))
        lc.addChildToPos(layer, btn, cc.p(layerW / 2 + 120, 94))
        self._pBtnTavern = btn
    end

    layer:setVisible(false)
    layer:runAction(lc.sequence(
        delay,
        function() layer:setVisible(true) end
    ))

    return layer, delay
end

function _M:createButton()
    local btnW = 160

    local btnReturn = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:onButtonEvent(sender) end, V.CRECT_BUTTON_S, btnW)
    btnReturn:addLabel(Str(STR.RETURN))
    btnReturn:setPosition(lc.w(self) / 2, 70)
    self:addChild(btnReturn)
    self._pBtnExit = btnReturn
  
    local batType = self._battleUi._battleType
    local isRetry = (self._battleUi._baseBattleType == Data.BattleType.base_PVE) and batType ~= Data.BattleType.expedition_ex and (self._result._resultType == Data.BattleResult.lose) and (batType ~= Data.BattleType.PVP_dark)
    local isReplay = (self._battleUi._battleType == Data.BattleType.replay) and (batType ~= Data.BattleType.PVP_dark)
    local isShowShare = false
    local showRetreat = not P._playerFindDark:isDarkFinished() and  batType == Data.BattleType.PVP_dark

    if self._result._log then
        lc.log("battle type = %d  sharable = %s", self._battleUi._battleType, ClientData._replaySharable and "true" or "false")

        if isReplay then
            isShowShare = ClientData._replaySharable
        else
            isShowShare = true
        end
        isShowShare = isShowShare and batType ~= Data.BattleType.PVP_dark
    end

    if isRetry then
        if true then
            local btnRetry = V.createScale9ShaderButton("img_btn_2_s", function(sender) self:onButtonEvent(sender) end, V.CRECT_BUTTON_S, btnW)
            btnRetry:addLabel(Str(STR.BATTLE_AGAIN))
            lc.addChildToPos(self, btnRetry, cc.p(lc.w(self) / 2 + 200, lc.y(btnReturn)))
            lc.offset(btnReturn, -200, 0)
            self._pBtnRetry = btnRetry

            self._isGrainEnough = true

        else
            local cost = P:getBattleCost(nil, false, self._battleUi._input._levelId)
            local area = V.createResConsumeButtonArea({120, 160}, "img_icon_res2_s", lc.Color3B.white, cost, Str(STR.BATTLE_AGAIN), "img_btn_2")
            area._btn._callback = function(sender) self:onButtonEvent(sender) end
            lc.addChildToPos(self, area, cc.p(lc.w(self) / 2 + 200, lc.y(btnReturn)))
            lc.offset(btnReturn, -200, 0)
            self._pBtnRetry = area._btn

            if cost > P._grain then
                area._resLabel:setColor(lc.Color3B.red)
            else
                self._isGrainEnough = true
            end
        end
    else
        if isReplay then
            local btnReplay = V.createScale9ShaderButton("img_btn_2_s", function(sender) self:onButtonEvent(sender) end, V.CRECT_BUTTON_S, btnW)
            btnReplay:addLabel(Str(STR.REPLAY))
            lc.addChildToPos(self, btnReplay, cc.p(lc.w(self) / 2 + 200, lc.y(btnReturn)))
            lc.offset(btnReturn, -200, 0)
            self._pBtnReplay = btnReplay

        end
    end

    if isShowShare then
        local btnShare = V.createScale9ShaderButton("img_btn_2_s", function(sender) self:onButtonEvent(sender) end, V.CRECT_BUTTON_S, btnW)
        btnShare:addLabel(Str(STR.SHARE))
        lc.addChildToPos(self, btnShare, cc.p(lc.w(self) / 2 + 200, lc.y(btnReturn)))
        if isReplay then
            lc.offset(self._pBtnReplay, -200, 0)
        else
            lc.offset(btnReturn, -200, 0)
        end
        self._pBtnShare = btnShare

        self._pBtnShare:setDisabledShader(V.SHADER_DISABLE)
        self._pBtnShare:setEnabled(false)
    end

    if showRetreat then
        btnReturn:setVisible(false)
        local btnRetreat = V.createScale9ShaderButton("img_btn_2_s", function(sender) self:onButtonEvent(sender) end, V.CRECT_BUTTON_S, btnW)
        btnRetreat:addLabel(Str(STR.BATTLE_RETREAT))
        lc.addChildToPos(self, btnRetreat, cc.p(lc.cw(self), lc.y(btnReturn)))
        self._pBtnRetreat = btnRetreat
    end
end 

function _M:createReplayResult(result)
    local pos = cc.p(V.SCR_CW , V.SCR_CH)
    local margin = 60

    if result._player then

    local center = lc.createSprite({_name = 'bat_result_replay_bg_center', _crect = cc.rect(10, 5, 2, 2), _size = cc.size(22, 552)})
    lc.addChildToPos(self, center, cc.p(V.SCR_CW, V.SCR_CH + 40), 1)
    local circle = lc.createSprite('bat_result_replay_bg_circle')
    lc.addChildToPos(self, circle, cc.p(V.SCR_CW, V.SCR_CH + 40), 1)

    for i = 1, 2 do
        local isWin = ((i == 1) and result._resultType or (-result._resultType)) == Data.BattleResult.win
        local isLose = ((i == 1) and result._resultType or (-result._resultType)) == Data.BattleResult.lose

        local bg = ccui.Scale9Sprite:createWithSpriteFrameName(isWin and "bat_result_replay_bg_win" or (isLose and "bat_result_replay_bg_lose" or "bat_result_replay_bg_draw"), cc.rect(11, 11, 1, 1))
        bg:setContentSize(V.SCR_CW - margin / 2, 552)
        lc.addChildToPos(self, bg, cc.p(i == 1 and (V.SCR_CW - lc.cw(bg)) or (V.SCR_CW + lc.cw(bg)), V.SCR_CH + 40))
        
        local centerPosX = V.SCR_W / 4 * (i == 1 and 1 or 3)
        local title = lc.createSprite(isWin and "bat_result_win_s" or (isLose and "bat_result_lose_s" or "bat_result_draw_s"))
        lc.addChildToPos(self, title, cc.p(centerPosX, V.SCR_CH + 210))

        -- info
        local player = i == 1 and result._player or result._opponent

        local avatar = UserWidget.create(player, bor(UserWidget.Flag.LEVEL_NAME), 1.0, false, true)
        lc.addChildToPos(self, avatar, cc.p(centerPosX, V.SCR_CH + 40))

        -- trophy
        if result._battleType ~= Data.BattleType.PVP_ladder and result._battleType ~= Data.BattleType.PVP_ladder_npc and result._battleType ~= Data.BattleType.PVP_room and result._battleType ~= Data.BattleType.PVP_group and result._battleType ~= Data.BattleType.PVP_dark and result._trophy and result._trophy ~= 0 then
            local icon = lc.createSprite("img_icon_res6_s")
		    lc.addChildToPos(self, icon, cc.p(centerPosX - 80, V.SCR_CH - 100))

            local trophy = (result._trophy or 0) * (isWin and 1 or -1)
            local str = string.format("%d (%s%d)", player._trophy or 0, trophy >= 0 and "+" or "", trophy)
		    local label = cc.Label:createWithTTF(str, V.TTF_FONT, V.FontSize.M1)
		    label:setAnchorPoint(0, 0.5)
            label:enableShadow()
            lc.addChildToPos(self, label, cc.p(lc.x(icon) + 40, lc.y(icon)))
            
        end
    end

    --score
    if  result._winScore and result._loseScore then
        local winLabel = V.createBMFont(V.BMFont.huali_32, Str(STR.WIN_S))
        local winScoreLabel = V.createBMFont(V.BMFont.num_48, result._winScore)
        lc.addChildToPos(self, winLabel, cc.p(V.SCR_W / 4 - 20, V.SCR_CH - 40))
        lc.addChildToPos(self, winScoreLabel, cc.p(V.SCR_W / 4 + 20, V.SCR_CH - 40))

        local loseLabel = V.createBMFont(V.BMFont.huali_32, Str(STR.WIN_S))
        local loseScoreLabel = V.createBMFont(V.BMFont.num_48, result._loseScore)
        lc.addChildToPos(self, loseLabel, cc.p(V.SCR_W / 4 * 3 - 20, V.SCR_CH - 40))
        lc.addChildToPos(self, loseScoreLabel, cc.p(V.SCR_W / 4 * 3 + 20, V.SCR_CH - 40))
    end

    end

    -- init button
    self:createButton()
    


    --[[if result._opponent then
        -- It's a replay of PVP
        local vs = lc.createSprite("img_vs")
        lc.addChildToPos(self, vs, pos)

        local addArea = function(player, resultType, isAttacker)
            local dir = (isAttacker and -1 or 1)

            local title = self:createTitle(resultType, 0.7)
            lc.addChildToPos(self, title, cc.p(pos.x + 260 * dir, V.SCR_H - 200))
            
            local battleType = self._battleUi._replayType
            local isClash = (battleType == Data.BattleType.PVP_clash or battleType == Data.BattleType.PVP_clash_npc)

            local flag = (isClash and UserWidget.Flag.REGION_NAME_UNION or UserWidget.Flag.NAME_UNION)
            local userAvatar = require("UserWidget").create(player, flag, 1.0, not isAttacker, false)
            lc.addChildToPos(self, userAvatar, cc.p(pos.x + 240 * dir, pos.y))

            local hasRegion = (userAvatar._regionArea and userAvatar._regionArea:isVisible())
            if hasRegion then
                userAvatar._regionArea:setColor(V.COLOR_TEXT_LIGHT)
            end

            if userAvatar._unionArea and userAvatar._unionArea:isVisible() then
                userAvatar._unionArea._name:setColor(lc.Color3B.yellow)
            else
                lc.offset(userAvatar._nameArea, 0, 20)
                if hasRegion then
                    lc.offset(userAvatar._regionArea, 0, 20)
                end
            end

			if result._trophy then
				local icon = lc.createSprite(isClash and "img_icon_res6_s" or "img_icon_res5_s")
				lc.addChildToPos(self, icon, cc.p(pos.x + 340 * dir, pos.y - 100))

				local label = cc.Label:createWithTTF(string.format("%d (%s%d)", player._trophy or 0, resultType ~= Data.BattleResult.lose and "+" or "-", result._trophy or 0), V.TTF_FONT, V.FontSize.S1)
				label:setAnchorPoint((dir + 1) / 2, 0.5)
                lc.addChildToPos(self, label, cc.p(dir == -1 and lc.right(icon) + 20 or lc.left(icon) - 20, lc.y(icon)))
			end
        end
        
        local resultType, isAttacker = result._resultType, result._isAttacker
        addArea(result._player, resultType, isAttacker)
        addArea(result._opponent, -resultType, not isAttacker)

    else
        -- It's a replay of PVE
        local win = self:createTitle(Data.BattleResult.win)
        lc.addChildToPos(self, win, pos)
    end

    -- init button
    self:createButton()
    ]]
end

function _M:createWorldBossResult(result)
    local pos = cc.p(V.SCR_CW, V.SCR_CH)
    
    local titleLayer, delay = self:createTitle(Data.BattleResult.win)
    lc.addChildToPos(self, titleLayer, pos)
    pos.y = pos.y - lc.h(titleLayer) / 2 - 20
        
    local scoreArea = lc.createNode(cc.size(240, 120))    
    lc.addChildToPos(self, scoreArea, pos)
    local scoreLabel = lc.createSprite("img_icon_score")
    lc.addChildToPos(scoreArea, scoreLabel, cc.p(lc.w(scoreArea) / 2, lc.h(scoreArea) - 36))
    local score = V.createBMFont(V.BMFont.huali_32, result._score)
    score:setColor(V.COLOR_TEXT_GREEN)
    lc.addChildToPos(scoreArea, score, cc.p(lc.w(scoreArea) / 2, 44))
    pos.y = pos.y - lc.h(scoreArea) / 2 - 20

    if result._isRank then
        local rankLayer = self:createRank(result._rank, result._curRank, Str(STR.BATTLE_SCORE_RANK), delay)
        pos.y = pos.y - lc.h(rankLayer) / 2
        lc.addChildToPos(self, rankLayer, pos)

        pos.y = lc.bottom(rankLayer) - 20
    end

    local rewardLayer = self:createReward(delay)
    if rewardLayer then
        pos.y = pos.y - lc.h(rewardLayer) / 2
        lc.addChildToPos(self, rewardLayer, pos)
    end
    
    -- init button
    self:createButton()
end

function _M:createDarkResult(result)
    local BOTTOM_HEIGHT = 335
    
    local bg = lc.createSprite("res/jpg/dark_result_bg.jpg")
    lc.addChildToCenter(self, bg)

    local winLoseBg = lc.createSprite("win_lose_bg")
    winLoseBg:setScale(result._resultType == Data.BattleResult.win and 1 or -1, 80 / lc.h(winLoseBg))
    lc.addChildToPos(self, winLoseBg, cc.p(V.SCR_CW, V.SCR_H - 100))

    local vsSpr = lc.createSprite("img_vs")
    lc.addChildToPos(self, vsSpr, cc.p(V.SCR_CW, 545))

    local leftSpr = lc.createSprite(result._resultType == Data.BattleResult.win and "dark_win" or (result._resultType == Data.BattleResult.lose and "dark_lose" or "dark_draw"))
    local rightSpr = lc.createSprite(result._resultType == Data.BattleResult.win and "dark_lose" or (result._resultType == Data.BattleResult.lose and "dark_win" or "dark_draw"))
    local leftPos = cc.p(V.SCR_CW / 2, lc.y(winLoseBg))
    local rightPos = cc.p(V.SCR_W * 3 / 4, lc.y(winLoseBg))
    lc.addChildToPos(self, leftSpr, leftPos)
    lc.addChildToPos(self, rightSpr, rightPos)

    local playerScore = result._winScore
    local oppoScore = result._loseScore
    local playerScoreLabel = V.createTTF(playerScore, V.FontSize.B1, V.COLOR_TEXT_WHITE)
    local oppoScoreLabel = V.createTTF(oppoScore, V.FontSize.B1, V.COLOR_TEXT_WHITE)
    playerScoreLabel:setAnchorPoint(1, 0.5)
    oppoScoreLabel:setAnchorPoint(0, 0.5)
    lc.addChildToPos(self, playerScoreLabel, cc.p(V.SCR_CW - 50, lc.y(winLoseBg)))
    lc.addChildToPos(self, oppoScoreLabel, cc.p(V.SCR_CW + 50, lc.y(winLoseBg)))

    local leftBg = lc.createSprite({_name = "room_left_bg", _crect=cc.rect(10, 10, 1, 1)})
    leftBg:setContentSize(cc.size(lc.cw(self) - 20, lc.h(leftBg)))
    leftBg:setAnchorPoint(0.5, 0.5)
    local leftUser = UserWidget.create(result._player, bor(UserWidget.Flag.LEVEL_NAME, UserWidget.Flag.UNION, UserWidget.Flag.REGION), 1.2)
    self:adjustUserWidget(leftUser)
    lc.addChildToPos(leftBg, leftUser, cc.p(lc.cw(leftBg) - 10, lc.ch(leftBg) - 10))
    lc.addChildToPos(self, leftBg, cc.p(lc.cw(leftBg), BOTTOM_HEIGHT + lc.ch(leftBg)))
    local jobNode = lc.createNode()
    lc.addChildToPos(leftBg, jobNode, cc.p(lc.cw(leftBg), lc.h(leftBg) - 25))
    leftUser._jobNode = jobNode

    local rightBg = lc.createSprite({_name = "room_right_bg", _crect=cc.rect(110, 10, 1, 1)})
    rightBg:setContentSize(cc.size(lc.cw(self) - 20, lc.h(rightBg)))
    rightBg:setAnchorPoint(0.5, 0.5)
    local rightUser = UserWidget.create(result._opponent, bor(UserWidget.Flag.LEVEL_NAME, UserWidget.Flag.UNION, UserWidget.Flag.REGION), 1.2)
    self:adjustUserWidget(rightUser, true)
    lc.addChildToPos(rightBg, rightUser, cc.p(lc.cw(rightBg) + 10, lc.ch(rightBg) - 10))
    lc.addChildToPos(self, rightBg, cc.p(lc.w(self) - lc.cw(rightBg), BOTTOM_HEIGHT + lc.ch(rightBg)))
    local jobNode = lc.createNode()
    lc.addChildToPos(rightBg, jobNode, cc.p(lc.cw(rightBg), lc.h(rightBg) - 25))
    rightUser._jobNode = jobNode

    --rewards
    local area = lc.createSprite({_name = "group_avatars_bg", _crect = cc.rect(1, 1, 2, 2), _size = cc.size(V.SCR_W, 200)})
    local expLayer = self:createResource(result, 0)
    lc.addChildToPos(area, expLayer, cc.p(V.SCR_CW, 110))
    lc.addChildToPos(self, area, cc.p(V.SCR_CW, BOTTOM_HEIGHT - 115))

    if not P._playerFindDark:isDarkFinished() then
        local prefix = string.format(Str(STR.WAIT_FOR_NEXT_BATTLE), P._playerFindDark._inning + 1)
        local tip = V.createTTF(prefix, V.FontSize.M1, V.COLOR_TEXT_WHITE)
        tip:runAction(lc.rep(lc.sequence(1, function() tip:setString(prefix..".") end, 1, function() tip:setString(prefix.."..") end, 1, function() tip:setString(prefix.."...") end)))
        lc.addChildToCenter(area, tip)
    end

--    local iconsNode = lc.createNode()
--    lc.addChildToPos(area, iconsNode, cc.p(V.SCR_CW, 70))
--    local icons = {}
--    table.insert(icons, IconWidget.create({_infoId = Data.ResType.gold, _count = 600}))
--    for _, res in ipairs(self._rewardItems) do
--        local icon = IconWidget.create(res)
--        icon._name:setColor(V.COLOR_TEXT_WHITE)
--        table.insert(icons, icon)
--    end
--    lc.addNodesToCenterH(iconsNode, icons, 10)

    self:createButton()
end

function _M:adjustUserWidget(user, fllipX)
    user._nameArea._level:setVisible(true)
    user._nameArea:setPosition(cc.p(lc.right(user._frame) - 5, lc.y(user._frame)))
    user._unionArea:setPosition(cc.p(lc.right(user._frame) + lc.cw(user._unionArea) + 5, lc.y(user._frame) - lc.ch(user._unionArea) - 10))
    user._unionArea._name:setColor(V.COLOR_TEXT_WHITE)
    user._regionArea:setPositionY(lc.bottom(user._frame) - 20)
    user._regionArea:setColor(V.COLOR_TEXT_WHITE)

    if fllipX then
        user:setScaleX(-user:getScaleX())
        user._frame:setScaleX(-user._frame:getScaleX())
        user._nameArea._name:setScaleX(-user._nameArea._name:getScaleX())
        user._nameArea._name:setAnchorPoint(1, 0.5)
        user._nameArea._level._level:setScaleX(-user._nameArea._level._level:getScaleX())
--        user._nameArea._level._level:setAnchorPoint(1, 0.5)
        user._unionArea._name:setScaleX(-user._unionArea._name:getScaleX())
        user._unionArea._name:setAnchorPoint(1, 0.5)
        user._unionArea._word:setScaleX(-user._unionArea._word:getScaleX())
--        user._unionArea._word:setAnchorPoint(1, 0.5)
        user._regionArea:setScaleX(-user._regionArea:getScaleX())
        user._regionArea:setAnchorPoint(1, 0)
    end
end

----------------------------------------------------
-- function
---------------------------------------------------

function _M:onButtonEvent(sender)
    if sender == self._pBtnTroop then
        self._battleUi:exitScene(ClientData.SceneId.manage_troop)

    elseif sender == self._pBtnTavern then
        self._battleUi:exitScene(ClientData.SceneId.tavern)
        
    elseif sender == self._pBtnExit then
        self._battleUi:hideTip()
        self._battleUi:tryExitScene()
        self:hide()

    elseif sender == self._pBtnRetry then
        if self._isGrainEnough then
            self._battleUi:retry()
        else
            ToastManager.push(Str(STR.NOT_ENOUGH_GRAIN))
        end
        
    elseif sender == self._pBtnReplay then
        self._battleUi:replay()
        
    elseif sender == self._pBtnShare then
        self._battleUi:showShare(self._result._log._id)

    elseif sender == self._pBtnRetreat then
        require("Dialog").showDialog(Str(STR.DARK_BATTLE_WARNING), function()
            P._playerFindDark:retreat()
            V.getActiveIndicator():show(Str(STR.WAIT_BATTLE_RESULT))
        end)

    end
end

return _M
