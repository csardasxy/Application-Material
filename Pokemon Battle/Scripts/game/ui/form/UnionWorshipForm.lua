local _M = class("UnionWorshipForm", BaseForm)

local FORM_SIZE = cc.size(800, 460)
local ITEM_SIZE = cc.size(172, 240)

function _M.create(member)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(member)
    return panel
end

function _M:init(member)
    _M.super.init(self, FORM_SIZE, Str(STR.SELECT_WORSHIP), bor(BaseForm.FLAG.BASE_TITLE_BG, BaseForm.FLAG.PAPER_BG))

    self._member = member

    self._isShowResourceUI = true
    V.getResourceUI():setMode(Data.ResType.gold)

    local form = self._form

    if P._vip < Data._globalInfo._vipWorship then
        local pos = cc.p(lc.w(form) / 2 - 25 - ITEM_SIZE.width / 2, lc.bottom(self._titleFrame) - 60 - ITEM_SIZE.height / 2)
        for i = 1, 2 do
            local item = self:createItem(i)
            lc.addChildToPos(form, item, pos, 0, i)
            pos.x = pos.x + ITEM_SIZE.width + 50
        end
    else
        local pos = cc.p(_M.FRAME_THICK_LEFT + 54 + ITEM_SIZE.width / 2, lc.bottom(self._titleFrame) - 60 - ITEM_SIZE.height / 2)
        for i = 1, 3 do
            local item = self:createItem(i)
            lc.addChildToPos(form, item, pos, 0, i)
            pos.x = pos.x + ITEM_SIZE.width + 50
        end
    end

    self:updateRemainTimes()
end

function _M:createItem(index)
    local item = lc.createSprite{_name = "img_com_bg_11", _crect = V.CRECT_COM_BG11, _size = ITEM_SIZE}    

    -- Add item name background
    local nameBg = lc.createSprite("img_item_title_bg")
    lc.addChildToPos(item, nameBg, cc.p(ITEM_SIZE.width / 2, ITEM_SIZE.height - 38))

    local nameValue = V.createTTF(Str(STR.WORSHIP_TITLE1 + index - 1), V.FontSize.S2)    
    lc.addChildToPos(nameBg, nameValue, cc.p(lc.w(nameBg) / 2, 32))

    local ico = IconWidget.create({_infoId = Data.ResType.grain, _count = Data._globalInfo._worshipGain[index]}, IconWidgetFlag.ITEM_NO_NAME)
    lc.addChildToPos(item, ico, cc.p(ITEM_SIZE.width / 2, ITEM_SIZE.height / 2 + 10))

    local btnBuy = V.createScale9ShaderButton("img_btn_1_s", function() self:worship(index) end, V.CRECT_BUTTON_1_S, 160)
    if index == 1 then
        btnBuy:addLabel(Str(STR.FREE))
    else
        item._resType = (index == 2 and Data.ResType.gold or Data.ResType.ingot)
        btnBuy:addLabel(Data._globalInfo._worshipCost[index])
        btnBuy:addIcon(string.format("img_icon_res%d_s", item._resType))
    end
    lc.addChildToPos(item, btnBuy, cc.p(ITEM_SIZE.width / 2, 40))

    return item
end

function _M:updateRemainTimes()
    local times = self._remainTimes
    if times then
        times:removeFromParent()
    end

    local count = Data._globalInfo._dailyWorshipCount
    times = V.createBoldRichText(string.format(Str(STR.DAILY_WORSHIP_TIMES), count - P._dailyWorship, count), V.RICHTEXT_PARAM_DARK_S1)
    lc.addChildToPos(self._form, times, cc.p(lc.w(self._form) / 2, lc.bottom(self._titleFrame) - 20))
    self._remainTimes = times
end

function _M:worship(index)
    if P._dailyWorship >= Data._globalInfo._dailyWorshipCount then
        ToastManager.push(Str(STR.CANNOT_UNION_WORSHIP))
        return
    end
   
    local item, cost = self._form:getChildByTag(index), Data._globalInfo._worshipCost[index]
    if item._resType == Data.ResType.ingot then
        if not V.checkIngot(cost) then
            return
        end
    else
        if not V.checkGold(cost) then
            return
        end            
    end
    
    local grain = Data._globalInfo._worshipGain[index]
    P._dailyWorship = P._dailyWorship + 1
    P:changeResource(item._resType, -cost)
    P:changeResource(Data.ResType.grain, grain)

    ClientData.sendUnionWorship(self._member._id, index)
    
    self:updateRemainTimes()
    self:hide()

    V.showResChangeText(lc._runningScene, Data.ResType.grain, grain)
end

function _M:onExit()
    _M.super.onExit(self)

    V.getResourceUI():setMode(Data.PropsId.yubi)
end

return _M