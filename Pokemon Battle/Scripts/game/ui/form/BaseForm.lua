local _M = class("BaseForm", require("BasePanel"))

_M.LEFT_MARGIN = 36
_M.RIGHT_MARGIN = 36
_M.TOP_MARGIN = 30
_M.BOTTOM_MARGIN = 30

_M.FRAME_THICK_LEFT = 36
_M.FRAME_THICK_RIGHT = 36
_M.FRAME_THICK_H = _M.FRAME_THICK_LEFT + _M.FRAME_THICK_RIGHT
_M.FRAME_THICK_TOP = 30
_M.FRAME_THICK_BOTTOM = 30
_M.FRAME_THICK_V = _M.FRAME_THICK_TOP + _M.FRAME_THICK_BOTTOM

_M.TAB_CRECT = cc.rect(36, 0, 1, 86)
_M.TAB_Y_FOCUS = 21
_M.TAB_Y_UNFOCUS = 23
_M.TAB_COLOR_UNFOCUS = cc.c3b(100, 100, 100)
_M.TAB_COLOR_LABEL_UNFOCUS = cc.c3b(110, 170, 60)

_M.ACTION_DURATION = 0.3

_M.FLAG = {
    BASE_TITLE_BG       = 0x0001,
    ADVANCE_TITLE_BG    = 0x0002,
    PAPER_BG            = 0x0004,
    TOP_AREA            = 0x0008,
    BOTTOM_AREA         = 0x0010,
    SCROLL_V            = 0x0020,
    SCROLL_H            = 0x0040,
    NO_CLOSE_BTN        = 0x0080,
    TTF_TITLE           = 0x0100,
}

function _M:init(size, title, flag, isForce)
    _M.super.init(self, isForce)

    -- Form content main container
    self._form = ccui.Widget:create()
    self._form:setContentSize(size)
    self._form:setTouchEnabled(true)
    self._form:setAnchorPoint(0.5, 0.5)

    -- Add form frame
    --[[
    local frame = V.createFrameBox(size)    
    lc.addChildToCenter(self._form, frame)
    self._frame = frame
    ]]
    -- Add snow images
    --[[
    local snow1 = lc.createSpriteWithMask("res/jpg/img_ui_snow_1.jpg")
    local snow2 = lc.createSpriteWithMask("res/jpg/img_ui_snow_2.jpg")
    lc.addChildToPos(frame, snow1, cc.p(size.width - _M.FRAME_THICK_RIGHT - lc.w(snow1) / 2, size.height - 11))
    lc.addChildToPos(frame, snow2, cc.p(_M.FRAME_THICK_LEFT + lc.w(snow2) / 2 - 16, size.height - 9))
    ]]--
    
    -- Create form according to the flag
    flag = flag or 0

    local bgOffset = cc.p(0, -2)
    local bgSize = cc.size(lc.w(self._form) - _M.FRAME_THICK_LEFT - _M.FRAME_THICK_RIGHT, lc.h(self._form) - _M.FRAME_THICK_TOP - _M.FRAME_THICK_BOTTOM)

    if band(flag, _M.FLAG.TOP_AREA) ~= 0 then
        self:addTopBg()
        bgSize.height = bgSize.height - 64
    end
    
    if band(flag, _M.FLAG.BOTTOM_AREA) ~= 0 then
        self:addBottomBg()
        bgSize.height = bgSize.height - 72
        bgOffset.y = bgOffset.y + 72
    end

    --self._bg = V.createShadowColorBg(bgSize)

    --lc.addChildToPos(self._form, self._bg, cc.p(_M.FRAME_THICK_LEFT + lc.w(self._bg) / 2 + bgOffset.x, _M.FRAME_THICK_BOTTOM + lc.h(self._bg) / 2 + bgOffset.y), -1)

    local offsetY = 0
    if title then
        
        local frame = V.createFrameBox(size, title) 
        lc.addChildToCenter(self._form, frame)
        self._frame = frame

        local titleBg
        if band(flag, _M.FLAG.BASE_TITLE_BG) ~= 0 then
            titleBg = ccui.Scale9Sprite:createWithSpriteFrameName("img_form_title_bg_2", V.CRECT_FORM_TITLE_BG2)
            titleBg:setContentSize(lc.w(self._form) - _M.LEFT_MARGIN - _M.RIGHT_MARGIN, V.CRECT_FORM_TITLE_BG2.height)
            lc.addChildToPos(self._form, titleBg, cc.p(lc.w(self._form) / 2, lc.h(self._form) - _M.TOP_MARGIN - lc.h(titleBg) / 2), 10)
            
            local titleLabel = cc.Label:createWithTTFStroke(title, V.TTF_FONT, V.FontSize.M1)
            titleLabel:setColor(V.COLOR_TEXT_LIGHT)
            titleLabel:setPosition(lc.w(titleBg) / 2, lc.h(titleBg) / 2 + 4)
            titleBg:addChild(titleLabel)
            self._titleLabel = titleLabel
        else    
           
            titleBg = lc.createNode()
            titleBg:setContentSize(cc.size(560, V.CRECT_FORM_TITLE_BG1_CRECT.height))
            
            lc.addChildToPos(self._form, titleBg, cc.p(lc.w(self._form) / 2, lc.h(self._form) - lc.h(titleBg) / 2 + 10), 10)
            --[[
            local light = lc.createSprite({_name = "img_form_title_light_1", _crect = V.CRECT_FORM_TITLE_LIGHT1_CRECT, _size = cc.size(200, V.CRECT_FORM_TITLE_LIGHT1_CRECT.height)})
            lc.addChildToPos(titleBg, light, cc.p(lc.w(titleBg) / 2, lc.h(titleBg) / 2 + 4))
            ]]
            local titleLabel
            
            titleLabel = V.createTTFStroke(title, V.FontSize.M1)

            titleLabel:setColor(V.COLOR_TEXT_WHITE)
            titleLabel:setPosition(lc.w(self._form) / 2, lc.h(self._form) - lc.h(titleLabel) / 2 - 12)
            self._form:addChild(titleLabel)
            self._titleLabel = titleLabel

            --offsetY = -(lc.top(titleBg) - lc.h(self._form)) / 2
        end

        self._titleFrame = titleBg
    else
        local frame = V.createFrameBox(size) 
        lc.addChildToCenter(self._form, frame)
        self._frame = frame
    end   
    
    --[[
    self._form:setPosition(lc.cw(self), lc.h(self) / 2 + offsetY)
    self:addChild(self._form)]]
    lc.addChildToCenter(self, self._form)
    
    if band(flag, _M.FLAG.NO_CLOSE_BTN) == 0 then
        local btnBack = V.createShaderButton("img_btn_close", function(sender) self:hide() end)
        btnBack:setZoomScale(0)
        btnBack:setPosition(lc.w(self._form) - 56 + 36, lc.h(self._form) - 36 + 8)
        btnBack:setTouchRect(cc.rect(0, 0, lc.w(btnBack) + 30, lc.h(btnBack) + 30))
        self._form:addChild(btnBack, 20)
        self._btnBack = btnBack
    end
end

function _M:addTopBg()
    local topBg = cc.Sprite:createWithSpriteFrameName("img_com_bg_8")
    topBg:setScaleX((lc.w(self._form) - _M.LEFT_MARGIN - _M.RIGHT_MARGIN) / lc.w(topBg) + 0.1)          -- Add 0.1 to avoid transparent edge on left and right after scale
    topBg:setScaleY(1.2)
    lc.addChildToPos(self._form, topBg, cc.p(lc.w(self._form) / 2, lc.h(self._form) - _M.FRAME_THICK_TOP - lc.sh(topBg) / 2 + 6), -2)
    self._frameTopBg = topBg    
end

function _M:addBottomBg()
    local bottomBg = V.createLineSprite("img_bottom_bg", lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT)
    lc.addChildToPos(self._frame, bottomBg, cc.p(lc.w(self._frame) / 2, V.FRAME_INNER_BOTTOM + lc.h(bottomBg) / 2 - 6), -1)
    self._frameBottomBg = bottomBg
end

function _M:show(isForce)
    _M.hideTopMost()

    if lc._runningScene and lc._runningScene._scene then
        if self:getParent() then
            if isForce then
                lc.changeParent(self, nil, lc._runningScene._scene, ClientData.ZOrder.form)
            else
                return
            end
        else
            lc._runningScene._scene:addChild(self, ClientData.ZOrder.form)
        end

        if self._form:getNumberOfRunningActions() == 0 then
            local dstPos = cc.p(lc.x(self._form), lc.y(self._form))
            self._form:setPosition(lc.w(self) / 2, -lc.h(self._form))
            self._form:runAction(lc.sequence(lc.ease(lc.moveTo(lc.absTime(_M.ACTION_DURATION), dstPos), "SineO"), function() 
                if self.onShowActionFinished then
                    self:onShowActionFinished()
                end
            end))
        end
    end
end

function _M:hide(isForce)
    if self:getParent() == nil then return end
    
    if isForce then
        self:removeFromParent()
        return
    end
    
    if self._form:getNumberOfRunningActions() == 0 then
        V.blockTouch(self)

        self._form:runAction(cc.Sequence:create(cc.EaseSineIn:create(cc.MoveTo:create(lc.absTime(_M.ACTION_DURATION), cc.p(lc.w(self) / 2, -lc.h(self._form)))), cc.CallFunc:create(function() 
            if self.onHideActionFinished then
                self:onHideActionFinished()
            end   
            self:removeFromParent()
        end)))
    end
end

function _M:addTabs(nameArr, focusTab)
    if nameArr == nil or #nameArr == 0 then return end

    if self._tabs then
        for i = 1, #self._tabs do
            self._tabs[i]:removeFromParent(true)
        end
    end
    
    self._tabs = {}

    local tabMarginLeft = 50
    local tabSpace = 5
    local tabWidth = (lc.w(self._form) - 2 * tabMarginLeft - (#nameArr - 1) * tabSpace) / #nameArr
    local x = tabMarginLeft     
    for i = 1, #nameArr do
        local tab = V.createScale9ShaderButton("img_form_tab_focus", function(sender) self:showTab(nameArr[i], false) end, _M.TAB_CRECT, tabWidth)
        tab:setColor(_M.TAB_COLOR_UNFOCUS)
        tab:setAnchorPoint(0.5, 1.0)
        tab:addLabel(nameArr[i])
        tab._label:setColor(_M.TAB_COLOR_LABEL_UNFOCUS)
        tab:setPosition(x + tabWidth / 2, _M.TAB_Y_UNFOCUS)
        
        x = x + tabWidth + tabSpace
        
        self._frame:addChild(tab, -1, i)
        self._tabs[nameArr[i]] = tab
    end

    local offsetY = lc.bottom(self._tabs[nameArr[1]])
    self._form:setPositionY(math.floor(lc.y(self._form) - offsetY / 2 + 6))
    
    if focusTab then
        self:showTab(nameArr[focusTab], true)
    else
        self:showTab(nameArr[1], true)
    end
end

function _M:showTab(name, isForce)
    local tab = self._tabs[name]
    if tab == nil then return false end

    local focusTab = self._focusTab
    if focusTab == tab and (not isForce) then return false end
    
    if focusTab then
        focusTab:setColor(_M.TAB_COLOR_UNFOCUS)
        focusTab:setLocalZOrder(-1)
        focusTab:setPositionY(_M.TAB_Y_UNFOCUS)
        focusTab._label:setColor(_M.TAB_COLOR_LABEL_UNFOCUS)
    end
    
    self._focusTab = tab

    tab:setColor(lc.Color3B.white)
    tab:setLocalZOrder(1)
    tab:setPositionY(_M.TAB_Y_FOCUS)
    tab._label:setColor(lc.Color3B.white)
    
    return true    
end

function _M:showFormTip(tipStr, callback, offX, offY)
    if self._tip then
        self._tip:removeFromParent()
    end

    local tip = V.createBoldRichText(tipStr, {_normalClr = V.COLOR_TEXT_DARK, _boldClr = V.COLOR_TEXT_ORANGE_DARK, _fontSize = V.FontSize.S1})
    
    local tipBg = lc.createImageView{_name = "img_tip_bg", _crect = V.CRECT_TIP_BG, _size = cc.size(lc.w(tip) + 90, lc.h(tip) + 100)}
    tipBg:setScale(0)
    tipBg:setAnchorPoint(0, 0)

    lc.addChildToPos(tipBg, tip, cc.p(lc.w(tip) / 2 + 45, lc.h(tip) / 2 + 70))
    lc.addChildToPos(self._form, tipBg, cc.p(10 + (offX or 0), lc.h(self._form) - 60 + (offY or 0)), 20)
    
    if callback then
        tipBg:setTouchEnabled(true)
        tipBg:addTouchEventListener(function(sender, type)
            if type == ccui.TouchEventType.ended then
                callback()
            end
        end)
    end
    
    tipBg:runAction(lc.ease(lc.scaleTo(0.4, 1), "BackO"))

    self._tip = tipBg
end

BaseForm = _M
return _M