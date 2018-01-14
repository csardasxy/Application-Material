local _M = class("SelectCardBackForm", BaseForm)

local FORM_SIZE = cc.size(840, 640)

local CARD_COUNT_IN_ROW = 6

function _M.create()
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)
    panel:init()
    return panel
end

function _M:init()
    _M.super.init(self, FORM_SIZE, Str(STR.CHANGE_CARD_BACK), 0)
    
    local list = lc.List.createH(cc.size(lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, lc.h(self._frame) - V.FRAME_INNER_TOP - V.FRAME_INNER_BOTTOM), 30, 20)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(self._frame, list)
    self._list = list
    
    local cardBacks = {}
    for infoId, info in pairs(Data._propsInfo) do
        if math.floor(infoId / 100) == 76 then
            if infoId == Data.PropsId.card_back or P:getItemCount(infoId) > 0 then
                table.insert(cardBacks, info)
            end
        end
    end
    table.sort(cardBacks, function(a, b) return a._id < b._id end)
    self._cardBacks = cardBacks

    self:updateAvatarList()
end

function _M:updateAvatarList()
    local list, cardBacks = self._list, self._cardBacks
    list:bindData(cardBacks, function(item, data) self:setOrCreateItem(item, data) end, math.min(5, #cardBacks))

    for i = 1, list._cacheCount do
        local data = cardBacks[i]
        local item = self:setOrCreateItem(nil, data)
        list:pushBackCustomItem(item)
    end

    list:jumpToTop()
end

function _M:setOrCreateItem(item, data)
    if item == nil then
        local back = V.createShaderButton(nil)
        
        back:setPressedShader(nil)
        backImg = lc.createSprite(V.getCardBackName(data._id))
        back:setContentSize(cc.size(lc.w(backImg) * 0.5, lc.h(backImg) * 0.5))
        backImg:setScale(0.5)
        lc.addChildToCenter(back, backImg)
        local name = V.createTTF("0", V.FontSize.S1, V.COLOR_TEXT_LIGHT)
        local btnSelect = V.createScale9ShaderButton("img_btn_1_s", nil, V.CRECT_BUTTON_1_S, 140)
        btnSelect:addLabel(Str(STR.SELECT))

        local itemW, itemH = lc.w(back), lc.h(back) + 10 + lc.h(name) + 14 + lc.h(btnSelect)
        item = ccui.Widget:create()
        item:setContentSize(itemW, itemH)
        lc.addChildToPos(item, back, cc.p(itemW / 2, itemH - lc.h(back) / 2))
        lc.addChildToPos(item, name, cc.p(itemW / 2, lc.bottom(back) - 10 - lc.h(name) / 2))
        lc.addChildToPos(item, btnSelect, cc.p(itemW / 2, lc.h(btnSelect) / 2))

        item._back = back
        item._name = name
        item._btnSelect = btnSelect
    end

    item._back:removeAllChildren()
    if ClientData._player._cardBackId == data._id then
        local status = lc.createSprite("img_cur")
        lc.addChildToCenter(item._back, status)
        lc.offset(status, 96, 60)
    elseif ClientData._player:getItemCount(data._id) <= 0 then
        V.addLockChains(item._back, 1)
    end

    --item._back:loadTextureNormal(V.getCardBackName(data._id), ccui.TextureResType.plistType)
    backImg = lc.createSprite(V.getCardBackName(data._id))
    backImg:setScale(0.5)
    lc.addChildToCenter(item._back, backImg, -1)
    item._back._callback = function()
        require("DescForm").create({_infoId = data._id}):show()
    end

    item._name:setString(data._nameSid and Str(data._nameSid) or Str(STR.DEFAULT)..Str(STR.CARD_BACK))
    item._btnSelect._callback = function()
        if ClientData._player:getItemCount(data._id) <= 0 then
            ToastManager.push(Str(STR.CARD_BACK_LOCKED))

        elseif ClientData._player._cardBackId == data._id then
            self:hide()

        else
            ClientData.sendSetCardBack(data._id)

            ClientData._player._cardBackId = data._id
            ToastManager.push(Str(STR.SELECT_CARD_BACK_SUCCESS))
            self:hide()
        end
    end

    return item
end

return _M