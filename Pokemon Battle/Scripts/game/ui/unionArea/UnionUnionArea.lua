local _M = class("UnionUnionArea", lc.ExtendCCNode)

local AREA_WIDTH_MAX = 1000

function _M.create(unionId, w, h, isDetail)
    local area = _M.new(lc.EXTEND_NODE)
    area:setAnchorPoint(0.5, 0.5)
    area:setContentSize(w - 20, h)

    area:init(unionId, isDetail)

    area:registerScriptHandler(function(evtName)
       if evtName == "enter" then
            area:onEnter()
        elseif evtName == "exit" then
            area:onExit()
        end
    end)

    return area
end

function _M:init(unionId, isDetail)
    self._unionId = unionId

    self:initTopArea()
    
    local line = lc.createSprite("img_divide_line_11")
    line:setScaleX((lc.w(self) + 2) / lc.w(line))
    lc.addChildToPos(self, line, cc.p(lc.cw(self), lc.bottom(self._topArea) + 12))

    local memBgPanel = lc.createSprite({_name = "img_troop_bg_2", _crect = cc.rect(20, 15, 1, 1), _size = cc.size(isDetail and lc.w(self) - 40 or lc.w(self) - V.UNION_BUTTON_AREA_SIZE.width - 40, lc.bottom(self._topArea) - 40)})
    lc.addChildToPos(self, memBgPanel, cc.p(lc.w(self) - 20 - lc.cw(memBgPanel), lc.bottom(self._topArea) - lc.ch(memBgPanel) - 10))
    local memList = lc.List.createV(cc.size(lc.w(memBgPanel) - 18, lc.h(memBgPanel) - 18), 6, 10)
    lc.addChildToCenter(memBgPanel, memList)
    self._memList = memList
end

function _M:initTopArea()
    local isSelfUnion = (self._unionId == P._unionId)
    local topBg = lc.createNode()
    topBg:setContentSize(cc.size(lc.w(self), 248))
    lc.addChildToPos(self, topBg, cc.p(lc.w(self) / 2, lc.h(self) - lc.h(topBg) / 2 - 8), 1)
    self._topArea = topBg
    
    local unionWidget = require("UnionWidget").create(self, true, true)
    self._unionWidget = unionWidget
    lc.addChildToPos(topBg, unionWidget, cc.p(lc.cw(unionWidget), lc.ch(topBg)))

    local descBg = lc.createSprite{_name = "img_troop_bg_2", _crect = cc.rect(20, 15, 1, 1), _size = cc.size(lc.w(topBg) - 540, 150)}
    descBg:setOpacity(127)
    lc.addChildToPos(topBg, descBg, cc.p(lc.w(topBg) - lc.cw(descBg) - 20, lc.ch(topBg) - 6))
    local descTitle = V.createTTFStroke(Str(STR.UNION_SUMMARY), V.FontSize.S2, V.COLOR_TEXT_ORANGE)
    
    --[[local titleBg = lc.createSprite('icon_mask')
    titleBg:setCascadeOpacityEnabled(true)
    titleBg:setScale(330 / lc.w(titleBg), 40 / lc.h(descTitle))
    titleBg:setAnchorPoint(0.5, 1)
    lc.addChildToPos(topBg, titleBg, cc.p(math.floor(lc.left(descBg) + lc.cw(descTitle)), lc.top(descBg) - 5))]]

    lc.addChildToPos(descBg, descTitle, cc.p(lc.cw(descBg), lc.h(descBg) + 2 + lc.ch(descTitle)))

    local desc = V.createTTF("", V.FontSize.S2, nil, cc.size(300, 0), cc.TEXT_ALIGNMENT_LEFT)
    desc:setAnchorPoint(0, 1)
    desc:setLineBreakWithoutSpace(true)
    lc.addChildToPos(descBg, desc, cc.p(17, lc.bottom(descTitle) - 10))
    self._desc = desc

end

function _M:popSelectPanel(parent, buttonDefs)
    local panel = require("TopMostPanel").ButtonList.create(cc.size(200, lc.h(self)))
    if panel then
        local gPos = lc.convertPos(cc.p(lc.w(parent) / 2, lc.h(parent) / 2), parent)
        panel:setButtonDefs(buttonDefs)
        panel:setPosition(gPos.x, gPos.y - lc.h(panel) / 2 - 24)
        panel:linkNode(parent)
        panel:show()
    end
end

function _M:updateView(union)
    self._unionWidget._badge:update(union._badge, union._word)

    local nameArea = self._unionWidget._nameArea
    nameArea._level:setString(tostring(union._level))
    nameArea:setName(union._name)

    self._unionWidget._id:setString(ClientData.convertId(union._id))
    self._unionWidget._member:setString(string.format("%d/%d", union:getMembersNum(), union._memberCapacity))

    if union._announce and union._announce ~= "" then
        self._desc:setString(union._announce)
        self._desc:setColor(V.COLOR_TEXT_LIGHT)
    else
        self._desc:setString(Str(STR.UNION_SUMMARY))
        self._desc:setColor(V.COLOR_TEXT_GRAY)
    end

    self:updateMemberList(union:getMembers())

    local isSelfUnion = (self._unionId == P._unionId)
    if isSelfUnion then
        local curExp = union._act
        local isMax, levelUpExp = P._playerUnion:getUnionUpgradeExp()
        if not isMax then
            self._unionWidget._expBar.update(curExp, curExp + levelUpExp)
        else
            self._unionWidget._expBar._label:setString(Str(STR.UNION_LEVEL_MAX))
        end
    end
end

function _M:updateMemberList(members)
    table.sort(members, function(a, b)  
        if a._unionJob == b._unionJob then
            if a._level == b._level then
                return a._lastLogin > b._lastLogin
            end
            return a._level > b._level
        end        
        return a._unionJob > b._unionJob
    end)

    local list = self._memList

    -- Create items
    list:bindData(members, function(item, mem) self:setOrCreateMemberItem(item, mem) end, math.min(6, #members))

    for i = 1, list._cacheCount do
        local item = self:setOrCreateMemberItem(nil, members[i])
        list:pushBackCustomItem(item)
    end
end

function _M:setOrCreateMemberItem(item, mem)
    local isSelfUnion = (self._unionId == P._unionId)

    if item == nil then
        item = V.createUnionMemberItem(mem, lc.w(self._memList), true)

        if not isSelfUnion and not P:isUserAdmin() then
            item._lastLogin:setVisible(false)
            item._lastLogin._value:setVisible(false)

            --lc.offset(item._userArea._nameArea, 0, -20)
            --lc.offset(item._job, 0, -20)
        end
    end

    item:update(mem)

    if isSelfUnion then
        if item._btn then
            item._btn:removeFromParent()
            item._btn = nil
        end

        --[[
        if mem._id == P._id then
            local btn = V.createItemCountArea(Data.PropsId.yubi, ClientData.getPropIconName(7024), 180)
            lc.addChildToPos(item, btn, cc.p(lc.w(item) - 30 - lc.w(btn) / 2, lc.h(item) / 2 + 2))
            item._btn = btn
            
        elseif mem._level > P._level then
            local btn = V.createShaderButton("img_btn_1", function() require("UnionWorshipForm").create(mem):show() end)
            btn:addLabel(Str(STR.WORSHIP))
            lc.addChildToPos(item, btn, cc.p(lc.w(item) - 30 - lc.w(btn) / 2, lc.h(item) / 2 + 2))
            item._btn = btn
        end
        ]]
    end

    return item
end

function _M:onEnter()
    self._listeners = {}
    table.insert(self._listeners, lc.addEventListener(Data.Event.user_dirty, function(event)
        local items = self._memList:getItems()
        for _, item in ipairs(items) do
            if item._member == event._data then
                self:setOrCreateMemberItem(item, event._data)
                break
            end
        end
    end))

--    table.insert())self._listeners, lc.addEventListener(Data.Event.prop_dirty, function(event)
--        if event._data._infoId == Data.PropsId.yubi then
--            local items = self._memList:getItems()
--            for _, item in ipairs(items) do
--                if item._member._id == P._id then
--                    item._btn._label:setString(P:getItemCount(Data.PropsId.yubi))
--                    break
--                end
--            end
--        end
--    end

    local updateView = function() self:updateView(P._playerUnion:getMyUnion()) end
    table.insert(self._listeners, lc.addEventListener(Data.Event.union_dirty, updateView))
    table.insert(self._listeners, lc.addEventListener(Data.Event.union_edit_dirty, updateView))
    table.insert(self._listeners, lc.addEventListener(Data.Event.union_member_dirty, updateView))
    table.insert(self._listeners, lc.addEventListener(Data.Event.union_level_upgrade, updateView))
    table.insert(self._listeners, lc.addEventListener(Data.Event.union_res_dirty, updateView))

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)

    -- Send packet
    if P._unionId == self._unionId then
        local myUnion = P._playerUnion:getMyUnion()
        if myUnion then
            self:updateView(myUnion)
        end
    else
        self._indicator = V.showPanelActiveIndicator(self)
        self._topArea:setVisible(false)
        performWithDelay(self, function() ClientData.sendGetUnionDetail(self._unionId) end, BaseForm.ACTION_DURATION)
    end
end

function _M:onExit()
    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end

    ClientData.removeMsgListener(self)
end

function _M:onMsg(msg)
    local msgType = msg.type
    
    if msgType == SglMsgType_pb.PB_TYPE_UNION_DETAIL then
        local resp = msg.Extensions[Union_pb.SglUnionMsg.union_detail_resp]
        if resp.union_info.id == self._unionId then
            local union = require("Union").create(resp.union_info, resp.member_info)
            if self._indicator then
                self._indicator:removeFromParent()
                self._indicator = nil
            end
    
            if union then
                self:updateView(union)
                self._topArea:setVisible(true)
            else
                if self._callback then
                    self._callback()
                end
            end
        end
    end
    
    return false
end

return _M