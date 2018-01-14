local _M = class("UnionMemberForm", BaseForm)

local FORM_SIZE = cc.size(960, 720)

_M.Mode = 
{
    select          = 1,
    contribute      = 2,
    activity        = 3,
}

local TAG_CUSTOM = 1000

function _M.createSelect(max, callback)
    local panel = _M.create(_M.Mode.select, max)
    panel._bottomArea._btnOk._callback = function()
        callback(panel)
    end
    return panel
end

function _M.createContribute()
    return _M.create(_M.Mode.contribute)
end

function _M.createActivity()
    return _M.create(_M.Mode.activity)
end

function _M.create(mode, param)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(mode, param)
    return panel
end

function _M:init(mode, param)
    _M.super.init(self, FORM_SIZE, "Q", bor(_M.FLAG.ADVANCE_TITLE_BG, _M.FLAG.SCROLL_V))

    self._mode = mode    
    if mode == _M.Mode.select then
        self._maxCount = param
        self._selCount = 0
        self:initBottomArea()
    end

    -- Init member list
    self._form:setTouchEnabled(false)
    local listBg = lc.createSprite({_name = "img_troop_bg_2", _crect = cc.rect(20, 15, 1, 1), _size = cc.size(lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT - 20, lc.bottom(self._titleFrame) - 50 - (self._bottomArea and lc.h(self._bottomArea) or 0))})
    lc.addChildToPos(self._frame, listBg, cc.p(lc.cw(self._frame), lc.ch(self._frame) - 20), -1)
    local list = lc.List.createV(cc.size(lc.w(listBg) - 18, lc.h(listBg) - 18), 20, 10)
    lc.addChildToCenter(listBg, list)

    self._list = list

    self:updateList()
    self:updateTitle()
end

function _M:initBottomArea()
    local area = lc.createNode(cc.size(lc.w(self._frame), 95))
    lc.addChildToPos(self._frame, area, cc.p(lc.w(self._frame) / 2, lc.h(area) / 2), 1)
    self._bottomArea = area

--    local bottomBg = lc.createSprite("img_com_bg_8")
--    bottomBg:setScaleX(lc.w(area) / lc.w(bottomBg) + 0.1)
--    bottomBg:setScaleY(lc.h(area) / lc.h(bottomBg))
--    lc.addChildToPos(area, bottomBg, cc.p(lc.w(area) / 2, lc.h(area) / 2), -1)

    local topLine = V.createLineSprite("img_divide_line_1", lc.w(area) - 50)
    lc.addChildToPos(area, topLine, cc.p(lc.cw(area), lc.h(area)))

    local btnOk = V.createScale9ShaderButton("img_btn_1_s", nil, V.CRECT_BUTTON_S, 160)
    btnOk:addLabel(Str(STR.OK))
    lc.addChildToPos(area, btnOk, cc.p(lc.cw(area), lc.h(area) / 2 + 10), 1)
    area._btnOk = btnOk
end

function _M:updateList()
    self._members = nil
    if not P._playerUnion._hasDetailInfo then
        self._activeIndicator = V.showPanelActiveIndicator(self._form)
        performWithDelay(self, ClientData.sendGetMyUnionDetail, _M.ACTION_DURATION)
        return
    end

    local union, mode = P._playerUnion:getMyUnion(), self._mode
    local members = union:getMembers()

    if mode == _M.Mode.select then
        local selfIndex
        for i, mem in ipairs(members) do
            mem._isSelected = false
            if mem._id == P._id then
                selfIndex = i
            end
        end

        if selfIndex then
            table.remove(members, selfIndex)
        end

    elseif mode == _M.Mode.contribute then
        table.sort(members, function(a, b)
            local cA, cB = union:getContribution(a._id), union:getContribution(b._id)
            cA = cA[Data.ResType.union_act]-- + cA[Data.ResType.union_wood]
            cB = cB[Data.ResType.union_act]-- + cB[Data.ResType.union_wood]
            if cA == cB then
                if a._level == b._level then
                    return a._lastLogin > b._lastLogin
                end
                return a._level > b._level
            end        
            return cA > cB
        end)

    elseif mode == _M.Mode.activity then
        table.sort(members, function(a, b)
            local cA, cB = union:getContribution(a._id), union:getContribution(b._id)
            cA, cB = cA[Data.ResType.union_act], cB[Data.ResType.union_act]
            if cA == cB then
                if a._level == b._level then
                    return a._lastLogin > b._lastLogin
                end
                return a._level > b._level
            end        
            return cA > cB
        end)

    end

    local list = self._list

    -- Create items
    list:bindData(members, function(item, mem) self:setOrCreateItem(item, mem) end, math.min(7, #members))
    self._members = members

    for i = 1, list._cacheCount do
        local item = self:setOrCreateItem(nil, members[i])
        list:pushBackCustomItem(item)
    end
end

function _M:updateTitle()
    local mode, title = self._mode
    if mode == _M.Mode.select then
        title = string.format("%s%s (%d/%d)", Str(STR.SELECT), Str(STR.UNION_MEMBER), self._selCount, self._maxCount)
    elseif mode == _M.Mode.contribute then
        title = Str(STR.MEMBER_CONTRIBUTE)
    elseif mode == _M.Mode.activity then
        title = Str(STR.MEMBER_ACTIVITY)
    end

    self._titleLabel:setString(title)
end

function _M:addOneValueArea(parent, str, iconName, x, y)
    local label = V.createTTF(str..": ", V.FontSize.S1)
    label:setAnchorPoint(0, 0.5)
    lc.addChildToPos(parent, label, cc.p(x, y))

    local value
    if iconName then
        value = V.addIconValue(parent, iconName, 0, lc.right(label) + 16, lc.y(label))
    else
        value = V.createTTF("", V.FontSize.S1)
        value:setAnchorPoint(0, 0.5)
        lc.addChildToPos(parent, value, cc.p(lc.right(label) + 16, lc.y(label)))
    end

    return value
end

function _M:setOrCreateItem(item, mem)
    local union, mode = P._playerUnion:getMyUnion(), self._mode
    if item == nil then
        item = V.createUnionMemberItem(mem, lc.w(self._list), true)

        if mode == _M.Mode.select then
            local checkArea = V.createCheckLabelArea("")
            lc.addChildToPos(item, checkArea, cc.p(lc.w(item) - 80, lc.y(item._userArea)))
            item._checkArea = checkArea

            item._starArea:setVisible(false)

        elseif mode == _M.Mode.contribute then
            item._todayGold, item._todayWood = V.addUnionContribution(item, Str(STR.TODAY)..Str(STR.CONTRIBUTE), V.FontSize.S2, 480, lc.h(item) / 2 + 24)
            item._weekGold, item._weekWood = V.addUnionContribution(item, Str(STR.THIS_WEEK)..Str(STR.CONTRIBUTE), V.FontSize.S2, 480, lc.h(item) / 2 - 16)

        elseif mode == _M.Mode.activity then
            item._todayAct = self:addOneValueArea(item, Str(STR.TODAY)..Str(STR.ACTIVE), "img_icon_res14_s", 438, lc.h(item) / 2 )
--            item._weekAct = self:addOneValueArea(item, Str(STR.THIS_WEEK)..Str(STR.ACTIVE), "img_icon_res14_s", 600, lc.h(item) / 2 - 16)

        end

        if self._isRank then
            lc.offset(item._userArea, 90)
        end
    end

    item:removeChildrenByTag(TAG_CUSTOM)

    if self._isRank then
        local rankNum = mem._rank
        if rankNum <= 3 then
            local medal = lc.createSprite(string.format("img_medal_%d", rankNum))
            medal:setPosition(lc.w(medal) / 2 + 40, lc.h(item) / 2 + 5)
            item:addChild(medal, 0, TAG_CUSTOM)
        else
            local number = V.createBMFont(V.BMFont.num_48, string.format("%d", rankNum))        
            number:setPosition(70, lc.h(item) / 2 + 2)
            item:addChild(number, 0, TAG_CUSTOM)
        end
    end

    item:update(mem)

    if mode == _M.Mode.select then
        item._checkArea._callback = function(isCheck)
            if isCheck == mem._isSelected then return end

            if isCheck then
                if self._selCount >= self._maxCount then
                    ToastManager.push(string.format(Str(STR.UNION_MEMBER_SELECT_MAX), self._maxCount))
                    item._checkArea:setCheck(false)
                    return
                end
            end

            mem._isSelected = isCheck
            self._selCount = self._selCount + (isCheck and 1 or -1)
            self:updateTitle()
        end
        item._checkArea:setCheck(mem._isSelected)

    elseif mode == _M.Mode.contribute then
        local daily, weekly = union:getContribution(mem._id)
        item._todayGold:setString(ClientData.formatNum(daily[Data.ResType.union_act], 9999))
--        item._todayWood:setString(daily[Data.ResType.union_wood])

        item._weekGold:setString(ClientData.formatNum(weekly[Data.ResType.union_act], 9999))
--        item._weekWood:setString(weekly[Data.ResType.union_wood])

    elseif mode == _M.Mode.activity then
        local daily = union:getActivePoint(mem._id)
        item._todayAct:setString(ClientData.formatNum(daily[Data.ResType.union_personal_power], 9999))
--        item._weekAct:setString(weekly[Data.ResType.union_act])

    end

    return item
end

function _M:onEnter()
    _M.super.onEnter(self)

    local updateList = function()
        if self._activeIndicator then
            self._activeIndicator:removeFromParent()
            self._activeIndicator = nil
        end

        self:updateList()
    end

    local listeners = {}
    table.insert(listeners, lc.addEventListener(Data.Event.union_member_dirty, updateList))
    table.insert(listeners, lc.addEventListener(Data.Event.union_dirty, updateList))

    self._listeners = listeners
end

function _M:onExit()
    _M.super.onExit(self)

    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
end

return _M