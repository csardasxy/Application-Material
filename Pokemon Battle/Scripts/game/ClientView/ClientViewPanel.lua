local _M = ClientView



function _M.showPanelActiveIndicator(panel, maskRect)
    local size = (maskRect and cc.size(maskRect.width, maskRect.height) or panel:getContentSize())
    local pos = (maskRect and cc.p(maskRect.x, maskRect.y) or cc.p(0, 0))

    local indicator = lc.createMaskLayer(0, lc.Color3B.red, size)
    lc.addChildToPos(panel, indicator, pos)

    local img = lc.createSprite("img_panel_active_indicator")
    img:runAction(lc.rep(lc.rotateBy(2.0, 360)))
    lc.addChildToCenter(indicator, img)

    return indicator
end

function _M.addLongPressDescPanel(parent, desc, posFunc)
    parent:setTouchEnabled(true)
    parent:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)

    parent:addTouchEventListener(function(sender, touchType, touch)
        if touchType == ccui.TouchEventType.began then
            local panel = require("TopMostPanel").DescPanel.create(desc)
            if panel then                
                panel:setPosition(posFunc(panel))
                panel:show()
            end

        elseif touchType == ccui.TouchEventType.moved then
            if cc.pGetDistance(touch:getLocation(), touch:getStartLocation()) > lc.Gesture.BUDGE_LIMIT then
                BasePanel.hideTopMost()
            end

        elseif touchType == ccui.TouchEventType.ended or touchType == ccui.TouchEventType.canceled then
            BasePanel.hideTopMost()

        end
    end)
end

function _M.getChatPanel()
    if _M.ChatPanel == nil then
        _M.ChatPanel = require("ChatPanel").create()
        _M.ChatPanel:retain()
    end

    return _M.ChatPanel    
end

function _M.releaseChatPanel()
    if _M.ChatPanel ~= nil then
        _M.ChatPanel:onRelease()        
        _M.ChatPanel:release()                       
        _M.ChatPanel = nil
    end
end

function _M.removeChatPanelFromParent()
    if _M.ChatPanel ~= nil then
        _M.ChatPanel:removeFromParent(false)
    end
end

function _M.showOperateTopMostPanel(titleStr, buttonDefs, item)
    local panel = require("TopMostPanel").ButtonList.create(cc.size(200, 600), titleStr)
    if panel then
        local gPos = lc.convertPos(cc.p(lc.w(item) / 2, lc.h(item) / 2), item)
        panel:setButtonDefs(buttonDefs)
        panel:linkNode(item)

        local halfH = lc.h(panel) / 2
        if gPos.y - halfH < 0 then
            gPos.y = halfH
        elseif gPos.y + halfH > V.SCR_H then
            gPos.y = V.SCR_H - halfH
        end
        panel:setPosition(gPos.x, gPos.y)

        panel:show()
    end

    return panel
end