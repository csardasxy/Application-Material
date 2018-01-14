local _M = class("ActiveChestForm", BaseForm)

local FORM_SIZE = cc.size(760, 500)
local DROP_AREA_SIZE = cc.size(620, 280)

function _M.create(index, bonus)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(index, bonus)
    return panel
end

function _M:init(index, bonus)
    _M.super.init(self, FORM_SIZE, nil, bor(BaseForm.FLAG.PAPER_BG))

    local bonesNames = {"1baoxiang", "2baoxiang", "3baoxiang", "4baoxiang", "5baoxiang"}


    local titleBg = lc.createSprite("img_title_bg_1")
    lc.addChildToPos(self._form, titleBg, cc.p(lc.w(self._form) / 2, lc.h(self._form) - 10 - lc.h(titleBg) / 2))

    local title = V.createTTFStroke(Str(STR.ACTIVE_BONUS), V.FontSize.S1)
    lc.addChildToCenter(titleBg, title)
    
    local chest = DragonBones.create(bonesNames[index])
    chest:gotoAndPlay("effect4")
    chest:setScale(0.4)
    lc.addChildToPos(self._form, chest, cc.p(120, lc.bottom(titleBg) - 60))
--    local name = V.createTTF(ClientData.getNameByInfoId(chest._infoId), V.FontSize.S1, V.COLOR_TEXT_LIGHT)
--    local nameBg = lc.createSprite{_name = "img_com_bg_2", _crect = V.CRECT_COM_BG2, _size = cc.size(400, 40)}
--    nameBg:setColor(lc.Color3B.black)
--    nameBg:setOpacity(100)
--    lc.addChildToPos(nameBg, name, cc.p(30 + lc.w(name) / 2, lc.h(nameBg) / 2 - 1))
--    lc.addChildToPos(form, nameBg, cc.p(lc.right(icon) - 10 + lc.w(nameBg) / 2, lc.top(icon) - lc.h(nameBg) / 2 - 10), -1)

    local descOffsetY = 30
    local desc = V.createTTF(string.format(Str(bonus._info._nameSid), bonus._info._val), V.FontSize.S1, V.COLOR_TEXT_LIGHT)
    lc.addChildToPos(self._form, desc, cc.p(lc.x(chest) + 70 + lc.w(desc) / 2, lc.y(chest)))
    
    -- Create drop area
    local dropBg = lc.createSprite{_name = "img_com_bg_11", _crect = V.CRECT_COM_BG11, _size = DROP_AREA_SIZE}
    lc.addChildToPos(self._form, dropBg, cc.p(lc.w(self._form) / 2, lc.bottom(titleBg) - 120 - lc.h(dropBg) / 2))
    
    local maybeLabel = V.addDecoratedLabel(dropBg, Str(STR.GET)..Str(STR.BONUS), cc.p(lc.w(dropBg) / 2, lc.h(dropBg) - 40), 26)
    maybeLabel:setColor(lc.Color3B.white)


    local ids, nums, drops = bonus._info._rid, bonus._info._count, {}
    for i, id in ipairs(ids) do
        local icon = IconWidget.create({_infoId = id, _count = nums[i]}, IconWidget.DisplayFlag.NAME)
        icon._name:setColor(lc.Color3B.white)
        local count = V.createBMFont(V.BMFont.huali_20, string.format("%s", ClientData.formatNum(nums[i], 9999)))
        count:setColor(lc.Color3B.white)
        lc.addChildToPos(icon, count, cc.p(lc.cw(icon), -16))
        table.insert(drops, icon)
    end

    lc.addNodesToCenterH(dropBg, drops, 16, lc.h(dropBg) / 2 + 6)

end

function _M:onEnter()
    _M.super.onEnter(self)
end

function _M:onExit()
    _M.super.onExit(self)
end

return _M