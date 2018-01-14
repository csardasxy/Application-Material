local _M = class("ClashChestForm", BaseForm)

local FORM_SIZE = cc.size(760, 570)
local DROP_AREA_SIZE = cc.size(620, 280)

function _M.create(grade, index, quality)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(grade, index, quality)
    return panel
end

function _M:init(grade, index, quality)
    _M.super.init(self, FORM_SIZE, nil, bor(BaseForm.FLAG.PAPER_BG))

    local chest = V.createClashFieldChest(grade, index, quality, true)
    local form, info = self._form, Data.getInfo(chest._infoId)

    local titleBg = lc.createSprite("img_title_bg_1")
    lc.addChildToPos(form, titleBg, cc.p(lc.w(form) / 2, lc.h(form) - 10 - lc.h(titleBg) / 2))

    local title = V.createTTFStroke(Str(Data._ladderInfo[grade]._nameSid)..Str(STR.FIND_CLASH_FIELD), V.FontSize.S1)
    lc.addChildToCenter(titleBg, title)
    
    chest:setTouchEnabled(false)
    lc.addChildToPos(form, chest, cc.p(130, lc.bottom(titleBg) - lc.h(chest) / 2 - 10))
    
    local name = V.createTTF(ClientData.getNameByInfoId(chest._infoId), V.FontSize.S1, V.COLOR_TEXT_LIGHT)
    local nameBg = lc.createSprite{_name = "img_com_bg_2", _crect = V.CRECT_COM_BG2, _size = cc.size(400, 40)}
    nameBg:setColor(lc.Color3B.black)
    nameBg:setOpacity(100)
    lc.addChildToPos(nameBg, name, cc.p(30 + lc.w(name) / 2, lc.h(nameBg) / 2 - 1))
    lc.addChildToPos(form, nameBg, cc.p(lc.right(chest) - 10 + lc.w(nameBg) / 2, lc.top(chest) - lc.h(nameBg) / 2 - 10), -1)

    local descOffsetY = 30
    local desc = V.createBoldRichTextMultiLine(Str(info._descSid), V.RICHTEXT_PARAM_LIGHT_S1, 480)
    lc.addChildToPos(form, desc, cc.p(lc.right(chest) + 20 + lc.w(desc) / 2, lc.top(chest) - descOffsetY - lc.h(desc) / 2))
    
    -- Create drop area
    local dropBg = lc.createSprite{_name = "img_com_bg_11", _crect = V.CRECT_COM_BG11, _size = DROP_AREA_SIZE}
    lc.addChildToPos(form, dropBg, cc.p(lc.w(form) / 2, lc.bottom(chest) - 20 - lc.h(dropBg) / 2))
    
    local maybeLabel = V.addDecoratedLabel(dropBg, Str(STR.MAYBE)..Str(STR.GET), cc.p(lc.w(dropBg) / 2, lc.h(dropBg) - 40), 26)
    maybeLabel:setColor(lc.Color3B.white)

    local id = chest._infoId - Data.PropsId.clash_chest
    local dropInfo, drops = Data._ladderChestsInfo[id], {}
    for i, dropId in ipairs(dropInfo._dropId) do
        local icon = IconWidget.create({_infoId = dropId, _count = dropInfo._min[i]}, IconWidget.DisplayFlag.NAME)
        icon._name:setColor(lc.Color3B.white)
        local count = V.createTTFStroke(string.format("%s", ClientData.formatNum(dropInfo._min[i], 9999)), V.FontSize.S3)
        count:setColor(lc.Color3B.white)
        lc.addChildToPos(icon, count, cc.p(lc.cw(icon), -16))
        table.insert(drops, icon)
    end

    lc.addNodesToCenterH(dropBg, drops, 16, lc.h(dropBg) / 2 + 6)

    --TODO
    --[[
    local tipStr
    if quality == Data.CardQuality.N then
        tipStr = Str(STR.FIND_CLASH_CHEST_NORMAL_TIP)
    elseif quality == Data.CardQuality.R then
        tipStr = Str(STR.FIND_CLASH_CHEST_GOOD_TIP)
    elseif quality == Data.CardQuality.SR then
        if grade == Data.FindClashGrade.legend then
            tipStr = Str(STR.FIND_CLASH_CHEST_RARE_TIP_CARD)
        else
            tipStr = Str(STR.FIND_CLASH_CHEST_RARE_TIP)
        end
    else
        if grade == Data.FindClashGrade.legend then
            tipStr = Str(STR.FIND_CLASH_CHEST_LEGEND_TIP_CARD)
        else
            tipStr = Str(STR.FIND_CLASH_CHEST_LEGEND_TIP)
        end

        if dropInfo._legendary > 0 then
            tipStr = tipStr..string.format(Str(STR.FIND_CLASH_CHEST_LEGEND_80_TIP), dropInfo._legendary)
        end
    end

    local tipBg = lc.createSprite{_name = "img_com_bg_20", _crect = V.CRECT_COM_BG20, _size = cc.size(560, 36)}
    tipBg:setColor(cc.c3b(12, 53, 121))
    lc.addChildToPos(dropBg, tipBg, cc.p(lc.w(dropBg) / 2, 48))

    local tip = V.createBoldRichText(tipStr, V.RICHTEXT_PARAM_LIGHT_S2)
    lc.addChildToPos(dropBg, tip, cc.p(lc.w(dropBg) / 2, lc.y(tipBg)))
    ]]
end

function _M:onEnter()
    _M.super.onEnter(self)
end

function _M:onExit()
    _M.super.onExit(self)
end

return _M