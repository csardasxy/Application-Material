local _M = class("CarSkinWidget", lc.ExtendUIWidget)

function _M.create(infoId, size)
    local widget = _M.new(lc.EXTEND_LAYOUT)
    widget:init(infoId, size)
    return widget
end

function _M:init(infoId, size)
    self._infoId = infoId
    self:setContentSize(size)
    
    local list = lc.List.createV(size, 16, 20)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(self, list)
    self._list = list
end

function _M:onEnter()
    self:updateList()  
end

function _M:updateList()
    local list = self._list

    list:removeAllItems()

    local info = Data.getInfo(self._infoId)
    local skinIds = {0}
    if self._infoId ~= 10407 or P._vip >= 12 then
        for i = 1, #info._skin do
            if info._skin[i] == 0 then break end
            skinIds[#skinIds + 1] = info._skin[i]
        end
    end

    list:bindData(skinIds, function(item, skinId) self:setOrCreateItem(item, skinId) end, math.min(3, #skinIds))
    
    for i = 1, list._cacheCount do
        local item = self:setOrCreateItem(nil, skinIds[i])
        list:pushBackCustomItem(item)
    end
end

function _M:setOrCreateItem(item, skinId)    
    local info = skinId == 0 and Data.getInfo(self._infoId) or Data._skinInfo[skinId]
    local canUse, availableSkin = P._playerCard:hasSkin(skinId)
    local expireDay = (availableSkin and availableSkin._expire ~= 0) and ClientData.getExpireDay(availableSkin._expire) or 0
    local isUsing = P._playerCard:getSkinId(self._infoId) == skinId
    local price = skinId == 0 and 0 or info._price
    
    if item == nil then
        item = ccui.Layout:create()
        item:setTouchEnabled(true)
        item:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)

        local bg = lc.createSpriteWithMask('res/jpg/skin_bg.jpg')
        item:setContentSize(bg:getContentSize())
        lc.addChildToCenter(item, bg)

        local frame = V.createSkinFrame(skinId, self._infoId, true)
        lc.addChildToPos(item, frame, cc.p(10 + lc.cw(frame), lc.ch(bg)))

        --local nameLabel = V.createBMFont(V.BMFont.huali_26, Str(info._nameSid))
        local nameLabel = V.createTTF(Str(info._nameSid), V.FontSize.S1)
        lc.addChildToPos(item, nameLabel, cc.p(384, lc.h(item) - 56))
        item._nameLabel = nameLabel

        local statusIcon = lc.createSprite('skin_bought')
        lc.addChildToPos(item, statusIcon, cc.p(lc.x(nameLabel), lc.ch(item) - 20))
        statusIcon:setVisible(canUse and expireDay == 0)
        item._statusIcon = statusIcon

        local expireLabel = V.createBMFont(V.BMFont.huali_26, string.format(Str(STR.SKIN_EXPIRE_IN), expireDay))
        lc.addChildToPos(item, expireLabel, cc.p(lc.x(nameLabel), lc.y(statusIcon)))
        expireLabel:setVisible(expireDay ~= 0)
        item._expireLabel = expireLabel

        local priceLabel = V.createResIconLabel(150, ClientData.getPropIconName(Data.PropsId.skin_crystal))
        priceLabel._label:setString(price)
        lc.addChildToPos(item, priceLabel, cc.p(lc.x(nameLabel) + 20, lc.y(statusIcon)))
        priceLabel:setVisible(not canUse)
        item._priceLabel = priceLabel

        local btn = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:onBtn(skinId) end, V.CRECT_BUTTON_S, 150)
        btn:addLabel(canUse and (isUsing and (Str(STR.CURRENT)..Str(STR.SELECT)) or Str(STR.SELECT)) or (Str(STR.GO)..Str(STR.BUY)))
        btn:setDisabledShader(V.SHADER_DISABLE)
        btn:setEnabled(not isUsing)
        lc.addChildToPos(item, btn, cc.p(lc.x(nameLabel), 46))
        item._btn = btn
    else
        item._image:setSpriteFrame(V.getCardImageName(self._infoId, skinId))
        item._nameLabel:setString(Str(info._nameSid))

        if canUse then
            item._statusIcon:setVisible(expireDay == 0)
            item._expireLabel:setVisible(expireDay ~= 0)
            item._priceLabel:setVisible(false)
            item._btn._label:setString(isUsing and (Str(STR.CURRENT)..Str(STR.SELECT)) or Str(STR.SELECT))
        else
            item._statusIcon:setVisible(false)
            item._expireLabel:setVisible(false)
            item._priceLabel:setVisible(true)
            item._btn._label:setString(Str(STR.GO)..Str(STR.BUY))
        end

        item._btn:setEnabled(not isUsing)
    end
        
    return item
end

function _M:onBtn(skinId)
    local info = skinId == 0 and Data.getInfo(self._infoId) or Data._skinInfo[skinId]
    local canUse = P._playerCard:hasSkin(skinId)
    local isUsing = P._playerCard:getSkinId(self._infoId) == skinId
    
    if canUse then
        if isUsing then
            
        else
            if P._playerCard:setSkinId(self._infoId, skinId) then
                ClientData.sendSetSkin(self._infoId, skinId)
                ToastManager.push(Str(STR.SET_SKIN_SUCCEED))
            else
                ToastManager.push(Str(STR.SET_SKIN_FAILED))
            end   
            P._playerCard:sendCardDirty(self._infoId)
            self:updateList() 
        end
    else
        if lc._runningScene._sceneId ~= ClientData.SceneId.skin_shop then
            V.popScene(true)
            lc.pushScene(require("SkinShopScene").create())
        end
        
    end
end

return _M