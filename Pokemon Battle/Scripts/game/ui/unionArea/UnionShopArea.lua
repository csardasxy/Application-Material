local _M = class("UnionShopArea", lc.ExtendCCNode)
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

    local list = lc.List.createH(cc.size(V.SCR_W - 20, lc.h(self) - 60), 0, 60)
    list:setAnchorPoint(0.5, 0.5)
    lc.addChildToPos(self, list, cc.p(lc.cw(self), lc.ch(self)))
    self._list = list

    self._recruitItems = {}
    local types = {}
    for k,v in pairs(self._packageCardNum) do
        types[#types + 1] = k
    end
    table.sort(types, function(a, b) return a > b end)
    for i = 1, #types do
        local item = self:createRecruitItem({_type = types[i]})
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
    local productInfos = Data._unionProductsExInfo
    local packages = {}
    local packageCardNum = {}
    for _,v in ipairs(productInfos) do
        local type = v._type
        if packages[type] == nil then
            packages[type] = {}
        end
        if not packageCardNum[type] then
            packageCardNum[type] = 0
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
            local disCounts = Data._globalInfo._unionShopDiscountMonth
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
            local disCount = 100
            if j > 0 then
                cost = cost * Data._globalInfo._unionShopDiscount[j]/100
            end
            table.insert(packages[type], {_infoId=id , _price=cost, _priceType=v._resType,_disCount=j,  _id=v._id})
            packageCardNum[type] = packageCardNum[type] + 1
        end
    end
    self._packages = packages
    self._packageCardNum = packageCardNum
end

function _M:createRecruitItem(info)
    local layout = ccui.Layout:create()
    layout:setContentSize(cc.size(BUTTON_WIDTH, lc.h(self)))
    layout:setAnchorPoint(0.5, 0.5)

    local titleBg = V.createUnionCardPackage(info)

    local btn = V.createShaderButton(nil, function(sender)
        if self._packageCardNum[info._type] > 0 then
            self:showCardBox(info)
        else
            ToastManager.push(Str(STR.ONSALE_NEXT_MONTH))
        end
    end)
    btn:setContentSize(titleBg:getContentSize())
    btn:setZoomScale(0.02)
    lc.addChildToCenter(btn, titleBg)

    lc.addChildToCenter(layout, btn)
    
    layout._info = info

    -- check locked
    local isLocked, str = false, ""

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

--    local package = V.createUnionCardPackage(info)
    local packageBtn = V.createShaderButton(nil, function(sender) self:hideCardBox() end)
--    packageBtn:setContentSize(package:getContentSize())
--    lc.addChildToPos(self, packageBtn, cc.p(0, lc.ch(self)) , 101)

    local node = cc.Node:create()
--    node:setContentSize(cc.size(lc.w(self) - lc.cw(packageBtn) - 40, lc.h(self)))
    node:setContentSize(cc.size(V.SCR_W-V.VERTICAL_TAB_WIDTH, lc.h(self)))

    node:setAnchorPoint(cc.p(0.5, 0.5))
--    local offx = (V.SCR_W - V.FRAME_INNER_RIGHT - self:convertToWorldSpace(cc.p(lc.right(packageBtn), 0)).x - lc.w(node)) / 2
--    lc.addChildToPos(self, node, cc.p(lc.w(self) - lc.cw(node) + offx, lc.ch(self)))
     lc.addChildToCenter(self, node)
    
    self._detailPanel = node

--    lc.addChildToCenter(packageBtn, package)
    self._detailPanel._package = packageBtn

    -- card list
    self:addCardList(node, info._type)

    -- box info
--    local bg = lc.createSprite({_name = "img_com_bg_40", _size = cc.size(V.SCR_W - 240, 66), _crect = cc.rect(4, 33, 1, 1)})
--    lc.addChildToPos(node, bg, cc.p(V.SCR_W - lc.cw(bg), 166))

--    local countBgSize
--    if info._type == 1002 then
--        countBgSize = cc.size(80, 30)
--    else
--        countBgSize = cc.size(40, 30)
--    end
--    node._cardCounts = {}
--    local qualityIcons = {"img_icon_quality_n", "img_icon_quality_r", "img_icon_quality_sr", "img_icon_quality_ur"}
--    for i = 1, 4 do
--        local pos = cc.p((countBgSize.width+54) * (4 - i) + 50, lc.ch(bg) - 4)

--        local icon = lc.createSprite(qualityIcons[i])
--        lc.addChildToPos(bg, icon, pos)

--        local countBg = lc.createSprite({_name = "img_com_bg_42", _crect = V.CRECT_COM_BG42, _size = countBgSize})
--        lc.addChildToPos(icon, countBg, cc.p(lc.w(icon) + lc.cw(countBg) - 4, lc.ch(icon)), -1)

--        local label = V.createTTF("100/100", V.FontSize.S3)
--        lc.addChildToPos(countBg, label, cc.p(lc.cw(countBg) - 2, lc.ch(countBg) + 2))
--        node._cardCounts[i] = label
--    end

--    if info._type == 1002 then
        -- remain package count
--        local countRemain = V.createTTF(Str(STR.REMIAN_CARD_PACKAGE), V.FontSize.S3)
--        lc.addChildToPos(bg, countRemain, cc.p(lc.w(bg) - 180, lc.ch(bg) + 16))

--        local countBg = lc.createSprite({_name = "img_com_bg_42", _crect = V.CRECT_COM_BG42, _size = cc.size(80, 30)})
--        lc.addChildToPos(bg, countBg, cc.p(lc.x(countRemain), lc.ch(bg) - 14))

--        local countLabel = V.createTTF("200", V.FontSize.S2)
--        lc.addChildToPos(countBg, countLabel, cc.p(lc.cw(countBg) - 2, lc.ch(countBg) + 2))
--        node._packageCount = countLabel

--    else
--        -- remain ui count
--        local str = string.format(Str(STR.RECRUIT_MORE_TIP), 10)
--        local buyTip = V.createBoldRichTextMultiLine(str, V.RICHTEXT_PARAM_LIGHT_S2)
--        lc.addChildToPos(bg, buyTip, cc.p(lc.w(bg) - 240, lc.ch(bg)), 2)
--        node._buyTip = buyTip

--        local tipBg = lc.createSprite({_name = "img_com_bg_42", _size = cc.size(lc.w(buyTip) + 20, 44), _crect = V.CRECT_COM_BG42})
--        lc.addChildToPos(bg, tipBg, cc.p(lc.x(buyTip), lc.y(buyTip) - 2))

--        lc.offset(buyTip, 120, 0)
--        lc.offset(tipBg, 120, 0)
--    end

    -- reset
    self:updateCardBox()

    -- animation
    packageBtn:setPosition(cc.p(lc.x(packageBtn) + 100, lc.y(packageBtn)))
    packageBtn:runAction(lc.sequence(
        lc.moveBy(0.2, cc.p(-100, 0))
        ))

    node:setVisible(false)
    node:setPositionX(lc.cw(self) - 200)
    node:runAction(lc.sequence(
        lc.delay(0.2), 
        lc.show(),
        lc.ease(lc.moveBy(0.3, cc.p(200, 0)), "BackO")
        ))

end

function _M:updateCardBox()
    if not self._detailPanel then
        return
    end

    self:updateCardList()

--    local remainCounts, getCounts, packageCount = self:getPackageInfo()

--    if self._detailPanel._packageCount then
--        for i = 1, #self._detailPanel._cardCounts do
--            self._detailPanel._cardCounts[i]:setString(string.format("%d/%d", remainCounts[i], getCounts[i] + remainCounts[i]))
--        end

--        self._detailPanel._packageCount:setString(packageCount)

--    else
--        for i = 1, #self._detailPanel._cardCounts do
--            self._detailPanel._cardCounts[i]:setString(getCounts[i] + remainCounts[i])
--        end
--    end

--    if self._detailPanel._buyTip then
--        local str = string.format(Str(STR.RECRUIT_MORE_TIP), self._remainUrCount)
--        V.updateBoldRichTextMultiLine(self._detailPanel._buyTip, str)
--    end

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
end

function _M:addCardList(node, packageType)

    local bgV = ccui.Scale9Sprite:createWithSpriteFrameName("depot_shop_bg1", cc.rect(27, 13, 1, 1))
    bgV:setContentSize(cc.size(lc.w(node) - 75, lc.h(node) + 18))
    lc.addChildToPos(node, bgV, cc.p(lc.cw(node), lc.ch(node)))

    local bgH1 = ccui.Scale9Sprite:createWithSpriteFrameName("depot_shop_bg2", cc.rect(61, 30, 1, 1))
    bgH1:setContentSize(cc.size(lc.w(node), lc.h(bgH1)))
    lc.addChildToPos(node, bgH1, cc.p(lc.cw(node), lc.ch(node) + 130))

    local bgH2 = ccui.Scale9Sprite:createWithSpriteFrameName("depot_shop_bg2", cc.rect(61, 30, 1, 1))
    bgH2:setContentSize(cc.size(lc.w(node), lc.h(bgH2)))
    lc.addChildToPos(node, bgH2, cc.p(lc.cw(node), 138))

    local cardList = CardList.create(cc.size(lc.w(node) - 100, lc.h(node)), 0.5, false, 220)
    cardList:setAnchorPoint(0.5, 0.5)
    lc.addChildToCenter(node, cardList)
    local onBuy = function(sender)
        local card = sender._card
        ClientData.sendBuyUnion(card._id)
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
            return ToastManager.push(Str(STR.SHOP_CARD_MAX))
        end

        local card = sender._card
        if card._price > P:getItemCount(card._priceType) then
            ToastManager.push(string.format(Str(STR.NOT_ENOUGH), Str(Data._propsInfo[Data.PropsId.yubi]._nameSid)))
            require("UnionContributeForm").create():show()
        else
            require("Dialog").showDialog(Str(STR.SURE_TO_BUY), function() onBuy(sender) end )
        end
    end
    cardList:registerTapBtnCustom1(confirmBuy)
    cardList:setMode(CardList.ModeType.union_shop)
    cardList._unionInfo = self._packages[packageType]
    cardList:registerCardSelectedHandler(function (card, index)
        local CardInfoPanel = require("CardInfoPanel")
        local cardInfoPanel = CardInfoPanel.create(card, 1, CardInfoPanel.OperateType.view, cardList._unionInfo[index])
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
    lc.addChildToPos(self._cardList, pageBg, cc.p( 0, lc.ch(pageBg) + 20), -1)
    pageBg:setScale(-1.0, 0.9)
    self._cardList._pageLabel:setPosition(cc.p(pageBg:getPosition()))
end

function _M:updateCardList()
    self._cardList:refresh()
end

return _M