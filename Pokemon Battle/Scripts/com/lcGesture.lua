lc = lc or {}

local _M = {}

--[[--
Enumerations used in this module
--]]--

_M.TouchState = 
{
    none                    = 0,
    began                   = 1,
    moved                   = 2,
    still                   = 3,
    ended                   = 4,
    cancelled               = 5,
}

_M.TouchEvent = 
{
    began                   = "LC_TOUCH_BEGAN",
    ended                   = "LC_TOUCH_ENDED",
    cancelled               = "LC_TOUCH_CANCELLED",
}

_M.GestureEvent = 
{    
    tap                     = "LC_GESTURE_TAP",
    pan                     = "LC_GESTURE_PAN",
    swipe                   = "LC_GESTURE_SWIPE",
    pinch                   = "LC_GESTURE_PINCH",
    long_press              = "LC_GESTURE_LONG_PRESS",
}

-- Constants
_M.SUPPORT_TOUCH_COUNT      = 2
_M.BUDGE_LIMIT              = 32.0
_M.TAP_TIME_LIMIT           = 0.5
_M.LONG_PRESS_TIME_LIMIT    = 2.0

--[[--
Private variables and methods
--]]--

-- process 5 touches at most
local function createTouch(id)
    local touch = {
        id = id,
        state = _M.TouchState.none,
        tapCount = 0, 
        budgedDir = lc.Dir.none, 
        budgeLimit = _M.BUDGE_LIMIT, 
        tapTimeLimit = _M.TAP_TIME_LIMIT,
        pos = {x = 0, y = 0},
        beganPos = {x = 0, y = 0},
        prevPos = {x = 0, y = 0},
        tick = 0,
        beganTick = 0,
        prevTick = 0
    }
    
    touch.isBudgedX = function(self)
        return math.abs(self.pos.x - self.beganPos.x) >= self.budgeLimit or self.budgedDir == lc.Dir.horizontal
    end
    
    touch.isBudgedY = function(self)
        return math.abs(self.pos.y - self.beganPos.y) >= self.budgeLimit or self.budgedDir == lc.Dir.vertical
    end
    
    touch.isBudged = function(self)
        return self:isBudgedX() or self:isBudgedY()
    end
    
    touch.getRelPos = function(self, relNode)
        return relNode:convertToNodeSpace(self.pos)
    end
    
    touch.getRelBeganPos = function(self, relNode)
        return relNode:convertToNodeSpace(self.beganPos)
    end
    
    touch.getRelPrevPos = function(self, relNode)
        return relNode:convertToNodeSpace(self.prevPos)
    end
    
    return touch
end

local _touches = nil
local _scheduler = lc.Scheduler
local _dispatcher = nil

-- Gesture tap
local _gestureTap = {touch = nil}

-- Gesture pan
local _gesturePan = {touch = nil}

_gesturePan.getOffset = function(self, relNode)
    local pos, prevPos
    if (relNode) then
        pos, prevPos = self.touch:getRelPos(relNode), self.touch:getRelPrevPos(relNode) 
    else
        pos, prevPos = self.touch.pos, self.touch.prevPos
    end
    return {x = pos.x - prevPos.x, y = pos.y - prevPos.y}
end

_gesturePan.getVelocity = function(self, relNode)
    local dt = self.touch.tick - self.touch.prevTick
    if (dt <= 0) then dt = 0.001 end
    
    local offset = self:getOffset(relNode)
    
    --print ("self._moveVelocity", dt, offset.x, offset.y)
    
    return {x = offset.x / dt, y = offset.y / dt}
end

-- Gesture swipe
local _gestureSwipe = {touch = nil}

_gestureSwipe.getOffset = function(self, relNode)
    local pos, prevPos
    if (relNode) then
        pos, prevPos = self.touch:getRelPos(relNode), self.touch:getRelPrevPos(relNode) 
    else
        pos, prevPos = self.touch.pos, self.touch.prevPos
    end
    return self.touch.budgedDir == lc.Dir.horizontal and pos.x - prevPos.x or pos.y - prevPos.y
end

_gestureSwipe.getVelocity = function(self, relNode)
    local dt = self.touch.tick - self.touch.prevTick
    return self:getOffset(relNode) / dt
end

-- Gesture pinch
local _gesturePinch = {touch1 = nil, touch2 = nil}

_gesturePinch.getScale = function(self, relNode)
    local pos1, prevPos1, pos2, prevPos2
    if (relNode) then
        pos1, prevPos1 = self.touch1:getRelPos(relNode), self.touch1:getRelPrevPos(relNode)
        pos2, prevPos2 = self.touch2:getRelPos(relNode), self.touch2:getRelPrevPos(relNode)  
    else
        pos1, prevPos1 = self.touch1.pos, self.touch1.prevPos
        pos2, prevPos2 = self.touch2.pos, self.touch2.prevPos
    end

    local prevDistance = lc.calcDistance(prevPos1, prevPos2)
    local distance = lc.calcDistance(pos1, pos2)
    return distance / prevDistance
end

_gesturePinch.getCenter = function(self, relNode)
    local pos1, pos2
    if (relNode) then
        pos1, pos2 = self.touch1:getRelPos(relNode), self.touch2:getRelPos(relNode) 
    else
        pos1, pos2 = self.touch1.pos, self.touch2.pos
    end

    return {x = (pos1.x + pos2.x) / 2, y = (pos1.y + pos2.y) / 2}
end

_gesturePinch.getCenterOffset = function(self, relNode)
    local center = self:getCenter(relNode)
    
    local prevPos1, prevPos2
    if (relNode) then
        prevPos1, prevPos2 = self.touch1:getRelPrevPos(relNode), self.touch2:getRelPrevPos(relNode) 
    else
        prevPos1, prevPos2 = self.touch1.prevPos, self.touch2.prevPos
    end
    local prevCenter = {x = (prevPos1.x + prevPos2.x) / 2, y = (prevPos1.y + prevPos2.y) / 2}
    return {x = center.x - prevCenter.x, y = center.y - prevCenter.y}
end

-- Gesture long press
local _gestureLongPress = {touch = nil}

-- Gesture handlers
local function handleTouchesBegan()
    if (not _M._isEnabled) then return end

    local event = cc.EventCustom:new(_M.TouchEvent.began)   
    for _, touch in ipairs(_touches) do
        if (touch.state == _M.TouchState.began) then
            event.touch = touch
            _dispatcher:dispatchEvent(event)
            
            -- Make sure TouchEvent.began event only send once
            touch.state = _M.TouchState.still
            
            if (_M._isLongPressEnabled) then
                local entryId = -1 
                entryId = _scheduler:scheduleScriptFunc(function()
                    _scheduler:unscheduleScriptEntry(entryId)
                    _gestureLongPress.touch = touch
                    event = cc.EventCustom:new(_M.GestureEvent.long_press)
                    event.gesture = _gestureLongPress
                    _dispatcher:dispatchEvent(event)
                end, _M.LONG_PRESS_TIME_LIMIT, false)
            end
        end
    end
end

local function handleTouchesMoved()
    if (not _M._isEnabled) then return end

    local touch1 = _touches[1]
    local touch2 = _touches[2]
    
    if (touch1.active and touch2.active) then
        if (_M._isPinchEnabled) then
            if (touch1.state == _M.TouchState.moved or touch2.state == _M.TouchState.moved) then
                _gesturePinch.touch1, _gesturePinch.touch2 = touch1, touch2
                local event = cc.EventCustom:new(_M.GestureEvent.pinch)
                event.gesture = _gesturePinch
                _dispatcher:dispatchEvent(event)
            end
        end
    else
        local touch = touch1.active and touch1 or touch2
        if (touch.state == _M.TouchState.moved) then
            _gesturePan.touch = touch
            local event = cc.EventCustom:new(_M.GestureEvent.pan)
            event.gesture = _gesturePan
            _dispatcher:dispatchEvent(event)
        end
        
        if (touch.state == _M.TouchState.moved and touch.budgedDir ~= lc.Dir.none) then
            _gestureSwipe.touch = touch
            local event = cc.EventCustom:new(_M.GestureEvent.swipe)
            event.gesture = _gestureSwipe
            _dispatcher:dispatchEvent(event)
        end
    end
end

local function handleTouchesEnded()
    local event = cc.EventCustom:new(_M.TouchEvent.ended)   
    for _, touch in ipairs(_touches) do
        if (touch.state == _M.TouchState.ended) then
            event.touch = touch
            _dispatcher:dispatchEvent(event)
            
            if (touch.tapCount > 0 and touch.budgedDir == lc.Dir.none) then
                _gestureTap.touch = touch
                local event = cc.EventCustom:new(_M.GestureEvent.tap)
                event.gesture = _gestureTap
                _dispatcher:dispatchEvent(event)
            end
        end
    end
end

local function handleTouchesCancelled()
    local event = cc.EventCustom:new(_M.TouchEvent.cancelled)   
    for _, touch in ipairs(_touches) do
        if (touch.state == _M.TouchState.cancelled) then
            event.touch = touch
            _dispatcher:dispatchEvent(event)
        end
    end    
end

-- Main entry of touches from cocos2d-x
local function onTouchesEvent(event, args)

    local camera = cc.Camera:getVisitingCamera()
    if camera ~= nil and camera:getCameraFlag() ~= 1 then return end

    if (event == "began") then
        for i = 1, #args, 3 do
            local touchId = args[i + 2] + 1
            if (touchId <= _M.SUPPORT_TOUCH_COUNT) then
                local x = args[i]
                local y = args[i + 1]
                local touch = _touches[touchId]
                
                touch.pos.x, touch.pos.y = x, y
                local isPosChanged = touch:isBudgedX() or touch:isBudgedY()
                
                touch.beganPos.x, touch.beganPos.y = x, y
                touch.prevPos.x, touch.prevPos.y = x, y
                touch.state = _M.TouchState.began
                touch.budgedDir = lc.Dir.none
                touch.isLongPressed = false;
                
                local tick = lc.Director:getCurrentTime()
                touch.beganTick, touch.prevTick, touch.tick = tick, tick, tick
    
                if (touch.tick - touch.prevTick >= touch.tapTimeLimit or isPosChanged) then
                    touch.tapCount = 0
                end
                
                touch.active = true
            end
        end

        handleTouchesBegan()
    elseif (event == "moved") then
        for _, touch in ipairs(_touches) do
            if (touch.active) then
                touch.state = _M.TouchState.still
            end
        end
        
        for i = 1, #args, 3 do
            local touchId = args[i + 2] + 1
            if (touchId <= _M.SUPPORT_TOUCH_COUNT) then
                local x = args[i]
                local y = args[i + 1]
                local touch = _touches[touchId]
                
                touch.prevPos.x, touch.prevPos.y = touch.pos.x, touch.pos.y
                touch.pos.x, touch.pos.y = x, y
                touch.state = _M.TouchState.moved
                touch.prevTick = touch.tick
                touch.tick = lc.Director:getCurrentTime()
                                
                if (touch.budgedDir == lc.Dir.none) then
                    if (touch:isBudgedX()) then
                        touch.budgedDir = lc.Dir.horizontal
                    elseif (touch:isBudgedY()) then
                        touch.budgedDir = lc.Dir.vertical
                    end
                    
                    if (touch.budgedDir ~= lc.Dir.none) then
                        touch.tapCount = 0
                        if (touch.schedulerId) then
                            _scheduler:unscheduleScriptEntry(touch.schedulerId)
                            touch.schedulerId = nil
                        end
                    end
                end
            end
        end
        
        handleTouchesMoved()
    elseif (event == "ended" or event == "cancelled") then
        local isCancelled = (event == "cancelled")
        
        for i = 1, #args, 3 do
            local touchId = args[i + 2] + 1
            if (touchId <= _M.SUPPORT_TOUCH_COUNT) then
                local x = args[i]
                local y = args[i + 1]
                local touch = _touches[touchId]
                
                touch.prevPos.x, touch.prevPos.y = touch.pos.x, touch.pos.y
                touch.pos.x, touch.pos.y = x, y
                touch.budgeLimit = _M.BUDGE_LIMIT
                touch.active = false
                touch.prevTick = touch.tick
                touch.tick = lc.Director:getCurrentTime()
                
                if (isCancelled) then
                    touch.tapCount = 0
                    touch.state = _M.TouchState.cancelled
                else
                    local isPosChanged = touch:isBudgedX() or touch:isBudgedY()
                    if (touch.tick - touch.prevTick < touch.tapTimeLimit and touch.budgedDir == lc.Dir.none and (not isPosChanged)) then
                        touch.tapCount = touch.tapCount + 1
                    else
                        touch.tapCount = 0
                    end
                    touch.state = _M.TouchState.ended
                end
            end
        end
        
        if (isCancelled) then
            handleTouchesCancelled()
        else
            handleTouchesEnded()
        end
    end
end

-- The layer only used to accept touches
local _touchLayer = cc.Layer:create()
_touchLayer:retain()
_touchLayer:setTouchEnabled(true)
_touchLayer:registerScriptTouchHandler(onTouchesEvent, true)
_touchLayer:resume()
_dispatcher = _touchLayer:getEventDispatcher()

--[[--
Dispatch a touch cancelled event

@param  #table touch            touch to be cancelled
--]]--
function _M.cancelTouch(touch, exceptTarget)
    local event = cc.EventCustom:new(_M.TouchState.cancelled)
    event.touch = touch
    event.exceptTarget = exceptTarget
    _dispatcher:dispatchEvent(event)
end

--[[--
Reset all touches
--]]--
function _M.resetTouches()
    _touches = {}
    for i = 1, _M.SUPPORT_TOUCH_COUNT, 1 do
        table.insert(_touches, createTouch(i))
    end
end

_M.resetTouches()

_M._isEnabled = true
_M._isLongPressEnabled = false
_M._isPinchEnabled = true

lc.Gesture = _M
return _M