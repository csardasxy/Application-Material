local _M = class("DailyTaskRewardForm", BaseForm)

local ITEM_SIZE = cc.size(190, 190)
local ITEM_GAP = 30
local COL_ITEM_COUNT = 3
local INFO_AREA_SIZE = cc.size(240, 120)
local FORM_SIZE = cc.size(980, 486)
local CardInfoPanel = require("CardInfoPanel")

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
        
    return panel 
end

function _M:init()
    --if not _M.super.init(self, ClientData.SceneId.depot, STR.SID_FIXITY_NAME_1016, BaseUIScene.STYLE_TAB, true) then return false end
    _M.super.init(self, FORM_SIZE, Str(STR.ACTIVE_BONUS), bor(BaseForm.FLAG.ADVANCE_TITLE_BG))

    local tabs = {
        {_str = Str(STR.DAILY_TASK), _index = 1},
        --{_str = Str(STR.MY)..Str(STR.ARTIFACT), _index = 2}, 
    }
    --V.addVerticalTabButtons(self, tabs, lc.top(self._frame) - 80, lc.left(self._frame) - 124, 580)
    
    local tabArea = V.createHorizontalTabListArea(lc.w(self._frame) - 40, tabs, function(tab) self:showTab(tab._index) end)
    lc.addChildToPos(self._frame, tabArea, cc.p(V.FRAME_INNER_LEFT + lc.w(tabArea) / 2, lc.h(self._frame) - 100), 3)
    self._tabArea = tabArea

    local bgPanel = lc.createSprite{_name = "img_troop_bg_2", _crect = cc.rect(20, 15, 1, 1), _size = cc.size(lc.w(self._frame) - V.FRAME_INNER_RIGHT - V.FRAME_INNER_LEFT, lc.bottom(self._tabArea) - 10)}
    lc.addChildToPos(self._frame, bgPanel, cc.p(lc.cw(self._frame), lc.bottom(self._tabArea) - lc.ch(bgPanel) + 5))
    self._bgPanel = bgPanel

    -- FIX LATER
    local pointBg = lc.createSprite("daily_active_bg")
    lc.addChildToPos(bgPanel, pointBg, cc.p(lc.cw(bgPanel), lc.h(bgPanel) - 50))

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
    local bar = ClientView.createBoxProgressBar(data, 580, function (sender)
        local bonus = bonuses[sender._index]
        if bonus:canClaim() then
            local result = ClientData.claimBonus(bonus)
            ClientView.showClaimBonusResult(bonus, result)
            sender._bones._claimed = bonus._isClaimed
            self._bar.update(P._dailyActive)
        else
            require("ActiveChestForm").create(sender._index, bonus):show()
        end
    end)
    lc.addChildToPos(bgPanel, bar, cc.p(lc.cw(bgPanel) - 10, lc.ch(bgPanel) - 80))

    bar.update(P._dailyActive)
    self._bar = bar


    --self._tabArea._focusTabIndex = 1
    --[[
    self:syncData()

    self._listeners = {}

    table.insert(self._listeners, lc.addEventListener(Data.Event.use_prop, function(event) 
        self:onPropUsed(event) 
    end))
    
    self._tabArea:showTab(1)
    ]]
end

function _M:syncData()
    --_M.super.syncData(self)

    self:prepareData()

    self:showTab(self._tabArea._focusTabIndex or 1, true)
end

function _M:createArea()
    local area = ccui.Layout:create()
    area:setContentSize(cc.size(lc.w(self._bgPanel) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, lc.h(self._bgPanel) - V.FRAME_INNER_TOP - V.FRAME_INNER_BOTTOM))
    area:setAnchorPoint(0.5, 0.5)
    area:setClippingEnabled(true)
    lc.addChildToCenter(self._bgPanel, area)
    return area
end

function _M:createDepotArea()
    self._depotArea = self:createArea()
    lc.addChildToPos(self._depotArea, list, cc.p(0, 0))
    self._depotArea._list = list
end

function _M:createArtifactArea()
    self._artifactArea = self:createArea()

    local list = lc.List.createH(cc.size(lc.w(self._artifactArea), lc.h(self._artifactArea)), 20, ITEM_GAP)
    lc.addChildToPos(self._artifactArea, list, cc.p(0, 0))
    self._artifactArea._list = list
end

function _M:prepareData()
    local props, artifacts = {}, {}
    for _, v in pairs(P._propBag._props) do
        if v._info._type > 0 and v._info._rank > 0 then
            if v._info._type == Data.PropsType.artifact then
                artifacts[#artifacts + 1] = v
            else
                props[#props + 1] = v
            end
        end
    end
    table.sort(props, function(a, b) return a._info._rank < b._info._rank end)
    table.sort(artifacts, function(a, b) return a._info._id < b._info._id end)

    self._props = props
    self._artifacts = artifacts
end

function _M:showTab(index, isForce)

    if self._tabArea._focusTabIndex == index and not isForce then 
    return 
    end
    
    --self._tabArea:showTab(index)
    --[[
    if index == 1 then
        self._depotArea:setVisible(true)
        self._artifactArea:setVisible(false)
        self:refreshItemList(0)
    elseif index == 2 then
        self._depotArea:setVisible(false)
        self._artifactArea:setVisible(true)
        self:refreshItemList(Data.PropsType.artifact)
    end
    ]]
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

end

function _M:onExit()
    _M.super.onExit(self)
        for _, listener in ipairs(self._listeners) do
        lc.Dispatcher:removeEventListener(listener)
    end
end

function _M:onCleanup()
    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
    
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename(BG_NAME))

    _M.super.onCleanup(self)
end

function _M:onMsg(msg)
    if _M.super.onMsg(self, msg) then return true end
    
    local msgType = msg.type
    local msgStatus = msg.status
    
    if msgType == SglMsgType_pb.PB_TYPE_USER_COLLECT_GOLD then
        local collectGoldResp = msg.Extensions[User_pb.SglUserMsg.user_collect_gold_resp]
        local gold = collectGoldResp.gold
        local credit = collectGoldResp.credit

        self:onGoldCollected(gold, credit)
    end
end

function _M:onPropUsed(event)
    local prop, useCount = event._prop, event._useCount
    if prop._count == 0 then
        self:refreshItemList(0)
    else
        local items = self._depotArea._list:getItems()
        for _, item in ipairs(items) do
            for _, propItem in ipairs(item._props) do
                if propItem then
                    if propItem._icon._data._infoId == prop._infoId then
                        propItem._icon:resetData(prop)
                    end
                end
            end
        end
    end
end

return _M