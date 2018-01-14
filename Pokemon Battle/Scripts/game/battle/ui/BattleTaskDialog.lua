local _M = class("BattleTaskDialog", lc.ExtendUIWidget)
BattleTaskDialog = _M

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
            self._battleUi:hideTask()
        end
    end)

    local bg = lc.createSprite("battle_task_bg")
    bg:setPosition(V.SCR_CW + 20, V.SCR_CH + 40)
    self:addChild(bg)

    local centerPos = cc.p(bg:getContentSize().width / 2, bg:getContentSize().height / 2)
    
    local strs = self._battleUi._player._battleCondition:getConditionDesc()
    local defaultPos = cc.p(centerPos.x, centerPos.y + 10)
    for i = 1, #strs do
        local pos = cc.p(defaultPos.x, defaultPos.y - (i - 1) * 60)

        local label = cc.Label:createWithTTF(strs[i], V.TTF_FONT, V.FontSize.S1)
        label:setPosition(pos.x + 10, pos.y)
        bg:addChild(label)

        local star = lc.createSprite('battle_task_star')
        lc.addChildToPos(bg, star, cc.p(lc.left(label) - 30, pos.y))

        --[[
        local line = cc.Sprite:createWithSpriteFrameName("battle_task_line")
        line:setPosition(bg:getContentSize().width / 2, pos.y - 10)
        line:setScaleX(540 / line:getContentSize().width)
        bg:addChild(line)
        ]]
    end

    -- action
    self._bg = bg
    local time = cc.Director:getInstance():getScheduler():getTimeScale()
    
    bg:setScale(0)
    bg:runAction(cc.EaseBackOut:create(cc.ScaleTo:create(0.3 * time, 1.0)))
    
    --[[
    glowSpr:runAction(cc.RepeatForever:create(cc.Sequence:create(
        cc.EaseInOut:create(cc.ScaleTo:create(1.0 * time, 11.0), 1.5),
        cc.EaseInOut:create(cc.ScaleTo:create(1.0 * time, 9.0), 1.5)
    )))
    ]]
    
    -- Tap to continue
    local continue = V.createTTF(Str(STR.CONTINUE), V.FontSize.S1)
    continue:setPosition(V.SCR_CW, 40)
    continue:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeIn:create(0.5), cc.DelayTime:create(0.5), cc.FadeOut:create(0.5))))
    self:addChild(continue)
end

function _M:hide()
    local time = cc.Director:getInstance():getScheduler():getTimeScale()
    self._bg:runAction(cc.Sequence:create(
        cc.EaseBackIn:create(cc.ScaleTo:create(0.2 * time, 0)),
        cc.CallFunc:create(function () self:removeFromParent() end)
        ))
end

return _M