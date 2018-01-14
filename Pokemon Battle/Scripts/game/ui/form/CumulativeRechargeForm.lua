local _M = class("CumulativeRechargeForm", BaseForm)

local FORM_SIZE = cc.size(800, 670)
local TAB_WIDTH = 140
local TAB_MARGIN_TOP = 20
local TAB_MARGIN_LEFT = 0
local ITEM_Height = 150

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
    
    return panel    
end

function _M:init()
    local activityInfo = ClientData.getActivityByType(603)
    _M.super.init(self, FORM_SIZE, activityInfo and Str(activityInfo._nameSid) or '', bor(BaseForm.FLAG.ADVANCE_TITLE_BG))

    local adSpr = lc.createSprite("res/jpg/cumulative_recharge_bg.jpg")
    V.setMaxSize(adSpr, FORM_SIZE.width - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, FORM_SIZE.height - V.FRAME_INNER_TOP - V.FRAME_INNER_BOTTOM)
    lc.addChildToCenter(self._frame, adSpr, -1)
    self._adSpr = adSpr
    --create icons
    local chargeIngot = P._playerActivity._chargeIngot
    bonusIds = activityInfo._param
    self._bonusIds = bonusIds
    for i, id in ipairs(bonusIds) do
        self._defaultIndex = i
        self._bonusInfo = Data._bonusInfo[id]
        if chargeIngot < self._bonusInfo._val then
            break
        end
    end
    self._curIndex = self._defaultIndex
    self._iconNode = lc.createNode()
    lc.addChildToPos(self._form, self._iconNode, cc.p(lc.cw(self._form), 275))

    local btnArrowLeft = V.createArrowButton(true, cc.size(100, 100), function(sender) self:onBtnArrow(sender) end)
    btnArrowLeft:setVisible(false)
    lc.addChildToPos(self._form, btnArrowLeft, cc.p(100, 290))
    self._btnArrowLeft = btnArrowLeft

    local btnArrowRight = V.createArrowButton(false, cc.size(100, 100), function(sender) self:onBtnArrow(sender) end)
    lc.addChildToPos(self._form, btnArrowRight, cc.p(FORM_SIZE.width - 100, 290))
    self._btnArrowRight = btnArrowRight

    self:refreshIcons()
    

    local progressBar = V.createLabelProgressBar(FORM_SIZE.width - 300, nil, V.COLOR_TEXT_WHITE, V.COLOR_TEXT_BLUE)
    lc.addChildToPos(self._form, progressBar, cc.p(V.FRAME_INNER_LEFT + 30 + lc.cw(progressBar), 100))
    progressBar._bar:setPercent(chargeIngot / self._bonusInfo._val * 100)
    progressBar:setLabel(chargeIngot, self._bonusInfo._val)
    self._progressBar = progressBar

    local rechargeBtn = V.createScale9ShaderButton("img_btn_3", function()
        lc.pushScene(require("RechargeScene").create())
        self:hide()
        end, V.CRECT_BUTTON, 150)
    lc.addChildToPos(self._form, rechargeBtn, cc.p(lc.right(progressBar) + 120, lc.y(progressBar) + 15))
    rechargeBtn:addLabel(Str(STR.RECHARGE))

    local tip = self:createVipTip()
    lc.addChildToPos(self._form, tip, cc.p(lc.x(progressBar), 150))
    self._tip = tip

end

function _M:refreshIcons()
    local iconNode = self._iconNode
    iconNode:removeAllChildren()
    local bonusId = self._bonusIds[self._curIndex]
    self._curBonusInfo = Data._bonusInfo[bonusId]
    local icons = {}
    for i, id in ipairs(self._curBonusInfo._rid) do
        local icon = IconWidget.create({_infoId = id, _count = self._curBonusInfo._count[i]})
        icon._name:setColor(V.COLOR_TEXT_WHITE)
        table.insert(icons, icon)
    end
    lc.addNodesToCenterH(iconNode, icons, 20)
    self._btnArrowLeft:setVisible(self._curIndex > self._defaultIndex)
    self._btnArrowRight:setVisible(self._curIndex < math.min(self._defaultIndex + 2, #self._bonusIds))
end

function _M:refreshProgress()
    local bonusId = self._bonusIds[self._curIndex]
    self._curBonusInfo = Data._bonusInfo[bonusId]
    local chargeIngot = P._playerActivity._chargeIngot
    local progressBar = self._progressBar
    progressBar._bar:setPercent(chargeIngot / self._curBonusInfo._val * 100)
    progressBar:setLabel(chargeIngot, self._curBonusInfo._val)

    self._tip:removeFromParent()
    self._tip = self:createVipTip()
    lc.addChildToPos(self._form, self._tip, cc.p(lc.x(progressBar), 150))
end

function _M:onBtnArrow(sender)
    if sender == self._btnArrowLeft then
        if self._curIndex <= self._defaultIndex then
            return
        end
        self._curIndex = self._curIndex - 1
    else
        if self._curIndex >= math.min(self._defaultIndex + 2, #self._bonusIds) then
            return
        end
        self._curIndex = self._curIndex + 1
    end
    
    self:refreshIcons()
    self:refreshProgress()
end

function _M:createVipTip()
    local bonusId = self._bonusIds[self._curIndex]
    self._curBonusInfo = Data._bonusInfo[bonusId]
    local chargeIngot = P._playerActivity._chargeIngot
    local targetIngot = self._curBonusInfo._val
    local richText = ccui.RichTextEx:create()
    if chargeIngot < targetIngot then
        richText:insertElement(ccui.RichItemText:create(0, V.COLOR_TEXT_LIGHT, 255, Str(STR.RECHARGE_AGAIN), V.TTF_FONT, V.FontSize.S1))
        richText:insertElement(ccui.RichItemText:create(0, V.COLOR_TEXT_INGOT, 255, string.format(" %d ", targetIngot - chargeIngot), V.TTF_FONT, V.FontSize.S1))
        richText:insertElement(ccui.RichItemCustom:create(0, lc.Color3B.white, 255, lc.createSprite(string.format("img_icon_res%d_s", Data.ResType.ingot))))
        richText:insertElement(ccui.RichItemText:create(0, V.COLOR_TEXT_LIGHT, 255, " "..Str(STR.CAN_CLAIM), V.TTF_FONT, V.FontSize.S1))
    else
        richText:insertElement(ccui.RichItemText:create(0, V.COLOR_TEXT_LIGHT, 255, Str(STR.ALL_CLAIMED), V.TTF_FONT, V.FontSize.S1))
    end
    
    richText:formatText()
    return richText        
end



function _M:onEnter()
    _M.super.onEnter(self)

    self._listeners = {}
end

function _M:onExit()
    _M.super.onExit(self)

    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
end

function _M:onCleanup()
    lc.TextureCache:removeTextureForKey("res/jpg/cumulative_recharge_bg.jpg")
end

return _M