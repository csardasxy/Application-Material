local _M = class("BattlePVPDialog", function() return cc.Node:create() end)
BattlePVPDialog = _M

_M.Type = 
{
    online          = 1,
    offline         = 2,
    thinking        = 3,
}

function _M.create(battleUi, type)
    local panel = _M.new()
    panel:init(battleUi, type)
    return panel
end

-------------------------------------------------------
-- init
-------------------------------------------------------

function _M:init(battleUi, type)
    self._battleUi = battleUi
    if type == _M.Type.online then
        self:initOnline()
    elseif type == _M.Type.offline then
        self:initOffline()
    elseif type == _M.Type.thinking then
        self:initThinking()
    end
end

function _M:initOnline()
    local bones = DragonBones.create("zg")
    bones:setPosition(V.SCR_CW, V.SCR_CH + 100)
    self:addChild(bones)

    bones:gotoAndPlay("effect")

    local time = bones:getAnimationDuration("effect")
    bones:runAction(cc.Sequence:create(
        cc.DelayTime:create(time),
        cc.CallFunc:create(function () self:hide() end)
        ))
end

function _M:initOffline()
    local bones = DragonBones.create("zg2")
    bones:setPosition(V.SCR_CW, V.SCR_H - 150)
    self:addChild(bones)

    bones:gotoAndPlay("effect")

    local time = bones:getAnimationDuration("effect") * 3
    bones:runAction(cc.Sequence:create(
        cc.DelayTime:create(time),
        cc.CallFunc:create(function () self:hide() end)
        ))
end

function _M:initThinking()
    local bg = ccui.Scale9Sprite:createWithSpriteFrameName("img_tip_bg", V.CRECT_TIP_BG)
    bg:setContentSize(250, 130)
    bg:setScale(0.6)
    self:addChild(bg)
    self._bg = bg
    local prefix = cc.Label:createWithTTF(Str(STR.BATTLE_CHAT_THINKING), V.TTF_FONT, V.FontSize.M2)
    prefix:setColor(cc.c3b(0, 0, 0))
    self:addChild(prefix)
    self._prefix = prefix
    if self._battleUi._player._stepStatus == BattleData.Status.wait_opponent then
        bg:setFlippedX(self._battleUi._isReverse)
        bg:setFlippedY(not self._battleUi._isReverse)
        bg:setPosition(not self._battleUi._isReverse and cc.p(V.SCR_W - 330, V.SCR_H - 34) or cc.p(200, 220))
        prefix:setPosition(not self._battleUi._isReverse and cc.p(V.SCR_W - 350, lc.y(bg) - 10) or cc.p(180, lc.y(bg) + 10))
    else
        bg:setFlippedX(not self._battleUi._isReverse)
        bg:setFlippedY(self._battleUi._isReverse)
        bg:setPosition(self._battleUi._isReverse and cc.p(V.SCR_W - 330, V.SCR_H - 34) or cc.p(200, 220))
        prefix:setPosition(self._battleUi._isReverse and cc.p(V.SCR_W - 350, lc.y(bg) - 10) or cc.p(180, lc.y(bg) + 10))
    end

    local dot = '. '
    local curTime = ClientData.getCurrentTime()
    local roundEndTime = self._battleUi._roundEndTimestamp
    local remainTime = (roundEndTime ~= nil and curTime < roundEndTime) and (roundEndTime - curTime) or 0
    local dots = cc.Label:createWithTTF(remainTime > 0 and ' '..math.floor(remainTime) or dot, V.TTF_FONT, V.FontSize.M2)
    dots:setAnchorPoint(0, 0.5)
    dots:setColor(cc.c3b(0, 0, 0))
    dots:setPosition(lc.right(prefix) + 2, lc.y(prefix))
    self:addChild(dots)
    self._dots = dots

    local index = 1
    dots:runAction(cc.RepeatForever:create(cc.Sequence:create(
        cc.DelayTime:create(1),
        cc.CallFunc:create(function ()
            index = index + 1
            if index > 3 then index = 1 end

            local curTime = ClientData.getCurrentTime()
            local roundEndTime = self._battleUi._roundEndTimestamp
            local remainTime = (roundEndTime ~= nil and curTime < roundEndTime) and (roundEndTime - curTime) or 0

            local curStr = ""
            if remainTime > 0 then
                curStr = ' '..math.floor(remainTime)
            else
                for i = 1, index do curStr = curStr..dot end
            end
            dots:setString(curStr)
        end)
    )))
end

function _M:hide()
    self:removeFromParent()
end

function _M:reverse()
    local bg = self._bg
    local prefix = self._prefix
    if self._battleUi._player._stepStatus == BattleData.Status.wait_opponent then
        bg:setFlippedX(self._battleUi._isReverse)
        bg:setFlippedY(not self._battleUi._isReverse)
        bg:setPosition(not self._battleUi._isReverse and cc.p(V.SCR_W - 330, V.SCR_H - 34) or cc.p(200, 220))
        prefix:setPosition(not self._battleUi._isReverse and cc.p(V.SCR_W - 350, lc.y(bg) - 10) or cc.p(180, lc.y(bg) + 10))
    else
        bg:setFlippedX(not self._battleUi._isReverse)
        bg:setFlippedY(self._battleUi._isReverse)
        bg:setPosition(self._battleUi._isReverse and cc.p(V.SCR_W - 330, V.SCR_H - 34) or cc.p(200, 220))
        prefix:setPosition(self._battleUi._isReverse and cc.p(V.SCR_W - 350, lc.y(bg) - 10) or cc.p(180, lc.y(bg) + 10))
    end
    self._dots:setPosition(lc.right(prefix) + 2, lc.y(prefix))
end

return _M
