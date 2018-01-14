local _M = class("ActiveIndicator", require("BasePanel"))

local TIME_OUT = 30

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
    return panel
end

function _M:init()   
    _M.super.init(self, true, true)

    self._ignoreBlur = true

    self.Label = ccui.Text:create("", V.TTF_FONT, V.FontSize.M2)    
    self.Label:setColor(cc.c3b(18, 186, 255))
    self:addChild(self.Label)    
end

function _M:show(label, hideDuration, userData, timeoutDuration)
    self._userData = userData
    self._isShowing = true

    if self:getParent() == nil then
        if label == nil then self._isNeedTransparent = true end
        lc._runningScene._scene:addChild(self, ClientData.ZOrder.indicator)
    end
    
    if self._spine == nil then
        self._spine = V.createSpine('dengdai')
        self._spine:setAnimation(0, 'animation', true)
        self:addChild(self._spine)
        
        self._spine:setPosition(lc.w(self) / 2, lc.h(self) / 2 + 80)        
    end
    
    self.Label:setVisible(false)
    self._spine:setVisible(false)
    self:setBackGroundColorOpacity(0)
    
    self._timestamp = lc.Director:getCurrentTime()
    
    self:stopAllActions()
    
    local timeout = timeoutDuration or TIME_OUT
    if timeout > 0 then
        self:runAction(lc.sequence(timeout,
            function()
                local scene = lc._runningScene
                if scene and scene._reloadDialog == nil then
                    scene:showReloadDialog(Str(STR.DISCONNECT), msgStatus)
                end
            end
        ))
    end

    if label == nil then return end

    self.Label:setPosition(lc.w(self) / 2, lc.h(self) / 2 - 60)
    self.Label:setString(label)

    local duration = hideDuration or 0
    self:runAction(lc.sequence(duration,
        function() 
            self.Label:setVisible(true)
            
            self._spine:setVisible(true)

            self:setBackGroundColorOpacity(_M.DEFAULT_MASK_OPACITY)
        end
    ))
end

function _M:hide()
    local userData = self._userData
    self._userData = nil
    self._isShowing = false

    if self:getParent() ~= nil then
        self:removeFromParent(false)
    end
    
    if self._spine ~= nil then
        self._spine:removeFromParent()
        self._spine = nil
    end
    self:stopAllActions()
    
    return userData
end

function _M:getDuration()
    return lc.Director:getCurrentTime() - self._timestamp
end

return _M