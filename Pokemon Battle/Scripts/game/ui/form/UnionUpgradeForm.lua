local _M = class("UnionUpgradeForm", BaseForm)

local FORM_SIZE = cc.size(800, 530)
local UNLOCK_AREA_SIZE = cc.size(640, 260)

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
    return panel
end

function _M:init()
    _M.super.init(self, FORM_SIZE, Str(STR.UNION)..Str(STR.UPGRADE), bor(BaseForm.FLAG.ADVANCE_TITLE_BG, BaseForm.FLAG.PAPER_BG))
    
    self._isShowResourceUI = true
    local form, union = self._form, P._playerUnion:getMyUnion()

    -- Upgrade level change    
    local levelLabel = V.createTTF(Str(STR.UNION)..Str(STR.LEVEL)..": ", V.FontSize.S1, V.COLOR_LABEL_DARK)
    local curLevel = V.createTTF(tostring(union._level), V.FontSize.M2, V.COLOR_TEXT_DARK)
    local newLevel = V.createTTF(tostring(union._level + 1), V.FontSize.M2, V.COLOR_TEXT_DARK)
    
    local arrow = lc.createSprite("img_arrow_right")
    arrow:setColor(V.COLOR_TEXT_GREEN)

    lc.addNodesToCenterH(form, {levelLabel, curLevel, arrow, newLevel}, 16, lc.bottom(self._titleFrame) - 30)
    
    -- Unlock items
    local unlockBg = lc.createSprite{_name = "img_com_bg_10", _crect = V.CRECT_COM_BG10, _size = UNLOCK_AREA_SIZE}
    lc.addChildToPos(form, unlockBg, cc.p(lc.w(form) / 2, lc.bottom(levelLabel) - 16 - UNLOCK_AREA_SIZE.height / 2))

    local list = lc.List.createV(cc.size(UNLOCK_AREA_SIZE.width - 40, UNLOCK_AREA_SIZE.height - 30))
    list:setAnchorPoint(0.5, 0.5)
    list:setBounceEnabled(false)
    lc.addChildToPos(unlockBg, list, cc.p(lc.w(unlockBg) / 2, lc.h(unlockBg) / 2 + 4))

    local unlocks, lineH = {Str(STR.UNION_UPGRADE_UNLOCK_MARKET)}, 32
    for _, tech in pairs(union._techs) do
        if tech._info._unlockLevel == union._level + 1 then
            table.insert(unlocks, string.format(Str(STR.UNION_UPGRADE_UNLOCK_TECH), Str(tech._info._nameSid)))
        end
    end

    local itemH = 50 + lineH * #unlocks

    local unlockItem = ccui.Widget:create()
    unlockItem:setContentSize(lc.w(list), itemH)

    V.addDecoratedLabel(unlockItem, Str(STR.UNLOCK_FUNCTION), cc.p(lc.w(unlockItem) / 2, itemH - 16), 26)

    local y = itemH - 50
    for _, str in ipairs(unlocks) do
        local line = V.createBoldRichText(str, {_normalClr = V.COLOR_TEXT_DARK, _boldClr = V.COLOR_TEXT_GREEN_DARK, _fontSize = V.FontSize.S1})
        lc.addChildToPos(unlockItem, line, cc.p(lc.w(unlockItem) / 2, y - lineH / 2))
        y = y - lineH
    end

    list:pushBackCustomItem(unlockItem)

    -- Upgrade button
    local btnW = 180
    local btnUpgrade = V.createScale9ShaderButton("img_btn_1", function(sender) self:upgrade() end, V.CRECT_BUTTON, btnW)
    btnUpgrade:addLabel(Str(STR.UPGRADE))
    lc.addChildToPos(form, btnUpgrade, cc.p(lc.w(form) / 2, lc.h(btnUpgrade) / 2 + _M.BOTTOM_MARGIN + 24))

    local woodArea, upgradeWood = V.createResIconLabel(btnW - 20, "img_icon_res12_s"), union:getLevelupWood()
    woodArea._label:setString(upgradeWood)
    woodArea._label:setColor(union._wood >= upgradeWood and lc.Color3B.white or lc.Color3B.red)
    lc.addChildToPos(form, woodArea, cc.p(lc.x(btnUpgrade) + 6, lc.top(btnUpgrade) + 10 + lc.h(woodArea) / 2))

    local goldArea, upgradeGold = V.createResIconLabel(btnW - 20, "img_icon_res11_s"), union:getLevelupGold()
    goldArea._label:setString(upgradeGold)
    goldArea._label:setColor(union._gold >= upgradeGold and lc.Color3B.white or lc.Color3B.red)
    lc.addChildToPos(form, goldArea, cc.p(lc.left(woodArea) - 120, lc.y(woodArea)))

    local actArea, upgradeAct = V.createResIconLabel(btnW - 20, "img_icon_res13_s"), union:getLevelupAct()
    actArea._label:setString(upgradeAct)
    actArea._label:setColor(union._act >= upgradeAct and lc.Color3B.white or lc.Color3B.red)
    lc.addChildToPos(form, actArea, cc.p(lc.right(woodArea) + 120, lc.y(woodArea)))
end

function _M:upgrade()
    local result = P._playerUnion:upgrade(true)
    if result == Data.ErrorType.ok then
        ClientData.sendUnionUpgrade()
        self:hide()

    elseif result == Data.ErrorType.need_more_union_gold then
        ToastManager.push(Str(STR.NOT_ENOUGH_UNION_GOLD))
    elseif result == Data.ErrorType.need_more_union_wood then
        ToastManager.push(Str(STR.NOT_ENOUGH_UNION_WOOD))
    elseif result == Data.ErrorType.need_more_union_act then
        ToastManager.push(Str(STR.NOT_ENOUGH_UNION_ACT))
    end
end

return _M