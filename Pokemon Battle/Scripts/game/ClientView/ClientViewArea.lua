local _M = ClientView

function _M.createUnionInfoArea(user, isFlipX)
    local area = lc.createNode()

    -- Create union flag
    local badge = lc.createSprite("avatar_badge_s_1")
    area._badge = badge

    local unionName = cc.Label:createWithTTF((user and user._unionName) or "", _M.TTF_FONT, _M.FontSize.S2)
    unionName:setAnchorPoint(isFlipX and 1 or 0, 0.5)
    area._name = unionName

    local areaW = lc.w(badge) + 6 + lc.w(unionName)
    local areaH = lc.h(badge)
    area:setContentSize(areaW, areaH)

    if isFlipX then
        lc.addChildToPos(area, unionName, cc.p(lc.w(unionName), areaH / 2))
        lc.addChildToPos(area, badge, cc.p(lc.right(unionName) + 6 + lc.w(badge) / 2, lc.y(unionName)))
    else
        lc.addChildToPos(area, badge, cc.p(lc.w(badge) / 2, areaH / 2))
        lc.addChildToPos(area, unionName, cc.p(lc.right(badge) + 6, lc.y(badge)))
    end

    local word = cc.Label:createWithTTF((user and user._unionWord) or "", _M.TTF_FONT, 18)
    word:setColor(lc.Color3B.yellow)
    lc.addChildToPos(area, word, cc.p(lc.x(badge), lc.y(badge)))
    area._word = word

    area.setName = function(area, name)
        area._name:setString(name)
    end

    return area
end

function _M.createVerticalTabListArea(height, tabs, callback, bgColor)
    local size = cc.size(_M.VERTICAL_TAB_WIDTH, height)
    local area = lc.createNode(size)
    local listSize = cc.size(size.width, height)

    local frame = ccui.Scale9Sprite:createWithSpriteFrameName("img_com_bg_27", _M.CRECT_COM_BG27)
    frame:setContentSize(size)
    lc.addChildToCenter(area, frame)

    local edge = lc.createSprite('img_divide_line_6')
    edge:setScale(1, lc.h(frame) / lc.h(edge))
    lc.addChildToPos(area, edge, cc.p(lc.right(frame) - 4, lc.y(frame)))

    local list = lc.List.createV(listSize, 20, 8)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(area, list)
    lc.offset(list, 12, 0)
    
    area._list = list
    area._callback = callback
    
    area.showTab = function(self, index, isUserBehavior)
        local items, btnTab, btnItemIndex = list:getItems()
        for i, item in ipairs(items) do
            if item._index == index then
                btnTab = item
                btnItemIndex = i
                break
            end
        end

        if btnTab.checkValid and not btnTab.checkValid() then
            return
        end

        local needCheckBounce
        if btnTab._tabs then
            btnTab._icon:stopAllActions()

            if btnItemIndex == self._expandedTabIndex then
                if self._focusedTab and self._focusedTab._expandedIndex == btnItemIndex then
                    self._focusedTab = nil
                end

                local expandedBtn = items[self._expandedTabIndex]
                for i = 1, #expandedBtn._tabs do
                    list:removeItem(self._expandedTabIndex)
                end
                self._expandedTabIndex = -1
                
                btnTab._icon:runAction(lc.rotateTo(0.1, -90))

            else
                if self._focusedTab and self._focusedTab._index ~= nil and self._focusedTab._isSub then
                    self._focusedTab = nil
                end

                if self._expandedTabIndex ~= -1 then
                    local expandedBtn = items[self._expandedTabIndex]
                    for i = 1, #expandedBtn._tabs do
                        list:removeItem(self._expandedTabIndex)
                    end
                    self._expandedTabIndex = -1
                  
                end

                local items, btnTab, btnItemIndex = list:getItems()
                for i, item in ipairs(items) do
                    if item._index == index then
                        btnTab = item
                        btnItemIndex = i
                        break
                    end
                end

                for _, tab in ipairs(btnTab._tabs) do
                    local btn = self:createTab(tab, tab._subIndex, cc.size(180, 70))
                    list:insertCustomItem(btn, btnItemIndex)
                end
                self._expandedTabIndex = btnItemIndex

                btnTab._icon:runAction(lc.rotateTo(0.1, 0))
            end
            
            needCheckBounce = true

            if self._subTabExpandCallback then
                self._subTabExpandCallback(btnTab)
            end

        else
            local isSameTab = (self._focusedTab == btnTab)
            if not isSameTab then
                local btn = self._focusedTab
                if btn then
                    btn:loadTextureNormal("img_btn_tab_bg_unfocus_3", ccui.TextureResType.plistType)
                    btn:setColor(btn._isSub and cc.c3b(180, 250, 255) or lc.Color3B.white)
                    --btn:setEnabled(true)
                    --btn:setSwallowTouches(true)

                    if btn._isSub then
                        btn._expandedIndex = nil
                    end

                    if btn._scaleSize then btn:setContentSize(btn._scaleSize) end
                end
        
                self._focusedTab = btnTab
                if btnTab._isSub then
                    btnTab._expandedIndex = self._expandedTabIndex
                end

                btnTab:loadTextureNormal("img_btn_tab_bg_focus_3", ccui.TextureResType.plistType)
                --btnTab:setEnabled(false)
                --btnTab:setSwallowTouches(false)

                if btnTab._scaleSize then btnTab:setContentSize(btnTab._scaleSize) end
            end

            if self._callback then
                self._callback(btnTab, isSameTab, isUserBehavior)
            end
        end

        if needCheckBounce then
            self:checkListBounce()
        end

        if not isUserBehavior then
            -- make tab visible
            local innerHeight = list:getInnerContainerSize().height
            local pos = math.max(innerHeight - lc.bottom(btnTab) - lc.h(list) + list:getItemsMargin(), 0)
            list:gotoPos(pos)
        end
    end

    area.createTab = function(self, tab, i, scaleSize)
        local btn = _M.createShaderButton("img_btn_tab_bg_unfocus_3")

        if scaleSize then
            btn:ignoreContentAdaptWithSize(false)
            btn:setContentSize(scaleSize)
            btn._scaleSize = scaleSize
        end

        local str, icon
        if type(tab) == "string" then
            str = tab

            btn._index = i
        else
            str = tab._str
            icon = tab._icon

            btn._index = tab._index or i
            btn._userData = tab._userData
            btn._tabs = tab._tabs
            btn._isSub = tab._isSub

            btn.checkValid = tab.checkValid
        end

        btn:setName(str)
        btn:addLabel(str, btn._isSub and _M.COLOR_TEXT_LIGHT or _M.COLOR_TEXT_LIGHT)
        lc.offset(btn._label, -14, 0)
        btn:setColor(btn._isSub and cc.c3b(180, 250, 255) or lc.Color3B.white)
        btn._callback = function() area:showTab(btn._index, true) end

        if icon then
            btn:addIcon(icon)
        end

        if btn._tabs then
           btn:addIcon("img_arrow_down_2")
           btn._icon:setColor(lc.Color3B.yellow)
           btn._icon:setRotation(-90)
        end

        return btn
    end

    area.resetTabs = function(self, tabs)
        list:removeAllItems()
        self._focusedTab = nil
        self._expandedTabIndex = -1

        -- Add tab buttons
        for i, tab in ipairs(tabs) do
            local btnTab = self:createTab(tab, i)
            list:pushBackCustomItem(btnTab)
        end

        self:checkListBounce()
    end

    area.checkListBounce = function(self)
        list:forceDoLayout()

        local innerHeight = list:getInnerContainerSize().height
        list:setBounceEnabled(innerHeight > listSize.height)
    end

    area.focusAtPos = function(self, pos)
        local item = list:getItems()[pos]
        if item then
            self:showTab(item._index)
        end
    end

    if tabs then
        area:resetTabs(tabs)
    end

    return area
end

function _M.createHorizontalTabListArea(width, tabs, callback, bgColor)
    local size = cc.size(width, _M.HORIZONTAL_TAB_HEIGHT)
    local area = lc.createNode(size)
    local listSize = cc.size(width, size.height)

    -- fix
    local list = lc.List.createH(listSize, 20, 8)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(area, list)
    lc.offset(list, 6, 0)
    
    area._list = list
    area._callback = callback
    
    area.showTab = function(self, index, isUserBehavior)
        local items, btnTab, btnItemIndex = list:getItems()
        for i, item in ipairs(items) do
            if item._index == index then
                btnTab = item
                btnItemIndex = i
                break
            end
        end

        if btnTab.checkValid and not btnTab.checkValid() then
            return
        end

        local needCheckBounce
        -- sub tab
        if btnTab._tabs then
        
            if btnItemIndex == self._expandedTabIndex then
                if self._focusedTab and self._focusedTab._expandedIndex == btnItemIndex then
                    self._focusedTab = nil
                end

                local expandedBtn = items[self._expandedTabIndex]
                for i = 1, #expandedBtn._tabs do
                    list:removeItem(self._expandedTabIndex)
                end
                self._expandedTabIndex = -1
            else
                if self._focusedTab and self._focusedTab._index ~= nil and self._focusedTab._isSub then
                    self._focusedTab = nil
                end

                if self._expandedTabIndex ~= -1 then
                    local expandedBtn = items[self._expandedTabIndex]
                    for i = 1, #expandedBtn._tabs do
                        list:removeItem(self._expandedTabIndex)
                    end
                    self._expandedTabIndex = -1
                  
                end

                local items, btnTab, btnItemIndex = list:getItems()
                for i, item in ipairs(items) do
                    if item._index == index then
                        btnTab = item
                        btnItemIndex = i
                        break
                    end
                end
                --[[
                local height = #btnTab._tabs * _M.CRECT_BUTTON_1_S.height + (#btnTab._tabs - 1) * 2
                local posY = _M.CRECT_BUTTON_1_S.height / 2
                local panel = lc.createSprite({_name = "img_com_bg_30", _crect = cc.rect(20, 20, 1, 1), _size = cc.size(120, height)})
                lc.addChildToPos(btnTab, panel, cc.p(lc.cw(btnTab), - lc.ch(panel)), 3)
                ]]
                for _, tab in ipairs(btnTab._tabs) do
                    local btn = self:createTab(tab, tab._subIndex)
                    --[[
                    lc.addChildToPos(panel, btn, cc.p(lc.cw(panel), posY))
                    posY = posY + _M.CRECT_BUTTON_1_S.height + 2]]
                    list:insertCustomItem(btn, btnItemIndex)
                end
                self._expandedTabIndex = btnItemIndex
            end
            
            needCheckBounce = true

            if self._subTabExpandCallback then
                self._subTabExpandCallback(btnTab)
            end

        else
            local isSameTab = (self._focusedTab == btnTab)
            if not isSameTab then
                local btn = self._focusedTab
                if btn then
                    btn:loadTextureNormal("img_btn_tab_bg_unfocus_3", ccui.TextureResType.plistType)
                    btn:setColor(btn._isSub and cc.c3b(180, 250, 255) or lc.Color3B.white)
                    btn._label:setColor(cc.c3b(134, 226, 227))
                    --btn:setEnabled(true)
                    --btn:setSwallowTouches(true)

                    if btn._isSub then
                        btn._expandedIndex = nil
                        
                    end

                    --if btn._scaleSize then btn:setContentSize(btn._scaleSize) end
                end
        
                self._focusedTab = btnTab
                if btnTab._isSub then
                    btnTab._expandedIndex = self._expandedTabIndex
                    btnTab._label:setColor(cc.c3b(134, 226, 227))
                end

                btnTab:loadTextureNormal("img_btn_tab_bg_focus_3", ccui.TextureResType.plistType)
                btnTab._label:setColor(_M.COLOR_TEXT_TITLE)
                --btnTab:setEnabled(false)
                --btnTab:setSwallowTouches(false)

                --if btnTab._scaleSize then btnTab:setContentSize(btnTab._scaleSize) end
            end

            if self._callback then
                self._callback(btnTab, isSameTab, isUserBehavior)
            end
        end

        if needCheckBounce then
            self:checkListBounce()
        end

        if not isUserBehavior then
            -- make tab visible
            local innerHeight = list:getInnerContainerSize().height
            local pos = math.max(innerHeight - lc.bottom(btnTab) - lc.h(list) + list:getItemsMargin(), 0)
            list:gotoPos(pos)
        end
    end

    area.createTab = function(self, tab, i, scaleSize)
        local btn = _M.createShaderButton("img_btn_tab_bg_unfocus_3")

        if scaleSize then
            btn:ignoreContentAdaptWithSize(false)
            btn:setContentSize(scaleSize)
            btn._scaleSize = scaleSize
        end

        local str, icon
        if type(tab) == "string" then
            str = tab

            btn._index = i
        else
            str = tab._str

            btn._index = tab._index or i
            btn._userData = tab._userData
            btn._tabs = tab._tabs
            btn._isSub = tab._isSub

            btn.checkValid = tab.checkValid
        end

        btn:setName(str)
        btn:addLabel(str, btn._isSub and cc.c3b(134, 226, 227) or cc.c3b(134, 226, 227))
        lc.offset(btn._label, 0, -8)
        btn:setColor(btn._isSub and cc.c3b(134, 226, 227) or lc.Color3B.white)
        btn._callback = function() area:showTab(btn._index, true) end

        return btn
    end

    area.resetTabs = function(self, tabs)
        list:removeAllItems()
        self._focusedTab = nil
        self._expandedTabIndex = -1


        -- Add tab buttons
        for i, tab in ipairs(tabs) do
            local btnTab = self:createTab(tab, i)
            list:pushBackCustomItem(btnTab)
        end

        self:checkListBounce()
    end

    area.checkListBounce = function(self)
        list:forceDoLayout()

        local innerHeight = list:getInnerContainerSize().height
        list:setBounceEnabled(innerHeight > listSize.height)
    end

    area.focusAtPos = function(self, pos)
        local item = list:getItems()[pos]
        if item then
            self:showTab(item._index)
        end
    end

    if tabs then
        area:resetTabs(tabs)
    end

    return area
end

function _M.createVerticalIconTabListArea(height, tabs, callback, bgColor)
    local size = cc.size(_M.VERTICAL_TAB_WIDTH, height)
    local area = lc.createNode(size)
    local listSize = cc.size(size.width, height)

    local frame = ccui.Scale9Sprite:createWithSpriteFrameName("img_com_bg_27", _M.CRECT_COM_BG27)
    frame:setContentSize(size)
    lc.addChildToCenter(area, frame)

    local edge = lc.createSprite('img_divide_line_6')
    edge:setScale(1, lc.h(frame) / lc.h(edge))
    lc.addChildToPos(area, edge, cc.p(lc.right(frame) - 4, lc.y(frame)))

    local list = lc.List.createV(listSize, 0, -30)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(area, list)
    lc.offset(list, 0, 0)
    
    area._list = list
    area._callback = callback
    
    area.showTab = function(self, index, isUserBehavior)
        local items, btnTab, btnItemIndex = list:getItems()
        for i, item in ipairs(items) do
            if item._index == index then
                btnTab = item
                btnItemIndex = i
                break
            end
        end

        if btnTab.checkValid and not btnTab.checkValid() then
            return
        end

        local isSameTab = (self._focusedTab == btnTab)
        if not isSameTab then
            local btn = self._focusedTab
            if btn then
                btn:loadTextureNormal("img_btn_tab_bg_unfocus_4", ccui.TextureResType.plistType)
                btn._arrow:setVisible(false)
                btn._fg:setScale(0.9)
            end
        
            self._focusedTab = btnTab
                
            btnTab:loadTextureNormal("img_btn_tab_bg_focus_4", ccui.TextureResType.plistType)
            btnTab._arrow:setVisible(true)
            btnTab._fg:setScale(1)
        end

        if self._callback then
            self._callback(btnTab, isSameTab, isUserBehavior)
        end

        if not isUserBehavior then
            -- make tab visible
            local innerHeight = list:getInnerContainerSize().height
            local pos = math.max(innerHeight - lc.bottom(btnTab) - lc.h(list) + list:getItemsMargin(), 0)
            list:gotoPos(pos)
        end
    end

    area.createTab = function(self, tab, i)
        local btn = _M.createShaderButton("img_btn_tab_bg_unfocus_4")

        icon = tab._icon

        btn._index = tab._index or i
        btn._userData = tab._userData
        btn._tabs = tab._tabs

        btn.checkValid = tab.checkValid

        local fg = lc.createSpriteWithMask(icon)
        lc.addChildToCenter(btn, fg)
        fg:setScale(0.9)
        btn._fg = fg

        local arrow = lc.createSprite('img_btn_tab_bg_focus_4_top')
        lc.addChildToCenter(fg, arrow)
        arrow:setVisible(false)
        btn._arrow = arrow
        
        btn._callback = function() area:showTab(btn._index, true) end

        return btn
    end

    area.resetTabs = function(self, tabs)
        list:removeAllItems()
        self._focusedTab = nil
        self._expandedTabIndex = -1

        -- Add tab buttons
        for i, tab in ipairs(tabs) do
            local btnTab = self:createTab(tab, i)
            list:pushBackCustomItem(btnTab)
        end

    end

    area.focusAtPos = function(self, pos)
        local item = list:getItems()[pos]
        if item then
            self:showTab(item._index)
        end
    end

    if tabs then
        area:resetTabs(tabs)
    end

    return area
end

function _M.createHorizontalIconTabListArea(width, tabs, callback, bgColor)
    local size = cc.size(width, 105)
    local area = lc.createNode(size)
    local listSize = cc.size(width, size.height)
    --[[
    local frame = ccui.Scale9Sprite:createWithSpriteFrameName("img_com_bg_27", _M.CRECT_COM_BG27)
    frame:setContentSize(size)
    ]]
    local frame = lc.createNode(size)
    lc.addChildToCenter(area, frame)

    local edge = lc.createSprite('img_divide_line_11')
    edge:setScale(lc.w(frame) / lc.w(edge), 1)
    lc.addChildToPos(area, edge, cc.p(lc.x(frame), lc.bottom(frame)))
    local edge2 = lc.createSprite('img_divide_line_11')
    edge2:setScale(lc.w(frame) / lc.w(edge2), 1)
    lc.addChildToPos(area, edge2, cc.p(lc.x(frame), lc.top(frame)))

    local list = lc.List.createH(listSize, 6, 3)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(area, list)
    lc.offset(list, 0, 0)
    
    area._list = list
    area._callback = callback
    
    area.showTab = function(self, index, isUserBehavior)
        local items, btnTab, btnItemIndex = list:getItems()
        for i, item in ipairs(items) do
            if item._index == index then
                btnTab = item
                btnItemIndex = i
                break
            end
        end

        if btnTab.checkValid and not btnTab.checkValid() then
            return
        end

        local isSameTab = (self._focusedTab == btnTab)
        if not isSameTab then
            local btn = self._focusedTab
            if btn then
                btn:loadTextureNormal("img_tb1", ccui.TextureResType.plistType)
                --btn._arrow:setVisible(false)
                
                --btn:setScale(0.9)
            end
        
            self._focusedTab = btnTab
                
            btnTab:loadTextureNormal("img_tb1_focus", ccui.TextureResType.plistType)
            --btnTab._arrow:setVisible(true)
            
            btnTab:setScale(1)
        end

        if self._callback then
            self._callback(btnTab, isSameTab, isUserBehavior)
        end

        if not isUserBehavior then
            -- make tab visible
            local innerHeight = list:getInnerContainerSize().height
            local pos = math.max(innerHeight - lc.bottom(btnTab) - lc.h(list) + list:getItemsMargin(), 0)
            list:gotoPos(pos)
        end
    end

    area.createTab = function(self, tab, i)
        local btn = _M.createShaderButton("img_tb1")

        icon = tab._icon

        btn._index = tab._index or i
        btn._userData = tab._userData
        btn._tabs = tab._tabs

        btn.checkValid = tab.checkValid
        
        --[[
        local fg = lc.createSpriteWithMask(icon)
        lc.addChildToCenter(btn, fg)
        ]]
        btn._fg = fg
        --[[
        local arrow = lc.createSprite('img_btn_tab_bg_focus_4_top')
        lc.addChildToCenter(fg, arrow)
        arrow:setVisible(false)
        btn._arrow = arrow
        ]]
        btn._callback = function() area:showTab(btn._index, true) end

        return btn
    end

    area.resetTabs = function(self, tabs)
        list:removeAllItems()
        self._focusedTab = nil
        self._expandedTabIndex = -1

        -- Add tab buttons
        for i, tab in ipairs(tabs) do
            local btnTab = self:createTab(tab, i)
            btnTab:setScale(0.9)
            list:pushBackCustomItem(btnTab)
        end

    end

    area.focusAtPos = function(self, pos)
        local item = list:getItems()[pos]
        if item then
            self:showTab(item._index)
        end
    end

    if tabs then
        area:resetTabs(tabs)
    end

    return area
end

function _M.createEvolutionArea(quality, count)
    local iconName = "card_quality"
    local iconSize = lc.frameSize(iconName)

    local gap = -7
    local areaSize = cc.size(lc.makeEven(iconSize.width * count + gap * (count - 1)), iconSize.height)
    local area = lc.createNode(areaSize)
    area:setCascadeOpacityEnabled(true)

    local left = iconSize.width / 2
    for i = 1, count do
        local icon = cc.Sprite:createWithSpriteFrameName(iconName)
        lc.addChildToPos(area, icon, cc.p(left, iconSize.height / 2))
        left = left + iconSize.width + gap
    end

    return area
end

function _M.createResConsumeButtonArea(w, iconName, resBgColor, resLabel, btnLabel, btnName)
    local area = ccui.Widget:create()
    area:setAnchorPoint(0.5, 0.5)

    local resW, btnW
    local isVertical
    if type(w) == "number" then
        isVertical = true
        resW = w - 20
        btnW = w
    else
        isVertical = false
        resW = w[1]
        btnW = w[2]
    end

    local resArea = lc.createNode()--_M.createResIconLabel(resW, iconName, resBgColor or lc.Color3B.black)
    resArea:setContentSize(resW, V.CRECT_COM_BG2.height)

    local icon = lc.createSprite(iconName)
    lc.addChildToPos(resArea, icon, cc.p(0, lc.ch(resArea)))
    icon:setScale(0.7)
    resArea._ico = icon

    local label = V.createBMFont(V.BMFont.huali_26, "")
    label:setAnchorPoint(0, 0.5)
    lc.addChildToPos(resArea, label, cc.p(lc.right(icon) + 2, lc.ch(resArea)))
    resArea._label = label

    if resLabel then
        resArea._label:setString(resLabel)
    end

    local btn = _M.createScale9ShaderButton(btnName or "img_btn_1_s", nil, _M.CRECT_BUTTON_1_S, btnW)
    lc.addChildToPos(btn, resArea, cc.p(lc.cw(btn) - 22, lc.ch(btn)))
    btn._icon = resArea
    if btnLabel then
        btn:addLabel(btnLabel)
        lc.offset(btn._label, 22, -2)
        lc.offset(btn._icon, 55 + 16)
    end

    if isVertical then
        local resAreaHeight = lc.h(resArea)
        local h = resAreaHeight + lc.h(btn) + 10
        area:setContentSize(w, h)
        --lc.addChildToPos(area, resArea, cc.p(btnW / 2 + math.floor(lc.w(resArea._ico) / 4) - 4, h - resAreaHeight / 2))
        lc.addChildToPos(area, btn, cc.p(btnW / 2, lc.h(btn) / 2))
    else
        area:setContentSize(btnW, lc.h(btn))
        --lc.addChildToPos(area, resArea, cc.p(resW / 2, lc.h(area) / 2))
        lc.addChildToPos(area, btn, cc.p(btnW / 2, lc.ch(area)))
    end

    area._resArea = resArea
    area._resLabel = resArea._label
    area._btn = btn

    return area
end

function _M.createLevelArea(level)
    local levelBg = lc.createSprite("avatar_level_bg")
    levelBg:setCascadeOpacityEnabled(true)

    local levelValue = cc.Label:createWithTTF(string.format("%d", level), _M.TTF_FONT, _M.FontSize.S3)
    levelValue:setPosition(lc.w(levelBg) / 2, lc.h(levelBg) / 2 + 2)
    levelBg:addChild(levelValue)
    levelBg._level = levelValue

    return levelBg
end


function _M.createLevelNameArea(level, name, isFlipX)
    local isFlipX = isFlipX or false

    local bg = lc.createSprite("avatar_name_bg")
    bg:setFlippedX(isFlipX)

    local w, h = lc.w(bg), lc.h(bg)
    local area = lc.createNode(cc.size(w, h), nil, cc.p(isFlipX and 1 or 0, 0.5))

    lc.addChildToCenter(area, bg)
    area._bg = bg
    
    local name = cc.Label:createWithTTF(name, _M.TTF_FONT, _M.FontSize.M2)
    name:setAnchorPoint(isFlipX and 1 or 0, 0.5)
    lc.addChildToPos(area, name, cc.p(isFlipX and (w - 16) or 16, lc.ch(area)))
    area._name = name

    local levelArea = _M.createLevelAreaNew(level)
    lc.addChildToPos(area, levelArea, cc.p(isFlipX and (w - 44) or 44, lc.bottom(name) - 54))
    area._level = levelArea

    area.setName = function(area, name)
        area._name:setString(name)
        area._name:setScale(math.min(180 / lc.w(area._name), 0.8))
    end

    return area
end


function _M.createTitleArea(titleStr, backFunc, helpFunc)
    local titleArea = ccui.Widget:create()

    titleArea:setContentSize(V.SCR_W, _M.CRECT_TITLE_AREA_BG.height)
    titleArea:setPosition(V.SCR_CW, V.SCR_H - lc.h(titleArea) / 2)
    
    titleArea:setTouchEnabled(true)
    
    local bg = lc.createSprite({_name = "img_ui_scene_title_bg", _crect = _M.CRECT_TITLE_AREA_BG, _size = titleArea:getContentSize()})
    lc.addChildToCenter(titleArea, bg)

    --[[
    if helpFunc then
        local btn = V.createShaderButton("img_btn_rule", helpFunc)
        lc.addChildToPos(titleArea, btn, cc.p(lc.right(title) + lc.ch(btn) + 10, lc.ch(titleArea) - 2))
        btn:setTouchRect(cc.rect(-16, -16, lc.w(btn) + 32, lc.h(btn) + 32))
    end
    ]]


    local btnBack = V.createScale9ShaderButton("img_btn_1_s", backFunc, V.CRECT_BUTTON_S, 92, 50)
    btnBack:setPosition(80, lc.h(titleArea) / 2 + 2)
    titleArea:addChild(btnBack)
    local backArrow = lc.createSprite("img_ui_scene_back")
    lc.addChildToCenter(btnBack, backArrow)
    titleArea._btnBack = btnBack

    local title = V.createTTFStroke(titleStr, V.FontSize.M1)
    title:setColor(V.COLOR_TEXT_TITLE)
    lc.addChildToPos(titleArea, title, cc.p(lc.right(btnBack) + 50 + lc.cw(title), lc.h(titleArea) / 2))
    lc.offset(title, -10, 0)
    titleArea._title = title

    return titleArea
end

function _M.createIconLabelArea(iconName, labelStr, w, callback, cbIconName)
    local h = lc.frameSize("img_com_bg_58").height
    local size = cc.size(w, h)

    -- Divide the bg to 3 parts 
    local crect = _M.CRECT_COM_BG58
    crect.y = 0
    crect.height = h

    -- Check whether has add button
    local area
    if callback then
        area = _M.createShaderButton(nil, callback)
    else
        area = ccui.Widget:create()
    end
    area:setContentSize(size)

    local valBg = ccui.Scale9Sprite:createWithSpriteFrameName("img_com_bg_58", crect)
    valBg:setContentSize(size)
    valBg:setPosition(size.width / 2, size.height / 2)
    area:addChild(valBg)
    area._valBg = valBg

    local icon = lc.createSprite(iconName)
    icon:setPosition(4, lc.h(area) / 2 + 2)
    area:addChild(icon)
    area._icon = icon

    local btnAdd = nil
    if cbIconName then
        btnAdd = lc.createSprite(cbIconName)
        btnAdd:setPosition(lc.w(area) - 6 - lc.w(btnAdd) / 2, lc.h(area) / 2)
        btnAdd:setColor(cc.c3b(255, 230, 30))
        area:addChild(btnAdd)
        area._btnAdd = btnAdd
    end

    labelStr = labelStr or "0"
    local label = _M.createBMFont(_M.BMFont.huali_26, labelStr)
    label:setPosition(math.floor(((btnAdd and lc.left(btnAdd) or (size.width - 5)) - lc.right(icon)) / 2) + lc.right(icon), size.height / 2 + 1)    
    area:addChild(label)
    area._label = label

    return area
end

function _M.createItemCountArea(infoId, iconName, w, count)
    count = count or P:getItemCount(infoId)
    local area = _M.createIconLabelArea(iconName, tostring(count), w, function()
        require("DescForm").create({_infoId = infoId, _showOwnCount = true}):show()
    end)

    return area
end


function _M.createMaterialArea(mats, title, checkNeed)
    local area = ccui.Layout:create()
    area:setAnchorPoint(0.5, 0.5)
    area:setContentSize(V.SCR_W, 200)         -- Resize the area according to the center button size

    --[[
    area:registerScriptHandler(function(evt) 
        if evt == "cleanup" then            
            lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/img_btn_ball_frame.jpg"))
            lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/img_btn_ball.jpg"))
            lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/img_crystal.jpg"))
        end
    end)
    ]]

    --[[
    local diamond = lc.createSpriteWithMask("res/jpg/img_crystal.jpg")
    lc.addChildToPos(area, diamond, cc.p(V.SCR_CW, 210))
    diamond:runAction(lc.rep(lc.sequence(lc.moveBy(1, 0, 10), lc.moveBy(1, 0, -10))))
    ]]

    -- Left and right material background and slots
    local slots = {}
    area._slots = slots

    local baseW, slotW, slotGap = 170, 100, 14
    --local slotCount = math.max(2, #mats)
    local slotCount = math.max(1, #mats)

    --local matBg = lc.createSprite("img_mat_bg")
    --matBg:setScale(720 / lc.w(matBg), 1)
    --lc.addChildToPos(area, matBg, cc.p(lc.w(area) / 2, lc.h(area) / 2 + 80), -1)
    
    local x, y, slot = (lc.w(area) - slotCount * slotW - (slotCount - 1) * slotGap) / 2 + slotW / 2, 196

    local matLabel = V.createBMFont(_M.BMFont.huali_26, title)
    lc.addChildToPos(area, matLabel, cc.p(lc.w(area) / 2, y + 68))

    for i = 1, slotCount do
        slot = lc.createSprite("img_slot")
        lc.addChildToPos(area, slot, cc.p(x, y))
        slots[#slots + 1] = slot

        x = x + slotW + slotGap

        local bg = lc.createSprite("img_com_bg_19")
        bg:setScaleX(0.6)
        lc.addChildToPos(slot, bg, cc.p(lc.w(slot) / 2, -lc.h(bg) / 2 + 12), -1)
        slot._bg = bg
    end

    -- Fill slot material to slots
    -- mat = {_icon, _need}
    for i = 1, #mats do
        local slot = slots[i]
        local mat = mats[i]
        if mat._need > 0 then
            local val = _M.createBMFont(_M.BMFont.huali_20, string.format("%d", mat._need))
            val:setScale(0.8 / slot._bg:getScaleX(), 0.8)
            lc.addChildToCenter(slot._bg, val)
            
            -- Add icon
            if checkNeed and mat._icon._data._count < mat._need then
                val:setColor(lc.Color3B.red)
            end
            lc.addChildToCenter(slot, mat._icon)
        end
    end
    
    return area   
end

function _M.createCheckLabelArea(labelStr, callback, isCheck)
    local area = ccui.Widget:create()
    area:setAnchorPoint(0.5, 0.5)
    area._isCheck = isCheck or false
    area._callback = callback
    
    local label = cc.Label:createWithTTF(labelStr, _M.TTF_FONT, _M.FontSize.S1)
    local button = _M.createShaderButton("img_btn_check_bg", function(sender) 
        area._isCheck = not area._isCheck
        sender._checkSprite:setVisible(area._isCheck)
        if area._callback then area._callback(area._isCheck) end        
    end)
    button:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)
    button:setTouchRect(cc.rect(-10, -10, lc.w(button) + 20, lc.h(button) + 20))
    button._checkSprite = lc.createSprite("img_icon_check")
    button._checkSprite:setVisible(area._isCheck)
    lc.addChildToCenter(button, button._checkSprite)
    
    area:setContentSize(lc.w(button) + lc.w(label) + 6, math.max(lc.h(button), lc.h(label)))
    lc.addChildToPos(area, button, cc.p(lc.w(button) / 2, lc.h(area) / 2))
    lc.addChildToPos(area, label, cc.p(lc.w(area) - lc.w(label) / 2, lc.h(area) / 2))
    
    area.setCheck = function(self, isCheck)
        self._isCheck = isCheck
        self._btn._checkSprite:setVisible(isCheck)
        if self._callback then self._callback(isCheck) end
    end

    area._label = label
    area._btn = button
    return area
end

function _M.createStarArea(count)
    local areaSize = cc.size(240, 26)
    local area = lc.createNode(areaSize)
    area:setCascadeOpacityEnabled(true)

    local icons = {}
    for i = 1, _M.MAX_STAR_COUNT do
        local icon = cc.ShaderSprite:createWithFramename("card_quality")
        lc.addChildToCenter(area, icon)
        icons[i] = icon
    end
    area._icons = icons

    area.update = function(self, count)
        local iconSize = cc.size(25, 26)
        local gap = -1
    
        local totalWidth = iconSize.width * count + gap * (count - 1)
        if totalWidth > areaSize.width then
            gap = (areaSize.width - iconSize.width * count) / (count - 1)
        end 

        local right = areaSize.width - iconSize.width / 2
        for i = 1, _M.MAX_STAR_COUNT do
            local icon = self._icons[i]
            icon:setVisible(i <= count)
            icon:setPosition(cc.p(right, areaSize.height / 2))
            right = right - iconSize.width - gap
        end
    end

    area.setEffect = function(self, effect)
        for i = _M.MAX_STAR_COUNT, 1, -1 do
            self._icons[i]:setEffect(effect)
        end
    end

    area:update(count)

    return area
end

function _M.createLegendNumArea(num)
    local area = lc.createSprite("img_legend_num_bg")
    area:setCascadeOpacityEnabled(true)

    local num = _M.createBMFont(_M.BMFont.number_legend, Str(STR[string.format("NUM_%d", num)]))
    num:setColor(_M.COLOR_LEGEND_NUM)
    lc.addChildToCenter(area, num)

    area._num = num
    return area
end


function _M.createSnowArea(size, snowCount)
    local SNOW_GROUP_COUNT, SNOW_COUNT = 4, snowCount or 40
    local SNOW_SPEED, SNOW_ACTION_TAG_MOVE_Y, SNOW_X_MOVE_TIME = 20, 1, 3

    local area = lc.createNode(size)
    
    local runSnowAction = function(snow, speed)
        local action = lc.moveBy(size.height * 2 / speed, 0, -size.height * 2)
        action:setTag(SNOW_ACTION_TAG_MOVE_Y)
        snow:runAction(action)
    end

    local snows = {}
    for g = 1, SNOW_GROUP_COUNT do
        local offsetX = SNOW_X_MOVE_TIME * SNOW_SPEED * (g + 1) / 8
        local layer = lc.createNode(size)
        lc.addChildToPos(area, layer, cc.p(size.width / 2 + offsetX, size.height / 2), 0, g)

        layer:runAction(lc.rep(lc.sequence(
            lc.ease(lc.moveTo(SNOW_X_MOVE_TIME, size.width / 2 - 2 * offsetX, size.height / 2), "SineIO", 0.9),
            lc.ease(lc.moveTo(SNOW_X_MOVE_TIME, size.width / 2 + 2 * offsetX, size.height / 2), "SineIO", 0.9)
        )))

        local count = SNOW_COUNT / (g + 1)
        for i = 1, count do
            local speed = SNOW_SPEED + math.random(0, 50)

            local snow = lc.createSprite("img_snow")
            snow:setScale(1 + 0.5 * g)
            snow:setPosition(math.random(size.width), math.random(size.height))
            layer:addChild(snow)

            snow._group = g
            runSnowAction(snow, speed * (g + 1))
            table.insert(snows, snow)
        end
    end

    area:scheduleUpdateWithPriorityLua(function()
        for _, snow in ipairs(snows) do
            local y = lc.y(snow)
            if y < 0 then
                local speed = SNOW_SPEED + math.random(0, 50)
                snow:stopActionByTag(SNOW_ACTION_TAG_MOVE_Y)
                snow:setPosition(math.random(size.width), size.height - ((math.floor(-y) % size.height)))

                runSnowAction(snow, speed * (snow._group + 1))
            end
        end
    end, 0)

    return area
end

function _M.createClashFieldArea(grade, callback, isShowTrophy)
    local frame = lc.createNode(cc.size(362, 362))
    local ballBg = lc.createSprite(string.format("res/jpg/img_battle_bg_%d.png", grade))
    lc.addChildToCenter(frame, ballBg)
    --[[
    local bgName = string.format("res/bat_scene/bat_scene_%d_bg.jpg", 10 + grade)
    frame:registerScriptHandler(function(evt)
        if evt == "cleanup" then
            lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename(bgName))
        end
    end)
    ]]
    local clipNode = cc.ClippingNode:create()
    local stencil = cc.LayerColor:create(lc.Color4B.white, lc.w(frame) - 30, lc.h(frame))
    stencil:setPosition(14, 0)
    clipNode:setStencil(stencil)
    V.createClipNode(nil, cc.rect( (- lc.cw(frame) + 50), - lc.ch(frame), (lc.w(frame) - 25), lc.h(frame)), false)
    
    local titleBg

    if isShowTrophy then
        ballBg:setScale(0.65)
        titleBg = lc.createSprite("img_title_bg_1")
        lc.addChildToPos(frame, titleBg, cc.p(lc.w(frame) / 2, lc.top(ballBg) + lc.h(titleBg) / 2 + 26))
        local trophy = V.createResIconLabel(180, "img_icon_res6_s")
        lc.addChildToPos(frame, trophy, cc.p(lc.w(frame) / 2 + 20, math.floor(lc.h(trophy) / 2 + 18)))
        if grade == Data.FindClashGrade.legend then
            trophy._label:setString(string.format("%d +", Data._ladderInfo[grade]._trophy))
        else
            local min = (grade == Data.FindClashGrade.bronze and 0 or Data._ladderInfo[grade]._trophy)
            trophy._label:setString(string.format("%d - %d", min, Data._ladderInfo[grade + 1]._trophy - 1))
        end
        frame._trophy = trophy._label
        frame:setContentSize(lc.w(ballBg), lc.top(titleBg) - lc.bottom(trophy))
    else 
        local bg = lc.createSprite("res/jpg/battle_bg.jpg")
        lc.addChildToCenter(frame, bg, -1)
        frame._bg = bg
        titleBg = lc.createSprite("img_title_bg_1")
        lc.addChildToPos(bg, titleBg, cc.p(lc.w(bg) / 2, lc.h(bg) - lc.h(titleBg) / 2))
    end

    local gradeStr, clr = Str(Data._ladderInfo[grade]._nameSid), _M.COLORS_TEXT_CLASH_GRADE[grade]
    --local title = V.createTTF(gradeStr..Str(STR.FIND_CLASH_FIELD), V.FontSize.S2, clr)
    local title = V.createTTFStroke(gradeStr..Str(STR.FIND_CLASH_FIELD), V.FontSize.S1)
    lc.addChildToPos(titleBg, title, cc.p(lc.cw(titleBg), lc.ch(titleBg)))
    frame._title = title
    
    
   
    if callback then
        frame:setTouchEnabled(true)
        frame:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)
        frame:addTouchEventListener(function(sender, evt)
            if evt == ccui.TouchEventType.ended then
                callback()
            end
        end)
    end
    
    return frame
end


function _M.createAddCardArea(scale, callback, isLock)
    local size = cc.size(256, 370)

    local button = _M.createTouchSpriteWithMask("res/jpg/add_card_bg.jpg", function(sender) if callback then callback(sender) end end)
    button:setScale(scale)
    
    local bg
    if isLock then
        --button:setDisabledShader(_M.SHADER_DISABLE)
        button:setEnabled(false)
        button:setSwallowTouches(false)

        bg = cc.LayerGradient:create(cc.c4b(0x89, 0x89, 0x89, 0xff), cc.c4b(0x4b, 0x4b, 0x4b, 0xff))

        _M.addLockChains(button, scale)
    else
        bg = cc.LayerGradient:create(cc.c4b(0xc4, 0x9d, 0x6c, 0xff), cc.c4b(0x5e, 0x50, 0x39, 0xff))
    end

    bg:ignoreAnchorPointForPosition(false)
    bg:setContentSize(size.width - 32, size.height - 32)
    bg:setScale(scale)
    lc.addChildToCenter(button, bg, -1)

    local addIcon = lc.createSprite("img_icon_add_big")
    if isLock then
        addIcon:setColor(lc.Color3B.gray)
        addIcon:setOpacity(100)
    end
    lc.addChildToCenter(bg, addIcon)
    
    return button       
end

function _M.createVerticalTabListArea2(height, tabs, callback, bgColor)
    local size = cc.size(166, height)
    local area = lc.createNode(size)
    local listSize = cc.size(size.width, height)

    local frame = ccui.Scale9Sprite:createWithSpriteFrameName("img_com_bg_30", cc.rect(20, 20, 1, 1))
    frame:setContentSize(size)
    lc.addChildToCenter(area, frame)

    local list = lc.List.createV(listSize, 20, 8)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(area, list)
    
    area._list = list
    area._callback = callback
    
    area.showTab = function(self, index, isUserBehavior)
        local items, btnTab, btnItemIndex = list:getItems()
        for i, item in ipairs(items) do
            if item._index == index then
                btnTab = item
                btnItemIndex = i
                break
            end
        end

        if btnTab.checkValid and not btnTab.checkValid() then
            return
        end

        local needCheckBounce
        if btnTab._tabs then
            btnTab._icon:stopAllActions()

            if btnItemIndex == self._expandedTabIndex then
                if self._focusedTab and self._focusedTab._expandedIndex == btnItemIndex then
                    self._focusedTab = nil
                end

                local expandedBtn = items[self._expandedTabIndex]
                for i = 1, #expandedBtn._tabs do
                    list:removeItem(self._expandedTabIndex)
                end
                self._expandedTabIndex = -1
                
                btnTab._icon:runAction(lc.rotateTo(0.1, -90))

            else
                if self._focusedTab and self._focusedTab._index ~= nil and self._focusedTab._isSub then
                    self._focusedTab = nil
                end

                if self._expandedTabIndex ~= -1 then
                    local expandedBtn = items[self._expandedTabIndex]
                    for i = 1, #expandedBtn._tabs do
                        list:removeItem(self._expandedTabIndex)
                    end
                    self._expandedTabIndex = -1
                  
                end

                local items, btnTab, btnItemIndex = list:getItems()
                for i, item in ipairs(items) do
                    if item._index == index then
                        btnTab = item
                        btnItemIndex = i
                        break
                    end
                end

                for _, tab in ipairs(btnTab._tabs) do
                    local btn = self:createTab(tab, tab._subIndex, cc.size(180, 70))
                    list:insertCustomItem(btn, btnItemIndex)
                end
                self._expandedTabIndex = btnItemIndex

                btnTab._icon:runAction(lc.rotateTo(0.1, 0))
            end
            
            needCheckBounce = true

            if self._subTabExpandCallback then
                self._subTabExpandCallback(btnTab)
            end

        else
            local isSameTab = (self._focusedTab == btnTab)
            if not isSameTab then
                local btn = self._focusedTab
                if btn then
                    btn:loadTextureNormal("img_btn_tab_bg_unfocus_1", ccui.TextureResType.plistType)
                    btn:setColor(btn._isSub and cc.c3b(180, 250, 255) or lc.Color3B.white)
                    --btn:setEnabled(true)
                    --btn:setSwallowTouches(true)

                    if btn._isSub then
                        btn._expandedIndex = nil
                    end

                    if btn._scaleSize then btn:setContentSize(btn._scaleSize) end
                end
        
                self._focusedTab = btnTab
                if btnTab._isSub then
                    btnTab._expandedIndex = self._expandedTabIndex
                end

                btnTab:loadTextureNormal("img_btn_tab_bg_focus_1", ccui.TextureResType.plistType)
                --btnTab:setEnabled(false)
                --btnTab:setSwallowTouches(false)

                if btnTab._scaleSize then btnTab:setContentSize(btnTab._scaleSize) end
            end

            if self._callback then
                self._callback(btnTab, isSameTab, isUserBehavior)
                self:setVisible(false)
            end
        end

        if needCheckBounce then
            self:checkListBounce()
        end

        if not isUserBehavior then
            -- make tab visible
            local innerHeight = list:getInnerContainerSize().height
            local pos = math.max(innerHeight - lc.bottom(btnTab) - lc.h(list) + list:getItemsMargin(), 0)
            list:gotoPos(pos)
        end
    end

    area.createTab = function(self, tab, i, scaleSize)
        local btn = _M.createShaderButton("img_btn_tab_bg_unfocus_1")

        if scaleSize then
            btn:ignoreContentAdaptWithSize(false)
            btn:setContentSize(scaleSize)
            btn._scaleSize = scaleSize
        end

        local str, icon
        if type(tab) == "string" then
            str = tab

            btn._index = i
        else
            str = tab._str
            icon = tab._icon

            btn._index = tab._index or i
            btn._userData = tab._userData
            btn._tabs = tab._tabs
            btn._isSub = tab._isSub

            btn.checkValid = tab.checkValid
        end

        btn:setName(str)
        btn:addLabel(str, btn._isSub and _M.COLOR_TEXT_LIGHT or _M.COLOR_TEXT_LIGHT)
        btn._label:setScale(0.8)
        btn:setColor(btn._isSub and cc.c3b(180, 250, 255) or lc.Color3B.white)
        btn._callback = function() area:showTab(btn._index, true) end

        if icon then
            btn:addIcon(icon)
        end

        if btn._tabs then
           btn:addIcon("img_arrow_down_2")
           btn._icon:setColor(lc.Color3B.yellow)
           btn._icon:setRotation(-90)
        end

        return btn
    end

    area.resetTabs = function(self, tabs)
        list:removeAllItems()
        self._focusedTab = nil
        self._expandedTabIndex = -1

        -- Add tab buttons
        for i, tab in ipairs(tabs) do
            local btnTab = self:createTab(tab, i)
            list:pushBackCustomItem(btnTab)
        end

        self:checkListBounce()
    end

    area.checkListBounce = function(self)
        list:forceDoLayout()

        local innerHeight = list:getInnerContainerSize().height
        list:setBounceEnabled(innerHeight > listSize.height)
    end

    area.focusAtPos = function(self, pos)
        local item = list:getItems()[pos]
        if item then
            self:showTab(item._index)
        end
    end

    if tabs then
        area:resetTabs(tabs)
    end

    return area
end

function _M.createHorizontalTabListArea2(width, tabs, callback, bgColor)
    local size = cc.size(width, _M.HORIZONTAL_TAB_HEIGHT)
    local area = lc.createNode(size)
    local listSize = cc.size(width, size.height)

    -- fix
    local list = lc.List.createH(listSize, 20, 8)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(area, list)
    lc.offset(list, 6, 0)
    
    area._list = list
    area._callback = callback
    
    area.showTab = function(self, index, isUserBehavior)
        local items, btnTab, btnItemIndex = list:getItems()
        for i, item in ipairs(items) do
            if item._index == index then
                btnTab = item
                btnItemIndex = i
                break
            end
        end

        if btnTab.checkValid and not btnTab.checkValid() then
            return
        end

        local needCheckBounce
        
        local isSameTab = (self._focusedTab == btnTab)
        if not isSameTab then
            local btn = self._focusedTab
            if btn then
                if btn._tabArea then
                    btn._tabArea:setVisible(false)
                end
                btn:loadTextureNormal("img_btn_tab_bg_unfocus_6", ccui.TextureResType.plistType)
                btn._label:setColor(cc.c3b(134, 226, 227))
                btn._label:setPositionY(lc.ch(btn) - 4)

                --if btn._scaleSize then btn:setContentSize(btn._scaleSize) end
            end
        
            self._focusedTab = btnTab
            if btnTab._tabArea then
                btnTab._tabArea:setVisible(true)
            end
            btnTab:loadTextureNormal("img_btn_tab_bg_focus_6", ccui.TextureResType.plistType)
            btnTab._label:setColor(_M.COLOR_TEXT_TITLE)
            btnTab._label:setPositionY(lc.ch(btnTab))

            --if btnTab._scaleSize then btnTab:setContentSize(btnTab._scaleSize) end
        else
            if btnTab._tabArea then
                btnTab._tabArea:setVisible(true)
            end
        end

        if self._callback and btnTab._tabArea == nil then
            self._callback(btnTab, isSameTab, isUserBehavior)
        end


        if needCheckBounce then
            self:checkListBounce()
        end

        if not isUserBehavior then
            -- make tab visible
            local innerHeight = list:getInnerContainerSize().height
            local pos = math.max(innerHeight - lc.bottom(btnTab) - lc.h(list) + list:getItemsMargin(), 0)
            list:gotoPos(pos)
        end
    end

    area.createTab = function(self, tab, i, scaleSize)
        local btn = _M.createShaderButton("img_btn_tab_bg_unfocus_6")

        if scaleSize then
            btn:ignoreContentAdaptWithSize(false)
            btn:setContentSize(scaleSize)
            btn._scaleSize = scaleSize
        end

        local str, icon
        if type(tab) == "string" then
            str = tab

            btn._index = i
        else
            str = tab._str

            btn._index = tab._index or i
            btn._userData = tab._userData
            btn._tabs = tab._tabs
            btn._isSub = tab._isSub

            btn.checkValid = tab.checkValid
        end
               
        if btn._tabs then
            local height = #btn._tabs * _M.CRECT_BUTTON_1_S.height + (#btn._tabs - 1) * 10 + 30
            local tabArea = _M.createVerticalTabListArea2(height, btn._tabs, callback)
            lc.addChildToPos(self:getParent(), tabArea, cc.p(lc.left(self) + i * (lc.w(btn) + 8.8) - 67, lc.y(self) - lc.ch(tabArea) - 27), 3)
            --lc.addChildToCenter(btn, tabArea, 3)
            tabArea:setVisible(false)
            btn._tabArea = tabArea
        end
        btn:setName(str)
        btn:addLabel(str, btn._isSub and cc.c3b(134, 226, 227) or cc.c3b(134, 226, 227))
        lc.offset(btn._label, 0, -8)
        btn:setColor(btn._isSub and cc.c3b(134, 226, 227) or lc.Color3B.white)
        btn._label:setPositionY(lc.ch(btn) - 4)
        btn._callback = function() area:showTab(btn._index, true) end

        return btn
    end

    area.resetTabs = function(self, tabs)
        list:removeAllItems()
        self._focusedTab = nil
        self._expandedTabIndex = -1


        -- Add tab buttons
        for i, tab in ipairs(tabs) do
            local btnTab = self:createTab(tab, i)
            list:pushBackCustomItem(btnTab)
        end
    end

    area.focusAtPos = function(self, pos)
        local item = list:getItems()[pos]
        if item then
            self:showTab(item._index)
        end
    end

    if tabs then
        area:resetTabs(tabs)
    end

    return area
end

function _M.createHorizontalTabListArea3(width, tabs, callback, bgColor)
    local size = cc.size(width, _M.HORIZONTAL_TAB_HEIGHT)
    local area = lc.createNode(size)
    local listSize = cc.size(width, size.height)

    -- fix
    local list = lc.List.createH(listSize, 20, 8)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(area, list)
    lc.offset(list, 6, 0)
    
    area._list = list
    area._callback = callback
    
    area.showTab = function(self, index, isUserBehavior)
        local items, btnTab, btnItemIndex = list:getItems()
        for i, item in ipairs(items) do
            if item._index == index then
                btnTab = item
                btnItemIndex = i
                break
            end
        end

        if btnTab.checkValid and not btnTab.checkValid() then
            return
        end

        local needCheckBounce
        -- sub tab
        if btnTab._tabs then
        
            if btnItemIndex == self._expandedTabIndex then
                if self._focusedTab and self._focusedTab._expandedIndex == btnItemIndex then
                    self._focusedTab = nil
                end

                local expandedBtn = items[self._expandedTabIndex]
                for i = 1, #expandedBtn._tabs do
                    list:removeItem(self._expandedTabIndex)
                end
                self._expandedTabIndex = -1
            else
                if self._focusedTab and self._focusedTab._index ~= nil and self._focusedTab._isSub then
                    self._focusedTab = nil
                end

                if self._expandedTabIndex ~= -1 then
                    local expandedBtn = items[self._expandedTabIndex]
                    for i = 1, #expandedBtn._tabs do
                        list:removeItem(self._expandedTabIndex)
                    end
                    self._expandedTabIndex = -1
                  
                end

                local items, btnTab, btnItemIndex = list:getItems()
                for i, item in ipairs(items) do
                    if item._index == index then
                        btnTab = item
                        btnItemIndex = i
                        break
                    end
                end
                --[[
                local height = #btnTab._tabs * _M.CRECT_BUTTON_1_S.height + (#btnTab._tabs - 1) * 2
                local posY = _M.CRECT_BUTTON_1_S.height / 2
                local panel = lc.createSprite({_name = "img_com_bg_30", _crect = cc.rect(20, 20, 1, 1), _size = cc.size(120, height)})
                lc.addChildToPos(btnTab, panel, cc.p(lc.cw(btnTab), - lc.ch(panel)), 3)
                ]]
                for _, tab in ipairs(btnTab._tabs) do
                    local btn = self:createTab(tab, tab._subIndex)
                    --[[
                    lc.addChildToPos(panel, btn, cc.p(lc.cw(panel), posY))
                    posY = posY + _M.CRECT_BUTTON_1_S.height + 2]]
                    list:insertCustomItem(btn, btnItemIndex)
                end
                self._expandedTabIndex = btnItemIndex
            end
            
            needCheckBounce = true

            if self._subTabExpandCallback then
                self._subTabExpandCallback(btnTab)
            end

        else
            local isSameTab = (self._focusedTab == btnTab)
            if not isSameTab then
                local btn = self._focusedTab
                if btn then
                    btn:loadTextureNormal("img_btn_tab_bg_unfocus_5", ccui.TextureResType.plistType)
                    btn:setColor(btn._isSub and cc.c3b(180, 250, 255) or lc.Color3B.white)
                    btn._label:setColor(cc.c3b(134, 226, 227))
                    btn._label:setPositionY(lc.ch(btn) - 4)
                    --btn:setEnabled(true)
                    --btn:setSwallowTouches(true)

                    if btn._isSub then
                        btn._expandedIndex = nil
                        
                    end

                    --if btn._scaleSize then btn:setContentSize(btn._scaleSize) end
                end
        
                self._focusedTab = btnTab
                if btnTab._isSub then
                    btnTab._expandedIndex = self._expandedTabIndex
                    btnTab._label:setColor(cc.c3b(134, 226, 227))
                    btnTab._label:setPositionY(lc.ch(btnTab) - 4)
                end

                btnTab:loadTextureNormal("img_btn_tab_bg_focus_5", ccui.TextureResType.plistType)
                btnTab._label:setColor(_M.COLOR_TEXT_TITLE)
                btnTab._label:setPositionY(lc.ch(btnTab))
                --btnTab:setEnabled(false)
                --btnTab:setSwallowTouches(false)

                --if btnTab._scaleSize then btnTab:setContentSize(btnTab._scaleSize) end
            end

            if self._callback then
                self._callback(btnTab, isSameTab, isUserBehavior)
            end
        end

        if needCheckBounce then
            self:checkListBounce()
        end

        if not isUserBehavior then
            -- make tab visible
            local innerHeight = list:getInnerContainerSize().height
            local pos = math.max(innerHeight - lc.bottom(btnTab) - lc.h(list) + list:getItemsMargin(), 0)
            list:gotoPos(pos)
        end
    end

    area.createTab = function(self, tab, i, scaleSize)
        local btn = _M.createShaderButton("img_btn_tab_bg_unfocus_5")

        if scaleSize then
            btn:ignoreContentAdaptWithSize(false)
            btn:setContentSize(scaleSize)
            btn._scaleSize = scaleSize
        end

        local str, icon
        if type(tab) == "string" then
            str = tab

            btn._index = i
        else
            str = tab._str

            btn._index = tab._index or i
            btn._userData = tab._userData
            btn._tabs = tab._tabs
            btn._isSub = tab._isSub

            btn.checkValid = tab.checkValid
        end

        btn:setName(str)
        btn:addLabel(str, btn._isSub and cc.c3b(134, 226, 227) or cc.c3b(134, 226, 227))
        lc.offset(btn._label, 0, 0)
        btn:setColor(btn._isSub and cc.c3b(134, 226, 227) or lc.Color3B.white)
        btn._label:setPositionY(lc.ch(btn) - 4)
        btn._callback = function() area:showTab(btn._index, true) end

        return btn
    end

    area.resetTabs = function(self, tabs)
        list:removeAllItems()
        self._focusedTab = nil
        self._expandedTabIndex = -1


        -- Add tab buttons
        for i, tab in ipairs(tabs) do
            local btnTab = self:createTab(tab, i)
            list:pushBackCustomItem(btnTab)
        end

        self:checkListBounce()
    end

    area.checkListBounce = function(self)
        list:forceDoLayout()

        local innerHeight = list:getInnerContainerSize().height
        list:setBounceEnabled(innerHeight > listSize.height)
    end

    area.focusAtPos = function(self, pos)
        local item = list:getItems()[pos]
        if item then
            self:showTab(item._index)
        end
    end

    if tabs then
        area:resetTabs(tabs)
    end

    return area
end
