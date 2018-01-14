local _M = class("ClashChestBonusForm", BaseForm)

local FORM_SIZE = cc.size(880, 680)
local TOP_AREA_HEIGHT = 200
local PROGRESS_BAR_SIZE = cc.size(800, 300)

_M.Tab = {
    daily = 1,
    season = 2,
    intro = 3,
}

function _M.create(tabIndex, grade)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(tabIndex, grade)
    return panel 
end

function _M:init(tabIndex, grade)
    _M.super.init(self, FORM_SIZE, Str(STR.BONUS), bor(BaseForm.FLAG.ADVANCE_TITLE_BG))

    local bg = lc.createSprite({_name = "img_troop_bg_2", _crect = cc.rect(19, 17, 1, 1), _size = cc.size(FORM_SIZE.width - 60, FORM_SIZE.height - 142)})
    lc.addChildToPos(self._frame, bg, cc.p(lc.cw(self._frame), lc.bottom(self._frame) + lc.ch(bg) + 32), -1)
    self._bg = bg
    
    self._grade = grade

    local clipNode = cc.ClippingNode:create()
    clipNode:setContentSize(self._bg:getContentSize())
    local stencil = cc.LayerColor:create(lc.Color4B.white, lc.w(self._bg) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, lc.h(self._bg))
    stencil:setPosition(V.FRAME_INNER_LEFT, 0)
    clipNode:setStencil(stencil)
    lc.addChildToCenter(self._bg, clipNode)
    self._clipNode = clipNode
    local form, btnW, btnH = clipNode, 120, 430

    local btnArrowLeft = V.createArrowButton(true, cc.size(btnW, btnH), function(sender) self:onBtnArrow(sender) end)
    lc.addChildToPos(form, btnArrowLeft, cc.p(_M.FRAME_THICK_LEFT + btnW / 2 - 10, lc.h(form) / 2 + 80))
    self._btnArrowLeft = btnArrowLeft
    if grade == Data.FindClashGrade.bronze then btnArrowLeft:setVisible(false) end

    local btnArrowRight = V.createArrowButton(false, cc.size(btnW, btnH), function(sender) self:onBtnArrow(sender) end)
    lc.addChildToPos(form, btnArrowRight, cc.p(lc.w(form) - _M.FRAME_THICK_RIGHT - btnW / 2 + 10, lc.h(form) / 2 + 80))
    self._btnArrowRight = btnArrowRight
    if grade == Data.FindClashGrade.legend then btnArrowRight:setVisible(false) end
    
    local area = self:createArea(grade)
    lc.addChildToPos(form, area, cc.p(lc.w(form) / 2, _M.FRAME_THICK_BOTTOM + 30 + lc.h(area) / 2))
    self._fieldArea = area

    local tabs = {
    {_index = _M.Tab.daily, _str = Str(STR.DAILY_TARGET)},
    {_index = _M.Tab.season, _str = Str(STR.SEASON_TARGET)},
    {_index = _M.Tab.intro, _str = Str(STR.REWARD_INTRO)},
    }

    V.addHorizontalTabButtons2(self._form, {Str(STR.DAILY_TARGET), Str(STR.SEASON_TARGET), Str(STR.REWARD_INTRO)}, lc.top(self._bg) + 51 + 21, lc.left(self._bg) - 107 - 122 - 19, 1600)

    self._form.showTab = function(form, index)
        form._tabArea:showTab(index)
        if index == _M.Tab.daily then
            self._bar:setVisible(true)
            self._seasonBar:setVisible(false)
            self._winNode:setVisible(true)
            self._pointNode:setVisible(false)
            self._fieldArea:setVisible(false)
            self._btnArrowLeft:setVisible(false)
            self._btnArrowRight:setVisible(false)
            
        elseif index == _M.Tab.season then
            self._bar:setVisible(false)
            self._seasonBar:setVisible(true)
            self._winNode:setVisible(false)
            self._pointNode:setVisible(true)
            self._fieldArea:setVisible(false)
            self._btnArrowLeft:setVisible(false)
            self._btnArrowRight:setVisible(false)

        elseif index == _M.Tab.intro then
            self._bar:setVisible(false)
            self._seasonBar:setVisible(false)
            self._winNode:setVisible(false)
            self._pointNode:setVisible(false)
            self._fieldArea:setVisible(true)
            
            if self._grade > Data.FindClashGrade.bronze then
                self._btnArrowLeft:setVisible(true)
            end
            if self._grade < Data.FindClashGrade.legend then
                self._btnArrowRight:setVisible(true)
            end

        end
        self:addChest()
    end

    local pointNode = lc.createNode()
    lc.addChildToPos(self._bg, pointNode, cc.p(lc.cw(self._bg), 50))
    self._pointNode = pointNode
    local pointTitle = V.createTTF(Str(STR.TROPHY_SEASON_MAX)..":", V.FontSize.M2)
    local pointIcon = lc.createSprite(string.format("img_icon_res%d_s", Data.ResType.clash_trophy))
--    pointIcon:setAnchorPoint(1, 0.5)
--    lc.addChildToPos(pointNode, pointIcon, cc.p(-30, 0))
    local pointBg = lc.createSprite({_name = "img_com_bg_57", _crect = V.CRECT_COM_BG57, _size = cc.size(80,40)})
--    pointBg:setAnchorPoint(0, 0.5)
--    lc.addChildToPos(pointNode, pointBg, cc.p(0, 0))
    local pointLabel = V.createTTF(P._playerFindClash._trophy, V.FontSize.M2)
    pointLabel:setAnchorPoint(0, 0.5)
    lc.addChildToCenter(pointBg, pointLabel)
    self._pointLabel = pointLabel
    lc.addNodesToCenterH(pointNode, {pointTitle, pointIcon, pointBg}, 10)

    local winNode = lc.createNode()
    lc.addChildToPos(self._bg, winNode, cc.p(lc.cw(self._bg), 50))
    self._winNode = winNode
    local winBg = lc.createSprite({_name = "img_com_bg_57", _crect = V.CRECT_COM_BG57, _size = cc.size(80,40)})
--    winBg:setAnchorPoint(0, 0.5)
--    lc.addChildToPos(winNode, winBg, cc.p(0, 0))
    local winTitle = V.createTTF(Str(STR.WIN_CONTINOUS_TODAY_MAX)..":", V.FontSize.M2)
--    winTitle:setAnchorPoint(1, 0.5)
--    lc.addChildToPos(winNode, winTitle, cc.p(0, 0))
    lc.addNodesToCenterH(winNode, {winTitle, winBg}, 0)
    self._winTitle = winTitle
    local winLabel = V.createTTF(P._ladderContLose == 1 and 0 or P._dailyClashWin, V.FontSize.M2)
    winLabel:setAnchorPoint(1, 0.5)
    lc.addChildToCenter(winBg, winLabel)
    self._winLabel = winLabel

    local bonuses = P._playerBonus._bonusDailyActive

    self:createBar()

    self:createSeasonBar()

    local chestNode = lc.createNode()
    chestNode:setContentSize(cc.size(400, 400))
    lc.addChildToPos(self._bg, chestNode, cc.p(lc.cw(self._bg), lc.ch(self._bg) + 25), 2)
    self._chestNode = chestNode

    self._form:showTab(tabIndex or _M.Tab.daily)

    self:addChest()

end

function _M:addChest()
    self._chestNode:removeAllChildren()

    local genChestParam = function(i)
        return P._playerFindClash:getChestGrade(i), i, Data.CardQuality.UR
    end
    if self._bar:isVisible() and not self._seasonBar:isVisible() then
        local index = #P._playerFindClash._chests
        local chestInfo = P._playerFindClash._chests[index]
        for i, info in ipairs(P._playerFindClash._chests) do
            if not info._prop._isOpened then
                index = i
                chestInfo = info
                break
            end
        end
-- fix later
        local chest
        if index == 0 or (chestInfo._prop._isOpened and index < 5) then
            chest = V.createClashFieldChest(genChestParam(index + 1))
            --[[
            chest = V.createShaderButton("img_pokemonBall", function(chest)
                require("ClashChestForm").create(genChestParam(index + 1)):show()
            end)]]
        else
            chest = V.createClashFieldChest(chestInfo._grade, index, Data.CardQuality.UR)
            --[[
            chest = V.createShaderButton("img_pokemonBall", function(chest)
                require("ClashChestForm").create(chestInfo._grade, index, Data.CardQuality.UR):show()
            end)]]
        end
        chest:setContentSize(240, 240)
        chest._bones:setPosition(cc.p(120, 120))
        chest._bones:setScale(0.84)
        lc.addChildToCenter(self._chestNode, chest)
        lc.offset(chest, -20, -8)
    elseif not self._bar:isVisible() and self._seasonBar:isVisible() then
        local chest = V.createClashTargetChest(P:getClashTargetStep())
        --[[
        local chest = V.createShaderButton("img_pokemonBall", function(sender) 
            local targetStep = P:getClashTargetStep()
            local bonus = P._playerBonus._bonusClashTarget[targetStep]
            if bonus and bonus:canClaim() then
                if ClientData.claimBonus(bonus) == Data.ErrorType.ok then
                    local RewardPanel = require("RewardPanel")
                    RewardPanel.create(bonus, RewardPanel.MODE_CLAIM):show()
    --                sender.update()±ÜÃâ±ÀÀ£
                    if sender._openCallback then
                        sender._openCallback()
                    end
                end
            else
                require("ClashTargetChestForm").create(P:getClashTargetStep()):show()
            end
        end)]]
        chest:setContentSize(240, 240)
        chest._bones:setPosition(cc.p(120, 120))
        chest._bones:setScale(0.84)
        lc.addChildToCenter(self._chestNode, chest)
        lc.offset(chest, -20, -8)
    end

end

function _M:createBar()
    local data = {}
    for i = 1, 5 do
        table.insert(data, i--[[{_darkSpr = "dark_point_big", _lightSpr = "light_point_big"}]])
    end
    local bar = V.createClashChestProgressBar(data)
    local barBg = lc.createSprite("res/jpg/daily_target_progress_bg.png")
    local barFront = lc.createSprite("res/jpg/daily_target_progress_front_5.png")
    lc.addChildToPos(self._bg, bar, cc.p(lc.cw(self._bg), lc.ch(self._bg) + 25))
    lc.addChildToCenter(bar, barBg, -1)
    lc.addChildToCenter(bar, barFront)
    self._bar = bar

    bar.updateWithAni()
end

function _M:createSeasonBar()
    local data = {{_val = Data._globalInfo._playerTitleTrophy[2], _darkSpr = "dark_point_big", _lightSpr = "light_point_big"}}
    local bonuses = P._playerBonus._bonusClashTarget
    for i,bonus in ipairs(bonuses) do
        table.insert(data, {_val = bonus._info._val, _darkSpr = "dark_point_big", _lightSpr = "light_point_big"})
    end
    local bar = V.createClashSeasonProgressBar(data, 800)
    local barBg = lc.createSprite("res/jpg/daily_target_progress_bg.png")
    local barFront = lc.createSprite("res/jpg/daily_target_progress_front_7.png")
    lc.addChildToPos(self._bg, bar, cc.p(lc.cw(self._bg), lc.ch(self._bg) + 25))
    lc.addChildToCenter(bar, barBg, -1)
    lc.addChildToCenter(bar, barFront)
    self._seasonBar = bar

    bar.updateWithAni(P._playerBonus._bonusClashTarget[1]._value)
end


function _M:refreshView()
    self._pointLabel:setString(P._playerBonus._bonusClashTarget[1]._value)
    self._winLabel:setString(#P._playerFindClash._chests)
    if self._bar then
        self._bar.updateWithAni()
    end
    if self._seasonBar then
        self._seasonBar.updateWithAni(P._playerBonus._bonusClashTarget[1]._value)
    end
    self:addChest()
end

function _M:createArea(grade)
    local area = lc.createNode()
    area:setCascadeOpacityEnabled(true)

    local field = V.createClashFieldArea(grade, nil, true)
    field:setCascadeOpacityEnabled(true)

    local chests = {}
    for i = 1, 5 do
        local chest = V.createClashFieldChest(grade, i, i <= 3 and Data.CardQuality.R or (i <= 5 and Data.CardQuality.SR or Data.CardQuality.UR), true)
        chest:setCascadeOpacityEnabled(true)
        table.insert(chests, chest)
    end

    local w, h = lc.w(field) + 10, lc.h(field) + 8 + lc.h(chests[1])
    area:setContentSize(w, h)

    lc.addChildToPos(area, field, cc.p(lc.cw(area), lc.h(area) - lc.h(field) / 2))

    local chestBg = lc.createSprite({_name = "img_troop_bg_6", _crect =  cc.rect(19, 17, 1, 1), _size = cc.size(lc.w(self._bg) - 44, lc.h(chests[1]) + 45)})
    lc.addChildToPos(area, chestBg, cc.p(lc.cw(area), lc.ch(chestBg) - 37))
    local x, y = 80 - 24, lc.bottom(field) + 8
    for _, chest in ipairs(chests) do
        lc.addChildToPos(chestBg, chest, cc.p(x + lc.w(chest) / 2, y - lc.h(chest) / 2))
        x = x + lc.w(chest) + 35
    end

    return area
end

function _M:onBtnArrow(arrow)
    self._btnArrowLeft:setVisible(true)
    self._btnArrowRight:setVisible(true)

    local offset, x, y = lc.w(self._bg), lc.cw(self._bg), lc.y(self._fieldArea)
    local nextGrade, nextFieldArea
    if arrow == self._btnArrowLeft then
        nextGrade = self._grade - 1
    else
        nextGrade = self._grade + 1
        offset = -offset
    end

    nextFieldArea = self:createArea(nextGrade)

    self._btnArrowLeft:setVisible(nextGrade ~= Data.FindClashGrade.bronze)
    self._btnArrowRight:setVisible(nextGrade ~= Data.FindClashGrade.legend)

--    nextFieldArea:setOpacity(0)
    lc.addChildToPos(self._clipNode, nextFieldArea, cc.p(x - offset, y))

    local curFieldArea, duration = self._fieldArea, lc.absTime(0.5)
    curFieldArea:stopAllActions()
    curFieldArea:runAction(lc.sequence(lc.ease(lc.moveTo(duration, x + offset, y), "BackO"), lc.remove()))

    nextFieldArea:runAction(lc.ease(lc.moveTo(duration, x, y), "BackO"))
    self._fieldArea = nextFieldArea
    self._grade = nextGrade
end

function _M:onMsg(msg)
    local msgType = msg.type
    if msgType == SglMsgType_pb.PB_TYPE_USER_OPEN_CHEST then
        local resp = msg.Extensions[User_pb.SglUserMsg.user_open_chest_resp]

        local chest = V.getActiveIndicator():hide()
        
        P._propBag._props[chest._infoId]._isOpened = true
        chest:update(P._playerFindClash:getChestGrade(chest._infoId % 10))
        P._propBag._props[chest._infoId]:sendPropDirty()

        local RewardPanel = require("RewardPanel")
        RewardPanel.create(resp, RewardPanel.MODE_CHEST):show()


        self:addChest()

        return true
    end
    
    return false
end

function _M:onEnter()
    _M.super.onEnter(self)

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)

    self:refreshView()

    self._listeners = {}
    table.insert(self._listeners, lc.addEventListener(Data.Event.prop_dirty, function(event)        
        self:refreshView()
    end))
    table.insert(self._listeners, lc.addEventListener(Data.Event.trophy_dirty, function(event)        
        self:refreshView()
    end))
    table.insert(self._listeners, lc.addEventListener(Data.Event.clash_trophy_dirty, function(event)        
        self:refreshView()
    end))
    table.insert(self._listeners, lc.addEventListener(Data.Event.bonus_dirty, function(event)
        if event._data._type == Data.BonusType.clash_target then     
            self:refreshView()
        end
    end))
end

function _M:onExit()
    _M.super.onExit(self)
    ClientData.removeMsgListener(self)
    for _, listener in ipairs(self._listeners) do
        lc.Dispatcher:removeEventListener(listener)
    end

end

function _M:onCleanup()
    V.getMenuUI():updateDailyActiveFlag()
    _M.super.onCleanup(self)
    lc.TextureCache:removeTextureForKey("res/jpg/daily_target_bg.jpg")
end

return _M