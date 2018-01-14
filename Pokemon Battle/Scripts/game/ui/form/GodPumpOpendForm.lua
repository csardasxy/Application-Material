local _M = class("GodPumpOpendForm", BaseForm)

local FORM_SIZE = cc.size(600, 640)

local ITEM_HEIGHT = 180

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(logType, focusTab)
    return panel
end

function _M:init()
    _M.super.init(self, FORM_SIZE, Str(STR.LOTTERY_OPENED), bor(BaseForm.FLAG.ADVANCE_TITLE_BG))
    
    local list = lc.List.createV(cc.size(lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT - 32, lc.h(self._frame) - V.FRAME_INNER_TOP - V.FRAME_INNER_BOTTOM), 32, 10)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(self._form, list)
    lc.offset(list, 4, 0)
    
    self._list = list

end    

function _M:onEnter()
    _M.super.onEnter(self)

    if not self._data then
        ClientData.sendGetLotteryOpened()
        self._indicator = V.showPanelActiveIndicator(self._form, lc.bound(self._list))
        lc.offset(self._indicator, 0, 20)
    end
    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
end

function _M:onExit()
    _M.super.onExit(self)
    lc.Dispatcher:removeEventListener(self._listener)
    ClientData.removeMsgListener(self)
end

function _M:refreshList()
    if self._indicator then
        self._indicator:removeFromParent()
        self._indicator = nil
    end

    local data = self._data

    
    if data == nil then return end

    -- Create items
    local list = self._list
    list:bindData(data, function(item, info) self:setOrCreateItem(item, info) end, math.min(7, #data))

    for i = 1, list._cacheCount do
        local info = data[i]
        local item = self:setOrCreateItem(nil, info)
        list:pushBackCustomItem(item)
    end

    list:checkEmpty(Str(STR.LIST_EMPTY_NO_X))

    list:refreshView()
    list:gotoTop()
end

function _M:setOrCreateItem(item, info)    
    if item == nil then
        item = lc.createImageView{_name = "img_com_bg_35", _crect = V.CRECT_COM_BG35}
        item:setContentSize(cc.size(lc.w(self._list), 108))
        
        item:setTouchEnabled(true)
        item:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)

        local bar = lc.createSprite('img_bg_deco_35')
        lc.addChildToPos(item, bar, cc.p(lc.cw(bar), lc.ch(item) + 3))
        item._bar = bar

        local number = V.createBMFont(V.BMFont.huali_32, "")
        lc.addChildToPos(item, number, cc.p(64, lc.h(item) / 2 + 2))
        
        item:addTouchEventListener(function(sender, type)
            if type == ccui.TouchEventType.ended then
                if sender._info and self._list then
                    if sender._info._user._id ~= P._id then
                        V.operateUser(sender._info._user, sender)
                            require("ClashUserInfoForm").create(sender._info._user._id):show()
                    end
                end
            end
        end)

        local userArea = UserWidget.create(nil, UserWidget.Flag.REGION_NAME_UNION, 1.2)
        userArea:setScale(0.7)
        lc.addChildToPos(item, userArea, cc.p(150 + lc.w(userArea) / 2, lc.h(item) / 2 + 4))
        
        item._avatarArea = userArea

        item.update = function(info)
            if info then
                item._info = info

                local period = info._period
                number:setString(string.format(Str(STR.ISSUE_NO), period))

                local userArea = item._avatarArea
                userArea:setUser(info._user, true)
                userArea._regionArea:setPosition(cc.p(lc.right(userArea._frame), 0))
            end
        end
    end
    item.update(info)
    return item
end

function _M:parseListData(listInfos)
    self._data = {}
    for i, info in ipairs(listInfos) do
        local user = require("User").create(info.user_info)
        table.insert(self._data, {_period = info.period, _user = user})
    end
    table.sort(self._data, function(A, B)
        return A._period > B._period
    end)
end

function _M:onMsg(msg)
    local msgType = msg.type
    if msgType == SglMsgType_pb.PB_TYPE_WORLD_LOTTERY_OPENED then
        local resp = msg.Extensions[World_pb.SglWorldMsg.lottery_open_list_resp]
        self:parseListData(resp)
        self:refreshList()
        return true
    end
    return false
end

return _M