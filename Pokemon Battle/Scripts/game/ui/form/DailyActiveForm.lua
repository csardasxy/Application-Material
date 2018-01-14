local _M = class("DailyActiveForm", BaseForm)

local FORM_SIZE = cc.size(1010, 700)
local TOP_AREA_HEIGHT = 180
local PROGRESS_BAR_SIZE = cc.size(800, 300)

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
    return panel 
end

function _M:init()
    _M.super.init(self, FORM_SIZE, Str(STR.FUND_TASK), bor(BaseForm.FLAG.ADVANCE_TITLE_BG))

    local bg = lc.createNode(cc.size(lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, TOP_AREA_HEIGHT))
    lc.addChildToPos(self._frame, bg, cc.p(lc.cw(self._frame), lc.bottom(self._titleLabel) - TOP_AREA_HEIGHT / 2 + 30), -1)
    self._topBg = bg

    -- active point
    local pointBg = lc.createSprite("daily_active_bg")
    lc.addChildToPos(bg, pointBg, cc.p(lc.cw(pointBg) + 80, lc.ch(bg) - 20))

    local pointLabel = V.createBMFont(V.BMFont.huali_26, P._dailyActive)
    pointLabel:setColor(V.COLOR_TEXT_INGOT)
    pointLabel:setAnchorPoint(0, 0.5)
    lc.addChildToPos(pointBg, pointLabel, cc.p(95, 26))
    self._pointLabel = pointLabel
    
    -- bonus
    local bonuses = P._playerBonus._bonusDailyActive

    local data = {}
    for i,bonus in ipairs(bonuses) do
        table.insert(data, {_val = bonus._info._val, _darkSpr = "dark_point", lightSpr = "light_point", _claimed = bonus._isClaimed})
    end
    local bar = V.createDailyTaskProgressBar(data, 680, function (sender)
        local bonus = bonuses[sender._index]
        if bonus:canClaim() then
            local result = ClientData.claimBonus(bonus)
            V.showClaimBonusResult(bonus, result)
            sender._bones._claimed = bonus._isClaimed
            self._bar.update(P._dailyActive)
        else
            require("ActiveChestForm").create(sender._index, bonus):show()
        end
    end)
    local barBg = lc.createSprite("res/jpg/daily_target_progress_bg.png")
    local barFront = V.createShaderButton("res/jpg/daily_target_progress_front_5.png", function() require("DailyTaskRewardForm").create():show() end)
    barFront:setZoomScale(0)
    local ball = lc.createSprite("img_pokemonBall")
    lc.addChildToCenter(bar, barBg, -1)
    lc.addChildToCenter(bar, barFront)
    lc.addChildToCenter(barFront, ball)
    lc.addChildToPos(bg, bar, cc.p(lc.cw(barBg), lc.bottom(pointBg) - lc.ch(barBg) - 4))
    self._bar = bar

    bar.update(P._dailyActive)

    self:createBottomArea()

end

function _M:refreshTasks()
    local i, delay = 0, 0
    for _, bonus in pairs(P._playerBonus._bonusFundTasks) do
        if not bonus._isClaimed then
            i = i + 1
            if i > 5 then break end
            delay = math.max(self._tasks[6-i].runActionUpdateBonus(bonus), delay)
        end
    end
    while i < 5 do
        i = i + 1
        delay = math.max(self._tasks[6-i].runActionUpdateBonus(nil), delay)
    end
    return delay
end

function _M:createBottomArea()
    local list = lc.List.createV(cc.size(lc.w(self._form) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT - lc.w(self._bar) - 10, 434), 41, 12)
    list:setAnchorPoint(0.5, 0.5)
    
    local fundTaskArea = ccui.Widget:create()
    local fundTaskBg = lc.createSprite({_name = "img_troop_bg_2", _crect = V.CRECT_COM_BG30, _size = cc.size(lc.w(self._form) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT - lc.w(self._bar) - 20, 450)})
    fundTaskArea:setContentSize(fundTaskBg:getContentSize())
    lc.addChildToPos(self._form, fundTaskBg, cc.p(lc.w(self._form) - V.FRAME_INNER_RIGHT - lc.cw(fundTaskBg) - 10, lc.h(self._form) - V.FRAME_INNER_TOP - lc.ch(fundTaskBg) - 45))
    lc.addChildToPos(fundTaskBg, list, cc.p(lc.cw(fundTaskBg) - 7, lc.ch(fundTaskBg) - 5))
    list:pushBackCustomItem(fundTaskArea)

    local tasks = {}
    for j = 1, 5 do 
        local task = V.setOrCreateFundTaskCell(nil, nil, j, true)
        task._claimBtn._callback = function(sender)
            self:onClaim(task)
        end
        table.insert(tasks, task)
    end
    lc.addNodesToCenterV(fundTaskArea, tasks, 36)
    self._tasks = tasks

    self:refreshTasks()

    local list2 = lc.List.createH(cc.size(lc.w(self._form) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, lc.h(self._form) - V.FRAME_INNER_BOTTOM - V.FRAME_INNER_TOP - 460), 0, 10)
    list2:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(self._form, list2, cc.p(lc.cw(self._form), V.FRAME_INNER_BOTTOM + lc.ch(list2) - 20))
    local callback1 = function (sender)
        if P:checkFindClash() then
            lc.pushScene(require("FindScene").create(Data.FindMatchType.clash))
            self:hide()
        else
            ToastManager.push(string.format(Str(STR.FINDSCENE_LOCKED), Str(Data._chapterInfo[1]._nameSid)))
        end
    end
    local callback2 = function (sender)
        if V.tryGotoFindLadder(true) then
            self:hide()
        end
    end
    local callback3 = function (sender)
        if V.tryGotoExpedition(true) then
            self:hide()
        end
    end
    local callback4 = function (sender)
        if V.tryGotoUnionBattle(true) then
            self:hide()
        end
    end
    local data = {
    {_title = Str(STR.FIND_CLASH_TITLE)..Str(STR.GET)..Str(STR.WIN),_callBack = callback1, _rewards = {{_str = Str(STR.TASK), _num = Str(STR.MULTIPY)..Data._globalInfo._ladderPowerGet}}},
    --{_title = Str(STR.FIND_ARENA_TITLE)..Str(STR.CAPTURE)..Str(STR.GET),_callBack = callback2, _rewards = {{_str = Str(STR.TASK), _num = Str(STR.MULTIPY)..Data._globalInfo._ladderExPowerGet}}},
    --{_title = Str(STR.FIND_UNION_BATTLE_TITLE)..Str(STR.GET)..Str(STR.WIN),_callBack = callback4, _rewards = {{_str = Str(STR.TASK), _num = Str(STR.MULTIPY)..Data._globalInfo._masswarPowerGet}}},
    --{_title = Str(STR.DEFEAT_CHALLENGER),_callBack = callback3, _rewards = {{_str = Str(STR.TASK), _num = Str(STR.MULTIPY)..Data._globalInfo._simpleNPCPowerGet}, {_str = "-", _num = Str(STR.MULTIPY)..Data._globalInfo._bossPowerGet}}},
    }
    local y = lc.bottom(self._titleLabel) - TOP_AREA_HEIGHT - 30
    for i, info in ipairs(data) do
        local item = self:createItem(info)
        list2:pushBackCustomItem(item)
    end
end

function _M:onClaim(sender)
    local result = ClientData.claimBonus(sender._bonus)
    V.showClaimBonusResult(sender._bonus, result)
    P._playerBonus._bonusFundTasks[sender._bonus._info._cid] = nil
    self:refreshTasks()
end

function _M:createItem(info)
    local layout = ccui.Widget:create()
    layout:setAnchorPoint(0.5, 0.5)
    layout:setContentSize(cc.size((lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT - 60) / 4, 120))

    local bg = lc.createSprite({_name = "card_info_widget", _size = layout:getContentSize(), _crect = cc.rect(25, 50, 2, 2)})
    lc.addChildToCenter(layout, bg)

    --[[
    local deco = lc.createSprite('img_bg_deco_29')
    V.setMaxSize(deco, lc.w(layout), lc.h(layout))
    lc.addChildToPos(layout, deco, cc.p(lc.w(layout) - lc.cw(deco) * deco:getScale(), lc.ch(layout)))
    
    local titleBg = lc.createSprite("img_deco_bar_01")
    lc.addChildToPos(layout, titleBg, cc.p(lc.cw(titleBg), lc.h(layout) - lc.ch(titleBg) - 5))
    ]]

    local titleLabel = V.createTTFStroke(info._title, V.FontSize.S3)--V.createTTF(info._title, V.FontSize.M2, V.COLOR_TEXT_WHITE)
    titleLabel:setColor(V.COLOR_TEXT_ORANGE)
    titleLabel:setScale(0.9)
    lc.addChildToPos(layout, titleLabel, cc.p(lc.cw(layout), lc.h(layout) - lc.ch(titleLabel) - 5))

    --local rewardLabels = {}
    local rewardNums = {}
    local x = 10
    local width = 180
    local gap = 40
    for i, reward in ipairs(info._rewards) do
        --local rewardLabel = V.createTTF(reward._str, V.FontSize.M2, V.COLOR_TEXT_WHITE)
        --rewardLabel:setAnchorPoint(0, 0.5)
        --lc.addChildToPos(layout, rewardLabel, cc.p(x + (i - 1) * width, lc.bottom(titleLabel) - 25))
        local rewardIcon = lc.createSprite("img_icon_res14_s")
        lc.addChildToPos(layout, rewardIcon, cc.p(30 + x + (i - 1) * width, lc.bottom(titleLabel) - 40))
        local numLabel = V.createTTF(reward._num, V.FontSize.M2, V.COLOR_TEXT_WHITE)
        numLabel:setAnchorPoint(0, 0.5)
        lc.addChildToPos(layout, numLabel, cc.p(lc.right(rewardIcon) + 4, lc.y(rewardIcon)))

        --table.insert(rewardLabels, rewardLabel)
        table.insert(rewardNums, numLabel)
    end

    local button = V.createScale9ShaderButton("img_btn_1_s", info._callBack, V.CRECT_BUTTON_S, 100)
    button:addLabel(Str(STR.GO))
    lc.addChildToPos(layout, button, cc.p(lc.w(layout) - 65, lc.ch(layout) - 10))

    --layout._rewardLabels = rewardLabels
    layout._rewardNums = rewardNums
    return layout
end

function _M:refreshView()
    self._pointLabel:setString(P._dailyActive)
    self._bar.update(P._dailyActive)
end

function _M:onEnter()
    _M.super.onEnter(self)

    self:refreshView()

    self._listeners = {}
    table.insert(self._listeners, lc.addEventListener(Data.Event.daily_active_dirty, function(event)        
        self:refreshView()
    end))
    table.insert(self._listeners, lc.addEventListener(Data.Event.fund_task_dirty, function(event)
        local tasks = clone(P._playerBonus._changedFundTasks)
        P._playerBonus._changedFundTasks = {}
        local delay = self:refreshTasks() + 0.1
        self:runAction(lc.sequence(delay, function()
            if table.maxn(tasks) > 0 then
                require("FundTasksPanel").create(tasks, Str(STR.FUND_TASK_RESET)):show()
            end 
        end))
    end))
--    table.insert(self._listeners, lc.addEventListener(Data.Event.bonus_dirty, function(event)
--        local bonus = event._data
--        if bonus._type == Data.BonusType.fund_task then
--            self:refreshTasks()
--        end
--    end))
end

function _M:onExit()
    _M.super.onExit(self)

    for _, listener in ipairs(self._listeners) do
        lc.Dispatcher:removeEventListener(listener)
    end

end

function _M:onCleanup()
    V.getMenuUI():updateDailyActiveFlag()
    _M.super.onCleanup(self)

end

return _M