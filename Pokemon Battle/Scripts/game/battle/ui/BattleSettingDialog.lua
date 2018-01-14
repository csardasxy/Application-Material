local _M = class("BattleSettingDialog", lc.ExtendUIWidget)
BattleSettingDialog = _M

function _M.create(battleUi)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(battleUi)
    return panel
end

-------------------------------------------------------
-- init
-------------------------------------------------------

function _M:init(battleUi)
    self._battleUi = battleUi

    self:addTouchEventListener(function(sender, type) 
        if type == ccui.TouchEventType.ended then
            battleUi:hideSetting()
        end
    end)

    battleUi._btnSetting:setLocalZOrder(BattleScene.ZOrder.form + 2)
    
    local baseButtons, buttons = {battleUi._btnMusic, battleUi._btnSndEffect}, {}

    -- TODO
    --if not battleUi._isOnlinePvp then table.insert(baseButtons, battleUi._btnHelp) end
    if battleUi._needTask then table.insert(baseButtons, battleUi._btnTask) end
    if battleUi._needRetreat then table.insert(baseButtons, battleUi._btnRetreat) end
    if battleUi._needReturn then table.insert(baseButtons, battleUi._btnReturn) end
    
    
    local defaultPos = self:getDefaultPosition()
    for i = 1, #baseButtons do
        local pos = cc.p(defaultPos.x + i * 112, defaultPos.y)
        
        local button = baseButtons[i]
        button:setLocalZOrder(BattleScene.ZOrder.form + 1)
        button:stopAllActions()
        button:setPosition(defaultPos)
        button:setScale(0)
        button:setDisabledShader(V.SHADER_DISABLE)
        
        local touchEnable = true
        if button == battleUi._btnRetreat and battleUi._player._isFinished then
            touchEnable = false
        end

        local time = cc.Director:getInstance():getScheduler():getTimeScale()
        button:runAction(cc.Sequence:create(
            cc.DelayTime:create(0.05 * (i - 1) * time),
            cc.CallFunc:create(function () button:setVisible(true) button:setEnabled(false) end),
            cc.EaseBackOut:create(cc.Spawn:create(cc.ScaleTo:create(0.35 * time, 1.0), cc.MoveTo:create(0.35 * time, pos))),
            cc.CallFunc:create(function () button:setEnabled(touchEnable) end)
        ))
    end
    for i = 1, #buttons do
        local pos = cc.p(defaultPos.x, defaultPos.y - i * 90)

        local button = buttons[i]
        button:setLocalZOrder(BattleScene.ZOrder.form + 1)
        button:stopAllActions()
        button:setPosition(defaultPos)
        button:setScale(0.5)
        button:setDisabledShader(V.SHADER_DISABLE)
        
        local touchEnable = true
        if button == battleUi._btnRetreat and (battleUi._player._isFinished or battleUi:isGuideWorldBattle()) then
            touchEnable = false
        end
        
        local time = cc.Director:getInstance():getScheduler():getTimeScale()
        button:runAction(cc.Sequence:create(
            cc.DelayTime:create(0.05 * (i - 1) * time),
            cc.CallFunc:create(function () button:setVisible(true) button:setEnabled(false) end),
            cc.EaseBackOut:create(cc.Spawn:create(cc.ScaleTo:create(0.35 * time, 1.0), cc.MoveTo:create(0.35 * time, pos))),
            cc.CallFunc:create(function () button:setEnabled(touchEnable) end)
        ))
    end
end    

function _M:hide()
    local battleUi = self._battleUi

    battleUi._btnSetting:setLocalZOrder(BattleScene.ZOrder.ui + 1)
    battleUi._btnSetting:setEnabled(true)
    battleUi._btnSetting:setColor(lc.Color3B.white)
    
    local baseButtons, buttons = {battleUi._btnMusic, battleUi._btnSndEffect, battleUi._btnHelp}, {}
    if battleUi._needTask then table.insert(baseButtons, battleUi._btnTask) end
    if battleUi._needRetreat then table.insert(baseButtons, battleUi._btnRetreat) end
    if battleUi._needReturn then table.insert(baseButtons, battleUi._btnReturn) end
    
    local defaultPos = self:getDefaultPosition()
    for i = 1, #baseButtons do
        local button = baseButtons[i]
        button:setLocalZOrder(BattleScene.ZOrder.ui)
        button:stopAllActions()
        button:setEnabled(false)

        local time = cc.Director:getInstance():getScheduler():getTimeScale()
        button:runAction(cc.Sequence:create(
            cc.DelayTime:create(0.05 * (i - 1) * time),
            cc.EaseBackIn:create(cc.Spawn:create(cc.ScaleTo:create(0.3 * time, 0), cc.MoveTo:create(0.3 * time, defaultPos)))
        ))
    end
    for i = 1, #buttons do
        local button = buttons[i]
        button:setLocalZOrder(BattleScene.ZOrder.ui)
        button:stopAllActions()
        button:setEnabled(false)

        local time = cc.Director:getInstance():getScheduler():getTimeScale()
        button:runAction(cc.Sequence:create(
            cc.DelayTime:create(0.05 * (i - 1) * time),
            cc.EaseBackIn:create(cc.Spawn:create(cc.ScaleTo:create(0.3 * time, 0.1), cc.MoveTo:create(0.3 * time, defaultPos)))
        ))
    end
    
    self:removeFromParent()
end

function _M:getDefaultPosition()
    return cc.p(self._battleUi._btnSetting:getPosition())
end

return _M