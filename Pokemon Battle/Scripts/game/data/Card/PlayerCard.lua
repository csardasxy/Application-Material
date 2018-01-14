local _M = class("PlayerCard")

local Json = require("json")

----------------------------------------------- init --------------------------------------------------------
function _M:ctor()
    self:clear()
    
    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
end

function _M:clear()
    self._monsters = {}
    self._magics = {}
    self._traps = {}
    self._rares = {}
    
    self._cards = 
    {
        [Data.CardType.monster] = self._monsters,
        [Data.CardType.magic] = self._magics,
        [Data.CardType.trap] = self._traps,
    }
    
    self._levels = {}
    self._unlocked = {}
    self._skins = {}

    self._troops = {}
    self._guardSlots = {}

    self._groupMonsters = {}
    self._groupMagics = {}
    self._groupTraps = {}
    self._groupRares = {}
    
    self._groupCards = 
    {
        [Data.CardType.monster] = self._groupMonsters,
        [Data.CardType.magic] = self._groupMagics,
        [Data.CardType.trap] = self._groupTraps,
    }

    self._cardFragment = {}
    self._recommendTroops = {}
    self._systemRecommendTroops = {}
end

function _M:init(pbCard)
    for i = 1, #pbCard.levels do
        local pbLevel = pbCard.levels[i]
        local infoId = pbLevel.info_id
        self._levels[infoId] = pbLevel.level
        
        local cardType = Data.getType(infoId)
        self._cards[cardType][infoId] = 0
    end

    for i = 1, #pbCard.cards do
        local infoId = pbCard.cards[i].info_id
        local cardType = Data.getType(infoId)
        self._cards[cardType][infoId] = pbCard.cards[i].num
    end

    for i = 1, #pbCard.unlocked do
        self._unlocked[pbCard.unlocked[i]] = true
    end

    for i = 1, #pbCard.skin do
        local pbSkin = pbCard.skin[i]
        local skin = {_currentSkinId = pbSkin.default_skin, _availableSkins = {}}
        for j = 1, #pbSkin.skin_id do
            skin._availableSkins[j] = {_id = pbSkin.skin_id[j], _expire = math.floor(pbSkin.expire[j] / 1000)}   
        end
        self._skins[pbSkin.info_id] = skin
    end

    for i = 1, #pbCard.dark_troops do
        print ('@@@@@@@@ DARK TROOP', i)
        local pbTroop = pbCard.dark_troops[i]
        local troop = {}
        for j = 1, #pbTroop.troop_item do
            troop[j] = Data.pb2Resource(pbTroop.troop_item[j])
            print ('         ', j, troop[j]._infoId, 'x', troop[j]._num)
        end
        local index = Data.TroopIndex.dark_battle1 + i - 1
        self._troops[index] = troop
    end

    for i = 1, #pbCard.troops do
        print ('@@@@@@@@ TROOP', i)
        local pbTroop = pbCard.troops[i]
        local troop = {}
        for j = 1, #pbTroop.troop_item do
            troop[j] = Data.pb2Resource(pbTroop.troop_item[j])
            print ('         ', j, troop[j]._infoId, 'x', troop[j]._num)
        end
        self._troops[i] = troop
    end

    for i, fragment in ipairs(pbCard.fragments) do
        local infoId = fragment.info_id
        self._cardFragment[infoId] = fragment.num
    end

    for i = 1, 8 do
        self._guardSlots[#self._guardSlots + 1] = {_id = i, _level = 1}
    end
    for i = 1, #pbCard.slots do
        local pbGuardSlot = pbCard.slots[i]
        local guardSlot = self._guardSlots[pbGuardSlot.id]
        guardSlot._level = pbGuardSlot.level
        if pbGuardSlot:HasField('guard') then
            local pbGuard = pbGuardSlot.guard
            local guard = {_infoId = pbGuard.info_id, _timestamp = pbGuard.timestamp / 1000, _span = pbGuard.span / 1000}
            guardSlot._guard = guard
        end
    end
    for i = 1, 8 do
        local guardSlot = self._guardSlots[i]
        print ('@@@@@@@@ GUARD', guardSlot._id, guardSlot._level, guardSlot._guard and guardSlot._guard._infoId)
    end
    self:initSystemRecommendTroops()
end

function _M:initGroupCards(pbCard)
    for i = 1, #pbCard.cards do
        local infoId = pbCard.cards[i].info_id
        local cardType = Data.getType(infoId)
        self._groupCards[cardType][infoId] = pbCard.cards[i].num
    end
    for i = 1, #pbCard.troop do
        print ('@@@@@@@@ GROUP TROOP', i)
        local pbTroop = pbCard.troop[i]
        local troop = {}
        for j = 1, #pbTroop.troop_item do
            troop[j] = Data.pb2Resource(pbTroop.troop_item[j])
            print ('         ', j, troop[j]._infoId, 'x', troop[j]._num)
        end
        self._troops[i + Data.TroopIndex.union_battle1 - 1] = troop
    end
    lc.sendEvent(Data.Event.group_cards_dirty)
end

function _M:initRecommendTroops(pbReplays)
    self._recommendTroops = {}
    for i, pbReplay in ipairs(pbReplays) do
        local input = ClientData.genInputFromReplayResp(pbReplay)
        table.insert(self._recommendTroops, input)
    end
    lc.sendEvent(Data.Event.recommend_troop_dirty)
end

------------------------------------------------- init ---------------------------------------------------------

------------------------------------------------- onMsg ---------------------------------------------------------

function _M:onMsg(msg)
    local msgType = msg.type
    local msgStatus = msg.status

    if msgType == SglMsgType_pb.PB_TYPE_CITY_GUARD or msgType == SglMsgType_pb.PB_TYPE_CITY_PICK then
        local pbGuardSlot
        if msgType == SglMsgType_pb.PB_TYPE_CITY_GUARD then
            pbGuardSlot = msg.Extensions[City_pb.SglCityMsg.city_guard_resp]
        else
            pbGuardSlot = msg.Extensions[City_pb.SglCityMsg.city_pick_resp]
        end
        local pbGuard = pbGuardSlot:HasField('guard') and pbGuardSlot.guard or nil

        local guardSlot = self._guardSlots[pbGuardSlot.id]
        local guard = guardSlot and guardSlot._guard 
        if pbGuard ~= nil and guard ~= nil and pbGuard.info_id == guard._infoId then
            if guard._span == nil then
                guard._timestamp = pbGuard.timestamp / 1000
                guard._span = pbGuard.span / 1000
                lc.sendEvent(Data.Event.guard_confirm, guard)
            end
        end
           
        return true
    elseif msgType == SglMsgType_pb.PB_TYPE_MASSWAR_MULTIPLE_LOAD_CARDS then
        local resp = msg.Extensions[UnionWar_pb.SglUnionWarMsg.masswar_load_cards_resp]
        self:initGroupCards(resp)
        V.getActiveIndicator():hide()

        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_WORLD_RECOMMEND_TROOP then
        local resp = msg.Extensions[World_pb.SglWorldMsg.recommend_troop_resp]
        self:initRecommendTroops(resp)

        return true
    end

    return false
end

------------------------------------------------- onMsg ---------------------------------------------------------

------------------------------------------------- card operate -------------------------------------------------

function _M:upgradeCard(infoId, isChecking)
    if self._levels[infoId] >= Data.CARD_MAX_LEVEL  then
        return Data.ErrorType.card_not_support
    end

    local gold = self:getUpgradeGold(infoId)
    if not P:hasResource(Data.ResType.gold, gold) then
        return Data.ErrorType.need_more_gold
    end   
    
    local cardType = Data.getType(infoId)
    local count = self:getUpgradeCount(infoId)
    if self._cards[cardType][infoId] < count then
        return Data.ErrorType.need_more_samecard
    end    
        
    local stoneProp, stone = self:getUpgradeStone(infoId)
    if not P._propBag:hasProps(stoneProp, stone) then
        if stoneProp == Data.PropsId.stone_rare then
            return Data.ErrorType.need_more_stonerare
        else
            return Data.ErrorType.need_more_stonelegend
        end
    end
        
    if not isChecking then
        self._levels[infoId] = self._levels[infoId] + 1
        self:removeCard(infoId, count)
        P:changeResource(Data.ResType.gold, -gold)
        P._propBag:changeProps(stoneProp, -stone)
    end              
        
    return Data.ErrorType.ok
end

function _M:composeCard(infoId, count, isChecking)
    if self._levels[infoId] == nil or self._levels[infoId] == 0 then
        return Data.ErrorType.card_cannot_compose
    end

    local gold = self:getComposeGold(infoId) * count
    if not P:hasResource(Data.ResType.gold, gold) then
        return Data.ErrorType.need_more_gold
    end  

    local dustType, dust = self:getComposeDust(infoId)
    dust = dust * count
    if not P._propBag:hasProps(dustType, dust) then
        return Data.ErrorType.need_more_dust
    end

    if not isChecking then
        self:addCard(infoId, count)
        P:changeResource(Data.ResType.gold, -gold)
        P._propBag:changeProps(dustType, -dust)
    end

    return Data.ErrorType.ok        
end

function _M:composeCardByFragment(infoId, isChecking)
    local fragmentId = self:convert2FragmentId(infoId)
    local cardId = self:convert2CardId(infoId)
    local fragmentCount = self:getFragmentCount(infoId)
    local commonCount = P:getItemCount(Data.PropsId.common_fragment)
    local ret = Data.ErrorType.ok
    if fragmentCount + commonCount < Data._globalInfo._legendCardMixCount then
        ret = Data.ErrorType.fragment_not_enough
    elseif fragmentCount < Data._globalInfo._legendCardMixCount then
        ret = Data.ErrorType.compose_common_fragment
    end
    if not isChecking then
        ClientData.sendComposeCard(cardId)
        self:addCard(cardId, 1)
        if fragmentCount < Data._globalInfo._legendCardMixCount and fragmentCount + commonCount >= Data._globalInfo._legendCardMixCount then
            P:addResource(Data.PropsId.common_fragment, 1, self:getFragmentCount(infoId) - Data._globalInfo._legendCardMixCount)
        end
        self:addCard(fragmentId, - Data._globalInfo._legendCardMixCount)
    end
    return ret
end

function _M:decomposeCard(infoId, count, isChecking)
    local gold = self:getDecomposeGold(infoId) * count
    if not P:hasResource(Data.ResType.gold, gold) then
        return Data.ErrorType.need_more_gold
    end     

    local cardType = Data.getType(infoId)
    if self._cards[cardType][infoId] < count then
        return Data.ErrorType.need_more_samecard
    end    

    local dustType, dust = self:getDecomposeDust(infoId)
    dust = dust * count
    if not isChecking then
        self:removeCard(infoId, count)
        P:changeResource(Data.ResType.gold, -gold)
        --P._propBag:changeProps(dustType, dust)
        P:changeResource(dustType, dust)
    end

    return Data.ErrorType.ok, dust     
end

function _M:getCanDecomposeCount()
    local sr, r, n = 0, 0, 0
    for t = Data.CardType.monster, Data.CardType.trap do
        local cards = self._cards[t]
        for infoId, count in pairs(cards) do
            if count > 3 then
                count = count - 3
                local info = Data.getInfo(infoId)
                if info._quality == Data.CardQuality.N then n = n + count
                elseif info._quality == Data.CardQuality.R then r = r + count
                elseif info._quality == Data.CardQuality.SR then sr = sr + count
                end
            end
        end
    end
    return sr, r, n
end

function _M:decomposeAll()
    local totalDust = 0
    for t = Data.CardType.monster, Data.CardType.trap do
        local cards = self._cards[t]
        for infoId, count in pairs(cards) do
            local info = Data.getInfo(infoId)
            if count > 3 and info._quality < Data.CardQuality.UR then
                count = count - 3
                local ret, dust = self:decomposeCard(infoId, count)
                totalDust = totalDust + dust
            end
        end
    end
    return totalDust
end

function _M:recoveryCard(infoId, count, isChecking, productId)
    local cardType = Data.getType(infoId)
    if self._cards[cardType][infoId] < count then
        return Data.ErrorType.need_more_samecard
    end    

    local dustType, dust = self:getRecoveryDust(productId)
    dust = dust * count
    if not isChecking then
        self:removeCard(infoId, count)
        P:addResource(dustType, nil, dust)
    end

    return Data.ErrorType.ok, dust     
end

--function _M:getCanRecoveryCount()
--    local sr, r, n = 0, 0, 0
--    for t = Data.CardType.monster, Data.CardType.trap do
--        local cards = self._cards[t]
--        for infoId, count in pairs(cards) do
--            if count > 3 then
--                count = count - 3
--                local info = Data.getInfo(infoId)
--                if info._quality == Data.CardQuality.N then n = n + count
--                elseif info._quality == Data.CardQuality.R then r = r + count
--                elseif info._quality == Data.CardQuality.SR then sr = sr + count
--                end
--            end
--        end
--    end
--    return sr, r, n
--end

--function _M:recoveryAll()
--    local totalDust = 0
--    for t = Data.CardType.monster, Data.CardType.trap do
--        local cards = self._cards[t]
--        for infoId, count in pairs(cards) do
--            local info = Data.getInfo(infoId)
--            if count > 3 and info._quality < Data.CardQuality.UR then
--                count = count - 3
--                local ret, dust = self:decomposeCard(infoId, count)
--                totalDust = totalDust + dust
--            end
--        end
--    end
--    return totalDust
--end

-------------------------------------------- card operate ------------------------------------------------------

-------------------------------------------- card ----------------------------------------------------------

function _M:getUpgradeCount(infoId)
    local info, cardType = Data.getInfo(infoId)
    local level = self._levels[infoId]
    if level == Data.CARD_MAX_LEVEL then return 0 end

    local index = (info._quality - 1) * Data.CARD_MAX_LEVEL + level
    if cardType == Data.CardType.monster then
        return Data._globalInfo._monsterUpgradeCount[index]
    elseif cardType == Data.CardType.magic then
        return Data._globalInfo._magicUpgradeCount[index]
    elseif cardType == Data.CardType.trap then
        return Data._globalInfo._trapUpgradeCount[index]
    end
end

function _M:getUpgradeGold(infoId)
    local info, cardType = Data.getInfo(infoId)
    local level = self._levels[infoId]
    
    local index = (info._quality - 1) * Data.CARD_MAX_LEVEL + level
    if cardType == Data.CardType.monster then
        return Data._globalInfo._monsterUpgradeGold[index]
    elseif cardType == Data.CardType.magic then
        return Data._globalInfo._magicUpgradeGold[index]
    elseif cardType == Data.CardType.trap then
        return Data._globalInfo._trapUpgradeGold[index]
    end
end

function _M:getUpgradeStone(infoId)
    local info, cardType = Data.getInfo(infoId)
    local level = self._levels[infoId]
    local index = (info._quality - 1) * Data.CARD_MAX_LEVEL + level
    if cardType == Data.CardType.monster then
        return Data.PropsId.monster_stone_n + info._quality - 1, Data._globalInfo._monsterUpgradeStone[index]
    elseif cardType == Data.CardType.magic then
        return Data.PropsId.magic_stone_n + level - 1, Data._globalInfo._magicUpgradeStone[index]
    elseif cardType == Data.CardType.trap then
        return Data.PropsId.trap_stone_n + level - 1, Data._globalInfo._trapUpgradeStone[index]
    end
end

function _M:getComposeDust(infoId)
    local info, cardType = Data.getInfo(infoId)
    local level = 1
    local index = (info._quality - 1) * Data.CARD_MAX_LEVEL + level
    if cardType == Data.CardType.monster then
        return Data.PropsId.dust_monster, Data._globalInfo._monsterComposeDust[index]
    elseif cardType == Data.CardType.magic then
        return Data.PropsId.dust_magic, Data._globalInfo._magicComposeDust[index]
    elseif cardType == Data.CardType.trap then
        return Data.PropsId.dust_trap, Data._globalInfo._trapComposeDust[index]
    end
end

function _M:getComposeGold(infoId)
    local info, cardType = Data.getInfo(infoId)
    local level = 1
    local index = (info._quality - 1) * Data.CARD_MAX_LEVEL + level
    if cardType == Data.CardType.monster then
        return Data._globalInfo._monsterComposeGold[index]
    elseif cardType == Data.CardType.magic then
        return Data._globalInfo._magicComposeGold[index]
    elseif cardType == Data.CardType.trap then
        return Data._globalInfo._trapComposeGold[index]
    end
end

function _M:getDecomposeDust(infoId)
    local info, cardType = Data.getInfo(infoId)
    local level = 1
    local index = (info._quality - 1) * Data.CARD_MAX_LEVEL + level
    if cardType == Data.CardType.monster then
        return Data.ResType.gold, Data._globalInfo._monsterDecomposeDust[index]
    elseif cardType == Data.CardType.magic then
        return Data.ResType.gold, Data._globalInfo._magicDecomposeDust[index]
    elseif cardType == Data.CardType.trap then
        return Data.ResType.gold, Data._globalInfo._trapDecomposeDust[index]
    end
end

function _M:getRecoveryDust(productId)
    local info = Data._unionProductsExInfo[productId]
    local cost = info._cost
    local percent = Data._globalInfo._receveryPercent/100
    return Data.PropsId.yubi,cost*percent
end

function _M:getDecomposeGold(infoId)
    local info, cardType = Data.getInfo(infoId)
    local level = 1
    local index = (info._quality - 1) * Data.CARD_MAX_LEVEL + level
    if cardType == Data.CardType.monster then
        return Data._globalInfo._monsterDecomposeGold[index]
    elseif cardType == Data.CardType.magic then
        return Data._globalInfo._magicDecomposeGold[index]
    elseif cardType == Data.CardType.trap then
        return Data._globalInfo._trapDecomposeGold[index]
    end
end

--------------------------------------------- card ----------------------------------------------------------------

function _M:getCards(type)
    return self._cards[type]
end

function _M:getGroupCards(type)
    return self._groupCards[type]
end

function _M:getAllCards(type)
    local info
    if type == Data.CardType.monster then
        info = Data._monsterInfo
    elseif type == Data.CardType.magic then
        info = Data._magicInfo
    elseif type == Data.CardType.trap then
        info = Data._trapInfo
    end

    local cards = {}
    for k, v in pairs(info) do
        cards[k] = P._playerCard:getCardCount(k)
    end

    return cards
end

function _M:getCardCount(infoId)
    local cardType = Data.getType(infoId)
    return self._cards[cardType] and self._cards[cardType][infoId] or 0
end

function _M:getGroupCardCount(infoId)
    local cardType = Data.getType(infoId)
    return self._groupCards[cardType] and self._groupCards[cardType][infoId] or 0
end

function _M:getIsCardFragment(id)
    local cardType = Data.getType(id)
    return cardType == Data.CardType.fragment
end

function _M:convert2FragmentId(id)
    if self:getIsCardFragment(id) then
        return id
    end
    return id + 100000
end

function _M:convert2CardId(id)
    if not self:getIsCardFragment(id) then
        return id
    end
    return id - 100000
end

function _M:getFragmentCount(infoId)
    infoId = self:convert2FragmentId(infoId)
    return self._cardFragment[infoId] or 0
end

function _M:changeFragmentCount(infoId, delta)
    infoId = self:convert2FragmentId(infoId)
    local oriCount = self:getFragmentCount(infoId)
    self._cardFragment[infoId] = math.max(oriCount + delta, 0)
    self:sendFragmentDirty()
    return oriCount + delta > 0
end

function _M:addCard(infoId, count)    
    local cardType = Data.getType(infoId)
    if cardType == Data.CardType.fragment then
        self:changeFragmentCount(infoId, count)
        self:sendFragmentDirty()
    else
        self._cards[cardType][infoId] = (self._cards[cardType][infoId] or 0) + count
        self:sendCardDirty(infoId)

        if self._levels[infoId] == nil or self._levels[infoId] == 0 then
            self._unlocked[infoId] = true
            self._levels[infoId] = 1

            self:sendCardAdd(infoId)
            self:sendCardFlagDirty(infoId)
            return true
        end

        return false
    end
end

function _M:removeCard(infoId, count)
    local cardType = Data.getType(infoId)
    if cardType == Data.CardType.fragment then
        self._cardFragment[infoId] = math.max(self:getFragmentCount(infoId) - count, 0)
        self:sendFragmentDirty()
    else
        local curCount = self._cards[cardType][infoId] or 0
        if curCount >= count then
            self._cards[cardType][infoId] = curCount - count
        end

        self:sendCardDirty(infoId)

        if curCount == count then
            self:sendCardListDirty(cardType)
        end
    end
end

--------------------------------------------- card ----------------------------------------------------------------


----------------------------------------------- troop -------------------------------------------------------------------------------

function _M:updateTroop(card, troopIndex)
    local troop = self._troops[troopIndex]
    if troop ~= nil then
        for i = 1, #troop do
            if troop[i]._infoId == card._infoId then
                troop[i]._num = troop[i]._num + 1
                return
            end
        end
        table.insert(troop, {_infoId = card._infoId, _num = 1})
        --table.sort(troop, function(a, b) return a._troopPos[troopIndex] < b._troopPos[troopIndex] end)
    end
end

function _M:saveTroop(newTroop, troopIndex)
    --[[
    local dirtyCards = {}
    local troop = self._troops[troopIndex]
    for i = 1, #troop do
        dirtyCards[ troop[i]._infoId ] = troopIndex
    end
    for i = 1, #newTroop do
        if dirtyCards[ newTroop[i]._infoId ] ~= nil then
            dirtyCards[ newTroop[i]._infoId ] = nil 
        else
            dirtyCards[ newTroop[i]._infoId ] = troopIndex
        end
    end
    
    for k, v in pairs(dirtyCards) do k:sendCardTroopDirty(v) end    
    ]]

    self._troops[troopIndex] = {}
    for i = 1, #newTroop do
        self._troops[troopIndex][#self._troops[troopIndex] + 1] = {_infoId = newTroop[i]._infoId, _num = newTroop[i]._num}
    end

    return Data.ErrorType.ok
end

function _M:checkTroop(troopIndex)
    if not (P._guideID > 172 and not ClientData.isDEV()) then return true end

    if self:isTroopEmpty(troopIndex) then
        return false, Str(STR.EMPTY_IN_TROOP)
    end

    if Data.isUnionBattleTroop(troopIndex) then
        if self:getTroopCardCountByType(nil, troopIndex) < Data.MAX_UNION_TROOP_CARD_COUNT then
            return false, string.format(Str(STR.AT_LEAST_ONE_IN_TROOP), Data.MAX_UNION_TROOP_CARD_COUNT)
        end
    elseif Data.isDarkTroop(troopIndex) then
        if self:getTroopCardCountByType(nil, troopIndex) < Data.MIN_TROOP_CARD_COUNT_2 then
            return false, string.format(Str(STR.AT_LEAST_ONE_IN_TROOP), Data.MIN_TROOP_CARD_COUNT_2)
        end
    end

    local checkLevel = 30
    local minCount = P:getTotalCharacterLevel() >= checkLevel and Data.MIN_TROOP_CARD_COUNT_2 or Data.MIN_TROOP_CARD_COUNT

    if minCount == Data.MIN_TROOP_CARD_COUNT_2 then
        if P._playerCard:getTroopCardCountByType(nil, troopIndex) < minCount then
            return false, string.format(Str(STR.AT_LEAST_ONE_IN_TROOP_2), checkLevel, minCount)
        end
    else
        if P._playerCard:getTroopCardCountByType(nil, troopIndex) < minCount then
            return false, string.format(Str(STR.AT_LEAST_ONE_IN_TROOP), minCount)
        end
    end

    return true
end

function _M:isTroopEmpty(troopIndex)       
    return #self._troops[troopIndex] == 0
end

function _M:checkDarkTroops()
    local ret, str = true, ""
    for i = Data.TroopIndex.dark_battle1, Data.TroopIndex.dark_battle3 do
        ret = self:checkTroop(i)
        if not ret then  
            str = Str(STR.DARK_TROOP_CHECK_FAIL)
            break
        end
    end
    return ret, str
end

function _M:clearTroop(troopIndex)
    local troop = self._troops[troopIndex]
    if troop == nil or #troop == 0 then return end

    while #troop > 0 do
        local card = troop[1]
        card._troopPos[troopIndex] = 0
        card:sendCardTroopDirty(troopIndex)
    end
end

function _M:getTroop(troopIndex, isClone)
    local troop
    if isClone then
        troop = {}
        for _, card in ipairs(self._troops[troopIndex]) do
            table.insert(troop, card)
        end
    else
        troop = self._troops[troopIndex]
    end

    return troop
end

function _M:getTroopFightingValue(troopIndex)
    local value = 0
    return value
end

function _M:getTroopCardCountByType(type, troopIndex)
    local cards, num = self:getTroop(troopIndex), 0
    for i = 1, #cards do
        local cardType = Data.getType(cards[i]._infoId)
        if (type ~= nil and cardType == type) or (type == nil) then            
            num = num + cards[i]._num
        end
    end

    return num
end

function _M:getTroopCardCountByMinStar(minStar, troopIndex)
    local cards, num = self:getTroop(troopIndex), 0
    for i = 1, #cards do
        local info, cardType = Data.getInfo(cards[i]._infoId)
        if cardType == Data.CardType.monster and info._star >= minStar then            
            num = num + cards[i]._num
        end
    end
    return num
end

function _M:getTroopCardCountByNature(nature, troopIndex)
    local cards, num = self:getTroop(troopIndex), 0
    for i = 1, #cards do
        local info, cardType = Data.getInfo(cards[i]._infoId)
        if cardType == Data.CardType.monster and info._nature == nature then            
            num = num + cards[i]._num
        end
    end
    return num
end

function _M:getCardCountInTroop(infoId)
    local maxCount = 0
    for i = 1, #self._troops do
        local troop = self._troops[i]
        for j = 1, #troop do
            local troopCard = troop[j]
            if troopCard._infoId == infoId then
                if troopCard._num > maxCount then
                    maxCount = troopCard._num
                    break
                end
            end
        end
    end
    return maxCount
end

-------------------------------------------- troop -----------------------------------------------------------------------


----------------------------------- message ----------------------------------------------------------------------------------

function _M:sendCardDirty(infoId)
    local eventCustom = cc.EventCustom:new(Data.Event.card_dirty)
    eventCustom._infoId = infoId
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:sendFragmentDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.fragment_dirty)
    eventCustom._infoId = infoId
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:sendCardAdd(infoId)
    local eventCustom = cc.EventCustom:new(Data.Event.card_add)
    eventCustom._infoId = infoId
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:sendCardListDirty(type)
    local eventCustom = cc.EventCustom:new(Data.Event.card_list_dirty)
    eventCustom._type = type
    lc.Dispatcher:dispatchEvent(eventCustom)
       
    ClientData.setNeedSyncDataForCardListScenes()
end

function _M:sendCardFlagDirty(infoId)
    local eventCustom = cc.EventCustom:new(Data.Event.card_flag_dirty)
    eventCustom._infoId = infoId
    lc.Dispatcher:dispatchEvent(eventCustom)
       
    ClientData.setNeedSyncDataForCardListScenes()
end

function _M:sendCardSelect(infoId, count)
    local eventCustom = cc.EventCustom:new(Data.Event.card_select)
    eventCustom._infoId = infoId
    eventCustom._count = count
    lc.Dispatcher:dispatchEvent(eventCustom)
end

----------------------------------- message --------------------------------------------------------------------------------------


----------------------------------- flag ----------------------------------------------------------------------------------

function _M:getCardFlag()
    return self:getCardFlagByType()
end

function _M:getMonsterFlag()
    return self:getCardFlagByType(Data.CardType.monster)
end

function _M:getTrapFlag()
    return self:getCardFlagByType(Data.CardType.trap)
end

function _M:getMagicFlag()
    return self:getCardFlagByType(Data.CardType.magic)
end

function _M:getCardFlagByType(cardType)
    local flag = 0
    for infoId, isUnlocked in pairs(self._unlocked) do
        if isUnlocked and ((not cardType) or Data.getType(infoId) == cardType) then
            flag = flag + 1
        end
    end

    return flag
end

function _M:removeUnlocked(infoId)
    self._unlocked[infoId] = nil

    self:sendCardFlagDirty(infoId)
end

function _M:isUnlocked(infoId)
    return self._unlocked[infoId]
end

function _M:getSkinId(infoId)
    local skin = self._skins[infoId]
    if skin == nil then return 0 end
    return skin._currentSkinId
end

function _M:hasSkin(skinId, isForever)
    if skinId == 0 then return true end

    local skinInfo = Data._skinInfo[skinId]
    if skinInfo == nil then return false end
    local infoId = skinInfo._infoId
    local skin = self._skins[infoId]
    if skin == nil then return false end

    for i = 1, #skin._availableSkins do
        if skinId == skin._availableSkins[i]._id then
            if skin._availableSkins[i]._expire == 0 or not isForever then return true, skin._availableSkins[i] end 
        end
    end
    return false
end

function _M:setSkinId(infoId, skinId)
    local skin = self._skins[infoId]

    if skinId == 0 then 
        if skin ~= nil then skin._currentSkinId = skinId end
        return true
    end

    if skin == nil then return false end
    local skinInfo = Data._skinInfo[skinId]
    if skinInfo == nil then return false end
    
    for i = 1, #skin._availableSkins do
        if skinId == skin._availableSkins[i]._id then
            skin._currentSkinId = skinId
            return true
        end
    end
    return false
end

function _M:buySkinId(skinId, day)
    local skinInfo = Data._skinInfo[skinId]
    if skinInfo == nil then return false end
    if self:hasSkin(skinId, true) then return false end

    local hasSkin, availableSkin = self:hasSkin(skinId, false)
    local expire = day == 0 and 0 or ClientData.getExpireTimestamp(day)
    if hasSkin then
        if availableSkin._expire < expire then
            availableSkin._expire = expire
        end
    else
        local infoId = skinInfo._infoId
        local skin = self._skins[infoId] or {_currentSkinId = 0, _availableSkins = {}}
        skin._availableSkins[#skin._availableSkins + 1] = {_id = skinId, _expire = expire}
        self._skins[infoId] = skin
    end
    return true
end

function _M:getRecommendTroops()
    return self._recommendTroops
end

function _M:getSystemRecommendTroops()
    return self._systemRecommendTroops
end

function _M:initSystemRecommendTroops()
    local characters = {2, 3, 4, 5, 10, 12, 13}
    local startId = 15000
    local data = Data._troopInfo
    for _, id in ipairs(characters) do
        local troopId = startId + id
        local info = data[troopId]
        if info then
            local troop = {}
            local troopLevel = {}
            local name = Str(info._nameSid)
            local avatar = info._picId
            local cardIds = info._infoId
            for i, cardId in ipairs(cardIds) do
                table.insert(troop, {info_id = cardId, num = info._num[i]})
                table.insert(troopLevel, {info_id = cardId, level = info._level[i]})
            end
            local player = {_name = name, _avatar = avatar, _level = 30, _troopCards = troop, _troopLevels = troopLevel, _troopSkins = {}, _fortressHp = info._fortressHp}
            table.insert(self._systemRecommendTroops, {_player = player, _isAttacker = true})
        end
    end
end


----------------------------------- flag ----------------------------------------------------------------------------------

return _M
