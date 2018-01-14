local _M = class("BattleLine", lc.ExtendUIWidget)
BattleLine = _M

_M.MOVE_SPEED = 500
_M.SCALE_SPEED = 1
_M.OPACITY_SPEED = 255

function _M.create(startPos)
    local line = _M.new(lc.EXTEND_LAYOUT)
    line:init(startPos)
    
    return line
end

function _M:init(startPos)
   self:setAnchorPoint(0.5, 0)
   self:setPosition(startPos)
   self:setCascadeColorEnabled(true)
   self:setClippingEnabled(true)

   self._arrow = cc.Sprite:createWithSpriteFrameName("bat_arrow_1")
   self:addChild(self._arrow)
   
   self._segments = {}    
   self._startPos = startPos
   
   local segment = cc.Sprite:createWithSpriteFrameName("bat_arrow_2")
   self._segmentH = lc.h(segment)
end

function _M:onEnter()
    self:scheduleUpdateWithPriorityLua(function(dt) self:onSchedule(dt) end, 0)
end

function _M:onExit()
    self:unscheduleUpdate()
end

function _M:onCleanup()
    if self._targetCard then
        self._targetCard:stopAllActions()
        self._targetCard:setPosition(self._targetPos)
    end

    ClientData._battleScene._battleUi._playerUi:updateCardsActive()
end

function _M:onSchedule(dt)
    if not self._isAnimation then return end

    self._arrow:setPositionY(lc.y(self._arrow) + _M.MOVE_SPEED * dt)
    if lc.top(self._arrow) > lc.h(self) - 90 then
        if self._arrow:getScale() > 0 then
            self._arrow:setScale(self._arrow:getScale() - _M.SCALE_SPEED * dt)
        end
        if self._arrow:getOpacity() > 0 then
            self._arrow:setOpacity(self._arrow:getOpacity() - _M.OPACITY_SPEED * dt)
        end
    end
    
    for i = 1, #self._segments do
        self._segments[i]:setPositionY(lc.y(self._segments[i]) + _M.MOVE_SPEED * dt)
        if lc.top(self._segments[i]) > lc.h(self) - 90 then
            if self._segments[i]:getScale() > 0 then
                self._segments[i]:setScale(self._segments[i]:getScale() - _M.SCALE_SPEED * dt)
            end
            if self._segments[i]:getOpacity() > 0 then
                self._segments[i]:setOpacity(self._segments[i]:getOpacity() - _M.OPACITY_SPEED * dt)
            end
        end
    end
    
    local bottom
    if #self._segments > 0 then
        bottom = lc.bottom(self._segments[#self._segments])
    else
        bottom = lc.bottom(self._arrow)
    end
    
    if bottom > lc.h(self) then
       self:resetToPos(-lc.h(self._arrow) / 2)
    end
end

function _M:resetToPos(startPos)
     self._isAniFromBottom = false

    self._arrow:setPositionY(startPos)
    self._arrow:setScale(1)
    self._arrow:setOpacity(0xff)
        
    local bottom = lc.bottom(self._arrow) - 10
    for i = 1, #self._segments do
        self._segments[i]:setPositionY(bottom - lc.h(self._segments[i]) / 2)
        self._segments[i]:setScale(1)
        self._segments[i]:setOpacity(0xff)
            
        bottom = lc.bottom(self._segments[i]) - 10
    end
end

function _M:directTo(pos, targetCard)
   local distance = cc.pGetDistance(pos, self._startPos)
   if distance < 70 then distance = 70 end

   self:setContentSize(120, distance)
   self:setRotation(90 - math.deg(cc.pToAngleSelf(cc.pSub(pos, self._startPos))))

   self._isAnimation = false
   if self._targetCard == targetCard and targetCard ~= nil then
       self._isAnimation = true
       return
   end

   for i = 1, #self._segments do
       self._segments[i]:removeFromParent()
   end
   self._segments = {}
   
   self._arrow:setPosition(lc.w(self) / 2, lc.h(self) - lc.h(self._arrow) / 2)
   self._arrow:setScale(1.0)
   self._arrow:setOpacity(0xff)
   
   local bottom = lc.bottom(self._arrow) - 10
   while true do
       local segment = cc.Sprite:createWithSpriteFrameName("bat_arrow_2")
       segment:setPosition(lc.w(self) / 2, bottom - lc.h(segment) / 2)
       self:addChild(segment)
       table.insert(self._segments, segment)
       
       bottom = lc.bottom(segment) - 10
       if bottom <= 0 then break end
   end
   
   if self._targetCard ~= targetCard then
       if self._targetCard ~= nil then
           self._targetCard:stopActionByTag(0xff)
           self._targetCard:setPosition(self._targetPos)
           self._targetCard:setScale(1)
           self._targetCard = nil
       end
       self._targetCard = targetCard
       
       if targetCard ~= nil then
           self._targetPos = cc.p(targetCard:getPosition())
       
           local action = lc.rep(lc.sequence(cc.ScaleTo:create(0.5, 1.1),
                cc.ScaleTo:create(0.5, 1.0)))
           action:setTag(0xff)
           targetCard:runAction(action)
       end
   end
end

return _M