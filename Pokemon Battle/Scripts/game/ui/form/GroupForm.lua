local _M = class("GroupForm", BaseForm)

local FORM_SIZE = cc.size(960, 700)

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
    
    return panel
end

function _M:init()
    _M.super.init(self, FORM_SIZE, Str(STR.JOIN_GROUP), bor(_M.FLAG.ADVANCE_TITLE_BG, _M.FLAG.SCROLL_V))
    
    local groupList = lc.List.createV(cc.size(lc.w(self._form) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT - 12, lc.bottom(self._titleFrame)), 20, 0)
    groupList:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(self._frame, groupList, cc.p(lc.cw(self._form), lc.ch(self._form)), -1)
    self._groupList = groupList

    self._indicator = V.showPanelActiveIndicator(self._form)
    ClientData.sendGetGroups()
end

function _M:updateView()
    local groups = P._playerUnion:getGroups()
    self:updateGroupList(groups)
end

function _M:updateGroupList(groups)
    local list = self._groupList
    list:removeAllItems()

    if not groups then return end

    local listData = {}
    for _, group in pairs(groups) do
        table.insert(listData, group)
    end

    list:bindData(listData, function(item, group)
        self:setOrCreateGroupItem(item, group)
    end, math.min(#listData, 6))
    for i = 1, #listData do
        local item = self:setOrCreateGroupItem(nil, listData[i])
        
        list:pushBackCustomItem(item)
    end

    list:checkEmpty(Str(STR.LIST_EMPTY_GROUP))
end

function _M:setOrCreateGroupItem(layout, group)
    if layout == nil then
        layout = ccui.Widget:create()
        layout:setContentSize(lc.w(self._groupList) - 20, 180)

        showBtn = showBtn or true

        local bg = lc.createSprite{_name = "img_com_bg_35", _crect = V.CRECT_COM_BG35, _size = layout:getContentSize()}
        lc.addChildToCenter(layout, bg, -1)
        layout._bg = bg

        local deco = lc.createSprite('img_bg_deco_29')
        deco:setPosition(cc.p(lc.w(bg) - lc.cw(deco) / 2  - 60, lc.h(bg) / 2))
        deco:setScale(lc.h(bg) / lc.h(deco))
        bg:addChild(deco)

        local avatarSpr = V.createGroupAvatar(1)
        avatarSpr:setScale(0.9)
        lc.addChildToPos(layout, avatarSpr, cc.p(lc.cw(avatarSpr) + 20, lc.ch(layout) + 25))

        local groupNameBg = lc.createSprite("group_name_bg")
        lc.addChildToPos(layout, groupNameBg, cc.p(lc.x(avatarSpr), lc.bottom(avatarSpr) - 20))

        local groupNameLabel = V.createTTF("", V.FontSize.S3)
        lc.addChildToCenter(groupNameBg, groupNameLabel)

        local splitLine = lc.createSprite("my_split_line")
        splitLine:setScaleY( (lc.h(layout) - 15) / lc.h(splitLine))
        lc.addChildToPos(layout, splitLine, cc.p(lc.right(avatarSpr) + 30, lc.ch(layout) + 6))

        local startX = lc.right(avatarSpr) + 10
        local members, memItems = {}, {}
        for i = 1, Data.GROUP_NUM do
            local item = V.createUnionGroupMemItem(nil ,members[i], true, false)
            
            item._addFunc = function(sender)
                self:joinGroup(sender._groupId)
            end
            lc.addChildToPos(layout, item, cc.p(startX + i * 120 - 30, lc.ch(layout) + 10))
            table.insert(memItems, item)
        end

        for i = Data.GROUP_NUM + 1, 5 do
            local lockedSpr = lc.createSprite("group_mem_lock")
            lc.addChildToPos(layout, lockedSpr, cc.p(startX + i * 120 - 30, lc.ch(layout) + 15))
        end

--        local idLabel = V.createTTF("", V.FontSize.M2)
--        lc.addChildToPos(layout, idLabel, cc.p(lc.w(layout) - 20, lc.ch(layout)))

        layout.update = function(self, group, showBtn, showDetail)
            self._groupId = group._id
--            idLabel:setString(group._id)
            avatarSpr.update(group._avatar)
            groupNameLabel:setString(group._name)
            local members = group._members
            for i = 1, Data.GROUP_NUM do
                memItems[i]:update(group._id, members[i], showBtn, showDetail)
                memItems[i]._nameLabel:setColor(members[i] and V.COLOR_TEXT_DARK or V.COLOR_TEXT_BLUE_DARK)
            end
        end
    end

    layout:update(group, true, false)

    return layout
end

function _M:joinGroup(groupId)
    P._playerUnion:joinGroup(groupId)
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listeners = {}
    table.insert(self._listeners, lc.addEventListener(Data.Event.union_group_dirty, function(evt)
        if self._indicator then
            self._indicator:removeFromParent()
            self._indicator = nil
        end
        if P._playerUnion:getMyGroup() then
            self:hide()
        else
            self:updateView()
        end
    end))
end

function _M:onExit()
    _M.super.onExit(self)

    for _, listener in pairs(self._listeners) do
        lc.Dispatcher:removeEventListener(listener)
    end
end

function _M:onCleanup()
    _M.super.onCleanup(self)
    ClientData.sendStopUpdateGroups()
    ClientData.removeMsgListener(self)
end


return _M