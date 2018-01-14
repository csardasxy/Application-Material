local _M = class("PlayerMarket")

local TYPE = Data.MarketBuyType

-- Goods: means the product is generated locally by using excel
-- Products: means the product is required from server

function _M:ctor()
    self._products = {}
    self._rareGoodsMap = {}
    self._godGoodsMap = {}
    self._exchangeMap = {}
    self._refreshingBits = 0
    
    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
end

function _M:clear()
    for k in pairs(self._products) do
        self._products[k] = {}
    end
    self._rareGoodsMap = {}
    self._godGoodsMap = {}
    self._exchangeMap = {}
    self._refreshingBits = 0
end

function _M:clearUnionMarket()
    self._products[TYPE.union] = {}
    self:clearRefreshing(TYPE.union)
end

function _M:init(pbMarket)
    self._offs = {1, 1, 1, 1, 1, 1, 1}
    if P._playerActivity._actMarketOff then
        local off = P._playerActivity._actMarketOff
        for i = Data.MarketBuyType.daily, Data.MarketBuyType.dragon_flag do
            self._offs[i] = off._bonusId[i - Data.MarketBuyType.daily + 1] / 10
        end
    end

    self._nextRefreshTime = pbMarket.next_refresh / 1000
    self._fragMarketTimestamp = pbMarket.last_open / 1000

    self:initProducts(pbMarket.bundles, TYPE.random)
    --self:initProducts(pbMarket.pvp_bundles, TYPE.flag)
    self:initProducts(pbMarket.ladder_bundles, TYPE.dragon_flag)
    --self:initProducts(pbMarket.myst_bundles, TYPE.fragment)

    self:initGifts(pbMarket.gifts)

    self:initRareGoodsMap(pbMarket.rare_bundles)
    self:initGodGoodsMap(pbMarket.legend_bundles)
    self:initExchangeMap(pbMarket.exchange_prop_limit)
end

function _M:initRareGoodsMap(ids)
    for _, id in ipairs(ids) do
        self._rareGoodsMap[id] = 1
    end
end

function _M:initGodGoodsMap(ids)
    for _, id in ipairs(ids) do
        self._godGoodsMap[id] = 1
    end
end

function _M:initExchangeMap(limits)
    for _, limit in ipairs(limits) do
        local id = limit.bundle_id
        local num = limit.limit
        self._exchangeMap[id] = num
    end
end

function _M:initProducts(pbBundles, type)
    self._products[type] = {}
    local products = self._products[type]

    for _, bundle in ipairs(pbBundles) do
        local product = self:createProduct(bundle, type)
        table.insert(products, product)
    end

    local sortFixed = function(a, b)
        if a._isFixed == b._isFixed then
            return a._id < b._id
        else
            return a._isFixed
        end
    end

    if type == TYPE.flag then
        table.sort(products, sortFixed)

    elseif type == TYPE.union then
        table.sort(products, function(a, b)
            local unionLevel = P._playerUnion:getMyUnion()._level
            if unionLevel >= a._info._level and unionLevel >= b._info._level then
                return sortFixed(a, b)
            else
                return a._info._level < b._info._level
            end
        end)

    elseif type == TYPE.fragment then
        -- Nothing to do

    end

    self:clearRefreshing(type)
    self:sendMarketListDirty(type)
end

function _M:initGifts(pbGifts)
    self._gifts = {}
    if pbGifts == nil then
        self._gifts._timestamp = 0
        return
    end

    for _, gift in ipairs(pbGifts) do
        table.insert(self._gifts, {_infoId = gift.info_id, _num = gift.num, _level = gift.level, _isFragment = gift.is_fragment})
    end

    self._gifts._price = 500
    self._gifts._timestamp = ClientData.getCurrentTime()
end

function _M:createProduct(pbProduct, productType)
    local product = {}
    product._id = pbProduct.id
    product._type = productType
    product._isAvailable = pbProduct.is_available

    local res = pbProduct.product
    product._infoId = res.info_id
    product._num = res.num
    product._isFragment = res.is_fragment
    product._level = res.level
    
    if productType == Data.MarketBuyType.fragment then
        local cost = pbProduct.cost
        product._resType = cost.info_id
        product._cost = cost.num
        product._costFragment = true

    else
        product._productId = pbProduct.info_id
        product._buyCount = pbProduct.count

        local info, cost
        if productType == Data.MarketBuyType.random then
            info = Data._productsInfo[product._productId]
            cost = info._cost
        elseif productType == Data.MarketBuyType.flag then
            info = Data._pvpProductsInfo[product._productId]
            cost = info._cost
        elseif productType == Data.MarketBuyType.union then
            info = Data._unionProductsInfo[product._productId]
            cost = self:getProductCost(product, info)

            local heroInfo, type = Data.getInfo(product._infoId)
            if heroInfo ~= nil and type == Data.CardType.monster and heroInfo._fragmentCount >= 80 then
                if info._param[2] == nil or info._param[2] == 0 then
                    product._buyCountMax = info._count
                else
                    product._buyCountMax = info._param[2]
                end
            else                
                product._buyCountMax = info._count
            end
        elseif productType == Data.MarketBuyType.dragon_flag then
            info = Data._ladderProductsInfo[product._productId]
            cost = self:getProductCost(product, info)
            product._buyCountMax = info._count
        end

        product._info = info
        product._resType = info._resType
        product._cost = cost * product._num * self._offs[productType]
        product._isFixed = (info._isFixed == 1)
    end

    return product
end

function _M:getProductCost(product, info)
    info = info or product._info
    local heroInfo, type = Data.getInfo(product._infoId)
    if heroInfo ~= nil and type == Data.CardType.monster then
        if product._type == TYPE.union then
            local cost
            if info._param[1] == nil or info._param[1] == 0 then
                cost = info._cost
            else
                cost = info._param[1]
            end

            local costFlag
            if info._param[3] == nil or info._param[3] == 0 then
                costFlag = info._costFlag
            else
                costFlag = info._param[3]
            end

            return math.floor(cost * math.pow(costFlag / 100, product._buyCount))
        end
    end
    
    if product._type == TYPE.union or product._type == TYPE.dragon_flag then
        return math.floor(info._cost * math.pow(info._costFlag / 100, product._buyCount))
    end

    return info._cost 
end

function _M:scheduler(dt)
    -- Check fragment market close
    if self._fragMarketTimestamp > 0 then
        if self:isFragMarketClosed() then
            self:closeFragMarket()
        end
    end

    -- Check gift
    if self._gifts._timestamp > 0 then
        if self:isGiftsClosed() then
            self:closeGifts()
        end
    end

    -- Check refresh
    local curTime = ClientData.getCurrentTime()
    if curTime > self._nextRefreshTime then
        if not self:isRefreshing(Data.MarketBuyType.random) then
            self._refreshingBits = bor(0, blsh(1, Data.MarketBuyType.random), --[[blsh(1, Data.MarketBuyType.flag),]] blsh(1, Data.MarketBuyType.dragon_flag))
            ClientData.sendProductsRefreshAll()
        end
    end

    if P:hasUnion() then
        if curTime > P._playerUnion._nextRefreshTime then
            self:sendRefresh(Data.MarketBuyType.union)
        end
    end
end

function _M:sendRefresh(type, infoId)
    if not self:isRefreshing(type) then
        self._refreshingBits = bor(self._refreshingBits, blsh(1, type))
        ClientData.sendProductsRefresh(type, infoId)
    end
end

function _M:isRefreshing(type)
    if self._refreshingBits == 0 then
        return false
    end

    return band(self._refreshingBits, blsh(1, type)) ~= 0
end

function _M:clearRefreshing(type)
    self._refreshingBits = band(self._refreshingBits, bnot(blsh(1, type)))
end

function _M:getProducts(type)
    if type == TYPE.daily then
        return self:getGoods()
    elseif type == TYPE.vip then
        return self:getVipGoods()
    else
        products = self._products[type]
        if type == TYPE.random then
            products = P:sortResultItems(products)
        end

        return products
    end
end

function _M:getGoods()
    local goods = {}

    for _, v in pairs(Data._goodsInfo) do
        local infoId = v._infoId
        if infoId >= 7015 and infoId <= 7018 then
            local good = {_id = v._id, _infoId = v._infoId, _level = v._level, _resType = v._resType, _num = v._num, _isFragment = (v._isFragment > 0), _type = TYPE.daily, _isAvailable = self:getBuyGoodsNumber(infoId) > 0}
            good._cost = v._cost * good._num * self._offs[TYPE.daily]
            table.insert(goods, good)
        end
    end
    table.sort(goods, function(a, b)
        return Data._propsInfo[a._infoId]._rank < Data._propsInfo[b._infoId]._rank
    end)

    -- Check market activity
    --[[
    local actMarket = P._playerActivity._actMarket
    if actMarket then
        for i, id in ipairs(actMarket._bonusId) do
            local v = Data._activityGoodsInfo[id]
            if v._isVip == 0 then
                local good = {_id = v._id, _infoId = v._infoId, _info = v, _level = v._level, _resType = v._resType, _num = v._num, _isFragment = (v._isFragment > 0), _type = TYPE.daily, _isAvailable = true, _isAct = true}
                if v._buyCountMax > 0 then
                    good._buyCount = P._playerActivity._productBuyCounts[v._id] or 0
                    good._buyCountMax = v._buyCountMax
                end
                good._cost = v._cost * good._num * self._offs[TYPE.daily]
                table.insert(goods, 1, good)
            end
        end
    end
    ]]
    
    return goods
end

function _M:getVipGoods()
    local goods = {}

    -- Check market activity
    local actMarket = P._playerActivity._actMarket
    if actMarket then
        for i, id in ipairs(actMarket._bonusId) do
            local v = Data._activityGoodsInfo[id]
            if v._isVip == 1 then
                local good = {_id = v._id, _infoId = v._infoId, _info = v, _level = v._level, _resType = v._resType, _num = v._num, _isFragment = (v._isFragment > 0), _type = TYPE.vip, _isAvailable = true, _isAct = true, _isVip = true}
                if v._buyCountMax > 0 then
                    good._buyCount = P._playerActivity._productBuyCounts[v._id] or 0
                    good._buyCountMax = v._buyCountMax
                end
                good._cost = v._cost * good._num * self._offs[TYPE.vip]
                table.insert(goods, good)
            end
        end
    end

    return goods
end

function _M:hasVipGoods()
    local actMarket = P._playerActivity._actMarket
    if actMarket then
        for i, id in ipairs(actMarket._bonusId) do
            lc.log("id = %d", id)
            local v = Data._activityGoodsInfo[id]
            if v._isVip == 1 then
                return true
            end
        end
    end

    return false
end

function _M:getBuyGoodsNumber(infoId, isTotal) 
    local player, remainTimes = P

    if infoId == Data.PropsId.orange_hero_f_box then
        remainTimes = player:getBuyOrangeHeroFBoxNumber()
        return remainTimes + (isTotal and player._dailyBuyOrangeHeroFBox or 0)
    elseif infoId == Data.PropsId.purple_hero_f_box then
        remainTimes = P:getBuyPurpleHeroFBoxNumber()
        return remainTimes + (isTotal and player._dailyBuyPurpleHeroFBox or 0)
    elseif infoId == Data.PropsId.dust_monster then
        remainTimes = P:getBuyHeroExpNumber()
        return remainTimes + (isTotal and player._dailyBuyHeroExp or 0)
    elseif infoId == Data.PropsId.dust_magic then
        remainTimes = P:getBuyEquipExpNumber()
        return remainTimes + (isTotal and player._dailyBuyEquipExp or 0)
    elseif infoId == Data.PropsId.dust_trap then
        remainTimes = P:getBuyHorseExpNumber()
        return remainTimes + (isTotal and player._dailyBuyHorseExp or 0)
    elseif infoId == Data.PropsId.dust_rare then
        remainTimes = P:getBuyBookExpNumber()
        return remainTimes + (isTotal and player._dailyBuyBookExp or 0)
    elseif infoId == Data.PropsId.orange_horse_f_box then
        remainTimes = P:getBuyOrangeHorseFBoxNumber()
        return remainTimes + (isTotal and player._dailyBuyOrangeHorseFBox or 0)
    elseif infoId == Data.PropsId.purple_horse_f_box then
        remainTimes = P:getBuyPurpleHorseFBoxNumber()
        return remainTimes + (isTotal and player._dailyBuyPurpleHorseFBox or 0)
    elseif infoId == Data.PropsId.evolute_material then
        remainTimes = P:getBuyRemedyNumber()
        return remainTimes + (isTotal and player._dailyBuyRemedy or 0)
    elseif infoId == Data.PropsId.polish then
        remainTimes = P:getBuyStoneNumber()
        return remainTimes + (isTotal and player._dailyBuyStone or 0)
    end

    return 0
end

function _M:buyGoods(product, count)
    local cost = product._cost * count
    if not P:hasResource(product._resType, cost) then
        if product._resType == Data.ResType.ingot then
            return Data.ErrorType.need_more_ingot            
        elseif product._resType == Data.ResType.gold then
            return Data.ErrorType.need_more_gold
        end        
    end  
        
    if product._infoId == Data.PropsId.orange_hero_f_box then
        P._dailyBuyOrangeHeroFBox = P._dailyBuyOrangeHeroFBox  + count
        product._isAvailable = P:getBuyOrangeHeroFBoxNumber() > 0

    elseif product._infoId == Data.PropsId.purple_hero_f_box then
        P._dailyBuyPurpleHeroFBox = P._dailyBuyPurpleHeroFBox + count
        product._isAvailable = P:getBuyPurpleHeroFBoxNumber() > 0

    elseif product._infoId == Data.PropsId.orange_horse_f_box then
        P._dailyBuyOrangeHorseFBox = P._dailyBuyOrangeHorseFBox + count
        product._isAvailable = P:getBuyOrangeHorseFBoxNumber() > 0

    elseif product._infoId == Data.PropsId.purple_horse_f_box then
        P._dailyBuyPurpleHorseFBox = P._dailyBuyPurpleHorseFBox + count
        product._isAvailable = P:getBuyPurpleHorseFBoxNumber() > 0

    elseif product._infoId == Data.PropsId.dust_monster then
        P._dailyBuyHeroExp = P._dailyBuyHeroExp + count
        product._isAvailable = P:getBuyHeroExpNumber() > 0

    elseif product._infoId == Data.PropsId.dust_magic then
        P._dailyBuyEquipExp = P._dailyBuyEquipExp + count
        product._isAvailable = P:getBuyEquipExpNumber() > 0

    elseif product._infoId == Data.PropsId.dust_trap then
        P._dailyBuyHorseExp = P._dailyBuyHorseExp + count
        product._isAvailable = P:getBuyHorseExpNumber() > 0

    elseif product._infoId == Data.PropsId.dust_rare then
        P._dailyBuyBookExp = P._dailyBuyBookExp + count
        product._isAvailable = P:getBuyBookExpNumber() > 0

    elseif product._infoId == Data.PropsId.evolute_material then
        P._dailyBuyRemedy = P._dailyBuyRemedy + count
        product._isAvailable = P:getBuyRemedyNumber() > 0

    elseif product._infoId == Data.PropsId.polish then
        P._dailyBuyStone = P._dailyBuyStone + count
        product._isAvailable = P:getBuyStoneNumber() > 0

    end
    
    P:changeResource(product._resType, -cost)
    P._propBag:changeProps(product._infoId, product._num * count)

    if product._buyCountMax then
        product._buyCount = product._buyCount + 1

        if product._isAct then
            P._playerActivity._productBuyCounts[product._id] = product._buyCount
        end
    end

    self:sendProductDirty(product)
    
    return Data.ErrorType.ok
end

function _M:buyProduct(product)
    if product then
        local resType = product._resType
        local type = Data.getType(resType)
        if type == Data.CardType.res then
            if not P:hasResource(resType, product._cost) then
                if resType == Data.ResType.gold then
                    return Data.ErrorType.need_more_gold
                elseif resType == Data.ResType.grain then
                    return Data.ErrorType.need_more_grain
                elseif resType == Data.ResType.ingot then
                    return Data.ErrorType.need_more_ingot
                end
                
                return Data.ErrorType.error
            end
            P:changeResource(resType, -product._cost)

        elseif type == Data.CardType.props then
            if not P._propBag:hasProps(resType, product._cost) then
                return Data.ErrorType.need_more_money
            end
            P._propBag:changeProps(resType, -product._cost)

        else
            return Data.ErrorType.error
        end
        
        P:addResources({product._infoId}, {product._level}, {product._num}, {product._isFragment})
        
        if product._buyCountMax then
            product._buyCount = product._buyCount + 1
            product._cost = self:getProductCost(product) * product._num * self._offs[product._type]

            if product._isAct then
                P._playerActivity._productBuyCounts[product._id] = product._buyCount
            end

        else
            if not product._isAct then
                product._isAvailable = false
            end
        end

        self:sendProductDirty(product)
    
        return Data.ErrorType.ok
    end
    
    return Data.ErrorType.error
end

function _M:buyGifts()
    if #self._gifts._timestamp == 0 then return end


end

function _M:getGiftRemainTime()
    if self._gifts._timestamp == 0 then
        return 0
    end
    return self._gifts._timestamp + Data._globalInfo._shopOpenTime * 3600 - ClientData.getCurrentTime()
end

function _M:isGiftsClosed()
    return self:getGiftRemainTime() <= 0
end

function _M:closeGifts()
    self._gifts._timestamp = 0
    lc.sendEvent(Data.Event.gift_closed)
end

function _M:getFragMarketRemainTime()
    if self._fragMarketTimestamp == 0 then
        return 0
    end
    return self._fragMarketTimestamp + Data._globalInfo._shopOpenTime * 3600 - ClientData.getCurrentTime()
end

function _M:isFragMarketClosed()
    return self:getFragMarketRemainTime() <= 0
end

function _M:closeFragMarket()
    self._fragMarketTimestamp = 0
    self:sendFragMarketClosed()
end

function _M:onMsg(msg)    
    local msgType = msg.type
    local msgStatus = msg.status
    
    if msgType == SglMsgType_pb.PB_TYPE_SHOP_REFRESH or msgType == SglMsgType_pb.PB_TYPE_SHOP_REFRESH_EX then
        local pbMarket = msg.Extensions[Shop_pb.SglShopMsg.shop_refresh_resp]
        self._nextRefreshTime = pbMarket.next_refresh / 1000
        self:initProducts(pbMarket.bundles, TYPE.random)
    
        return true 

    elseif msgType == SglMsgType_pb.PB_TYPE_SHOP_REFRESH_PVP or msgType == SglMsgType_pb.PB_TYPE_SHOP_REFRESH_PVP_EX then
        local pbMarket = msg.Extensions[Shop_pb.SglShopMsg.shop_refresh_resp]
        self._nextRefreshTime = pbMarket.next_refresh / 1000
        self:initProducts(pbMarket.bundles, TYPE.flag)

        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_SHOP_REFRESH_LADDER or msgType == SglMsgType_pb.PB_TYPE_SHOP_REFRESH_LADDER_EX then
        local pbMarket = msg.Extensions[Shop_pb.SglShopMsg.shop_refresh_resp]
        self._nextRefreshTime = pbMarket.next_refresh / 1000
        self:initProducts(pbMarket.bundles, TYPE.dragon_flag)
    
        return true 

    elseif msgType == SglMsgType_pb.PB_TYPE_SHOP_REFRESH_ALL then
        local pbMarket = msg.Extensions[Shop_pb.SglShopMsg.shop_refresh_all_resp]
        self._nextRefreshTime = pbMarket.next_refresh / 1000
        self:initProducts(pbMarket.bundles, TYPE.random)
        self:initProducts(pbMarket.pvp_bundles, TYPE.flag)
        self:initProducts(pbMarket.ladder_bundles, TYPE.dragon_flag)

        return true
    
    elseif msgType == SglMsgType_pb.PB_TYPE_SHOP_OPEN then
        local pbMarket = msg.Extensions[Shop_pb.SglShopMsg.shop_open_resp]
        self._fragMarketTimestamp = pbMarket.last_open / 1000
        self:initProducts(pbMarket.bundles, TYPE.fragment)
        self:sendFragMarketOpen()

        local eventCustom = cc.EventCustom:new(Data.Event.push_notice)
        eventCustom._title = Str(STR.SYSTEM)
        eventCustom._content = Str(STR.NOTICE_FRAG_MARKET_OPEN)        
        lc.Dispatcher:dispatchEvent(eventCustom)

        return true
    end
    
    return false
end

function _M:sendProductDirty(product)
    local eventCustom = cc.EventCustom:new(Data.Event.product_dirty)
    eventCustom._data = product
    lc.Dispatcher:dispatchEvent(eventCustom)   
end

function _M:sendMarketListDirty(type)
    local eventCustom = cc.EventCustom:new(Data.Event.market_list_dirty)
    eventCustom._type = type
    lc.Dispatcher:dispatchEvent(eventCustom)   
end

function _M:sendFragMarketOpen()
    local eventCustom = cc.EventCustom:new(Data.Event.fragment_market_open)    
    lc.Dispatcher:dispatchEvent(eventCustom)   
end

function _M:sendFragMarketClosed()
    local eventCustom = cc.EventCustom:new(Data.Event.fragment_market_closed)    
    lc.Dispatcher:dispatchEvent(eventCustom)   
end

function _M:exchangeProp(exchange)
    local exchangeNum = self._exchangeMap[exchange._id] or 0
    ClientData.sendActivityExchange(exchange._id)
    self._exchangeMap[exchange._id] = exchangeNum + 1
    local itemIds = exchange._item
    local bonusId= exchange._reward
    local bonusInfo = Data._bonusInfo[bonusId]
    local rewardId = bonusInfo._rid[1]
    local counts = {}
    for _, count in ipairs(bonusInfo._count) do
        table.insert(counts, count * (bonusInfo._multiple or 1))
    end
    P:addResources(bonusInfo._rid, bonusInfo._level, counts, bonusInfo._isFragment)

    for i, id in ipairs(itemIds) do
        P:addResource(id, 1, -exchange._number[i], false)
    end
end

return _M
