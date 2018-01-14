local _M = class("BaseUIScene", require("BaseScene"))

local DEF_BG_COLOR = cc.c4b(30, 20, 10, 255)
local DEF_BG_HEIGHT = 60

_M.STYLE_EMPTY      = 0
_M.STYLE_SIMPLE     = 1
_M.STYLE_TAB        = 2

function _M:init(sceneId, titleStr, style, hasHelp)
    if not _M.super.init(self, sceneId) then return false end
    
    self:initCommonArea(titleStr, style, hasHelp)

    return true
end

function _M:initCommonArea(titleStr, style, hasHelp)
    -- TODO
    hasHelp = false

    local cx = lc.w(self) / 2
    self._bg = lc.createNode(cc.size(lc.w(self), lc.h(self)))
    lc.addChildToCenter(self, self._bg)
    local bg = lc.createSprite("res/jpg/ui_scene_bg.jpg")
    for i = 0, lc.w(self), lc.w(bg) do
        self._bg:addChild(bg)
        bg:setScaleY(lc.h(self._bg)/lc.h(bg))
        bg:setAnchorPoint(0,0)
        bg:setPosition(i, 0)
        bg = lc.createSprite("res/jpg/ui_scene_bg.jpg")
    end

    -- Init top area
    local hideFunc = function(sender) self:hide() end
    local helpFunc = nil
    if hasHelp and self._sceneId ~= ClientData.SceneId.manage_troop then
        helpFunc = function(sender) self:onHelp() end
    end

    self._titleArea = V.createTitleArea(Str(titleStr), hideFunc, helpFunc)
    self:addChild(self._titleArea)
    
    if style ~= _M.STYLE_EMPTY then
        -- Add default background
        --local defBg = cc.LayerColor:create(DEF_BG_COLOR, lc.w(self), DEF_BG_HEIGHT)
        --lc.addChildToPos(self, defBg, cc.p(0, lc.bottom(self._titleArea) - DEF_BG_HEIGHT + 2), -1)

        --V.addUISceneCommonFrames(self, style == _M.STYLE_TAB and lc.y(defBg) or lc.bottom(self._titleArea) - 20)
    end

end

function _M:onEnter()
    _M.super.onEnter(self)
    
    local resource = V.getResourceUI()
    resource:setMode(Data.ResType.gold)

    --resource:setPositionX(V.SCR_CW + 36)
    if self._sceneId ~= ClientData.SceneId.manage_troop then
        self._scene:addChild(resource, ClientData.ZOrder.ui)
    end

    self._titleArea._btnBack:setEnabled(true)
    
    lc.Audio.playAudio(AUDIO.M_CITY)
end

function _M:onExit()
    _M.super.onExit(self)
    
    V.removeResourceFromParent()

    self._titleArea._btnBack:setEnabled(false)
end

function _M:onCleanup()
    _M.super.onCleanup(self)
end

function _M:hide()
    V.popScene()
end

function _M:onHelp()
    local helpType
    if self._sceneId == ClientData.SceneId.manage_troop then
        helpType = Data.HelpType.herocenter
    elseif self._sceneId == ClientData.SceneId.barrack then
        helpType = Data.HelpType.barrack
    elseif self._sceneId == ClientData.SceneId.factory_trap then
        helpType = Data.HelpType.blacksmith
    elseif self._sceneId == ClientData.SceneId.stable then
        helpType = Data.HelpType.stable
    elseif self._sceneId == ClientData.SceneId.factory_magic then
        helpType = Data.HelpType.library
    elseif self._sceneId == ClientData.SceneId.market then
        helpType = Data.HelpType.market
    elseif self._sceneId == ClientData.SceneId.tavern then
        local focusedIndex = self._tabArea._focusedTab._index
        if focusedIndex == self.TAB.time_limit then
            helpType = Data.HelpType.tavern_time_limit
        elseif focusedIndex == self.TAB.times_limit then
            helpType = Data.HelpType.tavern_times_limit
        elseif focusedIndex == self.TAB.draw_card then
            helpType = Data.HelpType.tavern_draw_card
        elseif focusedIndex == self.TAB.rare_draw_card then
            helpType = Data.HelpType.tavern_rare_draw_card
        elseif focusedIndex == self.TAB.depot_shop then
            helpType = Data.HelpType.tavern_depot_shop
        elseif focusedIndex == self.TAB.depot_vip_shop then
            helpType = Data.HelpType.tavern_depot_vip_shop
        elseif focusedIndex == self.TAB.rare_shop then
            helpType = Data.HelpType.tavern_rare_shop
        elseif focusedIndex == self.TAB.diamond_shop then
            helpType = Data.HelpType.tavern_diamond_shop
        elseif focusedIndex == self.TAB.god_pump then
            helpType = Data.HelpType.tavern_god_pump
        end
    elseif self._sceneId == ClientData.SceneId.factory_monster then
        helpType = Data.HelpType.heromansion
    elseif self._sceneId == ClientData.SceneId.train then
        helpType = Data.HelpType.train
    elseif self._sceneId == ClientData.SceneId.expedition then
        helpType = Data.HelpType.expedition        
    elseif self._sceneId == ClientData.SceneId.guard then
        helpType = Data.HelpType.guard
    elseif self._sceneId == ClientData.SceneId.lottery then
        helpType = Data.HelpType.lottery
    elseif self._sceneId == ClientData.SceneId.find then
        local focusedIndex = self._tabArea._focusedTab._index
        if focusedIndex == self.TAB.clash then        
            helpType = Data.HelpType.seek
        elseif focusedIndex == self.TAB.ladder then
            helpType = Data.HelpType.elite
        elseif focusedIndex == self.TAB.union_battle then
            helpType = Data.HelpType.union_battle
        elseif focusedIndex == self.TAB.dark then
            helpType = Data.HelpType.dark
        elseif focusedIndex == self.TAB.hall then
            helpType = Data.HelpType.room
        end
        
    elseif self._sceneId == ClientData.SceneId.depot then
        helpType = Data.HelpType.depot
    elseif self._sceneId == ClientData.SceneId.union then
        helpType = Data.HelpType.union
    elseif self._sceneId == ClientData.SceneId.skin_shop then
        helpType = Data.HelpType.skin_shop
    elseif self._sceneId == ClientData.SceneId.in_room then
        helpType = Data.HelpType.room
    end
    
    if helpType then
        V.showHelpForm(nil, helpType)
    end
end

BaseUIScene = _M
return _M