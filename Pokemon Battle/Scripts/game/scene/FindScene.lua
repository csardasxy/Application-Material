local _M = class("FindScene", BaseUIScene)

--local TrophyArea = require("FindTrophyArea")
--local MeleeArea = require("FindMeleeArea")
local ClashArea = require("FindClashArea")
local LadderArea = require("FindLadderArea")
local HallArea = require("HallArea")
local UnionBattleArea = require("UnionBattleArea")
local DarkBattleArea = require("DarkBattleArea")

local BG_NAME = "res/jpg/find_match_bg.jpg"

_M.TAB = {
    --trophy      = Data.FindMatchType.trophy,
    --melee       = Data.FindMatchType.melee,
    clash       = Data.FindMatchType.clash,   
    ladder       = Data.FindMatchType.ladder,
    hall            = Data.FindMatchType.hall,
    union_battle     = Data.FindMatchType.union_battle,
    dark                = Data.FindMatchType.dark
}

function _M.create(tabIndex)
    return lc.createScene(_M, tabIndex)
end

function _M:init(tabIndex)
    if not _M.super.init(self, ClientData.SceneId.find, STR.FIND_TITLE, BaseUIScene.STYLE_EMPTY, true) then return false end
    
    --[[
    local bg = lc.createSprite(BG_NAME)
    local scaleX = lc.w(self) / lc.w(bg)
    local scaleY = lc.bottom(self._titleArea) / lc.h(bg)
    bg:setScale(scaleX > scaleY and scaleX or scaleY)
    bg:setPosition(lc.w(self) / 2, lc.sh(bg) / 2)
    bg:setVisible(false)
    self:addChild(bg)
    ]]

    ClientData.loadLCRes("res/find.lcres")

    self:initTabArea()
    self._initTabIndex = tabIndex or _M.TAB.clash

    self._titleArea._btnBack._callback = function ()
        if P._playerFindDark:isInDarkBattle() then
            require("Dialog").showDialog(Str(STR.DARK_BATTLE_WARNING), function()
                P._playerFindDark:retreat(true)
                self:onBattleWait()
            end)
        else
            self:hide()
        end
    end
    
    return true
end

function _M:syncData()
    _M.super.syncData(self)

    if not P._playerFindClash._isSyncData then
        self:setTabIndicators(true)
        ClientData.sendClashSync()
    end

    local focusedIndex
    if self._tabArea._focusedTab then
        focusedIndex = self._tabArea._focusedTab._index
    else
        focusedIndex = self._initTabIndex
    end

    -- fix reconnect bug in ladder tab
    if not P._playerFindClash._isSyncData and focusedIndex ~= _M.TAB.dark then
        focusedIndex = _M.TAB.clash
    end

    if P._playerFindDark:isInDarkBattle() then
        focusedIndex = _M.TAB.dark
    end

    self._tabArea:showTab(focusedIndex, true)
    self:showTabFlag()

    self._titleArea:setVisible(true)
    self._titleArea:setOpacity(255)
end

function _M:initTabArea()
    local tabs = {
        --[[
        {_index = _M.TAB.trophy, _str = Str(STR.FIND_TROPHY_TITLE), checkValid = function()
            if P._level < Data._globalInfo._unlockFindMatch then
                ToastManager.push(string.format(Str(STR.LORD_UNLOCK_LEVEL), Data._globalInfo._unlockFindMatch))
                return false
            end
            return true
        end},
        {_index = _M.TAB.melee, _str = Str(STR.FIND_MELEE_TITLE), checkValid = function()
            if P._level < Data._globalInfo._unlockFindMatch then
                ToastManager.push(string.format(Str(STR.LORD_UNLOCK_LEVEL), Data._globalInfo._unlockFindMatch))
                return false
            end
            return true
        end},
        ]]
        {_index = _M.TAB.clash, _icon = 'img_tb1', checkValid = function()
            return true
        end},
    }

    --if not ClientData.isAppStoreReviewing() then
    if false then

    --if ClientData._userRegion._id >= 8001 and ClientData._userRegion._id <= 8003 then
        table.insert(tabs, {_index = _M.TAB.ladder, _icon = 'img_tb2', checkValid = function()
            --[[
            if P:getMaxCharacterLevel() < Data._globalInfo._unlockLadder then 
--                ToastManager.push(string.format(Str(STR.LORD_UNLOCK_LEVEL), Data._globalInfo._unlockLadder))
                local panel = require("BasePanel").new(lc.EXTEND_LAYOUT_MASK)
                panel:init(false, true)
                function panel:onCleanup()
                    lc.TextureCache:removeTextureForKey("res/jpg/ad_20.jpg")
                end
                local ad = lc.createSpriteWithMask("res/jpg/ad_20.jpg")
                lc.addChildToCenter(panel, ad)
                panel:show()
                return false
            end]]
            if not P._playerFindClash._isSyncData then return false end
            return true
        end})
    --end
        if P._playerFindUnionBattle:getIsUnionBattleActivityValid() then
            table.insert(tabs, {_index = _M.TAB.union_battle, _icon = 'img_tb3', checkValid = function()
            --[[
                if P:getMaxCharacterLevel() < Data._globalInfo._unlock2v2 then 
                    local panel = require("BasePanel").new(lc.EXTEND_LAYOUT_MASK)
                    panel:init(false, true)
                    function panel:onCleanup()
                        lc.TextureCache:removeTextureForKey("res/jpg/ad_18.jpg")
                    end
                    local ad = lc.createSpriteWithMask("res/jpg/ad_18.jpg")
                    lc.addChildToCenter(panel, ad)
                    panel:show()
                    return false
            
                end]]
                if not P._playerFindClash._isSyncData then return false end
                return true
            end})
        end

        if P._playerFindDark:getIsDarkActivityValid() then
            table.insert(tabs, {_index = _M.TAB.dark, _icon = 'img_tb4', checkValid = function()
            --[[
                if P:getMaxCharacterLevel() < Data._globalInfo._unlockDark then 
                    local panel = require("BasePanel").new(lc.EXTEND_LAYOUT_MASK)
                    panel:init(false, true)
                    function panel:onCleanup()
                        lc.TextureCache:removeTextureForKey("res/jpg/ad_18.jpg")
                    end
                    local ad = lc.createSpriteWithMask("res/jpg/ad_18.jpg")
                    lc.addChildToCenter(panel, ad)
                    panel:show()
                    return false
            
                end]]
                return true
            end})
        end
        
        table.insert(tabs, {_index = _M.TAB.hall, _icon = 'img_tb5', checkValid = function()
        --[[
            if P:getMaxCharacterLevel() < Data._globalInfo._unlockHall then 
--                ToastManager.push(string.format(Str(STR.LORD_UNLOCK_LEVEL), Data._globalInfo._unlockHall))
                    local panel = require("BasePanel").new(lc.EXTEND_LAYOUT_MASK)
                    panel:init(false, true)
                    function panel:onCleanup()
                        lc.TextureCache:removeTextureForKey("res/jpg/ad_15.jpg")
                    end
                    local ad = lc.createSpriteWithMask("res/jpg/ad_15.jpg")
                    lc.addChildToCenter(panel, ad)
                    panel:show()
                return false
            end]]
            if not P._playerFindClash._isSyncData then return false end
            return true
        end})
    
    end

    local tabArea = V.createHorizontalIconTabListArea(lc.w(self._titleArea), tabs, function(tab, isSameTab, isUserBehavior)
        if not isSameTab or isUserBehavior then
            self:showTab(tab)
        end
    end)
    lc.addChildToPos(self, tabArea, cc.p(lc.cw(self), lc.bottom(self._titleArea) - lc.ch(tabArea)), 1)

    self._tabArea = tabArea
end

function _M:showTab(tab)
    if P._playerFindDark:isInDarkBattle() and tab._index ~= _M.TAB.dark then
        require("Dialog").showDialog(Str(STR.DARK_BATTLE_WARNING), function()
            P._playerFindDark:retreat(true)
            self:onBattleWait()
        end)
        self._tabArea:showTab(_M.TAB.dark)
    end
    local contentArea = self._contentArea
    if contentArea then
        if contentArea._linkObjs then
            for _, obj in ipairs(contentArea._linkObjs) do
                obj:removeFromParent()
            end
        end

        contentArea:removeFromParent()
        self._contentArea = nil
    end

    local areaW, areaH, area, areaY = lc.w(self), lc.bottom(self._titleArea) - 105
    --[[if tab._index == _M.TAB.trophy then
        area = TrophyArea.create(areaW, areaH)

    elseif tab._index == _M.TAB.melee then
        area = MeleeArea.create(areaW, areaH)

    else]]
    if tab._index == _M.TAB.clash then
        area = ClashArea.create(areaW, areaH)
    elseif tab._index == _M.TAB.ladder then
        area = LadderArea.create(areaW, areaH)
    elseif tab._index == _M.TAB.hall then
        area = HallArea.create(areaW, areaH)
    elseif tab._index == _M.TAB.union_battle then
        area = UnionBattleArea.create(areaW, areaH)
    elseif tab._index == _M.TAB.dark then
        area = DarkBattleArea.create(areaW, areaH)
    end

    if area then
        lc.addChildToPos(self, area, cc.p(lc.cw(self), areaY or lc.h(area) / 2))
        self._contentArea = area
    end

    self:setResourceMode()
end

function _M:showTabFlag(tabIndex)    
    local tabs = self._tabArea._list:getItems()

    if tabIndex == nil or tabIndex == _M.TAB.trophy then
        local number = P._playerLog:getNewDefenseLogCount()
        V.checkNewFlag(tabs[1], number)

        if _M.TAB.trophy == self._tabArea._focusedTab._index then
            self._contentArea:updateLogFlag()
        end
    end

    if tabIndex == nil or tabIndex == _M.TAB.clash then

    end
end

function _M:setResourceMode()
    V.getResourceUI():setVisible(true)
    local focusedIndex = self._tabArea._focusedTab._index
    if focusedIndex == _M.TAB.clash then
        V.getResourceUI():setMode(Data.ResType.clash_trophy)

    elseif focusedIndex == _M.TAB.ladder then
        V.getResourceUI():setMode(not P._playerFindLadder._hasTicket and Data.PropsId.ladder_ticket or Data.ResType.ladder_trophy)

    elseif focusedIndex == _M.TAB.hall then
        V.getResourceUI():setMode(Data.ResType.gold)

    elseif focusedIndex == _M.TAB.union_battle then
        V.getResourceUI():setMode(Data.ResType.gold)

    elseif focusedIndex == _M.TAB.dark then
        V.getResourceUI():setMode(Data.ResType.dark_trophy)
        V.getResourceUI():setVisible(not P._playerFindDark:isInDarkBattle())
    end
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listeners = {}

    table.insert(self._listeners, lc.addEventListener(Data.Event.log_dirty, function(event)
        local PlayerLog = require("PlayerLog")
        if event._event == PlayerLog.Event.defense_log_dirty then
            self:showTabFlag(_M.TAB.trophy)
        end
    end))

    table.insert(self._listeners, lc.addEventListener(Data.Event.clash_sync_ready, function(event)
        self:setTabIndicators(false)
    end))

    local synced = false
    local curArea = self._contentArea
    if curArea == nil or not curArea._ignoreSync then
        synced = true
        self:syncData()
    else
        curArea._ignoreSync = nil
        self:setResourceMode()
    end

    if not P._playerFindClash._isSyncData then
        self:setTabIndicators(true)
        --ClientData.sendClashSync()
    end
    
    local focusedIndex
    if self._tabArea._focusedTab then
        focusedIndex = self._tabArea._focusedTab._index
    else
        focusedIndex = self._initTabIndex
    end

    -- fix reconnect bug in ladder tab
    if not P._playerFindClash._isSyncData and focusedIndex ~= _M.TAB.dark then
        focusedIndex = _M.TAB.clash
    end

    if P._playerFindDark:isInDarkBattle() then
        focusedIndex = _M.TAB.dark
    end

    if not synced then
        self._tabArea:showTab(focusedIndex, true)
    end
end

function _M:setTabIndicators(show)
    local tabArea = self._tabArea
    local items = tabArea._list:getItems()
    for i, item in ipairs(items) do
        if item._index ~= _M.TAB.clash and item._index ~= _M.TAB.dark then
            local indicator = item._indicator
            if show then
                if not indicator then
                    item._indicator = V.showPanelActiveIndicator(item)
                end
            else
                if indicator then
                    indicator:removeFromParent()
                    item._indicator = nil
                end
            end
        end
    end
end

function _M:onExit()
    _M.super.onExit(self)

    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
end

function _M:onCleanup()
    _M.super.onCleanup(self)
    V.getResourceUI():setVisible(true)
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename(BG_NAME))
    lc.TextureCache:removeTextureForKey("res/jpg/union_battle_bg.jpg")
    lc.TextureCache:removeTextureForKey("res/jpg/dark_battle_bg.jpg")

    ClientData.unloadLCRes({"find.jpm", "find.png.sfb"})
end

function _M:onBattleEnd(resp)
    if resp:HasField("dark_duel_end_resp") then
        V.getActiveIndicator():hide()
        local rewards = {}
        local pbRewards = resp.resource
        for _, card in ipairs(pbRewards) do
            if card.info_id ~= Data.PropsId.flag and not (card.info_id >= Data.PropsId.clash_chest and card.info_id <= Data.PropsId.clash_chest_end) then            
                table.insert(rewards, card)
            end
        end
        if V._findMatchPanel then
            V._findMatchPanel:hide()
        end
        require("RewardPanel").create(rewards):show()
    else
        _M.super:onBattleEnd(resp)
    end
end

function _M:onOpponentNotFound(pbReward)
    local area = self._contentArea
    if area and area.onOpponentNotFound then
        area:onOpponentNotFound(pbReward)
    end
end

return _M