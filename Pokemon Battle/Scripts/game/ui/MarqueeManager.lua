local _M = {}

_M.Msgs = {}
local MAX_MSG_COUNT = 100

function _M.attach(scene)
    local panel = _M.Panel
    if panel == nil then
        local bg = lc.createSprite("img_marquee_bg")
        panel = lc.createNode(cc.size(V.SCR_W - 360, lc.h(bg)))
        panel:setCascadeOpacityEnabled(true)
        bg:setScaleX(lc.w(panel) / lc.w(bg))
        lc.addChildToCenter(panel, bg)
        panel:retain()
        panel._bg = bg

        local clip = V.createClipNode(nil, cc.rect(0, 0, lc.w(panel), lc.h(panel)))
        clip:setCascadeColorEnabled(true)
        lc.addChildToCenter(panel, clip)
        panel._clip = clip

        _M.Panel = panel

        panel.removeMsg = function(panel)
            if panel._msg then
                panel._msg:removeFromParent()
                panel._msg = nil
                table.remove(_M.Msgs, 1)

                if #_M.Msgs == 0 then
                    if not panel._isFadingOut then
                        panel:runAction(lc.sequence(lc.fadeOut(0.5), function() panel._isFadingOut = false end))
                        panel._isFadingOut = true
                    end
                end
            end
        end

        panel._listener = lc.addEventListener(Data.Event.message, function(event)
            if event._event == P._playerMessage.Event.msg_dirty then
                if event._type == Data.MsgType.bulletin then
                    local count, msgs, timestamp = event._param, P._playerMessage._msgAll[Data.MsgType.bulletin], P._loginTime
                    for i = 1, count do
                        local msg = msgs[i]
                        if msg._needMarquee and math.floor(msg._timestamp) > math.ceil(timestamp) then
                            _M.push(string.format("#|%s|#%s", msg._user._name, msg._content))
                        end
                    end
                end
            end
        end)

        lc.addChildToPos(scene, panel, cc.p(lc.w(scene) / 2, 90))
    else
        panel:setVisible(true)
        lc.changeParent(panel, nil, scene)
    end

    panel:setOpacity(#_M.Msgs == 0 and 0 or 255)
    panel:scheduleUpdateWithPriorityLua(_M.update, 0)
end

function _M.unattach()
    if _M.Panel then
        _M.Panel:removeFromParent(false)
    end
end

function _M.release()
    _M.Msgs = {}

    if _M.Panel then
        lc.Dispatcher:removeEventListener(_M.Panel._listener)

        _M.Panel:removeFromParent()
        _M.Panel:release()
        _M.Panel = nil
    end
end

function _M.push(msg, skipShowPanel)
    if #msg > MAX_MSG_COUNT then
        return false
    end

    table.insert(_M.Msgs, msg)

    _M.showPanel()
    return true
end

function _M.pushArray(msgs)
    for _, msg in ipairs(msgs) do
        if not _M.push(msg, true) then
            break
        end
    end

    _M.showPanel()
end

function _M.stop()
    local panel = _M.Panel
    if panel then
        panel:setVisible(false)
    end
end

function _M.showPanel()
    local panel = _M.Panel
    if panel == nil or not panel:isVisible() then
        return
    end

    panel._isFadingOut = false
    panel:stopAllActions()

    panel:runAction(lc.fadeIn(0.5))
end

function _M.update(dt)
    local msgs, panel = _M.Msgs, _M.Panel
    if panel == nil or not panel:isVisible() or #msgs == 0 then
        return
    end

    if panel._msg == nil then
        local msg, userName = msgs[1]

        -- Check whethe the msg contains user name
        local pos1 = string.find(msg, "#")
        if pos1 == 1 then
            pos2 = string.find(msg, "#", pos1 + 1)
            userName = string.sub(msg, pos1 + 1, pos2 - 1)
            msg = string.sub(msg, pos2 + 1)
        end

        local txtParam, text = {_fontSize = V.FontSize.S2, _normalClr = V.COLOR_TEXT_LIGHT, _boldClr = V.COLOR_TEXT_PURPLE}
        if userName then
            text = V.createBoldRichText(userName, V.RICHTEXT_PARAM_LIGHT_S2)
            V.appendBoldRichText(text, msg, txtParam)
            text:formatText()            
        else
            text = V.createBoldRichText(msg, txtParam)
        end

        lc.addChildToPos(panel._clip, text, cc.p(lc.w(panel) + lc.w(text) / 2, lc.h(panel) / 2))
        text:runAction(lc.sequence(lc.moveTo(20, -lc.w(text) / 2, lc.y(text)), function()
            panel:removeMsg()
        end))

        panel._msg = text
    end
end

MarqueeManager = _M
return _M