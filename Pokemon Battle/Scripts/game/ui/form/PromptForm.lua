local Base = class("PromptForm", BaseForm)

local BUTTON_W = 160
local BUTTON_Y = 90

function Base:init(size, title)
    Base.super.init(self, size, title, 0)

    self._hideBg = true
    self._btnBack:setVisible(false)
end

function Base:addButton(name, label, x, y, callback)
    local btn = V.createScale9ShaderButton(name, callback, string.sub(name, #name - 1, #name) == '_s' and V.CRECT_BUTTON_S or V.CRECT_BUTTON, BUTTON_W)
    btn:addLabel(label)
    lc.addChildToPos(self._form, btn, cc.p(x, y or BUTTON_Y))
    return btn
end

-----------------------------------------------------------------------------------------------------------------

local ConfirmSweep = class(nil, Base)
Base.ConfirmSweep = ConfirmSweep

function ConfirmSweep.create(sweepTimes, callback)
    local form = ConfirmSweep.new(lc.EXTEND_LAYOUT_MASK)    
    form:init(cc.size(600, 360), Str(STR.NOT_ENOUGH_SWEEP_CARD), sweepTimes, callback)
    return form
end

function ConfirmSweep:init(size, title, sweepTimes, callback)
    ConfirmSweep.super.init(self, size, title)

    self._callback = callback

    local ingotNeed = (sweepTimes - P._propBag._props[Data.PropsId.sweep_card]._num) * 2
    self._ingotNeed = ingotNeed

    local form, x = self._form, lc.w(self._form) / 2

    local text = V.createBoldRichText(string.format(Str(STR.CONFIRM_SWEEP_INGOT), ingotNeed), V.RICHTEXT_PARAM_LIGHT_S1, 400)
    lc.addChildToPos(form, text, cc.p(x, lc.bottom(self._titleFrame) - 30 - lc.h(text) / 2))
    
    self:addButton("img_btn_2", Str(STR.CANCEL), x - BUTTON_W / 2 - 10, nil, function() self:hide() end)

    local sweepArea = V.createResConsumeButtonArea(BUTTON_W, "img_icon_res3_s", V.COLOR_RES_LABEL_BG_LIGHT, tostring(ingotNeed), string.format(Str(STR.CONTINUE_DO), Str(STR.SWEEP)))
    sweepArea._btn._callback = function() self:onButtonTap("ok") end
    lc.addChildToPos(form, sweepArea, cc.p(x + BUTTON_W / 2 + 10, BUTTON_Y + (lc.h(sweepArea) - lc.h(sweepArea._btn)) / 2))

    if P._ingot < ingotNeed then
        sweepArea._resLabel:setColor(lc.Color3B.red)
    end
end

function ConfirmSweep:onButtonTap(name)
    if name == "ok" then
        if V.checkIngot(self._ingotNeed) then
            self._callback()
            self:hide()
        end
    end
end

-----------------------------------------------------------------------------------------------------------------

local ConfirmBuyIngot = class(nil, Base)
Base.ConfirmBuyIngot = ConfirmBuyIngot

function ConfirmBuyIngot.create()
    local form = ConfirmBuyIngot.new(lc.EXTEND_LAYOUT_MASK)    
    form:init(cc.size(560, 320), Str(STR.NOT_ENOUGH_INGOT))
    return form
end

function ConfirmBuyIngot:init(size, title)
    ConfirmBuyIngot.super.init(self, size, title)

    local x = lc.w(self._form) / 2

    local text = V.createTTF(Str(STR.SURE_TO_RECHARGE), V.FontSize.S1, V.COLOR_TEXT_LIGHT, cc.size(360, 0))
    lc.addChildToPos(self._form, text, cc.p(x, lc.bottom(self._titleFrame) - 30 - lc.h(text) / 2))

    if ClientData.isHideCharge() then
        self:addButton("img_btn_2_s", Str(STR.CANCEL), x, nil, function() self:hide() end)
    else
        x = x + BUTTON_W / 2 + 10
        lc.addChildToPos(self._form, V.createChargeButton(BUTTON_W, self), cc.p(x, BUTTON_Y))
        self:addButton("img_btn_2_s", Str(STR.CANCEL), x - BUTTON_W - 20, nil, function() self:hide() end)
    end
end

-----------------------------------------------------------------------------------------------------------------

local ConfirmBuyFund = class(nil, Base)
Base.ConfirmBuyFund = ConfirmBuyFund

function ConfirmBuyFund.create(callback)
    local form = ConfirmBuyFund.new(lc.EXTEND_LAYOUT_MASK)    
    form:init(cc.size(640, 480), Str(STR.BUY)..ClientData.getNameByInfoId(Data.PropsId.union_fund), callback)
    return form
end

function ConfirmBuyFund:init(size, title, callback)
    ConfirmBuyFund.super.init(self, size, title)

    local x = lc.w(self._form) / 2

    local icon = IconWidget.create({_infoId = Data.PropsId.union_fund, _count = 1})
    icon._name:setColor(lc.Color3B.white)
    lc.addChildToPos(self._form, icon, cc.p(x, lc.bottom(self._titleFrame) - 24 - lc.h(icon) / 2))

    local text = V.createBoldRichText(string.format(Str(STR.SURE_TO_BUY_UNION_FUND), ClientData.getNameByInfoId(Data.PropsId.union_fund)), V.RICHTEXT_PARAM_LIGHT_S1, 500)
    lc.addChildToPos(self._form, text, cc.p(x, lc.bottom(icon) - 20 - lc.h(text) / 2))

    self:addButton("img_btn_3", Str(STR.BUY), x + BUTTON_W / 2 + 16, nil, function() self:hide() callback() end)
    self:addButton("img_btn_2_s", Str(STR.CANCEL), x - BUTTON_W / 2 - 16, nil, function() self:hide() end)
end

-----------------------------------------------------------------------------------------------------------------

local ConfirmEditUnion = class(nil, Base)
Base.ConfirmEditUnion = ConfirmEditUnion

function ConfirmEditUnion.create(isNameChanged, isFlagChanged, callback)
    local form = ConfirmEditUnion.new(lc.EXTEND_LAYOUT_MASK)
    form:init(cc.size(560, 340), isNameChanged, isFlagChanged, callback)
    return form
end

function ConfirmEditUnion:init(size, isNameChanged, isFlagChanged, callback)
    ConfirmEditUnion.super.init(self, size)

    local x = lc.w(self._form) / 2

    local needIngot = 0
    if isNameChanged then
        local ingot = Data._globalInfo._editUnionNameIngot
        local key = V.createKeyValueLabel(Str(STR.CHANGE)..Str(STR.UNION_NAME)..Str(STR.CONSUME), ingot, V.FontSize.S1, false, "img_icon_res3_s")
        key:addToParent(self._form, cc.p(120, lc.h(self._form) - 110))
        needIngot = needIngot + ingot
        self._nameKey = key
    end

    if isFlagChanged then
        local ingot = Data._globalInfo._editUnionTagIngot
        local key = V.createKeyValueLabel(Str(STR.CHANGE)..Str(STR.UNION_BADGE)..Str(STR.CONSUME), ingot, V.FontSize.S1, false, "img_icon_res3_s")
        if isNameChanged then
            self._nameKey:setPosition(lc.x(self._nameKey), lc.h(self._form) - 80)
            key:addToParent(self._form, cc.p(120, lc.h(self._form) - 130))
        else
            key:addToParent(self._form, cc.p(120, lc.h(self._form) - 110))
        end

        needIngot = needIngot + ingot
    end

    self:addButton("img_btn_2_s", Str(STR.CANCEL), x - BUTTON_W + 40, nil, function() self:hide() end)

    local changeArea = V.createResConsumeButtonArea(BUTTON_W, "img_icon_res3_s", V.COLOR_RES_LABEL_BG_LIGHT, tostring(needIngot), Str(STR.CHANGE))
    changeArea._btn._callback = function()
        if callback then callback() end
        self:hide()
    end
    lc.addChildToPos(self._form, changeArea, cc.p(x + BUTTON_W - 40, BUTTON_Y + (lc.h(changeArea) - lc.h(changeArea._btn)) / 2))

    if P._ingot < needIngot then
        changeArea._resLabel:setColor(lc.Color3B.red)
    end
end

-----------------------------------------------------------------------------------------------------------------

local ConfirmBuyProduct = class(nil, Base)
Base.ConfirmBuyProduct = ConfirmBuyProduct

function ConfirmBuyProduct.create(product, callback)
    local form = ConfirmBuyProduct.new(lc.EXTEND_LAYOUT_MASK)
    form:init(cc.size(560, 400), product, callback)
    form._hideBg = false
    return form
end

function ConfirmBuyProduct:init(size, product, callback)
    ConfirmBuyProduct.super.init(self, size)

    local form, x = self._form, lc.w(self._form) / 2

    local leftIcon = IconWidget.create({_infoId = product._resType, _count = product._cost, _isFragment = product._costFragment}, IconWidget.DisplayFlag.ITEM)
    local rightIcon = IconWidget.create(product, IconWidget.DisplayFlag.ITEM)
    leftIcon._name:setColor(lc.Color3B.white)
    rightIcon._name:setColor(lc.Color3B.white)
    
    local arrow = lc.createSprite("img_arrow_right")
    arrow:setColor(V.COLOR_TEXT_GREEN)
    lc.addChildToPos(form, arrow, cc.p(x, lc.h(form) - 130))
    lc.addChildToPos(form, leftIcon, cc.p(x - 100, lc.y(arrow) - 10))
    lc.addChildToPos(form, rightIcon, cc.p(x + 100, lc.y(leftIcon)))

    local tip = V.createTTF(Str(STR.SURE_TO_BUY), V.FontSize.S1, V.COLOR_TEXT_LIGHT)
    lc.addChildToPos(form, tip, cc.p(x, lc.bottom(leftIcon) - 40))

    self:addButton("img_btn_2_s", Str(STR.CANCEL), x - BUTTON_W + 40, nil, function() self:hide() end)
    self:addButton("img_btn_1_s", Str(STR.BUY), x + BUTTON_W - 40, nil, function()
        if callback then callback() end
        self:hide()
    end)
end

-----------------------------------------------------------------------------------------------------------------

local ConfirmMix = class(nil, Base)
Base.ConfirmMix = ConfirmMix

local SelectCountWidget = require("SelectCountWidget")

function ConfirmMix.create(data, isCommonFirst, callback, isMultiCount)
    local form = ConfirmMix.new(lc.EXTEND_LAYOUT_MASK)
    form:init(data, isCommonFirst, callback, isMultiCount)
    form._hideBg = false
    return form
end

function ConfirmMix:init(data, isCommonFirst, callback, isMultiCount)
    local size = isMultiCount and cc.size(600, 440 + SelectCountWidget.HEIGHT) or cc.size(560, 420)

    ConfirmMix.super.init(self, size)

    local form, x = self._form, lc.w(self._form) / 2
    self._data = data

    local icon = IconWidget.create(data, IconWidget.DisplayFlag.ITEM)
    lc.addChildToPos(form, icon, cc.p(x, lc.h(form) - 130))

    local countWidget
    if isMultiCount then
        countWidget = SelectCountWidget.create(nil, 100)
        lc.addChildToPos(form, countWidget, cc.p(x, lc.bottom(icon) - 10 - countWidget.HEIGHT / 2))
    end

    local tip = V.createTTF(Str(STR.MIX_COST), V.FontSize.S1, V.COLOR_LABEL_DARK)
    lc.addChildToPos(form, tip, cc.p(x, lc.bottom(countWidget or icon) - 40))

    local fragNum, comFragNum, comFragId = self:getMixCost(isCommonFirst, 1)
    local fragArea, comFragArea
    if fragNum > 0 then
        fragArea = V.createResIconLabel(120, "card_fragment")        
        fragArea._ico:setScale(0.5)
        fragArea._label:setString(fragNum)
        lc.addChildToPos(form, fragArea, cc.p(x - (comFragNum > 0 and lc.w(fragArea) / 2 + 4 or -10), lc.bottom(tip) - 30))
    end

    if comFragNum > 0 then
        comFragArea = V.createResIconLabel(120, string.format("img_icon_%d", comFragId))
        comFragArea._label:setString(comFragNum)
        lc.addChildToPos(form, comFragArea, cc.p(x + (fragNum > 0 and lc.w(comFragArea) / 2 + 24 or 10), lc.bottom(tip) - 30))
    end

    if countWidget then
        countWidget._callback = function(count)
            local fragNum, comFragNum, comFragId = self:getMixCost(isCommonFirst, count)
            if fragArea then
                fragArea._label:setString(fragNum)

                self._needMoreFrag = (fragNum > P._playerCard:getFragmentNum(data._infoId))
                fragArea._label:setColor(self._needMoreFrag and lc.Color3B.red or lc.Color3B.white)
            end

            if comFragArea then
                comFragArea._label:setString(comFragNum)

                self._needMoreComFrag = (comFragNum > P:getItemCount(comFragId))
                comFragArea._label:setColor(self._needMoreComFrag and lc.Color3B.red or lc.Color3B.white)
            end
        end
    end

    self:addButton("img_btn_2_s", Str(STR.CANCEL), x - BUTTON_W + 40, nil, function() self:hide() end)
    self:addButton("img_btn_1_s", Str(STR.COMPOSE), x + BUTTON_W - 40, nil, function()
        if self._needMoreFrag or self._needMoreComFrag then
            ToastManager.push(Str(STR.NEED_FRAGMENTS_MIX))
            return
        end

        if callback then callback(countWidget and countWidget:getCount() or 1) end
        self:hide()
    end)
end

function ConfirmMix:getMixCost(isCommonFirst, count)
    local data = self._data

    local fragNum, comFragNum, comFragId = 0, 0
    local fragNeed = data._info._fragmentCount * count
    if isCommonFirst then
        if comFragNum > fragNeed then
            comFragNum = fragNeed
        end
        fragNum = fragNeed - comFragNum
    else
        if fragNum > fragNeed then
            fragNum = fragNeed
        end
        comFragNum = fragNeed - fragNum
    end

    return fragNum, comFragNum, comFragId
end



-----------------------------------------------------------------------------------------------------------------

local ConfirmInvited = class(nil, Base)
Base.ConfirmInvited = ConfirmInvited

function ConfirmInvited.create(user, callback)
    local form = ConfirmInvited.new(lc.EXTEND_LAYOUT_MASK)
    form:init(cc.size(600, 420), user, callback)
    form._hideBg = false
    return form
end

function ConfirmInvited:init(size, user, callback)
    ConfirmBuyProduct.super.init(self, size)

    local form, x = self._form, lc.w(self._form) / 2

    local tip = V.createBoldRichText(Str(STR.INVITED_CONFIRM), V.RICHTEXT_PARAM_LIGHT_S1, 440)
    lc.addChildToPos(form, tip, cc.p(x, lc.h(form) - Base.FRAME_THICK_TOP - 40 - lc.h(tip) / 2))

    local userWidget = UserWidget.create(user, UserWidget.Flag.REGION_NAME_UNION)
    lc.addChildToPos(form, userWidget, cc.p(x, lc.bottom(tip) - 40 - lc.h(userWidget) / 2))
    userWidget._regionArea:setColor(lc.Color3B.white)

    self:addButton("img_btn_2_s", Str(STR.CANCEL), x - BUTTON_W + 40, nil, function() self:hide() end)
    self:addButton("img_btn_1_s", Str(STR.OK), x + BUTTON_W - 40, nil, function()
        if callback then callback() end
        self:hide()
    end)
end




-----------------------------------------------------------------------------------------------------------------

local SelectRecruitFrag = class(nil, Base)
Base.SelectRecruitFrag = SelectRecruitFrag

function SelectRecruitFrag.create(infoId, callback)
    local form = SelectRecruitFrag.new(lc.EXTEND_LAYOUT_MASK)
    form:init(cc.size(600, 480), infoId, callback)
    form._hideBg = false
    return form
end

function SelectRecruitFrag:init(size, infoId, callback)
    ConfirmBuyProduct.super.init(self, size)

    local form, x = self._form, lc.w(self._form) / 2

    local tip = V.createBoldRichText(Str(STR.LOTTERY_FRAGMENT_TIP), V.RICHTEXT_PARAM_DARK_S1, 440)
    lc.addChildToPos(form, tip, cc.p(x, lc.h(form) - Base.FRAME_THICK_TOP - 40 - lc.h(tip) / 2))

    local infoIds, icons = {1019, 1041, 1294}, {}
    for _, id in ipairs(infoIds) do
        local icon = IconWidget.create({_infoId = id, _isFragment = true}, IconWidget.DisplayFlag.ITEM)
        table.insert(icons, icon)
    end

    lc.addNodesToCenterH(form, icons, 50, lc.bottom(tip) - IconWidget.SIZE)

    for _, icon in ipairs(icons) do
        local isSel = (icon._data._infoId == infoId)
        if isSel then
            self._selectedIcon = icon
        end

        local sel = V.createCheckLabelArea("", function(isCheck)
            if isCheck then
                if self._selectedIcon then
                    self._selectedIcon._selector:setCheck(false)
                end
                self._selectedIcon = icon
            else
                if self._selectedIcon == icon then
                    self._selectedIcon = nil
                end
            end
        end, isSel)
        lc.addChildToPos(form, sel, cc.p(lc.x(icon), lc.bottom(icon) - 32))

        icon._selector = sel
    end

    self:addButton("img_btn_2_s", Str(STR.CANCEL), x - BUTTON_W + 40, nil, function() self:hide() end)
    self:addButton("img_btn_1_s", Str(STR.OK), x + BUTTON_W - 40, nil, function()
        if callback then callback(self._selectedIcon) end
        self:hide()
    end)
end

-----------------------------------------------------------------------------------------------------------------
 
local ConfirmRematch = class(nil, Base)
Base.ConfirmRematch = ConfirmRematch

function ConfirmRematch.create(matchType)
    local form = ConfirmRematch.new(lc.EXTEND_LAYOUT_MASK)
    form:init(matchType)
    form._hideBg = false
    return form
end

function ConfirmRematch:init(matchType)
    ConfirmRematch.super.init(self, cc.size(700, 360), Str(STR.FIND_MATCH_NONE_TITLE))

    local form, x = self._form, lc.w(self._form) / 2

    -- Do not close the form, remove old listeners and add a empty listener
    self:addTouchEventListener(function() end)
    self._btnBack:setVisible(false)

    local tip = V.createBoldRichText(Str(STR.FIND_MATCH_NONE), V.RICHTEXT_PARAM_LIGHT_S1, 550)
    lc.addChildToPos(form, tip, cc.p(x, lc.h(form) - Base.FRAME_THICK_TOP - 40 - lc.h(tip) / 2))

    if matchType == Data.FindMatchType.clash then
        local grade = P._playerFindClash._grade
        --[[
        if grade >= Data.FindClashGrade.lengend then    
            local noticeStr = string.format(Str(STR.FIND_MATCH_NPC_TROPHY), Str(Data._ladderInfo[grade]._nameSid))
            local notice = V.createBoldRichText(noticeStr, {_normalClr = V.COLOR_TEXT_RED_DARK, _boldClr = V.COLOR_TEXT_BLUE_DARK, _fontSize = V.FontSize.S2, _width = 500})
            lc.addChildToPos(form, notice, cc.p(x, lc.bottom(tip) - 20 - lc.h(notice) / 2))
        end
        ]]

        self:addButton("img_btn_2_s", Str(STR.CANCEL), x - BUTTON_W / 2 - 20, BUTTON_Y + 80, function()
            ClientData.sendWorldFindExCancel()
            self:hide()
        end)

        self:addButton("img_btn_1_s", Str(STR.FIND_REMATCH), x + BUTTON_W / 2 + 20, BUTTON_Y + 80, function()
            lc.sendEvent(Data.Event.rematch_again)
            self:hide()
        end)

        if ConfirmRematch._troopIndex == nil then
            self._troopDirty = true
        end
        self._preTroopIndex = P._curTroopIndex

        self._btnTroop = self:addButton("img_btn_2", "", x - BUTTON_W / 2 - 20, nil, function()
            self._troopDirty = true
            lc.pushScene(require("HeroCenterScene").create(ConfirmRematch._troopIndex))
        end)

        self:addButton("img_btn_1_s", Str(STR.FIND_MATCH_NPC), x + BUTTON_W / 2 + 20, nil, function()
            lc.sendEvent(Data.Event.rematch_npc)
            self:hide()
        end)
    else
        local notice = V.createBoldRichText(Str(STR.FIND_MATCH_NPC_MELEE), {_normalClr = V.COLOR_TEXT_RED_DARK, _boldClr = V.COLOR_TEXT_BLUE_DARK, _fontSize = V.FontSize.S2, _width = 500})
        lc.addChildToPos(form, notice, cc.p(x, lc.bottom(tip) - 20 - lc.h(notice) / 2))

        self:addButton("img_btn_2_s", Str(STR.CANCEL), x - BUTTON_W - 20, nil, function()
            ClientData.sendWorldFindExCancel()
            self:hide()
        end)

        self:addButton("img_btn_1_s", Str(STR.FIND_REMATCH), x, nil, function()
            lc.sendEvent(Data.Event.rematch_again)
            self:hide()
        end)
        self:addButton("img_btn_1_s", Str(STR.FIND_MATCH_NPC), x + BUTTON_W + 20, nil, function()
            lc.sendEvent(Data.Event.rematch_npc)
            self:hide()
        end)
    end
end

function ConfirmRematch:onEnter()
    ConfirmRematch.super.onEnter(self)

    if self._troopDirty then
        ConfirmRematch._troopIndex = P._curTroopIndex
        self._troopDirty = false
    end

    if self._btnTroop then
        self._btnTroop._label:setString(string.format("%s %d", Str(STR.TROOP), ConfirmRematch._troopIndex))
    end
end

function ConfirmRematch:hide()
    if self._preTroopIndex then
        P:setCurrentTroopIndex(self._preTroopIndex)
    end

    lc.sendEvent(Data.Event.rematch_hide)

    ConfirmRematch.super.hide(self)
end

-----------------------------------------------------------------------------------------------------------------


local ConfirmCompose = class(nil, Base)
Base.ConfirmCompose = ConfirmCompose

function ConfirmCompose.create(targetCard, selectedCards, callback)
    local form = ConfirmCompose.new(lc.EXTEND_LAYOUT_MASK)
    form:init(cc.size(700, 520), targetCard, selectedCards, callback)
    form._hideBg = false
    return form
end

function ConfirmCompose:init(size, targetCard, selectedCards, callback)
    ConfirmCompose.super.init(self, size)

    local form, x = self._form, lc.w(self._form) / 2

    local tip = V.createBoldRichText(Str(STR.COMPOSE_WARN), V.RICHTEXT_PARAM_LIGHT_S1, 540)
    lc.addChildToPos(form, tip, cc.p(x, lc.h(form) - Base.FRAME_THICK_TOP - 40 - lc.h(tip) / 2))

    local w = 120
    local cardsPos =
    {
        cc.p(Base.FRAME_THICK_LEFT+20+ 0.5*w , lc.bottom(tip)-10-0.5*w),
        cc.p(Base.FRAME_THICK_LEFT+20+1.5*w , lc.bottom(tip)-10-0.5*w),
        cc.p(Base.FRAME_THICK_LEFT+20+2.5*w , lc.bottom(tip)-10-0.5*w),
        cc.p(Base.FRAME_THICK_LEFT+20+ 0.5*w , lc.bottom(tip)-10-1.5*w),
        cc.p(Base.FRAME_THICK_LEFT+20+1.5*w , lc.bottom(tip)-10-1.5*w),
        cc.p(Base.FRAME_THICK_LEFT+20+2.5*w , lc.bottom(tip)-10-1.5*w),
    }

    local index=1
    for k,v in pairs(selectedCards) do
        for i=1,v do
            local icon = IconWidget.createByInfoId(k)
            icon:setScale(w/lc.w(icon) , w/lc.h(icon))
            lc.addChildToPos(form, icon, cardsPos[index])
            index = index+1
        end
    end

    local arrow = lc.createSprite("img_arrow_right_02")
    lc.addChildToPos(form, arrow, cc.p(Base.FRAME_THICK_LEFT+35+3*w+lc.cw(arrow), lc.bottom(tip)-10-w))

    local widget = V.createShaderButton(nil, function(sender) require("CardInfoPanel").create(targetCard, 1):show() end)
    widget:setContentSize(cc.size(210*0.7, 300*0.7))
    widget:setAnchorPoint(cc.p(0.5, 0.5))
    lc.addChildToPos(form, widget, cc.p(lc.right(arrow)+20+lc.cw(widget), lc.bottom(tip)-5-w))
    
    local cardSprite = require("CardThumbnail").create(targetCard, 0.7)
    lc.addChildToCenter(widget, cardSprite)

    self:addButton("img_btn_2_s", Str(STR.CANCEL), x - BUTTON_W + 40, nil, function() self:hide() end)
    self:addButton("img_btn_1_s", Str(STR.OK), x + BUTTON_W - 40, nil, function()
        if callback then callback() end
        self:hide()
    end)
end

-----------------------------------------------------------------------------------------------------------------
return Base