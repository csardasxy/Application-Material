local _M = class("LadderChestForm", BaseForm)

local FORM_SIZE = cc.size(760, 570)
local DROP_AREA_SIZE = cc.size(620, 280)

function _M.create(...)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(...)
    return panel
end

function _M:init(infoId)
    _M.super.init(self, FORM_SIZE, nil, bor(BaseForm.FLAG.PAPER_BG))

    local form = self._form

    local bonesNames = {"1baoxiang", "2baoxiang", "3baoxiang", "4baoxiang", "5baoxiang"}
    local info = Data._propsInfo[infoId]
    local bones = DragonBones.create(bonesNames[info._picId - 7820 + 1])
    lc.addChildToPos(form, bones, cc.p(150, lc.h(form) - 140))
    bones:setScale(0.6)
    bones:gotoAndPlay("effect4")
    
    --[[local name = V.createTTF(ClientData.getNameByInfoId(infoId), V.FontSize.S1, V.COLOR_TEXT_LIGHT)
    local nameBg = lc.createSprite{_name = "img_com_bg_2", _crect = V.CRECT_COM_BG2, _size = cc.size(400, 40)}
    nameBg:setColor(lc.Color3B.black)
    nameBg:setOpacity(100)
    lc.addChildToPos(nameBg, name, cc.p(30 + lc.w(name) / 2, lc.h(nameBg) / 2 - 1))
    lc.addChildToPos(form, nameBg, cc.p(lc.x(bones) + 100 + lc.cw(nameBg), lc.y(bones)), -1)]]

    local desc = V.createTTF(Str(info._descSid), V.FontSize.S1, V.COLOR_TEXT_LIGHT, cc.size(440, 0))
    lc.addChildToPos(form, desc, cc.p(lc.x(bones) + lc.cw(desc) + 100, lc.y(bones)))
    
    -- Create drop area
    local dropBg = lc.createSprite{_name = "img_com_bg_11", _crect = V.CRECT_COM_BG11, _size = DROP_AREA_SIZE}
    lc.addChildToPos(form, dropBg, cc.p(lc.w(form) / 2, lc.h(dropBg) / 2 + 60))
    
    local maybeLabel = V.addDecoratedLabel(dropBg, Str(STR.MAYBE)..Str(STR.GET), cc.p(lc.w(dropBg) / 2, lc.h(dropBg) - 40), 26)
    maybeLabel:setColor(lc.Color3B.white)

    local id = infoId - Data.PropsId.ladder_chest + 100
    local dropInfo, drops = Data._ladderChestsInfo[id], {}
    for i, dropId in ipairs(dropInfo._dropId) do
        local icon, count
        local count
        if dropInfo._min[i] ~= dropInfo._max[i] then
            icon = IconWidget.create({_infoId = dropId, _showOwnCount = true, _param = {_min = dropInfo._min[i], _max = dropInfo._max[i]}}, IconWidget.DisplayFlag.NAME)
            count = V.createBMFont(V.BMFont.huali_20, string.format("%s-%s", ClientData.formatNum(dropInfo._min[i], 9999), ClientData.formatNum(dropInfo._max[i], 9999)))
        else
            icon = IconWidget.create({_infoId = dropId, _count = dropInfo._min[i]}, IconWidget.DisplayFlag.NAME)
            count = V.createBMFont(V.BMFont.huali_20, ClientData.formatNum(dropInfo._min[i], 9999))
        end
        icon._name:setColor(lc.Color3B.white)
        count:setColor(lc.Color3B.white)
        lc.addChildToPos(icon, count, cc.p(lc.cw(icon), -16))
        table.insert(drops, icon)
    end

    lc.addNodesToCenterH(dropBg, drops, 16, lc.h(dropBg) / 2 + 6)
end

return _M