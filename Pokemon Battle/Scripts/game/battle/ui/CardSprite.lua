local _M = class("CardSprite", function() return ccui.Widget:create() end)
CardSprite = _M

_M.EVENT            = "CARD_SPRITE_EVENT"

_M.Status = 
{
    normal = 1,
    back = 2,
    fight = 3,
    dead = 4,
    large = 5,
    info = 6,
    cover = 7,
    show = 8,
}

_M.TouchStatus = 
{
    ungrabbed = 1,
    grabbed = 2,
    moved = 3,
}

_M.ZOrder = 
{
    -- child
    shadow          = -2,
    card            = 0,
    effect          = 1,
    bottom_effect   = -1,
    
    -- effect 
    efc             = 0,
    label           = 1,
    skill_label     = 2,
}

_M.Scale = 
{
    normal = 0.25,
    normal_main = 0.4,
    hd = 1.0,
    cover = 1.0,
    show = 0.75,
    grave = 0.16,
}

_M.EventType = 
{
    show_card_info = 12,
    hide_card_info = 13,
    show_grave_list = 14,
    show_rare_list = 15,
}

_M.TouchCardType = 
{
    self_hand_card = 1,
    need_show_info = 2,
    board_card = 4,
    ground_card = 5,
    grave_card = 6,
}

local TAG_EFFECT = 1001
local TAG_FADE_ACTION = 100

-- Reference the battle scene

function _M.create(...)
    local cardSpr = _M.new()
	cardSpr:init(...)
	
	cardSpr:registerScriptHandler(function(evtName)
	    if evtName == "exit" then
            cardSpr:onExit()
        end
	end)
	
    return cardSpr
end

function _M:onExit()
    if self._touchEvent._focusedScheduler ~= nil then
        lc.Scheduler:unscheduleScriptEntry(self._touchEvent._focusedScheduler)
        self._touchEvent._focusedScheduler = nil
    end
end

-----------------------------------------
-- init
-----------------------------------------
function _M:init(card, playerUi)
    self._card = card
    self._battleUi = playerUi._battleUi

    self._scene = ClientData._battleScene

    self:setPlayerUi(playerUi)
    
    -- init value
    self._touchEvent = {}
    self._touchEvent._status = _M.TouchStatus.ungrabbed
    self._default = {_position = 0, _rotation = 0}
    
    self._default._position = cc.p(0, 0)
    self._default._rotation = {x = self._battleUi._battleType == Data.BattleType.layout and 0 or (self._battleUi._isReverse and -V.BATTLE_ROTATION_X or V.BATTLE_ROTATION_X), y = 0, z = 0}

    self._statusEfc = {}
    
    self:setCascadeOpacityEnabled(true)

    -- for add sprite children
    self._pCardArea = cc.Node:create()
    self._pCardArea:setCascadeOpacityEnabled(true)
    self:addChild(self._pCardArea, _M.ZOrder.card)

    --[[
    local drawNode = cc.DrawNode:create()
    drawNode:setContentSize(V.CARD_SIZE.width / 2, V.CARD_SIZE.height / 2)
    drawNode:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(self, drawNode, 4)
    drawNode:drawRect(cc.p(0, 0), cc.p(lc.w(drawNode), lc.h(drawNode)), cc.c4f(1, 1, 1, 1))
    ]]

    -- for add shadow children
    self._pShadowArea = cc.Node:create()
    self._pShadowArea:setCascadeOpacityEnabled(true)
    self:addChild(self._pShadowArea, _M.ZOrder.shadow)
    self._pShadowArea:setVisible(false)

    -- for add mask particle
    self._pMaskParticleArea = cc.Node:create()
    self._pMaskParticleArea:setCascadeOpacityEnabled(true)
    self:addChild(self._pMaskParticleArea, _M.ZOrder.effect)

    self._buffIcons = {}
    
    if self:shouldShowNormal() then 
        self:initNormal()
    else 
        self:initBack() 
    end
end

function _M:shouldShowNormal()
    if (self._battleUi._isObserver or self._battleUi._battleType == Data.BattleType.replay) and self._card._status == BattleData.CardStatus.hand then
        return  not self._ownerUi._hideHandCards
    end
    return self._isController
end

function _M:shouldShowCardInfo()
--    return self._isController or not self._ownerUi._hideHandCards
    local playerUi = self._ownerUi
    local player = playerUi._player
    local oppoPlayer = playerUi._opponentUi._player
    return self._isController or self._battleUi._isObserver
end

function _M:setPlayerUi(playerUi)
    self._ownerUi = playerUi

    self._isAttacker = playerUi._isAttacker
    self._isController = self._isAttacker == self._battleUi._isAttacker
end

function _M:initCard(cardStatus)
    if cardStatus ~= nil then self._status = cardStatus end
    
    if self._pFrame == nil then
        self._pFrame = V.createCardFrame(self._card._infoId, self._ownerUi._cardBackId, self._ownerUi._player._skins[self._card._infoId])
        self._pCardArea:addChild(self._pFrame, 1)
        
        self._pHpSpr = self._pFrame._hpValue
        self._pCostValue = self._pFrame._costValue

        -- for add effection children
        self._pEffectArea = cc.Node:create()
        self._pEffectArea:setCascadeOpacityEnabled(true)
        self._pEffectArea:setScale(1 / _M.Scale.normal)
        lc.addChildToCenter(self._pFrame._image, self._pEffectArea, 1)

        -- for add bottom effection children
        self._pBottomEffectArea = cc.Node:create()
        self._pBottomEffectArea:setCascadeOpacityEnabled(true)
        self._pBottomEffectArea:setScale(1 / _M.Scale.normal)
        lc.addChildToCenter(self._pFrame._image, self._pBottomEffectArea, -1)
    end
    
    ------------init back card area-----------
    if self._status == _M.Status.back then
        -- init shadow
        self._pShadow = V.createCardShadow(nil, _M.Scale.normal, 0, 0)
        self._pShadowArea:addChild(self._pShadow)
        
    ------------init normal card area-----------
    elseif self._status == _M.Status.normal or self._status == _M.Status.dead then
        -- init shadow
        if self._pShadow == nil then
            self._pShadow = V.createCardShadow(self._card, _M.Scale.normal, 0, 0)
            self._pShadowArea:addChild(self._pShadow)
        end
        
    ------------init fight card area-----------    
    elseif self._status == _M.Status.fight then
        -- init shadow
        if self._pShadow == nil then            
            local pos, name
            if self._card:isMonster() then
                pos, name = cc.p(-5, -14), "card_shadow"

            else
                pos, name = cc.p(0, -14), "card_shadow"

            end
            
            self._pShadow = lc.createSprite(name)
            self._pShadow:setPosition(pos)
            self._pShadow:setScale(4 * _M.Scale.normal)
            self._pShadow:setOpacity(120)
            self._pShadowArea:addChild(self._pShadow)
        end
        
    ------------init dead card area-----------
    elseif self._status == _M.Status.show then
        if self._pFrameIcon == nil then
            self._pFrameIcon = cc.ShaderSprite:createWithFramename("card_icon_quality_0"..self._card._info._quality)
            self._pFrameIcon:setEffect(V.getCardShader(self._card._infoId))
            self._pFrameIcon:setCascadeOpacityEnabled(true)
            self._pFrameIcon:setScale(1)
            self._pCardArea:addChild(self._pFrameIcon, 2)
            
            local pos = cc.p(self._pFrameIcon:getContentSize().width / 2, self._pFrameIcon:getContentSize().height / 2)
            local role = cc.Sprite:createWithSpriteFrameName(V.getCardIconName(self._card._infoId))
            role:setPosition(pos)
            self._pFrameIcon:addChild(role, -1)
            
            local cardBg = cc.Sprite:createWithSpriteFrameName("img_card_ico_bg")
            cardBg:setPosition(pos)
            self._pFrameIcon:addChild(cardBg, -2)
        end
        
    end

    self._scene:seenByCamera3D(self)
end

function _M:initNormal()
    local status = self._status
    self._status = _M.Status.normal
    self:removeCardActive()
    self:removeAllStatus()
    
    if status == self._status then 
        return
    elseif status ~= nil then
        if self._pFrameIcon ~= nil then self._pFrameIcon:removeFromParent(); self._pFrameIcon = nil end
        if self._pShadow ~= nil then self._pShadow:removeFromParent(); self._pShadow = nil end
        if self._pTimesSpr ~= nil then self._pTimesSpr:removeFromParent(); self._pTimesSpr = nil end
    end
    
    self:initCard()
    self._pFrame:setVisible(true)
    self._pFrame:setStatus(true, false)

    self._pCardArea:setScale(CardSprite.Scale.normal)
    self:setRotation3D(self._default._rotation)
end

function _M:initBack()
    local status = self._status
    self._status = _M.Status.back
    self:removeCardActive()
    self:removeAllStatus()
    
    if status == self._status then return
    elseif status ~= nil then
        if self._pFrameIcon ~= nil then self._pFrameIcon:removeFromParent(); self._pFrameIcon = nil end
        if self._pTimesSpr ~= nil then self._pTimesSpr:removeFromParent(); self._pTimesSpr = nil end
        if self._pShadow ~= nil then self._pShadow:removeFromParent(); self._pShadow = nil end
    end
    
    self:initCard()
    self._pFrame:setVisible(true)
    self._pFrame:setStatus(false, false)

    self:setRotation3D(self._default._rotation)
    self._pCardArea:setScale(CardSprite.Scale.normal)
end

function _M:initFight()
    local status = self._status
    self._status = _M.Status.fight
    self:removeCardActive()
    self:removeAllStatus()
    
    if status == self._status then
        return
    elseif status ~= nil then
        if self._pFrameIcon ~= nil then self._pFrameIcon:removeFromParent(); self._pFrameIcon = nil end
        if self._pShadow ~= nil then self._pShadow:removeFromParent(); self._pShadow = nil end
    end
    
    self:initCard()
    self._pFrame:setVisible(true)
    self._pFrame:setStatus(true, true) 

    self._pCardArea:setScale(self._card._pos == 1 and CardSprite.Scale.normal_main or CardSprite.Scale.normal)
    self:setRotation3D({x = 0, y = 0, z = 0})

    self:reloadAllStatus()
end

function _M:initDead()
    local status = self._status
	self._status = _M.Status.dead
    self:removeCardActive()
    self:removeAllStatus()
    
    if status == self._status then 
        return
    elseif status ~= nil then
        if self._pFrameIcon ~= nil then self._pFrameIcon:removeFromParent(); self._pFrameIcon = nil end
        if self._pShadow ~= nil then self._pShadow:removeFromParent(); self._pShadow = nil end
        if self._pTimesSpr ~= nil then self._pTimesSpr:removeFromParent(); self._pTimesSpr = nil end
    end
    
    self:initCard()
    self._pFrame:setVisible(true)
    self._pFrame:setStatus(true, false)

    self:setRotation3D({x = 0, y = 0, z = 0})
end

-----------------------------------------
-- touch function
-----------------------------------------

function _M:onTouchBegan(touch)
    if (not self._battleUi:isVisible()) or (self._touchEvent._status ~= nil and self._touchEvent._status ~= _M.TouchStatus.ungrabbed) then return false end
    self._touchEvent._status = _M.TouchStatus.grabbed

    -- touch event type
    local time = cc.Director:getInstance():getScheduler():getTimeScale() * 0.02
    if self._touchEvent._focusedScheduler == nil then self._touchEvent._focusedScheduler = lc.Scheduler:scheduleScriptFunc(function(dt) self:onTouchFocused() end, time, false) end
    self._touchEvent._focusTimes = 0
    self._touchEvent._isTapped = true
    self._touchEvent._isLongPressed = false
    
    -- hand show info   
    if self:shouldShowCardInfo() and self._card._status == BattleData.CardStatus.hand then
        self._touchEvent._touchCardType = _M.TouchCardType.self_hand_card
        self._touchEvent._startPos = cc.p(self:getPosition())
        self:showLargePic(touch == nil)
    elseif self._card._status == BattleData.CardStatus.board then
        self._touchEvent._touchCardType = _M.TouchCardType.board_card
        self._touchEvent._startPos = cc.p(self:getPosition())
    elseif self._card._status == BattleData.CardStatus.grave then
        self._touchEvent._touchCardType = _M.TouchCardType.grave_card
        self._touchEvent._startPos = cc.p(self:getPosition())
    else
        --self._touchEvent._touchCardType = _M.TouchCardType.need_show_info
        --self:sendEvent(_M.EventType.show_card_info)
    end
end

function _M:onTouchMoved(touch)
    local status = self._touchEvent._status

    if status == nil or status == _M.TouchStatus.ungrabbed then return end
    self._touchEvent._status = _M.TouchStatus.moved
     
    if status == _M.TouchStatus.grabbed then
        if cc.pGetDistance(touch:getLocation(), touch:getStartLocation()) <= lc.Gesture.BUDGE_LIMIT then        
            self._touchEvent._status = status
        else
            self._touchEvent._isTapped = false
            self._touchEvent._isLongPressed = false

            self._pCardArea:stopAllActions()
            if self._touchEvent._touchCardType == _M.TouchCardType.self_hand_card then
                if self._status == _M.Status.info then
                    self:hideCardInfo()
                end
            elseif self._touchEvent._touchCardType == _M.TouchCardType.board_card then
                -- if enable long press for self board card, open under line
                self:sendEvent(_M.EventType.hide_card_info)
            end
        end
        
    elseif status == _M.TouchStatus.moved then
        self._touchEvent._focusTimes = 0

        if self._touchEvent._touchCardType == _M.TouchCardType.self_hand_card then
            local pos = cc.p(self._touchEvent._startPos.x + touch:getLocation().x - touch:getStartLocation().x, self._touchEvent._startPos.y + touch:getLocation().y - touch:getStartLocation().y)
            self:setPosition(pos)
            self:handCardMove(2, touch:getLocation().x - touch:getPreviousLocation().x, touch:getLocation().y - touch:getPreviousLocation().y)
        elseif self._touchEvent._touchCardType == _M.TouchCardType.board_card then
            -- do nothing here, all handled in playerUi
        end
    end
end

function _M:onTouchFocused()
    self._touchEvent._focusTimes = self._touchEvent._focusTimes + 1
    
    if self._touchEvent._status == _M.TouchStatus.ungrabbed then
        -- on touch ended, remove scheduler
        if self._touchEvent._focusedScheduler ~= nil then
            lc.Scheduler:unscheduleScriptEntry(self._touchEvent._focusedScheduler)
            self._touchEvent._focusedScheduler = nil
        end
        
    elseif self._touchEvent._status == _M.TouchStatus.grabbed then
        -- long pressed touch event type
        if not self._touchEvent._isLongPressed and self._touchEvent._focusTimes > 5 then 
            self._touchEvent._isLongPressed = true
            self._touchEvent._isTapped = false
            
            -- todo on long pressed
            if self._touchEvent._touchCardType == _M.TouchCardType.self_hand_card then
                if self._status == _M.Status.large then
                    self:showCardInfo()
                end
            elseif self._touchEvent._touchCardType == _M.TouchCardType.board_card then
                -- if enable long press for self board card, open under line
                --[[
                local dragCard = self._battleUi:getEventDrag()
                if not (dragCard ~= nil and dragCard == self) then
                    self:sendEvent(_M.EventType.show_card_info)
                end
                ]]
            end
        end
        
    elseif self._touchEvent._status == _M.TouchStatus.moved then
        -- recover hand card move
        if self._touchEvent._touchCardType == _M.TouchCardType.self_hand_card then
            if self._touchEvent._focusTimes > 1 then
                self:handCardMove(1)
            end
        end
    end
end

function _M:onTouchEnded(touch)
    if self._touchEvent._status == nil or self._touchEvent._status == _M.TouchStatus.ungrabbed then return end
    local status = self._touchEvent._status
    self._touchEvent._status = _M.TouchStatus.ungrabbed

    if status == _M.TouchStatus.grabbed then
        -- card tapped event
        if self._touchEvent._isTapped then
            if self._touchEvent._touchCardType == _M.TouchCardType.self_hand_card then
                self:hideLargePic()
            elseif self._touchEvent._touchCardType == _M.TouchCardType.board_card then
                self:sendEvent(_M.EventType.show_card_info)
            elseif self._touchEvent._touchCardType == _M.TouchCardType.grave_card then
                self:sendEvent(_M.EventType.show_grave_list)
            elseif self._touchEvent._touchCardType == _M.TouchCardType.ground_card and (self._card._status == BattleData.CardStatus.show or self:shouldShowCardInfo()) then
                self:sendEvent(_M.EventType.show_card_info)
            end
        
        -- card long pressd event
        elseif self._touchEvent._isLongPressed then
             if self._touchEvent._touchCardType == _M.TouchCardType.self_hand_card then
                self:hideLargePic()
             elseif self._touchEvent._touchCardType == _M.TouchCardType.board_card then
                -- if enable long press for self board card, open under line
                self:sendEvent(_M.EventType.hide_card_info)
             elseif self._touchEvent._touchCardType == _M.TouchCardType.need_show_info then
             end
        end
        
    elseif status == _M.TouchStatus.moved then
        if self._touchEvent._touchCardType == _M.TouchCardType.self_hand_card then
            self:hideLargePic()
            self:handCardMove(0)
        elseif self._touchEvent._touchCardType == _M.TouchCardType.board_card then
            self:sendEvent(_M.EventType.hide_card_info)
        elseif self._touchEvent._touchCardType == _M.TouchCardType.need_show_info then
        end
    end
end

function _M:onTouchCanceled()
    if self._touchEvent._status == nil or self._touchEvent._status == _M.TouchStatus.ungrabbed then return end
    local status = self._touchEvent._status
    self._touchEvent._status = _M.TouchStatus.ungrabbed
    
    if status == _M.TouchStatus.grabbed then
        -- card tapped event
        if self._touchEvent._isTapped then
            if self._touchEvent._touchCardType == _M.TouchCardType.self_hand_card then
                self:hideLargePic()
            end
        
        -- card long pressd event
        elseif self._touchEvent._isLongPressed then
             if self._touchEvent._touchCardType == _M.TouchCardType.self_hand_card then
                self:hideLargePic()
             elseif self._touchEvent._touchCardType == _M.TouchCardType.board_card then
                -- if enable long press for self board card, open under line
                self:sendEvent(_M.EventType.hide_card_info)
             elseif self._touchEvent._touchCardType == _M.TouchCardType.need_show_info then
             end
        end
        
    elseif status == _M.TouchStatus.moved then
        if self._touchEvent._touchCardType == _M.TouchCardType.self_hand_card then
             self:hideLargePic()
            self:handCardMove(0)
        elseif self._touchEvent._touchCardType == _M.TouchCardType.board_card then
        elseif self._touchEvent._touchCardType == _M.TouchCardType.need_show_info then
        end
    end
end

-----------------------------------------
-- touch function
-----------------------------------------
function _M:sendEvent(type, val)
    local eventCustom = cc.EventCustom:new(_M.EVENT)
    eventCustom._sender = self
    eventCustom._type = type
    eventCustom._val = val
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:containsTouchLocation(x, y)
    if not self:isVisible() then return false end 

    local pos = cc.p(self:getPosition())
    local rect, width, height

    if self._card._status == BattleData.CardStatus.board then
        pos = self._pFrame:convertToNodeSpace3D(cc.p(x, y), ClientData._camera3D)
        rect = cc.rect(0, 0, lc.w(self._pFrame), lc.h(self._pFrame) + 100)
        x, y = pos.x, pos.y
    elseif self._card._status == BattleData.CardStatus.show then
        if self._pFrameIcon == nil then return false end
        pos = self._pFrameIcon:convertToNodeSpace3D(cc.p(x, y), ClientData._camera3D)
        rect = cc.rect(0, 0, lc.w(self._pFrameIcon), lc.h(self._pFrameIcon))
        x, y = pos.x, pos.y
    else
        pos = self._pFrame._frame:convertToNodeSpace3D(cc.p(x, y), ClientData._camera3D)
        rect = cc.rect(0, 0, lc.w(self._pFrame._frame), lc.h(self._pFrame._frame))
        x, y = pos.x, pos.y
    end

    return cc.rectContainsPoint(rect, cc.p(x, y))
end

function _M:handCardMove(type, x, y)
    -- reset hand card move to default
    if type == 0 then 
        local r3d = {x = 0, y = 0, z = 0}
        self._pCardArea:setRotation3D(r3d)
        self._pShadowArea:setRotation3D(r3d)
        
        self._pShadowArea:setPosition(0, 0)
        self._pShadowArea:setScale(1.0)
        
    -- recover hand card move on focus
    elseif type == 1 then
        local step = 2
        local dR3d = self._pCardArea:getRotation3D()
        local r3d = { x = dR3d.x < -step and (dR3d.x + step) or (dR3d.x > step and (dR3d.x - step) or 0),
                      y = dR3d.y < -step and (dR3d.y + step) or (dR3d.y > step and (dR3d.y - step) or 0), 
                      z = 0 }
        self._pCardArea:setRotation3D(r3d)
        self._pShadowArea:setRotation3D(r3d)
        
        local step = 4
        local defaultPos = cc.p(-100, -100)
        local dPos = cc.p(self._pShadowArea:getPosition())
        dPos = cc.p(dPos.x - defaultPos.x, dPos.y - defaultPos.y)
        local pos = { x = dPos.x < -step and (dPos.x + step) or (dPos.x > step and (dPos.x - step) or 0),
                      y = dPos.y < -step and (dPos.y + step) or (dPos.y > step and (dPos.y - step) or 0)}
        self._pShadowArea:setPosition(pos.x + defaultPos.x, pos.y + defaultPos.y)
        
        self._pShadowArea:setScale(1 / _M.Scale.normal * 0.8)
        
    -- hand card move 
    elseif type == 2 then
        local dR3d = self._pCardArea:getRotation3D()
        local r3d = { x = dR3d.x < (- y * 2.5 - 10) and (dR3d.x + 3) or (dR3d.x > (- y * 2.5 + 10) and (dR3d.x - 3) or dR3d.x),
                      y = dR3d.y < (x * 2.5 - 10) and (dR3d.y + 3) or (dR3d.y > (x * 2.5 + 10) and (dR3d.y - 3) or dR3d.y), 
                      z = 0 }
        self._pCardArea:setRotation3D(r3d)
        self._pShadowArea:setRotation3D(r3d)
        
        local defaultPos = cc.p(-100, -100)
        local dPos = cc.p(self._pShadowArea:getPosition())
        dPos = cc.p(dPos.x - defaultPos.x, dPos.y - defaultPos.y)
        local pos = { x = dPos.x < (- x * 5 - 20) and (dPos.x + 6) or (dPos.x > (- x * 5 + 20) and (dPos.x - 6) or dPos.x),
                      y = dPos.y < (- y * 5 - 20) and (dPos.y + 6) or (dPos.y > (- y * 5 + 20) and (dPos.y - 6) or dPos.y) }
        self._pShadowArea:setPosition(pos.x + defaultPos.x, pos.y + defaultPos.y)
        
        self._pShadowArea:setScale(1 / _M.Scale.normal * 0.8)
    end
end

function _M:showLargePic(isStatic)
    self._tempStatus = self._status
    self._status = _M.Status.large
    
    -- scheduler
    if self._touchEvent._showPicScheduler ~= nil then 
        lc.Scheduler:unscheduleScriptEntry(self._touchEvent._showPicScheduler)
        self._touchEvent._showPicScheduler = nil 
    end
    
    -- select action
    local time = cc.Director:getInstance():getScheduler():getTimeScale() * 2.0
    
    self:stopAllActions()
    self:setPosition(V.SCR_CW - 300, 280)
    --self:setRotation3D({x = V.BATTLE_ROTATION_X, y = 0, z = 0})
    self:setScale(1, 1)
    self._pShadowArea:stopAllActions()
    self._pShadowArea:setPosition(0, 0)
    self._pShadowArea:setRotation3D({x = 0, y = 0, z = 0})
    self._pShadowArea:setScale(1, 1)
    
    self._pCardArea:setScale(_M.Scale.hd)
    self._pEffectArea:setVisible(false)
    self._pBottomEffectArea:setVisible(false)
    self._pMaskParticleArea:setVisible(false)

    if not isStatic then
        self._pCardArea:runAction(cc.RepeatForever:create(cc.Sequence:create(
            cc.EaseOut:create(cc.MoveBy:create(time, cc.p(5, 10)), 2),
            cc.EaseIn:create(cc.MoveBy:create(time, cc.p(-5, -10)), 2),
            cc.EaseOut:create(cc.MoveBy:create(time, cc.p(-5, -10)), 2),
            cc.EaseIn:create(cc.MoveBy:create(time, cc.p(5, 10)), 2)
            )))
    end
        
    -- reset to touch status
    self:updateZOrder()
end

function _M:hideLargePic()
    if self._status ~= _M.Status.large and self._status ~= _M.Status.info then return end
    
    self:hideCardInfo()
    self._pEffectArea:setVisible(true)
    self._pBottomEffectArea:setVisible(true)
    self._pMaskParticleArea:setVisible(true)
    
    self._pCardArea:setScale(_M.Scale.normal)
    self._pCardArea:stopAllActions()
    self._pCardArea:setPosition(0, 0)
    
    -- reset status
    self._status = self._tempStatus

    -- reset to touch status
    self:updateZOrder()
end

function _M:showCardInfo(isHandCard)
    --if P._guideID < 100 then return end

    self._status = _M.Status.info
    if isHandCard == nil then isHandCard = true end
    
    if self._pInfoArea ~= nil then self._pInfoArea:removeFromParent() end
    self._pInfoArea = cc.Node:create()

    self._pCardArea:addChild(self._pInfoArea, 10)

    local areaW, areaH = 604, 600
 
    local size = cc.size(areaW - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, areaH)
    local list = require('CardInfoWidget').create(self._card._infoId, self._card._level, size, true, self._card)
    list:setAnchorPoint(0.5, 0.5)

    if lc.h(list) ~= 0 then
        local area = V.createFrameBox(cc.size(areaW, lc.h(list) + V.FRAME_INNER_TOP + V.FRAME_INNER_BOTTOM))
        area:setAnchorPoint(0, 1)
        lc.addChildToPos(self._pInfoArea, area, cc.p(140, 220))

        lc.addChildToCenter(area, list, -1)    
    end
     
    --self:setCameraMask(ClientData.CAMERA_2D_FLAG)
    if not isHandCard then
        self:setRotation3D({x = 0, y = 0, z = 0})
    end

    -- If NPC tip is shown, close it
    if self._battleUi._guideTipVals and self._battleUi._guideTipVals.t.touch ~= 1 then
        self._battleUi:hideTip()
    end
end

function _M:hideCardInfo()
    self._status = _M.Status.large
    
    if self._pInfoArea  then
        self._pInfoArea:removeFromParent()
        self._pInfoArea = nil
    end

    --self._scene:seenByCamera3D(self)
end

function _M:getCardStatusStrs()
    local card = self._card
    
    local positiveStrs, negativeStrs = {}, {}, {}
    local strs = {positiveStrs, negativeStrs}

    if card:isMonster() then
        local colors = {cc.c3b(255, 255, 16), cc.c3b(26, 254, 7), cc.c3b(250, 10, 10)}
        
        for i = 1, BattleData.PositiveType.count do
            if card:hasBuff(true, i) then
                if i == BattleData.PositiveType.irony then 
                    --[[
                    local val = card:getBuffValue(true, BattleData.PositiveType.irony)
                    if val == 0 then val = ''
                    elseif val < 0x10000 then val = '['..Str(STR.CARD_CATEGORY_BEGIN + val)..Str(STR.CARD_CATEGORY)..']' 
                    else val = '['..Str(STR.CARD_KEYWORD_BEGIN + val - 0x10000)..Str(STR.CARD_KEYWORD)..']' 
                    end
                    table.insert(positiveStrs, string.format(Str(status._descId), val))
                    ]]
                elseif i == BattleData.PositiveType.waterMark then 
                    local val = card:getBuffValue(true, BattleData.PositiveType.waterMark)
                    local val2 = nil
                    table.insert(positiveStrs, string.format(Str(status._descId), val, val2))
                end
            end
        end

        for i = 1, BattleData.NegativeType.count do
            if card:hasBuff(false, i) then
                if i <= BattleData.NegativeType.chaos then 
                    local val = card:getBuffValue(false, BattleData.PositiveType.waterMark)
                    local val2 = nil
                    table.insert(negativeStrs, string.format(Str(STR.BATTLE_CARD_BUFF_SLEEP + i - 1), val, val2))
                end
            end
        end
    end

    return strs
end

-----------------------------------------
-- update function
-----------------------------------------

function _M:updateZOrder(isActionCard)
    if self._status == _M.Status.large or self._status == _M.Status.info then
        self:setLocalZOrder(BattleUi.ZOrder.card_touch)
        
    elseif isActionCard then
        self:setLocalZOrder(BattleUi.ZOrder.card_action)

    elseif self._status == _M.Status.normal then 
        self:setLocalZOrder(BattleUi.ZOrder.card_hand + (self._card._pos or 0))

    elseif self._status == _M.Status.back then
        self:setLocalZOrder(BattleUi.ZOrder.card + (self._card._pos or 0))
        
    elseif self._status == _M.Status.fight then
        self:setLocalZOrder(BattleUi.ZOrder.card_board + (self._card._pos or 0))
        
    elseif self._status == _M.Status.dead then
        self:setLocalZOrder(BattleUi.ZOrder.card)
    end
end

function _M:updateAtkHp()
    self:updateBuffIcons()
end

function _M:updateActive(val)
    if val then
        if self._handGlow == nil then
            local layer = lc.createNode()
            lc.addChildToCenter(self._pFrame, layer, -1)
            layer:setScale(1.8)

            --local gemEnough = not self._card:hasNeedExtraGemSkill()
            --self._battleUi:createDragonBones("xuanzhong", cc.p(5, 8), layer, gemEnough and "effect1" or "effect3", false, 2.0)
            self._battleUi:createDragonBones("xuanzhong", cc.p(5, 8), layer, "effect1", false, 2.0)

            --[[
            local par = Particle.create("par_kprc04")
            lc.addChildToCenter(layer, par)
            par:setPositionType(cc.POSITION_TYPE_GROUPED)
            ]]
            

            self._ownerUi._scene:seenByCamera3D(layer)

            self._handGlow = layer
        end
    else
        if self._handGlow ~= nil then
            self._handGlow:removeFromParent()
            self._handGlow = nil
        end
    end
end

function _M:updateBoardActive()
    local playerUi = self._ownerUi
    local player = playerUi._player
    local isActive = (player:getActionPlayer() == player) 
        and self._battleUi._showingAttackCard ~= self
        and self._card._owner:canUseAnyMonsterSpell(self._card)
    
    if isActive then
        if self._boardGlow == nil then
            local layer = lc.createNode()
            lc.addChildToCenter(self._pFrame, layer, -1)
            self._boardGlow = layer
            layer:setScale(1.0)

            --local par = Particle.create("par_kprc04")
            --lc.addChildToCenter(layer, par)
            --par:setPositionType(cc.POSITION_TYPE_GROUPED) 
            layer._bones = self._battleUi:createDragonBones("szkp", cc.p(5, 8), layer, "effect1", false, 1.8)
            --[[
            self._battleUi:createDragonBones("xuanzhong", cc.p(5, 8), layer, gemEnough and "effect2" or "effect4", false, 2.0)
            for i = -1, 1, 2 do
                self:efcParticle("par_kpxz_x", cc.p(0, (self._pFrame:getContentSize().height / 2 - 15)* i), false, true, layer)
                self:efcParticle("par_kpxz_y", cc.p((self._pFrame:getContentSize().width / 2 - 15) * i, 0), false, true, layer)
            end
            ]]
            self._ownerUi._scene:seenByCamera3D(layer)
        else
            self._boardGlow._bones:gotoAndPlay("effect1")
        end
    else
        if self._boardGlow ~= nil then
            self._boardGlow:removeFromParent()
            self._boardGlow = nil
        end
    end
end

--------------------------------
-- buff related
--------------------------------

function _M:updatePositiveStatus()
    self:updateBuffIcons()
end

function _M:updateNegativeStatus()
    self:updateBuffIcons()
    self:updateBoardActive()
end

function _M:reloadAllStatus()
    self:updateBuffIcons()
    self:updateBoardActive()
end

function _M:removeAllStatus()
    self:updateBuffIcons()
end

function _M:removeCardActive()
    if self._handGlow ~= nil        then self._handGlow:removeFromParent(); self._handGlow = nil end
    if self._bookGlow ~= nil        then self._bookGlow:removeFromParent(); self._bookGlow = nil end
    if self._bookMask ~= nil        then self._bookMask:removeFromParent(); self._bookMask = nil end
    if self._boardGlow ~= nil       then self._boardGlow:removeFromParent(); self._boardGlow = nil end
    if self._boardSelected ~= nil       then self._boardSelected:removeFromParent(); self._boardSelected = nil end
end


--------------------------------
-- status change
--------------------------------

function _M:playToBoard(delay)
    -- support to board from hand, pile, grave, leave

    local playerUi = self._ownerUi
    local battleUi = playerUi._battleUi

    -- reset 
    self:updateActive(false)

    if self:shouldShowNormal() and self._status ~= _M.Status.normal then
        self:initNormal()
    elseif (not self:shouldShowNormal()) and self._status ~= _M.Status.back then
        self:initBack()
    end

    if self._card._sourceStatus == BattleData.CardStatus.pile then
        self:setPosition(cc.p(V.SCR_CW, V.SCR_CH))
    elseif self._card._sourceStatus == BattleData.CardStatus.hand then
        playerUi:replaceHandCards(delay, self._card)
    end

    --playerUi:replaceBoardCards(delay, self._card)

    -- action
    local centerPos = cc.p(V.SCR_CW, V.SCR_CH)
    local curPos = cc.p(self:getPosition())
    local boardPos = self._default._position
    local scale = 1 / _M.Scale.normal

    local centerLen = playerUi:calLengthAndAngle(centerPos, curPos)
    local centerTime = centerLen / 1500
    local boardTime = 0.35

    local is4111 = self._card._statusVal == BattleData.CardStatusVal.g2b_4111
    self:runAction(lc.sequence(
        lc.delay(delay),
        lc.call(function () self:updateZOrder(true) end),
        -- to center
        lc.ease(lc.spawn(lc.moveTo(centerTime, is4111 and boardPos or centerPos), lc.rotateTo(centerTime, (self._battleUi._isReverse and -V.BATTLE_ROTATION_X or V.BATTLE_ROTATION_X), 0, 0), lc.scaleTo(is4111 and 0 or centerTime, is4111 and 0 or scale)), "BackO"),
        -- using
        lc.call(function () 
            local par = Particle.create("par_kprc01")
            lc.addChildToCenter(self, par, CardSprite.ZOrder.efc)

            local par = Particle.create("par_kprc02")
            lc.addChildToCenter(self, par, CardSprite.ZOrder.efc)

            --[[
            if self._card._infoId == 10006 then
                local par = Particle.create("par_kprc03")
                lc.addChildToCenter(self, par, CardSprite.ZOrder.efc)
            elseif self._card._infoId == 10293 then
                local par = Particle.create("jsb1")
                lc.addChildToCenter(self, par, CardSprite.ZOrder.efc) 
                local par = Particle.create("jsb2")
                lc.addChildToCenter(self, par, CardSprite.ZOrder.efc) 
            elseif self._card._infoId == 10307 then
                local par = Particle.create("v11")
                lc.addChildToCenter(self, par, CardSprite.ZOrder.efc)
            elseif self._card:isV12() then
                local bones = playerUi:efcDragonBones2("xieshen", "effect", 1.0, true)
                lc.addChildToPos(battleUi, bones, boardPos, BattleUi.ZOrder.effect + 1)
            end
            ]]

            -- audio
            battleUi._audioEngine:playEffect("e_card_using")
            battleUi._audioEngine:playHeroAudio(self._card._infoId, false)

            if is4111 then
                self:setVisible(true)
                local bones = playerUi:efcDragonBones2("szfs", "effect", 1.3, true)
                lc.addChildToPos(battleUi, bones, boardPos, BattleUi.ZOrder.effect + 1)
                lc.offset(bones, 0, 10)
                local par = Particle.create("par_szfs")
                self._scene:seenByCamera3D(bones)
                lc.addChildToCenter(bones, par, CardSprite.ZOrder.efc)
            end

            if self._status ~= _M.Status.normal then
                self:initNormal()
            end
        end),
        lc.delay(is4111 and 1.2 or 0.4),
        -- to board: init fight
        lc.ease(lc.spawn(lc.moveTo(boardTime, boardPos), lc.rotateTo(boardTime, 0, 0, 0), lc.scaleTo(boardTime, 1)), "O", 0.4),
        lc.call(function () 
            -- audio
            battleUi._audioEngine:playEffect("e_card_board")

            local par = Particle.create("par_yhcx")
            lc.addChildToCenter(self, par, CardSprite.ZOrder.efc)

            self:initFight()
            self:updateAtkHp()
            self:updateZOrder()

            playerUi:updateBoardCardsActive()
        end)
    ))

    self._pShadowArea:runAction(lc.sequence(
        lc.delay(delay),
        -- to center
        lc.spawn(lc.moveTo(centerTime, cc.p(-100, -50)), lc.scaleTo(centerTime, 0.6), lc.fadeTo(centerTime, 200)),
        -- using
        lc.delay(0.4), 
        -- to board
        lc.spawn(lc.moveTo(boardTime, cc.p(0, 0)), lc.scaleTo(boardTime, 1.0), lc.fadeTo(boardTime, 255))
    ))

    return delay + centerTime + (is4111 and 1.2 or 0.4) + boardTime + 0.3 + 0.1
end

function _M:playEmptyToBoard(delay)
    local playerUi = self._ownerUi
    local opponentUi = playerUi._opponentUi
    local battleUi = playerUi._battleUi

    -- reset 
    self:updateActive(false)

    --playerUi:replaceBoardCards(delay, self._card)
    --opponentUi:replaceBoardCards(delay, self._card)
            
    self:setVisible(false)
    self:setPosition(self._default._position)
    
    if self._card._statusVal == BattleData.CardStatusVal.e2b_3136 then
        delay = delay + 1.0
    end

    -- action  
    self:runAction(lc.sequence(
        lc.delay(delay),
        lc.call(function () 
            self:updateZOrder(true)

            playerUi:efcParticle("par_cs1", self._default._position, false, false)
            battleUi._audioEngine:playEffect("e_wzsy")
        end),
        lc.delay(0.3),
        lc.call(function () 
            playerUi:efcParticle("par_cs2", self._default._position, false, false)
        end),
        lc.delay(0.3),
        lc.call(function () 
            playerUi:efcParticle("par_cs3", self._default._position, false, false)
                                        
            self:setVisible(true)
            self:setOpacity(255)
            self:updateZOrder()

            playerUi:updateBoardCardsActive()

            --audio
            battleUi._audioEngine:playHeroAudio(self._card._infoId, false)
        end)
        ))
            
    return delay + 0.3 + 0.3
end

function _M:playBoardToBoard(delay)
    local playerUi = self._ownerUi
    local opponentUi = playerUi._opponentUi
    local battleUi = playerUi._battleUi

    -- reset 
    self:updateActive(false)

    --playerUi:replaceBoardCards(delay, self._card)
    --opponentUi:replaceBoardCards(delay, self._card)

    -- action
    local curPos = cc.p(self:getPosition())
    local boardPos = self._default._position

    local boardLen = playerUi:calLengthAndAngle(curPos, boardPos)
    local boardTime = math.sqrt(boardLen) / 30 + 0.02

    self:runAction(lc.sequence(
        lc.delay(delay),
        lc.call(function () self:updateZOrder(true) end),
        lc.moveTo(boardTime, boardPos),
        lc.call(function()
            self:updateZOrder()
            playerUi:updateBoardCardsActive()
        end)
    ))

    return delay + boardTime
end

function _M:playBoardToGrave(delay)
    local playerUi = self._ownerUi
    local battleUi = playerUi._battleUi

    -- reset 
    self:updateActive(false)

    self:runAction(lc.sequence(
        lc.delay(delay),
        lc.call(function () 
            self:updateZOrder(true)
            playerUi:efcCardDie(self) 
        end),
        lc.delay(0.4),
        lc.call(function () 
            playerUi:addGraveCard(self) 
            self:updateZOrder()
        end)
    ))

    return delay + 0.5
end

function _M:playToGrave(delay)
    -- support to board from hand, pile, leave
    local playerUi = self._ownerUi
    local opponentUi = playerUi._opponentUi
    local battleUi = playerUi._battleUi

    -- reset 
    self:updateActive(false)

    if self._card._sourceStatus == BattleData.CardStatus.hand then
        playerUi:replaceHandCards(delay, self._card)
    end

    -- action
    local centerPos = cc.p(self._ownerUi._isController and (V.SCR_CW + 460) or (V.SCR_CW - 460), V.SCR_CH)
    local curPos = cc.p(self:getPosition())
    local centerLen = playerUi:calLengthAndAngle(centerPos, curPos)
    local centerTime = centerLen / 1500
    
    self:runAction(lc.sequence(
        -- to center
        lc.delay(delay), 
        lc.call(function () self:updateZOrder(true) end),
        lc.ease(lc.spawn(lc.moveTo(centerTime, centerPos), lc.rotateTo(centerTime, 0), lc.scaleTo(centerTime, 1)), "BackO"),
        -- action
        lc.call(function () playerUi:efcNormalCardDie(self, true) end),
        lc.delay(0.2),
        lc.call(function () 
            playerUi:addGraveCard(self) 
            self:updateZOrder()
        end)
    ))

    self._pShadowArea:runAction(lc.sequence(
        lc.delay(delay), 
        lc.spawn(lc.moveTo(centerTime, cc.p(-100, -50)), lc.scaleTo(centerTime, 0.6), lc.fadeTo(0.2, 200))
        ))

    return delay + centerTime + 0.2
end

function _M:fastToGrave(delay)
    -- support to board from hand, pile, leave
    local playerUi = self._ownerUi
    local opponentUi = playerUi._opponentUi
    local battleUi = playerUi._battleUi

    -- reset 
    self:updateActive(false)

    self._pCardArea:setScale(_M.Scale.grave)
    playerUi:addGraveCard(self) 
    self:updateZOrder()
    
    return delay
end

function _M:playToPile(delay)
    -- support to board from hand, pile, leave
    local playerUi = self._ownerUi
    local opponentUi = playerUi._opponentUi
    local battleUi = playerUi._battleUi

    -- reset
    self:updateActive(false)

    if self._card._sourceStatus == BattleData.CardStatus.hand then
        playerUi:replaceHandCards(delay, self._card)
    end

    if self:shouldShowNormal() and self._status ~= _M.Status.normal then
        self:initNormal()
    elseif (not self:shouldShowNormal()) and self._status ~= _M.Status.back then
        self:initBack()
    end

    -- action
    local centerPos = cc.p(V.SCR_CW + 440, V.SCR_CH)
    local pilePos = cc.p(V.SCR_CW + (playerUi._isController and 300 or -300), V.SCR_CH + (playerUi._isController and -200 or 200))
    local curPos = cc.p(self:getPosition())
    local centerLen = playerUi:calLengthAndAngle(centerPos, curPos)
    local centerTime = centerLen / 1500 + 0.1
    local pileTime = 0.4
    local scale = 1 / _M.Scale.normal

    self:runAction(lc.sequence(
        -- to center
        lc.delay(delay), 
        lc.call(function () self:updateZOrder(true) end),
        lc.ease(lc.spawn(lc.moveTo(centerTime, centerPos), lc.rotateTo(centerTime, 0), lc.scaleTo(centerTime, scale)), "BackO"),
        -- to pile
        lc.delay(0.1),
        lc.ease(lc.spawn(lc.moveTo(pileTime, pilePos), lc.rotateTo(pileTime, 90, 0, 90), lc.scaleTo(pileTime, 1.0)), "BackO")--[[,
        lc.call(function () playerUi:hideCardSprite(self) end)]]
    ))
    self._pShadowArea:runAction(lc.sequence(
        lc.delay(delay), 
        lc.spawn(lc.moveTo(centerTime, cc.p(-100, -50)), lc.scaleTo(centerTime, 0.6), lc.fadeTo(0.2, 200)),
        lc.delay(0.1),
        lc.ease(lc.rotateTo(pileTime, 90, 0, 90))
        ))

    return delay + 0.1 + centerTime + pileTime
end

function _M:fastToPile(delay)
    local playerUi = self._ownerUi
    local opponentUi = playerUi._opponentUi
    local battleUi = playerUi._battleUi

    -- reset
    self:updateActive(false)

    if self:shouldShowNormal() and self._status ~= _M.Status.normal then
        self:initNormal()
    elseif (not self:shouldShowNormal()) and self._status ~= _M.Status.back then
        self:initBack()
    end

    --playerUi:hideCardSprite(self)
    return delay
end

function _M:playToLeave(delay)
    -- support to board from hand, pile, leave
    local playerUi = self._ownerUi
    local opponentUi = playerUi._opponentUi
    local battleUi = playerUi._battleUi

    -- reset
    self:updateActive(false)

    if self._card._sourceStatus == BattleData.CardStatus.hand then
        playerUi:replaceHandCards(delay, self._card)
    end

    -- action
    local centerPos = cc.p(V.SCR_CW - 440, V.SCR_CH)
    local pilePos = cc.p(-100, V.SCR_CH + (playerUi._isController and -200 or 200))
    local curPos = cc.p(self:getPosition())
    local centerLen = playerUi:calLengthAndAngle(centerPos, curPos)
    local centerTime = centerLen / 1500 + 0.1
    local pileTime = 0.4
    local scale = 1 / _M.Scale.normal

    self:runAction(lc.sequence(
        -- to center
        lc.delay(delay), 
        lc.call(function () self:updateZOrder(true) end),
        lc.ease(lc.spawn(lc.moveTo(centerTime, centerPos), lc.rotateTo(centerTime, 0), lc.scaleTo(centerTime, scale)), "BackO"),
        -- to pile
        lc.delay(0.1),
        lc.ease(lc.spawn(lc.moveTo(pileTime, pilePos), lc.scaleTo(pileTime, 1.0)), "BackO"),
        lc.call(function () playerUi:hideCardSprite(self) end)
    ))
    self._pShadowArea:runAction(lc.sequence(
        lc.delay(delay), 
        lc.spawn(lc.moveTo(centerTime, cc.p(-100, -50)), lc.scaleTo(centerTime, 0.6), lc.fadeTo(0.2, 200))
        ))

    return delay + 0.1 + centerTime + pileTime
end

function _M:playBoardToLeave(delay)
    local playerUi = self._ownerUi
    local battleUi = playerUi._battleUi

    -- reset 
    self:updateActive(false)

    self:runAction(lc.sequence(
        lc.delay(delay),
        lc.call(function () 
            self:updateZOrder(true)
            playerUi:efcCardDie(self) 
        end),
        lc.delay(0.4),
        lc.call(function () 
            playerUi:hideCardSprite(self)
        end)
    ))

    return delay + 0.5
end

function _M:playToHand(delay, isShowOppo)
    local playerUi = self._ownerUi
    local opponentUi = playerUi._opponentUi
    local battleUi = playerUi._battleUi
    
    -- reset
    self:updateActive(false)

    playerUi:replaceHandCards(delay, self._card)

    if isShowOppo then
        self:initNormal()
    elseif self:shouldShowNormal() and self._status ~= _M.Status.normal then
        self:initNormal()
    elseif (not self:shouldShowNormal()) and self._status ~= _M.Status.back then
        self:initBack()
    end

    self._pCardArea:setScale(_M.Scale.normal)

    -- action
    local centerPos = cc.p(V.SCR_CW + (isShowOppo and 0 or 300), V.SCR_CH + (isShowOppo and 0 or (playerUi._isController and -100 or 200)))
    local centerTime = playerUi._isController and 0.25 or 0.15
    local scale = isShowOppo and 2 or (playerUi._isController and (1 / _M.Scale.normal) or 1.0)
    local position = self._default._position
    local rotation = self._default._rotation
    local delayTime = isShowOppo and 2.0 or 0

    --self:setRotation3D({x = 90, y = 0, z = 0})
    --self:setRotation3D({x = 0, y = 0, z = 0})

    self:runAction(lc.sequence(
        -- to center
        lc.delay(delay), 
        lc.call(function () 
            self:updateZOrder(true)
            playerUi._audioEngine:playEffect("e_card_deal") 
        end),
        lc.ease(lc.spawn(lc.moveTo(centerTime, centerPos), lc.rotateTo(centerTime, (self._battleUi._isReverse and -V.BATTLE_ROTATION_X or V.BATTLE_ROTATION_X), 0, 0), lc.scaleTo(centerTime, scale)), "BackO"),
        -- show oppo
        lc.delay(delayTime),
        lc.call(function () 
            if isShowOppo and not self:shouldShowNormal() then
                self:initBack()
            end
        end),
        -- to hand
        lc.ease(lc.spawn(lc.moveTo(0.3, position), lc.rotateTo(0.3, rotation), lc.scaleTo(0.3, 1)), "O", 2.5),
        lc.call(function () self:updateZOrder() end)
        ))

    self._pShadowArea:runAction(lc.sequence(
        lc.delay(delay),
        lc.spawn(lc.moveTo(centerTime, cc.p(-100, -50)), lc.scaleTo(centerTime, 0.6), lc.fadeTo(centerTime, 200)),
        lc.spawn(lc.moveTo(0.3, cc.p(0, 0)), lc.scaleTo(0.3, 1.0), lc.fadeTo(0.3, 255))
        ))

    return delay + centerTime + delayTime, delay + centerTime + delayTime + 0.3
end

function _M:playRetrievToPile(delay)
    local playerUi = self._ownerUi
    local opponentUi = playerUi._opponentUi
    local battleUi = playerUi._battleUi

    -- reset
    self:updateActive(false)

    -- action
    local pilePos = cc.p(V.SCR_W, V.SCR_CH + (playerUi._isController and -200 or 200))
    local pileTime = 0.6

    self:runAction(lc.sequence(
        -- to center
        lc.delay(delay), 
        lc.call(function () self:updateZOrder(true) end),
        -- to pile
        lc.ease(lc.spawn(lc.moveTo(pileTime, pilePos), lc.rotateTo(pileTime, 90, 0, 0), lc.scaleTo(pileTime, 1.0)), "BackO"),
        lc.call(function () playerUi:hideCardSprite(self) end)
    ))
    self._pShadowArea:runAction(lc.sequence(
        lc.delay(delay), 
        lc.ease(lc.rotateTo(pileTime, 90, 0, 0))
        ))

    return delay + pileTime
end

function _M:playRetrievToLeave(delay)
    -- support to board from hand, pile, leave
    local playerUi = self._ownerUi
    local opponentUi = playerUi._opponentUi
    local battleUi = playerUi._battleUi

    -- reset
    self:updateActive(false)

    -- action
    local pilePos = cc.p(-100, V.SCR_CH + (playerUi._isController and -200 or 200))
    local pileTime = 0.4

    self:runAction(lc.sequence(
        -- to center
        lc.delay(delay), 
        lc.call(function () self:updateZOrder(true) end),
        -- to pile
        lc.ease(lc.spawn(lc.moveTo(pileTime, pilePos), lc.rotateTo(pileTime, 0), lc.scaleTo(pileTime, 1.0)), "BackO"),
        lc.call(function () playerUi:hideCardSprite(self) end)
    ))
    self._pShadowArea:runAction(lc.sequence(
        lc.delay(delay), 
        lc.ease(lc.rotateTo(pileTime, 90, 0, 0))
        ))

    return delay + pileTime
end

function _M:playRetrievToHand(delay)
    -- support to board from hand, pile, leave
    local playerUi = self._ownerUi
    local opponentUi = playerUi._opponentUi
    local battleUi = playerUi._battleUi

    -- reset
    self:updateActive(false)

    playerUi:replaceHandCards(delay, self._card)

    -- action
    local position = self._default._position
    local rotation = self._default._rotation

    self:runAction(lc.sequence(
        lc.delay(delay), 
        lc.call(function () self:updateZOrder(true) end),
        -- to hand
        lc.ease(lc.spawn(lc.moveTo(0.4, position), lc.rotateTo(0.4, rotation), lc.scaleTo(0.4, 1)), "O", 2.5),
        lc.call(function () self:updateZOrder() end)
        ))

    self._pShadowArea:runAction(lc.sequence(
        lc.delay(delay),
        lc.spawn(lc.moveTo(0.4, cc.p(0, 0)), lc.scaleTo(0.4, 1.0), lc.fadeTo(0.4, 255))
        ))

    return delay + 0.4
end

function _M:playCoverRetriev(delay)
    local playerUi = self._ownerUi
    local opponentUi = playerUi._opponentUi
    local battleUi = playerUi._battleUi

    -- action
    local scale = 1 / CardSprite.Scale.normal
    local curPos = cc.p(self:getPosition())
    local centerPos = cc.p(V.SCR_CW + 440, V.SCR_CH)

    self:runAction(lc.sequence(
        -- start
        lc.delay(delay),
        lc.call(function() 
            self:updateZOrder(true)

            local bones = playerUi:efcDragonBones2("zh", "effect1", 1.0, true)
            lc.addChildToPos(battleUi, bones, curPos, BattleUi.ZOrder.card_board + 1)
            battleUi._scene:seenByCamera3D(bones)
        end),
        -- move to center
        lc.delay(0.6),
        lc.call(function ()
            if self:shouldShowNormal() then 
                self:initNormal()
            else 
                self:initBack() 
            end
        end),
        lc.ease(lc.spawn(lc.scaleTo(0.2, scale), lc.moveTo(0.2, centerPos)), "BackO")
        ))
          
    self._pShadowArea:runAction(lc.sequence(
        lc.delay(delay + 0.6), 
        lc.spawn(lc.moveTo(0.2, cc.p(-100, -50)), lc.scaleTo(0.2, 0.6), lc.fadeTo(0.2, 200))
        ))
            
    return delay + 0.8
end

function _M:playGraveRetriev(delay)
    local playerUi = self._ownerUi
    local opponentUi = playerUi._opponentUi
    local battleUi = playerUi._battleUi

    -- action
    local scale = 1 / CardSprite.Scale.normal
    local curPos = playerUi._isController and PlayerUi.Pos.attacker_grave or PlayerUi.Pos.defender_grave
    local centerPos = cc.p(V.SCR_CW - 440, V.SCR_CH)

    if self._card._statusVal == BattleData.CardStatusVal.g2h_oppo then
        curPos = (not playerUi._isController) and PlayerUi.Pos.attacker_grave or PlayerUi.Pos.defender_grave
    end

    local action = lc.sequence(
        -- start
        lc.delay(delay),
        lc.call(function() 
            self:updateZOrder(true)

            local bones = playerUi:efcDragonBones2("zh", "effect1", 1.0, true)
            lc.addChildToPos(battleUi, bones, curPos, BattleUi.ZOrder.card + 1)
            playerUi._scene:seenByCamera3D(bones)
        end),
        -- move to center
        lc.delay(0.6),
        lc.call(function ()
            if self._card._statusVal == BattleData.CardStatusVal.g2b_4111 then
                self:setVisible(false)
            else
                self:setVisible(true)
            end
            self:setOpacity(255)
            self:setPosition(curPos)

            if self:shouldShowNormal() then 
                self:initNormal()
            else 
                self:initBack() 
            end
        end),
        lc.ease(lc.spawn(lc.scaleTo(0.4, scale), lc.moveTo(0.4, centerPos)), "BackO")
        )

    action._dontFixPos = true

    self:runAction(action)
          
    self._pShadowArea:runAction(lc.sequence(
        lc.delay(delay + 0.6), 
        lc.spawn(lc.moveTo(0.4, cc.p(-100, -50)), lc.scaleTo(0.4, 0.6), lc.fadeTo(0.4, 200))
        ))
            
    return delay + 1.0
end

function _M:playBoardRetriev(delay)
    local playerUi = self._ownerUi

    local scale = 1 / CardSprite.Scale.normal
        
    self:runAction(lc.sequence(
        lc.delay(delay),
        lc.call(function() 
            self:updateZOrder(true)

            playerUi:efcDragonBones(self, "tuika", cc.p(0, -10), true, false, "effect", 2.4) 
        end),
        lc.ease(lc.scaleTo(0.1, scale - 0.2), "O", 2.5),
        lc.call(function()
            if self:shouldShowNormal() then 
                self:initNormal()
            else 
                self:initBack()
            end
        end),
        lc.ease(lc.scaleTo(0.1, scale), "BackO")
        ))

    self._pShadowArea:runAction(lc.sequence(
        lc.delay(delay), 
        lc.spawn(lc.moveTo(0.1, cc.p(-100, -50)), lc.scaleTo(0.3, 0.6), lc.fadeTo(0.3, 200))
        ))
        
    return delay + 0.4
end

--------------------------------
-- buff icons
--------------------------------

function _M:updateBuffIcons()
    local card = self._card

    if self._pFrame == nil then return end
    if not card:isMonster() then return end

    -- 1. damage
    local damage = card._maxHp - card._hp
    if damage > 0 then
        if self._buffIcons[BattleData.NegativeType.damage] == nil then
            self:addBuffIcon(BattleData.NegativeType.damage, cc.p(lc.w(self._pFrame) - 20, -10), card._maxHp - card._hp)
        else
            self:updateBuffIcon(BattleData.NegativeType.damage, card._maxHp - card._hp)
        end
    else
        if self._buffIcons[BattleData.NegativeType.damage] == nil then
            
        else
            self:removeBuffIcon(BattleData.NegativeType.damage)
        end
    end
    
    -- 2. negative buff
    local negaBuffTypes = {}
    for i = 1, #BattleData.NEGATIVE_COMMON do
        if card:hasBuff(false, BattleData.NEGATIVE_COMMON[i]) then
            negaBuffTypes[#negaBuffTypes + 1] = BattleData.NEGATIVE_COMMON[i]

            if self._buffIcons[i] == nil then
                self:addBuffIcon(i, cc.p(#negaBuffTypes * 74 - 54, -10))
            else
                self:updateBuffIcon(i)
            end
        else
            if self._buffIcons[i] == nil then
            
            else
                self:removeBuffIcon(i)
            end 
        end
    end

    -- 3. power
    local count = card:getBuffValue(true, BattleData.PositiveType.powerMark)
    if count > 0 then
        if self._buffIcons[99] == nil then
            self:addBuffIcon(99, cc.p(80, 400), 'x'..count)
        else
            self:updateBuffIcon(99, 'x'..count)
        end
    else
        if self._buffIcons[99] == nil then
            
        else
            self:removeBuffIcon(99)
        end 
    end
    
    -- 4. positive buff
    local hasPositiveBuff = false
    for i = 1, BattleData.PositiveType.count do
        if i ~= BattleData.PositiveType.powerMark and card:hasBuff(true, i) then   
            hasPositiveBuff = true
            break
        end
    end
    if hasPositiveBuff then
        if self._buffIcons[0] == nil then
            self:addBuffIcon(0, cc.p(40, 490))
        else
            self:updateBuffIcon(0)
        end
    else
        if self._buffIcons[0] == nil then
            
        else
            self:removeBuffIcon(0)
        end 
    end

    -- 4. equip
    local bindCard = card._binds[1]
    if bindCard ~= nil then
        if self._pBindCardImage == nil then
            self:addBindCardImage(bindCard)
        else
            self:updateBindCardImage(bindCard)
        end
    else
        if self._pBindCardImage == nil then
        else
            self:removeBindCardImage()
        end
    end
end

function _M:createBuffIcon(buffType)
    local name = 'bat_ico_buff_positive'

    if buffType == 99 then  name = 'bat_ico_buff_power'
    elseif buffType == BattleData.NegativeType.damage then name = 'bat_ico_buff_damage'
    elseif buffType == BattleData.NegativeType.burn then name = 'bat_ico_buff_burn'
    elseif buffType == BattleData.NegativeType.chaos then name = 'bat_ico_buff_chaos'
    elseif buffType == BattleData.NegativeType.numb then name = 'bat_ico_buff_numb'
    elseif buffType == BattleData.NegativeType.poison then name = 'bat_ico_buff_poison'
    elseif buffType == BattleData.NegativeType.sleep then name = 'bat_ico_buff_sleep'
    end
    return lc.createSprite(name)
end

function _M:addBuffIcon(buffType, pos, labelValue)
    local card = self._card

    local icon = self:createBuffIcon(buffType)
    icon:setScale(0)
    icon:runAction(lc.ease(lc.scaleTo(0.5, 1), "BackO"))
    self._buffIcons[buffType] = icon
    lc.addChildToPos(self._pFrame, icon, pos, 10)

    if labelValue then
        local label = V.createTTFBold(labelValue, V.FontSize.B2)
        label:enableOutline(lc.Color4B.black, 2)
        if buffType == 99 then
            lc.addChildToPos(icon, label, cc.p(lc.w(icon) + lc.cw(label), lc.ch(label)))
        else
            lc.addChildToPos(icon, label, cc.p(lc.cw(icon), lc.ch(icon)))
        end
        icon._label = label
    end

    icon:setCameraMask(ClientData.CAMERA_3D_FLAG)
end

function _M:removeBuffIcon(buffType)
    local icon = self._buffIcons[buffType]
    self._buffIcons[buffType] = nil
    icon:runAction(lc.sequence(lc.scaleTo(0.5, 0), lc.remove()))
end

function _M:updateBuffIcon(buffType, labelValue)
    if labelValue then
        local icon = self._buffIcons[buffType]
        icon._label:setString(labelValue)
    end
end

--------------------------------
-- bind card
--------------------------------

function _M:addBindCardImage(bindCard)
    local scale = 0.3

    local image = lc.createSprite(V.getCardImageName(bindCard._infoId))
    image:setScale(scale)

    local btn = V.createShaderButton(nil, function() 
        self._battleUi:showCardInfo(nil, bindCard)
    end)
    btn:setContentSize(lc.sw(image), lc.sh(image))
    lc.addChildToPos(self._pFrame, btn, cc.p(lc.w(self._pFrame) - 20, 480), 10)
    lc.addChildToCenter(btn, image)

    local imageFrame = lc.createSprite('bat_equip_frame')
    lc.addChildToCenter(btn, imageFrame)

    btn:setCameraMask(ClientData.CAMERA_3D_FLAG)
    self._pBindCardImage = btn
end

function _M:updateBindCardImage(bindCard)
    
end

function _M:removeBindCardImage()
    local image = self._pBindCardImage
    image:removeFromParent()
    self._pBindCardImage = nil
end

return _M