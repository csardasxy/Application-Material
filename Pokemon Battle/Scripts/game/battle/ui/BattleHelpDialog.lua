local _M = class("BattleHelpDialog", lc.ExtendUIWidget)
BattleHelpDialog = _M

function _M.create(battleUi)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(battleUi)
    
    panel:addTouchEventListener(function(sender, type) 
        if type == ccui.TouchEventType.ended then
            panel:hide()
        end
    end)

    panel:registerScriptHandler(function(evtName)
        if evtName == "cleanup" then
            ClientData.unloadLCRes({"bat_help.jpm", "bat_help.png.sfb"})
        end
    end)

    return panel
end

function _M:init(battleUi)
    self._battleUi = battleUi
    
    ClientData.loadLCRes("res/bat_help.lcres")

    self:setOpacity(V.MASK_OPACITY_LIGHT)
    
    if self._battleUi._btnSpeed and self._battleUi._btnSpeed:isVisible() then
        local x, y = self._battleUi._btnSpeed:getPosition()
        self:addChild(lc.createSprite("bat_help_speed", cc.p(x + 108, y + 20)))
    end

    if self._battleUi._btnAuto and self._battleUi._btnAuto:isVisible() then
        local x, y = self._battleUi._btnAuto:getPosition()
        self:addChild(lc.createSprite("bat_help_auto", cc.p(x + 134, y + 16)))
    end

    if self._battleUi._btnSkip and self._battleUi._btnSkip:isVisible() then
        local x, y = self._battleUi._btnSkip:getPosition()
        self:addChild(lc.createSprite("bat_help_skip", cc.p(x + 110, y)))
    end

    if self._battleUi._atkPile then
        local x, y = self._battleUi._atkPile:getParent():getPosition()
        self:addChild(lc.createSprite("bat_help_pile", cc.p(x - 134, y + 10)))
    end

    local offX = (V.SCR_W - 1024) / 2

    local pos = cc.p(self._battleUi._btnEndRound:getPosition())
    self:addChild(lc.createSprite("bat_help_start", cc.p(pos.x + offX - 142, pos.y)))
    
    local pos = PlayerUi.Pos.attacker_gems[2]
    self:addChild(lc.createSprite("bat_help_gem", cc.p(pos.x + offX - 190, pos.y)))

    local pos = PlayerUi.Pos.attacker_grave
    self:addChild(lc.createSprite("bat_help_grave", cc.p(pos.x + offX + 120, pos.y)))

    local pos = PlayerUi.Pos.attacker_fortress
    self:addChild(lc.createSprite("bat_help_fortress", cc.p(pos.x + offX + 66, pos.y + 64)))

    -- Tap to continue
    local continue = V.createTTF(Str(STR.CONTINUE))
    continue:setPosition(V.SCR_CW, V.SCR_H - 40)
    continue:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeIn:create(0.5), cc.DelayTime:create(0.5), cc.FadeOut:create(0.5))))
    self:addChild(continue)
end    

function _M:hide()    
    self:removeFromParent()
end

return _M