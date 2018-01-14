local _M = class("PlayerActivity")

function _M:ctor()

end

function _M:init(pb)
    if pb then
        self._ghost = pb.ghost
        self._loginDays = pb.login
        self._chargeIngot = pb.charge
        self._chargeDays = pb.charge_ex
        self._lastChargeTimestamp = pb.last_charge_ex
        self._rebateIngot = pb.rebate
        self._consumeIngot = pb.consume

        if pb:HasField("bonus") then
            local valueMap, claimedMap = P._playerBonus.hashPbBonus(pb.bonus)            
            for _, bonus in ipairs(P._playerBonus._bonusActivity) do
                bonus._value = valueMap[bonus._info._cid] or bonus._value
                bonus._isClaimed = claimedMap[bonus._infoId] or bonus._isClaimed
            end
        end

        self._productBuyCounts = {}
        for _, bundle in ipairs(pb.bundles) do
            self._productBuyCounts[bundle.info_id] = bundle.num
        end        
    end

    self._actCharge = ClientData.isActivityValid(ClientData.getActivityByType(603))

    --[[
    -- Check special activities
    for _, info in pairs(Data._activityInfo) do
        info.getTypes = function(info, index)
            local mainType = math.floor(info._type[index or 1] / 100)
            local subType = info._type[index or 1] - mainType * 100
            return mainType, subType
        end

        info._beginTimestamp = self:parseTime(info._beginTime)
        info._endTimestamp = self:parseTime(info._endTime)

        if self:isValid(info) and self:isVisible(info) then
            local mainType, subType = info:getTypes()
            if mainType == Data.ActType.forum then
                if subType == 6 then
                    self._actNewRegionLegend = info
                end

            elseif mainType == Data.ActType.market then
                if subType == 1 then
                    self._actMarket = info
                elseif subType == 2 then
                    self._actMarketOff = info
                end

            elseif mainType == Data.ActType.score then
                self._actScore = info

                if subType == Data.ResType.blood_jade then
                    self._actFragRecruit = info
                end

            elseif mainType == Data.ActType.consume then
                self._actConsume = info

            elseif mainType == Data.ActType.charge then
                if subType == 2 then
                    self._actDailyChargeTimes = info

                elseif subType == 3 then
                    self._actCharge = info

                elseif subType == 4 then
                    self._actRebate = info

                elseif subType == 5 then
                    self._actChargeDays = info

                elseif subType == 6 then
                    self._actChargeBonus = info

                end

            elseif mainType == Data.ActType.weekend then
                if subType == 1 or subType == 2 then
                    self._actFlag2x = info
                end

            elseif mainType == Data.ActType.chapter then
                for i = 1, #info._type do
                    _, subType = info:getTypes(i)
                    if subType == 1 then
                        self._actNormalFrag2x = info

                    elseif subType == 2 then
                        self._actMidFrag2x = info

                    elseif subType == 3 then
                        self._actHardFrag2x = info

                    elseif subType == 8 then
                        self._actGuardTower2x = info

                    elseif subType == 10 then
                        self._actContributeYubi2x = info

                    end
                end

            elseif mainType == Data.ActType.festival then
                if subType == 1 then
                    if info._param[1] > 0 then
                        self._actFestivalTask = info
                    end
                end

            elseif mainType == Data.ActType.tavern then
                if subType == 1 then
                    self._actCountryRecruit = info
                end

            elseif mainType == Data.ActType.split then
                if subType == 2 then
                    self._actSplit = info
                end

            elseif mainType == Data.ActType.gift then
                self._actGift = info

            end
        end
    end
    ]]
end

function _M:clear()
    self._actNewRegionLegend = nil
    self._actMarket = nil
    self._actMarketOff = nil
    self._actScore = nil
    self._actConsume = nil
    self._actDailyChargeTimes = nil
    self._actCharge = nil
    self._actRebate = nil
    self._actChargeDays = info
    self._actChargeBonus = info
    self._actFlag2x = nil
    self._actNormalFrag2x = nil
    self._actMidFrag2x = nil
    self._actHardFrag2x = nil
    self._actGuardTower2x = nil
    self._actContributeYubi2x = nil
    self._actFestivalTask = nil
    self._actCountryRecruit = nil
    self._actFragRecruit = nil
    self._actSplit = nil
    self._actGift = nil
end

function _M:genActivityKey(info)
    return info._type[1]..info._beginTime..info._endTime
end

function _M:parseTime(timeStr)
    if timeStr == nil or timeStr == '' then
        return 0
    end

    local day = tonumber(timeStr)
    if day then
        return P._serverOpenTimestamp + (day - 1) * Data.DAY_SECONDS
    else
        return ClientData.parseTimeStr(timeStr)
    end
end

function _M:isVisible(info)
    if ClientData._cfg.testActivity then
        return true
    end

    -- Check long-term activities
    if info._type[1] == 401 then
        if P._playerBonus._bonusLogin[1]._value > 8 then
            return false
        end
    end

    local time = info._visibleTime
    if time == '' then
        return true
    end

    -- Check visible time
    local times = string.splitByChar(time, '-')
    local curTime = ClientData.getCurrentTime()
    if self:parseTime(times[1]) <= curTime then
        if times[2] then
            return self:parseTime(times[2]) >= curTime
        else
            return true
        end
    end
    
    return false
end

function _M:hasVisibleActivities()
    for _, info in pairs(Data._activityInfo) do
        if self:isVisible(info) then
            return true
        end
    end

    return false
end

function _M:isValid(info)
    local curTime = ClientData.getCurrentTime()
    return info._beginTimestamp <= curTime and (curTime < info._endTimestamp or info._endTimestamp == 0)
end

function _M:getNewActivityCount()
    local count = 0
    for _, info in pairs(Data._activityInfo) do
        if self:isActivityNew(info) then
            count = count + 1            
        end
    end

    return count
end

function _M:isActivityNew(info)
    if not self:isValid(info) or not self:isVisible(info) then
        return false
    end

    info = (type(info) == "number" and Data._activityInfo[info] or info)
    local key = self:genActivityKey(info)
    return lc.readConfig(key, 0) == 0
end

function _M:readActivity(info)
    if not self:isValid(info) or not self:isVisible(info) then
        return
    end

    info = (type(info) == "number" and Data._activityInfo[info] or info)
    local key = self:genActivityKey(info)
    lc.writeConfig(key, ClientData.getCurrentTime())
end

function _M:checkChargeDays()
    if self._actChargeBonus == nil then return end

    local _, day = ClientData.getServerDate()
    local _, lastDay = ClientData.getServerDate(self._lastChargeTimestamp)
    if day ~= lastDay then
        self._chargeDays = self._chargeDays + 1
        self._lastChargeTimestamp = ClientData.getCurrentTime()
    end    
end

function _M:getActivitiesToShow()
    local activities = {}
    
    if not ClientData.isAppStoreReviewing() then
        if not ClientData.isActivityShowed(Data.PurchaseType.return_to_game) and ClientData.isReturnToGame() and not ClientData.isReturnToGameClaimed() then
            table.insert(activities, Data.PurchaseType.return_to_game)
        end

        for i = Data.PurchaseType.limit_3, Data.PurchaseType.limit_5 do
            if not ClientData.isActivityShowed(i) and ClientData.isActivityValidByParam(i) then
                table.insert(activities, i)
            end
        end

        local purchaseTypes = lc.PLATFORM == cc.PLATFORM_OS_ANDROID and {Data.PurchaseType.limit_2, Data.PurchaseType.limit_1} or {Data.PurchaseType.limit_1, Data.PurchaseType.limit_2}
        for i = 1, #purchaseTypes do
            local purchaseType = purchaseTypes[i]
            if not ClientData.isActivityShowed(purchaseType) and ClientData.isActivityValidByParam(purchaseType) and not ClientData.isRecharged(purchaseType) and ClientData.isRecharged(Data.PurchaseType.package_1) then
                table.insert(activities, purchaseType)
            end
        end

        if not ClientData.isActivityShowed(Data.PurchaseType.ad_recharge) and not ClientData.isGemRecharged() then
            table.insert(activities, Data.PurchaseType.ad_recharge)
        end

        if not ClientData.isActivityShowed(Data.PurchaseType.ad_package) and not ClientData.isRecharged(Data.PurchaseType.package_1) then
            table.insert(activities, Data.PurchaseType.ad_package)
        end

    end

    return activities 
end

PlayerActivity = _M
return _M