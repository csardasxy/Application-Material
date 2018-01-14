local _M = class("CardThumbnail", lc.ExtendUIWidget)

_M.pool = {}

local countAreaOffset = -194

function _M.create(infoId, scale, skinId)
    local layout = _M.new(lc.EXTEND_LAYOUT)
    layout:setAnchorPoint(0.5, 0.5)
    layout:setContentSize(V.CARD_SIZE)
    layout:setTouchEnabled(false)
    layout:createComponent(infoId, skinId)
    layout:setScaleFactor(scale)
    layout:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)
    layout:setCascadeOpacityEnabled(true)
    return layout
end

function _M:createComponent(infoId, skinId)
    self._infoId = infoId
    self._skinId = skinId
    
    self._frame = V.createCardFrame(self._infoId, nil, self._skinId)
    lc.addChildToCenter(self, self._frame, 1)
    
    self._shadow = V.createCardShadow(self._infoId)
    self._frame:addChild(self._shadow, -1)

--    self._states = V.createCardStates(self._infoId)
--    lc.addChildToCenter(self._frame, self._states)
    
end

function _M:updateComponent(infoId, skinId)
    self._infoId = infoId
    self._skinId = skinId
    
    self._frame:update(self._infoId, self._skinId)
    self._shadow:update(self._infoId)
end

function _M.createPool()
    if #_M.pool ~= 0 then return end

    for i = 1, 80 do
        local thumbnail = _M.create(10001, 1)
        thumbnail:registerScriptHandler(function(evt) 
            if evt == "enter" then thumbnail:onEnter()
            elseif evt == "exit" then thumbnail:onExit() end
        end)
        
        local item = ccui.Layout:create()
        item:addChild(thumbnail)

        -- Custom button 1
        local btnCustom1 = V.createScale9ShaderButton("img_btn_1_s", nil, V.CRECT_BUTTON_1_S, 110)
        btnCustom1:setEnabled(false)
        btnCustom1:setVisible(false)
        btnCustom1:addLabel("")
        item:addChild(btnCustom1)
        
        --- Radio button
        local buttonRadio = ccui.ShaderButton:create("img_btn_check_bg", ccui.TextureResType.plistType)
        buttonRadio:setVisible(false)
        buttonRadio:setTouchRect(cc.rect(-10, -10, lc.w(buttonRadio) + 20, lc.h(buttonRadio) + 20))
        buttonRadio:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)
        lc.addChildToPos(item, buttonRadio, cc.p(0, -136)) 
        
        buttonRadio._checkedSprite = cc.Sprite:createWithSpriteFrameName("img_icon_check")
        buttonRadio._checkedSprite:setVisible(false)
        lc.addChildToPos(buttonRadio, buttonRadio._checkedSprite, cc.p(lc.w(buttonRadio) / 2, lc.h(buttonRadio) / 2 + 8)) 
        
        -- Check button
        local buttonCheck = ccui.ShaderButton:create("img_btn_check_bg", ccui.TextureResType.plistType)
        buttonCheck:setVisible(false)    
        buttonCheck:setTouchRect(cc.rect(-10, -10, lc.w(buttonCheck) + 20, lc.h(buttonCheck) + 20)) 
        buttonCheck:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)
        lc.addChildToPos(item, buttonCheck, cc.p(0, -136)) 
        
        buttonCheck._checkedSprite = cc.Sprite:createWithSpriteFrameName("img_icon_check")
        buttonCheck._checkedSprite:setVisible(false)
        lc.addChildToPos(buttonCheck, buttonCheck._checkedSprite, cc.p(lc.w(buttonCheck) / 2, lc.h(buttonCheck) / 2 + 8))   

        -- counter area
        local countArea = lc.createSprite({_name = 'img_card_count_bg', _crect = cc.rect(26, 20, 1, 1), _size = cc.size(180, 55)})
        countArea:setAnchorPoint(0.5, 1)
        countArea:setVisible(false)
        lc.addChildToPos(item, countArea, cc.p(0, countAreaOffset), -1)
        
        local countBg = ccui.Scale9Sprite:createWithSpriteFrameName("depot_bg",cc.rect(0,0,0,0))
        countBg:setContentSize(cc.size(lc.w(countArea) - 20, lc.h(countArea) - 5))
        lc.addChildToCenter(countArea, countBg, -1)
        countBg:setVisible(false)
        countArea._bg = countBg

        --[[
        local progressBg = lc.createSprite('img_card_count_bg_02')
        lc.addChildToPos(countArea, progressBg, cc.p(lc.w(countArea) / 2, 18), -1)
        countArea._bg = progressBg

        local progressBar = ccui.LoadingBar:create()
        progressBar:loadTexture("img_card_count_fg", ccui.TextureResType.plistType)
        progressBar:setDirection(ccui.LoadingBarDirection.LEFT)
        lc.addChildToCenter(progressBg, progressBar)
        progressBar:setScale9Enabled(true)
        progressBar:setCapInsets(cc.rect(0, 0, 1, 25))
        progressBar:setContentSize(progressBg:getContentSize())
        progressBar:setPercent(0)
        countArea._bar = progressBar
        ]]

        local countLabel = V.createBMFont(V.BMFont.huali_26, "x1")
        -- fix later
        lc.addChildToPos(countArea, countLabel, cc.p(lc.w(countArea) / 2, lc.h(countArea) / 2))
        countArea._label = countLabel
        countArea.update = function(self, visible, count, totalCount, specificCount, ownCount)
            if not ownCount then ownCount =  P._playerCard:getCardCount(item._thumbnail._infoId) end
            item._thumbnail._count = count
            if count ~= nil and totalCount ~= nil and (count >= totalCount or (specificCount ~= nil and specificCount >= ownCount)) then
                --self._bg:setVisible(false)
                self._label:setString(lc.str(count >= totalCount and STR.USE_LIMITED or STR.USED_OUT))
                self._label:setPosition(lc.w(self) / 2, 26)
                item._thumbnail:setGray(true)
                item._locked = true
            else
                if count and totalCount then    
                    self._label:setString(count..'/'..ownCount)
                elseif count then
                    self._label:setString('x'..count)
                else
                    self._label:setString('x'..ownCount)
                end

                --[[
                self._bg:setVisible(true)
                if count and totalCount then    
                    self._label:setString(count..'/'..totalCount)
                    self._bar:setPercent(0)
                elseif count then 
                    self._label:setString('x'..count)
                    self._bar:setPercent(0)
                else
                    local cardCount, upgradeCount = P._playerCard:getCardCount(item._thumbnail._infoId), P._playerCard:getUpgradeCount(item._thumbnail._infoId)
                    if upgradeCount > 0 then
                        self._label:setString(cardCount..'/'..upgradeCount)
                        self._bar:setPercent(cardCount * 100 / upgradeCount)
                    else
                        self._label:setString('x'..cardCount)
                        self._bar:setPercent(100)
                    end
                end
                ]]
                self._label:setPosition(lc.w(self) / 2, 26)
                item._thumbnail:setGray(false)
                item._locked = false
            end
            self:setVisible(visible)
            self:setScale(item._thumbnail._scale / 0.6)
            self:setPosition(cc.p(0, item._thumbnail._scale / 0.6 * countAreaOffset + 6))
        end
        countArea.updateDetermined = function (self, visible, count, totalCount)
            self._label:setString(count..'/'..totalCount)

            if count == 0 then
                item._thumbnail:setGray(true)
                item._locked = true
            else
                item._thumbnail:setGray(false)
                item._locked = false
            end

            self._label:setScale(0.9)
            self._label:setPosition(lc.w(self) / 2, 22)

            self:setVisible(visible)
            self:setScale(item._thumbnail._scale / 0.6)
            self:setPosition(cc.p(0, item._thumbnail._scale / 0.6 * countAreaOffset + 10))
        end

        -- multi select area
        local multiSelectArea = lc.createSprite({_name = "img_com_bg_26", _crect = V.CRECT_COM_BG26, _size = cc.size(159, 36)})
        multiSelectArea:setVisible(false)
        lc.addChildToPos(item, multiSelectArea, cc.p(0, -132))
        local counterLabel = V.createBMFont(V.BMFont.huali_26, "0")
        lc.addChildToCenter(multiSelectArea, counterLabel)
        multiSelectArea._label = counterLabel
        local btnAdd = V.createShaderButton("img_btn_squarel_s_2", 
            function(sender) if multiSelectArea._callbackAdd then multiSelectArea._callbackAdd(d)end  end
        )
        lc.addChildToPos(btnAdd, lc.createSprite("img_icon_add"), cc.p(lc.w(btnAdd) / 2, lc.h(btnAdd) / 2 + 1))
        lc.addChildToPos(multiSelectArea, btnAdd, cc.p(lc.w(multiSelectArea) - lc.w(btnAdd) / 2, lc.h(multiSelectArea) / 2))
        local btnMinus = V.createShaderButton("img_btn_squarel_s_2", 
            function(sender) if multiSelectArea._callbackMinus then multiSelectArea._callbackMinus() end  end
        )
        lc.addChildToPos(btnMinus, lc.createSprite("img_icon_minus"), cc.p(lc.w(btnMinus) / 2, lc.h(btnMinus) / 2 + 1))
        lc.addChildToPos(multiSelectArea, btnMinus, cc.p(lc.w(btnMinus) / 2, lc.h(multiSelectArea) / 2))
        multiSelectArea._btnAdd = btnAdd
        multiSelectArea._btnMinus = btnMinus

        -------------------------- sprite mixable ------------------------------------------------------------        
        local statusRect = V.createStatusLabel("", V.COLOR_TEXT_GREEN)
        statusRect:setVisible(false)
        lc.addChildToCenter(thumbnail, statusRect)
        -------------------------- sprite mixable ------------------------------------------------------------        

        item.showStatusRect = function(item, isShow, label, color, pos, rotation)
            statusRect:setVisible(isShow)
            if isShow then
                statusRect:setRotation(rotation or 0)
                statusRect:setColor(color or V.COLOR_TEXT_GREEN)
                statusRect:setPosition(pos or cc.p(lc.w(thumbnail) / 2, lc.h(thumbnail) / 2))

                statusRect._label:setString(label)
                statusRect._label:setColor(statusRect:getColor())
            end 
        end

        thumbnail._item = item
        item._thumbnail = thumbnail

        btnCustom1:setDisabledShader(V.SHADER_DISABLE)

        item._btnCustom1 = btnCustom1
        item._btnRadio = buttonRadio
        item._btnCheck = buttonCheck
        item._countArea = countArea
        item._multiSelectArea = multiSelectArea
        item._statusRect = statusRect
        item._listeners = {}
        item:retain()
        item._isBusy = false
        item._poolIndex = i
        table.insert(_M.pool, item)
    end
end

function _M.releasePool()
    for i, item in ipairs(_M.pool) do
        item._thumbnail:unregisterScriptHandler()
        for i = 1, #item._listeners do lc.Dispatcher:removeEventListener(item._listeners[i]) end
        item._listeners = {}
        item:removeAllChildren()
        item:release()
    end
    _M.pool = {}
end

function _M.createFromPool(infoId, scale, skinId)
    --[[
    local count = 0
    for i, item in ipairs(_M.pool) do
        if not item._isBusy then count = count + 1 end
    end
    print ('############ create', count)
    ]]

    local freeItem
    for i, item in ipairs(_M.pool) do
        if not item._isBusy then
            item._isBusy = true
            item._sceneId = (lc._runningScene and lc._runningScene._sceneId or 0)
            
            if infoId ~= nil then
                item._thumbnail:updateComponent(infoId, skinId)
            end

            item._thumbnail:setScaleFactor(scale)
            item._thumbnail:setVisible(true)

            item._thumbnail:setGray(false)
            item._countArea:setPositionY(item._thumbnail._scale / 0.6 * countAreaOffset)

            item._listeners = {}
            
            local listener = lc.addEventListener(Data.Event.card_select, function(event)
                if item._thumbnail._infoId == event._infoId then
                    if item._btnRadio:isVisible() then
                        item._btnRadio._checkedSprite:setVisible(event._count > 0)
                    end
                    if item._btnCheck:isVisible() then
                        item._btnCheck._checkedSprite:setVisible(event._count > 0)
                    end
                end
            end)
            table.insert(item._listeners, listener)

            freeItem = item
            break
        end
    end

    if freeItem == nil then
        -- something wrong
        local sceneIds = ""
        for _, item in ipairs(_M.pool) do
            if item._isBusy then
                sceneIds = sceneIds..tostring(item._sceneId)..","
            end
        end
        lc.log(sceneIds)
        ClientData.sendUserEvent({err_debug = 1, sceneIds = sceneIds})
    end
    
    --print ('[CardThumbnailPool] create', freeItem._poolIndex, infoId)

    return freeItem
end

function _M.releaseToPool(item)
    --[[
    local count = 0
    for i, item in ipairs(_M.pool) do
        if not item._isBusy then count = count + 1 end
    end
    print ('############ release', count)
    ]]

    item:removeFromParent()
    item._isBusy = false
    item._sceneId = nil
    
    for i = 1, #item._listeners do lc.Dispatcher:removeEventListener(item._listeners[i]) end
    item._listeners = {}

    item:setVisible(true)
        
    item._thumbnail:setScaleFactor(1)
    item._thumbnail:setTouchEnabled(false)
    item._thumbnail:setOpacity(255)
    
    item._btnCustom1:setEnabled(false)
    item._btnCustom1:setVisible(false)
    item._btnCustom1:setContentSize(lc.w(item._btnCustom1), V.CRECT_BUTTON.height)    
    item._btnCustom1._callback = nil
    if item._btnCustom1._resIcon then
        item._btnCustom1._resIcon:removeFromParent()
        item._btnCustom1._resIcon = nil
    end
    
    item._btnRadio:setEnabled(false)
    item._btnRadio:setVisible(false)
    item._btnRadio._checkedSprite:setVisible(false)
    item._btnRadio._card = nil
    
    item._btnCheck:setEnabled(false)
    item._btnCheck:setVisible(false)
    item._btnCheck._checkedSprite:setVisible(false)
    item._btnCheck._card = nil

    item._countArea:setVisible(false)
    item._countArea._bg:setVisible(false)

    item._multiSelectArea:setVisible(false)
    item._multiSelectArea._callbackAdd = nil
    item._multiSelectArea._callbackMinus = nil
        
    item._statusRect:setVisible(false)

    if item._thumbnail._newFlag then
        item._thumbnail._newFlag:removeFromParent()
        item._thumbnail._newFlag = nil
    end

    if item._thumbnail._discountFlag then
        item._thumbnail._discountFlag:removeFromParent()
        item._thumbnail._discountFlag = nil
    end

    item._thumbnail:setGray(false)

    --print ('[CardThumbnailPool] release', item._poolIndex, item._thumbnail._infoId)
end

function _M:onEnter()
    self._listeners = {}

    local listener = lc.addEventListener(Data.Event.card_dirty, function(event)
        if event._infoId == self._infoId then 
            self._skinId = P._playerCard:getSkinId(self._infoId)
            self:updateComponent(self._infoId, self._skinId) end
    end)
    table.insert(self._listeners, listener)
end

function _M:onExit()
    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
    self._listeners = {}

    if self._newBones ~= nil then
        self._newBones:removeFromParent()
        self._newBones = nil
    end
end

function _M:setScaleFactor(scale)    
    self._scale = (scale and scale or 1)
    self:setContentSize(cc.size(V.CARD_SIZE.width * self._scale, V.CARD_SIZE.height * self._scale))
    
    local center = cc.p(lc.w(self) / 2, lc.h(self) / 2)
    self._frame:setPosition(center)
    
    self._frame:setScale(self._scale)

end

function _M:getMaxSize()
    return V.CARD_SIZE
end

function _M:updateFlag()
    local flag = V.checkNewFlag(self, P._playerCard:isUnlocked(self._infoId), 40 - 50 * self._scale, 10 - 260 * self._scale)
    if flag then 
        flag:setLocalZOrder(2)
        flag:setSpriteFrame("img_new_l") 
        flag:setScale(1)
    end

    if flag then
        if self._newBones == nil then
            self._newBones = require("DragonBones").create("xuanzhong")
            self._newBones:gotoAndPlay("effect1")
            lc.addChildToCenter(self, self._newBones, -1)
        end
    else
        if self._newBones ~= nil then
            self._newBones:removeFromParent()
            self._newBones = nil
        end
    end
end

function _M:updateUnionShopFlag(count, totalCount, price, priceType, disCount)
    local countArea = self._item._countArea
    countArea:setVisible(true)
    countArea._bg:setVisible(true)
    countArea._label:setString(count..'/'..totalCount)
    countArea._label:setPositionY(lc.ch(countArea._bg) + 4)
    countArea:setScale(self._item._thumbnail._scale / 0.6)
    countArea:setPosition(cc.p(0, self._item._thumbnail._scale / 0.6 * countAreaOffset))
    local flag = nil
    
    if disCount==0 then
        if self._discountFlag then
            self._discountFlag:removeFromParent()
            self._discountFlag = nil
        end
        flag = V.checkNewFlag(self, true, 40 - 50 * self._scale, 10 - 260 * self._scale)
        if flag then 
            flag:setLocalZOrder(2)
            flag:setSpriteFrame("discount_bg_new") 
        end
    else
        if self._newFlag then
            self._newFlag:removeFromParent()
            self._newFlag = nil
        end
        flag = V.checkDiscountFlag(self, disCount, 40 - 50 * self._scale, 10 - 260 * self._scale)
        if flag then 
            flag:setLocalZOrder(2)
        end
    end

    if count >= totalCount then
        self._item._countArea._label:setString(Str(STR.UNION_SHOP_OWN))
        --self._frame._frame:setEffect(V.SHADER_DISABLE)
        --self._frame:setEffect(V.SHADER_DISABLE)
    end
    
    self._item._btnCustom1:setEnabled(true)
--    self._item._btnCustom1:setEnabled(count<totalCount and price<P:getItemCount(priceType))
end

function _M:updateRareShopFlag(count, totalCount, price, priceType, hasBought)
    local countArea = self._item._countArea
    countArea:setVisible(true)
    countArea._bg:setVisible(true)
--    countArea._label:setString(count..'/'..totalCount)
    countArea._label:setPositionY(lc.ch(countArea._bg) + 4)
    countArea:setScale(self._item._thumbnail._scale / 0.6)
    countArea:setPosition(cc.p(0, self._item._thumbnail._scale / 0.6 * countAreaOffset))
    if hasBought then
        self._item._countArea._label:setString(Str(STR.PURCHASED))
    elseif count >= totalCount then
        self._item._countArea._label:setString(Str(STR.UNION_SHOP_OWN))
    else
        self._item._countArea._label:setString("0/1")
    end
    
    self._item._btnCustom1:setEnabled(true)
end

function _M:updateDiamondShopFlag(count, totalCount, price, priceType)
    local countArea = self._item._countArea
    countArea:setVisible(true)
    countArea._bg:setVisible(true)
    countArea._label:setString(count..'/'..totalCount)
    countArea._label:setPositionY(lc.ch(countArea._bg) + 4)
    countArea:setScale(self._item._thumbnail._scale / 0.6)
    countArea:setPosition(cc.p(0, self._item._thumbnail._scale / 0.6 * countAreaOffset))

    self._item._btnCustom1:setEnabled(true)
end

function _M:setGray(isGray)
    self._frame._frame:setEffect(isGray and V.SHADER_DISABLE or (self._infoId and V.getCardShader(self._infoId) or nil))
    self._frame:setEffect(isGray and V.SHADER_DISABLE or nil)
    self._frame._evolutionIcon:setEffect(isGray and V.SHADER_DISABLE or nil)
    self._frame._weaknessIcon:setEffect(isGray and V.SHADER_DISABLE or nil)
    self._frame._resistIcon:setEffect(isGray and V.SHADER_DISABLE or nil)
    self._frame._quality:setEffect(isGray and V.SHADER_DISABLE or nil)
    self._frame._evolutionBg:setEffect(isGray and V.SHADER_DISABLE or nil)
--    if isGray then
--        self._frame._frame:setEffect(V.SHADER_DISABLE)
--        self._frame:setEffect(V.SHADER_DISABLE)
--    end
end

return _M