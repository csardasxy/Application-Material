local BaseUIScene = require("BaseUIScene")

local _M = class("SkinShopScene", BaseUIScene)
local FilterWidget = require("FilterWidget")
local CardInfoPanel = require("CardInfoPanel")

local TAB_MONSTER = 1
local TAB_RARE = 2

function _M.create()
    return lc.createScene(_M)
end

function _M:init()
    if not _M.super.init(self, ClientData.SceneId.skin_shop, STR.SKIN_SHOP, BaseUIScene.STYLE_TAB, true) then return false end

    self:createFrame()
    self:createFilterWidget()
    self:createSkinList()
    V.addVerticalTabButtons(self, {Str(STR.MONSTER)--[[, Str(STR.RARE)..Str(STR.MONSTER)]]}, lc.top(self._frame) - 60, lc.left(self._frame) - 124, 580)

    self:syncData()

    self:showTab(TAB_MONSTER)

    return true
end

function _M:onEnter()
    _M.super.onEnter(self)

    V.getResourceUI():setMode(Data.PropsId.skin_crystal)
    
    self._listeners = {}
    table.insert(self._listeners, lc.addEventListener(Data.Event.prop_dirty, function() self._skinList:updatePage(false) end))
end

function _M:onExit()
    _M.super.onExit(self)

    V.getResourceUI():setMode(Data.ResType.gold)
    
    for i = 1, #self._listeners do    
        lc.Dispatcher:removeEventListener(self._listeners[i])
    end
end

function _M:onCleanup()
    _M.super.onCleanup(self)

    for k, v in pairs(Data._skinInfo) do
        if v._effect ~= 0 then
            ClientData.unloadDragonBones(v._effect)
        end
    end
end

function _M:syncData()
    _M.super.syncData(self)

    
end

function _M:createFrame()
    local frame = V.createFrameBox(cc.size(lc.w(self) - (16 + V.FRAME_TAB_WIDTH) * 2, lc.h(self) - lc.h(self._titleArea)))
    lc.addChildToPos(self, frame, cc.p(lc.w(self) / 2, lc.bottom(self._titleArea) - lc.h(frame) / 2 + 10))
    self._frame = frame
end

function _M:createFilterWidget()
    local filterWidget = FilterWidget.create(FilterWidget.ModeType.skin, lc.h(self._frame) - 80)
    filterWidget:resetAllFilter() 
    filterWidget:registerSortFilterHandler(function() self:updateSkinList() end)
    
    lc.addChildToPos(self._frame, filterWidget, cc.p(lc.w(self._frame) + V.FRAME_TAB_WIDTH - lc.w(filterWidget) / 2 + 2, lc.h(filterWidget) / 2))
    self._filterWidget = filterWidget
end

function _M:createSkinList()
    self._skinList = require("ItemList").create(cc.size(lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT - 90, lc.h(self._frame) - V.FRAME_INNER_TOP - V.FRAME_INNER_BOTTOM), 
        cc.size(256, 312),
        Str(STR.LIST_EMPTY_NO_SKIN),
        function() return self:createSkinItem() end,
        function(item, data) return self:updateSkinItem(item, data) end)
    self._skinList:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(self._frame, self._skinList, cc.p(lc.w(self._frame) / 2, lc.h(self._frame) / 2))

    local pageBg = lc.createSprite({_name = "img_page_bg", _size = cc.size(125, 33), _crect = cc.rect(11, 11, 4, 8)}) 
    lc.addChildToPos(self._frame, pageBg, cc.p(-lc.w(pageBg) / 2 + 12, 48), -1)

    self._skinList._pageLabel:setPosition(-120, 20)

    self._skinList:setData(self:getSkinData())
end

function _M:updateSkinList()
    self._skinList:setData(self:getSkinData())
    self._skinList:updatePage(true)
end 

function _M:createSkinItem()
    local item = ccui.Layout:create()
    item:setTouchEnabled(true)
    item:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)
    item:setAnchorPoint(0.5, 0.5)

    local frame = V.createSkinFrame(50002)
    item:setContentSize(lc.w(frame), lc.h(frame) + 60)
    item._skinFrame = frame

    local btn = V.createScale9ShaderButton("img_btn_1_s", function(sender) self:onBtn(sender) end, V.CRECT_BUTTON_S, lc.w(frame))
    btn:addLabel(Str(STR.BUY))
    btn:setDisabledShader(V.SHADER_DISABLE)
    btn:setTouchRect(cc.rect(0, 0, lc.w(item), lc.h(item)))
    lc.addChildToPos(item, btn, cc.p(lc.cw(frame), lc.ch(btn)))
    item._btn = btn

    lc.addChildToPos(btn, frame, cc.p(lc.cw(frame), lc.h(btn) + lc.ch(frame)))

    return item
end

function _M:updateSkinItem(item, data)
    if data == nil then
        item:setVisible(false)
        return 
    end

    local infoId = data._infoId
    local skinId = data._id
    local info = Data.getInfo(infoId)
    local hasCard = P._playerCard:getCardCount(infoId) > 0
    local isBought = P._playerCard:hasSkin(skinId, true)

    local size = item._btn:getContentSize()

    item:setVisible(true)
    item._skinFrame:updateSkin(skinId, infoId)
    item._skinFrame._nameLabel:setString(Str(data._nameSid))
    item._skinFrame._monsterNameLabel:setString(Str(info._nameSid))
    item._btn._skinId = skinId
    item._btn:loadTextureNormal(hasCard and "img_btn_1_s" or "img_btn_2_s", ccui.TextureResType.plistType)
    item._btn:setContentSize(size)
    item._btn._label:setString(hasCard and (isBought and Str(STR.PURCHASED) or Str(STR.BUY)) or Str(STR.SKIN_NEED_CARD))
end

function _M:getSkinData()
    local skinInfos = {}
    for k, v in pairs(Data._skinInfo) do
        if v._infoId ~= 10407 or P._vip >= 12 then
            skinInfos[#skinInfos + 1] = v
        end
    end
    table.sort(skinInfos, function(a, b) return a._id > b._id end)

    local _, quality = self._filterWidget:getFilterQualityFunc()
    local _, cost = self._filterWidget:getFilterLevelFunc()
    local _, nature = self._filterWidget:getFilterNatureFunc()
    local _, category = self._filterWidget:getFilterCategoryFunc()
    local _, search = self._filterWidget:getFilterSearchFunc()
    
    skinInfos = self:filterSkinData(skinInfos, quality, cost, nature, category, search)


    return skinInfos
end

function _M:filterSkinData(skinInfos, quality, cost, nature, category, search)
    local filteredInfos = {}

    for i = 1, #skinInfos do
        local skinInfo = skinInfos[i]
        local infoId = skinInfo._infoId
        local info = Data.getInfo(infoId)
        local isValid = true
        if quality ~= nil and info._quality ~= quality then isValid = false end
        if cost ~= nil and info._cost ~= cost then isValid = false end
        if nature ~= nil and info._nature ~= nature then isValid = false end
        if category ~= nil and info._category ~= category then isValid = false end
        if search ~= nil and search ~= '' then
            local index = string.find(Str(skinInfo._nameSid)..Str(info._nameSid), search)
            if index == nil or index == 0 then isValid = false end
        end
        if isValid then filteredInfos[#filteredInfos + 1] = skinInfo end
    end

    return filteredInfos 
end

function _M:onBtn(btn)
    local skinId = btn._skinId
    local infoId = Data._skinInfo[skinId]._infoId

    local hasCard = P._playerCard:getCardCount(infoId) > 0
    if not hasCard then
        ToastManager.push(Str(STR.SKIN_NEED_CARD))
        return
    end

    require("SkinBuyForm").create(skinId):show()
end

function _M:showTab(tabIndex)
    self._tabArea:showTab(tabIndex)
end


return _M