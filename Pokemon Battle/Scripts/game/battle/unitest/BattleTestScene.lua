local _M = class("BattleTestScene", require("BaseScene"))
BattleTestScene = _M

require "BattleTestUi"
require "BattleTestUiTouch"
require "BattleTestListDialog"
require "BattleTestExtend"

function _M.create(scene)
    return lc.createScene(_M, scene)
end

function _M:init(scene)
    if not _M.super.init(self, ClientData.SceneId.battle_test) then return false end

    self._lastScene = scene

    ClientData._battleScene = self
    -- Do not guide in the battle
    self._isGuideOnEnter = false

    self._battleUiNormal = BattleTestUi.create(self, "normal")
    self:addChild(self._battleUiNormal)

    self._battleUi = self._battleUiNormal

    self:setKeyboardEnabled(true)
    self:registerScriptKeypadHandler(function(key)
        local eventCustom = cc.EventCustom:new(Data.Event.unitest)
        eventCustom._key = key
        lc.Dispatcher:dispatchEvent(eventCustom)
    end)

    return true
end

function _M:onEnter()
    _M.super.onEnter(self)
end

function _M:onExit()  
    ClientData._battleScene = self._lastScene
    _M.super.onExit(self)

end

return _M