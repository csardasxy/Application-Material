local _M = class("RechargeScene", require("BaseUIScene"))

local SMALL_IAP_MAX_COUNT = 5
local pos_center_x = V.SCR_CW + 120 * ((V.SCR_W - 1024) / (1366 - 1024))

local vipMax = function()
    return #Data._globalInfo._vipIngot - 2
end

function _M.create(...)
    return lc.createScene(_M, ...)
end

function _M:init()
    if not _M.super.init(self, ClientData.SceneId.recharge, STR.RECHARGE, require("BaseUIScene").STYLE_TAB, false) then return false end

    --bg
    --self._bg:setTexture("res/jpg/recharge_bg.jpg")
    
    --girl
    local girl = lc.createSpriteWithMask("res/jpg/girl_recharge.jpg")
    lc.addChildToPos(self._bg, girl, cc.p(lc.cw(self._bg) - V.SCR_CW + lc.cw(girl) - 100, V.SCR_CH - 40))

    --ui
    self:initPurchase()
    self:initVip()

    if ClientData.isAndroidTest0602() then
        local label = V.createTTF(Str(STR.ANDROID_TEST_TIP_1), V.FontSize.S)
        lc.addChildToPos(self, label, cc.p(lc.cw(self), lc.ch(label) + 10))
    end

    return true
end

function _M:onEnter()
    _M.super.onEnter(self) 

    local events = {
        Data.Event.vip_dirty,
        Data.Event.vip_exp_dirty, 
        }
    
    self._listeners = {}
    for i = 1, #events do
        local listener = lc.addEventListener(events[i], function(event) self:onEvent(events[i]) end)
        table.insert(self._listeners, listener)        
    end
end

function _M:onExit()
    _M.super.onExit(self)

    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end

    V.getMenuUI():updateActivityFlag()
end

function _M:onCleanup()
    _M.super.onCleanup(self)

    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/recharge_bg.jpg"))
end

function _M:initPurchase()
    -- items
    local indices = {
        Data.PurchaseType.product_1,
        Data.PurchaseType.product_2,
        Data.PurchaseType.product_3,
        Data.PurchaseType.product_4,
        Data.PurchaseType.product_5,
        Data.PurchaseType.product_6
    }

    local marginX = 20
    local marginY = 50
    local centerPos = cc.p(pos_center_x, V.SCR_CH - 110)

    self._purchaseItems = {}
    for i = 1, #indices do
        local purchaseType = indices[i]
        
        local item = self:createPurchaseItem(purchaseType)
        local pos = cc.p(centerPos.x + ((i - 1) % 3 - 1) * (lc.w(item) + marginX), centerPos.y + (0.5 - math.floor((i - 1) / 3)) * (lc.h(item) + marginY))
        lc.addChildToPos(self, item, pos)
        self._purchaseItems[i] = item
    end

    self:updatePurchaseItems()
end

function _M:createPurchaseItem(purchaseType)
    local item = V.createShaderButton("img_recharge_bg", function () self:onBuyIngot(purchaseType) end)
    
    local bones = DragonBones.create("baoshi")
    lc.addChildToPos(item, bones, cc.p(lc.cw(item), lc.ch(item) + 44))
    bones:gotoAndPlay("effect"..purchaseType)

    -- price
    local priceIcon = V.createBMFont(V.BMFont.huali_26, Str(STR.RMB))
    lc.addChildToPos(item, priceIcon, cc.p(lc.cw(priceIcon) + 20, lc.ch(priceIcon) + 28))

    local price = ClientData.getPrice(purchaseType)
    local priceLabel = V.createBMFont(V.BMFont.huali_32, price)
    lc.addChildToPos(item, priceLabel, cc.p(lc.cw(priceLabel) + 20 + lc.w(priceIcon), lc.ch(priceLabel) + 26))

    --ingot
    local ingot, gift = ClientData.getIngot(purchaseType, false)
    local ingotLabel = V.createBMFont(V.BMFont.num_48, ingot)
    lc.addChildToPos(item, ingotLabel, cc.p(lc.w(item) - lc.cw(ingotLabel) - 56, lc.ch(ingotLabel) + 14))

    local ingotIcon = lc.createSprite("img_icon_res3_s")
    lc.addChildToPos(item, ingotIcon, cc.p(lc.w(item) - lc.cw(ingotIcon) - 24, lc.ch(ingotIcon) + 22))

    local giftIcon = lc.createSprite("img_recharge_gift")
    lc.addChildToPos(item, giftIcon, cc.p(lc.w(item) - 40, lc.h(item) - 20))

    local giftLabel = V.createBMFont(V.BMFont.huali_26, gift)
    lc.addChildToPos(giftIcon, giftLabel, cc.p(lc.cw(giftIcon) + 6, lc.ch(giftIcon) - 8))
    item._giftLabel = giftLabel

    local doubleIcon = lc.createSprite(not ClientData.isAndroidTest0602() and "img_recharge_double" or "img_recharge_double_test")
    lc.addChildToPos(item, doubleIcon, cc.p(lc.w(item) - 40, lc.h(item) - 20))

    item.update = function () 
        local ingot, gift = ClientData.getIngot(purchaseType, false)

        if not ClientData.isAndroidTest0602() then
            doubleIcon:setVisible(ingot == gift)
            giftIcon:setVisible(ingot ~= gift and gift > 0)
            giftLabel:setString(gift)
        else
            doubleIcon:setVisible(true)
            giftIcon:setVisible(false)
        end
    end

    return item
end

function _M:updatePurchaseItems()
    for i = 1, #self._purchaseItems do
        local item = self._purchaseItems[i]
        item:update()
    end
end

function _M:initVip()
    local centerPos = cc.p(pos_center_x, V.SCR_CH + 220)

    local sprite = lc.createSprite({_name = "img_com_bg_46", _crect = V.CRECT_COM_BG46, _size = cc.size(810, 118)})
    lc.addChildToPos(self, sprite, centerPos)

    -- vip
    local vipBg = lc.createSprite("img_recharge_vip")
    lc.addChildToPos(self, vipBg, cc.p(centerPos.x - 300, centerPos.y + 4))

    local vipLabel = V.createBMFont(V.BMFont.huali_32, 0)
    lc.addChildToPos(vipBg, vipLabel, cc.p(lc.cw(vipBg), lc.ch(vipBg) - 24))
    self._vip = vipLabel

    --progress
    local progress = V.createLabelProgressBar(440)
    lc.addChildToPos(self, progress, cc.p(centerPos.x, centerPos.y - 24))
    self._progress = progress

    local nextVip = V.createTTF("", V.FontSize.B2)
    lc.addChildToPos(self, nextVip, cc.p(0, 0))
    nextVip:setColor(V.COLOR_TEXT_VIP)
    self._nextVip = nextVip

    --vip tip
    local btn = V.createScale9ShaderButton("img_btn_2_s", function(sender) 
            require("VIPInfoForm").create():show()
        end, V.CRECT_BUTTON_S, 120)
    lc.addChildToPos(self, btn, cc.p(centerPos.x + 306, centerPos.y))
    btn:addLabel(Str(STR.PRIVILEGE))

    self:updateVip()
end

function _M:updateVip()
    self._vip:setString(P._vip)
    self._nextVip:setString(string.format("VIP%d", P._vip + 1))
    self._progress._bar:setPercent(P._vip < vipMax() and (P._vipExp * 100 / P:getVIPupExp()) or 0)

    if self._vipTip then self._vipTip:removeFromParent() end
    self._vipTip = self:createVipTip()
    lc.addChildToPos(self, self._vipTip, cc.p(lc.left(self._progress) + lc.cw(self._vipTip) + 10, lc.y(self._progress) + 44))

    self._nextVip:setPosition(cc.p(lc.right(self._vipTip) + lc.cw(self._nextVip) + 10, lc.y(self._vipTip) - 2))
    self._nextVip:setVisible(P._vip < vipMax())
end

function _M:createVipTip(str)
    local richText = ccui.RichTextEx:create()

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
    
    richText:formatText()
    return richText        
end

function _M:onBuyIngot(type, isForce)
    if ClientData.isAppStore() and not ClientData.isAppStoreReviewing() then
        if P._playerBonus:getIapCount(type) >= SMALL_IAP_MAX_COUNT then
            require("Dialog").showDialog(string.format(Str(STR.SMALL_IAP_COUNT_EXCEED), SMALL_IAP_MAX_COUNT), nil, true)
            return
        end
    end

    V.startIAP(type)
end

function _M:onEvent(event)
    if event == Data.Event.vip_dirty or event == Data.Event.vip_exp_dirty then
        self:updateVip()
        self:updatePurchaseItems()
    end
end



return _M