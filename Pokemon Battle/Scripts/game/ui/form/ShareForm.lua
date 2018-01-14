local _M = class("ShareForm", BaseForm)

local PlayerLog = require("PlayerLog")

local FORM_SIZE = cc.size(640, 280)

function _M.create(logId)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(logId)
    return panel
end

function _M:init(logId)
    self._logId = logId

    _M.super.init(self, FORM_SIZE, Str(STR.SHARE), 0)

    local form = self._form

    -- edit box
    local editor = V.createEditBox("img_com_bg_58", cc.rect(57, 14, 2, 2), cc.size(500, 60), Str(STR.INPUT_SHARE_TEXT), true)
    lc.addChildToPos(form, editor, cc.p(lc.w(form) / 2, lc.bottom(self._titleFrame) - 20 - lc.h(editor) / 2))
    self._editor = editor

    local btnShare = V.createScale9ShaderButton("img_btn_2", function() self:share() end, V.CRECT_BUTTON, 120)
    btnShare:addLabel(Str(STR.SHARE))
    lc.addChildToPos(form, btnShare, cc.p(lc.right(editor) - lc.w(btnShare) / 2, 80))
    self._btnShare = btnShare

    -- time
    local dt = P._nextShareBattle - ClientData.getCurrentTime()
    if dt > 0 then
        self:scheduleUpdateWithPriorityLua(function(dt)
            local timeRemain = P._nextShareBattle - ClientData.getCurrentTime()
            if timeRemain < 0 then
                self:updateTip("")
                self:unscheduleUpdate()
            else
                local tip = string.format(Str(STR.SHARE_TIME), ClientData.formatPeriod(timeRemain))
                self:updateTip(tip)
            end
        end, 0)
    end
end

function _M:updateTip(tip)
    if self._tip then
        self._tip:removeFromParent()
        self._tip = nil
    end

    local tipLabel = V.createBoldRichText(tip, V.RICHTEXT_PARAM_DARK_S1)
    lc.addChildToPos(self._form, tipLabel, cc.p(lc.left(self._editor) + lc.w(tipLabel) / 2, lc.y(self._btnShare)))
    self._tip = tipLabel
end

function _M:share()
    local logId = self._logId
    local shareText = self._editor:getText()
    local dt = P._nextShareBattle - ClientData.getCurrentTime()
    
    if dt > 0 then
        ToastManager.push(string.format(Str(STR.SHARE_TIME), ClientData.formatPeriod(dt)))

    elseif lc.utf8len(shareText) > ClientData.MAX_INPUT_LEN  then
        ToastManager.push(Str(STR.MESSAGE)..string.format(Str(STR.CANNOT_MORE_THAN), ClientData.MAX_INPUT_LEN))

    else
        V.getActiveIndicator():show(Str(STR.WAITING), nil, self)
        self._isWaitingShare = true
        ClientData.sendBattleShare(logId, shareText)
    end
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listeners = {}
    table.insert(self._listeners, lc.addEventListener(Data.Event.log_dirty, function(event)
        self:onLogEvent(event)
    end))

    table.insert(self._listeners, lc.addEventListener(Data.Event.log_shared, function(event)
        self:onLogEvent(event)
    end))
end

function _M:onExit()
    _M.super.onExit(self)

    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
end

function _M:onLogEvent(event)
    local indicator = V.getActiveIndicator()
    if not self._isWaitingShare or event._logId ~= self._logId then return end

    indicator:hide()
    if event._event == PlayerLog.Event.log_item_dirty then
        P._nextShareBattle = ClientData.getCurrentTime() + Data._globalInfo._battleShareCD * 60
        ToastManager.push(Str(STR.SHARE_SUCCESS))

    elseif event._event == PlayerLog.Event.log_already_shared then
        ToastManager.push(Str(STR.BATTLE_SHARED))

    end

    self:hide()
end

return _M