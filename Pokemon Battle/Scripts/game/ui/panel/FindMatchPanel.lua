local _M = class("FindMatchPanel", BasePanel)

local COUNT_DOWN_SECONDS = 15

function _M.create(matchType)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(matchType)
    return panel
end

function _M:init(matchType)
    _M.super.init(self, true)

    self._matchType = matchType

    local spine = V.createSpine('shousuo')
    spine:setAnimation(0, 'animation', true)
    lc.addChildToPos(self, spine, cc.p(lc.w(self) / 2, 500))
    self._spine = spine

    local btnCancel = V.createScale9ShaderButton("img_btn_2_s", function() self:cancelFind() end, V.CRECT_BUTTON_S, 200)
    btnCancel:addLabel(Str(STR.CANCEL))
    lc.addChildToPos(self, btnCancel, cc.p(lc.w(self) / 2, 200))
    self._btnCancel = btnCancel

    local countDown = V.createBMFont(V.BMFont.huali_26, "0")
    lc.addChildToPos(self, countDown, cc.p(lc.x(btnCancel), lc.top(btnCancel) + 20 + lc.h(countDown) / 2))
    countDown:setVisible(false)

    self._countDownTimestamp = ClientData.getCurrentTime()
    self:scheduleUpdateWithPriorityLua(function(dt)
        local sec = math.max(0, COUNT_DOWN_SECONDS - math.floor(ClientData.getCurrentTime() - self._countDownTimestamp))
        if sec == 0 then
            self:unscheduleUpdate()            
        end
        
        countDown:setString(string.format(Str(STR.FIND_MATCH_COUNTDOWN), sec))        
    end, 0)

    local tipBg = lc.createSprite{_name = "img_com_bg_7", _crect = V.CRECT_COM_BG7, _size = cc.size(500, 120)}
    tipBg:setColor(V.COLOR_TEXT_DARK)
    tipBg:setOpacity(180)
    lc.addChildToPos(self, tipBg, cc.p(lc.w(self) / 2, 100))
    self._tipBg = tipBg

    self._tipSids = {}
    for k, v in pairs(Data._tipInfo) do
        table.insert(self._tipSids, v._nameSid)
    end    

    self._tipIndex = math.random(1, #self._tipSids)    
    local tip = V.createTTF(Str(self._tipSids[self._tipIndex]), nil, nil, cc.size(400, 0))
    lc.addChildToCenter(tipBg, tip)
    self._tip = tip

    local btnW, btnH = 100, lc.h(tipBg)
    local btnArrowLeft = V.createArrowButton(true, cc.size(btnW, btnH), function(sender) self:onBtnArrow(sender) end)
    lc.addChildToPos(self, btnArrowLeft, cc.p(lc.left(tipBg) - btnW / 2 - 10, lc.y(tipBg)))
    self._btnArrowLeft = btnArrowLeft

    local btnArrowRight = V.createArrowButton(false, cc.size(btnW, btnH), function(sender) self:onBtnArrow(sender) end)
    lc.addChildToPos(self, btnArrowRight, cc.p(lc.right(tipBg) + btnW / 2 + 10, lc.y(tipBg)))
    self._btnArrowRight = btnArrowRight

    if matchType == Data.FindMatchType.clash then
        --ClientData.sendWorldFindEx(P._curTroopIndex, Battle_pb.PB_BATTLE_WORLD_LADDER)
        self:runAction(lc.sequence(
            1, function() 
                ClientData.sendWorldFindEx(P._curTroopIndex, Battle_pb.PB_BATTLE_WORLD_LADDER) 
            end,
            120, function () 
                ClientData.sendWorldFindExCancel() 
                ToastManager.push(Str(STR.FIND_TIME_OUT))
                self:hide() 
            end))

    elseif matchType == Data.FindMatchType.ladder then
        self:runAction(lc.sequence(
            1, function() 
                ClientData.sendWorldFindEx(P._curTroopIndex, Battle_pb.PB_BATTLE_WORLD_LADDER_EX) 
            end,
            120, function () 
                ClientData.sendWorldFindExCancel() 
                ToastManager.push(Str(STR.FIND_TIME_OUT))
                self:hide() 
            end))
    elseif matchType == Data.FindMatchType.union_battle then
        self:runAction(lc.sequence(
            1, function() 
                ClientData.sendWorldFindEx(P._curTroopIndex, Battle_pb.PB_BATTLE_MASSWAR_MULTIPLE) 
            end,
            120, function () 
                ClientData.sendWorldFindExCancel()
                ToastManager.push(Str(STR.FIND_TIME_OUT))
                self:hide() 
            end))
    elseif matchType == Data.FindMatchType.dark then
        self:runAction(lc.sequence(
            1, function()
                P._playerFindDark:find(true)
            end,
            120, function ()
                ClientData.sendWorldFindExCancel()
                ToastManager.push(Str(STR.FIND_TIME_OUT))
                self:hide() 
            end))
    end
end

function _M:cancelFind()
    if self._matchType == Data.FindMatchType.dark and P._playerFindDark:isInDarkBattle() then
        return require("Dialog").showDialog(Str(STR.CANCLE_DARK_TIP), function()
            P._playerFindDark:retreat()
            V.getActiveIndicator():show(Str(STR.WAIT_BATTLE_RESULT))
        end)
    else
        ClientData.sendWorldFindExCancel()
    end
end

function _M:stopEffect()
    if self._effectId then
        cc.SimpleAudioEngine:getInstance():stopEffect(self._effectId)
        lc.Audio.stopAudio(AUDIO.E_FIND_MATCH_OVER)
        self._effectId = nil
    end

    lc.Audio.stopAudio(AUDIO.E_FIND_MATCH_OVER)

    if self._effectScheduleId then
        lc.Scheduler:unscheduleScriptEntry(self._effectScheduleId)
        self._effectScheduleId = nil
    end
end

function _M:onEnter()
    _M.super.onEnter(self)

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
    V._findMatchPanel = self

    self:stopEffect()

    if ClientData._isEffectOn then
        local playFindEffect = function() self._effectId = cc.SimpleAudioEngine:getInstance():playEffect("res/audio/e_find_match.wav", false) end
        self._effectScheduleId = lc.Scheduler:scheduleScriptFunc(playFindEffect, 0.95, false)
        playFindEffect()
    end
end

function _M:onExit()
    _M.super.onExit(self)

    ClientData.removeMsgListener(self)
    V._findMatchPanel = nil

    self:stopEffect()
end

function _M:onFind(input)
--    local stopName = string.format("stop_%d", input._clashOppoType)
--    self._bones:gotoAndPlay(stopName)

--    self:stopEffect()
--    lc.Audio.playAudio(AUDIO.E_FIND_MATCH_OVER)

--    self._btnCancel:setVisible(false)

--    local duration = self._bones:getAnimationDuration(stopName)
--    self:runAction(lc.sequence(duration, function()
--        lc._runningScene:onBattleRecover(input)
--    end))
    lc._runningScene:onBattleRecover(input)
end

function _M:onBtnArrow(arrow)
    local offset, x, y = lc.x(self._tipBg) - lc.w(self._tipBg) / 2, lc.w(self._tipBg) / 2, lc.h(self._tipBg) / 2
    local nextIndex = self._tipIndex
    if arrow == self._btnArrowLeft then
        nextIndex = nextIndex - 1
        if nextIndex == 0 then nextIndex = #self._tipSids end
    else
        nextIndex = nextIndex + 1
        if nextIndex == #self._tipSids + 1 then nextIndex = 1 end

        offset = -offset
    end

    local nextTip = V.createTTF(Str(self._tipSids[nextIndex]), nil, nil, cc.size(400, 0))
    nextTip:setOpacity(0)
    lc.addChildToPos(self._tipBg, nextTip, cc.p(x - offset, y))

    local curFieldArea, duration = self._fieldArea, lc.absTime(0.1)
    self._tip:stopAllActions()
    self._tip:runAction(lc.sequence({lc.moveTo(duration, x + offset, y), lc.fadeOut(duration)}, lc.remove()))

    nextTip:runAction(lc.sequence({lc.moveTo(duration, x, y), lc.fadeIn(duration)}))
    self._tip = nextTip
    self._tipIndex = nextIndex
end

function _M:onMsg(msg)
    local msgType = msg.type
    
    return false
end

return _M