local _M = class("UnionLogForm", BaseForm)

local FORM_SIZE = cc.size(900, 700)

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
    return panel
end

function _M:init()
    _M.super.init(self, FORM_SIZE, Str(STR.UNION)..Str(STR.UNION_LOG), 0)
    
    self._form:setTouchEnabled(false)
    local listBg = lc.createSprite({_name = "img_troop_bg_2", _crect = cc.rect(20, 15, 1, 1), _size = cc.size(lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT - 20, lc.bottom(self._titleFrame) - 50 - (self._bottomArea and lc.h(self._bottomArea) or 0))})
    lc.addChildToPos(self._frame, listBg, cc.p(lc.cw(self._frame), lc.ch(self._frame) - 20), -1)
    local list = lc.List.createV(cc.size(lc.w(listBg) - 18, lc.h(listBg) - 18), 30, 10)
    lc.addChildToCenter(listBg, list)

    self._list = list

    if ClientData._unionLogs == nil then
        self._activeIndicator = V.showPanelActiveIndicator(self._form)
    else
        self:updateLogs()
    end
end

function _M:parseLog(pbMsg)
    local log = {_timestamp = pbMsg.timestamp / 1000, _content = ""}
    log._date = os.date("!*t", log._timestamp + ClientData._timezone)

    local user1Name, user2Name = pbMsg.user1.name
    if pbMsg:HasField("user2") then
        user2Name = pbMsg.user2.name
    end

    local action = pbMsg.type
    if action == Union_pb.PB_UNION_CREATE then
        log._content = string.format("|%s|%s|%s|", user1Name, Str(STR.CREATE_UNION), pbMsg.user1.union_name)

    elseif action == Union_pb.PB_UNION_JOIN then
        if user2Name then
            log._content = string.format("|%s|"..Str(STR.BE_INVITED_TO).."%s", user1Name, user2Name, Str(STR.UNION_JOIN_NEWS))
        else
            log._content = string.format("|%s|%s", user1Name, Str(STR.UNION_JOIN_NEWS))
        end

    elseif action == Union_pb.PB_UNION_KICKOUT then
        log._content = string.format("|%s|"..Str(STR.UNION_KICKOUT_NEWS), user1Name, user2Name)

    elseif action == Union_pb.PB_UNION_LEAVE then
        log._content = string.format("|%s|%s", user1Name, Str(STR.UNION_LEAVE_NEWS))

    elseif action == Union_pb.PB_UNION_TO_CO_LEADER or action == Union_pb.PB_UNION_TO_MEMBER then
        log._content = string.format("|%s|"..Str(STR.UNION_CHANGE_JOB_NEWS), user1Name, user2Name, Str(STR.ROOKIE + pbMsg.user2.union_title - 1))

    elseif action == Union_pb.PB_UNION_TO_LEADER then
        log._content = string.format("|%s|%s", user1Name, Str(STR.UNION_TO_LEADER))

    elseif action == Union_pb.PB_UNION_RESIGN then
        log._content = string.format("|%s|"..Str(STR.UNION_GIVE_LEADER_TO), user1Name, user2Name)

    elseif action == Union_pb.PB_UNION_UPGRADE then
        log._content = string.format("|%s|"..Str(STR.UNION_UPGRADE_NEWS), user1Name, pbMsg.param1)

    elseif action == Union_pb.PB_UNION_TECH_UPGRADE then
        local union = P._playerUnion:getMyUnion()
        if union then
            log._content = string.format("|%s|"..Str(STR.UNION_UPGRADE_TECH_NEWS), user1Name, Str(union._techs[pbMsg.param2]._info._nameSid), pbMsg.param1)
        else
            log._content = ""
        end

    elseif action == Union_pb.PB_UNION_DONATE then
        -- The log should be merged into one log later
        log._msg = pbMsg

    elseif action == Union_pb.PB_UNION_IMPEACHED then
        log._content = string.format("|%s|"..Str(STR.UNION_IMPEACHED_NEWS), user1Name)

    end

    return log
end

function _M:mergeLog(logs, mLogs)
    table.sort(mLogs, function(a, b) return a._timestamp > b._timestamp end)

    local action, mergedLog, year, month, day = mLogs[1]._msg.type, 0, 0, 0, 0
    if action == Union_pb.PB_UNION_DONATE then
        local merge = function(log, exp)
            if exp > 0 then
                log._content = string.format(Str(STR.NEWS_MEMBER_ALL_CONTRIBUTE), exp)
                table.insert(logs, log)
            end
        end

        local exp = 0
        for _, log in ipairs(mLogs) do
            local date = log._date
            if date.year ~= year or date.month ~= month or date.day ~= day then
                merge(mergedLog, exp)

                mergedLog, year, month, day = log, date.year, date.month, date.day
                exp = 0
            end
            
            for _, res in ipairs(log._msg.resource) do
                if res.info_id == Data.ResType.union_act then
                    exp = exp + res.num
                end
            end
        end

        merge(mergedLog, exp)
    end

    return log
end

function _M:updateLogs()
    local logs, list = ClientData._unionLogs, self._list
    list:bindData(logs, function(item, log) self:setOrCreateLogItem(item, log) end, math.min(25, #logs))

    for i = 1, list._cacheCount do
        if logs[i]._isDate == true and i ~= 1 then
            local item = self:createSeparator()
            list:pushBackCustomItem(item)
        end
        local item = self:setOrCreateLogItem(nil, logs[i])
        list:pushBackCustomItem(item)
    end

    list:forceDoLayout()
    list:jumpToTop()
end

function _M:createSeparator()
    local item = ccui.Widget:create()
    item:setContentSize(lc.w(self._form), 32)
    local separator = lc.createImageView("img_divide_line_5")
    separator:setScaleX((lc.w(item)) / lc.w(separator))
    lc.addChildToCenter(item, separator)
    return item
end

function _M:setOrCreateLogItem(item, log)
    if item == nil then
        item = ccui.Widget:create()
        item:setContentSize(830, 32)

        local label = V.createTTF("")
        label:setAnchorPoint(0, 0.5)
        lc.addChildToPos(item, label, cc.p(70, lc.h(item) / 2))
        item._label = label
    end

    item._log = log

    if item._removeElement then
        item._removeElement:removeFromParent()
    end

    if log._date then
        item._label:setString(string.format("%02d:%02d", log._date.hour, log._date.min))
        item._label:setColor(V.COLOR_LABEL_LIGHT)

        local content = V.createBoldRichText(log._content, V.RICHTEXT_PARAM_LIGHT_S2)
        content:setAnchorPoint(cc.p(0, 0.5))
        lc.addChildToPos(item, content, cc.p(150, lc.y(item._label)))
        item._removeElement = content

    else
        item._label:setString(log._content)
        item._label:setColor(V.COLOR_TEXT_LIGHT)
        --[[
        local bg = lc.createSprite{_name = "img_com_bg_2", _crect = V.CRECT_COM_BG2, _size = cc.size(300, 30)}
        bg:setColor(lc.Color3B.black)
        bg:setOpacity(100)
        lc.addChildToPos(item, bg, cc.p(lc.w(bg) / 2 + 50, lc.h(item) / 2), -1)
        item._removeElement = bg
        ]]
    end

    return item
end

function _M:removeIndicator()
    if self._activeIndicator then
        self._activeIndicator:removeFromParent()
        self._activeIndicator = nil
    end
end

function _M:onEnter()
    _M.super.onEnter(self)

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
end

function _M:onExit()
    _M.super.onExit(self)
     
    ClientData.removeMsgListener(self)
end

function _M:onShowActionFinished()
    if ClientData._unionLogs == nil then
        ClientData.sendGetUnionLog()   
    end
end

function _M:onMsg(msg)
    if msg.type == SglMsgType_pb.PB_TYPE_UNION_LOG then
        self:removeIndicator()

        local pbMsgs, logs, mergeLogs = msg.Extensions[Union_pb.SglUnionMsg.union_message_resp], {}, {}
        for _, pbMsg in ipairs(pbMsgs) do         
            local log = self:parseLog(pbMsg)
            if log._msg then
                mergeLogs[pbMsg.type] = mergeLogs[pbMsg.type] or {}
                table.insert(mergeLogs[pbMsg.type], log)
            else
                table.insert(logs, log)
            end
        end

        -- Merge logs
        for _, mLogs in pairs(mergeLogs) do
            self:mergeLog(logs, mLogs)
        end

        table.sort(logs, function(a, b) return a._timestamp > b._timestamp end)

        -- Insert time label to logs
        local i, year, month, day = 1, 0, 0, 0
        while i <= #logs do
            local date = logs[i]._date
            if (date.year ~= year or date.month ~= month or date.day ~= day) then
                year, month, day = date.year, date.month, date.day
                table.insert(logs, i, {_isDate = true, _content = string.format("%s%s%s%s%s%s", year, Str(STR.YEAR), month, Str(STR.MONTH), day, Str(STR.DAY_RI))})
                i = i + 1
            end

            i = i + 1
        end

        ClientData._unionLogs = logs

        self:updateLogs()

        return true
    end

    return false
end

return _M