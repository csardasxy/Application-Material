local _M = class("DiamondShopArea", lc.ExtendCCNode)
local CardList = require("CardList")

local AREA_WIDTH_MAX = 800
local BUTTON_WIDTH = 250
function _M.create(areaW, areaH)
    local area = _M.new(lc.EXTEND_NODE)
    area:setAnchorPoint(0.5, 0.5)
    area:setContentSize(math.min(areaW, AREA_WIDTH_MAX), areaH)
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
    
    self:generateCardPackageData()

    local list = lc.List.createH(cc.size(V.SCR_W-V.VERTICAL_TAB_WIDTH, lc.h(self) - 60), 30, 30)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(self, list, cc.p(lc.cw(self), lc.ch(self) + 10))
    self._list = list

    self._recruitItems = {}
    for k,v in pairs(self._packageCardNum) do
        local item = self:createRecruitItem(v)
        list:pushBackCustomItem(item)
        table.insert(self._recruitItems, item)
    end

    local listeners = {}
    table.insert(listeners, lc.addEventListener(Data.Event.prop_dirty, function (event) 
        self:updateCardBox()
     end))
    table.insert(listeners, lc.addEventListener(Data.Event.card_dirty, function (event) 
        self:updateCardBox()
     end))
    self._listeners = listeners
end

function _M:generateCardPackageData()
    local productInfos = Data._diamondProductsInfo
    local packages = {}
    local packageCardNum = {}
    for _,v in ipairs(productInfos) do
        local type = v._type
        if not (P:getCharacterUnlockCount() < 2 and type > 1020) then
            if packages[type] == nil then
                packages[type] = {}
            end
            local packageNum
            for _, v in ipairs(packageCardNum) do
                if v._type == type then
                    packageNum = v
                    break
                end
            end
            if not packageNum then
                packageNum = {_type = type, _num = 0}
                table.insert(packageCardNum, packageNum)
            end
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
                local cost = v._cost
                table.insert(packages[type], {_infoId=id , _price=cost, _priceType=v._resType,  _id=v._id})
                packageNum._num = packageNum._num + 1
            end
        end
    end
    table.sort(packageCardNum, function (A, B)
        if A._num == 0 and B._num > 0 then
            return false
        elseif B._num == 0 and A._num > 0 then
            return true
        end
        return A._type < B._type
    end)
    self._packages = packages
    self._packageCardNum = packageCardNum
end

function _M:createRecruitItem(info)
    local layout = ccui.Layout:create()
    layout:setContentSize(cc.size(BUTTON_WIDTH, lc.h(self)))
    layout:setAnchorPoint(0.5, 0.5)

    local titleBg = V.createDiamondCardPackage(info)

    local btn = V.createShaderButton(nil, function(sender)
        if info._num > 0 then
            self:showCardBox(info)
        else
            ToastManager.push(Str(STR.SID_FIXITY_DESC_1013))
        end
    end)
    btn:setContentSize(titleBg:getContentSize())
    btn:setZoomScale(0.02)
    lc.addChildToCenter(btn, titleBg)

    lc.addChildToCenter(layout, btn)
    
    layout._info = info

    -- check locked
    local isLocked, str = self:isLocked(info)

    if isLocked then
        btn:setTouchEnabled(false)
        titleBg:setGray()

        local bg = lc.createSprite("img_com_bg_45")
        lc.addChildToPos(titleBg, bg, cc.p(lc.cw(titleBg), lc.ch(titleBg) + 30))

        local label = V.createBoldRichTextMultiLine(str, V.RICHTEXT_PARAM_LIGHT_S2)
        lc.addChildToCenter(bg, label)
    end

    return layout
end

function _M:isLocked(info)
    local isLocked, str = false, ""
    local value = info._type * 100 + 1
    if value == 103001 and P:getCharacterUnlockCount() < 2 then
        isLocked = true
        str = string.format(Str(STR.NEED_UNLOCK_CHARACTER_COUNT), 2)
    elseif value == 104001 and P:getCharacterUnlockCount() < 2 then
        isLocked = true
        str = string.format(Str(STR.NEED_UNLOCK_CHARACTER_COUNT), 2)
    end
    return isLocked, str
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

function _M:showCardBox(info)
    if self._detailPanel then
        return self:updateCardBox()
    end

    self._list:setVisible(false)

    local packageBtn = V.createShaderButton(nil, function(sender) self:hideCardBox() end)

    local node = cc.Node:create()
    node:setContentSize(cc.size(V.SCR_W-V.VERTICAL_TAB_WIDTH, lc.h(self)))

    node:setAnchorPoint(cc.p(0.5, 0.5))
     lc.addChildToCenter(self, node)
    
    self._detailPanel = node

    self._detailPanel._package = packageBtn

    -- card list
    self:addCardList(node, info._type)


    -- reset
    self:updateCardBox()

    -- animation
    packageBtn:setPosition(cc.p(lc.x(packageBtn) + 100, lc.y(packageBtn)))
    packageBtn:runAction(lc.sequence(
        lc.moveBy(0.2, cc.p(-100, 0))
        ))

    node:setVisible(false)
    node:setPositionX(lc.cw(self) - 80)
    node:runAction(lc.sequence(
        lc.delay(0.2), 
        lc.show(),
        lc.ease(lc.moveBy(0.3, cc.p(80, 0)), "BackO")
        ))

    local resPanel = V.getResourceUI()
    resPanel:setMode(Data.PropsId.times_package_ticket)

end

function _M:updateCardBox()
    if not self._detailPanel then
        return
    end

    self:updateCardList()
end

function _M:hideCardBox()
    self._list:setVisible(true)

    if self._detailPanel then
        self._detailPanel._package:removeFromParent()
        self._detailPanel._package = nil

        self._cardList:removeFromParent()
        self._cardList = nil

        self._detailPanel:removeFromParent()
        self._detailPanel = nil
    end

    local resPanel = V.getResourceUI()
    resPanel:setMode(Data.ResType.gold)
end

function _M:addCardList(node, packageType)

    local bgV = ccui.Scale9Sprite:createWithSpriteFrameName("depot_shop_bg1", cc.rect(27, 13, 1, 1))
    bgV:setContentSize(cc.size(lc.w(node) - 95, lc.h(node) - 40))
    lc.addChildToPos(node, bgV, cc.p(lc.cw(node), lc.ch(node) + 20))

    local bgH1 = ccui.Scale9Sprite:createWithSpriteFrameName("depot_shop_bg2", cc.rect(61, 30, 1, 1))
    bgH1:setContentSize(cc.size(lc.w(node) - 20, lc.h(bgH1)))
    lc.addChildToPos(node, bgH1, cc.p(lc.cw(node), lc.ch(node) + 125))

    local bgH2 = ccui.Scale9Sprite:createWithSpriteFrameName("depot_shop_bg2", cc.rect(61, 30, 1, 1))
    bgH2:setContentSize(cc.size(lc.w(node) - 20, lc.h(bgH2)))
    lc.addChildToPos(node, bgH2, cc.p(lc.cw(node), 168))

    local cardList = CardList.create(cc.size(lc.w(node) - 100, lc.h(node) - 60), 0.5, false, 220)
    cardList:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(node, cardList, cc.p(lc.cw(node), lc.ch(cardList) + 15))
    local onBuy = function(sender)
        local card = sender._card

        if card._price > P:getItemCount(card._priceType) then
            if card._priceType == Data.PropsId.times_package_ticket then
                ToastManager.push(string.format(Str(STR.NOT_ENOUGH), Str(Data._propsInfo[Data.PropsId.times_package_ticket]._nameSid)))
                return require("ExchangeResForm").create(Data.PropsId.times_package_ticket):show()
            else
                return ToastManager.push(string.format(Str(STR.NOT_ENOUGH), Str(Data._propsInfo[card._priceType]._nameSid)))
            end
        end

        ClientData.sendBuyDiamond(card._id)
        P._playerCard:addCard(card._infoId, 1)
        P:addResource(card._priceType, nil, -card._price)
        require("RewardCardPanel").create(Str(STR.BUYSUCCESS), {card}):show()
        lc.Audio.playAudio(AUDIO.E_CARD_GET)
        cardList:refresh()
    end
    local confirmBuy = function(sender)
        local card = sender._card
        local getNum = P._playerCard:getCardCount(card._infoId)
        local cardInfo = Data.getInfo(card._infoId)
        local maxCount = cardInfo._maxCount or 3
        if getNum >= maxCount then
            return require("Dialog").showDialog(Str(STR.SHOP_CARD_MAX_CONFIRM), function() onBuy(sender) end)
        end

        return require("Dialog").showDialog(Str(STR.SURE_TO_BUY), function() onBuy(sender) end )

    end
    cardList:registerTapBtnCustom1(confirmBuy)
    cardList:setMode(CardList.ModeType.diamond_shop)
    cardList._diamondInfo = self._packages[packageType]
    cardList:registerCardSelectedHandler(function (card, index)
        local CardInfoPanel = require("CardInfoPanel")
        local cardInfoPanel = CardInfoPanel.create(card, 1, CardInfoPanel.OperateType.view, cardList._diamondInfo[index])
        cardInfoPanel:show()
    end)
    cardList:init(Data.BaseCardTypes[1]) 
    cardList._pageLabel:setPositionY(cardList._pageLabel:getPositionY())
    cardList:refresh(true)
    self._cardList = cardList
    local offX = 10
    cardList._pageLeft._pos = cc.p(offX, lc.ch(cardList))
    cardList._pageRight._pos = cc.p(lc.w(cardList) - offX, lc.ch(cardList))

    local pageBg = lc.createSprite({_name = "img_page_bg", _size = cc.size(125, 33), _crect = cc.rect(11, 11, 4, 8)}) 
    lc.addChildToPos(self._cardList, pageBg, cc.p( 0, lc.ch(pageBg) + 50), -1)
    pageBg:setScale(-1.0, 0.9)
    self._cardList._pageLabel:setPosition(cc.p(pageBg:getPosition()))
end

function _M:updateCardList()
    self._cardList:refresh()
end

return _M