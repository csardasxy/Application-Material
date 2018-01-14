local _M = class("SelectRegionForm", BaseForm)

local FORM_SIZE = cc.size(940, 600)

local REGION_PER_PAGE = 10

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
    return panel    
end

function _M:init()
    _M.super.init(self, FORM_SIZE, Str(STR.REGION_TITLE), bor(BaseForm.FLAG.ADVANCE_TITLE_BG))
    
    self:initTabArea()
    self:initList()

    self._tabArea:focusAtPos(1)
end

function _M:initTabArea()
    local maxRegion = ClientData._regionCount

    local orderedRegions = {}
    for _, region in pairs(ClientData._regions) do
        table.insert(orderedRegions, region)
    end
    table.sort(orderedRegions, function(a, b) return a._id < b._id end)
    self._orderedRegions = orderedRegions

    local tabs = {}
    for i = 1, maxRegion, 10 do
        local str = string.format(Str(STR.REGION_A_TO_B), i, math.min(i + 9, maxRegion))
        table.insert(tabs, 1, {_str = str, _index = i})
    end

    if #ClientData._historyRegion > 0 then
        table.insert(tabs, 1, {_str = Str(STR.REGION_HISTORY), _index = 0})
    end

    local tabArea = V.createVerticalTabListArea(lc.h(self._form) - _M.TOP_MARGIN - _M.BOTTOM_MARGIN, tabs, function(tab, isSameTab, isUserBehavior) self:showTab(tab._index, not isSameTab, isUserBehavior) end)
    lc.addChildToPos(self._form, tabArea, cc.p(_M.LEFT_MARGIN + lc.w(tabArea) / 2 - 12, lc.h(self._form) / 2))
    self._tabArea = tabArea
end

function _M:initList()
    local listW = lc.w(self._form) - _M.LEFT_MARGIN - _M.RIGHT_MARGIN - lc.w(self._tabArea) + 6
    local listH = lc.h(self._tabArea) + 4

    local list = lc.List.createV(cc.size(listW, listH), 20, 8)
    lc.addChildToPos(self._form, list, cc.p(lc.right(self._tabArea), 15))
    self._list = list
end

function _M:showTab(tabIndex, isForce, isUserBehavior)
    if not isForce then return end

    self._focusTabIndex = tabIndex
    self:refreshList()
end

function _M:refreshList()
    local list, tabIndex = self._list, self._focusTabIndex
    if tabIndex == 0 then
        list:bindData(ClientData._historyRegion, function(item, history) self:setOrCreateHistoryItem(item, history) end, math.min(10, #ClientData._historyRegion))
        for i = 1, list._cacheCount do
            local item = self:setOrCreateHistoryItem(nil, ClientData._historyRegion[i])
            list:pushBackCustomItem(item)
        end

        list:setBounceEnabled(true)

    else
        local regions = {}
        for i = tabIndex, tabIndex + 9, 2 do
            table.insert(regions, {self._orderedRegions[i], self._orderedRegions[i + 1]})
        end

        list:bindData(regions, function(item, regions) self:setOrCreateRegionItem(item, regions) end, math.min(5, #regions))
        for i = 1, list._cacheCount do
            local item = self:setOrCreateRegionItem(nil, regions[i])
            list:pushBackCustomItem(item)
        end

        list:setBounceEnabled(false)

    end

    list:refreshView()
    list:jumpToTop()
end

function _M:setOrCreateHistoryItem(item, history)
    if item == nil then
        item = ccui.Widget:create()
        item:setContentSize(570, 80)

        local btn = V.createScale9ShaderButton("img_com_bg_2", nil, V.CRECT_COM_BG2, lc.w(item), 50)
        btn:setColor(lc.Color3B.black)
        btn:setOpacity(100)
        lc.addChildToPos(item, btn, cc.p(lc.w(btn) / 2, lc.h(item) / 2))
        item._btn = btn
    
        --local avatar = UserWidget.create(nil, UserWidget.Flag.LEVEL_NAME, 0.7)
        local avatar = UserWidget.create(nil, UserWidget.Flag.LEVEL_NAME, 1.0)
        avatar:setScale(0.7)
        lc.addChildToPos(btn, avatar, cc.p(lc.w(avatar) / 2 - 40, lc.h(btn) / 2))
        item._avatar = avatar

        avatar._nameArea:setPosition(lc.right(avatar._frame), lc.y(avatar._frame))
        --avatar._nameArea._bg:setColor(cc.c3b(255, 220, 140))

        local region = V.createTTF("", V.FontSize.S1)
        region:setAnchorPoint(1.0, 0.5)        
        lc.addChildToPos(btn, region, cc.p(lc.w(btn), lc.h(btn) / 2))
        item._region = region
    end

    item._history = history

    item._btn._callback = function()
        if self._callback then
            self._callback(history._rid)
        end

        self:hide()
    end

    item._avatar:setUser(history)

    local region = ClientData._regions[history._rid]
    item._region:setString(ClientData.genFullRegionName(region._id, region._name))

    return item
end

function _M:setOrCreateRegionItem(item, regions)
    if item == nil then
        item = ccui.Widget:create()
        item:setContentSize(570, 80)

        local createSubItem = function()
            local btn = V.createScale9ShaderButton("img_com_bg_2", nil, cc.rect(8, 14, 1, 1), lc.w(item) / 2 - 20, 50)
            btn:setColor(lc.Color3B.black)
            btn:setOpacity(100)

            local label = V.createTTF("", V.FontSize.S1)
            label:setAnchorPoint(0, 0.5)
            lc.addChildToPos(btn, label, cc.p(12, lc.h(btn) / 2))
            btn._label = label

            local flag = lc.createSprite("img_region_full")            
            lc.addChildToPos(btn, flag, cc.p(lc.w(btn) - lc.w(flag) / 2 + 10, lc.h(btn) / 2))
            btn._flag = flag

            return btn
        end

        item._left = createSubItem()
        lc.addChildToPos(item, item._left, cc.p(lc.w(item._left) / 2, lc.h(item) / 2))

        item._right = createSubItem()
        lc.addChildToPos(item, item._right, cc.p(lc.w(item) - lc.w(item._right) / 2, lc.h(item) / 2))
    end

    local updateItem = function(subItem, region)
        subItem._region = region

        if region then
            subItem:setVisible(true)

            subItem._callback = function()
                if self._callback then
                    lc.log("Select region: %d", region._id)
                    self._callback(region._id)
                end

                self:hide()
            end

            local flagName
            if region._isRecommend then
                flagName = "img_region_recommend"
            elseif region._isNew then
                flagName = "img_region_new"
            elseif region._status == Region_pb.PB_TYPE_FULL then
                flagName = "img_region_full"
            end

            if flagName then
                subItem._flag:setSpriteFrame(flagName)
                subItem._flag:setVisible(true)
            else
                subItem._flag:setVisible(false)
            end

            subItem._label:setString(ClientData.genFullRegionName(region._id, region._name))
        else
            subItem:setVisible(false)
        end
    end    

    updateItem(item._left, regions[1])
    updateItem(item._right, regions[2])
    
    return item
end

return _M