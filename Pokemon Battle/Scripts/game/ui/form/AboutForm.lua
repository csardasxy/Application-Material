local _M = class("AboutForm", BaseForm)

local FORM_SIZE = cc.size(600, 540)

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
    
    return panel    
end

function _M:init()
    self._resNames = ClientData.loadLCRes("res/about.lcres")

    _M.super.init(self, FORM_SIZE, nil, bor(BaseForm.FLAG.PAPER_BG))

    local form = self._form

    local copyRight = self:createCopyRight()
    lc.addChildToPos(form, copyRight, cc.p(lc.w(form) / 2, lc.h(form) - _M.FRAME_THICK_TOP - 48 - lc.h(copyRight) / 2))

    local specialThanks = self:createSpecialThanks()
    lc.addChildToPos(form, specialThanks, cc.p(lc.w(form) / 2, lc.bottom(copyRight) - 40 - lc.h(specialThanks) / 2))
end

function _M:onCleanup()
    _M.super.onCleanup(self)

    ClientData.unloadLCRes(self._resNames)
end

function _M:createCopyRight()
    local item = lc.createNode(cc.size(lc.w(self._form) - 100, 180))

    local labelCopyRight = V.addDecoratedLabel(item, Str(STR.COPYRIGHT), cc.p(lc.w(item) / 2, lc.h(item) - 20), 26)        
    local labelBg = labelCopyRight:getParent()
        
    local iconCopyRightOwner = lc.createSprite("about_logo_leocool")
    lc.addChildToPos(item, iconCopyRightOwner, cc.p(lc.x(labelBg), lc.bottom(labelBg) - 20 - lc.h(iconCopyRightOwner) / 2))
    
    local labelCopyRightOwnerCN = V.createTTF(Str(STR.COPYRIGHT_OWNER_CN), V.FontSize.S1, V.COLOR_TEXT_LIGHT)
    lc.addChildToPos(item, labelCopyRightOwnerCN, cc.p(lc.x(labelBg), lc.bottom(iconCopyRightOwner) - 6 - lc.h(labelCopyRightOwnerCN) / 2))
    
    return item
end

function _M:createSpecialThanks()
    local item = lc.createNode(cc.size(lc.w(self._form) - 100, 180))

    local labelSpecialThanks = V.addDecoratedLabel(item, Str(STR.SPECIAL_THANKS), cc.p(lc.w(item) / 2, lc.h(item) - 20), 26)
    local labelBg = labelSpecialThanks:getParent()

    local y = lc.bottom(labelBg) - 20
    local addLabelIcon = function(label, iconName, x)
        local label = V.createTTF(label, V.FontSize.S1, V.COLOR_TEXT_LIGHT)
        lc.addChildToPos(item, label, cc.p(x, y - lc.h(label) / 2))

        local icon = lc.createSprite(iconName)
        lc.addChildToPos(item, icon, cc.p(x, lc.bottom(label) - 6 - lc.h(icon) / 2))
    end

    local cx = lc.w(item) / 2
    addLabelIcon(Str(STR.TECHNOLOGY_ENGINE), "about_logo_cocos2dx", cx - 160)
    addLabelIcon(Str(STR.IMAGE_DESIGN), "about_logo_shengtang", cx)
    addLabelIcon(Str(STR.AUDIO_DEVELOP), "about_logo_guangyun", cx + 160)

    return item
end

return _M