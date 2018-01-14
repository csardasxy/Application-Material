local _M = class("VIPInfoForm", BaseForm)

local FORM_SIZE = cc.size(980, 648)

local vipMax = function()
    if P._vip <= 8 then return 9
    elseif P._vip == 9 then return 10
    else return #Data._globalInfo._vipIngot - 2
    end
end

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()        
    
    return panel
end

function _M:init()
    _M.super.init(self, FORM_SIZE, "VIP"..Str(STR.PRIVILEGE))

    -- init ui
    local title = cc.Label:createWithTTF("", V.TTF_FONT, V.FontSize.M1)
    title:setColor(V.COLOR_TEXT_TITLE)
    lc.addChildToPos(self._frame, title, cc.p(lc.cw(self._frame), lc.h(self._frame) - 80))
    self._titleLabel = title

    local vipArea = lc.createNode(cc.size(lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, lc.h(self._frame) - V.FRAME_INNER_TOP - V.FRAME_INNER_BOTTOM))
    lc.addChildToPos(self._frame, vipArea, cc.p(lc.cw(self._frame), lc.ch(self._frame) - 60))

    local areaW = lc.w(vipArea)
    local areaH = lc.h(vipArea)

    -- Create arrow buttons
    local btnW, btnH = 100, 100

    local btnArrowLeft = V.createArrowButton(true, cc.size(btnW, btnH), function(sender) self:onBtnArrow(sender) end)
    lc.addChildToPos(vipArea, btnArrowLeft, cc.p(btnW / 2, areaH / 2))
    vipArea._btnArrowLeft = btnArrowLeft

    local arrowLeftLabel = V.createBMFont(V.BMFont.huali_26, "V")
    lc.addChildToPos(btnArrowLeft, arrowLeftLabel, cc.p(btnW / 2, btnH / 2 + 5 + lc.h(arrowLeftLabel)))
    vipArea._arrowLeftLabel = arrowLeftLabel

    local btnArrowRight = V.createArrowButton(false, cc.size(btnW, btnH), function(sender) self:onBtnArrow(sender) end)
    lc.addChildToPos(vipArea, btnArrowRight, cc.p(areaW - btnW / 2, areaH / 2))
    vipArea._btnArrowRight = btnArrowRight

    local arrowRightLabel = V.createBMFont(V.BMFont.huali_26, "V")
    lc.addChildToPos(btnArrowRight, arrowRightLabel, cc.p(btnW / 2, lc.y(arrowLeftLabel)))
    vipArea._arrowRightLabel = arrowRightLabel

    -- Create text area
    local textArea = ccui.Layout:create()
    textArea:setContentSize(cc.size(areaW - btnW - btnW, areaH - 110))
    textArea:setAnchorPoint(0.5, 0.5)
    textArea:setClippingEnabled(true)
    lc.addChildToPos(vipArea, textArea, cc.p(areaW / 2, areaH - 24 - lc.h(textArea) / 2))
    vipArea._textArea = textArea

    local textFrame = lc.createSprite({_name = 'img_com_bg_11', _crect = V.CRECT_COM_BG11, _size = textArea:getContentSize()})
    lc.addChildToCenter(textArea, textFrame)
            
    self._vipArea = vipArea

    -- reset
    self:scrollToVip(math.max(P._vip, 1), true)
end

function _M:scrollToVip(vip, isSkipAni)
    self._titleLabel:setString(string.format("VIP %d %s%s", vip, Str(STR.LEVEL), Str(STR.PRIVILEGE)))

    local vipArea = self._vipArea
    local vipMaxLevel = vipMax()

    -- Left and Right button
    vipArea._btnArrowLeft:setVisible(vip ~= 1)
    vipArea._btnArrowRight:setVisible(vip ~= vipMaxLevel)

    if vip > 1 then
        vipArea._arrowLeftLabel:setString(string.format("VIP %d", vip - 1))
    end
    if vip < vipMaxLevel then
        vipArea._arrowRightLabel:setString(string.format("VIP %d", vip + 1))
    end

    -- Update content
    local isVipUp = (vipArea._vip == nil or vipArea._vip < vip)

    local textArea = vipArea._textArea
    local areaW, areaH = lc.w(textArea), lc.h(textArea)
    local list = textArea._list

    local duration = isSkipAni and 0 or 0.2
    if list then
        list:stopAllActions()
        list:runAction(lc.sequence({lc.moveBy(duration, isVipUp and -areaW or areaW, 0), lc.fadeOut(duration)}, lc.remove()))
    end

    list = self:createVipItemsList(vip)
    lc.addChildToPos(textArea, list, cc.p(lc.w(textArea) / 2 + (isVipUp and areaW or -areaW), lc.h(textArea) / 2))
    list:runAction(lc.sequence({lc.moveTo(duration, lc.w(textArea) / 2, lc.y(list)), lc.fadeIn(duration)}))
    textArea._list = list

    vipArea._vip = vip
end

function _M:onBtnArrow(sender)
    local vipArea = self._vipArea
    if vipArea == nil then return end

    if sender == vipArea._btnArrowLeft then
        self:scrollToVip(vipArea._vip - 1)
    else
        self:scrollToVip(vipArea._vip + 1)
    end
end

function _M:createVipItemsList(vip)
    local textArea = self._vipArea._textArea

    local list = lc.List.createV(cc.size(lc.w(textArea) - 40, lc.h(textArea) - 16), 20, 20)
    list:setAnchorPoint(0.5, 0.5)

    list:pushBackCustomItem(self:createVipTextItem(vip, lc.w(list)))
    list:pushBackCustomItem(self:createVipBonusItem(vip, lc.w(list)))

    return list
end

function _M:createVipTextItem(vip, width)
    -- Do not use list currently, because all contents can be shown in one screen
    local items, gap, totalH = {}, 4, 0
    local addListItem = function(str)
        if str then
            local item = self:createRichText(str)
            table.insert(items, item)
        
            if totalH > 0 then
                totalH = totalH + gap
            end
            totalH = totalH + lc.h(item)
        end
    end

    local strs = {
        Str(STR.VIP_CONTENT_1),      -- ingot
        Str(STR.VIP_CONTENT_2),      -- vip gift
        Str(STR.VIP_CONTENT_3),      -- vip include
        Str(STR.VIP_CONTENT_4),      -- buy grain, gold
        Str(STR.VIP_CONTENT_5),      -- buy evoluate materials
        Str(STR.VIP_CONTENT_6),      -- buy chest
        Str(STR.VIP_CONTENT_7),      -- buy exp props
        Str(STR.VIP_CONTENT_8),      -- free times of activity battle
        Str(STR.VIP_CONTENT_9),      -- unlock buy times of activity battle
        Str(STR.VIP_CONTENT_10),     -- buy times of activity battle
        Str(STR.VIP_CONTENT_11),     -- battle 2x speed
        Str(STR.VIP_CONTENT_12),     -- guard tower count
        Str(STR.VIP_CONTENT_13),     -- unlock ingot refresh market
        Str(STR.VIP_CONTENT_14),     -- times of ingot refresh market
        Str(STR.VIP_CONTENT_15),     -- times of refresh other market
        Str(STR.VIP_CONTENT_16),     -- flag get when win
        Str(STR.VIP_CONTENT_17),     -- hero fragment exchange forever
        Str(STR.VIP_CONTENT_18),     -- unlock sweep 5 times
        Str(STR.VIP_CONTENT_19),     -- reset city attack or sweep times
        Str(STR.VIP_CONTENT_20),     -- union ingot worship
        Str(STR.VIP_CONTENT_21),     -- unlock legend lottery
        Str(STR.VIP_CONTENT_22),     -- grace +1
        Str(STR.VIP_CONTENT_23),      -- legend hero box times limit
        Str(STR.VIP_CONTENT_24),      -- clash exp
        Str(STR.VIP_CONTENT_25),      -- ladder exp
        Str(STR.VIP_CONTENT_26),      -- expedition exp
    }

    local gInfo = Data._globalInfo
    local vipIndex = vip + 1

    addListItem(string.format(strs[1], gInfo._vipIngot[vipIndex]))
    addListItem(string.format(strs[2], vip))

    --[[if vip > 1 then
        addListItem(string.format(strs[3], vip - 1))
    end

    if vip == 3 then
        addListItem(strs[18])
    end]]
    --[[
    addListItem(self:genVipItemsListText(vipIndex, gInfo._vipResetSweepCount, strs[19]))

    addListItem(self:genVipItemsListText(vipIndex, gInfo._vipBuyGrain, strs[4]))

    
    addListItem(self:genVipItemsListText(vipIndex, gInfo._vipBuyRemedy, strs[5]))
    addListItem(self:genVipItemsListText(vipIndex, gInfo._vipBuyChest1, strs[6]))
    addListItem(self:genVipItemsListText(vipIndex, gInfo._vipBuyHeroExp, strs[7]))

    addListItem(self:genVipItemsListText(vipIndex, gInfo._vipLegendChest, strs[23]))

    addListItem(self:genVipItemsListText(vipIndex, gInfo._vipRobGoldCount, strs[8]))
    addListItem(self:genVipItemsListText(vipIndex, gInfo._vipRobExpCount, strs[8]))
    addListItem(self:genVipItemsListText(vipIndex, gInfo._vipEliteCount, strs[8]))
    addListItem(self:genVipItemsListText(vipIndex, gInfo._vipRobHorseCount, strs[8]))
    addListItem(self:genVipItemsListText(vipIndex, gInfo._vipExpeditionCount, strs[8]))

    addListItem(self:genVipItemsListText(vipIndex, gInfo._vipBuyRobGold, strs[10], strs[9]))
    addListItem(self:genVipItemsListText(vipIndex, gInfo._vipBuyRobExp, strs[10], strs[9]))
    addListItem(self:genVipItemsListText(vipIndex, gInfo._vipBuyElite, strs[10], strs[9]))
    addListItem(self:genVipItemsListText(vipIndex, gInfo._vipBuyRobHorse, strs[10], strs[9]))
    addListItem(self:genVipItemsListText(vipIndex, gInfo._vipBuyExpedition, strs[10], strs[9]))
    ]]

    if vip == gInfo._2xSpeedVip or vip == gInfo._3xSpeedVip then
        local speed = (vip == gInfo._2xSpeedVip and 2 or 3)
        addListItem(string.format(strs[11], speed))
    end

    local clashExp = Data._globalInfo._vipLadderExp[vip + 1]
    if clashExp > 0 then
        addListItem(string.format(strs[24], clashExp))
    end
    local ladderExp = Data._globalInfo._vipLadderExExp[vip + 1]
    if ladderExp > 0 then
        addListItem(string.format(strs[25], ladderExp))
    end
    local expeditionExp = Data._globalInfo._vipExpeditionExp[vip + 1]
    if expeditionExp > 0 then
        addListItem(string.format(strs[26], expeditionExp))
    end

    --[[
    addListItem(self:genVipItemsListText(vipIndex, gInfo._vipGrace, strs[22]))
    
    if vip == gInfo._vipLottery then
        addListItem(strs[21])
    end

    addListItem(self:genVipItemsListText(vipIndex, gInfo._vipGuardHero, strs[12]))
    addListItem(self:genVipItemsListText(vipIndex, gInfo._vipBuyRefresh, strs[14], strs[13]))
    addListItem(self:genVipItemsListText(vipIndex, gInfo._vipBuyRefreshEx, strs[15]))
    
    if vip == gInfo._vipRecruit then
        addListItem(strs[16])
    end

    if vip == gInfo._vipWorship then
        addListItem(string.format(strs[20], speed))
    end
    ]]

    local title = cc.Label:createWithTTF(Str(STR.SPECIFIC_PRIVILEGE)..":", V.TTF_FONT, V.FontSize.S1)
    title:setColor(V.COLOR_TEXT_LIGHT)
    totalH = totalH + lc.h(title)

    -- Position items to the list
    local listItem, titleH = ccui.Widget:create(), 40
    totalH = totalH + titleH
    listItem:setContentSize(width, totalH)
    listItem:setCascadeOpacityEnabled(true)

    V.addDecoratedLabel(listItem, Str(STR.SPECIFIC_PRIVILEGE), cc.p(lc.w(listItem) / 2, totalH - titleH / 2), 26)
                
    local top = totalH - titleH
    for _, item in ipairs(items) do
        lc.addChildToPos(listItem, item, cc.p(width / 2, top - lc.h(item) / 2))
        top = top - lc.h(item) - gap
    end
    
    return listItem
end

function _M:createVipBonusItem(vip, width)
    local bonusId = {10099, 10100, 10101, 10130, 10102, 10103, 10104, 10105, 10106, 10107, 10108, 10109, 10110, 10200, 10201, 10827}

    local bonusInfo, icons = Data._bonusInfo[bonusId[vip]], {}
    for i = 1, #bonusInfo._rid do
        local ico = IconWidget.create{_infoId = bonusInfo._rid[i], _level = bonusInfo._level[i], _count = bonusInfo._count[i], _isFragment = (bonusInfo._isFragment[i] > 0)}
        ico._name:setColor(V.COLOR_BMFONT)
        table.insert(icons, ico)
    end    
    P:sortResultItems(icons)

    local item, titleH = ccui.Widget:create(), 30
    item:setContentSize(width, titleH + lc.h(icons[1]) + 10)
    item:setCascadeOpacityEnabled(true)

    V.addDecoratedLabel(item, Str(STR.SPECIFIC_BONUS), cc.p(lc.w(item) / 2, lc.h(item) - titleH / 2), 26)

    lc.addNodesToCenterH(item, icons, 20, 56)

    return item
end

function _M:genVipItemsListText(vipIndex, values, str, unlockStr)
    local gInfo = Data._globalInfo
    
    local value = values[vipIndex]
    if vip == 1 or values[vipIndex] ~= values[vipIndex - 1] then
        if value == 1 then
            if values == gInfo._vipBuyElite then
                value = Str(STR.COPY_ELITE)
            elseif values == gInfo._vipBuyBoss then
                value = Str(STR.COPY_BOSS)
            elseif values == gInfo._vipBuyCommander then
                value = Str(STR.COPY_COMMANDER)
            elseif values == gInfo._vipBuyExpedition then
                value = Str(STR.COPY_EXPEDITION)
            elseif values == gInfo._vipGrace or values == gInfo._vipLegendChest then
                return string.format(str, value)
            else
                value = nil
            end

            return string.format(unlockStr, value)          -- unlock
        elseif value > 0 then
            if values == gInfo._vipRobExpCount or values == gInfo._vipBuyRobExp then
                return string.format(str, Str(STR.COPY_IMMUNITY_PHY), value)
            elseif values == gInfo._vipEliteCount or values == gInfo._vipBuyElite then
                return string.format(str, Str(STR.COPY_ELITE), value)
            elseif values == gInfo._vipCommanderCount or values == gInfo._vipBuyCommander then
                return string.format(str, Str(STR.COPY_COMMANDER), value)
            elseif values == gInfo._vipExpeditionCount or values == gInfo._vipBuyExpedition then
                return string.format(str, Str(STR.COPY_EXPEDITION), value)
            else
                return string.format(str, value)            -- buy count
            end
        end
    end

    return nil
end

function _M:createRichText(str)
    local richText = ccui.RichTextEx:create()
    if str then
        V.appendBoldRichText(richText, str, {_normalClr = V.COLOR_TEXT_LIGHT, _boldClr = V.COLOR_TEXT_GREEN_DARK})
        richText:setCascadeOpacityEnabled(true)

    else
        if P._vip < vipMax() then
            richText:insertElement(ccui.RichItemText:create(0, V.COLOR_TEXT_LIGHT, 255, Str(STR.RECHARGE_AGAIN), V.TTF_FONT, V.FontSize.S1))
            richText:insertElement(ccui.RichItemText:create(0, V.COLOR_TEXT_INGOT, 255, string.format(" %d ", P:getVIPupExp() - P._vipExp), V.TTF_FONT, V.FontSize.S1))
            richText:insertElement(ccui.RichItemCustom:create(0, lc.Color3B.white, 255, lc.createSprite(string.format("img_icon_res%d_s", Data.ResType.ingot))))
            richText:insertElement(ccui.RichItemText:create(0, V.COLOR_TEXT_LIGHT, 255, " "..Str(STR.CAN_ARRIVE), V.TTF_FONT, V.FontSize.S1))
        else
            richText:insertElement(ccui.RichItemText:create(0, V.COLOR_TEXT_LIGHT, 255, Str(STR.VIP_MAX), V.TTF_FONT, V.FontSize.S1))

            local vip = V.createBMFont(V.BMFont.huali_26, string.format(" VIP %d", vipMax()))
            vip:setColor(V.COLOR_TEXT_VIP)
            richText:insertElement(ccui.RichItemCustom:create(0, lc.Color3B.white, 255, vip))
        end
    end
    
    richText:formatText()
    return richText        
end

return _M