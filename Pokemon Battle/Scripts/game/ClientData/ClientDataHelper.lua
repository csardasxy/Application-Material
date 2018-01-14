local _M = ClientData


-- player data helper

function _M.getDisplayRegionId(id)
    if ClientData.isDJLX() then
        id = id - Data.DJLX_REGION_ID_BASE
    end
    return id < 100000 and (id % 10000) or id
end

function _M.getUserStringId(regionId, userId)
    return string.format("%d+%d", regionId, userId)
end

function _M.getChannelName(region)
    if region < 10000 then
        return Str(STR.CHANNEL_ANDROID)
    elseif region < 20000 then
        return Str(STR.CHANNEL_APPLE)
    else
        return Str(STR.CHANNEL_YYB)
    end
end

function _M.genFullRegionName(id, name, isShort)
    return string.format("%03d%s%s%s", _M.getDisplayRegionId(id), Str(STR.REGION), isShort and " " or "  ", name)
end

function _M.genChannelRegionName(region)
    local channelName = _M.getChannelName(region)
    local regionId = _M.getDisplayRegionId(region)
    return string.format("%s%d%s", channelName, regionId, Str(STR.REGION))
end

function _M.addBattleDebugLog(str)
    _M._battleDebugLog = (_M._battleDebugLog or '')..str
end

function _M.getCity(id)
    return P._playerWorld._cities[id]
end

function _M.sortTroopCards(cards)
    table.sort(cards, function(a, b)
        local typeOrder = {[Data.CardType.monster] = 1, [Data.CardType.magic] = 2, [Data.CardType.trap] = 3}
        local infoA, typeA = Data.getInfo(a._infoId)
        local infoB, typeB = Data.getInfo(b._infoId)
        if typeOrder[typeA] == typeOrder[typeB] then
            if infoA._quality == infoB._quality then
                return infoA._id > infoB._id        
            else
                return infoA._quality > infoA._quality
            end
        else
            return typeOrder[typeA] < typeOrder[typeB]
        end
    end)
end

function _M.claimBonus(bonus)
    local result
    if bonus._id then
        result = P._playerBonus:claimServerBonus(bonus)
        if result == Data.ErrorType.ok then
            ClientData.sendClaimServerBonus(bonus._id)
        end
    else
        result = P._playerBonus:claimBonus(bonus._infoId)
        if result == Data.ErrorType.ok then
            if bonus._type == Data.BonusType.online then
                ClientData.sendClaimOnlineBonus(bonus._infoId)
            elseif bonus._type == Data.BonusType.activity then
                ClientData.sendClaimActivityBonus(bonus._task._infoId)
            else
                ClientData.sendClaimBonus(bonus._infoId)
            end
        end
    end
    return result
end

-- system helper functions

function _M.getCurrentTime()
    if P._loginTime == nil or _M._baseTime == nil then
        return lc.Director:getCurrentTime()
    else
        return P._loginTime + _M.getRunningTime()
    end
end

function _M.getRunningTime()
    local curTime = lc.Director:getCurrentTime()
    return _M._baseTime and curTime - _M._baseTime or 0
end

function _M.getUtcTime(date)
    if type(date) == "number" then
        return date + _M._timezone
    else
        return os.time(date) + _M._timezone
    end
end

function _M.getDayOfWeek()
    if P._timeOffset then
        local timeCur = _M.getCurrentTime() + P._timeOffset
        return os.date("!*t", timeCur).wday - 1
    else
        return os.date("*t", _M.getCurrentTime()).wday - 1
    end
end

function _M.getVersion()
    local serverMD5 = lc.File:getWritablePath().."md5"
    local internalMD5 = "md5"
    local data = lc.readFile(serverMD5, 0, 32)
    if data == nil or #data == 0 then
        data = lc.readFile(internalMD5, 0, 32)
        if data == nil or #data == 0 then return "" end
    end
    local n, key = string.unpack(data, "<I")
    local decrypt = string.decrypt(string.sub(data, 5), key)
    local n, versionLen = string.unpack(decrypt, "b")
    local version = string.sub(decrypt, 2, versionLen + 1)
    return version
end

function _M.getBinVersion()
    return lc.App.getBinaryVersion and lc.App:getBinaryVersion() or "1.5.0"
end

function _M.getDisplayVersion()
    local ver = string.splitByChar(_M.getVersion(), '.')
    return string.format('%s.%s', _M.getBinVersion(), ver[4])
end

function _M.getNameByInfoId(infoId)
    local type = Data.getType(infoId)
    if type == Data.CardType.nature then return Str(STR.CARD_NATURE_BEGIN + infoId % 1000)
    elseif type == Data.CardType.category then return Str(STR.CARD_CATEGORY_BEGIN + infoId % 1000)
    elseif type == Data.CardType.keyword then return Str(STR.CARD_KEYWORD_BEGIN + infoId % 1000)
    end

    if type == Data.CardType.fragment then
        infoId = P._playerCard:convert2CardId(infoId)
    end

    local info = Data.getInfo(infoId)
    return info and Str(info._briefNameSid or info._nameSid) or ""
end

function _M.getItemTypeNameByInfoId(infoId, isFragment)
    local info, type = Data.getInfo(infoId)
    if type == Data.CardType.res then
        return Str(STR.RESOURCE)
    elseif type == Data.CardType.common_fragment or isFragment then
        return Str(STR.CARD)..Str(STR.FRAGMENT)
    elseif type == Data.CardType.props then
        type = info._type
        if type == 0 then
            return Str(STR.RESOURCE)
        elseif type >= 1 and type <= 4 then
            return Str(type + STR.PROPS_TYPE_BOX - 1)
        elseif type == 5 then
            return Str(STR.PROPS_TYPE_DECORATION)
        elseif type == 10 then
            return Str(STR.PROPS_TYPE_UNION)
        else
            return ""
        end
    else
        return Str(STR.CARD)
    end
end

function _M.isAppStoreReviewing()
    return bit.band(_M._option, 1) ~= 0
end

function _M.isHideActivityPackage()
    return bit.band(_M._option, 2) ~= 0
end

function _M.isHideCharge()
    --TODO
    return true
end

function _M.isShowAgreement()
    return false
end

function _M.isAndroidTest0602()
    return false
end

function _M.isDEV()
    return ClientData._userRegion and (ClientData._userRegion._id == 1001 or ClientData._userRegion._id == 1002)
end

function _M.isAppStore()
    return lc.App:getChannelName() == 'ASDK' and (lc.PLATFORM == cc.PLATFORM_OS_IPHONE or lc.PLATFORM == cc.PLATFORM_OS_IPAD)
end

function _M.isYYB()
    return lc.App:getChannelName() == 'ASDK' and ClientData.getSubChannelName() == 'yyb'
end

function _M.isYYBNew()
    return _M.isYYB() and lc.App.yybGetLoginType and lc.App:yybGetLoginType() ~= ""
end

function _M.isYYBLoginByQQ()
    return _M.isYYB() and lc.App.yybGetLoginType and lc.App:yybGetLoginType() == "0"
end

function _M.isDJLX()
    return lc.App:getChannelName() == 'ASDK' and ClientData.getAppId() == '10037'
end

function _M.hasAppStoreIapBug()
    local binVersion = _M.getBinVersion()
    local vs = string.splitByChar(binVersion, '.')
    local v = {tonumber(vs[1]), tonumber(vs[2]), tonumber(vs[3])}
    return (v[1] < 1) or (v[1] == 1 and v[2] < 6) or (v[1] == 1 and v[2] == 6 and v[3] < 5)
end

function _M.isUseFacebook()
    return false
end

function _M.isPlayVideo()
    return not ClientData.isAppStoreReviewing()
end

function _M.replaceCityScene()
    if ClientData.isAppStoreReviewing() then
        lc.replaceScene(require("CityScene2").create())
    else
        lc.replaceScene(require("CityScene").create())
    end
end

function _M.getPicIdByInfoId(infoId)
    local picId = 0
    local info = Data.getInfo(infoId)
    if info then picId = info._picId end
    if picId == nil or picId == 0 then picId = infoId end
    return picId
end

function _M.getPropIconName(infoId, isNormal)
    if isNormal then
        return string.format("props_ico_%d", ClientData.getPicIdByInfoId(infoId))
    else
        return string.format("img_icon_props_s%d", ClientData.getPicIdByInfoId(infoId))
    end
end

function _M.toggleAudio(behavior, isOn)
    if behavior == lc.Audio.Behavior.music then
        _M._isMusicOn = isOn
        lc.UserDefault:setBoolForKey(_M.ConfigKey.music_on, isOn)    
    else
        _M._isEffectOn = isOn
        lc.UserDefault:setBoolForKey(_M.ConfigKey.effect_on, isOn)
    end
    lc.Audio.setIsMute(not isOn, behavior)
end

function _M.syncServerPush()
    local flag = 0
    if lc.UserDefault:getBoolForKey(ClientData.ConfigKey.push_copy_pvp, true) then
        flag = bor(flag, 1)
    end

    if lc.UserDefault:getBoolForKey(ClientData.ConfigKey.push_union_help, true) then
        flag = bor(flag, 2)
    end

    _M.sendServerPushSwitch(flag)
end

function _M.getUnpassTeachCount(typeIndex, subTypeIndex)
    local minId = typeIndex * Data.INFO_ID_GROUP_SIZE_LARGE
    local maxId = (typeIndex + 1) * Data.INFO_ID_GROUP_SIZE_LARGE

    local count = 0
    local level = P:getMaxCharacterLevel()
    
    if typeIndex == Data.TeachType.mid_teach then
        if subTypeIndex == nil then             
            for i = 1, 3 do count = count + _M.getUnpassTeachCount(typeIndex, i) end
            return count
        elseif level < Data._globalInfo._unlockMidTeach + (subTypeIndex - 1) * 2 then 
            return count 
        end
    elseif (typeIndex == Data.TeachType.master_teach and level < Data._globalInfo._unlockMasterTeach) 
        or (typeIndex == Data.TeachType.new_teach and level < Data._globalInfo._unlockNewTeach) then
        return count
    end

    for _, info in pairs(Data._teachInfo) do
        if info._id > minId and info._id < maxId then
            if subTypeIndex == nil or (math.floor((info._id % Data.INFO_ID_GROUP_SIZE_LARGE - 1) / 8) + 1 == subTypeIndex) then
                local bonusId = info._bonusId
                local bonus = P._playerBonus._bonusTeach[bonusId]
                if bonus and bonus._value < bonus._info._val then
                    count = count + 1
                end
            end
        end
    end

    return count
end

-- data helper functions

function _M.formatNum(num, limit, isForceInt)
    num = num or 0
    limit = limit or 999999

    if num > limit then
        if num % 10000 == 0 or isForceInt then
            return string.format("%d"..Str(STR.WAN), math.floor(num / 10000))
        else
            return string.format("%.1f"..Str(STR.WAN), num / 10000)
        end
    else
        return string.format("%d", num)
    end
end

function _M.formatPeriod(dt, partCount)
    local t = dt
    local day = math.floor(t / Data.DAY_SECONDS)

    t = t % Data.DAY_SECONDS
    local hour = math.floor(t / 3600)

    t = t % (3600)
    local minute = math.floor(t / 60)

    t = t % 60
    local second = t

    local count = 0
    partCount = partCount or 2

    local str = ""
    if day > 0 then
        count = count + 1
        str = string.format("%d%s", day, Str(STR.DAY))
    end
    
    if count == partCount then return str end
    
    if hour > 0 then
        count = count + 1
        str = string.format("%s%d%s", str, hour, Str(STR.HOUR))
    end
    
    if count == partCount then return str end
    
    if minute > 0 then
        count = count + 1
        str = string.format("%s%d%s", str, minute, Str(STR.MINUTE))
    end
    
    if count == partCount then return str end
    
    if second > 0 or (count == 0 and second == 0) then
        str = string.format("%s%d%s", str, second, Str(STR.SECOND))
    end
    
    return str 
end

function _M.formatTime(dt)
    if dt < 0 then dt = 0 end

    local hour = math.floor(dt / 3600)
    local minute = math.floor(dt % 3600 / 60)
    local second = math.floor(dt % 3600 % 60)

    return string.format("%02d:%02d:%02d", hour, minute, second)
end

function _M.parseTimeStr(str, timezone)
    if str == nil or str == '' then
        return 0
    end

    local parts = string.split(str, ".")
    local timestamp = _M.getUtcTime{year = tonumber(parts[1]), month= tonumber(parts[2]), day = tonumber(parts[3]), 
        hour = parts[4] and tonumber(parts[4]) or 4, min = parts[5] and tonumber(parts[5]) or 0, sec = parts[6] and tonumber(parts[6]) or 0, isdst = false}
    
    return timestamp - (timezone or Data.SERVER_TIME_ZONE)
end

function _M.getTimeAgo(timestamp, maxDay)
    local dt = _M.getCurrentTime() - timestamp

    local day = math.floor(dt / 24 / 3600)
    if day > 0 then
        if maxDay and day > maxDay then            
            return string.format("%s%d%s", Str(STR.EXCEED), maxDay, Str(STR.DAY_AGO))
        else
            return string.format("%d%s", day, Str(STR.DAY_AGO))
        end
    end

    local hour = math.floor(dt / 3600)
    if hour > 0 then
        return string.format("%d%s", hour, Str(STR.HOUR_AGO))
    end

    local minute = math.floor(dt / 60)
    if minute > 0 then
        return string.format("%d%s", minute, Str(STR.MINUTE_AGO))
    end

    if dt <= 1 then
        return Str(STR.NOW)
    end

    return string.format("%d%s", dt, Str(STR.SECOND_AGO))
end

function _M.getServerDate(timestamp)
    if P == nil or P._loginTime == nil then
        return nil, nil, nil, nil        -- hour, day, month, year
    end

    local date = os.date("!*t", timestamp or _M.getCurrentTime() + P._timeOffset)

    return date.hour, date.day, date.month, date.year
end

function _M.getServerTick(timestamp)
    local hour, day, month, year = _M.getServerDate(timestamp)
    return year * 1000000 + month * 10000 + day * 100 + hour
end

function _M.getServerDayTimeRemain(hour)
    local date = os.date("!*t", ClientData.getCurrentTime())
    date.hour = hour or 24; date.min = 0; date.sec = 0
    local timeCur, timeDayEnd = ClientData.getUtcTime(ClientData.getCurrentTime()), ClientData.getUtcTime(date)
    return timeDayEnd - timeCur
end

function _M.getExpireTimestamp(day)
    local timestamp = _M.getCurrentTime() + P._timeOffset
    timestamp = timestamp - timestamp % (3600 * 24)
    timestamp = timestamp + day * 3600 * 24 - P._timeOffset
    return timestamp
end

function _M.getExpireDay(timestamp)
    local todayTimestamp = _M.getExpireTimestamp(0)
    return math.floor((timestamp - todayTimestamp) / 3600 / 24)
end
    
function _M.getMonthDay(year, month)
    local days = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
    local day = days[month]
    if month ==  2 and year % 4 == 0 and year % 100 ~= 0 then
        day = day + 1
    end
    return day
end

function _M.getDaysAfterServerOpen()
    return (_M.getCurrentTime() - P._serverOpenTimestamp) / Data.DAY_SECONDS
end

function _M.convertId(id, isReverse)
    local swap = function(id)
        return bor(blsh(band(id, 0xFF), 8), band(brsh(id, 8), 0xFF))
    end

    if isReverse then
        if id >= 75536 then
            return 65536 + math.floor((id - 75536) / 8)
        else
            id = id - 10000
            return swap(id)
        end
    else
       if id >= 65536 then
           return 75536 + (id - 65536) * 8
       else
           return swap(id) + 10000
       end
    end
end

function _M.isRateValid()
    return lc.App.getAppRateUrl and lc.App:getAppRateUrl() ~= "" and (not ClientData.isAppStoreReviewing())
end

function _M.isMixable(infoId)
    return true
end

function _M.getTroopName(troopIndex, isAddRemark)
    local name
    name = string.format("%s %d", Str(STR.TROOP), troopIndex)

    if isAddRemark then
        local remarkStr = P._troopRemarks[troopIndex]
        if remarkStr == nil or remarkStr == "" then
            remarkStr = Str(STR.REMARK_NONE)
        end

        name = name..string.format("\n|%s|", remarkStr)
    end


    return name
end

function _M.getStrByCardType(type)
    if type == Data.CardType.monster then
        return Str(STR.MONSTER)
    elseif type == Data.CardType.magic then
        return Str(STR.MAGIC)
    elseif type == Data.CardType.trap then
        return Str(STR.TRAP)
    end
end


function _M.getAvatarFrameName(id, vip)
    if id == Data.PropsId.avatar_frame then
        vip = vip or P._vip
        --return string.format("avatar_frame_%03d", vip == 0 and 1 or 101)
        return string.format("avatar_frame_%03d", 1)
    else
        return string.format("avatar_frame_%d", id)
    end
end

function _M.getSkillDesc(skillId)
    local info, desc = Data._skillInfo[skillId]
    if info._val[1] == 0 then
        desc = Str(info._descSid)
    else
        desc = string.format(Str(info._descSid), info._val[1], info._val[2], info._val[3], info._val[4])
    end
    return desc
end

function _M.getRandomArray(array)
    local srcArray = {}
    for i = 1, #array do
        table.insert(srcArray, #srcArray + 1, array[i])
    end
    
    local newArray = {}
    while #srcArray > 0 do
        local index = math.random(1, #srcArray)
        table.insert(newArray, #newArray + 1, srcArray[index])
        table.remove(srcArray, index)
    end
    
    return newArray
end

function _M.pbTroopToTroop(pbTroop)
    local troopInfo = {} 

    local levels = {}
    for i = 1, #pbTroop do
        local pbCard=  pbTroop[i]
        local card = {_infoId = pbCard.info_id, _num = pbCard.num, _level = 1}
        troopInfo[#troopInfo + 1] = card
    end

    return troopInfo
end

function _M.troopToPbtroop(cards)
    local troopCards = {}
    local troopLevels = {}
    for i, card in ipairs(cards) do
        troopCards[i] = {info_id = card._infoId, num = card._num}
    end
    for i, card in ipairs(cards) do
        troopLevels[i] = {info_id = card._infoId, level = 1}
    end
    return troopCards, troopLevels
end

function _M.saveTroops()
    if _M._cloneTroops == nil then return false end

    local isUpdateView = false
    for k, v in pairs(_M._cloneTroops) do
        if v._isDirty then
            P._playerCard:saveTroop(v, k)
            isUpdateView = true
        end
    end
    
    return isUpdateView
end

function _M.initConfig(userId)
    local configPrefix = _M._userRegion._id..'.'..userId
    lc.resetConfigFile(configPrefix)
    return configPrefix
end

function _M.getActiveUnionWarCity()
	local unionId = P._unionId
	local currentTime = _M.getCurrentTime()
	if unionId ~= nil and unionId > 0 then
		for _, war in pairs(_M._unionWorld._wars) do
			if war._unionInfos[1]._id == unionId or war._unionInfos[2]._id == unionId then
				if currentTime >= war._startTime and currentTime <= war._endTime then
					return _M._unionWorld._cities[war._levelIds[1]]
				end
			end
		end
	end

	return nil
end

function _M.checkBtnClick()
    local curTime = ClientData.getCurrentTime()
    if curTime - ClientData._btnClickTime < 1 then return false end
    ClientData._btnClickTime = curTime
    return true
end

-- recharge helper

function _M:isAnyRecharged()
    return P._vip > 0 or P._vipExp > 0
end

function _M:isGemRecharged()
    for i = Data.PurchaseType.product_1, Data.PurchaseType.product_8 do
        if _M.isRecharged(i) then return true end
    end
    return false
end

function _M.isRecharged(type)
    local offset = 0
    if type < Data.PurchaseType.month_card_1 then
        offset = type - Data.PurchaseType.product_1
    elseif type < Data.PurchaseType.package_1 then
        offset = type - Data.PurchaseType.month_card_1 + 10
    elseif type < Data.PurchaseType.limit_1 then
        offset = type - Data.PurchaseType.package_1 + 20
    else
        offset = type - Data.PurchaseType.limit_1 + 30
    end

    return bit.band(P._firstIngotRecharge, bit.lshift(1, offset)) ~= 0
end

function _M.setRecharged(type)
    local offset = 0
    if type < Data.PurchaseType.month_card_1 then
        offset = type - Data.PurchaseType.product_1
    elseif type < Data.PurchaseType.package_1 then
        offset = type - Data.PurchaseType.month_card_1 + 10
    elseif type < Data.PurchaseType.limit_1 then
        offset = type - Data.PurchaseType.package_1 + 20
    else
        offset = type - Data.PurchaseType.limit_1 + 30
    end

    P._firstIngotRecharge = bit.bor(P._firstIngotRecharge, bit.lshift(1, offset))
    P._playerBonus._packageBonus[1120]._value = P._firstIngotRecharge

    P._playerBonus:incIapCount(type)
end

function _M.isRecharge7BonusClaimed()
    return P._playerBonus._packageBonus[1306]._isClaimed
end

function _M.getRecharge7BonusValue()
    return P._playerBonus._packageBonus[1306]._value
end

function _M.isReturnToGameClaimed()
    local bonus = P._playerBonus._returnBonus
    return bonus and bonus._isClaimed or false
end

function _M.isReturnToGame()
    local bonus = P._playerBonus._returnBonus
    return bonus and (bonus._value >= bonus._info._val) or false
end

function _M.getProductNameByPrice(price)
    if price == 6 then
        return "com.game.juedouzc.package2.ticket_6"
    elseif price == 30 then
        return "com.game.juedouzc.package3.ticket_30"
    elseif price == 28 then
        return "com.game.juedouzc.gold.ticket_28"
    elseif price == 68 then
        return "com.game.juedouzc.gold.ticket_68"
    elseif price == 88 then
        return "com.game.juedouzc.gold.ticket_88"
    else
        return "com.game.juedouzc.gem.ticket_"..price
    end
end

function _M.getProductName(purchaseType, inSupportCN)
    if purchaseType == Data.PurchaseType.month_card_1 then
        return "com.game.juedouzc.gold.ticket_28"
    elseif purchaseType == Data.PurchaseType.month_card_2 then
        return "com.game.juedouzc.gold.ticket_68"
    elseif purchaseType == Data.PurchaseType.fund then
        return "com.game.juedouzc.gold.ticket_88"
    elseif purchaseType == Data.PurchaseType.daily_1 then
        return _M.getProductNameByPrice(Data._globalInfo._monthCardRmb[4])
    elseif purchaseType == Data.PurchaseType.daily_2 then
        return _M.getProductNameByPrice(Data._globalInfo._monthCardRmb[5])
    elseif purchaseType == Data.PurchaseType.package_1 then
        return "com.game.juedouzc.package1.ticket_6"
    elseif purchaseType == Data.PurchaseType.package_2 then
        return "com.game.juedouzc.package2.ticket_6"
    elseif purchaseType == Data.PurchaseType.package_3 then
        return "com.game.juedouzc.package3.ticket_30"
    elseif purchaseType == Data.PurchaseType.package_4 or purchaseType == Data.PurchaseType.package_5 or purchaseType == Data.PurchaseType.package_6 then
        return _M.getProductNameByPrice(Data._globalInfo._packageRmb[purchaseType - Data.PurchaseType.package_1 + 1])
    elseif purchaseType == Data.PurchaseType.limit_1 or purchaseType == Data.PurchaseType.limit_2 then
        return _M.getProductNameByPrice(Data._globalInfo._limitRmb[purchaseType - Data.PurchaseType.limit_1 + 1])
    else
        return "com.game.juedouzc.gem.ticket_"..math.floor(Data._globalInfo._ingotValue[purchaseType] / 10)
    end
end

function _M.getProductTitle(purchaseType)
    if purchaseType == Data.PurchaseType.month_card_1 then
        return ClientData.isAppStoreReviewing() and Str(STR.SUPER_BONUS_1) or Str(STR.MONTH_CARD1)
    elseif purchaseType == Data.PurchaseType.month_card_2 then
        return ClientData.isAppStoreReviewing() and Str(STR.SUPER_BONUS_2) or Str(STR.MONTH_CARD2)
    elseif purchaseType == Data.PurchaseType.fund then
        return ClientData.isAppStoreReviewing() and Str(STR.SUPER_BONUS_3) or Str(STR.FUND_LEVEL)
    elseif purchaseType == Data.PurchaseType.daily_1 then
        return ClientData.getProductTitle(Data.PurchaseType.package_2)
    elseif purchaseType == Data.PurchaseType.daily_2 then
        return ClientData.getProductTitle(Data.PurchaseType.package_3)
    elseif purchaseType >= Data.PurchaseType.package_1 and purchaseType < Data.PurchaseType.limit_1 then
        return Str(STR.SUPER_PACKAGE_1 + purchaseType - Data.PurchaseType.package_1)
    elseif purchaseType >= Data.PurchaseType.limit_1 then
        return Str(STR.LIMIT_PACKAGE_1 + purchaseType - Data.PurchaseType.limit_1)
    else
        return string.format("%d %s", Data._globalInfo._ingotValue[purchaseType], Str(STR.SID_RES_NAME_3))
    end
end

function _M.pay(purchaseType, purchaseId)
    _M._purchaseType = purchaseType
    _M._purchaseId = purchaseId

    local userName = string.gsub(P._name, "'", "")
    local price = _M.getPrice(purchaseType)
    local payInfo
    if lc.App:getChannelName() == "OPPO" then
        local isMonthCard = (purchaseType == Data.PurchaseType.month_card_1 or purchaseType == Data.PurchaseType.month_card_2)
        local isFund = (purchaseType == Data.PurchaseType.fund)
        local count = (isMonthCard or isFund) and 1 or _M.getIngot(purchaseType)
        price = price / count
        local productName = (isMonthCard or isFund) and _M.getProductName(purchaseType, true) or Str(STR.SID_RES_NAME_3)
        payInfo = {productId = purchaseType, productName = productName, purchaseId = purchaseId, price = price, count = count, exchangeRate = 10,
            regionId = _M._userRegion._id, userId = P._id, userName = userName, userLevel = P._level}   
    elseif lc.App:getChannelName() == "MEIZU" or lc.App:getChannelName() == "SY37" or lc.App:getChannelName() == "YYB" then
        local count = _M.getIngot(purchaseType)
        price = price / count
        local productName = Str(STR.SID_RES_NAME_3)
        payInfo = {productId = purchaseType, productName = productName, purchaseId = purchaseId, price = price, count = count, exchangeRate = 10,
            regionId = _M._userRegion._id, userId = P._id, userName = userName, userLevel = P._level}   
    elseif lc.App:getChannelName() == "OFFICIAL" then
        local productId
        if purchaseType == Data.PurchaseType.month_card_1 then
            productId = 7
        elseif purchaseType == Data.PurchaseType.month_card_2 then
            productId = 8
        else
            productId = purchaseType
        end

        payInfo = {productId = productId, productName = _M.getProductName(purchaseType, true), purchaseId = purchaseId, price = price, count = 1, exchangeRate = 10,
            regionId = _M._userRegion._id, userId = P._id, userName = userName, userLevel = P._level}
    elseif lc.App:getChannelName() == "ASDK" then
        if lc.PLATFORM == cc.PLATFORM_OS_ANDROID then
            payInfo = {productId = purchaseType, productName = _M.getProductTitle(purchaseType), purchaseId = purchaseId, price = price, count = 1, exchangeRate = 10,
                regionId = _M._userRegion._id, userId = P._id, userName = userName, userLevel = P._level}
        else
            payInfo = {productId = purchaseType, productName = _M.getProductName(purchaseType, true), purchaseId = purchaseId, price = price, count = 1, exchangeRate = 10,
                regionId = _M._userRegion._id, userId = P._id, userName = userName, userLevel = P._level}
        end
    else
        payInfo = {productId = purchaseType, productName = _M.getProductName(purchaseType, lc.App:getChannelName() ~= "TONGBUTUI" and lc.App:getChannelName() ~= "YIXIN"), purchaseId = purchaseId, price = price, count = 1, exchangeRate = 10,
            regionId = _M._userRegion._id, userId = P._id, userName = userName, userLevel = P._level}
    end

    local payInfoStr = json.encode(payInfo)
    print ('####', payInfoStr)
    lc.App:pay(payInfoStr)
end

function _M.getPrice(type)
    local channel = lc.App:getChannelName()
    local values = (channel == "APPSTORE" and Data._globalInfo._ingotRmb or Data._globalInfo._ingotRmb)

    if type < Data.PurchaseType.month_card_1 then
        return Data._globalInfo._ingotRmb[type]
    elseif type < Data.PurchaseType.package_1 then
        return Data._globalInfo._monthCardRmb[type - Data.PurchaseType.month_card_1 + 1]
    elseif type < Data.PurchaseType.limit_1 then
        return Data._globalInfo._packageRmb[type - Data.PurchaseType.package_1 + 1]
    else
        return Data._globalInfo._limitRmb[type - Data.PurchaseType.limit_1 + 1]
    end
end

function _M.getDisplayPrice(type)
    local productId = nil
    local channel = lc.App:getChannelName()
    if channel == "APPSTORE" or channel == "FACEBOOK" then
        productId = ClientData.getProductName(type)
    end

    if productId ~= nil and lc.App.getDisplayPrice ~= nil then
        local displayPrice = lc.App:getDisplayPrice(productId);
        if displayPrice ~= '' then return displayPrice end
    end
    
    return string.format("%s %d", Str(STR.RMB), ClientData.getPrice(type))
end

function _M.getIngot(type, ignoreFirstRecharge)
    local channel = lc.App:getChannelName()
    
    local giftIngot = 0
    if type < Data.PurchaseType.month_card_1 then
        if not ignoreFirstRecharge and not ClientData.isRecharged(type) then
            giftIngot = Data._globalInfo._ingotValue[type]
        else
            giftIngot = Data._globalInfo._ingotGift[type]
            if P._playerActivity._actChargeBonus then
                giftIngot = giftIngot + math.floor(values[type] * P._playerActivity._actChargeBonus._bonusId[1] / 100)    
            end
        end
        return Data._globalInfo._ingotValue[type - Data.PurchaseType.product_1 + 1], giftIngot
    elseif type < Data.PurchaseType.package_1 then
        return Data._globalInfo._monthCardRmb[type - Data.PurchaseType.month_card_1 + 1] * 10, giftIngot
    elseif type < Data.PurchaseType.limit_1 then
        return Data._globalInfo._packageRmb[type - Data.PurchaseType.package_1 + 1] * 10, giftIngot
    else
        return Data._globalInfo._limitRmb[type - Data.PurchaseType.limit_1 + 1] * 10, giftIngot
    end
end

function _M.strToTimeTick(str)
    local parts = string.splitByChar(str, '.')
    local t = tonumber(parts[1]) * 1000000 + tonumber(parts[2]) * 10000 + tonumber(parts[3]) * 100 + tonumber(parts[4])
    return t
end

function _M.strToMonthDay(str, yesterday)
    local parts = string.splitByChar(str, '.')
    local year, month, day = tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3])
    if yesterday then
        day = day - 1
        if day == 0 then
            month = month - 1
            if month == 0 then month = 12 year = year - 1 end
            day = _M.getMonthDay(year, month)
        end
    end
    return tostring(month)..Str(STR.MONTH)..tostring(day)..Str(STR.DAY_RI)
end

function _M.getActivityDuration(activityInfo)   
    return _M.strToTimeTick(activityInfo._beginTime), _M.strToTimeTick(activityInfo._endTime)
end

function _M.getActivityDurationStr(activityInfo)
    local beginStr = _M.strToMonthDay(activityInfo._beginTime)
    local endStr = _M.strToMonthDay(activityInfo._endTime, true)
    if beginStr ~= endStr then return beginStr..' - '..endStr
    else return beginStr
    end
end

function _M.isActivityValid(activityInfo)
    if activityInfo == nil then return false end

    local tick = ClientData.getServerTick()
    local beginTimeTick, endTimeTick = ClientData.getActivityDuration(activityInfo)
    return tick >= beginTimeTick and tick < endTimeTick
end

function _M.isActivityForSubChannel(activityInfo)
    local subChannelType = ClientData.getSubChannelType()
    for i = 1, #activityInfo._subChannel do
        if activityInfo._subChannel[i] == subChannelType then
            return true
        end     
    end
    return false
end

function _M.getActivityByParam(value)
    for k, v in pairs(Data._activityInfo) do
        if v._param[1] == value and _M.isActivityForSubChannel(v) then 
            return v
        end  
    end
    return nil
end

function _M.getActivityByType(value)
    for k, v in pairs(Data._activityInfo) do
        if v._type[1] == value and _M.isActivityForSubChannel(v) then
            return v
        end  
    end
    return nil
end

function _M.getActivityByTypeAndParam(typeValue, value)
    for k, v in pairs(Data._activityInfo) do
        if v._type[1] == typeValue and _M.isActivityForSubChannel(v) then 
            for j = 1, #v._param do
                if v._param[j] == value then
                    return v, j
                end
            end
        end  
    end
    return nil 
end

function _M.getValidActivityByTypeAndParam(typeValue, value)
    local activityInfo, pos = ClientData.getActivityByTypeAndParam(typeValue, value)
    if activityInfo and ClientData.isActivityValid(activityInfo) then return activityInfo, pos end
    return nil
end

function _M.isActivityValidByParam(value)
    local activityInfo = ClientData.getActivityByParam(value)
    if activityInfo == nil then return false end
    return ClientData.isActivityValid(activityInfo)
end

function _M.clearActivityShowed(activityParam)
    lc.writeConfig(ClientData.ConfigKey.activity_show_day..activityParam, 0)
end

function _M.setActivityShowed(activityParam)
    local tick = math.floor(ClientData.getServerTick() / 100)

    lc.writeConfig(ClientData.ConfigKey.activity_show_day..activityParam, tick)
end

function _M.isActivityShowed(activityParam)
    local tick = math.floor(ClientData.getServerTick() / 100)

    local pretick = lc.readConfig(ClientData.ConfigKey.activity_show_day..activityParam, 0)
    return pretick == tick
end

-- battle helper functions

function _M.startFriendBattle(friendId)
    local isTroopValid, msg = P._playerCard:checkTroop(P._curTroopIndex)
    if not isTroopValid then
        ToastManager.push(msg)
        return
    end

    V.getActiveIndicator():show(Str(STR.WAITING))
    _M.sendFriendBattle(P._curTroopIndex, friendId)
end

function _M.sendBattleDebugLog()
    local msg = SglMsg_pb.SglReqMsg()
    msg.type = SglMsgType_pb.PB_TYPE_BATTLE_ERROR    
    _M.sendProtoMsg(msg)
end

function _M.genGuidanceTroop(id)
    local guidance = Data._guidanceInfo[id]

    local troopCards, cardLevels, oppoTroopCards, oppoCardLevels = {}, {}, {}, {}
    local fortressHp, oppoFortressHp = 0, 0
    for index = 1, 2 do
        local curTroopCards = (index == 1) and troopCards or oppoTroopCards
        local curLevels = (index == 1) and cardLevels or oppoCardLevels
        local troopInfo = Data._troopInfo[(index == 1) and guidance._card or guidance._oppoCard]
        
        if index == 1 then fortressHp = troopInfo._fortressHp
        else oppoFortressHp = troopInfo._fortressHp
        end

        for i = 1, #troopInfo._infoId do
            curTroopCards[i] = {info_id = troopInfo._infoId[i], num = troopInfo._num[i]}
            curLevels[i] = {info_id = troopInfo._infoId[i], level = troopInfo._level[i]}
        end
    end
    
    return troopCards, cardLevels, fortressHp, oppoTroopCards, oppoCardLevels, oppoFortressHp
end

function _M.genTestTroop()
    local attackerCards, attackerLevels, defenderCards, defenderLevels = {}, {}, {}, {}
    local info = Data._testInfo

    for i = 1, 2 do
        local prefix = (i == 1 and "_attacker" or "_defender")
        local cards = (i == 1 and attackerCards or defenderCards)
        local levels = (i == 1 and attackerLevels or defenderLevels)
        
        for index = 1, Data.MAX_TROOP_CARD_COUNT do
            if info[prefix.."CardInfoId"][index] == nil then break end
            
            local card = {}
            card.info_id = info[prefix.."CardInfoId"][index]
            card.num = info[prefix.."CardNum"][index] or 1
            table.insert(cards, card)

            local cardlLevel = {}
            cardlLevel.info_id = info[prefix.."CardInfoId"][index]
            cardlLevel.level = info[prefix.."CardLevel"][index] or 1
            table.insert(levels, cardlLevel)
        end
    end
    
    return attackerCards, attackerLevels, defenderCards, defenderLevels
end

function _M.genTestAllTroop()
    -- init test troop
    local attackerTroop = {}
    local defenderTroop = {}
    
    for b = 1, 2 do
        local troop = b == 1 and attackerTroop or defenderTroop
        
        for k, v in pairs(Data._monsterInfo) do
            local card = {}
            card.info_id = v._id
            card.level = 15
            card.evolution_level = 2
            card.new_skill_id = 0
            card.new_skill_level = 0
            card.round = 1
            
            table.insert(troop, card)
        end
    end
    
    return attackerTroop, defenderTroop
end

function _M.addSceneSkills(input, info)
    local skills = info._sceneSkills
    if skills[1] and skills[1][1] and skills[1][1] > 0 then
        input._opponent._fortressSkill = {_id = info._sceneSkills[1][1], _level = info._sceneSkills[1][2]}
    end

    if skills[2] and skills[2][1] and skills[2][1] > 0 then
        input._player._fortressSkill = {_id = info._sceneSkills[2][1], _level = info._sceneSkills[2][2]}
    end
end

function _M.setBattleFromSceneId(sceneId)
    if sceneId then
        _M._fromSceneId = sceneId
    else
        local scene = lc._runningScene
        if scene == nil or (scene._sceneId ~= _M.SceneId.city and scene._sceneId ~= _M.SceneId.world) then
            _M._fromSceneId = _M.SceneId.city
        else
            _M._fromSceneId = scene._sceneId
        end
    end
end

function _M.genInputFromResp(resp)
    local input = {}
    
    input._type = resp.type
    input._timestamp = resp.timestamp
    input._copyId = resp.copy_id
    input._levelId = resp.level_id
    input._isOppoOnline = resp.is_op_online or false
    input._isAttacker = resp.is_attacker or false

    input._isWatcher = resp.is_watcher or false
    
    input._player, input._opponent = {}, {}
    local info, oppoInfo = resp.player_troop.info or {}, resp.opponent_troop.info or {}
    input._player._name, input._player._level, input._player._vip, input._player._avatar, input._player._region, input._player._regionId = info.name or "", info.level or 0, info.vip or 0, info.avatar or 0, info.rid, info.rid
    input._player._avatarFrame, input._player._cardBackId = info.avatar_frame, (info.card_back == 0 and Data.PropsId.card_back or info.card_back)
    input._player._isNpc = info.is_npc
    input._opponent._name, input._opponent._level, input._opponent._vip, input._opponent._avatar, input._opponent._region = oppoInfo.name or "", oppoInfo.level or 0, oppoInfo.vip or 0, oppoInfo.avatar or 0, oppoInfo.rid
    input._opponent._avatarFrame, input._opponent._cardBackId = oppoInfo.avatar_frame, (oppoInfo.card_back == 0 and Data.PropsId.card_back or oppoInfo.card_back)
    input._opponent._isNpc = oppoInfo.is_npc
    
    input._player._troopCards, input._opponent._troopCards = resp.player_troop.cards, resp.opponent_troop.cards
    input._player._troopLevels, input._opponent._troopLevels = resp.player_troop.levels, resp.opponent_troop.levels
    input._player._troopSkins, input._opponent._troopSkins = resp.player_troop.skins, resp.opponent_troop.skins
    input._player._fortressHp, input._opponent._fortressHp = resp.player_troop.hp, resp.opponent_troop.hp

    input._player._trophy = info.trophy
    input._opponent._trophy = oppoInfo.trophy

    input._player._idInRoom,  input._opponent._idInRoom= resp.player_troop.id, resp.opponent_troop.id

    input._player._crown = nil
    if info:HasField('crown') then input._player._crown = {_infoId = info.crown.info_id, _num = info.crown.num} end
    input._opponent._crown = nil
    if oppoInfo:HasField('crown') then input._opponent._crown = {_infoId = oppoInfo.crown.info_id, _num = oppoInfo.crown.num} end

    input._player._avatarFrameCount = 0
    if info:HasField('avatar_frame_count') then input._player._avatarFrameCount = info.avatar_frame_count end
    input._opponent._avatarFrameCount = 0
    if oppoInfo:HasField('avatar_frame_count') then input._opponent._avatarFrameCount = oppoInfo.avatar_frame_count end

    if #resp.player_used_cards > 0 then
        input._player._usedCards = resp.player_used_cards
    end

    if #resp.opponent_used_cards > 0 then
        input._opponent._usedCards = resp.opponent_used_cards
    end
    
    if #resp.random_seq > 0 then
        input._randomSeed = resp.random_seq[1]
        print("BATTLE RANDOM SEED   ", resp.random_seq[1])
    end

    _M._isOppoOnline = input._isOppoOnline
    _M._usedCardsToAdd = {}
    _M._observeUsedCards = {}
    
    return input
end

function _M.genInputFromAttackResp(resp)
    local input = _M.genInputFromResp(resp)
    
    local levelInfo = Data._levelInfo[input._levelId]
    input._sceneType = Data.getSceneTypeByCityId(input._levelId)
    ClientData._battleFromTravel = levelInfo
    
    if resp.type == Battle_pb.PB_BATTLE_MATCH then
        input._battleType = Data.BattleType.PVP_room

    elseif resp.type == Battle_pb.PB_BATTLE_MASSWAR_MULTIPLE then
        input._battleType = Data.BattleType.PVP_group

    elseif resp.type == Battle_pb.PB_BATTLE_DARK then
        input._battleType = Data.BattleType.PVP_dark
        
    else        
        input._battleType = Data.BattleType.task
        
        input._opponent._name = Str(Data._levelInfo[input._levelId]._nameSid)
        input._opponent._level = 0
        
        input._conditionIds = levelInfo._condition
        input._conditionValues = levelInfo._value
        input._eventIds = levelInfo._eventId
        input._oppoEventIds = levelInfo._oppoEventId

        --[[
        if levelInfo._storyOppoUsedCards[1] > 0 and input._opponent._usedCards == nil then
            input._opponent._usedCards = levelInfo._storyOppoUsedCards
        end
        ]]

        input._sceneType = Data.getSceneTypeByCityId(input._levelId)

        _M.addSceneSkills(input, levelInfo)
    end
    
    return input
end

function _M.genInputFromActivityPvpResp(resp)
    local input = _M.genInputFromResp(resp)
    input._sceneType = (resp.opponent_troop.info.id % 4) + 1
    input._battleType = resp.opponent_troop.info.id == 0 and Data.BattleType.PVP_clash_npc or Data.BattleType.PVP_clash

    local evt = Data._activityTaskInfo._pvp._param[4][1]
    input._eventIds = {evt}
    input._oppoEventIds = {evt}

    _M.setBattleFromSceneId()
    
    return input
end

function _M.genInputFromLadderPvpResp(resp)
    local input = _M.genInputFromResp(resp)
    input._battleType = resp.opponent_troop.info.id == 0 and Data.BattleType.PVP_clash_npc or Data.BattleType.PVP_clash

    local selfTrophy, oppoTrophy = input._player._trophy, input._opponent._trophy
    input._clashGrade = P._playerFindClash:getGrade(math.max(selfTrophy, oppoTrophy))
    input._sceneType = 10 + input._clashGrade

    local trophyDif = oppoTrophy - selfTrophy
    local oppoType
    if input._battleType == Data.BattleType.PVP_clash_npc then
       oppoType = resp.npc_type + 1
        _M.addSceneSkills(input, {_sceneSkills = {Data._ladderInfo[input._clashGrade]._sceneSkills[oppoType]}})
    else
        oppoType = 5
    end
    input._clashOppoType = oppoType

    ClientData._battleFromFindIndex = Data.FindMatchType.lord_clash
    _M.setBattleFromSceneId(ClientData.SceneId.find)
    
    return input
end

function _M.genInputFromMatchResp(resp)
    local input = _M.genInputFromResp(resp)
    input._battleType = Data.BattleType.PVP_room

    input._sceneType = Data.BattleSceneType.gold_scene
--    todo observe

    _M.setBattleFromSceneId(ClientData.SceneId.in_room)
    
    return input
end

function _M.genInputFromGroupResp(resp)
    local input = _M.genInputFromResp(resp)
    input._battleType = Data.BattleType.PVP_group

    input._sceneType = Data.BattleSceneType.gold_scene
    
    ClientData._battleFromFindIndex = Data.FindMatchType.union_battle
    _M.setBattleFromSceneId(ClientData.SceneId.find)

    return input
end

function _M.genInputFromDarkResp(resp)
    local input = _M.genInputFromResp(resp)
    input._battleType = Data.BattleType.PVP_dark

    input._sceneType = Data.BattleSceneType.gold_scene
    
    ClientData._battleFromFindIndex = Data.FindMatchType.dark
    _M.setBattleFromSceneId(ClientData.SceneId.find)

    return input
end

function _M.genInputFromLadderExPvpResp(resp)
    local input = _M.genInputFromResp(resp)
    input._battleType = resp.opponent_troop.info.id == 0 and Data.BattleType.PVP_ladder_npc or Data.BattleType.PVP_ladder

    input._sceneType = 21

    ClientData._battleFromFindIndex = Data.FindMatchType.ladder
    _M.setBattleFromSceneId(ClientData.SceneId.find)
    
    return input
end

function _M.genInputFromExpeditionExResp(resp, expExData)
    local input = _M.genInputFromResp(resp)

    if expExData then
        local pbExpeditionEx = expExData
        ClientData._expeditionNpcInfos = {}
        for i = 1, #pbExpeditionEx.troops do
            local player = {_level = pbExpeditionEx.troops[i].level, _challengeCount = pbExpeditionEx.troops[i].chanllenge_count}
            table.insert(ClientData._expeditionNpcInfos, player)
        end
        if pbExpeditionEx:HasField("boss") then
            local pb = pbExpeditionEx.boss
            if ClientData._expeditionBossInfo == nil then ClientData._expeditionBossInfo = {} end
            ClientData._expeditionBossInfo._challengeCount = pb.chanllenge_count
        end
        ClientData._expeditionCurNpc = pbExpeditionEx.cur_npc
    end
    
    input._battleType = resp.type == Battle_pb.PB_BATTLE_EXPEDITION_EX_BOSS and Data.BattleType.expedition_ex_boss or Data.BattleType.expedition_ex
    input._sceneType = Data.BattleSceneType.gold_scene
    
    -- Back to exepdition scene after battle
    ClientData._battleFromCopy = {_type = Data.CopyType.expedition_ex}
    _M.setBattleFromSceneId()

    return input
end

function _M.genRecommendTrainInput(oriInput)
    local input = {}
    
    input._type = oriInput._type
    input._timestamp = 0
    input._copyId = oriInput.copy_id
    input._levelId = oriInput.level_id
    input._isOppoOnline = false
    input._isAttacker = true

    input._isWatcher = false
    
    input._player, input._opponent = {}, oriInput._player
    input._player._usedCards, input._opponent._usedCards = {}, {}
    input._player._name, input._player._level, input._player._vip, input._player._avatar, input._player._region = P._name or "", P._level or 0, P._vip or 0, P._avatar or 0, P._rid
    input._player._avatarFrame, input._player._cardBackId = P._avatarFrameId, P._cardBackId
    input._player._isNpc = false
    
    local curTroopCards = P._playerCard:getTroop(P._curTroopIndex, true)
    input._player._troopCards, input._player._troopLevels = _M.troopToPbtroop(curTroopCards)
    input._player._troopSkins = {}
    input._player._fortressHp = 8000

    input._player._crown = P._crown

    input._player._avatarFrameCount = 0
    
    input._randomSeed = math.random(65536)

    _M._isOppoOnline = input._isOppoOnline
    input._battleType = Data.BattleType.recommend_train

    input._sceneType = Data.BattleSceneType.gold_scene
    _M.setBattleFromSceneId(ClientData.SceneId.city)
    
    return input
end

function _M.genInputFromReplayResp(resp)
    local input
    if resp.type == Battle_pb.PB_BATTLE_CHAPTER or resp.type == Battle_pb.PB_BATTLE_NPC then
        input = _M.genInputFromAttackResp(resp)
        input._replayingLog = nil
    elseif resp.type == Battle_pb.PB_BATTLE_EXPEDITION_EX or resp.type == Battle_pb.PB_BATTLE_EXPEDITION_EX_BOSS then
        input = _M.genInputFromExpeditionExResp(resp)
        input._replayingLog = nil
    elseif resp.type == Battle_pb.PB_BATTLE_WORLD_LADDER  then
        input = _M.genInputFromLadderPvpResp(resp)
        input._replayingLog = _M._replayingLog
    elseif resp.type == Battle_pb.PB_BATTLE_WORLD_LADDER_EX then
        input = _M.genInputFromLadderExPvpResp(resp)
        input._replayingLog = _M._replayingLog
    elseif resp.type == Battle_pb.PB_BATTLE_MATCH then
        input = _M.genInputFromMatchResp(resp)
        input._replayingLog = _M._replayingLog
    elseif resp.type == Battle_pb.PB_BATTLE_MASSWAR_MULTIPLE then
        input = _M.genInputFromGroupResp(resp)
        input._replayingLog = _M._replayingLog
    elseif resp.type == Battle_pb.PB_BATTLE_DARK then
        input = _M.genInputFromDarkResp(resp)
        input._replayingLog = _M._replayingLog
    end
   
    input._replayBattleType = input._battleType
    input._battleType = Data.BattleType.replay
    
    return input
end


function _M.genInputFromRecoverResp(resp, msg)
    local input = {}
    
    local fromSceneId = _M._fromSceneId

    if resp.type == Battle_pb.PB_BATTLE_CHAPTER or resp.type == Battle_pb.PB_BATTLE_NPC or resp.type == Battle_pb.PB_BATTLE_RESCUE or resp.type == Battle_pb.PB_BATTLE_CITY then
        input = _M.genInputFromAttackResp(resp)
    elseif resp.type == Battle_pb.PB_BATTLE_FRIEND then
        input = _M.genInputFromFriendBattleResp(resp)
    elseif resp.type == Battle_pb.PB_BATTLE_WORLD then
        input = _M.genInputFromActivityPvpResp(resp)
    elseif resp.type == Battle_pb.PB_BATTLE_WORLD_LADDER then 
        input = _M.genInputFromLadderPvpResp(resp)
    elseif resp.type == Battle_pb.PB_BATTLE_WORLD_LADDER_EX then
        input = _M.genInputFromLadderExPvpResp(resp)
    elseif resp.type == Battle_pb.PB_BATTLE_MATCH then 
        input = _M.genInputFromMatchResp(resp)
    elseif resp.type == Battle_pb.PB_BATTLE_MASSWAR_MULTIPLE then 
        input = _M.genInputFromGroupResp(resp)
    elseif resp.type == Battle_pb.PB_BATTLE_DARK then 
        input = _M.genInputFromDarkResp(resp)
    elseif resp.type == Battle_pb.PB_BATTLE_EXPEDITION_EX or resp.type == Battle_pb.PB_BATTLE_EXPEDITION_EX_BOSS  then
        if msg:HasExtension(World_pb.SglWorldMsg.world_get_expedition_ex_resp) then
            input = _M.genInputFromExpeditionExResp(resp, msg.Extensions[World_pb.SglWorldMsg.world_get_expedition_ex_resp])
        else
            input = _M.genInputFromExpeditionExResp(resp)
        end
        
    end
    
    input._needForward = (input._player._usedCards and #input._player._usedCards or 0) + (input._opponent._usedCards and #input._opponent._usedCards or 0) > 0
    _M.setBattleFromSceneId(fromSceneId)

    return input
end

function _M.genInputFromFriendBattleResp(resp)
    local input = _M.genInputFromResp(resp)

    input._battleType = Data.BattleType.PVP_friend
    input._sceneType = (resp.opponent_troop.info.id % 4) + 1

    return input
end

function _M.genInputFromGuidance(id)
    local guidance = Data._guidanceInfo[id]
    if guidance == nil then return nil end
    
    local input = {}

    input._type = nil    
    input._timestamp = 0
    input._levelId = nil
    input._isOppoOnline = false
    input._isAttacker = guidance._isAttacker == 1

    input._player, input._opponent = {}, {}
    input._player._name, input._player._level, input._player._vip = Str(guidance._selfNameSid), 0, 0
    input._opponent._name, input._opponent._level, input._opponent._vip = Str(guidance._oppoNameSid), 0, 0
    input._player._isNpc, input._opponent._isNpc = false, false

    input._player._troopCards, input._player._troopLevels, input._player._fortressHp, input._opponent._troopCards, input._opponent._troopLevels, input._opponent._fortressHp = _M.genGuidanceTroop(id)
    input._player._troopSkins, input._opponent._troopSkins = {}, {}
    
	input._player._usedCards, input._opponent._usedCards = guidance._usedCards, guidance._oppoUsedCards

    input._battleType = Data.BattleType.guidance
    input._sceneType = guidance._sceneType
    input._eventIds = guidance._event
    input._oppoEventIds = guidance._oppoEvent

    -- fix for video scene, remove event 22
    if id == 1 and not ClientData.isPlayVideo() then
       for i = 1, #input._oppoEventIds do
           if input._oppoEventIds[i] == 22 then
                table.remove(input._oppoEventIds, i)
                break
           end 
       end
    end

    input._conditionIds = guidance._conditions

    input._needForward = guidance._needForward ~= 0
    
    input._player._avatar, input._opponent._avatar = 1, 201

    input._randomSeed = 0
    
    return input
end

function _M.genInputFromTest(battleType, param)
    local info, input = Data._testInfo, {}

    input._type = nil    
    input._timestamp = 0
    input._levelId = nil
    input._isOppoOnline = false
    input._isAttacker = true

    input._player, input._opponent = {}, {}
    input._player._name, input._player._level, input._player._vip = "Attacker", 0, 0
    input._opponent._name, input._opponent._level, input._opponent._vip = "Defender", 0, 0
    input._player._isNpc, input._opponent._isNpc = true, true
     
    input._player._troopCards, input._player._troopLevels, input._opponent._troopCards, input._opponent._troopLevels = _M.genTestTroop(id)
    input._player._troopSkins, input._opponent._troopSkins = {}, {}
    input._player._fortressHp, input._opponent._fortressHp = info["_attackerFortressHp"], info["_defenderFortressHp"]
    input._player._usedCards, input._opponent._usedCards = {}, {}
    input._eventIds, input._oppoEventIds = info["_attackerEvents"], info["_defenderEvents"]
	
    input._battleType = battleType
    if battleType == Data.BattleType.test then
        input._sceneType = 11--Data.BattleSceneType.country_scene_wei
        input._randomSeed = math.random(65536)
        
    elseif battleType == Data.BattleType.replay then
        input._sceneType = Data.BattleSceneType.exp_scene
        
        if info["_attackerUsedCards"][1] ~= 0 or #info["_attackerUsedCards"] > 1 then input._player._usedCards = info["_attackerUsedCards"] end
        if info["_defenderUsedCards"][1] ~= 0 or #info["_defenderUsedCards"] > 1 then input._opponent._usedCards = info["_defenderUsedCards"] end
        
        input._replayingLog = { _isAttack = true, _player = {_name = "replayPlayer", _level = 12, _trophy = 2, _avatar = 1001}, _opponent = {_name = "replayPlayer", _level = 12, _trophy = 2, _avatar = 1001} }
        
        input._randomSeed = math.random(65536)

    end

    input._player._avatar, input._opponent._avatar = 301, 201
    input._player._crown, input._opponent._crown = {_infoId = 7201, _num = 1}, {_infoId = 7204, _num = 2}

    _M._isOppoOnline = false

    return input
end

function _M.genInputFromUnitTest()
    local input = {}

    input._battleType = Data.BattleType.unittest
    input._type = nil    
    input._timestamp = 0
    input._levelId = nil
    input._isOppoOnline = false
    input._isAttacker = true

    input._player, input._opponent = {}, {}
    input._player._name, input._player._level, input._player._vip = "Attacker", 1, 0
    input._opponent._name, input._opponent._level, input._opponent._vip = "Defender", 1, 0
    input._player._isNpc, input._opponent._isNpc = true, true
     
    input._player._troopCards, input._player._troopLevels, input._player._troopSkins, input._opponent._troopCards, input._opponent._troopLevels, input._opponent._troopSkins = {}, {}, {}, {}, {}, {}
    input._player._fortressHp, input._opponent._fortressHp = 8000, 8000
    input._player._usedCards, input._opponent._usedCards = {}, {}
    input._eventIds, input._oppoEventIds = {}, {}
	
    input._sceneType = 11
    input._randomSeed = 0

    input._player._avatar, input._opponent._avatar = 301, 201
    
    _M._isOppoOnline = false

    return input
end

-- sync helper functions

function _M.setNeedSyncDataForCardListScenes()
    local BaseScene = require("BaseScene")
    for i = 1, #BaseScene._sceneList do
        local scene = BaseScene._sceneList[i]
        if scene ~= lc._runningScene and 
            (scene._sceneId == _M.SceneId.manage_troop or 
             scene._sceneId == _M.SceneId.factory_monster or
             scene._sceneId == _M.SceneId.factory_trap or
             scene._sceneId == _M.SceneId.stable or
             scene._sceneId == _M.SceneId.factory_magic or
             scene._sceneId == _M.SceneId.market or
             scene._sceneId == _M.SceneId.city) then
            scene._needSyncData = true
        end
    end
end

-- res helper functions

function _M.unloadLoadingRes(isAllPath)
    local removeTextures = function(path)
        local getFullPath = function(file)
            return path and path..file or lc.File:fullPathForFilename(file)
        end

        lc.TextureCache:removeTextureForKey(getFullPath("res/updater/loading_"..ClientData.getAppId()..".jpg"))
        lc.TextureCache:removeTextureForKey(getFullPath("res/updater/loading.jpg"))
        lc.TextureCache:removeTextureForKey(getFullPath("res/updater/loading1.jpg"))
        lc.TextureCache:removeTextureForKey(getFullPath("res/updater/loading_djlx.jpg"))
        
        lc.FrameCache:removeSpriteFramesFromFile("res/updater/loading.plist")
        lc.FrameCache:removeSpriteFramesFromFile(getFullPath("res/updater/loading.plist"))
        lc.TextureCache:removeTextureForKey(getFullPath("res/updater/loading.pvr.ccz"))
        
        lc.TextureCache:removeTextureForKey(getFullPath(string.format("res/jpg/img_loading_%s.jpg", lc.App:getChannelName())))
        lc.TextureCache:removeTextureForKey(getFullPath("res/jpg/load_btn_agreement.jpg"))
        lc.TextureCache:removeTextureForKey(getFullPath("res/jpg/load_btn_server.jpg"))

        ClientData.unloadDragonBones('loading')
    end

    if isAllPath then
        for _, path in ipairs(lc.File:getSearchPaths()) do
            removeTextures(path)
        end
    else
        removeTextures()
    end
end

function _M.unloadBattleRes()
    ClientData.unloadLCRes({"battle.jpm", "battle.png.sfb"})
    
    for index = 1, Data.BattleSceneType.count do
        local str = string.format("bat_scene_%d", index)
        ClientData.unloadLCRes({str..".jpm", str..".png.sfb"})
        lc.TextureCache:removeTextureForKey(string.format("res/bat_scene/bat_scene_%d_bg.jpg", index))
    end
    
    _M.unloadAllAudio()
    _M.unloadAllDragonBones()
    _M.unloadAllParticle()
    _M.unloadFonts(true)
end

function _M.unloadCityUnionRes()
    V.releaseMenuUI()
    V.releaseResourceUI()
    V.releaseActiveIndicator()
    V.releaseChatPanel()

    _M.unloadCityRes()
    _M.unloadUnionRes()

    _M.unloadFonts(false)
end

function _M.unloadCityRes()
    lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/city_bg_01.jpg"))
    ClientData.unloadLCRes({"city.jpm", "city.png.sfb"})
    
    ClientData.unloadLCRes({"activity.jpm", "activity.png.sfb"})
    ClientData.unloadLCRes({"copy.jpm", "copy.png.sfb"})
    ClientData.unloadLCRes({"travel.jpm", "travel.png.sfb"})

    for i = 1, 10 do
        local chapterName = string.format('chapter_%02d', i)
        ClientData.unloadLCRes({chapterName..".jpm", chapterName..".png.sfb"})
    end
    
    _M.unloadAllAudio()
    _M.unloadAllDragonBones()
    _M.unloadAllParticle()
end

function _M.unloadUnionRes()
    --lc.App:unloadRes({"union_war.pvr.ccz", "union_war.pvr.ccz.sfb"})
    --lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/union_world_bg.jpg"))
    --lc.TextureCache:removeTextureForKey(lc.File:fullPathForFilename("res/jpg/union_war_bg.jpg"))
    
    _M.unloadAllAudio()
    _M.unloadAllDragonBones()
    _M.unloadAllParticle()
end

function _M.unloadAllDragonBones()
    if Data._dragonBonesList == nil then
        local data = lc.readFile("res/effects/list.txt")
        Data._dragonBonesList = string.splitByChar(data, '\n')
    end

    local notify = lc.File:isPopupNotify()
    lc.File:setPopupNotify(false)
    for _, file in ipairs(Data._dragonBonesList) do
        _M.unloadDragonBones(file)
    end
    lc.File:setPopupNotify(notify)

    _M._dragonBonesTexture = {}
end

function _M.unloadDragonBones(name)
    local fname = name..".png"
    if lc.TextureCache:getTextureForKey(fname) ~= nil then
        cc.DragonBonesNode:removeTextureAtlas(name)
        lc.TextureCache:removeTextureForKey(fname)
        lc.log("unload dragonbones  "..fname)
    end    
end

function _M.unloadAllParticle()
    if Data._particleList == nil then
        local data = string.gsub(lc.readFile("res/particle/list.txt"), '\r', '')
        Data._particleList = string.splitByChar(data, '\n')
    end

    local notify = lc.File:isPopupNotify()
    lc.File:setPopupNotify(false)
    for _, file in ipairs(Data._particleList) do
        local fname = "res/particle/"..file..".png"
        if lc.TextureCache:getTextureForKey(fname) ~= nil then
            lc.TextureCache:removeTextureForKey(fname)
            lc.log("unload paritcle  "..fname)
        end
    end
    lc.File:setPopupNotify(notify)

    _M._particleTexture = {}
end

function _M.unloadAllAudio()
    if Data._batAudioList == nil then
        local data = string.gsub(lc.readFile("res/bat_audio/list.txt"), '\r', '')
        Data._batAudioList = string.splitByChar(data, '\n')
    end

    -- remove all audio
    for _, file in ipairs(Data._batAudioList) do
        local fname = "res/bat_audio/"..file..".mp3"
        cc.SimpleAudioEngine:getInstance():unloadEffect(fname)
    end

    for i = AUDIO.E_BATTLE_OPEN, AUDIO.M_BATTLE - 1 do
        lc.Audio.unloadAudio(i)
    end

    lc.log("unload audio")
end

function _M.unloadFonts(isBattle)
    local fontNames = isBattle and V.BMFONTS_BATTLE or V.BMFONTS_CITY
    for _, fontName in ipairs(fontNames) do
        local strs = string.split(fontName, ".")
        local textureName = strs[1]..".png"
        if lc.TextureCache:getTextureForKey(textureName) ~= nil then
            lc.TextureCache:removeTextureForKey(textureName)
            lc.log("unload fonts  "..textureName)
        end
    end
end

function _M.preloadFonts(isBattle)
    local fontNames = isBattle and V.BMFONTS_BATTLE or V.BMFONTS_CITY
    for _, fontName in ipairs(fontNames) do
        local label = cc.Label:createWithBMFont(fontName, "")
    end
end

-- union help functions

function _M.getUnionErrorStr(error)
    if error == Data.ErrorType.leader_operate then
        return Str(STR.UNION_LEADER_OPERATE)        
    elseif error == Data.ErrorType.elder_operate then
        return Str(STR.UNION_ELDER_OPERATE)
    elseif error == Data.ErrorType.rookie_operate then
        return Str(STR.UNION_ROOKIE_OPERATE)
    elseif error == Data.ErrorType.union_operate then
        return Str(STR.UNION_UNION_OPERATE)
    end
    
    return ""
end
