local _M = class("GodPumpUnopendForm", BaseForm)

local FORM_SIZE = cc.size(600, 640)

local ITEM_HEIGHT = 180

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(logType, focusTab)
    return panel
end

function _M:init()
    _M.super.init(self, FORM_SIZE, Str(STR.LOTTERY_UNOPENED), bor(BaseForm.FLAG.ADVANCE_TITLE_BG))
    
    local list = lc.List.createV(cc.size(lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT - 32, lc.h(self._frame) - V.FRAME_INNER_TOP - V.FRAME_INNER_BOTTOM), 32, 10)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(self._form, list)
    lc.offset(list, 4, 0)
    self._list = list
    
end    

function _M:onEnter()
    _M.super.onEnter(self)

    if not self._data then
        ClientData.sendGetLotteryUnopened()
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

    local list = self._list

    -- Create items
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

        local progressTitle = V.createTTF(Str(STR.PROGRESS), V.FontSize.S2, V.COLOR_TEXT_DARK)
        lc.addChildToPos(item, progressTitle, cc.p(lc.cw(item) + 40, lc.ch(item) + 20))

        local bar = V.createLabelProgressBar(180)
        lc.addChildToPos(item, bar, cc.p(lc.cw(item) + 40, lc.ch(item) - 20))

        local probabilityTitle = V.createTTF(Str(STR.PROBABILITY), V.FontSize.S2, V.COLOR_TEXT_DARK)
        lc.addChildToPos(item, probabilityTitle, cc.p(lc.w(item) - 70, lc.ch(item) + 20))
        local probabilityLabel = V.createTTF("", V.FontSize.S2, V.COLOR_TEXT_DARK)
        lc.addChildToPos(item, probabilityLabel, cc.p(lc.w(item) - 70, lc.ch(item) - 20))

        item.update = function(info)
            if info then
                item._info = info

                local period = info._period
                number:setString(string.format(Str(STR.ISSUE_NO), period))
                bar._bar:setPercent(info._progress * 100 / 2500)
                bar._label:setString(info._progress.."/".."2500")
                local probability = math.min(100, info._count/2500 * 100)
                probabilityLabel:setString(string.format("%.2f", probability).."%")
                probabilityLabel:setColor(V.getProbabilityColor(probability))
            end
        end
    end
    item.update(info)
    return item
end

function _M:parseListData(listInfos)
    self._data = {}
    for i, info in ipairs(listInfos) do
        table.insert(self._data, {_period = info.period, _progress = info.lottery_progress, _count = info.lottery_count})
    end
    table.sort(self._data, function(A, B)
        return A._period > B._period
    end)
end

function _M:onMsg(msg)
    local msgType = msg.type
    if msgType == SglMsgType_pb.PB_TYPE_WORLD_LOTTERY_UNOPEN then
        local resp = msg.Extensions[World_pb.SglWorldMsg.lottery_unopen_list_resp]
        self:parseListData(resp)
        self:refreshList()
        return true
    end
    return false
end

return _M