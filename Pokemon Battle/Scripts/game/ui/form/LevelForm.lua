local _M = class("LevelForm", BaseForm)

local FORM_SIZE = cc.size(758, 670)

local H_MARGIN = _M.LEFT_MARGIN + 40
local V_MARGIN = _M.TOP_MARGIN + 40
local CONTENT_MARGIN_H = 40
local CONTENT_MARGIN_LEFT = 16
local CONTENT_MARGIN_RIGHT = 16
local CONTENT_MARGIN_BOTTOM = 20
local AREA_GAP = 20

local BIG_BTN_W = 170
local SMALL_BTN_W = 100

function _M.create(levelInfo)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(levelInfo)
    
    return panel
end

function _M:init(levelInfo)
    _M.super.init(self, FORM_SIZE, Str(levelInfo._nameSid), bor(BaseForm.FLAG.PAPER_BG, BaseForm.FLAG.TTF_TITLE))

    self._levelInfo = levelInfo

    self._troopArea = self:createTroopArea(Str(STR.DEF_TROOP))
    
    local top = lc.h(self._frame) - V.FRAME_INNER_TOP - 50
    top = self:addArea(self._troopArea, top)
    self:addDividingLine(top)
    top = top - 16
    top = self:addArea(self:createDropArea(), top)
    self:addDividingLine(top)
    top = top - 16
    top = self:addArea(self:createConditionArea(), top)
    self:addDividingLine(top)
    top = top - 16
    
    self:createButtonArea()                         -- Do not add the default button area, it will be added to clip button area
    self:addArea(self:createButtonClipArea())
       
    self:updateRaidCountAndUiAround() 

    self:updateInfo()
end

function _M:onEnter()
    _M.super.onEnter(self)
    
    local listeners = {}

    table.insert(listeners, lc.addEventListener(GuideManager.Event.seek, function(event) self:onGuide(event) end))

    table.insert(listeners, lc.addEventListener(Data.Event.prop_dirty, function(event)
        if event._data._infoId == Data.PropsId.sweep_card then
            self:updateSweepCardLabels()
        end
    end))

    --[[
    table.insert(listeners, lc.addEventListener(Data.Event.grain_dirty, function(event)
        self:updateCostLabel()
    end))
    ]]

    self._listeners = listeners

    -- May back from hero center
    if self._btnTroop then
        self._btnTroop._label:setString(string.format("%s %d", Str(STR.TROOP), P._curTroopIndex))
    end

    if self._conditionList then
        for i = 1, #self._conditionList do
            local condLabel = self._conditionList[i]
            if P:preCheckCondition(condLabel._conditionId, condLabel._conditionValue, P._curTroopIndex) then
                condLabel:setColor(V.COLOR_TEXT_LIGHT)
            else
                condLabel:setColor(lc.Color3B.red)
            end
        end
    end

    self:updateMyAttackValue()
end

function _M:onExit()
    _M.super.onExit(self)

    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end

    self:unscheduleUpdate()
end

function _M:addArea(area, top)
    if top then
        lc.addChildToPos(self._frame, area, cc.p(lc.w(self._frame) / 2, top - lc.h(area) / 2))
        return top - lc.h(area) - AREA_GAP
    else
        self._frame:addChild(area)
    end
end

function _M:createTroopArea(title, h)
    local w = lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT
    h = h or 142
    local isMultiLine = (h > 142)

    local troopArea = lc.createNode(cc.size(w, h))

    local cardNumBg = lc.createSprite({_name = "img_com_bg_5", _crect = V.CRECT_COM_BG5, _size = cc.size(90, 46)})
    lc.addChildToPos(troopArea, cardNumBg, cc.p(lc.w(troopArea) - lc.w(cardNumBg) / 2 - 8, h - lc.h(cardNumBg) / 2 + 12))

    local cardNumIcon = lc.createSprite("img_icon_cardnum")
    cardNumIcon:setScale(0.6)
    lc.addChildToPos(cardNumBg, cardNumIcon, cc.p(24, lc.h(cardNumBg) / 2 + 2))

    troopArea._cardNumLabel = V.createBMFont(V.BMFont.huali_26, '0')
    lc.addChildToPos(cardNumBg, troopArea._cardNumLabel, cc.p(60, lc.h(cardNumBg) / 2 + 2))

    local troopTitle = V.createBMFont(V.BMFont.huali_26, title)
    lc.addChildToPos(troopArea, troopTitle, cc.p(CONTENT_MARGIN_LEFT + lc.w(troopTitle) / 2, h - lc.h(troopTitle) / 2))
    
    local troopList
    if isMultiLine then
        troopList = lc.List.createV(cc.size(w, h - 36), 6, 2)

        local border1 = lc.createSprite("img_gradient_border")
        border1:setScaleX(w / lc.w(border1))
        border1:setColor(cc.c3b(222, 210, 182))
        lc.addChildToPos(troopArea, border1, cc.p(w / 2, lc.h(troopList) - 5), 1)

        local border2 = lc.createSprite("img_gradient_border")
        border2:setScaleX(w / lc.w(border2))
        border2:setFlippedY(true)
        border2:setColor(cc.c3b(222, 210, 182))
        lc.addChildToPos(troopArea, border2, cc.p(w / 2, 5), 1)
    else
        troopList = lc.List.createH(cc.size(w, 110), CONTENT_MARGIN_LEFT, 10)
    end

    lc.addChildToPos(troopArea, troopList, cc.p(0, 0))
    
    troopArea._list = troopList
    troopList._isMultiLine = isMultiLine
    
    return troopArea
end

function _M:createDropArea(top)  
    local w = lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT
    local h = 140

    local dropArea = lc.createNode(cc.size(w, h))

    local dropTitle = V.createBMFont(V.BMFont.huali_26, Str(STR.MAYBE)..Str(STR.GET))
    dropTitle:setAnchorPoint(0, 0.5)
    lc.addChildToPos(dropArea, dropTitle, cc.p(CONTENT_MARGIN_LEFT, h - lc.h(dropTitle) / 2))

    local dropList = lc.List.createH(cc.size(w, 110), CONTENT_MARGIN_LEFT, 10)
    lc.addChildToPos(dropArea, dropList, cc.p(0, 0))
    
    self._dropList = dropList
    self._dropArea = dropArea
    self._dropTitle = dropTitle

    return dropArea
end

function _M:addDividingLine(top)
    local dividingLine = V.createDividingLine(lc.w(self._frame) - CONTENT_MARGIN_H - 16, V.COLOR_DIVIDING_LINE_LIGHT)
    lc.addChildToPos(self._frame, dividingLine, cc.p(lc.w(self._frame) / 2, top))
    
    self._dividingLine = dividingLine
end

function _M:createButtonArea()
    local w = lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT
    local h = 180

    local buttonArea = ccui.Layout:create()
    buttonArea:setContentSize(w, h)
    buttonArea:setAnchorPoint(0.5, 0.5)
    buttonArea:setPosition(lc.w(self._frame) / 2, CONTENT_MARGIN_BOTTOM + h / 2 + 16)
    
    self._buttonArea = buttonArea
    return buttonArea
end

function _M:updateTroopArea(troopArea, troopCards)
    local list, isMultiLine = troopArea._list, troopArea._list._isMultiLine
    list:removeAllChildren()

    local cardCount, icons = 0, {}
    for i, card in ipairs(troopCards) do
        local icon = IconWidget.create({_infoId = card._infoId, _num = card._num, _cardList = troopCards, _index = i, _title = Str(STR.DEF_TROOP)}, IconWidget.DisplayFlag.CARD_TROOP)
        if card._isDead then
            icon:setGray(true) 
        else
            cardCount = cardCount + card._num
        end
        table.insert(icons, icon)
    end

    if isMultiLine then
        local lineH = 100
        local x, y, lineItem = IconWidget.SIZE / 2 + 16, lineH / 2

        for i, icon in ipairs(icons) do
            if lineItem == nil then
                lineItem = ccui.Widget:create()
                lineItem:setContentSize(lc.w(list), lineH)
            end

            lc.addChildToPos(lineItem, icon, cc.p(x, y))
            if (i % 4) == 0 then
                list:pushBackCustomItem(lineItem)
                lineItem = nil
                x = IconWidget.SIZE / 2 + 16
            else
                x = x + IconWidget.SIZE + 12
            end
        end

        if lineItem then
            list:pushBackCustomItem(lineItem)
        end

    else
        for _, icon in ipairs(icons) do
            list:pushBackCustomItem(icon)
        end
    end

    troopArea._cardNumLabel:setString(string.format("%d", cardCount))
end

function _M:updateDropArea(dropIds)
    self._dropList:removeAllItems()
    for i = 1, #dropIds do
        local infoId = dropIds[i]

        local ico = IconWidget.create({_infoId = infoId, _isFragment = false, _showOwnCount = true}, IconWidgetFlag.ITEM_NO_NAME)
        self._dropList:pushBackCustomItem(ico)
    end
end


function _M:createConditionArea(top)
    local w = lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT
    local h = 80

    local conditionArea = lc.createNode(cc.size(w, h))

    local conditionTitle = V.createBMFont(V.BMFont.huali_26, Str(STR.PASS_CONDITION))
    lc.addChildToPos(conditionArea, conditionTitle, cc.p(CONTENT_MARGIN_LEFT + lc.w(conditionTitle) / 2, h - lc.h(conditionTitle) / 2))

    self._conditionTitle = conditionTitle
    self._conditionList = {}
    self._conditionArea = conditionArea

    return conditionArea
end

function _M:createButtonClipArea()
    local w = lc.w(self._buttonArea)
    local h = lc.h(self._buttonArea)

    local clipArea = ccui.Layout:create()
    clipArea:setContentSize(w, h)
    clipArea:setAnchorPoint(0.5, 0.5)
    clipArea:setPosition(self._buttonArea:getPosition())
    clipArea:setClippingEnabled(true)

    self._buttonArea:setContentSize(w * 2, h)
    self._buttonArea:setPosition(w, h / 2)
    clipArea:addChild(self._buttonArea)
    
    self:createButtons()
    
    --self:createArrows()

    return clipArea
end

function _M:createButtons()
    local halfW = lc.w(self._buttonArea) / 2

    local btnW = 148
    local btnH = V.CRECT_BUTTON.height
    local touchRect = cc.rect(0, 0, btnW, btnH + 40)

    --<< Troop and attack buttons >>--
    local btnTroop = V.createScale9ShaderButton("img_btn_2_s", function(sender) self:onSelectTroop() end, V.CRECT_BUTTON_1_S, btnW)
    btnTroop:addLabel("")
    btnTroop:setTouchRect(touchRect)
    lc.addChildToPos(self._buttonArea, btnTroop, cc.p(halfW / 2 - 100 - lc.w(btnTroop) / 2, btnH / 2))
    self._btnTroop = btnTroop

    self._labelAttack, self._iconAttack = V.addIconValue(self._buttonArea, "img_icon_power", "00000", lc.x(self._btnTroop) - 48, lc.top(self._btnTroop) + 24)
    self._labelAttack:setColor(V.COLOR_TEXT_LIGHT)
    --TODO--
    self._labelAttack:setVisible(false)
    self._iconAttack:setVisible(false)

    --[[
    --local atkArea = V.createResConsumeButtonArea(btnW, "img_icon_res2_s", nil, nil, Str(STR.CAPTURE))
    lc.addChildToPos(self._buttonArea, atkArea, cc.p(halfW / 2, lc.h(atkArea) / 2))
    atkArea._btn._callback = function() self:onAttack() end
    atkArea._btn:setTouchRect(touchRect)
    --lc.offset(atkArea._resArea, -120, -54)
    self._costLabel = atkArea._resLabel
    self._btnAttack = atkArea._btn
    ]]

    --[[
    --<< Sweep buttons >>--
    local sweepOnceArea = V.createResConsumeButtonArea(btnW, ClientData.getPropIconName(Data.PropsId.sweep_card), nil, nil, Str(STR.SWEEP))
    lc.addChildToPos(self._buttonArea, sweepOnceArea, cc.p(halfW / 2 + 150 + lc.w(sweepOnceArea._btn) / 2, lc.h(sweepOnceArea) / 2))
    sweepOnceArea._btn._callback = function() self:onSweep(1, true) end
    sweepOnceArea._btn:setTouchRect(touchRect)
    self._sweepOnceLabel = sweepOnceArea._resLabel
    ]]

    local atkArea = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:onAttack() end, V.CRECT_BUTTON_1_S, btnW)
    atkArea:addLabel(Str(STR.CAPTURE))
    lc.addChildToPos(self._buttonArea, atkArea, cc.p(halfW / 2 + 100 + lc.cw(atkArea), btnH / 2))
    self._btnAttack = atkArea

    --[[
    local sweepMoreArea = V.createResConsumeButtonArea(btnW, ClientData.getPropIconName(Data.PropsId.sweep_card), nil, nil, string.format(Str(STR.SWEEP_TIMES), 5))
    lc.addChildToPos(self._buttonArea, sweepMoreArea, cc.p(lc.x(atkArea) + halfW, lc.h(sweepMoreArea) / 2))
    sweepMoreArea._btn._callback = function() self:onSweep(5, true) end
    sweepMoreArea._btn:setTouchRect(touchRect)
    self._sweepMultiLabel = sweepMoreArea._resLabel
    ]]
end

--[[
function _M:createArrows()
    local halfW = lc.w(self._buttonArea) / 2
    local btnSize = cc.size(60, lc.h(self._buttonArea))

    -- Arrow right
    local btnArrowRight = V.createArrowButton(false, btnSize, function(sender) self:onArrow(sender) end)
    lc.addChildToPos(self._buttonArea, btnArrowRight, cc.p(halfW - lc.w(btnArrowRight) / 2, lc.h(self._buttonArea) / 2))
    
    -- Arrow left
    local btnArrowLeft = V.createArrowButton(true, btnSize, function(sender) self:onArrow(sender) end)
    lc.addChildToPos(self._buttonArea, btnArrowLeft, cc.p(halfW + lc.w(btnArrowLeft) / 2, lc.h(self._buttonArea) / 2))
    
    self._btnArrowLeft = btnArrowLeft
    self._btnArrowRight = btnArrowRight
end
]]

function _M:updateInfo()
    local troopCards = self:getTroopCards()
    ClientData.sortTroopCards(troopCards)
    self:updateTroopArea(self._troopArea, troopCards)
    
    local dropIds = self:getDrops(true)        
    self._dropTitle:setString(Str(STR.FIRST)..Str(STR.PASS_BONUS))
    self:updateDropArea(dropIds)
    
    if self._conditionArea then
        self:updateConditionArea()
    end
    
    self:updateMyAttackValue()
    self:updateRaidCountAndUiAround()
    --self:updateArrow()
end

function _M:updateConditionArea()
    if self._conditionList == nil then return end
    
    for _, conditionLabel in ipairs(self._conditionList) do
        conditionLabel._num:removeFromParent()
        conditionLabel:removeFromParent()
    end
    
    self._conditionList = {}
    
    local conditions = self:getConditions()

    local y = lc.bottom(self._conditionTitle) - 6
    for i = 1, #conditions do
        local condition = conditions[i]
        local conditionValue = self._levelInfo._value[i]
        local valueStr, suffixStr = "", ""
        if condition._id == 11 then
            valueStr = Str(STR.NATURE_NONE + conditionValue)
        elseif condition._id == 13 then
            local info = Data._monsterInfo[conditionValue] or Data._magicInfo[conditionValue] or Data._trapInfo[conditionValue]
            valueStr = Str(info._nameSid)
        elseif condition._id == 14 then
            valueStr = Str(Data._eventInfo[conditionValue]._nameSid)
        elseif condition._id == 29 then
            local infoId = conditionValue % 100000
            local count = math.floor(conditionValue / 100000)
            valueStr = ''..count
            local info = Data.getInfo(infoId)
            suffixStr = Str(info._nameSid)
        else
            valueStr = string.format("%d", conditionValue)
        end

        local condNum = cc.Label:createWithTTF(string.format(Str(STR.BRACKETS_D), i), V.TTF_FONT, V.FontSize.S2)
        condNum:setColor(V.COLOR_LABEL_LIGHT)
        lc.addChildToPos(self._conditionArea, condNum, cc.p(CONTENT_MARGIN_LEFT + 5 + lc.w(condNum) / 2, y - lc.h(condNum) / 2))

        local condDesc = string.gsub(Str(condition._descSid), "%[.+%]", valueStr)..suffixStr
        local condLabel = cc.Label:createWithTTF(condDesc, V.TTF_FONT, V.FontSize.S2)   
        condLabel:setColor(V.COLOR_TEXT_LIGHT)     
        lc.addChildToPos(self._conditionArea, condLabel, cc.p(lc.right(condNum) + 4 + lc.w(condLabel) / 2, lc.y(condNum)))
        condLabel._num = condNum
        condLabel._conditionId = condition._id
        condLabel._conditionValue = conditionValue

        table.insert(self._conditionList, condLabel)
        y = y - lc.h(condLabel) - 6
        
        if not P:preCheckCondition(condLabel._conditionId, condLabel._conditionValue, P._curTroopIndex) then
            condLabel:setColor(lc.Color3B.red)
        end
    end
end

function _M:updateMyAttackValue()
    self._labelAttack:setString(string.format("%d", P._playerCard:getTroopFightingValue(P._curTroopIndex)))
end

function _M:updateRaidCountAndUiAround()
    
    --if city._chapter > chapter then
    if false then
        -- Remain counts label
        if self._labelSweepCount == nil then
            local remainKey = V.createKeyValueLabel(Str(STR.REMAIN_TIMES), "0 / 0", V.FontSize.S2, false)
            local h = lc.h(self._buttonArea)
            remainKey:addToParent(self._frame, cc.p((lc.w(self._frame) - remainKey:getTotalWidth()) / 2, h + CONTENT_MARGIN_BOTTOM + 6 + lc.h(remainKey) / 2))
            self._labelSweepCount = remainKey
        end
    else
        if self._labelSweepCount then
            self._labelSweepCount:removeFromParent()
            self._labelSweepCount = nil
        end
    end
    
    if self._dividingLine == nil then
        self:addDividingLine(130)
    end

    if self._labelSweepCount then
        --TODO--
        self._labelSweepCount._value:setString(string.format("%d / %d", 1, Data._globalInfo._dailySweepCount))
    end

    -- Update buttons position above the dividing line
    if self.__Rank == nil then
        local createButton = function(label, callback)
            local crect = cc.rect(V.CRECT_COM_BG5.x, 0, V.CRECT_COM_BG5.width, lc.frameSize("img_com_bg_5").height)
            local button = V.createScale9ShaderButton("img_com_bg_5", callback, crect, 100)
            if label then
                button:addLabel(label)
            end
            return button
        end
        --[[
        self._btnRank = createButton(Str(STR.CITY_STRATEGY))
        lc.addChildToPos(self._frame, self._btnRank, cc.p(lc.w(self._frame) - CONTENT_MARGIN_RIGHT * 2 - lc.w(self._btnRank) / 2, 0))]]
    end
        
    --local btnY = lc.top(self._dividingLine) + lc.h(self._btnRank) / 2 + 4
    --TODO--
    local isVisible = false

    -- Update cost
    --self:updateCostLabel(math.floor(self._levelInfo._id / 10000) * 5)

    -- Update sweep card
    --self:updateSweepCardLabels()
end

function _M:onSelectTroop()    
    lc.pushScene(require("HeroCenterScene").create())     
end

function _M:onAttack()
    local isTroopValid, msg = P._playerCard:checkTroop(P._curTroopIndex)
    if not isTroopValid then
        ToastManager.push(msg)
        return        
    end
    
    if (not P:checkBattleCost(nil, self._levelInfo._id)) then
        ToastManager.push(Str(STR.NOT_ENOUGH_GRAIN), ToastManager.DURATION_LONG)
        require("ExchangeResForm").create(Data.ResType.grain):show()
        return
    end    
    
    self:hide()

    V.getActiveIndicator():show(Str(STR.WAITING))
    ClientData.sendWorldAttack(P._curTroopIndex, self._levelInfo._id)

    lc.UserDefault:setIntegerForKey(ClientData.ConfigKey.last_level, self._levelInfo._id)

    if GuideManager.getCurStepName() == "click fight" then
        GuideManager.finishStep(true)
    end
end

function _M:onBuyRaidTimes()
    --if not self._city:isResetSweepValid(self._focusTabIndex) then
    if false then
        ToastManager.push(string.format(Str(STR.NOT_ENOUGH_BUY_TIMES), Str(STR.BUY)..Str(STR.ATTACK_TIMES)))
        return false
    end

    --if not V.checkIngot(self._city:getBuySweepIngot(self._tabs[self._focusTabIndex]._tag)) then  
    if false then  
        return false
    end

    return true
end

function _M:onGuide(event)
    local curStep = GuideManager.getCurStepName()
    if curStep == "click fight" then
        GuideManager.setOperateLayer(self._btnAttack)
    else
        return
    end

    event:stopPropagation()    
end

function _M:getTroopCards()
    local troopCards = {}

    local troopId = self._levelInfo._opponentTroopID
    local troopInfo = Data._troopInfo[troopId]

    for i = 1, #troopInfo._infoId do
        troopCards[i] = {_infoId = troopInfo._infoId[i], _num = troopInfo._num[i], _level = troopInfo._level[i]}
    end

    return troopCards
end

function _M:getDrops(isFirst)
    if isFirst then
        return self._levelInfo._firstPid
    else
        return self._levelInfo._pid
    end
end

function _M:getConditions()
    local conditions = {}
    local conditionIds = self._levelInfo._condition 
    for i = 1, #conditionIds do
        local condition = Data._conditionInfo[conditionIds[i]]
        table.insert(conditions, condition)
    end
    return conditions
end

return _M