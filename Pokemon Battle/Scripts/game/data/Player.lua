local PlayerCard = require "PlayerCard"
local PlayerCity = require "PlayerCity"
local PlayerWorld = require "PlayerWorld"
local PlayerBonus = require "PlayerBonus"
local PlayerAchieve = require "PlayerAchieve"
local PlayerMarket = require "PlayerMarket"
local PlayerMessage = require "PlayerMessage"
local PlayerRank = require "PlayerRank"
local PlayerMail = require "PlayerMail"
local PlayerLog = require "PlayerLog"
local PlayerExpedition = require "PlayerExpedition"
local PlayerUnion = require "PlayerUnion"
local UnderAttack = require "UnderAttack"
local PropBag = require "PropBag"
local PlayerRoom = require "PlayerRoom"

local PlayerFindClash = require "PlayerFindClash"
local PlayerFindLadder = require "PlayerFindLadder"
local PlayerFindUnionBattle = require "PlayerFindUnionBattle"
local PlayerFindDark = require "PlayerFindDark"

require "PlayerActivity"
require("json")

local _M = class("Player")

function _M:ctor()
    self._playerCard = PlayerCard.new()
    self._playerCity = PlayerCity.new()
    self._playerWorld = PlayerWorld.new()
    self._playerBonus = PlayerBonus.new()
    self._playerAchieve = PlayerAchieve.new()
    self._playerMarket = PlayerMarket.new()
    self._playerMessage = PlayerMessage.new()    
    self._playerMail = PlayerMail.new()
    self._playerLog = PlayerLog.new()
    self._playerRank = PlayerRank.new()
    self._playerExpedition = PlayerExpedition.new()
    self._playerUnion = PlayerUnion.new()
    self._playerActivity = PlayerActivity.new()
    self._underAttack = UnderAttack.new()
    self._propBag = PropBag.new()
    self._playerRoom = PlayerRoom.new()

    self._playerFindClash = PlayerFindClash.new()
    self._playerFindLadder = PlayerFindLadder.new()
    self._playerFindUnionBattle = PlayerFindUnionBattle.new()
    self._playerFindDark = PlayerFindDark.new()
end

function _M:clear()
    self:stopPlayerScheduler()
    
    self._playerCard:clear()
    self._playerCity:clear()
    self._playerWorld:clear()
    self._playerBonus:clear()
    self._playerAchieve:clear()
    self._playerMarket:clear()
    self._playerMessage:clear()    
    self._playerMail:clear()
    self._playerLog:clear()   
    self._playerRank:clear()
    self._playerExpedition:clear()
    self._playerUnion:clear()
    self._playerActivity:clear()
    self._underAttack:clear()
    self._propBag:clear()
    self._playerRoom:clear()

    self._playerFindClash:clear()
    
    self._id = nil
    self._guideID = nil

    self._dailyActive = nil

    self._inviteCode = nil
    self._invitedCode = nil

    self._hasEnterCity = nil

    require("User").Users = {}
    require("Union").Unions = {}
    require("Mail").Mails = {}

    require("MarqueeManager").release()
end

function _M:init(resp)
    self._id = resp.user_info.id
    lc.log('@@@@@@@@ PLAYER ID: %d', self._id)

    self._sid = ClientData.getUserStringId(ClientData._userRegion._id, self._id)

    ClientData.initConfig(self._id)
    
    self._unionId = resp.user_info.union_id
    self._unionJob = resp.user_info.union_title
    self._roomId = resp.user_info.room_id or 0
    self._roomJob = resp.user_info.room_title or Data.RoomJob.rookie
    if self:hasUnion() then
        lc.log('@@@@@@@@ UNION ID: %d', self._unionId)
    end

    self._name = resp.user_info.name
    self._exp = resp.user_info.exp
    self._level = resp.user_info.level
    self._vip = resp.user_info.vip
    self._vipExp = resp.user_info.vip_exp
    self._trophy = resp.user_info.trophy
    self._avatar = resp.user_info.avatar
    self._avatarImage = resp.user_info.avatar_image
    self._loginTime = resp.user_info.last_login / 1000
    self._regTime = resp.user_info.reg_date / 1000
    --self._loginTime = os.time{year = 2015, month = 12, day = 5, hour = 13, min = 59, sec = 50}
    self._timeOffset = resp.time_offset / 1000

    self._privilege = resp.user_info.privilege

    self._canBind = resp.can_bind

    self._functionSwitch = 0
    if resp:HasField("function_switch") then
        self._functionSwitch = resp.function_switch
    end

    if resp.user_info:HasField("code") then
        self._invitedCode = resp.user_info.code
    end

    self._inviteIngot = resp.user_count.invite_charge
    self._inviteCount = resp.user_count.invite_count

    self._lastLogin = lc.readConfig(ClientData.ConfigKey.last_login, self._loginTime)
    lc.writeConfig(ClientData.ConfigKey.last_login, math.floor(self._loginTime))
    
    _, self._dayOfMonth = ClientData.getServerDate()
    
    self._gold = resp.user_info.gold
    self._grain = resp.user_info.grain
    self._ingot = resp.user_info.ingot
    self._achievePoint = resp.user_info.achievement

    self._highestPower = resp.power or 0

    
    
    self._guideID = ClientData.DEBUG_GUIDE_ID or resp.user_info.guide
    self._guideDifficultyID = resp.user_info.guide1
    self._guideRecruiteID = resp.user_info.guide2
    if self._guideDifficultyID == 0 then self._guideDifficultyID = 10001 end
    if self._guideRecruiteID == 0 then self._guideRecruiteID = 20001 end
    lc.log('@@@@@@@@ GUIDE ID: %d %d %d', self._guideID, self._guideDifficultyID, self._guideRecruiteID)
        
    self._activityPoints = 0

    self._pvpWinTotal = resp.user_battle.total_pvp_win
    self._pvpTotal = self._pvpWinTotal + resp.user_battle.total_pvp_lose
    self._pvpWinDaily = resp.user_battle.daily_pvp_win
    self._pvpDaily = self._pvpWinDaily + resp.user_battle.daily_pvp_lose

    self._dailyClashWin = resp.user_battle.daily_ladder_win
    self._ladderContWin = resp.user_battle.ladder_cont_win
    self._ladderContLose = resp.user_battle.ladder_cont_lose

    self._lotteryNextFree = {}
    for i = 1, #resp.user_lottery.next_free do
        self._lotteryNextFree[i] = resp.user_lottery.next_free[i] / 1000
    end

    self._legendBoxOpenTimes = resp.user_lottery.nchest
    self._legendBoxOpenRemainTimes = resp.user_lottery.nchest_ex

    self._bloodJade = resp.user_lottery.point
    
    self._dailyBuyOrangeHeroFBox = resp.user_count.buy_chest1
    self._dailyBuyPurpleHeroFBox = resp.user_count.buy_chest2
    self._dailyBuyOrangeHorseFBox = resp.user_count.buy_chest3
    self._dailyBuyPurpleHorseFBox = resp.user_count.buy_chest4
    self._dailyBuyHeroExp = resp.user_count.buy_hero_exp
    self._dailyBuyEquipExp = resp.user_count.buy_equip_exp
    self._dailyBuyHorseExp = resp.user_count.buy_horse_exp
    self._dailyBuyBookExp = resp.user_count.buy_book_exp
    self._dailyBuyStone = resp.user_count.buy_stone
    self._dailyBuyRemedy = resp.user_count.buy_remedy      

    self._dailyBuyGold = resp.user_count.buy_gold
    self._dailyBuyGrain = resp.user_count.buy_grain
    self._dailyBuyRefresh = resp.user_count.buy_refresh
    self._dailyBuyRefreshPvp = resp.user_count.buy_refresh_pvp
    self._dailyBuyRefreshUnion = resp.user_count.buy_refresh_union
    self._dailyBuyRefreshLadder = resp.user_count.buy_refresh_ladder
    self._dailyBuyCopyExpedition = resp.user_count.buy_expedition

    self._dailyBuyCopyElite = resp.user_count.buy_elite
    self._dailyBuyCopyBoss = resp.user_count.buy_rob_exp
    self._dailyBuyCopyCommander = resp.user_count.buy_commander

    self._dailyCopyBoss = resp.user_count.rob_gold
    self._dailyDonate = band(resp.user_count.donate, 128) / 128
    self._dailyIngotDonate = band(resp.user_count.donate, 127)
    self._dailyWorship = resp.user_count.worship
    
    self._dailyChallengeElite = resp.user_count.challenge_elite
    self._dailyChallengeCommander = resp.user_count.challenge_commander

    self._dailyTrophy = resp.user_count.trophy
    self._dailyExpedition = resp.user_count.expedition
    self._dailySendMail = resp.user_count.send_mail

    self._dailyClaimedGold = resp.user_count.gold
    self._dailyNextSpawn = resp.user_count.next_spawn / 1000
    if self._dailyClaimedGold == 0 then self._dailyClaimedGold = nil end

    self._dailyCollectedGold = resp.user_count.collect_gold
    print ('@@@@@@@@ COLLECTED GOLD:', self._dailyCollectedGold)

    self._dailyWorldBoss = resp.user_count.atk_boss
    self._dailyBuyWorldBoss = resp.user_count.buy_atk_boss
    self._worldBossScore = resp.user_battle.boss_score

    self._dailyResetLadder = resp.user_count.reset_ladder

    self._nextCityHelp = resp.user_count.next_sos / 1000
    
    self._monthlyRecheck = resp.user_count.re_check
    self._serverOpenTimestamp = resp.open_time/ 1000  --os.time{year = 2015, month = 12, day = 1, hour = 4, min = 0, sec = 0}
    
    self._unionFundFlag = resp.user_count.welfare

    self._changeNameCount = resp.user_count.edit_name
    self._nextShareBattle = resp.user_count.next_share / 1000  
    self._nextChat = resp.user_count.next_chat / 1000

    self._nextCopyPvp = resp.user_count.next_find / 1000
    self._unlockCopyPvpTimes = resp.user_count.buy_refresh_find
    self._dailyCopyPvpTimes = resp.user_count.atk_player
    
    self._grace = resp.user_count.grace

    if resp.user_count.month_card / 1000 > self._loginTime then
        self._monthCardDay1 = math.ceil((resp.user_count.month_card / 1000 - self._loginTime) / Data.DAY_SECONDS)
    else    
        self._monthCardDay1 = 0
    end

    if resp.user_count.month_card_ex / 1000 > self._loginTime then
        self._monthCardDay2 = math.ceil((resp.user_count.month_card_ex / 1000 - self._loginTime) / Data.DAY_SECONDS)
    else    
        self._monthCardDay2 = 0
    end

    self._firstIngotRecharge = resp.user_count.charge
    self._ingotDailyRecharge = resp.user_count.daily_charge
        
    self._systemAnnouncement = {}
    if #resp.announcement > 0 then
        local jsonNode = json.decode(resp.announcement)
        for _, node in ipairs(jsonNode) do
            table.insert(self._systemAnnouncement, {_title = node.title, _content = node.content, _timestamp = resp.time_of_ann / 1000})
        end
    end

    for _, announce in ipairs(self._systemAnnouncement) do
        announce._content = string.gsub(announce._content, "\\n", "\n")
    end    

    -- character
    self._characters = {}
    for id, info in pairs(Data._characterInfo) do
        local character = {_id = id, _level = 0, _exp = 0, _avatar = id * 100 + 1}
        self._characters[id] = character
    end
    for i = 1, #resp.attach.characters do
        local pbCharacter = resp.attach.characters[i]
        local character = {_id = pbCharacter.id, _level = pbCharacter.level, _exp = pbCharacter.exp, _avatar = pbCharacter.avatar}
        print ('@@@@@@@@ CHARACTER:', character._id, character._avatar, character._level, character._exp)
        self._characters[character._id] = character
    end
    
    -- init battle data
    self._isDefending = false
    self._baseHp = 500
    self._status = 0
    
    self._playerBonus:init(resp.attach.bonus)
    self._playerActivity:init(resp.attach.activity)
    self._playerFindLadder:init(resp.attach.ladder)
    self._playerFindDark:init(resp.attach.dark)

    self._playerCard:init(resp.card)
    self._playerCity:init(resp.city)
    self._playerWorld:init(resp.world)
    
    self._propBag:init(resp.attach.prop)
    self._troopRemarks = {}
    for _, remark in ipairs(resp.attach.prop.marks) do
        table.insert(self._troopRemarks, remark)
    end

    self._playerMarket:init(resp.attach.shop)
    
    self._playerAchieve:initMainTask()
    self._playerAchieve:initActivityTask()

    if resp:HasField("union") then
        self._playerUnion:initBase(resp.union)
    end

    

    -- avatar and card back
    self._avatarFrameId = resp.user_info.avatar_frame
    if self._avatarFrameId == 0 then
        _, self._avatarFrameId = self._propBag:validPropId(Data.PropsId.avatar_frame)
    end

    self._cardBackId = resp.user_info.card_back
    if self._cardBackId == 0 then
        self._cardBackId = Data.PropsId.card_back
    end

    self._crown = nil
    if resp.user_info:HasField('crown') then
        self._crown ={_infoId = resp.user_info.crown.info_id, _num = resp.user_info.crown.num}
    end

    -- copy pass times
    self._copyPassTimes, self._copyScore = {}, {}
    for k ,v in pairs(Data._copyInfo) do
        self._copyPassTimes[k] = 0
        self._copyScore[k] = 0
    end

    for _, copy in ipairs(resp.attach.copy.copies) do
        self._copyPassTimes[copy.id] = copy.value
        self._copyScore[copy.id] = copy.score
        print ('@@@@@@@@ COPY: ', copy.id, copy.value, copy.score)
    end

    -- chat ban list
    self._chatBanList = {}
    for _, userId in ipairs(resp.ban_chat) do
        self._chatBanList[userId] = true
    end

    

    self._curTroopIndex = lc.readConfig(ClientData.ConfigKey.cur_troop, 1)
    if self._curTroopIndex < 1 or self._curTroopIndex > self:getUnlockTroopNumber() then
        self._curTroopIndex = 1
        lc.writeConfig(ClientData.ConfigKey.cur_troop, self._curTroopIndex)
    end

    -- read configs
    if lc.readConfig(ClientData.ConfigKey.lock_level_city) == nil then
        lc.writeConfig(ClientData.ConfigKey.lock_level_city, self._level)
    end
    if lc.readConfig(ClientData.ConfigKey.lock_level_split) == nil then
        lc.writeConfig(ClientData.ConfigKey.lock_level_split, self._level)
    end
    if lc.readConfig(ClientData.ConfigKey.lock_level_equip) == nil then
        lc.writeConfig(ClientData.ConfigKey.lock_level_equip, self._level)
    end
    if lc.readConfig(ClientData.ConfigKey.lock_level_herocenter) == nil then
        lc.writeConfig(ClientData.ConfigKey.lock_level_herocenter, self._level) 
    end
    if lc.readConfig(ClientData.ConfigKey.lock_level_battle) == nil then
        lc.writeConfig(ClientData.ConfigKey.lock_level_battle, self._level) 
    end
    if lc.readConfig(ClientData.ConfigKey.lock_level_vip) == nil then
        lc.writeConfig(ClientData.ConfigKey.lock_level_vip, self._level)
    end    

    local channelName = lc.App:getChannelName()
    if channelName == "APPSTORE" or channelName == "FACEBOOK" then
        local subChannelName = ClientData.getSubChannelName()
        local userData = {subChannel = subChannelName, day = P:getDayDiff()}
        ClientData.sendUserEvent(userData)
        ClientData.submitRoleData('')
    elseif channelName == 'UC' then 
        ClientData.submitRoleData('loginGameRole')
    elseif channelName == 'ASDK' then 
        if #self._name ~= 0 and self._guideID >= 103 then ClientData.submitRoleData('0') end
        local subChannelName = ClientData.getSubChannelName()
        local userData = {subChannel = subChannelName, day = P:getDayDiff()}
        ClientData.sendUserEvent(userData)
    else 
        ClientData.submitRoleData('')
    end

    ClientData._worldDisplay = Data.WorldDisplay.normal
    ClientData._worldDisplayCity = Data.WorldDisplay.normal
    
    self._playerSchedulerID = lc.Scheduler:scheduleScriptFunc(function(dt) self:scheduler(dt) end, 1, false)
    
    --GuideManager.checkStartNewGuideByLevel()
end

function _M:hasUnion()
    return self._unionId and self._unionId > 0
end

function _M:scheduler(dt)
    -- Collect gold from world cities
    --[[
    if self._level >= Data._globalInfo._unlockCollectGold then
        if self._dailyClaimedGold == nil then
            local currentTime = ClientData.getCurrentTime()
            if currentTime >= self._dailyNextSpawn then            
                self._dailyClaimedGold = 0
                self._dailyNextSpawn = 0
                ClientData.sendGetDailyGold()
            end
        end
    end
    ]]

    self._playerRank:scheduler(dt)
    --self._playerMarket:scheduler(dt)
end

function _M:stopPlayerScheduler()
    if self._playerSchedulerID ~= nil then
        lc.Scheduler:unscheduleScriptEntry(self._playerSchedulerID)
        self._playerSchedulerID = nil
    end
end

function _M:setCurrentTroopIndex(index, isForce)
    if self._curTroopIndex == index and (not isForce) then return false end
    if index < 1 or index > self:getUnlockTroopNumber() then
        return false
    end
    self._curTroopIndex = index
    lc.writeConfig(ClientData.ConfigKey.cur_troop, index)
    
    return true
end

function _M:hasPrivilege(privilege)
    return band(self._privilege, privilege) ~= 0
end

function _M:isUserAdmin()
    return self._privilege == bor(Data.Privilege.chat_ban, Data.Privilege.mail_free)
end

function _M:setUnionFundValid(isValid)
    if isValid then
        self._unionFundFlag = bor(self._unionFundFlag, 0x2)
    else
        self._unionFundFlag = band(self._unionFundFlag, bnot(0x2))
    end
end

function _M:isUnionFundValid()
    return band(self._unionFundFlag, 0x2) ~= 0
end

function _M:givenUnionFund()
    self._unionFundFlag = bor(self._unionFundFlag, 0x1, 0x2)
end

function _M:getDayDiff()
    local dayReg = math.floor((P._regTime + 28800) / Data.DAY_SECONDS)
    local dayCur = math.floor((P._loginTime + 28800) / Data.DAY_SECONDS)
    return dayCur - dayReg
end

function _M:getItemCount(typeOrId)
    local cardType = Data.getType(typeOrId)
    if cardType == Data.CardType.res then
        if typeOrId == Data.ResType.gold then
            return self._gold

        elseif typeOrId == Data.ResType.grain then
            return self._grain

        elseif typeOrId == Data.ResType.ingot then
            return self._ingot

        elseif typeOrId == Data.ResType.clash_trophy then
            return P._playerFindClash._trophy

        elseif typeOrId == Data.ResType.ladder_trophy then
            return self._playerFindClash._ladderTrophy

        elseif typeOrId == Data.ResType.exp then
            return self._exp

        elseif typeOrId == Data.ResType.ghost then
            return self._playerActivity._ghost or 0
    
        elseif typeOrId == Data.ResType.blood_jade then
            return self._bloodJade

        elseif typeOrId == Data.ResType.union_battle_trophy then
            return self._playerUnion._battleTrophy

        elseif typeOrId == Data.ResType.dark_trophy then
            return self._playerFindDark._trophy

        elseif self:hasUnion() then
            local union = self._playerUnion:getMyUnion()
            if typeOrId == Data.ResType.union_act then
                return union._act

            elseif typeOrId == Data.ResType.union_gold then
                return union._gold

            elseif typeOrId == Data.ResType.union_wood then
                return union._wood

            end
        end

    elseif cardType == Data.CardType.props then
        if typeOrId >= Data.PropsId.special then
            if typeOrId == Data.PropsId.avatar_frame or typeOrId == Data.PropsId.card_back then
                return 1
            end
        end
        
        --TODO--
        --return self._propBag._props[typeOrId]._num
        return self._propBag._props[typeOrId] and self._propBag._props[typeOrId]._num or 0

    elseif cardType == Data.CardType.common_fragment then
        return self._playerCard:getCommonFragmentByInfoId(typeOrId)._fragmentNum

    end

    return -1
end

function _M:getLotteryFlag()
    local number = 0
    for i = 1, #self._lotteryNextFree do
        if self._lotteryNextFree[i] ~= 0 and self._lotteryNextFree[i] - ClientData.getCurrentTime() <= 0 then
            number = number + 1
        end
    end
    return number
end

function _M:getExchangeGold(grade)
    if grade == 9999 then
        return 520, 9999
    elseif grade == 4000 then
        return 280, 4000
    elseif grade == 10000 then
        return 601, 10000
    elseif grade == 3000 then
        return 3000, 3000, Data.ResType.gold
    elseif grade == 6000 then
        return 300, 6000
    elseif grade == 6800 then
        return 680, 6800
    else
        return Data._globalInfo._goldIngot[grade], Data._globalInfo._goldValue[grade]
    end
end

function _M:getExchangeGrain()
    local index = self._dailyBuyGrain + 1
    if index > #Data._globalInfo._grainIngot then
        index = #Data._globalInfo._grainIngot
    end
    
    return Data._globalInfo._grainIngot[index], Data._globalInfo._grainValue[index]
end

function _M:getExchangeDust(dustType, grade)
    if dustType == Data.PropsId.dust_monster then
        return Data._globalInfo._dustMonsterIngot[grade], Data._globalInfo._dustMonsterValue[grade]
    elseif dustType == Data.PropsId.dust_magic then
        return Data._globalInfo._dustMagicIngot[grade], Data._globalInfo._dustMagicValue[grade]
    elseif dustType == Data.PropsId.dust_rare then
        return Data._globalInfo._dustRareIngot[grade], Data._globalInfo._dustRareValue[grade]
    elseif dustType == Data.PropsId.dimension_bottle then
        return Data._globalInfo._dimensionBottleIngot[grade], Data._globalInfo._dimensionBottleValue[grade]
    elseif dustType == Data.PropsId.skin_crystal then
        return Data._globalInfo._phantomCrystalIngot[grade], Data._globalInfo._phantomCrystalValue[grade]
    elseif dustType == Data.PropsId.times_package_ticket then
        return Data._globalInfo._dimensionLotteryTokenIngot[grade], Data._globalInfo._dimensionLotteryTokenValue[grade]
    end
end

function _M:buyGold(grade)
    if self:getBuyGoldTimes() <= 0 then
        return Data.ErrorType.need_more_daily_buy_gold
    end
    
    local ingot, gold, resType = self:getExchangeGold(grade)
    resType = resType or Data.ResType.ingot
    if resType == Data.ResType.ingot then
        if not self:hasResource(resType, ingot) then
            return Data.ErrorType.need_more_ingot
        end
    elseif resType == Data.ResType.gold then
        if not self:hasResource(resType, ingot) then
            return Data.ErrorType.need_more_gold
        end
    end
    self._dailyBuyGold = self._dailyBuyGold + 1
    self:changeResource(Data.ResType.gold, gold)
    self:changeResource(resType, -ingot)
    
    return Data.ErrorType.ok
end

function _M:buyGrain()
    if self:getBuyGrainTimes() <= 0 then
        return Data.ErrorType.need_more_daily_buy_grain
    end
    
    local ingot, grain = self:getExchangeGrain()
    if not self:hasResource(Data.ResType.ingot, ingot) then
        return Data.ErrorType.need_more_ingot
    end
    self._dailyBuyGrain = self._dailyBuyGrain + 1
    self:changeResource(Data.ResType.grain, grain)
    self:changeResource(Data.ResType.ingot, -ingot)
    
    return Data.ErrorType.ok
end

function _M:buyDust(dustType, grade)
    local ingot, dust = self:getExchangeDust(dustType, grade)
    if not self:hasResource(Data.ResType.ingot, ingot) then
        return Data.ErrorType.need_more_ingot
    end
    --self._dailyBuyGold = self._dailyBuyGold + 1
    self._propBag:changeProps(dustType, dust)
    self:changeResource(Data.ResType.ingot, -ingot)
    
    return Data.ErrorType.ok
end

function _M:hasResource(resType, val)
    if resType == Data.ResType.gold then
        return self._gold >= val 
    elseif resType == Data.ResType.grain then
        return self._grain >= val
    elseif resType == Data.ResType.ingot then
        return self._ingot >= val
    elseif resType == Data.ResType.ghost then
        if self._playerActivity._ghost then
            return self._playerActivity._ghost >= val
        else
            return false
        end
    elseif resType == Data.ResType.blood_jade then
        return self._bloodJade >= val
    end
    return false
end

function _M:tryChangeResource(resType, delta)
    if resType == Data.ResType.gold then
        local gold = self._gold + delta
        if gold >= 0 then 
            local deltaRes = gold - self._gold
            return true, deltaRes 
        end 
    elseif resType == Data.ResType.grain then
        local grain = self._grain + delta
        if grain >= 0 then
            if grain > self:getGrainCapacity() then
                grain = self:getGrainCapacity()
            end
            local deltaRes = grain - self._grain
            return true, deltaRes 
        end
    elseif resType == Data.ResType.ingot then
        local ingot = self._ingot + delta
        if ingot >= 0 then 
            local deltaRes = ingot - self._ingot
            return true, deltaRes 
        end
    end
    return false, 0
end

function _M:changeResource(resType, delta)
    if Data.isUnionRes(resType) then
        return self._playerUnion:changeResource(resType, delta)
    end

    if resType == Data.ResType.gold then
        local gold = self._gold + delta
        if gold >= 0 then 
            local deltaRes = gold - self._gold
            self._gold = gold
            
            self:sendGoldDirty()
            return true, deltaRes 
        end 
    elseif resType == Data.ResType.grain then
        local grain = self._grain + delta
        if grain >= 0 then    
            local deltaRes = grain - self._grain
            self._grain = grain
            
            self:sendGrainDirty()
            return true, deltaRes 
        end
    elseif resType == Data.ResType.ingot then
        local ingot = self._ingot + delta
        if ingot >= 0 then 
            local deltaRes = ingot - self._ingot
            self._ingot = ingot

            if delta < 0 and self._playerActivity._actConsume then
                self._playerActivity._consumeIngot = self._playerActivity._consumeIngot - delta
            end
            
            self:sendIngotDirty()
            return true, deltaRes 
        end
    elseif resType == Data.ResType.ghost then
        if self._playerActivity._ghost then
            local ghost = self._playerActivity._ghost + delta
            if ghost >= 0 then
                self._playerActivity._ghost = ghost
                self:sendGhostDirty()
                return true, delta 
            end
        end
    elseif resType == Data.ResType.blood_jade then        
        local jade = self._bloodJade + delta
        if jade >= 0 then
            self._bloodJade = jade
            self:sendBloodJadeDirty()
            return true, delta
        end
    elseif resType == Data.ResType.achieve_point then        
        local point = self._achievePoint + delta
        if point >= 0 then
            self._achievePoint = point
            self:sendAchievePointDirty()
            return true, delta
        end

    elseif resType == Data.ResType.union_personal_power then
        local point = self._dailyActive + delta
        if point >= 0 then
            self._dailyActive = point
            self:sendDailyActiveDirty()
        end

    elseif resType == Data.ResType.union_battle_trophy then
        local trophy = self._playerUnion._battleTrophy + delta
        trophy = math.max(trophy, 500)
        self._playerUnion._battleTrophy = trophy
        self:sendUnionBattleTrophyDirty()

    elseif resType == Data.ResType.dark_trophy then
        local trophy = math.max(self._playerFindDark._trophy, 500) + delta
        trophy = math.max(trophy, 500)
        self._playerFindDark._trophy = trophy
        self:sendDarkTrophyDirty()

    elseif resType == Data.ResType.exp or resType == Data.ResType.character_exp then
        self:changeExp(delta)
    end
    
    return false, 0
end

function _M:addResourcesData(data)
    local cardTypes = {}
    for _, res in ipairs(data) do
        local cardType = self:addResource(res._infoId, res._level, res._count, res._isFragment, true)
        if cardType then cardTypes[cardType] = true end
    end

    for type in pairs(cardTypes) do
        self._playerCard:sendCardListDirty(type)
    end           
end

function _M:addResources(infoIds, levels, counts, isFragments)
    local cardTypes = {}
    local count = math.min(#infoIds, #counts)
    for i = 1, count do
        local cardType = self:addResource(infoIds[i], levels[i], counts[i], isFragments[i], true)
        if cardType then cardTypes[cardType] = true end
    end
    
    for type in pairs(cardTypes) do
        self._playerCard:sendCardListDirty(type)
    end           
end

function _M:addResource(infoId, level, count, isFragment, skipEvent)
    if Data.isUnionRes(infoId) then
        self._playerUnion:changeResource(infoId, count)
    else
        if infoId == Data.ResType.gold or infoId == Data.ResType.grain or infoId == Data.ResType.ingot or infoId == Data.ResType.ghost or infoId == Data.ResType.blood_jade or infoId == Data.ResType.achieve_point or infoId == Data.ResType.union_personal_power or infoId == Data.ResType.exp or infoId == Data.ResType.character_exp or infoId == Data.ResType.dark_trophy then
            self:changeResource(infoId, count)
        else
            local type = Data.getType(infoId)
            if type == Data.CardType.props then
                self._propBag:changeProps(infoId, count)
            elseif type == Data.CardType.monster_skin then
                self._playerCard:buySkinId(infoId, count)
            else -- card
                if self._playerCard:addCard(infoId, count) then 
                    if not skipEvent then
                        self._playerCard:sendCardListDirty(type)
                    end
                    
                    return type
                end
            end        
        end 
    end  
end

function _M:getLevelupGrain(preLevel, curLevel)
    local grain = 0
    for i = preLevel + 1, curLevel do
        grain = grain + Data._globalInfo._playerLevelupGrain[math.min(i, #Data._globalInfo._playerLevelupGrain)]
    end
    return grain
end

function _M:changeLevel(delta, timestamp)
    local characterId = self:getCharacterId()
    local character = self._characters[characterId]
    local level = character._level + delta
    if level > 0 then
        --self:changeResource(Data.ResType.grain, self:getLevelupGrain(character._level, level))

        character._level = level

        self:sendLevelDirty()
        
        --GuideManager.checkStartNewGuideByLevel()
        return true
    end
    
    return false
end

function _M:changeExp(delta, timestamp)
    local levelUp = 0
    local characterId = self:getCharacterId()
    local character = self._characters[characterId]
    character._exp = character._exp + delta
    local prevMaxCharacterLevel = self:getMaxCharacterLevel()
    
    local exp = self:getLevelupExp(character._level + levelUp)
    while character._level < 99 and exp > 0 and character._exp >= exp do
        character._exp = character._exp - exp
        levelUp = levelUp + 1

        exp = self:getLevelupExp(character._level + levelUp)
    end
    
    if levelUp > 0 then
        self:changeLevel(levelUp, timestamp)
    end
    self:sendExpDirty()

    local curMaxCharacterLevel = self:getMaxCharacterLevel()
    if curMaxCharacteLevel ~= prevMaxCharacterLevel then
        if lc.App:getChannelName() == 'ASDK' then
            ClientData.submitRoleData('2')
        end
    end
    
    return levelUp
end

function _M:changeVIP(delta)
    local vip = self._vip + delta
    if delta > 0 then
        --[[
        if self._vip < Data._globalInfo._vipSweep and vip >= Data._globalInfo._vipSweep then
            local eventCustom = cc.EventCustom:new(Data.Event.push_notice)
            eventCustom._title = Str(STR.UNLOCK)
            eventCustom._content = string.format(Str(STR.SWEEP_TIMES), Data._globalInfo._dailySweepCount)..Str(STR.UNLOCKED)
            lc.Dispatcher:dispatchEvent(eventCustom) 
        end
        ]]

        self._vip = vip

        self:sendVIPDirty()
        return true
    end
    
    return false
end

function _M:changeVIPExp(delta)
    local vipUp = 0
    self._vipExp = self._vipExp + delta
    
    local exp = self:getVIPupExp(self._vip + vipUp)
    while self._vip < #Data._globalInfo._vipIngot - 1 and exp > 0 and self._vipExp >= exp do
        self._vipExp = self._vipExp - exp
        vipUp = vipUp + 1
        
        exp = self:getVIPupExp(self._vip + vipUp)
    end
    
    if vipUp > 0 then
        self:changeVIP(vipUp)
    end
    self:sendVIPExpDirty()
    
    return vipUp
end

function _M:changeTrophy(delta)
    local trophy = self._trophy + delta
    if trophy < 0 then trophy = 0 end

    self._trophy = trophy
    self:sendTrophyDirty()
end

function _M:changeName(newName)
    if self._name == newName or newName == "" then return false end
    
    self._name = newName
    
    self:sendNameDirty()
    return true
end

function _M:changeIcon(iconId)
    if self._avatar == iconId then return false end
    self._avatar = iconId
    self._characters[math.floor(iconId / 100)]._avatar = iconId

    self:sendIconDirty()
    return true
end

-- mark
function _M:changeAvatarImage(id)
    if self._avatarImage == id then return false end
    self._avatarImage = id
    self._characters[math.floor(id / 100)]._avatarImage = id

    self:sendAvatarImageDirty()
    return true
end

function _M:changeAvatarFrame(id)
    if self._avatarFrameId == id then return false end    
    self._avatarFrameId = id
    
    self:sendAvatarFrameDirty()
    return true
end

function _M:changeCharacter(characterId, isForce)
    if not isForce and self:getCharacterId()== characterId then return false end

    self:changeIcon(self._characters[characterId]._avatar)
    self:sendCharacterDirty()
    return true
end

function _M:getBattleCost(times, isLose, levelId)
    local cost
    if levelId and levelId > 0 then
        local difficulty = math.floor(levelId  / 10000)
        cost = isLose and Data._globalInfo._chapterLoseCost[difficulty] or Data._globalInfo._chapterCost[difficulty]
    else
        cost = isLose and Data._globalInfo._battleLoseCost or Data._globalInfo._battleCost
    end

    if times then
        cost = cost * times
    end
    
    return cost
end

function _M:checkBattleCost(times, cityChapterId)
    local cost = self:getBattleCost(times, nil, cityChapterId)
    return self:hasResource(Data.ResType.grain, cost)
end

function _M:getFindCost()
    local index = math.floor(self._level / 5) + 1
    if index > #Data._globalInfo._findCost then index = #Data._globalInfo._findCost end
    
    return Data._globalInfo._findCost[index]
end

function _M:checkFindCost()
    local cost = self:getFindCost() 
       
    return self:hasResource(Data.ResType.gold, cost)
end

function _M:sortByInfoId(src, isReverse)
    local compare = function(a, b)
        if isReverse then
            if a._infoId ~= nil then
                return a._infoId > b._infoId
            else
                return a._id > b._id
            end
        else
            if a._infoId ~= nil then
                return a._infoId < b._infoId
            else
                return a._id < b._id
            end
        end
    end
    table.sort(src, compare)
    
    return src
end

function _M:sortByQuality(src, isReverse)
    local compare = function(a, b)     
        local infoA = Data.getInfo(a)
        local infoB = Data.getInfo(b)
        if infoA == nil or infoB == nil then
            print ('[Unrecognizable card]', a, b)
        end
        if infoA._quality == infoB._quality then
            return infoA._id > infoB._id
        else
            if isReverse then
                return infoA._quality > infoB._quality
            else
                return infoA._quality < infoB._quality
            end
        end
    end
    
    table.sort(src, compare)
    
    return src
end

function _M:sortCardsByATK(src, isReverse)
    local cards = src
    
    local compare = function(a, b)
        local infoA, infoB = Data.getInfo(a), Data.getInfo(b)
        local levelA, levelB = P._playerCard._levels[a], P._playerCard._levels[b]
        if isReverse then
            return infoA._atk[levelA] > infoB._atk[levelB]
        else
            return infoA._atk[levelA] < infoB._atk[levelB]
        end
    end
    
    table.sort(cards, compare)
    
    return cards    
end

function _M:sortCardsByHP(src, isReverse)
    local cards = src
    
    local compare = function(a, b)
        local infoA, infoB = Data.getInfo(a), Data.getInfo(b)
        if isReverse then
            return infoA._hp > infoB._hp
        else
            return infoA._hp < infoB._hp
        end
    end
    
    table.sort(cards, compare)
    
    return cards     
end

function _M:sortResultItems(items)
--    local factor = {8, 1, 2, 3, 4, -1, 6, 9, -1, 7}

    local compare = function(a, b)
        local infoIdA = P._playerCard:convert2CardId(a._infoId or a._data._infoId)
        local infoIdB = P._playerCard:convert2CardId(b._infoId or b._data._infoId)
        local infoA, typeA = Data.getInfo(infoIdA)
        local infoB, typeB = Data.getInfo(infoIdB)

        if typeA == Data.CardType.magic or typeA == Data.CardType.trap or typeA == Data.CardType.monster then
            typeA = typeA * 100
        elseif typeA == Data.CardType.props then
            typeA = typeA * 10
        end

        if typeB == Data.CardType.magic or typeB == Data.CardType.trap or typeB == Data.CardType.monster then
            typeB = typeB * 100
        elseif typeB == Data.CardType.props then
            typeB = typeB * 10
        end

        local qualityA, qualityB = infoA._quality or -1, infoB._quality or -1
        if typeA == typeB then
            if qualityA == qualityB then
                return infoA._id > infoB._id
            else
                return qualityA > qualityB
            end
        else
            return typeA > typeB
        end
    end
    
    table.sort(items, compare)
    return items
end

function _M:sortCardsByNum(src, isReverse)
    local cards = src
    
    local compare = function(a, b)
        local numA, numB = P._playerCard:getCardCount(a), P._playerCard:getCardCount(b)
        if numA == numB then
            if isReverse then
                return a > b
            else
                return a < b
            end
        end

        if isReverse then
            return numA > numB
        else
            return numA < numB
        end
    end
    
    table.sort(cards, compare)
    
    return cards   
end

function _M:filterByCategory(src, category)
    local filters = {}
    for _, val in ipairs(src) do
        local info = (type(val) == 'number') and Data.getInfo(val) or val
        if info._category == category then
            table.insert(filters, val)
        end
    end
    
    return filters
end

function _M:filterByQuality(src, quality)
    local filters = {}
    for _, val in ipairs(src) do
        local info = (type(val) == 'number') and Data.getInfo(val) or val
        if info._quality == quality then
            table.insert(filters, val)
        end
    end
    
    return filters
end

function _M:filterByNature(src, nature)        
    local filters = {}
    for _, val in ipairs(src) do
        local info = (type(val) == 'number') and Data.getInfo(val) or val
        if info._nature == nature then
            table.insert(filters, val)
        end
    end
    
    return filters
end

function _M:filterByLevel(src, star)        
    local filters = {}
    for _, val in ipairs(src) do
        local info = (type(val) == 'number') and Data.getInfo(val) or val
        if info._level == star - 1 then
            table.insert(filters, val)
        end
    end
    
    return filters
end

function _M:filterByType(src, type)
    local filters = {}
    for _, val in ipairs(src) do
        local cardType = (type(val) == 'number') and Data.getType(val) or Data.getType(val._infoId)
        if cardType == type then
            table.insert(filters, val)
        end
    end
    
    return filters
end

function _M:filterByTroop(src)
    local filters = {}
    for i = 1, #src do    
        if src[i]:isInTroop(0) then
            table.insert(filters, src[i])
        end
    end
    
    return filters
end

function _M:filterByUntroop(src)
    local filters = {}
    for i = 1, #src do    
        if not src[i]:isInTroop(0) then
            table.insert(filters, src[i])
        end
    end

    return filters
end

function _M:filterByCanUpgrade(src)
    local filters = {}
    for _, infoId in ipairs(src) do
        local ret = P._playerCard:upgradeCard(infoId, true)
        if ret == Data.ErrorType.ok then
            table.insert(filters, infoId)
        end
    end

    return filters
end

function _M:filterByCanCompose(src)
    local filters = {}
    for _, infoId in ipairs(src) do
        local ret = P._playerCard:composeCard(infoId, 1, true)
        if ret == Data.ErrorType.ok then
            table.insert(filters, infoId)
        end
    end

    return filters
end

function _M:filterBySearch(src, keyword)
    local filters = {}
    for _, val in ipairs(src) do
        local info = type(val) == 'number' and Data.getInfo(val) or val
    
        if keyword == "" then
            table.insert(filters, val)
        else
            local index = string.find(Str(info._nameSid), keyword)
            if index and index > 0 then
                table.insert(filters, val)
            elseif info._category ~= nil and keyword == Str(STR.CARD_CATEGORY_BEGIN + info._category) then
                table.insert(filters, val)
            elseif info._keyword ~= nil and keyword == Str(STR.CARD_KEYWORD_BEGIN + info._keyword) then
                table.insert(filters, val)
            else
                local type, isFound = Data.getType(info._id)
                if type == Data.CardType.monster then
                    for j = 1, #info._skillId do
                        if self:searchInSkill(info._skillId[j], keyword) then
                            table.insert(filters, val)
                            isFound = true
                            break
                        end
                    end
                end
            end
        end
    end
    
    return filters
end

function _M:searchInSkill(skillId, keyword)
    local info = Data._skillInfo[skillId]
    if info then
        local index = string.find(Str(info._nameSid), keyword)
        if index and index > 0 then
            return true
        else
            index = string.find(Str(info._descSid), keyword)
            if index and index > 0 then
                return true
            end
        end
    end

    return false
end

function _M:sendGoldDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.gold_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)   
end

function _M:sendGrainDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.grain_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)   
end

function _M:sendIngotDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.ingot_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)   
end

function _M:sendGhostDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.ghost_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:sendBloodJadeDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.blood_jade_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:sendAchievePointDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.achieve_point_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:sendUnionBattleTrophyDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.union_battle_trophy_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:sendDarkTrophyDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.dark_trophy_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:sendDailyActiveDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.daily_active_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:sendLevelDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.level_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)    
end

function _M:sendExpDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.exp_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:sendVIPDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.vip_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:sendVIPExpDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.vip_exp_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:sendMonthCardDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.month_card_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:sendFundDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.fund_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:sendPackageDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.package_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)
end

function _M:sendTrophyDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.trophy_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)    
end

function _M:sendNameDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.name_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)    
end

function _M:sendIconDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.icon_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)        
end

function _M:sendAvatarImageDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.avatar_image_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)        
end

function _M:sendAvatarFrameDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.avatar_frame_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)        
end

function _M:sendCharacterDirty()
    local eventCustom = cc.EventCustom:new(Data.Event.character_dirty)
    lc.Dispatcher:dispatchEvent(eventCustom)    
end

function _M:getUnlockSlotLevel(unlockSlotNum)
    local slotNum = unlockSlotNum + Data._globalInfo._unlockSlot[1]
    for i = 1, #Data._globalInfo._unlockSlot do
        if Data._globalInfo._unlockSlot[i] == slotNum then
            return i - 1
        end
    end    
end

function _M:getUnlockTroopNumber()
    return self:getCharacterUnlockCount()
end

function _M:getTitle(trophy)
    if trophy == nil then
        trophy = self._trophy
    end

    for i = 1, #Data._globalInfo._playerTitleTrophy do
        if i < #Data._globalInfo._playerTitleTrophy then
            if trophy >= Data._globalInfo._playerTitleTrophy[i] and trophy < Data._globalInfo._playerTitleTrophy[i + 1] then
                return i
            end
        else
            if trophy >= Data._globalInfo._playerTitleTrophy[i] then
                return i
            end
        end
    end
end

function _M:getMaxLevel()
    return #Data._globalInfo._playerLevelupExp
end

function _M:getLevelupExp(level)
    if level <= 0 then return 0 end
    
    if level >= #Data._globalInfo._playerLevelupExp then
        level = #Data._globalInfo._playerLevelupExp - 1
    end
    
    return Data._globalInfo._playerLevelupExp[level + 1] - Data._globalInfo._playerLevelupExp[level]
end

function _M:getVIPupExp(vip)
    if vip == nil then
        vip = self._vip
    end
    
    if vip < 0 then return 0 end
    if vip >= #Data._globalInfo._vipIngot - 1 then
        return 0
    end
    
    return Data._globalInfo._vipIngot[vip + 2] - Data._globalInfo._vipIngot[vip + 1]
end

function _M:getBattleExp(level)
    if level == nil then
        level = self._level
    end

    if level <= 0 then return 0 end

    if level > #Data._globalInfo._playerBattleExp then
        return Data._globalInfo._playerBattleExp[#Data._globalInfo._playerBattleExp]
    end

    return Data._globalInfo._playerBattleExp[level]
end

function _M:getHp(level)
    if level == nil then
        level = self._level
    end

    if level <= 0 then return 0 end
    
    if level > #Data._globalInfo._playerHp then
        return Data._globalInfo._playerHp[#Data._globalInfo._playerHp]
    end

    return Data._globalInfo._playerHp[level]
end

function _M:getReputation(level)
    if level == nil then
        level = self._level
    end

    if level <= 0 then return 0 end

    local reputation = lc.arrayAt(Data._globalInfo._playerReputation, level)
    return reputation + P._playerUnion:getTechVal(Data.UnionTechId.lord_reputation)    
end

function _M:getGrainCapacity(level)
    level = level or self._level
    if level > #Data._globalInfo._grainCapacity then
        level = #Data._globalInfo._grainCapacity
    end
    
    return Data._globalInfo._grainCapacity[level]
end

function _M:getBuyGoldTimes()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipBuyGold then
        index = #Data._globalInfo._vipBuyGold
    end
    
    return Data._globalInfo._vipBuyGold[index] - self._dailyBuyGold
end

function _M:getBuyGrainTimes()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipBuyGrain then
        index = #Data._globalInfo._vipBuyGrain
    end
    
    return Data._globalInfo._vipBuyGrain[index] - self._dailyBuyGrain
end

function _M:getBuyPacksNumber()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipBuyPacks then
        index = #Data._globalInfo._vipBuyPacks
    end
    
    return Data._globalInfo._vipBuyPacks[index] - self._dailyBuyPacks
end

function _M:getBuyHeroExpNumber()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipBuyHeroExp then
        index = #Data._globalInfo._vipBuyHeroExp
    end
    
    return Data._globalInfo._vipBuyHeroExp[index] - self._dailyBuyHeroExp
end

function _M:getBuyEquipExpNumber()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipBuyEquipExp then
        index = #Data._globalInfo._vipBuyEquipExp
    end
    
    return Data._globalInfo._vipBuyEquipExp[index] - self._dailyBuyEquipExp
end

function _M:getBuyHorseExpNumber()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipBuyHorseExp then
        index = #Data._globalInfo._vipBuyHorseExp
    end
    
    return Data._globalInfo._vipBuyHorseExp[index] - self._dailyBuyHorseExp
end

function _M:getBuyBookExpNumber()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipBuyBookExp then
        index = #Data._globalInfo._vipBuyBookExp
    end
    
    return Data._globalInfo._vipBuyBookExp[index] - self._dailyBuyBookExp
end

function _M:getBuyOrangeHeroFBoxNumber()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipBuyChest1 then
        index = #Data._globalInfo._vipBuyChest1
    end
    
    return Data._globalInfo._vipBuyChest1[index] - self._dailyBuyOrangeHeroFBox 
end

function _M:getBuyPurpleHeroFBoxNumber()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipBuyChest2 then
        index = #Data._globalInfo._vipBuyChest2
    end
    
    return Data._globalInfo._vipBuyChest2[index] - self._dailyBuyPurpleHeroFBox 
end

function _M:getBuyOrangeHorseFBoxNumber()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipBuyChest3 then
        index = #Data._globalInfo._vipBuyChest3
    end
    
    return Data._globalInfo._vipBuyChest3[index] - self._dailyBuyOrangeHorseFBox 
end

function _M:getBuyPurpleHorseFBoxNumber()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipBuyChest4 then
        index = #Data._globalInfo._vipBuyChest4
    end
    
    return Data._globalInfo._vipBuyChest4[index] - self._dailyBuyPurpleHorseFBox 
end

function _M:getBuyStoneNumber()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipBuyStone then
        index = #Data._globalInfo._vipBuyStone
    end
    
    return Data._globalInfo._vipBuyStone[index] - self._dailyBuyStone
end

function _M:getBuyRemedyNumber()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipBuyRemedy then
        index = #Data._globalInfo._vipBuyRemedy
    end
    
    return Data._globalInfo._vipBuyRemedy[index] - self._dailyBuyRemedy
end

function _M:getBuyRefreshTimes(type)
    if type == Data.MarketBuyType.random then
        return lc.arrayAt(Data._globalInfo._vipBuyRefresh, self._vip + 1)
    elseif type == Data.MarketBuyType.flag or type == Data.MarketBuyType.union or type == Data.MarketBuyType.dragon_flag then
        return lc.arrayAt(Data._globalInfo._vipBuyRefreshEx, self._vip + 1)
    end
    return 0
end

function _M:getRemainBuyRefreshTimes(type)
    if type == Data.MarketBuyType.random then
        return lc.arrayAt(Data._globalInfo._vipBuyRefresh, self._vip + 1) - self._dailyBuyRefresh
    elseif type == Data.MarketBuyType.flag then
        return lc.arrayAt(Data._globalInfo._vipBuyRefreshEx, self._vip + 1) - self._dailyBuyRefreshPvp
    elseif type == Data.MarketBuyType.union then
        return lc.arrayAt(Data._globalInfo._vipBuyRefreshEx, self._vip + 1) - self._dailyBuyRefreshUnion
    elseif type == Data.MarketBuyType.dragon_flag then
        return lc.arrayAt(Data._globalInfo._vipBuyRefreshEx, self._vip + 1) - self._dailyBuyRefreshLadder
    end
    return 0
end

function _M:getBuyRefreshCost(type, infoId)
    if type == Data.MarketBuyType.random then
        if infoId == Data.ResType.ingot then
            return lc.arrayAt(Data._globalInfo._buyRefreshCost, self._dailyBuyRefresh + 1)
        else
            return 1
        end

    elseif type == Data.MarketBuyType.flag then
        if infoId == Data.ResType.ingot then
            return lc.arrayAt(Data._globalInfo._buyRefreshPVPCost, self._dailyBuyRefreshPvp + 1)
        else
            return Data._globalInfo._buyRefreshPVPCostEx
        end

    elseif type == Data.MarketBuyType.union then
        if infoId == Data.ResType.ingot then
            return lc.arrayAt(Data._globalInfo._buyRefreshUnionCost, self._dailyBuyRefreshUnion + 1)
        else
            return  Data._globalInfo._buyRefreshUnionCostEx
        end

    elseif type == Data.MarketBuyType.dragon_flag then
        if infoId == Data.ResType.ingot then
            return lc.arrayAt(Data._globalInfo._buyRefreshLadderCost, self._dailyBuyRefreshLadder + 1)
        else
            return  Data._globalInfo._buyRefreshLadderCostEx
        end

    end

    return 0
end

function _M:getBuyShieldTimes()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipBuyShield then
        index = #Data._globalInfo._vipBuyShield
    end
    
    return Data._globalInfo._vipBuyShield[index] - self._dailyBuyShield
end

-- copy times

function _M:getCopyEliteTimes()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipEliteCount then
        index = #Data._globalInfo._vipEliteCount
    end

    return Data._globalInfo._vipEliteCount[index]
end

function _M:getCopyCommanderTimes()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipCommanderCount then
        index = #Data._globalInfo._vipCommanderCount
    end
    
    return Data._globalInfo._vipCommanderCount[index]
end

function _M:getCopyBossTimes()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipRobGoldCount then
        index = #Data._globalInfo._vipRobGoldCount
    end

    return Data._globalInfo._vipRobGoldCount[index]
end

function _M:getCopyExpeditionTimes()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipExpeditionCount then
        index = #Data._globalInfo._vipExpeditionCount
    end

    return Data._globalInfo._vipExpeditionCount[index]
end

-- copy buy times & ingot

function _M:getBuyCopyEliteRemainTimes()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipBuyElite then
        index = #Data._globalInfo._vipBuyElite
    end
    
    return Data._globalInfo._vipBuyElite[index] - self._dailyBuyCopyElite
end

function _M:getBuyCopyEliteIngot()
    return 18 + self._dailyBuyCopyElite * 10
end

function _M:getBuyCopyBossRemainTimes()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipBuyRobGold then
        index = #Data._globalInfo._vipBuyRobGold
    end
    
    return Data._globalInfo._vipBuyRobGold[index] - self._dailyBuyCopyBoss
end

function _M:getBuyCopyBossIngot()
    return 18 + self._dailyBuyCopyBoss * 10
end

function _M:getBuyCopyCommanderRemainTimes()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipBuyCommander then
        index = #Data._globalInfo._vipBuyCommander
    end
    
    return Data._globalInfo._vipBuyCommander[index] - self._dailyBuyCopyCommander
end

function _M:getBuyCopyCommanderIngot()
    return 38 + self._dailyBuyCopyCommander * 30
end

function _M:getBuyCopyExpeditionRemainTimes()
    local index = self._vip + 1
    if index > #Data._globalInfo._vipBuyExpedition then
        index = #Data._globalInfo._vipBuyExpedition
    end
    
    return Data._globalInfo._vipBuyExpedition[index] - self._dailyBuyCopyExpedition
end

function _M:getBuyCopyExpeditionIngot()
    return Data._globalInfo._buyExpeditionIngot
end

-- copy remain times

function _M:getCopyEliteRemainTimes()
    return self:getCopyEliteTimes() + self._dailyBuyCopyElite - self._dailyChallengeElite
end

function _M:getCopyBossRemainTimes()
    return self:getCopyBossTimes() + self._dailyBuyCopyBoss - self._dailyCopyBoss
end

function _M:getCopyCommanderRemainTimes()
    return self:getCopyCommanderTimes() + self._dailyBuyCopyCommander - self._dailyChallengeCommander
end

function _M:getCopyExpeditionRemainTimes()
    return self:getCopyExpeditionTimes() + self._dailyBuyCopyExpedition - self._dailyExpedition
end        

function _M:getToadLevel(playerLevel)
    return (playerLevel or self._level) - 25 + 1
end

function _M:getCopyTimes(copyType)
    local group = math.floor(copyType / 10)
    if group == Data.CopyType.group_elite then
        return self:getCopyEliteTimes()
    elseif group == Data.CopyType.group_boss then
        return self:getCopyBossTimes()
    elseif group == Data.CopyType.group_commander then
        return self:getCopyCommanderTimes()
    elseif group == Data.CopyType.group_expedition then
        return self:getCopyExpeditionTimes()
    end
end

function _M:getCopyTotalTimes(copyType)
    local group = math.floor(copyType / 10)
    if group == Data.CopyType.group_elite then
        return self:getCopyEliteTimes() + self._dailyBuyCopyElite
    elseif group == Data.CopyType.group_boss then
        return self:getCopyBossTimes() + self._dailyBuyCopyBoss
    elseif group == Data.CopyType.group_commander then
        return self:getCopyCommanderTimes() + self._dailyBuyCopyCommander
    elseif group == Data.CopyType.group_expedition then
        return self:getCopyExpeditionTimes() + self._dailyBuyCopyExpedition
    end
end

function _M:getChallengeCopyRemainTimes(copyType)
    local group = math.floor(copyType / 10)
    if group == Data.CopyType.group_elite then
        return self:getCopyEliteRemainTimes()
    elseif group == Data.CopyType.group_boss then
        return self:getCopyBossRemainTimes()
    elseif group == Data.CopyType.group_commander then
        return self:getCopyCommanderRemainTimes()
    elseif group == Data.CopyType.group_expedition then
        return self:getCopyExpeditionRemainTimes()
    end
end

function _M:getBuyCopyRemainTimes(copyType)
    local group = math.floor(copyType / 10)
    if group == Data.CopyType.group_elite then
        return self:getBuyCopyEliteRemainTimes()
    elseif group == Data.CopyType.group_boss then
        return self:getBuyCopyBossRemainTimes()
    elseif group == Data.CopyType.group_commander then
        return self:getBuyCopyCommanderRemainTimes()
    elseif group == Data.CopyType.group_expedition then
        return self:getBuyCopyExpeditionRemainTimes()
    end
end

function _M:accountCopyWin(copyType)
    local group = math.floor(copyType / 10)
    if group == Data.CopyType.group_elite then
--        P._playerAchieve:dailyTaskDone(Data.DailyTaskType.challenge_elite)
        P._dailyChallengeElite = P._dailyChallengeElite + 1

    elseif group == Data.CopyType.group_boss then
--        P._playerAchieve:dailyTaskDone(Data.DailyTaskType.copy_boss)
        P._dailyCopyBoss = P._dailyCopyBoss + 1

    elseif group == Data.CopyType.group_commander then
--        P._playerAchieve:dailyTaskDone(Data.DailyTaskType.rob_horse)
        P._dailyChallengeCommander = P._dailyChallengeCommander + 1

    elseif group == Data.CopyType.group_expedition then
--        P._playerAchieve:dailyTaskDone(Data.DailyTaskType.expedition)
        P._playerExpedition._chapter = P._playerExpedition._chapter + 1

    end
end

function _M:addBuyCopyTimes(copyType)
    local group = math.floor(copyType / 10)
    if group == Data.CopyType.group_elite then
        self._dailyBuyCopyElite= self._dailyBuyCopyElite + 1
    elseif group == Data.CopyType.group_boss then
        self._dailyBuyCopyBoss = self._dailyBuyCopyBoss + 1
    elseif group == Data.CopyType.group_commander then
        self._dailyBuyCopyCommander = self._dailyBuyCopyCommander + 1
    elseif group == Data.CopyType.group_expedition then
        self._dailyBuyCopyExpedition = self._dailyBuyCopyExpedition + 1
    end

    lc.sendEvent(Data.Event.copy_times_dirty, {_type = copyType})
end

function _M:preCheckCondition(conditionId, conditionValue, troopIndex)
    local condition = {}
    if conditionId == 6 or conditionId == 16 then
        condition._cardType = nil
        condition._type = 1
    elseif conditionId >= 7 and conditionId <= 9 then
        condition._cardType = conditionId - 6
        condition._type = 1
    elseif conditionId == 10 then
        local cardNum = self._playerCard:getTroopCardCountByMinStar(conditionValue, troopIndex)
        return cardNum == 0
    elseif conditionId == 11 then
        local cardNum = self._playerCard:getTroopCardCountByNature(conditionValue, troopIndex)
        return cardNum == 0
    elseif conditionId == 16 then
        condition._cardType = nil
        condition._type = 2
    elseif conditionId >= 17 and conditionId <= 19 then
        condition._cardType = conditionId - 16
        condition._type = 2
    end
       
    if condition._type ~= nil then
        local cardNum = self._playerCard:getTroopCardCountByType(condition._cardType, troopIndex)
        if condition._type == 1 then
            return cardNum >= conditionValue
        elseif condition._type == 2 then
            return cardNum <= conditionValue
        end        
    end
    
    return true
end

function _M:getDailyGoldFlag()
    local totalCount = Data._globalInfo._vipCollectGold[P._vip] or 5
    local count = totalCount - P._dailyCollectedGold

    if count > 0 and P._dailyNextSpawn < ClientData.getCurrentTime() then
        return 1
    end

    return 0
end

function _M:getCharacterId()
    local characterId = math.floor(self._avatar / 100)
    if Data._characterInfo[characterId] == nil then
        characterId = 3
    end
    return characterId
end

function _M:isCharacterUnlocked(characterId)
    return P._characters[characterId] and P._characters[characterId]._level > 0 or false
end

function _M:getCharacterCount()
    local count = 0
    for id, _ in pairs(Data._characterInfo) do
        if id < 50 then count = count + 1 end
    end

    return count
end

function _M:getCharacterUnlockCount()
    local count = 0
    for id, _ in pairs(Data._characterInfo) do
        if _M:isCharacterUnlocked(id) then
            count = count + 1
        end
    end

    return count
end

function _M:getMaxCharacterLevel()
    local maxLevel = 0
    for id, _ in pairs(Data._characterInfo) do
        local level = self._characters[id]._level
        if level > maxLevel then
            maxLevel = level
        end
    end
    return maxLevel
end

function _M:getTotalCharacterLevel()
    local totalLevel = 0
    for id, _ in pairs(Data._characterInfo) do
        local level = self._characters[id]._level
        totalLevel = totalLevel + level
    end
    return totalLevel
end

function _M:isShowSpecialPackage()
    return bit.band(self._functionSwitch, 1) ~= 0
end

function _M:getClashTargetStep()
    local step = #self._playerBonus._bonusClashTarget
    for i = 1, #self._playerBonus._bonusClashTarget do
        if not self._playerBonus._bonusClashTarget[i]._isClaimed then
            step = i
            break
        end
    end
    return step
end

function _M:isNewBie(recruiteInfo)
    local curDay = math.floor((ClientData.getCurrentTime() + P._timeOffset) / 86400)
    local regDay = math.floor((P._regTime + P._timeOffset) / 86400)
    return curDay - regDay < recruiteInfo._param[3]
end
         
function _M:checkFindClash()
    return true
    --return P._playerWorld._curLevel[1] > 10104
end   

function _M:checkCrossFindClash()
    return true
    --return P:getMaxCharacterLevel() >= Data.RANK_TROPHY_VISIBLE_LEVEL
end
    

return _M