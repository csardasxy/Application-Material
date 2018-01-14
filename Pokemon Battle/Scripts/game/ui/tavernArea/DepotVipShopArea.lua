local _M = class("DepotVipShopArea", lc.ExtendCCNode)
local CardList = require("CardList")

--local AREA_WIDTH_MAX = 800

function _M.create(areaW, areaH)
    local area = _M.new(lc.EXTEND_NODE)
    area:setAnchorPoint(0.5, 0.5)
    area:setContentSize(areaW, areaH)
    area:registerScriptHandler(function(evtName)
       if evtName == "enter" then
            area:onEnter()
        elseif evtName == "exit" then
            area:onExit()
        elseif evtName == "cleanup" then
            area:onCleanUp()
        end
    end)
    area:init()
    return area

end

function _M:init()
    self:addCardList()
    local bgV = ccui.Scale9Sprite:createWithSpriteFrameName("depot_shop_bg1", cc.rect(27, 13, 1, 1))
    bgV:setContentSize(cc.size(self:getContentSize().width, self:getContentSize().height + 20))
    lc.addChildToPos(self, bgV, cc.p(lc.cw(self), lc.ch(self) + 20))

    local bgH1 = ccui.Scale9Sprite:createWithSpriteFrameName("depot_shop_bg2", cc.rect(61, 30, 1, 1))
    bgH1:setContentSize(cc.size(self:getContentSize().width + 75, lc.h(bgH1)))
    lc.addChildToPos(self, bgH1, cc.p(lc.cw(self), lc.ch(self) + 133))

    local bgH2 = ccui.Scale9Sprite:createWithSpriteFrameName("depot_shop_bg2", cc.rect(61, 30, 1, 1))
    bgH2:setContentSize(cc.size(self:getContentSize().width + 75, lc.h(bgH2)))
    lc.addChildToPos(self, bgH2, cc.p(lc.cw(self), 128))

    local cardList = self._cardList
    local offX = 10
    cardList._pageLeft._pos = cc.p(offX, lc.ch(cardList))
    cardList._pageRight._pos = cc.p(lc.w(cardList) - offX, lc.ch(cardList))

    local pageBg = lc.createSprite({_name = "img_page_bg", _size = cc.size(125, 33), _crect = cc.rect(11, 11, 4, 8)}) 
    lc.addChildToPos(self._cardList, pageBg, cc.p( 0, lc.ch(pageBg) + 50), -1)
    pageBg:setScale(-1.0, 0.9)
    self._cardList._pageLabel:setPosition(cc.p(pageBg:getPosition()))

    local listeners = {}
    table.insert(listeners, lc.addEventListener(Data.Event.gold_dirty, function (event) if self:isVisible() then self._cardList:refresh() end end))
    table.insert(listeners, lc.addEventListener(Data.Event.card_dirty, function (event) if self:isVisible() then self._cardList:refresh() end end))
    self._listeners = listeners
end

function _M:onEnter()
end

function _M:onExit()
end

function _M:onCleanUp()
    for _,v in ipairs(self._listeners) do
        lc.Dispatcher:removeEventListener(v)
    end
end

function _M:addCardList()
    local cardList = CardList.create(cc.size(lc.w(self), lc.h(self)), 0.5, false, 300)
    cardList:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(self, cardList, cc.p(lc.cw(self), lc.ch(self) - 25), 2)
    local onBuy = function(sender)
        local card = sender._card
        ClientData.sendBuyDepot(card._id)
        P._playerCard:addCard(card._infoId, 1)
        P:changeResource(card._priceType, -card._price)
        require("RewardCardPanel").create(Str(STR.BUYSUCCESS), {card}):show()
        lc.Audio.playAudio(AUDIO.E_CARD_GET)
        cardList:refresh()
    end
    local confirmBuy = function(sender)
        local card = sender._card
        local getNum = P._playerCard:getCardCount(card._infoId)
        local cardInfo = Data.getInfo(card._infoId)
        if getNum >= cardInfo._maxCount then
            return ToastManager.push(Str(STR.SHOP_CARD_MAX))
        end

        local card = sender._card
        if V.checkGold(card._price) then
            require("Dialog").showDialog(Str(STR.SURE_TO_BUY), function() onBuy(sender) end )
        end
    end
    cardList:registerTapBtnCustom1(confirmBuy)
    cardList:setMode(CardList.ModeType.union_shop)
    local products = Data._productsExInfo
    local unionInfo = {}
    for _,v in ipairs(products) do
        if v._cost >= 50000 then
            local id = v._cardId
            local hour,day,month,year = ClientData.getServerDate()
            local onSaleDate = v._date
            local onSaleYear = string.sub(onSaleDate, 1, 4)
            local onSaleMonth = string.sub(onSaleDate, 5, 6)
            local onSaleDay = string.sub(onSaleDate, 7, 8)
            local deltaMonth = 12*(year-onSaleYear)+(month-onSaleMonth)
            local show = true
            if deltaMonth < 0 then show = false end
            if deltaMonth == 0 and day - onSaleDay < 0 then show = false end
            if show then
                local disCounts = Data._globalInfo._magicShopDiscountMonth
                local j = 0
                for i, disCount in ipairs(disCounts) do
                    if deltaMonth >= disCount then
                        j = i
                    end
                    if deltaMonth <= disCount then
                        break
                    end
                end
                local cost = v._cost
                if j > 0 then cost = cost * Data._globalInfo._magicShopDiscount[j]/100 end
                table.insert(unionInfo, {_infoId=id , _price=cost, _priceType=v._resType, _disCount=j, _id=v._id})
            end
        end
    end
    cardList._unionInfo = unionInfo
    cardList:registerCardSelectedHandler(function (card)
        local CardInfoPanel = require("CardInfoPanel")
        local cardInfoPanel = CardInfoPanel.create(card, 1, CardInfoPanel.OperateType.view)
        cardInfoPanel:show()
    end)
    cardList:init(Data.BaseCardTypes[1]) 

    local offX = 20
    cardList._pageLeft._pos = cc.p(-offX, lc.ch(cardList))
    cardList._pageRight._pos = cc.p(lc.w(cardList) + offX, lc.ch(cardList))

    cardList:refresh(true)
    self._cardList = cardList
end

function _M:refreshCardList()
    self._cardList:refresh()
end

return _M