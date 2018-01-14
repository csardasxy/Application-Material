local _M = class("ActivityForm", BaseForm)

local FORM_SIZE = cc.size(1000, 660)

function _M.create(activities, index)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(activities, index)
    return panel    
end

function _M:init(activities, index)
    _M.super.init(self, FORM_SIZE, nil, nil, true)

    index = index or 1
    local purchaseType = activities[index]

    ClientData.setActivityShowed(purchaseType)
    
    -- ui
    local layer = cc.Node:create()
    layer:setContentSize(cc.size(1116, 708))
    layer:setAnchorPoint(cc.p(0.5, 0.5))
    lc.addChildToCenter(self._frame, layer, -1)

    local ActivityScene = require("ActivityScene")
    if purchaseType >= Data.PurchaseType.limit_1 and purchaseType <= Data.PurchaseType.limit_5 then
        ActivityScene.createLimitLarge(purchaseType, layer, false)
        layer:setScale((lc.w(self._frame) - 40) / lc.w(layer._bg))
    elseif purchaseType == Data.PurchaseType.return_to_game then
        ActivityScene.createReturnPackage(layer, false)
        layer:setScale((lc.w(self._frame) - 40) / lc.w(layer._bg))
    elseif purchaseType == Data.PurchaseType.ad_recharge then
        ActivityScene.createAdRecharge(layer)
        layer:setScale((lc.w(self._frame) - 40) / lc.w(layer._bg))
    elseif purchaseType == Data.PurchaseType.ad_package then
        ActivityScene.createAdPackage(layer)
        layer:setScale((lc.w(self._frame) - 40) / lc.w(layer._bg))
    end

    -- touch
    if not (purchaseType >= Data.PurchaseType.limit_3 and purchaseType <= Data.PurchaseType.limit_5) then
        local layout = V.createShaderButton(nil, function() 
            self:jumpToBuy(purchaseType)
        end)
        layout:setContentSize(self._frame:getContentSize())
        layout:setAnchorPoint(cc.p(0.5, 0.5))
        lc.addChildToCenter(self._frame, layout, -1)
    end

    self._btnBack._callback = function ()
        self:jumpToNext(activities, index)
    end
end

function _M:onCleanup()
    _M.super.onCleanup(self)
    
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_limit_large_01.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_limit_large_02.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_limit_large_03.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_limit_large_04.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_limit_large_05.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_return.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_recharge.jpg"))
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/activity_package.jpg"))
    
    ClientData.unloadLCRes(self._resNames)
end


function _M:jumpToBuy(purchaseType)
    local ActivityScene = require("ActivityScene")
    if purchaseType == Data.PurchaseType.limit_1 then
        self:hide()
        lc.pushScene(ActivityScene.create(ActivityScene.Tab.limit_large_01))
    elseif purchaseType == Data.PurchaseType.limit_2 then 
        self:hide()
        lc.pushScene(ActivityScene.create(ActivityScene.Tab.limit_large_02))
    elseif purchaseType == Data.PurchaseType.return_to_game then 
        self:hide()
        lc.pushScene(ActivityScene.create(ActivityScene.Tab.return_to_game))
    elseif purchaseType == Data.PurchaseType.ad_recharge then 
        self:hide()
        lc.pushScene(ActivityScene.create(ActivityScene.Tab.first_recharge))
    elseif purchaseType == Data.PurchaseType.ad_package then 
        self:hide()
        lc.pushScene(ActivityScene.create(ActivityScene.Tab.package))
    end
end

function _M:jumpToNext(activities, index)
    self:hide()
    if index < #activities then
        require("ActivityForm").create(activities, index + 1):show()
    end
end

return _M