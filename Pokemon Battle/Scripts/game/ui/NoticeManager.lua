local _M = {}

local MAX_TEXT_WIDTH = 640
local MOVE_SPEED = 400

_M.Panels = {}
_M.SortedPanels = {}

function _M.init()
    if _M._scheduler == nil then
        _M._scheduler = lc.Scheduler:scheduleScriptFunc(function(dt) _M.scheduler(dt) end, 0, false)
    end
    
    if _M._listener == nil then
        _M._listener = lc.addEventListener(Data.Event.push_notice, function(event)
            local richText = ccui.RichTextEx:create()
            richText:insertElement(ccui.RichItemText:create(0, V.COLOR_LABEL_LIGHT, 255, string.format(Str(STR.BRACKETS_S), event._title), V.TTF_FONT, V.FontSize.S1))
            V.appendBoldRichText(richText, event._content, {_normalClr = V.COLOR_TEXT_DARK, _boldClr = V.COLOR_TEXT_GREEN_DARK, _fontSize = V.FontSize.S1})
            _M.show(richText, event._isImportant and -1 or 5)
        end)
    end
    
    if _M._bonusListener == nil then
        _M._bonusListener = lc.addEventListener(Data.Event.bonus_dirty, function(event)
            local bonus = event._data
            if bonus._info == nil then
                return
            end

            local lastValue, isShow = event._lastValue
            if lastValue then
                isShow = (lastValue < bonus._info._val and bonus._value >= bonus._info._val)
            else
                isShow = (bonus._value == bonus._info._val)
            end

            if bonus._type == Data.BonusType.daily_task then
                if not bonus._isClaimed and isShow then
                    local richText = ccui.RichTextEx:create()
                    richText:insertElement(ccui.RichItemText:create(0, V.COLOR_LABEL_LIGHT, 255, string.format(Str(STR.BRACKETS_S), Str(STR.DAILY_TASK)), V.TTF_FONT, V.FontSize.S1))
                    richText:insertElement(ccui.RichItemText:create(0, V.COLOR_TEXT_LIGHT, 255, Str(bonus._info._nameSid), V.TTF_FONT, V.FontSize.S1))
                    richText:insertElement(ccui.RichItemText:create(0, V.COLOR_TEXT_GREEN_DARK, 255, Str(STR.FINISHED), V.TTF_FONT, V.FontSize.S1))
                    _M.show(richText, 5)
                end

            elseif bonus._type == Data.BonusType.novice then
                if not bonus._isClaimed and isShow then
                    local richText = ccui.RichTextEx:create()
                    richText:insertElement(ccui.RichItemText:create(0, V.COLOR_LABEL_LIGHT, 255, string.format(Str(STR.BRACKETS_S), Str(STR.NOVICE_TASK)), V.TTF_FONT, V.FontSize.S1))
                    richText:insertElement(ccui.RichItemText:create(0, V.COLOR_TEXT_LIGHT, 255, Str(bonus._info._nameSid), V.TTF_FONT, V.FontSize.S1))
                    richText:insertElement(ccui.RichItemText:create(0, V.COLOR_TEXT_GREEN_DARK, 255, Str(STR.FINISHED), V.TTF_FONT, V.FontSize.S1))
                    _M.show(richText, 5)
                end

            else            
                for k, v in pairs(ClientData._player._playerAchieve._mainTasks) do
                    if v:isDefaultValid() and v._info._bonusId == bonus._infoId then
                        if not bonus._isClaimed and isShow then                            
                            local richText = ccui.RichTextEx:create()
                            richText:insertElement(ccui.RichItemText:create(0, V.COLOR_LABEL_LIGHT, 255, string.format(Str(STR.BRACKETS_S), Str(STR.MAIN_TASK)), V.TTF_FONT, V.FontSize.S1))
                            richText:insertElement(ccui.RichItemText:create(0, V.COLOR_TEXT_LIGHT, 255, v:getDesc(), V.TTF_FONT, V.FontSize.S1))
                            richText:insertElement(ccui.RichItemText:create(0, V.COLOR_TEXT_GREEN_DARK, 255, Str(STR.FINISHED), V.TTF_FONT, V.FontSize.S1))
                            _M.show(richText, 5)
                            break                              
                        end
                    end
                end
            end
        end)
    end
end

function _M.show(richText, duration, noticeId)
    if lc._runningScene == nil or lc._runningScene._scene == nil then
        return noticeId
    end

    if noticeId ~= nil and _M.Panels[noticeId] ~= nil then
        return noticeId
    end   
    
    if lc.FrameCache:getSpriteFrame("img_btn_close2") == nil then
        return nil
    end 
    
    local newNoticeId = 1
    while _M.Panels[newNoticeId] ~= nil do
        newNoticeId = newNoticeId + 1
    end
    
    richText:setMaxWidth(MAX_TEXT_WIDTH)
    richText:formatText()
    
    local button = V.createShaderButton("img_btn_close2", function(sender) _M.hide(newNoticeId) end)
    --button:ignoreContentAdaptWithSize(false)
    --button:setContentSize(50, 50)
    
    local panel = lc.createImageView{_name = "img_com_bg_37", _crect = V.CRECT_COM_BG37}
    panel:setContentSize(MAX_TEXT_WIDTH + 90, math.max(lc.h(richText), lc.h(button)) + 8)    
    panel:setOpacity(192)    
    lc.addChildToPos(panel, richText, cc.p(lc.w(richText) / 2 + 20, lc.h(panel) / 2))
    lc.addChildToPos(panel, button, cc.p(lc.w(panel) - lc.w(button) / 2 - 4, lc.h(panel) / 2))
    lc._runningScene._scene:addChild(panel, ClientData.ZOrder.toast)
    
    _M.sortPanels()
    
    if #_M.SortedPanels > 0 then
        panel:setPosition(lc.w(lc._runningScene) / 2, lc.top(_M.SortedPanels[1]) + lc.h(panel) / 2 + 2)
    else
        panel:setPosition(lc.w(lc._runningScene) / 2, lc.h(lc._runningScene) + lc.h(panel) / 2)
    end

    _M.Panels[newNoticeId] = panel
    table.insert(_M.SortedPanels, 1, panel)
    panel:retain()
    
    if duration ~= nil then
        panel:runAction(cc.Sequence:create(cc.DelayTime:create(duration), cc.CallFunc:create(function() _M.hide(newNoticeId) end)))
    end

    return newNoticeId, panel
end

function _M.hide(noticeId)
    if _M.Panels[noticeId] == nil then return end
    
    local panel = _M.Panels[noticeId]
    panel:removeFromParent()
    panel:release()
    
    _M.Panels[noticeId] = nil
    _M.sortPanels()
end

function _M.hideAll()
    for id, panel in pairs(_M.Panels) do
        _M.hide(id)
    end
end

function _M.bindToRunningScene()
    for k, v in pairs(_M.Panels) do
        if v:getParent() == nil then
            lc._runningScene._scene:addChild(v, ClientData.ZOrder.toast)
        end
    end
end

function _M.unbindFromRunningScene()
    for k, v in pairs(_M.Panels) do
        if v:getParent() ~= nil then
            v:removeFromParent(false)
        end
    end

    _M.Panels = {}
    _M.SortedPanels = {}
end

function _M.scheduler(dt)
    if #_M.SortedPanels > 0 then
        for i = 1, #_M.SortedPanels do
            local targetY
            if i == 1 then
                targetY = lc.h(lc._runningScene) - lc.h(_M.SortedPanels[i]) / 2
            else
                targetY = lc.bottom(_M.SortedPanels[i - 1]) - 2 - lc.h(_M.SortedPanels[i]) / 2
            end
            local srcY = lc.y(_M.SortedPanels[i])
            if targetY > srcY then
                _M.SortedPanels[i]:setPositionY(math.min(srcY + MOVE_SPEED * dt, targetY))
            else
                _M.SortedPanels[i]:setPositionY(math.max(srcY - MOVE_SPEED * dt, targetY))
            end                            
        end
    end
end

function _M.sortPanels()
    _M.SortedPanels = {}
    for k, v in pairs(_M.Panels) do
        table.insert(_M.SortedPanels, v)
    end
    table.sort(_M.SortedPanels, function(a, b) return lc.y(a) > lc.y(b) end)
end

NoticeManager = _M

return _M