local _M = class("AchieveForm", BaseForm)

local FORM_SIZE = cc.size(960, 660)
local ACHIEVE_POINT_HEIGHT = 60

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
    return panel 
end

function _M:init()
    _M.super.init(self, FORM_SIZE, Str(STR.ACHIEVEMENT), bor(BaseForm.FLAG.ADVANCE_TITLE_BG))

    self._form:setTouchEnabled(false)
    --self._bg:setTouchEnabled(true)    

    local tabArea = V.createHorizontalTabListArea2(lc.w(self._frame), nil, function(tab, isSameTab, isUserBehavior) self:showTab(tab._index, not isSameTab, isUserBehavior) end)
    lc.addChildToPos(self._form, tabArea, cc.p(_M.LEFT_MARGIN + lc.w(tabArea) / 2 - 12, lc.h(self._form) - 100 + 10), 2)
    tabArea._subTabExpandCallback = function(tab) self:showTabFlag() end    
    self._tabArea = tabArea

    local bgPanel = lc.createSprite{_name = "img_troop_bg_2", _crect = cc.rect(20, 15, 1, 1), _size = cc.size(lc.w(self._frame) - V.FRAME_INNER_RIGHT - V.FRAME_INNER_LEFT, lc.bottom(self._tabArea) - 10)}
    lc.addChildToPos(self._frame, bgPanel, cc.p(lc.cw(self._frame), lc.bottom(self._tabArea) - lc.ch(bgPanel) + 4))
    self._bgPanel = bgPanel

    local list = lc.List.createV(cc.size(lc.w(self._bgPanel) - 40, lc.h(self._bgPanel) - 20), 10, 10)
    list:setAnchorPoint(1, 0.5)
    lc.addChildToPos(self._bgPanel, list, cc.p(lc.w(self._bgPanel) - 20, 10 + lc.ch(list)))

    self._list = list

    local achievePointNode = lc.createNode()
    lc.addChildToPos(self._frame , achievePointNode , cc.p((lc.w(self._frame)+lc.right(tabArea)) / 2 - 14, lc.h(self._frame)-V.FRAME_INNER_TOP-ACHIEVE_POINT_HEIGHT))

    local pointNum = ClientData.formatNum(P._achievePoint , 9999)
    local pointLabel = V.createTTF(pointNum , V.FontSize.S1)
    pointLabel:setAnchorPoint(0.5,0)
    lc.addChildToPos(achievePointNode , pointLabel , cc.p(235,-26))
    self._pointLabel = pointLabel
    
    P._playerBonus:sendBonusRequest()
    if self._indicator then
        self._indicator:removeFromParent()
        self._indicator = nil
    end
    self._indicator = V.showPanelActiveIndicator(self._form, lc.bound(self._list))
    lc.offset(self._indicator, 0, 20)

    self._initTabIndex = tab or 1
    self._initSubTab = subTab
    if self._initTabIndex == 1 then
        self._initSubTab = self._initSubTab or 21
    end

    self:refreshTabs()
end

function _M:onDataCallBack()
    if self._indicator then
        self._indicator:removeFromParent()
        self._indicator = nil
    end
    self._tabArea:showTab(Data.BonusType.lord, false)
    self:onGuide(nil)
end

function _M:showTab(tabIndex, isForce, isUserBehavior)
    if not isForce then return end

    self._focusTabIndex = tabIndex
    self:refreshList()

    if GuideManager.isGuideEnabled() and isUserBehavior then
        GuideManager.finishStepLater()
    end
end

function _M:showTabFlag()
    local tabs = self._tabArea._list:getItems()

    for i = 1, #tabs do
        local number = 0
        local index = tabs[i]._index
        if index == Data.BonusType.lord then
            number = P._playerBonus:getMainTaskBonusFlag()
        elseif index == Data.BonusType.level then
            number = P._playerBonus:getLevelTaskBonusFlag()
        elseif index == Data.BonusType.daily_task then
            number = P._playerBonus:getDailyTaskBonusFlag()
        elseif index == Data.BonusType.novice then
            number = P._playerBonus:getNoviceTaskBonusFlag()
        elseif index == Data.BonusType.grain then
            number = P._playerBonus:getGrainTaskBonusFlag()
--        elseif index == Data.BonusType.online then
--            number = P._playerBonus:getOnlineTaskBonusFlag()
        elseif index == Data.BonusType.facebook then
            number = P._playerBonus:getFacebookTaskBonusFlag()
        elseif index == Data.BonusType.clash then
            number = P._playerBonus:getClashBonusesFlag() + P._playerBonus:getArenaBonusesFlag()
        elseif math.floor(index/ 100) == Data.BonusType.level then
            local subIndex = index % 100
            number = P._playerBonus:getLevelTaskBonusFlag(2000 + subIndex)
        elseif math.floor(index/ 100) == Data.BonusType.clash then
            local subIndex = index % 100
            if subIndex == 1 then
                number = P._playerBonus:getClashBonusesFlag()
            elseif subIndex == 2 then
                number = P._playerBonus:getArenaBonusesFlag()
            end
        elseif index == Data.BonusType.gold_cost then
            number = P._playerBonus:getCostBonusFlag()
        elseif index == Data.BonusType.gold_gain then
            number = P._playerBonus:getCollectBonusFlag()
        end

        local tab = tabs[i]
        V.checkNewFlag(tab, number)
    end
end

function _M:onEnter()
    _M.super.onEnter(self)

    self._listeners = {}

    local listener = lc.addEventListener(Data.Event.achieve_list_dirty, function(event) self:onDataCallBack() end)
    table.insert(self._listeners, listener)

    local listener = lc.addEventListener(Data.Event.achieve_point_dirty, function(event) self:refreshPoint()  end)
    table.insert(self._listeners, listener)

    local listener = lc.addEventListener(Data.Event.level_dirty, function(event) self:refreshList() end)
    table.insert(self._listeners, listener)

    listener = lc.addEventListener(Data.Event.bonus_dirty, function(event)
        local bonus = event._data
        local type = bonus._info._type
        if type == Data.BonusType.grain then
            self:showTabFlag()
        end
        --self:refreshCurrentTab()
    end)
    table.insert(self._listeners, listener)

    listener = lc.addEventListener(GuideManager.Event.seek, function(event) self:onGuide(event) end)
    table.insert(self._listeners, listener)

    listener = lc.addEventListener(GuideManager.Event.finish, function(event) self:onGuideFinish(event) end)
    table.insert(self._listeners, listener)

    local curStep = GuideManager.getCurStepName()
    if curStep == "enter task" then
        GuideManager.finishStepLater()
    end
end

function _M:onExit()
    _M.super.onExit(self)

    for _, listener in ipairs(self._listeners) do
        lc.Dispatcher:removeEventListener(listener)
    end

end

function _M:onCleanup()
    V.getMenuUI():updateAchieveFlag()
    _M.super.onCleanup(self)

    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/task_novice_top.jpg"))
end

function _M:onShowActionFinished()
    self:onGuide(nil)
    self._isShown = true

    self._tabArea:showTab(self._initTabIndex)
end

function _M:refreshPoint()
    local pointNum = ClientData.formatNum(P._achievePoint , 9999)
    self._pointLabel:setString(pointNum)
end

function _M:refreshList()
    local list = self._list

    if self._topBar then
        self._topBar:removeFromParent()
        self._topBar = nil
    end

    if self._focusTabIndex == Data.BonusType.lord then
        local validTasks, claimIndex = {}, 1
        for _, task in ipairs(P._playerAchieve:getOrderedMainTasks()) do
            if task:isValid() then
                local bonus = task:getBonus()
                if bonus._value >= bonus._info._val then
                    table.insert(validTasks, claimIndex, task)
                    claimIndex = claimIndex + 1
                else
                    table.insert(validTasks, task)
                end
            end
        end        

        list:bindData(validTasks, function(item, task) self:setOrCreateItem(item, task) end, math.min(5, #validTasks))

        for i = 1, list._cacheCount do
            list:pushBackCustomItem(self:setOrCreateItem(nil, validTasks[i]))
        end

        --list:setContentSize(lc.w(list), lc.h(self._frame))

    elseif self._focusTabIndex == Data.BonusType.level or math.floor(self._focusTabIndex / 100) == Data.BonusType.level then
        local bonuses, claimableBonuses, unclaimBonuses, claimedBonuses = {}, P._playerBonus.splitBonus(P._playerBonus._bonusLevel)
        local characterId = self._focusTabIndex - Data.BonusType.level*100
        for _, bonus in ipairs(claimableBonuses) do if bonus._info._cid - 2000 == characterId then table.insert(bonuses, bonus) end end
        for _, bonus in ipairs(unclaimBonuses) do if bonus._info._cid - 2000 == characterId then table.insert(bonuses, bonus) end end
        for _, bonus in ipairs(claimedBonuses) do if bonus._info._cid - 2000 == characterId then table.insert(bonuses, bonus) end end

        list:bindData(bonuses, function(item, bonus) self:setOrCreateItem(item, bonus) end, math.min(5, #bonuses))

        for i = 1, list._cacheCount do
            list:pushBackCustomItem(self:setOrCreateItem(nil, bonuses[i]))
        end

        --list:setContentSize(lc.w(list), lc.h(self._frame))

    elseif self._focusTabIndex == Data.BonusType.daily_task then
        local reorderedBonuses, claimIndex = {}, 1
        local bonuses = P._playerBonus._bonusDailyTask
        for _, bonus in ipairs(bonuses) do
            local level = P._playerAchieve:getDailyTaskLevel(bonus._info._cid % 100)
            if P._level >= level and not bonus._isClaimed then
                if bonus._value >= bonus._info._val then
                    table.insert(reorderedBonuses, claimIndex, bonus)
                    claimIndex = claimIndex + 1
                else
                    table.insert(reorderedBonuses, bonus)
                end
            end
        end

        list:bindData(reorderedBonuses, function(item, bonus) self:setOrCreateItem(item, bonus) end, math.min(5, #reorderedBonuses))

        for i = 1, list._cacheCount do
            list:pushBackCustomItem(self:setOrCreateItem(nil, reorderedBonuses[i]))
        end

        --list:setContentSize(lc.w(list), lc.h(self._frame))

        list:checkEmpty(Str(STR.LIST_EMPTY_TASK_DONE))

    elseif self._focusTabIndex == Data.BonusType.grain then
        local bonuses = P._playerBonus._bonusGrainTask
        list:bindData(bonuses, function(item, bonus) self:setOrCreateItem(item, bonus) end, math.min(5, #bonuses))

        for i = 1, list._cacheCount do
            list:pushBackCustomItem(self:setOrCreateItem(nil, bonuses[i]))
        end

        --list:setContentSize(lc.w(list), lc.h(self._frame))

--    elseif self._focusTabIndex == Data.BonusType.online then        
--        local bonuses, claimableBonuses, unclaimBonuses, claimedBonuses = {}, P._playerBonus.splitBonus(P._playerBonus._bonusOnlineTask)
--        for _, bonus in ipairs(claimableBonuses) do table.insert(bonuses, bonus) end
--        for _, bonus in ipairs(unclaimBonuses) do table.insert(bonuses, bonus) end
--        for _, bonus in ipairs(claimedBonuses) do table.insert(bonuses, bonus) end

--        list:bindData(bonuses, function(item, bonus) self:setOrCreateItem(item, bonus) end, math.min(5, #bonuses))

--        for i = 1, list._cacheCount do
--            list:pushBackCustomItem(self:setOrCreateItem(nil, bonuses[i]))
--        end

--        --list:setContentSize(lc.w(list), lc.h(self._frame))

    elseif self._focusTabIndex == Data.BonusType.novice then
        local reorderedBonuses, claimIndex = {}, 1
        local bonuses = P._playerBonus._bonusNoviceTask
        for _, bonus in ipairs(bonuses) do
            if not bonus._isClaimed then
                table.insert(reorderedBonuses, claimIndex, bonus)
                claimIndex = claimIndex + 1
            end
        end

        list:bindData(reorderedBonuses, function(item, bonus) self:setOrCreateItem(item, bonus) end, math.min(5, #reorderedBonuses))

        for i = 1, list._cacheCount do
            list:pushBackCustomItem(self:setOrCreateItem(nil, reorderedBonuses[i]))
        end

        if not ClientData.isAppStoreReviewing() then
            list:setContentSize(lc.w(list), lc.h(self._frame) - 110)
            if not list:checkEmpty(Str(STR.LIST_EMPTY_TASK_DONE)) then
                self._topBar = lc.createSpriteWithMask("res/jpg/task_novice_top.jpg")
                lc.addChildToPos(self._frame, self._topBar, cc.p(lc.left(list) + lc.w(self._topBar) / 2 - 8, lc.top(list) + lc.h(self._topBar) / 2 - 14))
            end
        else
            --list:setContentSize(lc.w(list), lc.h(self._frame))
        end

    elseif self._focusTabIndex == Data.BonusType.facebook then
        local bonuses = P._playerBonus._bonusFacebookTask
        list:bindData(bonuses, function(item, bonus) self:setOrCreateItem(item, bonus) end, math.min(5, #bonuses))

        for i = 1, list._cacheCount do
            list:pushBackCustomItem(self:setOrCreateItem(nil, bonuses[i]))
        end

        --list:setContentSize(lc.w(list), lc.h(self._frame))

    elseif self._focusTabIndex == Data.BonusType.clash or  math.floor(self._focusTabIndex/ 100) == Data.BonusType.clash then
        local subType = self._focusTabIndex% 100
        local bonuses = {}
        if subType == 1 then
            for _,clashBonus in ipairs(P._playerBonus._clashBonuses) do
                for _, bonus in ipairs(clashBonus) do
                    if bonus._isClaimed == false then
                        table.insert(bonuses , bonus)
                        break
                    end
                end
            end
        elseif subType == 2 then
            for _, arenaBonus in ipairs(P._playerBonus._arenaBonuses) do
                for _, bonus in ipairs(arenaBonus) do
                    if bonus._isClaimed == false then
                        table.insert(bonuses , bonus)
                        break
                    end
                end
            end
        end

        table.sort(bonuses, function (A, B)
            if A:canClaim() and not B:canClaim() then
                return true
            elseif not A:canClaim() and B:canClaim() then
                return false
            end
            return A._type < B._type
        end)

        list:bindData(bonuses, function(item, bonus) self:setOrCreateItem(item, bonus) end, math.min(5, #bonuses))

        for i = 1, list._cacheCount do
            list:pushBackCustomItem(self:setOrCreateItem(nil, bonuses[i]))
        end
    elseif self._focusTabIndex == Data.BonusType.gold_cost then
        local bonuses = {}
        for _,consumBonus in ipairs(P._playerBonus._costBonuses) do
            for _, bonus in ipairs(consumBonus) do
                if bonus._isClaimed == false then
                    table.insert(bonuses , bonus)
                    break
                end
            end
        end

        table.sort(bonuses, function (A, B)
                if A:canClaim() and not B:canClaim() then
                    return true
                elseif not A:canClaim() and B:canClaim() then
                    return false
                end
                return A._type < B._type
            end)

        list:bindData(bonuses, function(item, bonus) self:setOrCreateItem(item, bonus) end, math.min(5, #bonuses))

        for i = 1, list._cacheCount do
            list:pushBackCustomItem(self:setOrCreateItem(nil, bonuses[i]))
        end
    elseif self._focusTabIndex == Data.BonusType.gold_gain then
        local bonuses = {}
        for _,cardBonus in ipairs(P._playerBonus._collectBonuses) do
            for _, bonus in ipairs(cardBonus) do
                if bonus._isClaimed == false then
                    table.insert(bonuses , bonus)
                    break
                end
            end
        end

        table.sort(bonuses, function (A, B)
                if A:canClaim() and not B:canClaim() then
                    return true
                elseif not A:canClaim() and B:canClaim() then
                    return false
                end
                return A._type < B._type
            end)

        list:bindData(bonuses, function(item, bonus) self:setOrCreateItem(item, bonus) end, math.min(5, #bonuses))

        for i = 1, list._cacheCount do
            list:pushBackCustomItem(self:setOrCreateItem(nil, bonuses[i]))
        end
    end

    list:forceDoLayout()
    list:gotoTop()

    self:showTabFlag()
end

function _M:refreshCurrentTab()
    local focusedIndex = self._tabArea._focusedTab._index
    self:refreshTabs()
    if focusedIndex then
        self._tabArea:showTab(focusedIndex)
    end
end

function _M:refreshTabs()
    local characterTabs = {
        --{_str = Str(Data._characterInfo[10]._nameSid), _subIndex = Data.BonusType.level*100+10, _isSub = true},
        --{_str = Str(Data._characterInfo[13]._nameSid), _subIndex = Data.BonusType.level*100+13, _isSub = true},
        --{_str = Str(Data._characterInfo[12]._nameSid), _subIndex = Data.BonusType.level*100+12, _isSub = true},
        --{_str = string.sub(Str(Data._characterInfo[5]._nameSid), 1, 9), _subIndex = Data.BonusType.level*100+5, _isSub = true},
        {_str = Str(Data._characterInfo[2]._nameSid), _subIndex = Data.BonusType.level*100+2, _isSub = true},
        {_str = Str(Data._characterInfo[3]._nameSid), _subIndex = Data.BonusType.level*100+3, _isSub = true},
        {_str = Str(Data._characterInfo[4]._nameSid), _subIndex = Data.BonusType.level*100+4, _isSub = true},
     }

     local BattleFieldTabs = {
        {_str = Str(STR.FIND_ARENA_TITLE) , _subIndex = Data.BonusType.clash*100+2 , _isSub = true},
        {_str = Str(STR.FIND_CLASH_TITLE) , _subIndex = Data.BonusType.clash*100+1 , _isSub = true},
      }

    local tabs = nil
    if ClientData.isAppStoreReviewing() then
--        Data.AchieveType = {online = 1}
        tabs = {
--            {_str = Str(STR.ONLINE_TASK), _index = Data.BonusType.online},
        }
    else
        tabs = {
            {_str = Str(STR.MAIN_TASK), _index = Data.BonusType.lord},
            {_str = Str(STR.LEVEL_TASK), _index = Data.BonusType.level, _tabs = characterTabs},
            --{_str = Str(STR.DAILY_TASK)},
            --{_str = Str(STR.GRAIN_TASK)},
--            {_str = Str(STR.ONLINE_TASK), _index = Data.BonusType.online},
            {_str = Str(STR.APP_NAME_JDZC), _index = Data.BonusType.clash, _tabs = BattleFieldTabs},
            {_str = Str(STR.ACHIEVE_COST), _index = Data.BonusType.gold_cost},
            {_str = Str(STR.ACHIEVE_COLLECT),  _index = Data.BonusType.gold_gain},
        }
    end

    if ClientData.isUseFacebook() then
        Data.BonusType.facebook = Data.BonusType.online + 1
        Data.BonusType.novice = Data.BonusType.online + 2
        table.insert(tabs, {_str = 'Facebook'..Str(STR.BONUS)})
    end

    if not P._playerBonus:isAllNoviceTaskClaimed() then
        --TODO--
        --table.insert(tabs, {_str = Str(STR.NOVICE_TASK)})
    end

--    if P:checkFindClash() then
--        table.insert(tabs,{_str = Str(STR.FIND_TITLE), _index = Data.BonusType.fight, _tabs = BattleFieldTabs, checkValid = function()
--            return P:checkFindClash()
--            end})
--    end

    self._tabArea:resetTabs(tabs)
end

function _M:setOrCreateItem(item, data)
    if self._focusTabIndex == Data.BonusType.lord then
        local bonus = data:getBonus()
        local title = Str(STR.MAIN_TASK_CHAPTER + data._info._type)
        if item == nil then
            item = require("BonusWidget").create(lc.w(self._list), bonus, title, data:getDesc())
        else
            item:setBonus(bonus, title, data:getDesc())
            item._newFlag = nil
        end
        item:registerCallback(function(bonus) self:dealMainTask(bonus) end)

        local count = data:getClaimableCount()
        if count > 1 then
            local flag = V.checkNewFlag(item, count, -40, -32)
            if flag then flag:setSpriteFrame("img_new_g") end

            if item._progBar then
                item._progBar:setVisible(false)
            end

            local btnClaimAll = V.createScale9ShaderButton("img_btn_1_s", function()
                local bonusInfo = bonus._info
                local type, cid = bonusInfo._type, bonusInfo._cid

                local bonusMap, bonuses = {}, {}
                for _, t in pairs(P._playerAchieve._mainTasks) do
                    local bonus = t:getBonus()
                    local bonusInfo = bonus._info
                    if bonus._info._type == type and bonus._info._cid == cid then
                        if bonus:canClaim() then
                            ClientData.claimBonus(bonus)

                            for i, id in ipairs(bonusInfo._rid) do
                                local bonus = bonusMap[id]
                                if bonus == nil then
                                    bonus = {}
                                    bonusMap[id] = bonus

                                    bonus._infoId = id
                                    bonus._count = bonusInfo._count[i]
                                    bonus._level = bonusInfo._level[i]
                                    bonus._isFragment = bonusInfo._isFragment[i] > 0

                                    table.insert(bonuses, bonus)
                                else
                                    bonus._count = bonus._count + bonusInfo._count[i]
                                end
                            end
                        end
                    end
                end

                local RewardPanel = require("RewardPanel")
                RewardPanel.create(bonuses, RewardPanel.MODE_CLAIM_ALL):show()
                lc.Audio.playAudio(AUDIO.E_CLAIM)

                self:refreshList()

            end, V.CRECT_BUTTON_S, lc.w(item._button))
            btnClaimAll:addLabel(Str(STR.CLAIM_ALL))
            lc.addChildToPos(item, btnClaimAll, cc.p(lc.x(item._button), lc.bottom(item._button) - 4 - lc.h(btnClaimAll) / 2))
        end
    
    elseif self._focusTabIndex == Data.BonusType.novice then
        local title = string.format(Str(STR.NOVICE_TASK_LOGIN_DAYS_TO_CLAIM), data._infoId % 100)
        local desc = Str(data._info._nameSid)
        if item == nil then
            item = require("BonusWidget").create(lc.w(self._list), data, title, desc)
        else
            item:setBonus(data, title, desc)
        end
        item:registerCallback(function(bonus) self:dealNoviceTask(bonus) end)

    elseif self._focusTabIndex == Data.BonusType.facebook then
        if item == nil then
            item = require("BonusWidget").create(lc.w(self._list), data, title)
        else
            item:setBonus(data, title)
        end
        item:registerCallback(function(bonus) self:dealFacebookTask(bonus) end)

    elseif self._focusTabIndex == Data.BonusType.clash or math.floor(self._focusTabIndex / 100) == Data.BonusType.clash then
        local title = string.format(Str(data._info._nameSid), data._info._val)
        if item == nil then
            item = require("BonusWidget").create(lc.w(self._list), data, title)
        else
            item:setBonus(data, title)
        end
        item:registerCallback(function(bonus) self:dealClashAchieve(bonus) end)

        local count = 0
        if data._type == Data.BonusType.clash then
            count = P._playerBonus:getClashBonusFlag()
        elseif data._type == Data.BonusType.clash_conti then
            count = P._playerBonus:getClashContiBonusFlag()
        elseif data._type == Data.BonusType.clash_legacy then
            count = P._playerBonus:getClashLegacyBonusFlag()
        elseif data._type == Data.BonusType.clash_zone then
            count = P._playerBonus:getClashZoneBonusFlag()
        elseif data._type == Data.BonusType.arena_once then
            count = P._playerBonus:getArenaOnceBonusFlag()
        elseif data._type == Data.BonusType.arena_all then
            count = P._playerBonus:getArenaAllBonusFlag()
        elseif data._type == Data.BonusType.arena_12 then
            count = P._playerBonus:getArena12BonusFlag()
        end

        if count > 1 then
            local flag = V.checkNewFlag(item, count, -40, -32)
            if flag then flag:setSpriteFrame("img_new_g") end

            local btnClaimAll = V.createScale9ShaderButton("img_btn_1_s", function() self:claimAll(data) end, V.CRECT_BUTTON_S, lc.w(item._button), 50)
            btnClaimAll:addLabel(Str(STR.CLAIM_ALL))
            item:adjustPosition(true)
            lc.addChildToPos(item, btnClaimAll, cc.p(lc.x(item._button), lc.bottom(item._button) - 4 - lc.h(btnClaimAll) / 2))

        end

    elseif self._focusTabIndex == Data.BonusType.gold_cost then
        local title = string.format(Str(data._info._nameSid), data._info._val)
        if item == nil then
            item = require("BonusWidget").create(lc.w(self._list), data, title)
        else
            item:setBonus(data, title)
        end
        item:registerCallback(function(bonus) self:dealCostAchieve(bonus) end)
        local count = 0
        if data._type == Data.BonusType.gold_cost then
            count = P._playerBonus:getGoldCostBonusFlag()
        elseif data._type == Data.BonusType.gem_cost then
            count = P._playerBonus:getGemCostBonusFlag()
        elseif data._type == Data.BonusType.bottle then
            count = P._playerBonus:getBottleBonusFlag()
        elseif data._type == Data.BonusType.card_package then
            count = P._playerBonus:getCardPackageBonusFlag()
        end

        if count > 1 then
            local flag = V.checkNewFlag(item, count, -40, -32)
            if flag then flag:setSpriteFrame("img_new_g") end

            local btnClaimAll = V.createScale9ShaderButton("img_btn_1_s", function() self:claimAll(data) end, V.CRECT_BUTTON_S, lc.w(item._button), 50)
            btnClaimAll:addLabel(Str(STR.CLAIM_ALL))
            item:adjustPosition(true)
            lc.addChildToPos(item, btnClaimAll, cc.p(lc.x(item._button), lc.bottom(item._button) - 4 - lc.h(btnClaimAll) / 2))

        end


    elseif self._focusTabIndex == Data.BonusType.gold_gain then
        local title = string.format(Str(data._info._nameSid), data._info._val)
        if item == nil then
            item = require("BonusWidget").create(lc.w(self._list), data, title)
        else
            item:setBonus(data, title)
        end
        item:registerCallback(function(bonus) self:dealCollectAchieve(bonus) end)

        local count = 0
        if data._type == Data.BonusType.card_sr then
            count = P._playerBonus:getCardSrBonusFlag()
        elseif data._type == Data.BonusType.card_ur then
            count = P._playerBonus:getCardUrBonusFlag()
        elseif data._type == Data.BonusType.gold_gain then
            count = P._playerBonus:getGoldGainBonusFlag()
        end

        if count > 1 then
            local flag = V.checkNewFlag(item, count, -40, -32)
            if flag then flag:setSpriteFrame("img_new_g") end

            local btnClaimAll = V.createScale9ShaderButton("img_btn_1_s", function() self:claimAll(data) end, V.CRECT_BUTTON_S, lc.w(item._button), 50)
            btnClaimAll:addLabel(Str(STR.CLAIM_ALL))
            item:adjustPosition(true)
            lc.addChildToPos(item, btnClaimAll, cc.p(lc.x(item._button), lc.bottom(item._button) - 4 - lc.h(btnClaimAll) / 2))

        end


    else
        local title
        if self._focusTabIndex == Data.BonusType.level or math.floor(self._focusTabIndex / 100) == Data.BonusType.level then
            title = string.format(Str(data._info._nameSid), data._info._val)
        end

        if item == nil then
            item = require("BonusWidget").create(lc.w(self._list), data, title)
        else
            item:setBonus(data, title)
        end
        item:registerCallback(function(bonus) self:dealCommonTask(bonus) end)

    end

    return item
end

function _M:claimAll(bonus)
    local bonusInfo = bonus._info
    local type, cid = bonusInfo._type, bonusInfo._cid

    local bonusGroup = {}
    if bonus._type==Data.BonusType.clash then
        bonusGroup = P._playerBonus._bonusClash
    elseif bonus._type==Data.BonusType.clash_conti then
        bonusGroup = P._playerBonus._bonusClashConti
    elseif bonus._type==Data.BonusType.clash_legacy then
        bonusGroup = P._playerBonus._bonusClashLegacy
    elseif bonus._type==Data.BonusType.clash_local then
        bonusGroup = P._playerBonus._bonusClashLocal
    elseif bonus._type==Data.BonusType.clash_target then
        bonusGroup = P._playerBonus._bonusClashTarget
    elseif bonus._type==Data.BonusType.gold_cost then
        bonusGroup = P._playerBonus._bonusGoldCost
    elseif bonus._type==Data.BonusType.gem_cost then
        bonusGroup = P._playerBonus._bonusGemCost
    elseif bonus._type==Data.BonusType.gold_gain then
        bonusGroup = P._playerBonus._bonusGoldGain
    elseif bonus._type==Data.BonusType.card_package then
        bonusGroup = P._playerBonus._bonusCardPackage
    elseif bonus._type==Data.BonusType.card_ur then
        bonusGroup = P._playerBonus._bonusCardUr
    elseif bonus._type==Data.BonusType.card_sr then
        bonusGroup = P._playerBonus._bonusCardSr
    elseif bonus._type==Data.BonusType.bottle then
        bonusGroup = P._playerBonus._bonusBottle
    elseif bonus._type==Data.BonusType.arena_once then
        bonusGroup = P._playerBonus._bonusArenaOnce
    elseif bonus._type==Data.BonusType.arena_all then
        bonusGroup = P._playerBonus._bonusArenaAll
    elseif bonus._type==Data.BonusType.arena_12 then
        bonusGroup = P._playerBonus._bonusArena12
    end

    local bonusMap, bonuses = {}, {}
    for _, t in pairs(bonusGroup) do
        local bonus = t
        local bonusInfo = bonus._info
        if bonus._info._type == type and bonus._info._cid == cid then
            if bonus:canClaim() then
                ClientData.claimBonus(bonus)

                for i, id in ipairs(bonusInfo._rid) do
                    local bonus = bonusMap[id]
                    if bonus == nil then
                        bonus = {}
                        bonusMap[id] = bonus

                        bonus._infoId = id
                        bonus._count = bonusInfo._count[i]
                        bonus._level = bonusInfo._level[i]
                        bonus._isFragment = bonusInfo._isFragment[i] > 0

                        table.insert(bonuses, bonus)
                    else
                        bonus._count = bonus._count + bonusInfo._count[i]
                    end
                end
            end
        end
    end

    local RewardPanel = require("RewardPanel")
    RewardPanel.create(bonuses, RewardPanel.MODE_CLAIM_ALL):show()
    lc.Audio.playAudio(AUDIO.E_CLAIM)

    self:refreshList()
end

function _M:dealClashAchieve(bonus)
    if bonus._value >= bonus._info._val then
        if not bonus._isClaimed then
            local result = ClientData.claimBonus(bonus)
            self:refreshList()
            V.showClaimBonusResult(bonus, result)
        end
    elseif P:checkFindClash() then
        if bonus._type == Data.BonusType.arena_once or bonus._type == Data.BonusType.arena_all or bonus._type == Data.BonusType.arena_12 then
            lc.pushScene(require("FindScene").create(Data.FindMatchType.ladder))
        else
            lc.pushScene(require("FindScene").create())
        end
        self:hide(true)
    else
        ToastManager.push(string.format(Str(STR.FINDSCENE_LOCKED), Str(Data._chapterInfo[1]._nameSid)))
    end
end

function _M:dealCollectAchieve(bonus)
    if bonus._value >= bonus._info._val then
        if not bonus._isClaimed then
            local result = ClientData.claimBonus(bonus)
            self:refreshList()
            V.showClaimBonusResult(bonus, result)
        end
    else
        
        if bonus._info._type == Data.BonusType.gold_gain then
            require("ExchangeResForm").create(Data.ResType.gold):show()
            self:hide(true)
        else
            lc.pushScene(require("TavernScene").create())
            self:hide(true)
        end
    end
end

function _M:dealCostAchieve(bonus)
    if bonus._value >= bonus._info._val then
        if not bonus._isClaimed then
            local result = ClientData.claimBonus(bonus)
            self:refreshList()
            V.showClaimBonusResult(bonus, result)
        end
    else
        lc.pushScene(require("TavernScene").create())
        self:hide(true)
    end
end

function _M:dealMainTask(bonus)
    if bonus._value >= bonus._info._val then
        if not bonus._isClaimed then
            local result = ClientData.claimBonus(bonus)
            self:refreshList()
            V.showClaimBonusResult(bonus, result)
        end
    else
        local gotoTask
        for k, v in pairs(P._playerAchieve._mainTasks) do
            if v._info._bonusId == bonus._infoId then
                if GuideManager.isGuideEnabled() then
                    local curStep = GuideManager.getCurStepName()
                    if v._type == Data.MainTaskType.chapter then
                        if lc._runningScene._sceneId == ClientData.SceneId.city then
                            if curStep == "enter world" then
                                GuideManager.finishStep()
                            end
                        end
                    elseif v._type == Data.MainTaskType.card then
                        if curStep == "enter heromansion" or curStep == "enter barrack" then
                            GuideManager.finishStep()
                        end
                    end
                else
                    gotoTask = v
                end
            end
        end

        if gotoTask then
            self:setVisible(false)
            local bonus = gotoTask:getBonus()
            self:gotoBonusTask(bonus)
        end

        self:hide(true)
    end
end

function _M:dealCommonTask(bonus)
    if bonus._value >= bonus._info._val then
        if not bonus._isClaimed then
            local result = ClientData.claimBonus(bonus)
            self:refreshList()
            V.showClaimBonusResult(bonus, result)
        end
    else
        local type = bonus._info._cid % 100
        if type == Data.DailyAchieveType.city_battle_win then
            if lc._runningScene._sceneId == ClientData.SceneId.city then
                self:guideToChapter()
            else
                lc._runningScene:setWorldDisplay(Data.WorldDisplay.normal)
            end
        elseif type == Data.DailyAchieveType.challenge_elite
            or type == Data.DailyAchieveType.city_battle_win or type == Data.DailyAchieveType.player_battle_win
            or type == Data.DailyAchieveType.rob_horse or type == Data.DailyAchieveType.copy_boss or type == Data.DailyAchieveType.expedition then            

            if type == Data.DailyAchieveType.player_battle_win then
                lc.pushScene(require("FindScene").create())
            elseif type == Data.DailyAchieveType.rob_horse then
                require("CrusadePanel").create(Data.CopyType.group_commander):show()
            elseif type == Data.DailyAchieveType.challenge_elite then
                require("CrusadePanel").create(Data.CopyType.group_elite):show()
            elseif type == Data.DailyAchieveType.expedition then
                require("CrusadePanel").create(Data.CopyType.group_expedition):show()
            elseif type == Data.DailyAchieveType.copy_boss then
                require("CrusadePanel").create(Data.CopyType.group_boss):show()
            end

        elseif type == Data.DailyAchieveType.collect_in_residence or type == Data.DailyAchieveType.collect_in_farmland or type == Data.DailyAchieveType.collect_fragment then
            self:gotoBonusTask(bonus)

        elseif type == Data.DailyAchieveType.upgrade_hero then
            V.popScene(true)
            lc.pushScene(require("CardBoxScene").create(ClientData.SceneId.factory_monster))
        elseif type == Data.DailyAchieveType.upgrade_book then
            V.popScene(true)
            lc.pushScene(require("CardBoxScene").create(ClientData.SceneId.factory_magic))
        elseif type == Data.DailyAchieveType.upgrade_equip then
            V.popScene(true)
            lc.pushScene(require("CardBoxScene").create(ClientData.SceneId.factory_trap))
        elseif type == Data.DailyAchieveType.upgrade_horse then
            V.popScene(true)
            lc.pushScene(require("CardBoxScene").create(ClientData.SceneId.stable))
        elseif type == Data.DailyAchieveType.lottery_hero then
            V.popScene(true)
            lc.pushScene(require("TavernScene").create())
        elseif type == Data.DailyAchieveType.open_box then
            V.popScene(true)
            lc.pushScene(require("DepotScene").create())
        elseif type == Data.DailyAchieveType.challenge_uboss then
            if P:hasUnion() then
                V.popScene(true)
                lc.pushScene(require("UnionScene").create())
            else
                ToastManager.push(Str(STR.UNLOCK_JOIN_UNION))
                return
            end
        end

        self:hide(true)
    end
end

function _M:dealNoviceTask(bonus)
    local requiredDay = bonus._infoId % 100
    if bonus._value >= bonus._info._val then
        if not bonus._isClaimed then
            local loginDay = P._playerBonus._bonusLogin[1]._value
            if loginDay < requiredDay then
                ToastManager.push(string.format(Str(STR.NOVICE_TASK_CANT_CLAIM), requiredDay))
                return
            end

            local result = ClientData.claimBonus(bonus)
            self:refreshList()
            V.showClaimBonusResult(bonus, result)
        end
    else
        self:setVisible(false)
        self:gotoBonusTask(bonus)
        self:hide(true)
    end
end

function _M:dealFacebookTask(bonus)
    if bonus._value >= bonus._info._val then
        if not bonus._isClaimed then
            local result = ClientData.claimBonus(bonus)
            self:refreshList()
            V.showClaimBonusResult(bonus, result)
        end
    else
        self:gotoBonusTask(bonus)
    end
end

function _M:gotoBonusTask(bonus)
    local cid = bonus._info._cid

    if bonus._info._type == Data.BonusType.facebook then
        if (lc.PLATFORM == cc.PLATFORM_OS_WINDOWS) then
            local eventStr = {"FACEBOOK_LOGGEDIN", "FACEBOOK_LIKED", "FACEBOOK_INVITED"}
            local eventCustom = cc.EventCustom:new(Data.Event.application)
            eventCustom:setUserString(eventStr[cid - 2400])
            lc.Dispatcher:dispatchEvent(eventCustom)
        else
            if cid == 2401 then
                lc.App:facebookLogin()
            elseif cid == 2402 then
                lc.App:facebookLike("https://www.facebook.com/%E8%99%9F%E4%BB%A4%E4%B8%89%E5%9C%8B-1330223180338868/")
            elseif cid == 2403 then
                lc.App:facebookInvite("https://fb.me/1037952556288521");
            end
        end

    elseif cid == 1705 then
        -- Bonus do not need switch scene
        GuideManager.showSoftGuideFinger(V.getMenuUI()._btnRank)

    elseif bonus:isChapter() or cid == 1701 or cid == 1702 or (cid >= 2000 and cid <= 2100) then
        -- Bonus in the world scene
        if lc._runningScene._sceneId == ClientData.SceneId.city then
            local city
            if bonus:isChapter() then
                local levelInfo = Data._levelInfo[bonus._info._val]
                require("TravelPanel").create(levelInfo._id):show()

            elseif cid == 1701 then                
                lc.pushScene(require("WorldScene").create({_infoId = 1}, Data.WorldDisplay.normal))

            elseif cid == 1702 then
                -- Find a city chapter which can sweep
                for _, chapterInfo in ipairs(P._playerWorld._chapters) do
                    local city = P._playerWorld._cities[chapterInfo._levelId]
                    if city._status == city.Status.self and city:getType() ~= Data.CityType.small then
                        self:guideToChapter(city._chapterIds[1])
                        break
                    end
                end
            else
                self:guideToChapter()
            end
        else
            lc._runningScene:onGotoBonusTask(bonus)
        end

    else
        -- Bonus in the city scene
        if lc._runningScene._sceneId == ClientData.SceneId.world then
            -- Back to city scene
            V.popScene(true)
        end

        if V._cityScene then
            V._cityScene:onGotoBonusTask(bonus)
        end
    end
end

function _M:guideToChapter(chapter)
   
end

function _M:hide(isForce)
    _M.super.hide(self, isForce)

    local curStep = GuideManager.getCurStepName()
    if curStep == "close task" then
        GuideManager.finishStep()
    end
end

function _M:onGuide(event)
    local curStep = GuideManager.getCurStepName()
    if curStep == "claim task" then
        if self._list:getChildrenCount() > 0 then
            GuideManager.setOperateLayer(self._list:getItem(0)._button)
        end
    elseif curStep == "close task" then
        GuideManager.setOperateLayer(self._btnBack)
    elseif string.find(curStep, "goto task") then
        local index = tonumber(curStep:split(' ')[3])
        local delay = 0
        if index == 4 then
            -- Upgrade guide, we have to scroll to the item to make it visible
            self._list:scrollToBottom(0.2, false)
            delay = 0.3
        end

        self._list:runAction(lc.sequence(delay,
            function()
                GuideManager.setOperateLayer(self._list:getItem(index)._button)
            end
        ))
    elseif curStep == "show tab maintask" then
        GuideManager.setOperateLayer(self._tabArea._list:getItem(Data.BonusType.lord - 1))
    elseif curStep == "show tab dailytask" then
        GuideManager.setOperateLayer(self._tabArea._list:getItem(Data.BonusType.daily_task - 1))
    elseif curStep == "show tab novicetask" then
        GuideManager.setOperateLayer(self._tabArea._list:getItem(Data.BonusType.novice - 1))
    else
        return
    end
    
    if event then
        event:stopPropagation()
    end
end

function _M:onGuideFinish(event)
    local guideId = event._guideId
    if guideId == 500 then
        GuideManager.showSoftGuideFinger(self._list:getItem(Data.BonusType.lord - 1)._button)
    end
end

return _M