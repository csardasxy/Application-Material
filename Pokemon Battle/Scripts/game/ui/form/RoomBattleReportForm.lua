local _M = class("RoomBattleReportForm", BaseForm)

local FORM_SIZE = cc.size(900, 700)

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
    return panel
end

function _M:init()
    _M.super.init(self, FORM_SIZE, Str(STR.LOG), bor(BaseForm.FLAG.ADVANCE_TITLE_BG))
    P._playerRoom:sendGetRoomLog()
    self._indicator = V.showPanelActiveIndicator(self._form)
    self:initReplayList()
end

function _M:onEnter()
    self._listeners = {}
    self:updateList()
    table.insert(self._listeners, lc.addEventListener(Data.Event.log_dirty, function(event)
        self:onLogEvent(event)
    end))
end

function _M:onExit()
    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
end

function _M:onLogEvent(event)
    local PlayerLog = require("PlayerLog")
    local evt = event._event
    if evt == PlayerLog.Event.room_log_dirty then
        if self._indicator then
            self._indicator:removeFromParent()
            self._indicator = nil
        end
        self:updateList()
    end
end

function _M:initReplayList()
    local replayList = lc.List.createV(cc.size(lc.w(self._form) - 100, lc.bottom(self._titleFrame)), 6, 0)
    lc.addChildToPos(self._form, replayList, cc.p(50, 25))
    self._replayList = replayList
end

function _M:updateList()
    local logType = Battle_pb.PB_BATTLE_MATCH
    local logs = P._playerLog:getLogList(logType)
    if not logs then return end
    self._replayList:bindData(logs, function(item, log) self:setOrCreateItem(item, log) end, math.min(5, #logs))

    for i=1,self._replayList._cacheCount do
        local item = self:setOrCreateItem(nil, logs[i])
        self._replayList:pushBackCustomItem(item)
    end

    self._replayList:stopAllActions()

    self._replayList:checkEmpty(Str(STR.LIST_EMPTY_NO_LOG))
end

function _M:setOrCreateItem(layout, log)
--    local isSelf = message._user._id == P._id

    local player = log._player
    local opponent = log._opponent
    local resultType = log._resultType
    if not layout then
        layout = ccui.Layout:create()
        layout:setContentSize(cc.size(lc.w(self._replayList), 200))
        layout:setAnchorPoint(cc.p(0.5, 0.5))
        layout._log = log


        local itemBg = lc.createSprite({_name = "img_com_bg_54", _crect = cc.rect(20, 70, 1, 1), _size = cc.size(lc.w(self._replayList), 180)})
        lc.addChildToCenter(layout, itemBg)

        local userAvatar = UserWidget.create(player, UserWidget.Flag.LEVEL_NAME, 0.8, false)
        lc.addChildToPos(layout, userAvatar, cc.p(lc.cw(userAvatar) + 20, lc.h(layout) - lc.ch(userAvatar) - 25))
        layout._userAvatar = userAvatar

        local oppoAvatar = UserWidget.create(opponent, UserWidget.Flag.LEVEL_NAME, 0.8, true)
        lc.addChildToPos(layout, oppoAvatar, cc.p(lc.w(layout) - lc.cw(oppoAvatar) - 20, lc.y(userAvatar)))
        layout._oppoAvatar = oppoAvatar

        local leftSpr = lc.createSprite("img_win")
        lc.addChildToPos(layout, leftSpr, cc.p(lc.x(userAvatar), lc.bottom(userAvatar) - 30))
        layout._leftSpr = leftSpr

        local rightSpr = lc.createSprite("img_lose")
        lc.addChildToPos(layout, rightSpr, cc.p(lc.x(oppoAvatar), lc.bottom(oppoAvatar) - 30))
        layout._rightSpr = rightSpr

        local vsSpr = lc.createSprite("img_vs_s")
        lc.addChildToPos(layout, vsSpr, cc.p(lc.cw(layout), lc.y(userAvatar) + 20))

        local timeLabel = V.createTTF("", V.FontSize.S3)
        lc.addChildToPos(vsSpr, timeLabel, cc.p(lc.cw(vsSpr), lc.ch(vsSpr) - 50))
        timeLabel:setColor(lc.Color3B.black)
        layout._timeLabel = timeLabel

        local btn = V.createScale9ShaderButton("img_btn_1_s", function(sender) 
            self:onBattleReplay(log)
        end, V.CRECT_BUTTON_S, 140)
        lc.addChildToPos(layout, btn, cc.p(lc.cw(layout), lc.ch(btn) + 30))
        btn:addLabel(lc.str(STR.REPLAY))
        layout._btnReplay = btn
        -- update
        function layout:update()
            self._btnReplay:setVisible(self._log._replayId ~= nil)
            self._userAvatar:setUser(self._log._player)
            self._oppoAvatar:setUser(self._log._opponent)
            self._timeLabel:setString(ClientData.getTimeAgo(self._log._timestamp))
            if self._log._resultType == Data.BattleResult.win then
                self._leftSpr:setSpriteFrame("img_win")
                self._rightSpr:setSpriteFrame("img_lose")
            elseif self._log._resultType == Data.BattleResult.lose then
                self._leftSpr:setSpriteFrame("img_lose")
                self._rightSpr:setSpriteFrame("img_win")
            elseif self._log._resultType == Data.BattleResult.draw then
                self._leftSpr:setSpriteFrame("img_draw")
                self._rightSpr:setSpriteFrame("img_draw")
            end
        end
    else
        layout._log = log
    end


    layout:update()

    return layout
end

function _M:onBattleReplay(log)
    ClientData._replayingLog = log
    local isLocal = log:isLocal()
    ClientData.sendBattleReplay(log._replayId, isLocal)
end

return _M