local _M = class("BasePanel", lc.ExtendUIWidget)

_M.DEFAULT_MASK_OPACITY = 192
_M.Panels = {}

function _M:init(isForce, hideBg)
    self._isForce = isForce
    self._hideBg = hideBg
    self._ignoreBlur = (lc._runningScene and lc._runningScene._sceneId == ClientData.SceneId.battle)

    self:addTouchEventListener(function(sender, type)
        if type == ccui.TouchEventType.ended then            
            if not self._isForce then
                self:hide()
            end
        end
    end)
    
    return true
end

function _M:onEnter()
    self._blurListener = lc.addEventListener("director_after_blur", function(event) self:afterBlur(event) end)

    local isInsert = false
    for i = 1, #_M.Panels do
        if self:getLocalZOrder() < _M.Panels[i]:getLocalZOrder() then
            table.insert(_M.Panels, i, self)
            isInsert = true
            break
        end
    end
    if not isInsert then
        table.insert(_M.Panels, self)
    end

    if not self._ignoreBlur then
        self:updateBg()
    end

    --[[
    if self._panelName then
        ClientData.sendUserEvent({panelEnter = self._panelName})
    end
    --]]
end

function _M:onExit()
    lc.Dispatcher:removeEventListener(self._blurListener)

    for i = 1, #_M.Panels do
        if _M.Panels[i] == self then
            table.remove(_M.Panels, i)
            break
        end
    end

    if not self._ignoreBlur then
        self:updateBg()
    end

    --[[
    if self._panelName then
        ClientData.sendUserEvent({panelExit = self._panelName})
    end
    --]]
end
 
function _M:onCleanup()
end

function _M:updateBg()

    -- 1. set all layers to visible except guidance layers
    local parent = self:getParent()
    local children = parent:getChildren()
    for i = 2, #children do
        children[i]:setVisible(children[i]:getLocalZOrder() ~= ClientData.ZOrder.guide)
    end

    -- 2. set all panels to invisible, and find top panel with bg
    local topPanelWithBg = nil
    for i = #_M.Panels, 1, -1 do
        local panel = _M.Panels[i]
        panel:setVisible(false)
        if (not panel._hideBg) and (topPanelWithBg == nil) then
            topPanelWithBg = panel
        end
    end

    if topPanelWithBg ~= nil then
        -- 3. if top panel with bg exists, add existed blurred bg or create new blurred bg
        if _M._blurredBg == nil then
            local blurredBg = lc.Director:getBlurredScene()
            blurredBg:setBlendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA)
            _M._blurredBg = blurredBg

            -- NOTE: if creating new blurred bg, set _M._isBlurring to let updatePanels called in afterBlur
            _M._isBlurring = true
        end

        _M._blurredBg:removeFromParent()
        topPanelWithBg:addChild(_M._blurredBg, -1)
    else
        -- 4. if top panel with bg doesn't exist, set _M._blurredBg to nil
        _M._blurredBg = nil
    end

    -- 5. if not creating new blurred bg, call updatePanels now
    if not _M._isBlurring then
        self:updatePanels()
    end
end

function _M:afterBlur(event)
    if self == _M.Panels[#_M.Panels] then
        _M._isBlurring = false
        self:updatePanels()

        local scene = self:getParent()._layer
        if scene._sceneId == ClientData.SceneId.battle then
            -- NOTE: to avoid flicker effect for scenes with camera 3D, keep children[i] display one more frame then set to invisible
            scene:setVisible(true)
            scene:runAction(cc.Sequence:create(
                cc.DelayTime:create(0),
                cc.CallFunc:create(function() 
                    local nodes = {scene._battleUi, scene._battleUi._layer, scene._battleUi._skySpr}
                    for i = 1, #nodes do
                        local node = nodes[i]
                        local x = node:getPosition()
                        node:setPositionX(x + 1) 
                        node:setPositionX(x) 
                    end
                    scene:setVisible(false)
                end)))
        end
    end
end

function _M:show(zorder)
    _M.hideTopMost()
    lc._runningScene._scene:addChild(self, zorder or ClientData.ZOrder.form)
end

function _M:hide()
    self:removeFromParent()
end

function _M.hideTopMost()
    if _M._topMostPanel then
        _M._topMostPanel:hide()
    end
end

function _M:updatePanels()
    local panelCount = #_M.Panels
    local sceneId = lc._runningScene._sceneId

    local visiblePanels = {}
    if panelCount > 0 then  
        local topPanel = _M.Panels[panelCount]
          
        local isVisible = true
        local opacity = 0
        for i = panelCount, 1, -1 do
            local panel = _M.Panels[i]
            panel:setVisible(isVisible)
            if (not panel._hideBg) and isVisible then
                isVisible = false            
            end            

            if panel:isVisible() then
                if (not panel._hideBg) then
                    table.insert(visiblePanels, panel)
                end

                if panel.setBackGroundColorOpacity then                    
                    if panel._isNeedTransparent then
                        panel:setBackGroundColorOpacity(0)
                    else
                        if opacity == 0 then
                            opacity = _M.DEFAULT_MASK_OPACITY
                            panel:setBackGroundColorOpacity(opacity)
                        else
                            panel:setBackGroundColorOpacity(0)
                        end
                    end
                end
            end
        end

        if sceneId ~= ClientData.SceneId.loading and sceneId ~= ClientData.SceneId.region then
            if topPanel:getLocalZOrder() ~= ClientData.ZOrder.indicator and topPanel:getLocalZOrder() ~= ClientData.ZOrder.dialog then
                local zorder = topPanel._isShowResourceUI and (topPanel:getLocalZOrder() + 1) or ClientData.ZOrder.ui
                V.getResourceUI():setLocalZOrder(zorder)
            end
        end
    else
        if sceneId ~= ClientData.SceneId.loading and sceneId ~= ClientData.SceneId.region then
            V.getResourceUI():setLocalZOrder(ClientData.ZOrder.ui)
        end
    end

    local parent = self:getParent()
    local children = parent:getChildren()
    local topZOrder = #visiblePanels > 0 and visiblePanels[1]:getLocalZOrder() or -1
    local bottomZOrder = #visiblePanels > 0 and visiblePanels[#visiblePanels]:getLocalZOrder() or -1
    for i = 2, #children do
        if children[i]:getLocalZOrder() < bottomZOrder then
           children[i]:setVisible(false)
        elseif children[i]:getLocalZOrder() > topZOrder then
            children[i]:setVisible(true)
        end
    end
end

function _M:addBackButton()
    local btnBack = V.createScale9ShaderButton("img_btn_2_s", function(sender)
        self:hide()
    end, V.CRECT_BUTTON_1_S, 180)
    btnBack:addLabel(Str(STR.BACK))
    btnBack:setPosition(lc.w(self) / 2, 60)
    btnBack:setTouchRect(cc.rect(-20, -20, lc.w(btnBack) + 40, lc.h(btnBack) + 40))
    btnBack:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)
    self:addChild(btnBack)

    self._btnBack = btnBack
end

BasePanel = _M
return _M