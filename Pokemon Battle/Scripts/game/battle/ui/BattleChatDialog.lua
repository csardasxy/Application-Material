local _M = class("BattleChatDialog", lc.ExtendUIWidget)
BattleChatDialog = _M

function _M.create(battleUi, isController)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(battleUi, isController)
    return panel
end

-------------------------------------------------------
-- init
-------------------------------------------------------

function _M:init(battleUi, isController)
    self._battleUi = battleUi

    self:addTouchEventListener(function(sender, type) 
        if type == ccui.TouchEventType.ended then
            self:hide()
        end
    end)

    if isController then
        for id, info in pairs(Data._pvpChatInfo) do
            local labelStr = Str(info._nameSid)
            local isLeft = ((id % 2) == 0)
            local loft = math.floor((id - 1) / 2) + 1
            local pos = cc.p(350 + 140 * (isLeft and -1 or 1), 110 * loft + 30)
            local size = cc.size(260, 130)
        
            self:addChatWidget(isController, labelStr, pos, size, isLeft)
        end
    else
        local labelStr = Str(battleUi._isIgnoreChat and STR.SHOW_CHAT or STR.IGNORE_CHAT)
        local isLeft = false
        local pos = cc.p(V.SCR_W - 160, V.SCR_H - 140)
        local size = cc.size(260, 130)
        self:addChatWidget(isController, labelStr, pos, size, isLeft)
    end
end    

function _M:hide()
    self:removeFromParent()
end

function _M:addChatWidget(isController, labelStr, pos, size, isLeft)
    local widget = ccui.Widget:create()
    widget:setContentSize(size)
    widget:setTouchEnabled(true)
    widget:setAnchorPoint(0.5, 0.5)
    widget:setPosition(pos)
    self:addChild(widget)

    widget:addTouchEventListener(function (sender, type)
        if type == ccui.TouchEventType.began then 
            widget:stopAllActions()
            widget:runAction(cc.ScaleTo:create(0.08, 0.9))
        elseif type == ccui.TouchEventType.canceled then
            widget:stopAllActions()
            widget:runAction(cc.ScaleTo:create(0.08, 1.0)) 
        elseif type == ccui.TouchEventType.ended then 
            local battleUi = self._battleUi
            battleUi._chatCDScheduler = lc.Scheduler:scheduleScriptFunc(function(dt)
                lc.Scheduler:unscheduleScriptEntry(battleUi._chatCDScheduler)
                battleUi._chatCDScheduler = nil
            end, 10, false)

            if isController then
                battleUi:addChat(battleUi._player, labelStr)
                ClientData.sendBattleChat(labelStr)
            else
                battleUi._isIgnoreChat = not battleUi._isIgnoreChat
            end
            self:hide()
        end
    end)
        
    local spr = ccui.Scale9Sprite:createWithSpriteFrameName("img_tip_bg", V.CRECT_TIP_BG)
    spr:setContentSize(size)
    spr:setFlippedX(isLeft)
    spr:setFlippedY(not isController)
    spr:setPosition(size.width / 2, size.height / 2)
    widget:addChild(spr)
        
    local label = V.createTTF(labelStr, V.FontSize.S1, V.COLOR_TEXT_DARK)        
    label:setPosition(cc.p(size.width / 2, isController and 80 or 50))
    widget:addChild(label)
        
    -- aniamtion
    widget:setScale(0.3)
    widget:runAction(cc.EaseBackOut:create(cc.ScaleTo:create(0.3, 1.0)))
end

return _M