local _M = ClientView


function _M.createShaderButton(name, callback, x, y)
    name = name or "img_blank"
    local isBlank = (name == "img_blank")
    local isFile = string.find(name, "%.")
    local btn = ccui.ShaderButton:create(name, isFile and ccui.TextureResType.localType or ccui.TextureResType.plistType)

    -- Must use scale9 enabeld to make the shader button as a container which content size should be set by caller
    if isBlank then
        btn:setScale9Enabled(true)
        btn:setCapInsets(cc.rect(0, 0, 2, 2))
    end

    if x then btn:setPositionX(x) end
    if y then btn:setPositionY(y) end

    btn:setZoomScale(0.05)
    if not isFile then btn:setPressedShader(_M.SHADER_PRESS) end
    btn:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)

    btn.setDisplayFrame = function(self, name)
        local size = self:getContentSize()
        self:loadTextureNormal(name, ccui.TextureResType.plistType)
        self:setContentSize(size)
    end

    -- Label function
    btn.addLabel = function(self, labelStr, color)
        local label = _M.createTTFBold(labelStr, _M.FontSize.S2)
        label:enableOutline(V.COLOR_DARK_OUTLINE, 2)
        if color then label:setColor(color) end
        lc.addChildToPos(self, label, cc.p(lc.w(self) / 2, lc.h(self) / 2 + 1))
        self._label = label

        if self._icon then
            lc.offset(label, 16)
            self._icon:setPositionX(30)
        end
    end

    btn.addIcon = function(self, iconName)
        local icon = lc.createSprite(iconName)
        lc.addChildToPos(self, icon, cc.p(lc.w(self) / 2, lc.h(self) / 2 + 1))
        self._icon = icon

        if self._label then
            lc.offset(self._label, 16)
            icon:setPositionX(30)
        end
    end

    btn.removeIcon = function(self)
        if self._icon then
            self._icon:removeFromParent()
            self._icon = nil

            if self._label then
                self._label:setPositionX(lc.w(self) / 2)
            end
        end
    end

    btn.supportLongPress = function(self, isLongPress)
        local call = function(boost)
            lc.Audio.playAudio(AUDIO.E_BUTTON_DEFAULT)
            if self._callback then self._callback(self, boost) end
        end

        if isLongPress then
            self:addTouchEventListener(function(sender, evt)
                if evt == ccui.TouchEventType.began then
                    local longPressTimer = 0.5
                    self._longPressTime = 0
                    self._isLongPressing = nil

                    self._longPressID = lc.Scheduler:scheduleScriptFunc(function(dt)
                        self._longPressTime = self._longPressTime + dt    
                        if self._isLongPressing then
                            call(math.min(10, math.floor(self._longPressTime - longPressTimer)))
                        else
                            if self._longPressTime >= longPressTimer then
                                self._isLongPressing = true
                                call(0)
                            end
                        end
                    end, 0.1, false)

                elseif evt == ccui.TouchEventType.ended or evt == ccui.TouchEventType.canceled then
                    if self._longPressID then
                        lc.Scheduler:unscheduleScriptEntry(self._longPressID)
                        self._longPressID = nil
                    end

                    if evt == ccui.TouchEventType.ended and not self._isLongPressing then
                        call(0)
                    end
                end
            end)
        else
            self:addTouchEventListener(function(sender, evt)
                if evt == ccui.TouchEventType.ended then
                    call()
                end
            end)
        end
    end

    btn._callback = callback
    btn:supportLongPress(false)

    return btn
end

function _M.createScale9ShaderButton(name, callback, crect, w, h)
    local btn = _M.createShaderButton(name, callback)
    btn:setScale9Enabled(true)
    btn:setCapInsets(crect)
    btn:setContentSize(w or 0, h or crect.height)

    return btn
end

function _M.createChargeButton(w, form)
    local btnBuy = _M.createScale9ShaderButton("img_btn_3_s", function()
        if form then form:hide() end
        lc.pushScene(require("RechargeScene").create())
    end, _M.CRECT_BUTTON_S, w)
    btnBuy:addLabel(Str(STR.RECHARGE))
    btnBuy._label:setPositionX(w / 2 + 16)

    local bones = cc.DragonBonesNode:createWithDecrypt("res/effects/tili.lcres", "tili", "tili")
    bones:gotoAndPlay("effect3")
    lc.addChildToPos(btnBuy, bones, cc.p(26, lc.y(btnBuy._label)))

    return btnBuy
end

function _M.createResConsumeButton(w, resW, iconName, resLabel, btnLabel, btnName)
    local btn = _M.createScale9ShaderButton(btnName or "img_btn_1_s", nil, _M.CRECT_BUTTON_1_S, w, _M.CRECT_BUTTON_1_S.height)

    local label = _M.createTTFBold(btnLabel, _M.FontSize.S3)
    label:enableOutline(V.COLOR_DARK_OUTLINE, 1)
    lc.addChildToPos(btn, label, cc.p(lc.w(btn) / 2, lc.h(btn) / 2 - 1))
    btn._label = label

    local resArea = _M.createResIconLabel(resW, iconName, lc.Color3B.black)
    resArea:setOpacity(0)
    resArea._label:setString(resLabel)
    if type(resLabel) == "number" and resLabel <= 0 then
        lc.offset(resArea._label, -26)
    end

    lc.offset(btn._label, -resW / 2 + 2, 0)
    lc.addChildToPos(btn, resArea, cc.p(w - lc.w(resArea) / 2, lc.y(btn._label)))

    btn._resArea = resArea
    btn._resLabel = resArea._label
    
    return btn
end

function _M.createLabelButton(btnName, label, callback, pos)
    local button = _M.createShaderButton(btnName, callback)
    button:setTouchRect(cc.rect(-10, -10, lc.w(button) + 20, lc.h(button) + 20))

    local labelStr = _M.createBMFont(_M.BMFont.huali_26, label.str)
    lc.addChildToPos(button, labelStr, cc.p(lc.w(button) / 2, label.offY and label.offY or 0))

    if label.clr then labelStr:setColor(label.clr) end
    if pos then button:setPosition(pos) end
    button.label = label
    button._labelStr = labelStr
    
    return button
end

function _M.createArrowButton(isLeft, size, callback)
    local arrow = lc.createSprite("img_page_right")
    local btnW = size.width
    local btnH = size.height

    local btn = _M.createShaderButton(nil, callback)
    btn:setContentSize(btnW, btnH)
    btn:setTouchRect(cc.rect(0, -20, btnW, btnH + 40))

    arrow:setFlippedX(isLeft)

    local offX, duration = (isLeft and -6 or 6), lc.absTime(0.8)
    arrow:runAction(lc.rep(lc.sequence(lc.moveBy(duration, offX, 0), lc.moveBy(duration, -offX, 0))))
    lc.addChildToPos(btn, arrow, cc.p(btnW / 2 - offX / 2, btnH / 2))

    btn._arrow = arrow
    return btn
end

function _M.addVerticalTabButtons(parent, tabStrs, top, left, height, TAB_HEIGHT)
    local TAB_WIDTH = 159
    TAB_HEIGHT = TAB_HEIGHT or (96 + 20)
    
    local tabArea = lc.List.createV(cc.size(TAB_WIDTH, height or top), 0, 0)
    lc.addChildToPos(parent, tabArea, cc.p(left, top - lc.h(tabArea)))
    parent._tabArea = tabArea

    local innerH = #tabStrs * TAB_HEIGHT
    local inner = ccui.Widget:create()
    inner:setContentSize(lc.w(tabArea), innerH)
    tabArea:pushBackCustomItem(inner)

    if innerH < lc.h(tabArea) then
        tabArea:setBounceEnabled(false)
    end

    tabArea.showTab = function(self, tabIndex)
        if self._focusTabIndex then
            self:unfocusTab(self._focusTabIndex)
        end

        self._focusTabIndex = tabIndex

        local btn = self._tabs[self._focusTabIndex]
        btn:loadTextureNormal("img_btn_tab_bg_focus_1", ccui.TextureResType.plistType)
        btn:setEnabled(false)
        btn:setSwallowTouches(false)

        --performWithDelay(self, function() self:gotoPos(lc.right(btn) - lc.w(self)) end, 0)
    end

    tabArea.unfocusTab = function(self, tabIndex)
        local lastBtn = self._tabs[tabIndex]
        lastBtn:loadTextureNormal("img_btn_tab_bg_unfocus_1", ccui.TextureResType.plistType)
        lastBtn:setEnabled(true)
        lastBtn:setSwallowTouches(true)
    end

    tabArea.insertTab = function(self, index, label)
        local button = _M.createShaderButton("img_btn_tab_bg_unfocus_1", function(sender)
            if parent.showTab then
                parent:showTab(sender._index)
            else
                tabArea:showTab(sender._index)
            end
        end)
        button:setAnchorPoint(0, 0.5)
        button:addLabel(label)
        button:setZoomScale(0)
        inner:addChild(button, -index - 1)        
        table.insert(tabArea._tabs, index, button)

        for i, tab in ipairs(tabArea._tabs) do
            tab._index = i
        end

        if self._focusTabIndex and self._focusTabIndex >= index then
            self._focusTabIndex = self._focusTabIndex + 1
        end

        self:updateTabsPos()

        return button
    end

    tabArea.updateTabsPos = function(self)
        local count = 0
        for _, tab in ipairs(self._tabs) do
            if tab:isVisible() then
                count = count + 1
            end
        end

        local innerH = count * TAB_HEIGHT

        inner:setContentSize(lc.w(tabArea), innerH)
        self:setBounceEnabled(innerH > lc.h(self))
        self:refreshView()

        local lastY = innerH
        for _, tab in ipairs(self._tabs) do
            if tab:isVisible() then
                tab:setPosition(0, lastY - lc.h(tab) / 2)
                lastY = lastY - TAB_HEIGHT
            end
        end
    end

    tabArea._tabs = {}
    for i, str in ipairs(tabStrs) do
        local tab = tabArea:insertTab(i, str)
    end
    tabArea:updateTabsPos()
end

function _M.createIllustrationTabs(parent, tabStrs, top, left, height, TAB_HEIGHT)
    local TAB_WIDTH = 159
    TAB_HEIGHT = TAB_HEIGHT or (96 + 20)
    
    local tabArea = lc.List.createV(cc.size(TAB_WIDTH, height or top), 0, 0)
    lc.addChildToPos(parent, tabArea, cc.p(left, top - lc.h(tabArea)))
    parent._tabArea = tabArea

    local innerH = #tabStrs * TAB_HEIGHT
    local inner = ccui.Widget:create()
    inner:setContentSize(lc.w(tabArea), innerH)
    tabArea:pushBackCustomItem(inner)

    if innerH < lc.h(tabArea) then
        tabArea:setBounceEnabled(false)
    end

    tabArea.showTab = function(self, tabIndex)
        if self._focusTabIndex then
            self:unfocusTab(self._focusTabIndex)
        end

        self._focusTabIndex = tabIndex

        local btn = self._tabs[self._focusTabIndex]
        btn:loadTextureNormal("illustration_btn_focus", ccui.TextureResType.plistType)
        btn:setEnabled(false)
        btn:setSwallowTouches(false)

    end

    tabArea.unfocusTab = function(self, tabIndex)
        local lastBtn = self._tabs[tabIndex]
        lastBtn:loadTextureNormal("illustration_btn", ccui.TextureResType.plistType)
        lastBtn:setEnabled(true)
        lastBtn:setSwallowTouches(true)
    end

    tabArea.insertTab = function(self, index, label)
        local button = _M.createShaderButton("illustration_btn", function(sender)
            if parent.showTab then
                parent:showTab(sender._index)
            else
                tabArea:showTab(sender._index)
            end
        end)
        button:setAnchorPoint(0, 0.5)
        button:addLabel(label)
        button:setZoomScale(0)
        inner:addChild(button, -index - 1)        
        table.insert(tabArea._tabs, index, button)

        for i, tab in ipairs(tabArea._tabs) do
            tab._index = i
        end

        if self._focusTabIndex and self._focusTabIndex >= index then
            self._focusTabIndex = self._focusTabIndex + 1
        end

        self:updateTabsPos()

        return button
    end

    tabArea.updateTabsPos = function(self)
        local count = 0
        for _, tab in ipairs(self._tabs) do
            if tab:isVisible() then
                count = count + 1
            end
        end

        local innerH = count * TAB_HEIGHT

        inner:setContentSize(lc.w(tabArea), innerH)
        self:setBounceEnabled(innerH > lc.h(self))
        self:refreshView()

        local lastY = innerH
        for _, tab in ipairs(self._tabs) do
            if tab:isVisible() then
                tab:setPosition(0, lastY - lc.h(tab) / 2)
                lastY = lastY - TAB_HEIGHT
            end
        end
    end

    tabArea._tabs = {}
    for i, str in ipairs(tabStrs) do
        local tab = tabArea:insertTab(i, str)
    end
    tabArea:updateTabsPos()
end

function _M.addHorizontalTabButtons2(parent, tabStrs, top, left, width, TAB_WIDTH)
    local TAB_WIDTH = 172
    local TAB_HEIGHT = 72
    
    local tabArea = lc.List.create(cc.size(width or left, TAB_HEIGHT), lc.Dir.horizontal, 0, 10)
    lc.addChildToPos(parent, tabArea, cc.p(left, top - lc.h(tabArea)))
    parent._tabArea = tabArea
    tabArea:setLocalZOrder(3)
    local innerW = #tabStrs * TAB_WIDTH
    local inner = ccui.Widget:create()
    inner:setContentSize(innerW, lc.h(tabArea))
    tabArea:pushBackCustomItem(inner)

    if innerW < lc.w(tabArea) then
        tabArea:setBounceEnabled(false)
    end

    tabArea.showTab = function(self, tabIndex)
        if self._focusTabIndex then
            self:unfocusTab(self._focusTabIndex)
        end

        self._focusTabIndex = tabIndex

        local btn = self._tabs[self._focusTabIndex]
        btn:loadTextureNormal("img_btn_tab_bg_focus_3", ccui.TextureResType.plistType)
        btn:setEnabled(false)
        btn:setSwallowTouches(false)

    end

    tabArea.unfocusTab = function(self, tabIndex)
        local lastBtn = self._tabs[tabIndex]
        lastBtn:loadTextureNormal("img_btn_tab_bg_unfocus_3", ccui.TextureResType.plistType)
        lastBtn:setEnabled(true)
        lastBtn:setSwallowTouches(true)
    end

    tabArea.insertTab = function(self, index, label)
        local button = _M.createShaderButton("img_btn_tab_bg_unfocus_3", function(sender)
            if parent.showTab then
                parent:showTab(sender._index)
            else
                tabArea:showTab(sender._index)
            end
        end)
        local label = _M.createTTFBold(label, _M.FontSize.S1)
        label:enableOutline(V.COLOR_DARK_OUTLINE, 2)
        lc.addChildToPos(button, label, cc.p(lc.w(button) / 2, lc.h(button) / 2 -6))
        button._label = label
        button:setZoomScale(0)
        inner:addChild(button, -index - 1)        
        table.insert(tabArea._tabs, index, button)

        for i, tab in ipairs(tabArea._tabs) do
            tab._index = i
        end

        if self._focusTabIndex and self._focusTabIndex >= index then
            self._focusTabIndex = self._focusTabIndex + 1
        end

        self:updateTabsPos()

        return button
    end

    tabArea.updateTabsPos = function(self)
        local count = 0
        for _, tab in ipairs(self._tabs) do
            if tab:isVisible() then
                count = count + 1
            end
        end

        local innerW = count * TAB_WIDTH

        inner:setContentSize(innerW, lc.h(tabArea))
        self:setBounceEnabled(innerW > lc.w(self))
        self:refreshView()

        local lastX = innerW
        for _, tab in ipairs(self._tabs) do
            if tab:isVisible() then
                tab:setPosition(lastX - lc.w(tab) / 2, lc.h(tab) / 2)
                lastX = lastX + TAB_WIDTH
            end
        end
    end

    tabArea._tabs = {}
    for i, str in ipairs(tabStrs) do
        local tab = tabArea:insertTab(i, str)
    end
    tabArea:setScale(0.75)
    tabArea:updateTabsPos()
end

function _M.addHorizontalTabButtons(parent, tabStrs, top, left, width, TAB_HEIGHT)
    local TAB_WIDTH = 136
    TAB_HEIGHT = TAB_HEIGHT or (96 + 20)
    
    local tabArea = lc.List.create(cc.size(width or left, TAB_HEIGHT), lc.Dir.horizontal, 0, 0)
    lc.addChildToPos(parent, tabArea, cc.p(left, top - lc.h(tabArea)))
    parent._tabArea = tabArea
    tabArea:setLocalZOrder(3)
    local innerW = #tabStrs * TAB_WIDTH
    local inner = ccui.Widget:create()
    inner:setContentSize(innerW, lc.h(tabArea))
    tabArea:pushBackCustomItem(inner)

    if innerW < lc.w(tabArea) then
        tabArea:setBounceEnabled(false)
    end

    tabArea.showTab = function(self, tabIndex)
        if self._focusTabIndex then
            self:unfocusTab(self._focusTabIndex)
        end

        self._focusTabIndex = tabIndex

        local btn = self._tabs[self._focusTabIndex]
        btn:loadTextureNormal("img_btn_tab_bg_focus_1", ccui.TextureResType.plistType)
        btn:setEnabled(false)
        btn:setSwallowTouches(false)

    end

    tabArea.unfocusTab = function(self, tabIndex)
        local lastBtn = self._tabs[tabIndex]
        lastBtn:loadTextureNormal("img_btn_tab_bg_unfocus_1", ccui.TextureResType.plistType)
        lastBtn:setEnabled(true)
        lastBtn:setSwallowTouches(true)
    end

    tabArea.insertTab = function(self, index, label)
        local button = _M.createShaderButton("img_btn_tab_bg_unfocus_1", function(sender)
            if parent.showTab then
                parent:showTab(sender._index)
            else
                tabArea:showTab(sender._index)
            end
        end)
        button:setScale9Enabled(true)
        button:setCapInsets(cc.rect(60,0,2,55))
        button:setContentSize(120, 55)
        button:addLabel(label)
        button:setZoomScale(0)
        inner:addChild(button, -index - 1)        
        table.insert(tabArea._tabs, index, button)

        for i, tab in ipairs(tabArea._tabs) do
            tab._index = i
        end

        if self._focusTabIndex and self._focusTabIndex >= index then
            self._focusTabIndex = self._focusTabIndex + 1
        end

        self:updateTabsPos()

        return button
    end

    tabArea.updateTabsPos = function(self)
        local count = 0
        for _, tab in ipairs(self._tabs) do
            if tab:isVisible() then
                count = count + 1
            end
        end

        local innerW = count * TAB_WIDTH

        inner:setContentSize(innerW, lc.h(tabArea))
        self:setBounceEnabled(innerW > lc.w(self))
        self:refreshView()

        local lastX = innerW
        for _, tab in ipairs(self._tabs) do
            if tab:isVisible() then
                tab:setPosition(lastX - lc.w(tab) / 2, lc.h(tab) / 2)
                lastX = lastX + TAB_WIDTH
            end
        end
    end

    tabArea._tabs = {}
    for i, str in ipairs(tabStrs) do
        local tab = tabArea:insertTab(i, str)
    end
    tabArea:updateTabsPos()
end

function _M.createFilterButton(str, callback, w, h)
    local label = _M.createTTF(str, V.FontSize.S1)
    local item = lc.createSprite('img_filter_item')

    local gap = 6
    w = w or (lc.w(label) + lc.w(item) + gap)
    h = h or lc.h(item)

    local btn = _M.createScale9ShaderButton(nil, callback, cc.rect(1, 1, 1, 1), w, h)
    lc.addChildToPos(btn, item, cc.p(lc.cw(item), lc.ch(btn)))
    lc.addChildToPos(btn, label, cc.p(lc.w(item) + lc.cw(label) + gap, lc.ch(btn)))

    local selectSpr = lc.createSprite('img_filter')
    lc.addChildToPos(item, selectSpr, cc.p(lc.cw(selectSpr), lc.ch(selectSpr)))
    btn._selectSpr = selectSpr
    
    btn.setIsSelected = function (self, isSelected) 
        self._selectSpr:setVisible(isSelected)
    end

    return btn
end