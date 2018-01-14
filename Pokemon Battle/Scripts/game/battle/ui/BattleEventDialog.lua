local _M = class("BattleEventDialog", lc.ExtendUIWidget)
BattleEventDialog = _M

_M.Type = 
{
    story               = 11,
    
    info_help           = 21,
    
    guide_tap           = 31,
    guide_drag          = 32,
    guide_drag_to_card  = 33,
    guide_drag_to_pos   = 34,
    guide_drag_to_attack= 35,
    guide_drag_to_defend= 36,
}

function _M.create(battleUi, type, val, delayFinger)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(battleUi, type, val, delayFinger)
    return panel
end

-------------------------------------------------------
-- init
-------------------------------------------------------

function _M:init(battleUi, type, val, delayFinger)
    self._type = type
    self._battleUi = battleUi
    self._battleUi._guideCard = nil
    self._val = val
    self._delayFinger = delayFinger

    if type == _M.Type.info_help then
        self:showHelp()
    
    elseif type == _M.Type.guide_tap then
        self:showGuideTap(val)
    
    elseif type == _M.Type.guide_drag then
        self:showGuideDrag(val)
        
    elseif type == _M.Type.guide_drag_to_card or type == _M.Type.guide_drag_to_pos or type == _M.Type.guide_drag_to_attack or type == _M.Type.guide_drag_to_defend then
        self:showGuideDragTo(type, val)

    end
end

function _M:hide()
	if self._type == _M.Type.story then
		GuideManager.closeStoryDialog()
	end
    self:removeFromParent()
end

-------------------------------------------------------
-- function 
-------------------------------------------------------

function _M:showHelp()
    self:setOpacity(0)
    self:setTouchEnabled(false)
    
    local dialog =  BattleHelpDialog.create(self._battleUi)
    dialog:setTouchEnabled(true)
    dialog:addTouchEventListener(function(sender, type) 
        if type == ccui.TouchEventType.ended then
            dialog:runAction(lc.sequence(lc.remove(), 0.5, self._battleUi:hideEvent()))
        end
    end)
    self:addChild(dialog)
end

function _M:showGuideTap(val)
    self:setOpacity(0)
    self:setTouchEnabled(false)
    
    local node = val
    if node.setEnabled then node:setEnabled(true) end
    self:createOperateLayer(node)
end

function _M:showGuideDrag(val)
    self:setOpacity(0)
    self:setTouchEnabled(false)
    
    local node = val._pFrame
    local destPos = cc.p(V.SCR_CW, V.SCR_CH)
    self:createOperateLayer(node, destPos)
end

function _M:showGuideDragTo(type, val)
    self:setOpacity(0)
    self:setTouchEnabled(false)
    
    local node, target, destPos = val[1]._pFrame, val[2]
    if target then
        if type == _M.Type.guide_drag_to_card then
            destPos = self._battleUi._layer:convertToNodeSpace(target:convertToWorldSpace(cc.p(0, 0)))
        else
            destPos = self._battleUi._layer:convertToNodeSpace(target:convertToWorldSpace(cc.p(0, 0)))
        end
    elseif type == _M.Type.guide_drag_to_attack then
        destPos = cc.p(V.SCR_CW, 600)
    elseif type == _M.Type.guide_drag_to_defend then
        destPos = cc.p(V.SCR_CW - 20, 100)
    else
        local cards = self._battleUi._playerUi._pBoardCards
        for i = Data.MAX_CARD_COUNT_ON_BOARD, 1, -1 do
            if cards[i] then
                destPos = cc.p(V.SCR_CW + 100, V.SCR_CH)
                break
            end
        end

        if destPos == nil or destPos.x < V.SCR_CW then
            destPos = cc.p(V.SCR_CW, V.SCR_CH)
        end
    end

    -- Show arrow to indicate the drag direction
    local srcPos = self._battleUi._layer:convertToNodeSpace(val[1]:getParent():convertToWorldSpace(val[1]._default._position))
    local len = cc.pGetDistance(srcPos, destPos)
    local rotation = 90 - math.deg(cc.pToAngleSelf(cc.pSub(destPos, srcPos)))
    local arrow = lc.createSprite{_name = "img_arrow_up_4", _crect = V.CRECT_ARROW_4, _size = cc.size(48, len)}    
    arrow:setRotation(rotation)    
    arrow:setOpacity(0)
    lc.addChildToPos(self, arrow, cc.p((destPos.x + srcPos.x) / 2, (destPos.y + srcPos.y) / 2))
    self._guideArrow = arrow

    self:createOperateLayer(node, destPos)
end

-------------------------------------------------------
-- method 
-------------------------------------------------------

function _M:createOperateLayer(node, dstPos)
    local layer = V.createTouchLayer()
    self:addChild(layer)

    layer._touchHandler = function(evt, gx, gy)
        if self._ignoreTouch or (GuideManager._tipLayer and self._battleUi._guideTipVals.t.touch == 1) then return 0 end
        if self._blockTouch then return 1 end

        local btnEnd = self._battleUi._btnEndRound

        -- We can touch every where when guiding to tap end round button
        -- Otherwise, the end round button is not valid
        if node == btnEnd then
            self._battleUi._guideNode = node
            return 0
        else
            local gPos = cc.p(gx, gy)

            if lc.contain(node, gPos) then
                self._battleUi._guideNode = node
                return 0
            else
                self._battleUi._guideNode = nil
                return lc.contain(btnEnd, gPos) and 1 or 0
            end
        end
    end

    self.showFinger = function(self)
        local getFingerPos = function()
            local pos = self._battleUi._layer:convertToNodeSpace(node:convertToWorldSpace(cc.p(lc.w(node) / 2, lc.h(node) / 2)))
            if node == self._battleUi._btnEndRound then pos.x = pos.x - 14 pos.y = pos.y + 12 end
            return pos
        end
        local fingerPos = getFingerPos()
        local finger = GuideManager.createFinger(false, fingerPos, dstPos, getFingerPos)
        finger:setCameraMask(node:getCameraMask())
        self._battleUi._layer:addChild(finger, BattleScene.ZOrder.form - 1)

        if self._guideArrow then
            self._guideArrow:setOpacity(255)
            self._guideArrow:runAction(lc.rep(lc.sequence(1.0, lc.fadeTo(0.5, 100), lc.fadeTo(0.5, 255))))
        end

        self._blockTouch = nil
    end

    
    if self._delayFinger then
        self._blockTouch = true
    else
        self:showFinger()
    end

    return layer
end

return _M