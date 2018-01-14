local _M = class("ClashTargetChestForm", BaseForm)

local FORM_SIZE = cc.size(760, 570)
local DROP_AREA_SIZE = cc.size(620, 280)

function _M.create(step)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(step)
    return panel
end

function _M:init(step)
    _M.super.init(self, FORM_SIZE, nil, bor(BaseForm.FLAG.PAPER_BG))

    local form = self._form
    local bonus = P._playerBonus._bonusClashTarget[step]

    local chest = V.createClashTargetChest(step)
    
    local titleBg = lc.createSprite("img_title_bg_1")
    lc.addChildToPos(form, titleBg, cc.p(lc.w(form) / 2, lc.h(form) - _M.FRAME_THICK_TOP - lc.h(titleBg) / 2))

    local title = V.createTTFStroke(Str(STR.FIND_CLASH_SEASON_TARGET), V.FontSize.S1)
    lc.addChildToCenter(titleBg, title)
    
    chest:setTouchEnabled(false)
    lc.addChildToPos(form, chest, cc.p(130, lc.bottom(titleBg) - lc.h(chest) / 2 - 10))
    
    --local name = V.createTTF(ClientData.getNameByInfoId(chest._infoId), V.FontSize.S1, V.COLOR_TEXT_LIGHT)
    local nameBg = lc.createSprite{_name = "img_com_bg_2", _crect = V.CRECT_COM_BG2, _size = cc.size(400, 40)}
    nameBg:setColor(lc.Color3B.black)
    nameBg:setOpacity(100)
    --lc.addChildToPos(nameBg, name, cc.p(30 + lc.w(name) / 2, lc.h(nameBg) / 2 - 1))
    lc.addChildToPos(form, nameBg, cc.p(lc.right(chest) - 10 + lc.w(nameBg) / 2, lc.top(chest) - lc.h(nameBg) / 2 - 10), -1)
    
    local descOffsetY = 30
    local desc = V.createTTF(string.format(Str(bonus._info._nameSid), bonus._info._val), V.FontSize.S1, V.COLOR_TEXT_LIGHT, cc.size(440, 0))
    lc.addChildToPos(form, desc, cc.p(lc.right(chest) + 20 + lc.w(desc) / 2, lc.top(chest) - descOffsetY - lc.h(desc) / 2))
    
    -- Create drop area
    local dropBg = lc.createSprite{_name = "img_com_bg_11", _crect = V.CRECT_COM_BG11, _size = DROP_AREA_SIZE}
    lc.addChildToPos(form, dropBg, cc.p(lc.w(form) / 2, lc.bottom(chest) - 20 - lc.h(dropBg) / 2))
    
    local drops = {}
    for i = 1, #bonus._info._rid do
        local icon = IconWidget.create({_infoId = bonus._info._rid[i], _count = bonus._info._count[i]}, IconWidget.DisplayFlag.NAME)
        icon._name:setColor(lc.Color3B.white)
        local count = V.createBMFont(V.BMFont.huali_20, string.format("%s", ClientData.formatNum(bonus._info._count[i], 9999)))
        count:setColor(lc.Color3B.white)
        lc.addChildToPos(icon, count, cc.p(lc.cw(icon), -16))
        table.insert(drops, icon)
    end

    lc.addNodesToCenterH(dropBg, drops, 16, lc.h(dropBg) / 2 + 6)
end

return _M