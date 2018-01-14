local _M = class("LogForm", BaseForm)

local FORM_SIZE = cc.size(960, 640)

local ITEM_HEIGHT = 180
local TAG_REMOVE = 100

function _M.create(logType, focusTab)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(logType, focusTab)
    return panel
end

function _M:init(logType, focusTab)
    self._type = logType
    
    _M.super.init(self, FORM_SIZE, Str(STR.LOG), bor(BaseForm.FLAG.ADVANCE_TITLE_BG))
    
    local list = lc.List.createV(cc.size(lc.w(self._frame) - 64, lc.h(self._frame) - 70), 20, 20)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(self._frame, list)
    lc.offset(list, 0, -24)
    
    self._list = list
    
    if logType == Battle_pb.PB_BATTLE_PLAYER then
        self:addTabs({Str(STR.DEFENSE_LOG), Str(STR.ATTACK_LOG)}, focusTab)
    else
        self:refreshLog()
    end
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listener = lc.addEventListener(Data.Event.log_dirty, function(event)
        self:onLogEvent(event)
    end)
end

function _M:onExit()
    _M.super.onExit(self)
    
    if lc._runningScene._sceneId == ClientData.SceneId.find then
        lc._runningScene:showTabFlag()
    end

    V.getMenuUI():updateBattleFlag()

    lc.Dispatcher:removeEventListener(self._listener)
end

function _M:showTab(name, isForce)
    if not _M.super.showTab(self, name, isForce) then return false end
    
    self:refreshLog(name)
    return true
end

function _M:refreshLog(name)
    local logs
    if name then
        if self._focusTab ~= self._tabs[name] then return end

        logs = P._playerLog:getLogList(Battle_pb.PB_BATTLE_PLAYER, name == Str(STR.ATTACK_LOG))

        if name == Str(STR.ATTACK_LOG) then
            lc.writeConfig(ClientData.ConfigKey.new_attack_log, ClientData.getCurrentTime())

        elseif name == Str(STR.DEFENSE_LOG) then
            lc.writeConfig(ClientData.ConfigKey.new_defense_log, ClientData.getCurrentTime())
        end

    else        
        logs = P._playerLog:getLogList(self._type)

        if self._type == Battle_pb.PB_BATTLE_WORLD_LADDER then
            lc.writeConfig(ClientData.ConfigKey.new_clash_log, ClientData.getCurrentTime())
        else
            lc.writeConfig(ClientData.ConfigKey.new_ladder_log, ClientData.getCurrentTime())
        end
    end

    if logs then
        local list = self._list
        list:bindData(logs, function(item, log) self:setOrCreateItem(item, log) end, math.min(6, #logs))
    
        for i = 1, list._cacheCount do
            local item = self:setOrCreateItem(nil, logs[i])
            list:pushBackCustomItem(item)
        end

        list:refreshView()
        list:gotoTop()

        self._list:checkEmpty(Str(STR.LIST_EMPTY_NO_LOG))
    else
        local indicator = self._indicator
        if indicator == nil then
            self._indicator = V.showPanelActiveIndicator(self._form)
        end

        ClientData.sendGetPvpLogs(self._type)
    end
end

function _M:setOrCreateItem(item, log)    
    local isLocal = log:isLocal()
    if item == nil then
        item = lc.createImageView{_name = "img_troop_bg_6", _crect = cc.rect(20, 24, 2, 2), _size = cc.size(lc.w(self._list), 132)}
        item:setTouchEnabled(true)
        item:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)

        --local userArea = UserWidget.create(P, isLocal and UserWidget.Flag.NAME_UNION or UserWidget.Flag.REGION_NAME_UNION, 1, false, true)
        local userArea = UserWidget.create(P, UserWidget.Flag.NAME_UNION, 1, false, true)
        lc.addChildToPos(item, userArea, cc.p(176 + lc.w(userArea) / 2, lc.h(item) / 2))
        item._userArea = userArea
            
        local resName
        if isLocal then
            resName = "img_icon_res5_s"
        else
            if self._type == Battle_pb.PB_BATTLE_WORLD_LADDER then
                resName = "img_icon_res6_s"
            end
        end

        local trophyArea
        if resName then
            trophyArea = V.createIconLabelArea(resName, "", 140)
            lc.addChildToPos(item, trophyArea, cc.p(640, 100))
            item._trophyArea = trophyArea

            --[[
            local trophyIco = lc.createSprite(resName)
            lc.addChildToPos(item, trophyIco, cc.p(lc.left(trophyArea) + lc.w(trophyIco) / 2, lc.bottom(trophyArea) - 28))
            trophyIco:setScale(0.7)
            item._trophyIco = trophyIco
            ]]
                    
            local trophyChange = V.createBMFont(V.BMFont.huali_26, "")
            trophyChange:setAnchorPoint(0, 0.5)
            lc.addChildToPos(item, trophyChange, cc.p(lc.x(trophyArea) + 6, lc.bottom(trophyArea) - 18))
            item._trophyChange = trophyChange
        end

        local pos = trophyArea and cc.p(lc.left(trophyArea) + 6, lc.bottom(trophyArea) - 60) or cc.p(600, 110)
        local timeValue = V.createTTF("0", nil, V.COLOR_LABEL_LIGHT)
        timeValue:setAnchorPoint(0, 0.5)
        lc.addChildToPos(item, timeValue, pos)
        item._timeValue = timeValue

        local img = lc.createSprite("img_win")
        lc.addChildToPos(item, img, cc.p(lc.cw(img) + 2, lc.h(item) / 2))
        item._resultImg = img
        
        local btnReplay = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:onReplay(item._log) end, V.CRECT_BUTTON_S, 120)
        btnReplay:addLabel(Str(STR.REPLAY))
        btnReplay:setDisabledShader(V.SHADER_DISABLE)
        lc.addChildToPos(item, btnReplay, cc.p(lc.w(item) - lc.w(btnReplay) / 2 - 28, lc.h(item) / 2 + lc.h(btnReplay) / 2 + 2))
        item._btnReplay = btnReplay

        local btnShare = V.createScale9ShaderButton("img_btn_2_s", function(sender) self:onShare(item._log) end, V.CRECT_BUTTON_S, 120)
        btnShare:addLabel(Str(STR.SHARE))
        btnShare:setDisabledShader(V.SHADER_DISABLE)
        lc.addChildToPos(item, btnShare, cc.p(lc.x(btnReplay), lc.h(item) / 2 - lc.h(btnShare) / 2 - 2))
        item._btnShare = btnShare

    end

    item:removeChildrenByTag(TAG_REMOVE)
    item._log = log

    local opponent = log._opponent
    local resultType = log._resultType

    item:addTouchEventListener(function(sender, type)
        if type == ccui.TouchEventType.ended then
            if isLocal then
                V.operateUser(opponent, item)

            elseif self._type == Battle_pb.PB_BATTLE_WORLD_LADDER then
                if opponent._regionId > 0 then
                    require("ClashUserInfoForm").create(opponent._id):show()
                end
            end
        end
    end)

    item._userArea:setUser(opponent, true)
    if item._userArea._unionArea == nil or (not item._userArea._unionArea:isVisible()) then
        --TODO
        --lc.offset(item._userArea._nameArea, 0, 20)

        --if item._userArea._regionArea and item._userArea._regionArea:isVisible() then
        --    lc.offset(item._userArea._regionArea, 0, 20)
        --end

    end
    if item._trophyArea then
        item._trophyArea._label:setString(string.format("%d", opponent._trophy))
        item._trophyChange:setString(string.format("%s", (resultType ~= Data.BattleResult.lose and "+" or "-")..log._trophy))
    end
    item._timeValue:setString(ClientData.getTimeAgo(log._timestamp))        
    item._resultImg:setSpriteFrame(resultType == Data.BattleResult.win and "img_win" or (resultType == Data.BattleResult.draw and "img_draw" or "img_lose"))
    
    --item._trophyIco:setPositionY(lc.y(item._resultImg))
    --item._trophyChange:setPositionY(lc.y(item._resultImg))

    item._btnReplay:setEnabled(log._isAvailable)
    item._btnShare:setEnabled(log._isAvailable and not P._playerMessage:isLogShared(log._id))

    --TODO
    item._btnShare:setEnabled(false)

    if resultType == Data.BattleResult.lose then
        item:setColor(cc.c3b(200, 200, 200))
            --[[
        if log._city then
            local city = P._playerWorld._cities[log._city]
            if city then
                local loseCity = V.createTTF(Str(city._info._nameSid), nil, V.COLOR_TEXT_DARK)
                lc.addChildToPos(item, loseCity, cc.p(lc.x(item._trophyIco), lc.y(item._timeValue)), 0, TAG_REMOVE)

                local fall = V.createTTF(Str(STR.FALL), nil, V.COLOR_LABEL_DARK)
                lc.addChildToPos(item, fall, cc.p(lc.right(loseCity) + lc.w(fall) / 2, lc.y(loseCity)), 0, TAG_REMOVE)

                item._trophyIco:setPositionY(lc.y(item._resultImg) + 20)
                item._trophyChange:setPositionY(lc.y(item._resultImg) + 20)
            end
        end
        ]]
    else
        item:setColor(lc.Color3B.white)
    end
        
    return item
end

function _M:onLogEvent(event)
    local PlayerLog = require("PlayerLog")
    local evt = event._event
    if evt == PlayerLog.Event.attack_log_dirty then
        self:refreshLog(Str(STR.ATTACK_LOG))

    elseif evt == PlayerLog.Event.defense_log_dirty then
        self:refreshLog(Str(STR.DEFENSE_LOG))

    elseif evt == PlayerLog.Event.clash_log_dirty or evt == PlayerLog.Event.melee_log_dirty or evt == PlayerLog.Event.dark_log_dirty then
        if self._indicator then
            self._indicator:removeFromParent()
            self._indicator = nil
        end
        self:refreshLog()

    elseif evt == PlayerLog.Event.log_item_dirty then
        local logId = event._logId
        local items = self._list:getItems()
        for _, item in ipairs(items) do
            if item._log._id == logId then
                self:setOrCreateItem(item, item._log)
            end
        end
    end
end

function _M:onReplay(log)
    V.getActiveIndicator():show(Str(STR.WAITING))

    local isLocal = log:isLocal()

    ClientData._replayingLog = log
    ClientData._replaySharable = not isLocal
    ClientData.sendBattleReplay(log._replayId, isLocal)

    ClientData.sendUserEvent({logReplayId = log._replayId})
end

function _M:onShare(log)
    local dialog= require("ShareForm").create(log._id)
    dialog:show()
end

return _M