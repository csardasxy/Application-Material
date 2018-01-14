local _M = class("UnionContribute", BaseForm)

local FORM_SIZE = cc.size(750, 600)
local ITEM_SIZE = cc.size(650, 130)

local RES_TYPES = {-1, Data.ResType.gold, Data.ResType.ingot}

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:setLocalZOrder(99)
    panel:init(resType)
    return panel
end

function _M:init()    
    _M.super.init(self, FORM_SIZE, Str(STR.UNION_CONTRIBUTION), bor(BaseForm.FLAG.ADVANCE_TITLE_BG))

    self._isShowResourceUI = true
    

    local form = self._form
    lc.offset(form, 0, -20)

    self:initTopArea()

    local formBg = lc.createSprite({_name = "img_troop_bg_2", _crect = cc.rect(20, 15, 1, 1), _size = cc.size(lc.w(self._form) - 40, lc.bottom(self._topArea) - 10)})
    lc.addChildToPos(self._form, formBg, cc.p(lc.cw(self._form), lc.bottom(self._topArea) - lc.ch(formBg) + 15))
    -- Create contribute items
    local y = lc.bottom(self._topArea) - ITEM_SIZE.height / 2 - 6
    self._acts, self._woods = {}, {}
    for i = 1, 6 do
        local item, pos = self:createItem(i), cc.p(0, y)
        if i % 2 == 1 then
            pos.x = lc.w(form) / 2 - ITEM_SIZE.width / 2
            table.insert(self._acts, item)
--        else
--            pos.x = lc.w(form) / 2 + ITEM_SIZE.width / 2
--            y = y - ITEM_SIZE.height
--            table.insert(self._woods, item)
        end
        if item then
            pos.x = lc.cw(form)
             y = y - ITEM_SIZE.height - 10
            lc.addChildToPos(form, item, pos)
        end
    end
end

function _M:initTopArea()
    local topBg = lc.createNode()
    topBg:setContentSize(cc.size(lc.w(self._form) - 40, 110))
    lc.addChildToPos(self._frame, topBg, cc.p(lc.w(self._form) / 2, lc.h(self._form) - _M.FRAME_THICK_TOP - lc.h(topBg) / 2), -1)
    self._topArea = topBg

    local margin = 32

--    local remainTimes = V.createKeyValueLabel(Str(STR.REMAIN_TIMES), "", V.FontSize.S1, false)
--    remainTimes:addToParent(topBg, cc.p(margin, margin + lc.h(remainTimes) / 2))
--    self._remainTimes = remainTimes._value
--    self:updateRemainTimes()

--    self._act = V.addUnionContribution(topBg, Str(STR.TODAY)..Str(STR.CONTRIBUTE), V.FontSize.S1, 230, margin)
    local actPanel = lc.createSprite("img_com_bg_58")
    lc.addChildToPos(topBg, actPanel, cc.p(550, 40))
    local actIcon = lc.createSprite("img_icon_res13_s")
    lc.addChildToPos(actPanel, actIcon, cc.p(0, lc.ch(actPanel)))
    local actLabel = V.createTTFStroke(Str(STR.UNION)..Str(STR.CONTRIBUTE)..Str(STR.COLON), V.FontSize.S1)
    actLabel:setAnchorPoint(1, 0.5)
    lc.addChildToPos(actPanel, actLabel, cc.p(-27, lc.ch(actPanel)))
    self._act = V.createTTFStroke("", V.FontSize.S1)
    self._act:setAnchorPoint(cc.p(0, 0.5))
    lc.addChildToPos(topBg, self._act, cc.p(520, 40))
    self:updateContribution()
end

function _M:createItem(index)
    if index%2 == 0 then return end
    local item = lc.createSprite({_name = "img_troop_bg_6", _crect = V.CRECT_TROOP_BG, _size = ITEM_SIZE})
    local unionResType, unionResNum, resType, resNum, rewardNum, id
    if index % 2 == 1 then
        id = (index + 1) / 2
        unionResType = Data.ResType.union_act
        unionResNum = Data._globalInfo._unionDonateExp[id]
        resNum = Data._globalInfo._donateCost[id]
        rewardNum = Data._globalInfo._donateGetUnionCrystal[id]
        if id==3 then
            resNum = resNum+P._dailyIngotDonate*Data._globalInfo._donateIngotCostIncremental
        end
    else
        id = index / 2
        unionResType = Data.ResType.union_wood
        unionResNum = Data._globalInfo._unionDonateWood[id]
        resNum = Data._globalInfo._donateWoodCost[id]
        rewardNum = Data._globalInfo._donateWoodGain[id]
    end

    resType = RES_TYPES[id]

    if P._playerActivity._actContributeYubi2x then
        rewardNum = rewardNum * 2
    end

    local unionResIcon = IconWidget.create({_infoId = unionResType, _count = unionResNum}, IconWidget.DisplayFlag.ITEM)
    unionResIcon:setScale(0.8)
    lc.addChildToPos(item, unionResIcon, cc.p(86, ITEM_SIZE.height / 2 + 2))
    unionResIcon._name:setColor(V.COLOR_TEXT_WHITE)

--    local reward = V.createKeyValueLabel(Str(STR.CONTRIBUTE)..Str(STR.BONUS), rewardNum, V.FontSize.S1, false, ClientData.getPropIconName(7024))
--    reward:setColor(V.COLOR_TEXT_DARK)
--    reward:addToParent(item, cc.p(ITEM_SIZE.width - 46 - reward:getTotalWidth(), ITEM_SIZE.height - reward:getTotalHeight()))

    local reward =  IconWidget.create({_infoId = Data.PropsId.yubi, _count = rewardNum}, IconWidget.DisplayFlag.ITEM)
    reward:setScale(0.8)
    lc.addChildToPos(item, reward, cc.p(lc.right(unionResIcon) + lc.cw(reward) + 30, ITEM_SIZE.height / 2 + 2))
    reward._name:setColor(V.COLOR_TEXT_WHITE)

    local icoName
    if resType >= 0 then
        icoName = string.format("img_icon_res%d_s", resType)
    end

--    local btn = V.createResConsumeButtonArea({120, 110}, icoName, nil, resNum, Str(STR.CONTRIBUTE))
--    btn._btn._callback = function() self:contribute(id, unionResType, true) end

    local str = "img_btn_1_s"
    local btn = V.createResConsumeButton(200, 80, icoName, resNum, Str(STR.CONTRIBUTE), str)
    btn._resNum = resNum
    lc.addChildToPos(item, btn, cc.p(ITEM_SIZE.width - 40 - lc.w(btn) / 2, lc.ch(item)))
    btn:setDisabledShader(V.SHADER_DISABLE)
    if index ~= 3 then
        btn:setEnabled(P._dailyDonate < Data._globalInfo._dailyDonateCount)
    else
        btn:setEnabled(P._dailyIngotDonate < Data._globalInfo._ingotDonateUpLimit)
    end
    lc.offset(btn._resLabel, 4)
    btn._resLabel:setColor((resType == -1 or P:hasResource(resType, resNum)) and V.COLOR_TEXT_WHITE or V.COLOR_TEXT_RED)
    btn._callback = function() self:contribute(id, unionResType, true) end
    if icoName == nil then btn._resLabel:setString(Str(STR.FREE)) end
    item._btn = btn

    item._unionResType, item._unionResNum, item._resType, item._resNum, item._rewardNum = unionResType, unionResNum, resType, resNum, rewardNum
    return item
end

--function _M:updateRemainTimes()
--    local dailyTimes = Data._globalInfo._dailyDonateCount
--    self._remainTimes:setString(string.format("%d/%d", dailyTimes - P._dailyDonate, dailyTimes))
--end

function _M:updateContribution()
    local union = P._playerUnion:getMyUnion()
    local daily = union:getContribution(P._id)
    self._act:setString(daily[Data.ResType.union_act])
    if self._acts and #self._acts==3 then
        local IgnotItem = self._acts[3]
        local label = IgnotItem._btn._resLabel
        local resNum = Data._globalInfo._donateCost[3] + P._dailyIngotDonate * Data._globalInfo._donateIngotCostIncremental
        IgnotItem._resNum = resNum
        label:setString(resNum)

        for i = 1, 3 do
            local item = self._acts[i]
            local btn = item._btn
            local label = btn._resLabel
            if i ~= 3 then
                btn:setEnabled(P._dailyDonate < Data._globalInfo._dailyDonateCount)
            else
                btn:setEnabled(P._dailyIngotDonate < Data._globalInfo._ingotDonateUpLimit)
            end
            label:setColor((item._resType == -1 or P:hasResource(item._resType, item._resNum)) and V.COLOR_TEXT_WHITE or V.COLOR_TEXT_RED)
        end
        
    end
--    self._wood:setString(daily[Data.ResType.union_wood])
end

function _M:contribute(id, unionResType, isCheckMax)
--    if P._dailyDonate >= Data._globalInfo._dailyDonateCount then
    if (P._dailyDonate >= Data._globalInfo._dailyDonateCount and id ~= 3) or (P._dailyIngotDonate >= Data._globalInfo._ingotDonateUpLimit and id == 3) then
        ToastManager.push(Str(STR.CANNOT_UNION_CONTRIBUTE))
        return
    end

    local item = (unionResType == Data.ResType.union_act and self._acts[id] or self._woods[id])
    if item._resType == Data.ResType.ingot then
        if not V.checkIngot(item._resNum) then
            return
        end
    elseif item._resType == Data.ResType.gold then
        if not V.checkGold(item._resNum) then
            return
        end
    end

    if isCheckMax and P._playerUnion:isReachMaxResource(unionResType, item._unionResNum) then
        local resName = (unionResType == Data.ResType.union_act and Str(STR.UNION_EXP) or Str(STR.UNION_WOOD))
        require("Dialog").showDialog(string.format(Str(STR.UNION_RES_REACH_MAX_TIP), resName), function()
            self:contribute(id, unionResType)
        end)
        return
    end
    
    -- Union resource change
    local union = P._playerUnion:getMyUnion()
    union:contribute(P._id, unionResType, item._unionResNum)
    P._playerUnion:changeResource(unionResType, item._unionResNum)

    -- self resource change
    if id == 3 then
        P._dailyIngotDonate = P._dailyIngotDonate + 1
    else
        P._dailyDonate = P._dailyDonate + 1
    end

    P:changeResource(item._resType, -item._resNum)
    P._propBag:changeProps(Data.PropsId.yubi, item._rewardNum)

    ClientData.sendUnionContribute(id, unionResType)
    
--    self:updateRemainTimes()
    self:updateContribution()

    local data = {}
    table.insert(data, {_infoId = item._unionResType, _count = item._unionResNum, _isFragment = false, _level = 1})
    table.insert(data, {_infoId = Data.PropsId.yubi, _count = item._rewardNum, _isFragment = false, _level = 1})
    local RewardPanel = require("RewardPanel")
    RewardPanel.create(data, RewardPanel.MODE_UNION_CONTRIBUTE):show()
    lc.Audio.playAudio(AUDIO.E_CLAIM)

--    V.showResChangeText(item, Data.PropsId.yubi, item._rewardNum)
end

function _M:onEnter()
    _M.super.onEnter(self)
    self:updateContribution()
    
    self._listeners = {}
    table.insert(self._listeners, lc.addEventListener(Data.Event.gold_dirty, function (event) self:updateContribution() end))
    table.insert(self._listeners, lc.addEventListener(Data.Event.ingot_dirty, function (event) self:updateContribution() end))
end

function _M:onExit()
    _M.super.onExit(self)

    for _, listener in ipairs(self._listeners) do
        lc.Dispatcher:removeEventListener(listener)
    end
end

function _M:onCleanup()
    _M.super.onCleanup(self)

    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/union_contribute.jpg"))
end

return _M