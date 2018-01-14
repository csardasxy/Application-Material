local _M = class("TeachingForm", BaseForm)

local FORM_SIZE = cc.size(1010, 700)
local TEACHING_PASS_HEIGHT = 60

local SUBTYPE_GROUP_SIZE = 8

function _M.create(index)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(index)
    return panel 
end

function _M:init(index)
    _M.super.init(self, FORM_SIZE, Str(STR.GUIDANCE), bor(BaseForm.FLAG.ADVANCE_TITLE_BG))

    self._index = index or 10001
    self._form:setTouchEnabled(false)
    
    self:initData()

    local midTabs = {
        {_str = Str(STR.MID_TRANING_WARRIOR) , _subIndex = 23, _isSub = true, checkValid = function() 
            local level = Data._globalInfo._unlockMidTeach + 4
            if P:getMaxCharacterLevel() < level then 
                ToastManager.push(string.format(Str(STR.LORD_UNLOCK_LEVEL), level)) 
                return false
            end
            return true
        end},
        {_str = Str(STR.MID_TRANING_DRAGON) , _subIndex = 22, _isSub = true, checkValid = function() 
            local level = Data._globalInfo._unlockMidTeach + 2
            if P:getMaxCharacterLevel() < level then 
                ToastManager.push(string.format(Str(STR.LORD_UNLOCK_LEVEL), level)) 
                return false
            end
            return true
        end},
        {_str = Str(STR.MID_TRANING_MAGICIAN) , _subIndex = 21, _isSub = true},
      }

    local tabs = {
            {_str = Str(STR.BASIC_TRAINING), _index = Data.TeachType.basic_teach},
            {_str = Str(STR.MID_TRAINING), _index = Data.TeachType.mid_teach, _tabs = midTabs, checkValid = function() 
                if P:getMaxCharacterLevel() < Data._globalInfo._unlockMidTeach then 
                    ToastManager.push(string.format(Str(STR.LORD_UNLOCK_LEVEL), Data._globalInfo._unlockMidTeach)) 
                    return false
                end
                return true
            end},
            {_str = Str(STR.MASTER_TRAINING), _index = Data.TeachType.master_teach, checkValid = function() 
                if P:getMaxCharacterLevel() < Data._globalInfo._unlockMasterTeach then 
                    ToastManager.push(string.format(Str(STR.LORD_UNLOCK_LEVEL), Data._globalInfo._unlockMasterTeach)) 
                    return false
                end
                return true
            end},
            {_str = Str(STR.NEW_TRAINING), _index = Data.TeachType.new_teach, checkValid = function() 
                if P:getMaxCharacterLevel() < Data._globalInfo._unlockNewTeach then 
                    ToastManager.push(string.format(Str(STR.LORD_UNLOCK_LEVEL), Data._globalInfo._unlockNewTeach)) 
                    return false
                end
                return true
            end},
        }

    local tabArea = V.createVerticalTabListArea(lc.h(self._frame) - V.FRAME_INNER_TOP - V.FRAME_INNER_BOTTOM, tabs, function(tab, isSameTab, isUserBehavior) self:showTab(tab._index, not isSameTab, isUserBehavior) end)
    tabArea._subTabExpandCallback = function() self:updateButtonFlags() end
    lc.addChildToPos(self._frame, tabArea, cc.p(V.FRAME_INNER_LEFT + lc.w(tabArea) / 2, lc.h(self._frame) / 2), 0)
    self._tabArea = tabArea

    local list = lc.List.createV(cc.size(lc.w(self._frame) - lc.right(tabArea) - V.FRAME_INNER_RIGHT - 24, lc.h(self._frame) - V.FRAME_INNER_TOP - V.FRAME_INNER_BOTTOM - TEACHING_PASS_HEIGHT - 52), 10, 10)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(self._frame, list, cc.p(lc.right(tabArea) + 14 + lc.w(list) / 2, lc.h(self._frame) / 2 - TEACHING_PASS_HEIGHT))
    self._list = list

    local teachingPassNode = lc.createNode()
    lc.addChildToPos(self._frame, teachingPassNode, cc.p((lc.w(self._frame) + lc.right(tabArea)) / 2 - 14, lc.h(self._frame) - V.FRAME_INNER_TOP - TEACHING_PASS_HEIGHT))
    local teachingPassSprite = lc.createSprite("res/jpg/bat_passed_bg.jpg")
    teachingPassNode:addChild(teachingPassSprite)

    local passLabel = V.createTTF("", V.FontSize.S1)
    passLabel:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(teachingPassNode, passLabel, cc.p(235, lc.h(teachingPassNode) / 2 - 10))
    self._passLabel = passLabel

end

function _M:initData()
    self._teachInfos = {{}, {}, {}, {}}
    for _, info in pairs(Data._teachInfo) do
        local index = math.floor(info._id / Data.INFO_ID_GROUP_SIZE_LARGE)
        self._teachInfos[index][#self._teachInfos[index] + 1] = info
    end
end

function _M:onEnter()
    _M.super.onEnter(self)

    local typeIndex = math.floor(self._index / Data.INFO_ID_GROUP_SIZE_LARGE)
    if typeIndex ~= Data.TeachType.mid_teach then
        self._tabArea:showTab(typeIndex, false)
    else
        local subTypeIndex = math.floor(((self._index % Data.INFO_ID_GROUP_SIZE_LARGE) - 1) / SUBTYPE_GROUP_SIZE) + 1
        self._tabArea:showTab(typeIndex, false)
        self._tabArea:showTab(typeIndex * 10 + subTypeIndex, false)
    end
end

function _M:onExit()
    _M.super.onExit(self)
end

function _M:onCleanup()
    _M.super.onCleanup(self)

    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/task_novice_top.jpg"))
end

function _M:hide(isForce)
    _M.super.hide(self, isForce)

    local curStep = GuideManager.getCurStepName()
    if curStep == "close task" then
        GuideManager.finishStep()
    end
end

function _M:showTab(tabIndex, isForce, isUserBehavior)
    if not isForce then return end

    self._focusTabIndex = tabIndex
    if tabIndex < 10 then
        self:updatePassed(tabIndex)
    else
        self:updatePassed(math.floor(tabIndex / 10), tabIndex % 10)
    end
    self:refreshList()

    if GuideManager.isGuideEnabled() and isUserBehavior then
        GuideManager.finishStepLater()
    end
end

function _M:updatePassed(typeIndex, subTypeIndex)
    local passLimitNum = #self:getTeachInfos(typeIndex, subTypeIndex)
    local passNum = self:getTeachPassed(typeIndex, subTypeIndex)
    local passStr = string.format(passNum .. "/" .. passLimitNum)
    self._passLabel:setString(passStr)
end

function _M:getTeachInfos(typeIndex, subTypeIndex)
    if subTypeIndex == nil then return self._teachInfos[typeIndex] end

    local infos = {}
    for i = 1, #self._teachInfos[typeIndex] do
        local info = self._teachInfos[typeIndex][i]
        if math.floor((info._id % Data.INFO_ID_GROUP_SIZE_LARGE - 1) / SUBTYPE_GROUP_SIZE) + 1 == subTypeIndex then
            infos[#infos + 1] = info
        end
    end

    return infos
end

function _M:getTeachPassed(typeIndex, subTypeIndex)
    local passed = 0
    
    for k, teach in pairs(self._teachInfos[typeIndex]) do
        local bonus = P._playerBonus._bonusTeach[teach._bonusId]
        if subTypeIndex == nil or (k > (subTypeIndex - 1) * SUBTYPE_GROUP_SIZE and k <= subTypeIndex * SUBTYPE_GROUP_SIZE) then
            if bonus ~= nil and self:isTeachComplete(bonus) then
                passed = passed + 1
            end
        end
    end

    return passed
end

function _M:isTeachComplete(bonus)
    return bonus._isClaimed or (bonus._isClaimed == false and bonus:canClaim())
end

function _M:refreshList()
    local list = self._list

    if self._topBar then
        self._topBar:removeFromParent()
        self._topBar = nil
    end

    local sortFunc = function(a, b)
        local bonusA = P._playerBonus._bonusTeach[a._bonusId]
        local bonusB = P._playerBonus._bonusTeach[b._bonusId]
        if bonusA._isClaimed and not bonusB._isClaimed then return false
        elseif not bonusA._isClaimed and bonusB._isClaimed then return true
        else return a._id < b._id 
        end
    end

    for i = Data.TeachType.basic_teach, Data.TeachType.count do
        table.sort(self._teachInfos[i], sortFunc)
    end
    
    list:gotoTop()

    local infos
    if self._focusTabIndex < 10 then
        infos = self:getTeachInfos(self._focusTabIndex)
    else
        infos = self:getTeachInfos(math.floor(self._focusTabIndex / 10), self._focusTabIndex % 10)
    end
    list:bindData(infos, function(item, teach) self:setOrCreateItem(item, teach) end, math.min(5, #infos))
    for i = 1, list._cacheCount do
        list:pushBackCustomItem(self:setOrCreateItem(nil, infos[i]))
    end
    list:checkEmpty(Str(STR.LIST_EMPTY_NO_TRAINING))
    
    self:updateButtonFlags()
end

function _M:setOrCreateItem(item, teachInfo)
    local bonus = P._playerBonus._bonusTeach[teachInfo._bonusId]
    local title = string.format('%d-%d ', math.floor(teachInfo._id / 10000), teachInfo._id % 10000)..Str(teachInfo._titleSid)
    local brief = Str(teachInfo._briefSid)
    if item == nil then
        item = require("BonusWidget").create(lc.w(self._list), bonus, title, brief)
    else
        item:setBonus(bonus, title, brief)
    end
    item:registerCallback(function(bonus) self:dealTeachTask(teachInfo, bonus) end)

    if bonus._value >= bonus._info._val then
        if bonus._isClaimed then
            item._button:setVisible(true)
            item._button._label:setString(Str(STR.BATTLE_AGAIN))
        end
        item._claimedFlag:setSpriteFrame('passed_bg')
        item._claimedFlag:setColor(lc.Color3B.white)
        item._claimedFlag:setPositionY(120)
        item._claimedFlag:setVisible(true)
        item._claimedFlag._label:setVisible(false)
    elseif bonus._value < bonus._info._val then
        item._button._label:setString(Str(STR.CAPTURE))
    end

    item._button:setPositionY(64)
    item._button:setEnabled(self:isLastTeachPass(teachInfo))
    item._button:setVisible(true)

    return item
end

function _M:dealTeachTask(teachInfo, bonus)
    if bonus._value >= bonus._info._val and not bonus._isClaimed then
        local result = ClientData.claimBonus(bonus)
        self:refreshList()
        V.showClaimBonusResult(bonus, result)
        return
    end

    local input = ClientData.genInputFromUnitTest()
    input._ygo = teachInfo._id
    input._battleType = Data.BattleType.teach
    input._conditionIds = teachInfo._condition
    input._conditionValues = teachInfo._value
    input._teachingId = teachInfo._id

    lc.replaceScene(require("ResSwitchScene").create(lc._runningScene._sceneId, ClientData.SceneId.battle, input))
        
    self:hide(true)
end

function _M:isLastTeachPass(teachInfo)
    local lastId = teachInfo._passId[1]
    if lastId == 0 then return true end

    local lastTrainInfo = Data._teachInfo[lastId]
    local bonus = P._playerBonus._bonusTeach[lastTrainInfo._bonusId]
    return bonus._value >= bonus._info._val
end

function _M:updateButtonFlags()
    local items = self._tabArea._list:getItems()
    for i = 1, #items do
        local item = items[i]
        if item._index < 10 then
            local number = ClientData.getUnpassTeachCount(item._index)
            local flagBg = V.checkNewFlag(self._tabArea._list:getItems()[i], number, -20, -4)
            if flagBg ~= nil then flagBg:setSpriteFrame('img_new_g') end
        else
            local number = ClientData.getUnpassTeachCount(math.floor(item._index / 10), item._index % 10)
            local flagBg = V.checkNewFlag(self._tabArea._list:getItems()[i], number, -10, -4)
            if flagBg ~= nil then flagBg:setSpriteFrame('img_new_g') end
        end
    end
end


return _M