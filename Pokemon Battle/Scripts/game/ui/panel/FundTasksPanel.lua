local _M = class("FundTasksPanel", require("BasePanel"))

function _M.create(tasks, titleStr)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init(tasks, titleStr)
    return panel
end

function _M:init(tasks, titleStr)
    _M.super.init(self, false)

    local layout = lc.createNode()
    layout:setContentSize(self:getContentSize())
    lc.addChildToPos(self, layout, cc.p(lc.cw(self), lc.ch(self) - 50))
    self._layout = layout

    local titleBg = lc.createSprite("img_form_title_bg_1")
    lc.addChildToPos(layout, titleBg, cc.p(lc.cw(self), lc.ch(self) + lc.h(titleBg) + 190), 10)
    --[[
    local light = lc.createSprite({_name = "img_form_title_light_1", _crect = V.CRECT_FORM_TITLE_LIGHT1_CRECT, _size = cc.size(200, V.CRECT_FORM_TITLE_LIGHT1_CRECT.height)})
    lc.addChildToPos(titleBg, light, cc.p(lc.w(titleBg) / 2, lc.h(titleBg) / 2 + 4))
    ]]
    local titleLabel = V.createTTFStroke(titleStr, V.FontSize.M1)
    titleLabel:setColor(V.COLOR_TEXT_TITLE)
    titleLabel:setPosition(lc.w(titleBg) / 2, lc.h(titleBg) / 2 + 4 - 36)
    titleBg:addChild(titleLabel)
    self._titleLabel = titleLabel
    
    local items = {}
--    for i, task in ipairs(tasks) do
--        local bonus = self
--        local item = V.setOrCreateFundTaskCell(nil, task)
--        table.insert(items, item)
--    end
    local i = 1
    for _, bonus in pairs(P._playerBonus._bonusFundTasks) do
        if i > 5 then break end
        if tasks[bonus._info._cid] and not bonus._isClaimed then
            local item = V.setOrCreateFundTaskCell(nil, bonus, i)
            if titleStr ~= Str(STR.FUND_TASK_RESET) then
                item._callback = function (sender)
                    self:onItemClick()
                end
            else
                item._callback = function (sender)
                    layout:runAction(lc.sequence(lc.scaleTo(0.2, 0.5), lc.call(function() self:hide() end)))
                end
            end
            
            table.insert(items, item)
        end
        i = i + 1
    end
    lc.addNodesToCenterV(layout, items, 20)
    self._items = items

    for _, item in ipairs(items) do
        item.hide()
        item:runActionHideToShow()
    end

    local tipLabel = V.createTTF(Str(STR.FUND_TASK_TIP), V.FontSize.S1, V.COLOR_TEXT_WHITE)
    tipLabel:setPosition(lc.w(titleBg) / 2, lc.ch(tipLabel))
--    titleBg:addChild(tipLabel)
    lc.addChildToPos(layout, tipLabel, cc.p(lc.cw(layout), lc.ch(layout) - 260))
    self._tipLabel = tipLabel

    layout:setScale(0.5)
    layout:runAction(lc.scaleTo(0.2, 1))

    self:addTouchEventListener(function(sender, type)
        if type == ccui.TouchEventType.ended then            
            if not self._isForce then
                layout:runAction(lc.sequence(lc.scaleTo(0.2, 0.5), lc.call(function() self:hide() end)))
            end
        end
    end)
end

function _M:onItemClick()
    require("DailyActiveForm").create():show()
    self:hide()
end

return _M