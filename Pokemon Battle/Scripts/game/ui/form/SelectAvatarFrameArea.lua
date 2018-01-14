local _M = class("SelectAvatarFrameArea", lc.ExtendCCNode)


local AREA_WIDTH_MAX = 800

function _M.create(w, h)
    local area = _M.new(lc.EXTEND_NODE)
    area:setAnchorPoint(0.5, 0.5)
    area:setContentSize(math.min(w, AREA_WIDTH_MAX), h)
    area:init()

    return area
end

function _M:init()
    local areaW, areaH = lc.w(self), lc.h(self)
    
    local list = lc.List.createV(cc.size(lc.w(self), lc.h(self)), 20, 20)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(self, list)
    self._list = list
    
    local frames = {}
    for infoId, info in pairs(Data._propsInfo) do
        if math.floor(infoId / 100) == 75 then
            -- Skip special frames
            if infoId ~= Data.PropsId.avatar_frame_level_rank1 and
               infoId ~= Data.PropsId.avatar_frame_level_rank2 and
               infoId ~= Data.PropsId.avatar_frame_level_rank3 and
               infoId ~= Data.PropsId.avatar_frame_xmas_1 and
               infoId ~= Data.PropsId.avatar_frame_xmas_2 then
               local _, id = P._propBag:validPropId(infoId, true)
                if id == Data.PropsId.avatar_frame or P:getItemCount(id) > 0 then
                    table.insert(frames, info)
                end
            end
        end
    end
    table.sort(frames, function(a, b) return a._id < b._id end)
    self._frames = frames

    self:updateList()
end

function _M:updateList()
    local list, frames = self._list, self._frames
    list:bindData(frames, function(item, data) self:setOrCreateItem(item, data) end, math.min(6, #frames))

    for i = 1, list._cacheCount do
        local data = frames[i]
        local item = self:setOrCreateItem(nil, data)
        list:pushBackCustomItem(item)
    end

    list:jumpToTop()
end

function _M:setOrCreateItem(item, data)
    local frameSize = UserWidget.FRAME_SIZE

    if item == nil then
        local frame = V.createShaderButton("avatar_frame_001")
        frame:setPressedShader(nil)
        local name = V.createTTF("0", V.FontSize.S1, V.COLOR_TEXT_LIGHT)
        name:setAnchorPoint(0, 0.5)
        local btnSelect = V.createScale9ShaderButton("img_btn_1_s", nil, V.CRECT_BUTTON_1_S, 150)
        btnSelect:addLabel(Str(STR.SELECT))

        local itemW, itemH = lc.w(self._list), frameSize
        item = ccui.Widget:create()
        item:setContentSize(itemW, itemH)
        lc.addChildToPos(item, frame, cc.p(100, itemH / 2))
        lc.addChildToPos(item, name, cc.p(lc.right(frame) + 20, itemH / 2))
        lc.addChildToPos(item, btnSelect, cc.p(lc.w(item) - 120, itemH / 2))

        item._frame = frame
        item._name = name
        item._btnSelect = btnSelect
    end

    item._frame:removeAllChildren()
    item._frame:loadTextureNormal(ClientData.getAvatarFrameName(data._id), ccui.TextureResType.plistType)
    item._frame._callback = function()
        require("DescForm").create({_infoId = data._id}):show()
    end

    local baseId, id = P._propBag:validPropId(data._id, true)

    item._name:setString(data._nameSid and Str(data._nameSid) or Str(STR.AVATAR_FRAME_DEF))

    item._btnSelect._callback = function()
        if P:changeAvatarFrame(id) then
            ClientData.sendSetAvatarFrame(id)
        end
        self:getParent():getParent():getParent():getParent():hide()
    end

    return item
end

return _M