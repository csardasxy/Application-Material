local _M = class("RecruiteDetailForm", BaseForm)

local CardList = require("CardList")
local FilterWidget = require("FilterWidget")
local CardInfoPanel = require("CardInfoPanel")

local THUMBNAIL_SCALE = 0.6
local BOTTOM_H = 80

function _M.create(infoOnce, infoTen)
    local panel = _M.new(lc.EXTEND_LAYOUT_MASK)    
    panel:init(infoOnce, infoTen)
    
    return panel
end

function _M:init(infoOnce, infoTen)
    local visibleSize = lc.Director:getVisibleSize()
    _M.super.init(self, cc.size(visibleSize.width - (16 + V.FRAME_TAB_WIDTH) * 2, visibleSize.height - 80), Str(infoOnce._nameSid), initFlag, true)
    
    self._infoOnce = infoOnce
    self._infoTen = infoTen
    self._selectType = Data.CardType.monster
    
    self:createListArea()
    self:createBottomArea()
end

function _M:createListArea()
    local cardList = CardList.create(cc.size(lc.w(self._frame) - V.FRAME_INNER_LEFT - V.FRAME_INNER_RIGHT, lc.h(self._frame) - V.FRAME_INNER_TOP - V.FRAME_INNER_BOTTOM - BOTTOM_H), THUMBNAIL_SCALE, true)
    cardList:setAnchorPoint(0.5, 0.5)
    self._cardList = cardList

    cardList:setMode(CardList.ModeType.recruite)
    cardList._recruiteInfo = self._infoOnce

    cardList:setPosition(lc.w(self._frame) / 2, lc.h(self._frame) / 2 + BOTTOM_H / 2)
    cardList:registerCardSelectedHandler(function(data) 
        CardInfoPanel.create(data, 1, CardInfoPanel.OperateType.view):show()
    end)
    self._form:addChild(cardList)

    local offsetx = (lc.w(self._frame) - lc.w(self._cardList)) / 2 + 16
    self._cardList._pageLeft._pos = cc.p(-offsetx, 276)
    self._cardList._pageRight._pos = cc.p(lc.w(self._cardList) + offsetx, 276)

    offsetx = offsetx + 32
    local pageBg = lc.createSprite({_name = "img_page_bg", _size = cc.size(125, 33), _crect = cc.rect(11, 11, 4, 8)}) 
    lc.addChildToPos(self._frame, pageBg, cc.p(-lc.w(pageBg) / 2 + 12, 40), -1)
    self._pageBg = pageBg
    self._cardList._pageLabel:setPosition(-offsetx, -68)
    
    self:updateCardList()
end

function _M:createBottomArea()
    local bottomArea = V.createLineSprite("img_bottom_bg", lc.w(self._cardList))
    bottomArea:setAnchorPoint(0.5, 0)
    lc.addChildToPos(self._frame, bottomArea, cc.p(lc.w(self._frame) / 2, V.FRAME_INNER_BOTTOM - 12), -1)
    self._bottomArea = bottomArea

    local info = V.createTTF(Str(self._infoOnce._descSid), V.FontSize.S1)
    info:setAnchorPoint(0, 0.5)
    lc.addChildToPos(bottomArea, info, cc.p(20, lc.h(bottomArea) / 2))
    self._info = info
end

function _M:updateCardList()   
    self._cardList:init(self._selectType, {})
    self._cardList:refresh(true)
end

function _M:onEnter()
    _M.super.onEnter(self)
    
    self._listeners = {}
end

function _M:onExit()
    _M.super.onExit(self)
    
    for i = 1, #self._listeners do
        lc.Dispatcher:removeEventListener(self._listeners[i]) 
    end
end

return _M