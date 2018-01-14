local _M = class("GivePropForm", BaseForm)

local FORM_SIZE = cc.size(800, 600)

local COL_ITEM_COUNT = 5

function _M.create(user, activityType, props)
    local form = _M.new(lc.EXTEND_LAYOUT_MASK)
    form:init(user, activityType, props)
    return form
end

function _M:init(user, activityType, props)
    self._user = user
    self._activityType = activityType
    self._props = props or {}
     _M.super.init(self, FORM_SIZE, Str(STR.SEND_GIFT), bor(BaseForm.FLAG.ADVANCE_TITLE_BG))

     local itemList = lc.List.createV(cc.size(FORM_SIZE.width - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, FORM_SIZE.height - V.FRAME_INNER_TOP - V.FRAME_INNER_BOTTOM), 50, 10)
     lc.addChildToCenter(self._form, itemList)
     self._itemList = itemList

     self:refreshList()

--     lc.addChildToCenter(self._form, lc.createSprite("img_icon_props_s7038"))

end

function _M:refreshList()
    local props = self._props
    if self._activityType then
        local activityInfo = ClientData.getActivityByType(self._activityType)
        if activityInfo._type[1] == 803 then
            props = activityInfo._param
        end
    end

    if not props then
        props = {}
    end
    
    local data = lc.arrayToTable(props, COL_ITEM_COUNT, function(prop)
            return true
        end)
    
    self._itemList:bindData(data, function(item, ids)
        self:setOrCreateItem(item, ids)
        end, math.min(5, #data))
    for i = 1, self._itemList._cacheCount do
        local item = self:setOrCreateItem(nil, data[i])
        self._itemList:pushBackCustomItem(item)
    end
end

function _M:setOrCreateItem(layout, ids)
    if not layout then
        layout = ccui.Widget:create()
        
        layout:setContentSize(cc.size(lc.w(self._itemList), 150))
        layout._icons = {}

        layout.update = function(ids)
           
            for _, icon in ipairs(layout._icons) do
                icon:setVisible(false)
            end 

            for i, id in ipairs(ids) do
                local bonusInfo = Data._bonusInfo[id]
                local infoId = bonusInfo._rid[1]
                local icon = layout._icons[i]
                local count = P:getItemCount(infoId)
                if not icon then
                    icon = IconWidget.create({_infoId = infoId, _count = count})
                    icon._name:setColor(V.COLOR_TEXT_WHITE)
                    icon._nameColor = V.COLOR_TEXT_WHITE
                    icon._callback = function() self:onSelectProp(icon) end
                    lc.addChildToPos(layout, icon, cc.p((i - 0.5) * 150, lc.ch(layout)))
                    table.insert(layout._icons, i, icon)
                else
                    icon:resetData({_infoId = infoId, _count = P:getItemCount(infoId)})
                    icon:setVisible(true)
                end
                icon:setGray(count == 0)
                icon._countBg:setVisible(count > 0)
                icon._bonusId = id
            end
        end
    end

    layout.update(ids)
    return layout
end

function _M:onSelectProp(sender)
    local id = sender._bonusId
    local infoId = sender._data._infoId
    if P:getItemCount(infoId) <= 0 then
        return ToastManager.push(Str(STR.COUNT_NOT_ENOUGH))
    end
    local name = ClientData.getNameByInfoId(infoId)
    require("Dialog").showDialog(string.format(Str(STR.CONFIRM_SEND), name, self._user._name), function()
        P:addResource(infoId, 1, -1)
        ClientData.sendProp(self._user._id, id)
        ToastManager.push(Str(STR.SEND_GIFT)..Str(STR.SUCCESS))
        self:hide()
    end)
    
end

function _M:onEnter()
     _M.super.onEnter(self)
end

function _M:onExit()
     _M.super.onExit(self)
end

return _M