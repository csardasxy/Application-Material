local _M = class("FreeShowPanel", lc.ExtendCCNode)

--[[--
Enumerations used in this module
--]]--
_M.STATE_IDLE               = 0
_M.STATE_MOVING             = 1
_M.STATE_MOVING_INERTIA     = 2
_M.STATE_MOVING_BACK        = 3
_M.STATE_SCALING            = 4
_M.STATE_SCALING_BACK       = 5
_M.STATE_SCALING_WAITING    = 6

--[[--
Enumerations used in this module
--]]--
_M.Event = 
{    
    offset                  = "FREESHOWPANEL_OFFSET",
    scale                   = "FREESHOWPANEL_SCALE",
    animate_stopped         = "FREESHOWPANEL_ANIMATE_STOPPED",
}

--[[--
Private variables and methods
--]]--
local INERTIA_ACCLERATION           = 100
local INERTIA_ACC_FACTOR            = 4
local INERTIA_VELOCITY_MIN          = 400

local _scheduler = lc.Scheduler
local _touchId1, _touchId2

function _M.create(size, restrictDir, isSupportScale)
    local panel = _M.new(lc.EXTEND_LAYER)
    panel:ignoreAnchorPointForPosition(false)
    panel:init(size, restrictDir, isSupportScale)
    return panel
end

function _M:init(size, restrictDir, isSupportScale)
    self:setContentSize(size or {})

    self._moveBufferRatio = {l = 0, r = 0, t = 0, b = 0}
    self._moveBackTime = 0.4
    self._moveDampFactor = 0.3
    self._moveVelocity = {x = 0, y = 0}
    self._moveAcc = {x = 0, y = 0}
    self._moveBackPos = {x = 0, y = 0}
    
    self._touchCount = 0
    self._touchEnabled = true
    
    self._state = _M.STATE_IDLE
    self._scheduleId = {}
    self._moveBound = {x = 0, y = 0, width = 0, height = 0}

    self._maxMoveVelocity = 1000
    self._moveRestrictDir = restrictDir or lc.Dir.none
    self._isSupportScale = isSupportScale
    if self._isSupportScale then
        self._scaleMin = 0.5
        self._scaleMax = 1.0
        
        self._scaleBackTime = 0.4
        self._scaleDampFactor = 0.3
        self._scaleWaitingInterval = 0.1    

    else
        self._scaleMin = 1.0
        self._scaleMax = 1.0

    end

    self._scaleMinBuffer = 0
    self._scaleMaxBuffer = 0
    
    -- Register cleanup handler to release all listeners
    self:registerScriptHandler(function(evtName)
        if evtName == "enter" then self:onEnter()
        elseif evtName == "exit" then self:onExit()
        end
    end)
end

function _M:onEnter()
    local onGestureFunc = function(event) if self:onGesture(event) then event:stopPropagation() end end

    if self._moveRestrictDir == lc.Dir.none then
        lc.addGestureEventListener(lc.Gesture.GestureEvent.pan, onGestureFunc, self)
    else
        lc.addGestureEventListener(lc.Gesture.GestureEvent.swipe, onGestureFunc, self)
    end
    
    if self._isSupportScale then
        lc.addGestureEventListener(lc.Gesture.GestureEvent.pinch, onGestureFunc, self)
    end
    
    lc.addGestureEventListener(lc.Gesture.TouchEvent.began, onGestureFunc, self)
    lc.addGestureEventListener(lc.Gesture.TouchEvent.ended, onGestureFunc, self)
    lc.addGestureEventListener(lc.Gesture.TouchEvent.cancelled, onGestureFunc, self)
    
    -- Handle mouse event on windows os
    if (lc.PLATFORM == cc.PLATFORM_OS_WINDOWS) then
        local listener = cc.EventListenerMouse:create()
        listener:registerScriptHandler(function(event)
            if GuideManager.isGuideEnabled() then return end
            
            local pos = {x = event:getCursorX(), y = event:getCursorY()}
            local scrollY = event:getScrollY()
            if self._isSupportScale then
                self._state = _M.STATE_SCALING
                self._scaleLocalCenter = self:convertToNodeSpace(pos)
                local scale = scrollY < 0 and 1.1 or 0.9
                self:scaleView(scale)
                
                local newScaleCenter = lc.convertPos(self._scaleLocalCenter, self, self:getParent())
                local prevScaleCenter = lc.convertPos(self:convertToNodeSpace(pos), self, self:getParent())
                local offset = {x = prevScaleCenter.x - newScaleCenter.x, y = prevScaleCenter.y - newScaleCenter.y}
                self:moveView(offset)
                
                self._state = _M.STATE_IDLE
                if (not self:checkScaleBack()) then
                    self:checkMoveBack()
                end
            end
        end, cc.Handler.EVENT_MOUSE_SCROLL)
        
        local dispatcher = self:getEventDispatcher()
        dispatcher:addEventListenerWithSceneGraphPriority(listener, self)
    end 
    
    self._touchCount = 0 
    _touchId1 = -1
    _touchId2 = -1
end

function _M:onExit()
    self:removeAllSchedulers()
    self:getEventDispatcher():removeEventListenersForTarget(self)
end

function _M:setMoveBufferRatio(...)
    local arg = {...}
    local argCount = #arg   
    local ratio = self._moveBufferRatio
    if (argCount == 1) then
        ratio.l, ratio.r, ratio.t, ratio.b = arg[1], arg[1], arg[1], arg[1]
    elseif (argCount == 2) then
        ratio.l, ratio.r, ratio.t, ratio.b = arg[1], arg[1], arg[2], arg[2]
    elseif (argCount == 4) then
        ratio.l, ratio.r, ratio.t, ratio.b = arg[1], arg[2], arg[3], arg[4]
    else
        assert(false, "[FreeShowPanel:setMoveBufferRatio] Argument count is not 1, 2, 4!")
    end
end

function _M:setMoveBoundSize(size)
    self._moveBound.width = size.width
    self._moveBound.height = size.height
end

function _M:onGesture(event)
    assert(self._moveBound.width ~= 0 and self._moveBound.height ~= 0, "The size of move bound must be set!")    

    if (not self._touchEnabled) or (not ClientData._isWorking) or GuideManager.isGuideEnabled() then return end

    local evtName = event:getEventName()
    if (evtName == lc.Gesture.TouchEvent.began) then
        local touch = event.touch
        if (touch.id == 1 or touch.id == 2) then
            self:removeAllSchedulers()
            self._state = _M.STATE_IDLE
            self._moveVelocity = {x = 0, y = 0}
            if (self._isSupportScale) then self._scaleVelocity = 0 end
            --if (self._moveRestrictDir == lc.Dir.none) then touch.budgeLimit = 8 end        -- Reduce budge limit
            
            if (self._touchCount == 0) then
                _touchId1 = touch.id
            else
                _touchId2 = touch.id
            end
            
            self._touchCount = self._touchCount + 1
        end
    elseif (evtName == lc.Gesture.TouchEvent.ended or evtName == lc.Gesture.TouchEvent.cancelled) then
        -- Skip if the cancel event is send by the panel
        if (evtName == lc.Gesture.TouchEvent.cancelled and event.exceptTarget == self) then return end
    
        local touch = event.touch
        if (self._state == _M.STATE_MOVING) then
            if (self:isTouchValidAndRemove(touch)) then
                -- Still move until _moveVelocity becomes zero
                local absVelocityX = math.abs(self._moveVelocity.x)
                local absVelocityY = math.abs(self._moveVelocity.y)
                if (absVelocityX > INERTIA_VELOCITY_MIN or absVelocityY > INERTIA_VELOCITY_MIN) then
                    self:startMoveInertially(absVelocityX, absVelocityY);
                else
                    if ((not self._isSupportScale) or (not self:checkScaleBack())) then
                        self:checkMoveBack()
                    end
                end
            end
        elseif (self._state == _M.STATE_SCALING) then
            if (self:isTouchValidAndRemove(touch)) then
                -- The first touch is ended, waiting for the second touch
                self._state = _M.STATE_SCALING_WAITING
                self._scheduleId.scaleWaitingTimeout = _scheduler:scheduleScriptFunc(function(dt)
                    self._state = _M.STATE_MOVING
                    _scheduler:unscheduleScriptEntry(self._scheduleId.scaleWaitingTimeout) 
                end, self._scaleWaitingInterval, false);
            end
        elseif (self._state == _M.STATE_SCALING_WAITING) then
            if (self:isTouchValidAndRemove(touch)) then
                _scheduler:unscheduleScriptEntry(self._scheduleId.scaleWaitingTimeout)
                
                self._state = _M.STATE_IDLE
                if ((not self._isSupportScale) or (not self:checkScaleBack())) then
                    self:checkMoveBack()
                end
            end
        else
            if (self:isTouchValidAndRemove(touch) and self._touchCount == 0) then
                if ((not self._isSupportScale) or (not self:checkScaleBack())) then
                    self:checkMoveBack()
                end
            end
        end
    elseif (evtName == lc.Gesture.GestureEvent.swipe) then
        if GuideManager.isGuideEnabled() then return end
    
        local gesture = event.gesture
        local touch = gesture.touch
        if (_touchId1 == touch.id) then
            local dir = touch.budgedDir
            if (self._moveRestrictDir == dir) then
                local offset = gesture:getOffset(self:getParent())
                self:handleTouchOffset(gesture, dir == lc.Dir.horizontal and {x = offset, y = 0} or {x = 0, y = offset})
            end
        end
    elseif (evtName == lc.Gesture.GestureEvent.pan) then
        if GuideManager.isGuideEnabled() then return end
        
        local gesture = event.gesture
        local touch = gesture.touch
        if (_touchId1 == touch.id) then
            if (self._moveRestrictDir == lc.Dir.none and touch.budgedDir ~= lc.Dir.none) then
                self:handleTouchOffset(gesture, gesture:getOffset(self:getParent()))
            end
        end
    elseif (evtName == lc.Gesture.GestureEvent.pinch) then
        if GuideManager.isGuideEnabled() then return end
    
        if (self._isSupportScale and self._touchCount == 2) then
            local gesture = event.gesture
            local touch1 = gesture.touch1
            local touch2 = gesture.touch2

            local isStateChanged = false
            if (self._state == _M.STATE_IDLE) then
                self._state = _M.STATE_SCALING
                self._scaleLocalCenter = gesture:getCenter(self)
                isStateChanged = true
            end
            
            local parent = self:getParent()
            
            local scale = gesture:getScale(parent)
            local scaleDelta = self:scaleView(scale)
            local newScaleCenter = parent:convertToNodeSpace(self:convertToWorldSpace(self._scaleLocalCenter))
            local center = gesture:getCenter(parent)
            local offset = cc.p(center.x - newScaleCenter.x, center.y - newScaleCenter.y)
            offset = self:moveView(offset)
            
            lc.Gesture.cancelTouch(touch1, self)
            lc.Gesture.cancelTouch(touch2, self)
        end
    end
end

function _M:removeAllSchedulers()
    for _, id in pairs(self._scheduleId) do
        _scheduler:unscheduleScriptEntry(id)
    end
end

function _M:isTouchValidAndRemove(touch)
    if self._touchCount == 1 then
        _touchId1 = -1
        self._touchCount = self._touchCount - 1
        return true
    elseif self._touchCount == 2 then
        if _touchId1 == touch.id then
            _touchId1 = _touchId2
        end
        _touchId2 = -1
        self._touchCount = self._touchCount - 1
        return true
    end
    
    return false
end

function _M:handleTouchOffset(gesture, offset)
    if (offset.x == 0 and offset.y == 0) then return end

    local isStateChanged = false
    if (self._state == _M.STATE_IDLE) then
        self._state = _M.STATE_MOVING
        isStateChanged = true
    end
    
    local realOffset = self:moveView(offset)
    self._moveVelocity = gesture:getVelocity()
    if self._moveVelocity.x >= 0 then
        self._moveVelocity.x = math.min(self._moveVelocity.x, self._maxMoveVelocity)
    else
        self._moveVelocity.x = math.max(self._moveVelocity.x, -self._maxMoveVelocity)
    end
    if self._moveVelocity.y >= 0 then
        self._moveVelocity.y = math.min(self._moveVelocity.y, self._maxMoveVelocity)
    else
        self._moveVelocity.y = math.max(self._moveVelocity.y, -self._maxMoveVelocity)
    end
    
    --lc.log("vec(%f, %f) offset(%f, %f)", self._moveVelocity.x, self._moveVelocity.y, offset.x, offset.y)
        
    lc.Gesture.cancelTouch(gesture.touch)
end

function _M:moveView(offset)
    --lc.log("moveView offset1(%.2f, %.2f)", offset.x, offset.y)

    local moveBound = self._moveBound
    local moveBoundTop = moveBound.y + moveBound.height
    local moveBoundRight = moveBound.x + moveBound.width
    
    local moveBufRatio = self._moveBufferRatio
    local factor = self._moveDampFactor
    
    local scaledW = lc.sw(self)
    local scaledH = lc.sh(self)
    
    -- Check horizontal limit
    local processed = false
    local left = lc.left(self)
    if (offset.x > 0 and left > moveBound.x - moveBufRatio.l * scaledW) then
        offset.x = offset.x * factor
        processed = true
    end
    if (left + offset.x > moveBound.x) then
        offset.x = moveBound.x - left
        processed = true
    end

    if (not processed) then
        local right = lc.right(self)
        if (right < moveBoundRight + moveBufRatio.r * scaledW) then
            offset.x = offset.x * factor
        end
        if (right + offset.x < moveBoundRight) then
            offset.x = moveBoundRight - right
        end
    end
    
    -- Check vertical limit
    processed = false
    local bottom = lc.bottom(self)
    if (bottom > moveBound.y - moveBufRatio.b * scaledH) then
        offset.y = offset.y * factor
    end
    if (bottom + offset.y > moveBound.y) then
        offset.y = moveBound.y - bottom
    end

    if (not processed) then
        local top = lc.top(self)
        if (top < moveBoundTop + moveBufRatio.t * scaledH) then
            offset.y = offset.y * factor
        end
        if (top + offset.y < moveBoundTop) then
            offset.y = moveBoundTop - top
        end
    end
    
    --lc.log("moveView offset2(%f, %f)", offset.x, offset.y)
    self:setPosOffsetWithEvent(offset.x, offset.y)
    
    return offset
end

function _M:startMoveInertially(absVelocityX, absVelocityY)
    local accFactor = INERTIA_ACCLERATION / (absVelocityX + absVelocityY)
    self._moveAcc.x, self._moveAcc.y = accFactor * absVelocityX / lc.FPS, accFactor * absVelocityY / lc.FPS
    
    self._state = _M.STATE_MOVING_INERTIA
    self._scheduleId.moveInertially = _scheduler:scheduleScriptFunc(function(dt) self:moveInertially(dt) end, lc.FPS, false)
end

function _M:moveInertially(dt)
    local moveBound = self._moveBound
    local isStopMove = false

    -- Process horizontal movement
    local scaledW = lc.sw(self)
    local bufLeft = self._moveBufferRatio.l * scaledW
    local bufRight = self._moveBufferRatio.r * scaledW
    local left = lc.left(self)
    local right = lc.right(self)
    
    local accX = (self._moveVelocity.x > 0 and -self._moveAcc.x or self._moveAcc.x)
    if (bufLeft > 0 and (left - (moveBound.x - bufLeft)) > 0) then
        accX = accX * ((left - (moveBound.x - bufLeft)) * INERTIA_ACC_FACTOR / bufLeft + 1)
    elseif (bufRight > 0 and (right - (moveBound.x + moveBound.width + bufRight)) < 0) then
        accX = accX * ((right - (moveBound.x + moveBound.width + bufRight)) * INERTIA_ACC_FACTOR / bufRight + 1)
    end
    
    local prevVelocityX = self._moveVelocity.x
    local sign = prevVelocityX > 0 and 1 or -1
    self._moveVelocity.x = self._moveVelocity.x + accX * dt
    local offsetX = (sign * math.min(math.abs(prevVelocityX), self._maxMoveVelocity) + sign * math.min(math.abs(self._moveVelocity.x), self._maxMoveVelocity)) / 2 * dt
    if (left + offsetX > moveBound.x) then
        isStopMove = true
        offsetX = moveBound.x - left
    elseif (right + offsetX < moveBound.x + moveBound.width) then
        isStopMove = true
        offsetX = moveBound.x + moveBound.width - right
    end
    
    local isStopMoveX = false
    if (not isStopMove) then
        if ((accX <= 0 and self._moveVelocity.x <= 0) or (accX >= 0 and self._moveVelocity.x >= 0)) then
            self._moveAcc.x, self._moveVelocity.x = 0, 0
            isStopMoveX = true
        end
    end
    
    -- Process vertical movement
    local scaledH = lc.sh(self)
    local bufTop = self._moveBufferRatio.t * scaledH
    local bufBottom = self._moveBufferRatio.b * scaledH
    local top = lc.top(self)
    local bottom = lc.bottom(self)
    
    local accY = (self._moveVelocity.y > 0 and -self._moveAcc.y or self._moveAcc.y)
    if (bufBottom > 0 and (bottom - (moveBound.y - bufBottom)) > 0) then
        accY = accY * ((bottom - (moveBound.y - bufBottom)) * INERTIA_ACC_FACTOR / bufBottom + 1)
    elseif (bufTop > 0 and (top - (moveBound.y + moveBound.height + bufTop)) < 0) then
        accY = accY * ((top - (moveBound.y + moveBound.height + bufTop)) * INERTIA_ACC_FACTOR / bufTop + 1)
    end
    
    local prevVelocityY = self._moveVelocity.y
    sign = prevVelocityY > 0 and 1 or -1
    self._moveVelocity.y = self._moveVelocity.y + accY * dt
    local offsetY = (sign * math.min(math.abs(prevVelocityY), self._maxMoveVelocity) + sign * math.min(math.abs(self._moveVelocity.y), self._maxMoveVelocity)) / 2 * dt
    if (bottom + offsetY > moveBound.y) then
        isStopMove = true
        offsetY = moveBound.y - bottom
    elseif (top + offsetY < moveBound.y + moveBound.height) then
        isStopMove = true
        offsetY = moveBound.y + moveBound.height - top
    end
    
    if (not isStopMove) then
        if ((accY <= 0 and self._moveVelocity.y <= 0) or (accY >= 0 and self._moveVelocity.y >= 0)) then
            self._moveAcc.y, self._moveVelocity.y = 0, 0
            if (isStopMoveX) then isStopMove = true end
        end
    end
    
    --lc.log("of(%f, %f), v(%f, %f), %f", offsetX, offsetY, self._moveVelocity.x, self._moveVelocity.y, dt)
    
    -- Process offset
    self:setPosOffsetWithEvent(offsetX, offsetY)
    
    -- Check stop move
    if (isStopMove) then
        self._state = _M.STATE_IDLE
        _scheduler:unscheduleScriptEntry(self._scheduleId.moveInertially)
        
        self:checkMoveBack()
    end
end

function _M:checkMoveBack(dstScale)
    if self._isAnimating then return false end

    -- Change to dstScale for calculation
    local curScale = self:getScale()
    if (dstScale) then self:setScale(dstScale) end
    
    local moveBound = self._moveBound
    local moveBufRatio = self._moveBufferRatio
    
    -- Check horizontal buffer
    local left = lc.left(self)
    local right = lc.right(self)
    local scaledW = lc.sw(self)
    local isNeedMoveBackX = false
    local diffX = 0
    if (moveBufRatio.l > 0 or moveBufRatio.r > 0) then
        local exp1 = moveBound.x - moveBufRatio.l * scaledW
        local exp2 = moveBound.x + moveBound.width + moveBufRatio.r * scaledW
        if (exp1 - left < -0.001) then
            self._moveBackPos.x = exp1
            diffX = exp1 - left
            isNeedMoveBackX = true
        elseif (exp2 - right > 0.001) then
            self._moveBackPos.x = exp2
            diffX = exp2 - right
            isNeedMoveBackX = true
        end
        
        if (not isNeedMoveBackX) then
            self._moveAcc.x, self._moveVelocity.x = 0, 0
        end
    end
    
    -- Check vertical buffer
    local top = lc.top(self)
    local bottom = lc.bottom(self)
    local scaledH = lc.sh(self)
    local isNeedMoveBackY = false
    local diffY = 0
    if (moveBufRatio.b > 0 or moveBufRatio.t > 0) then
        local exp1 = moveBound.y - moveBufRatio.b * scaledH
        local exp2 = moveBound.y + moveBound.height + moveBufRatio.t * scaledH
        if (exp1 - bottom < -0.001) then
            self._moveBackPos.y = exp1
            diffY = exp1 - bottom
            isNeedMoveBackY = true
        elseif (exp2 - top > 0.001) then
            self._moveBackPos.y = exp2
            diffY = exp2 - top
            isNeedMoveBackY = true
        end
        
        if (not isNeedMoveBackY) then
            self._moveAcc.y, self._moveVelocity.y = 0, 0
        end
    end
    
    -- Resume to current scale
    if (dstScale) then self:setScale(curScale) end
    
    -- Schedule move back
    if (isNeedMoveBackX or isNeedMoveBackY) then
        if (isNeedMoveBackX) then
            self._moveVelocity.x = (diffX + diffX) / self._moveBackTime
            self._moveAcc.x = -self._moveVelocity.x / self._moveBackTime
        end
        
        if (isNeedMoveBackY) then
            self._moveVelocity.y = (diffY + diffY) / self._moveBackTime
            self._moveAcc.y = -self._moveVelocity.y / self._moveBackTime
        end
        
        --lc.log("vec(%f, %f) acc(%f, %f)", self._moveVelocity.x, self._moveVelocity.y, self._moveAcc.x, self._moveAcc.y)
        
        self._state = _M.STATE_MOVING_BACK
        if (self._scheduleId.moveBack) then _scheduler:unscheduleScriptEntry(self._scheduleId.moveBack) end
        self._scheduleId.moveBack = _scheduler:scheduleScriptFunc(function(dt) self:moveBack(dt) end, lc.FPS, false)
        return true
    else
        if (self._state ~= _M.STATE_SCALING_BACK) then
            self._state = _M.STATE_IDLE
        end
        return false
    end
end

function _M:moveBack(dt)
    local isStopMove = false
    local moveAcc = self._moveAcc
    
    -- Process horizontal movement
    local prevVelocityX = self._moveVelocity.x
    self._moveVelocity.x = self._moveVelocity.x + moveAcc.x * dt
    local offsetX = (prevVelocityX + self._moveVelocity.x) / 2 * dt
    if (moveAcc.x > 0 and self._moveVelocity.x >= 0) then
        offsetX = self._moveBackPos.x - lc.left(self)
        isStopMove = true
    elseif (moveAcc.x < 0 and self._moveVelocity.x <= 0) then
        offsetX = self._moveBackPos.x - lc.right(self)
        isStopMove = true
    end
    
    -- Process vertical movement
    local prevVelocityY = self._moveVelocity.y
    self._moveVelocity.y = self._moveVelocity.y + moveAcc.y * dt
    local offsetY = (prevVelocityY + self._moveVelocity.y) / 2 * dt
    if (moveAcc.y < 0 and self._moveVelocity.y <= 0) then
        offsetY = self._moveBackPos.y - lc.top(self)
        isStopMove = true
    elseif (moveAcc.y > 0 and self._moveVelocity.y >= 0) then
        offsetY = self._moveBackPos.y - lc.bottom(self)
        isStopMove = true
    end
    
    --lc.log("moveBack offset(%f, %f)", offsetX, offsetY)
    self:setPosOffsetWithEvent(offsetX, offsetY)
    
    if (isStopMove) then
        self._state = _M.STATE_IDLE
        _scheduler:unscheduleScriptEntry(self._scheduleId.moveBack)
        self._scheduleId.moveBack = nil
    end
end

function _M:scaleView(scale)
    local curScale = self:getScale()
    if (curScale < self._scaleMin or curScale > self._scaleMax) then
        if (scale > 1) then
            scale = (scale - 1) * self._scaleDampFactor + 1
        else
            scale = 1 - (1 - scale) * self._scaleDampFactor
        end
    end
    
    local newScale = scale * curScale
    if (newScale < self._scaleMin - self._scaleMinBuffer) then
        newScale = self._scaleMin - self._scaleMinBuffer
    elseif (newScale > self._scaleMax + self._scaleMaxBuffer) then
        newScale = self._scaleMax + self._scaleMaxBuffer
    end
    
    self:setScaleWithEvent(newScale)
    return newScale - curScale
end

function _M:checkScaleBack()
    if (self._scaleMinBuffer > 0 or self._scaleMaxBuffer > 0) then
        local curScale = self:getScale()
        local isNeedScaleBack = false
        local scaleDiff = 0
        if (curScale < self._scaleMin) then
            scaleDiff = self._scaleMin - curScale
            isNeedScaleBack = true
        elseif (curScale > self._scaleMax) then
            scaleDiff = self._scaleMax - curScale
            isNeedScaleBack = true
        end
        
        if (isNeedScaleBack) then
            self._scaleVelocity = (scaleDiff + scaleDiff) / self._scaleBackTime
            self._scaleAcc = -self._scaleVelocity / self._scaleBackTime
            
            self._state = _M.STATE_SCALING_BACK
            if (self._scheduleId.scaleBack) then _scheduler:unscheduleScriptEntry(self._scheduleId.scaleBack) end
            self._scheduleId.scaleBack = _scheduler:scheduleScriptFunc(function(dt) self:scaleBack(dt) end, lc.FPS, false)
            
            self._isMoveWhenScaleBack = not self:checkMoveBack(curScale + scaleDiff)
            if self._isMoveWhenScaleBack then
                self._scaleCenter = lc.convertPos(self._scaleLocalCenter, self, self:getParent())
            end
            
            return true
        else
            self._state = _M.STATE_IDLE
            return false
        end
    end
    
    return false
end

function _M:scaleBack(dt)
    local scaleAcc = self._scaleAcc

    local prevVelocity = self._scaleVelocity
    self._scaleVelocity = self._scaleVelocity + scaleAcc * dt
    local newScale = self:getScale() + (prevVelocity + self._scaleVelocity) / 2 * dt
    
    local isStopScale = false
    if (scaleAcc < 0 and newScale >= self._scaleMin) then
        newScale = self._scaleMin
        isStopScale = true
    elseif (scaleAcc > 0 and newScale <= self._scaleMax) then
        newScale = self._scaleMax
        isStopScale = true
    end
    
    self:setScaleWithEvent(newScale)
    
    if (self._isMoveWhenScaleBack) then
        local center = lc.convertPos(self._scaleLocalCenter, self, self:getParent())
        self:setPosOffsetWithEvent(self._scaleCenter.x - center.x, self._scaleCenter.y - center.y)
    end
    
    if (not isStopScale) then
        if ((scaleAcc < 0 and self._scaleVelocity <= 0) or (scaleAcc > 0 and self._scaleVelocity >= 0)) then
            isStopScale = true
        end
    end
    
    if (isStopScale) then
        self._state = _M.STATE_IDLE
        _scheduler:unscheduleScriptEntry(self._scheduleId.scaleBack)
    end
end

function _M:setPosOffsetWithEvent(xOffset, yOffset)
    lc.offset(self, xOffset, yOffset)
    
    if (self._isEventEnabled) then
        local event = cc.EventCustom:new(_M.Event.offset)   
        event.offset = {x = xOffset, y = yOffset}
        self:getEventDispatcher():dispatchEvent(event)
    end
end

function _M:setScaleWithEvent(scale)
    local oldScale = self:getScale()
    self:setScale(scale)
    
    if (self._isEventEnabled) then
        local event = cc.EventCustom:new(_M.Event.scale)   
        event.scaleDelta = scale - oldScale
        self:getEventDispatcher():dispatchEvent(event)
    end
end

function _M:animateTo(duration, scale, localPos, globalPos)
    if (self._scheduleId.moveBack) then 
        _scheduler:unscheduleScriptEntry(self._scheduleId.moveBack)
        self._scheduleId.moveBack = nil 
    end

    local size = self:getContentSize()    
    local parentSize = self:getParent():getContentSize()
    
    scale = math.min(self._scaleMax, math.max(self._scaleMin, scale))
    local minGlobalY = parentSize.height - (size.height - localPos.y) * scale
    local maxGlobalY = localPos.y * scale
    local minGlobalX = parentSize.width - (size.width - localPos.x) * scale
    local maxGlobalX = localPos.x * scale
    
    local globalX = math.max(minGlobalX, math.min(maxGlobalX, globalPos.x))
    local globalY = math.max(minGlobalY, math.min(maxGlobalY, globalPos.y))
    
    --lc.log("animate to %f %f %f", globalX, globalY, scale)
    
    local cx = globalX - (localPos.x - size.width / 2) * scale
    local cy = globalY - (localPos.y - size.height / 2) * scale
    
    self:stopAnimation()
    
    self._isAnimating = true
    self:runAction(cc.Sequence:create(cc.Spawn:create(
        cc.MoveTo:create(duration, cc.p(cx, cy)),
        cc.ScaleTo:create(duration, scale)),
        cc.CallFunc:create(function() self:stopAnimation(true) end)))
    
    if self._isEventEnabled then
        self._scheduleId.animateTo = _scheduler:scheduleScriptFunc(function(dt)
            local pos = cc.p(self:getPosition())
            --lc.log("(%.0f, %.0f) * %.0f", pos.x, pos.y, self:getScale())
            local event = cc.EventCustom:new(_M.Event.scale)   
            event.scaleDelta = 0
            self:getEventDispatcher():dispatchEvent(event)
        end, 0.1, false);
    end
end

function _M:stopAnimation(isSendEvent)
    self._isAnimating = false
    self:stopAllActions()
    if self._isEventEnabled then
        if isSendEvent == true then
            local event = cc.EventCustom:new(_M.Event.animate_stopped)   
            self:getEventDispatcher():dispatchEvent(event)
        end
    
        if self._scheduleId.animateTo ~= nil then
            _scheduler:unscheduleScriptEntry(self._scheduleId.animateTo)
            self._scheduleId.animateTo = nil
        end
    end 
end

return _M