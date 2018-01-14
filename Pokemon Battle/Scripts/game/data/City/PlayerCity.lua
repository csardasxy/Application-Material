local Fixity = require "Fixity"

local _M = class("PlayerCity")

function _M:ctor()
    self._fixities = {}
end

function _M:clear()
    self._fixities = {}
end

function _M:init(pbCity)
    local id = 1    
    for k, v in pairs(Data._fixityInfo) do
        local count = #v._pos01
        for i = 1, count do
            -- Filter invalid fixities
            if v._unlockLevel[i] >= 200 then
                break
            end

            if k > Data.FixityId.activity then
                local act = P._playerActivity._actFestivalTask
                if act == nil or act._param[1] ~= k then
                    break
                end
            end

            local f = Fixity.new(k)
            table.insert(self._fixities, f)
        
            if k == Data.FixityId.farmland then
                f._timestamp = pbCity.last_collect_grain / 1000

            elseif k == Data.FixityId.residence then
                f._timestamp = pbCity.last_collect_gold / 1000

            elseif k == Data.FixityId.guard then
                for i, guard in ipairs(pbCity.guards) do
                    local hero = P._playerCard._monsters[guard.hero_id]
                    if hero then
                        hero._taskId = 0
                        table.insert(f._guards, {_hero = hero, _timestamp = guard.timestamp / 1000, _span = guard.span / 1000})
                    end
                end
                self._guardFixity = f
            end
        end
    end
    table.sort(self._fixities, function(a, b) return a._infoId < b._infoId end)

    for i = 1, #self._fixities do
        self._fixities[i]._id = i                      
        self._fixities[i]._isLock = (P._level < self:getUnlockLevel(self._fixities[i]))      
    end
end

function _M:getGrainTime()    
    for k, v in pairs(self._fixities) do
        if v._infoId == Data.FixityId.farmland and not v._isLock then
            return v:getFullGrainTimestamp() - ClientData.getCurrentTime()
        end
    end    
    
    return 0
end

function _M:getGoldTime()
    for k, v in pairs(self._fixities) do
        if v._infoId == Data.FixityId.residence and not v._isLock then
            return v:getFullGoldTimestamp() - ClientData.getCurrentTime()
        end
    end    
    
    return 0
end

function _M:getFixityCount(infoId)
    local count = 0
    for k, v in pairs(self._fixities) do
        if v._infoId == infoId then
            count = count + 1
        end
    end
    return count
end

function _M:getUnlockLevel(fixity)
    local info = fixity._info
    if #info._unlockLevel == 1 then
        return info._unlockLevel[1]
    else
        local index = 0
        for _, f in ipairs(self._fixities) do
            if f._infoId == fixity._infoId then
                index = index + 1
                if f == fixity then
        	        return info._unlockLevel[index]
                end
            end
        end
    end
    
    return 0
end

function _M:getUnlockFixityNumber(infoId, level)
    level = level or P._level

    local info, number = Data._fixityInfo[infoId], 0
    for _, unlockLevel in ipairs(info._unlockLevel) do
        if level >= unlockLevel then
            number = number + 1
        end            
    end
    
    return number
end

function _M:tryUnlockFixities(timestamp)
    local unlockFarmland = {}
    local unlockResidence = {}
    local unlockFixityId = {}  
    local totalGrain = 0
    local totalGold = 0  
    for k, v in pairs(self._fixities) do
        if v._isLock then
            if P._level >= self:getUnlockLevel(v) then                
                v._isLock = false
                v._timestamp = timestamp
                v:sendFixityDirty()
                
                unlockFixityId[v._infoId] = v

                --[[
                if v._infoId == Data.FixityId.market or v._infoId == Data.FixityId.duel then
                    local eventCustom = cc.EventCustom:new(Data.Event.push_notice)
                    eventCustom._title = Str(STR.UNLOCK)
                    eventCustom._content = string.format(Str(STR.BRACKETS_S), Str(v._info._nameSid))..Str(STR.UNLOCKED)
                    lc.Dispatcher:dispatchEvent(eventCustom)    
                end
                ]]
            end
        else
            if v._infoId == Data.FixityId.farmland then
                totalGrain = totalGrain + v:getRes(timestamp - v._timestamp)                
                table.insert(unlockFarmland, v)
            elseif v._infoId == Data.FixityId.residence then
                totalGold = totalGold + v:getRes(timestamp - v._timestamp)
                table.insert(unlockResidence, v)
            end            
        end
    end

    for k, v in pairs(unlockFixityId) do
        if k == Data.FixityId.farmland then
            local remainRes = totalGrain / (#unlockFarmland + 1)
            for i = 1, #unlockFarmland do
                unlockFarmland[i]._timestamp = timestamp
                unlockFarmland[i]._remainRes = remainRes        
            end
            v._remainRes = remainRes
        elseif k == Data.FixityId.residence then
            local remainRes = totalGold / (#unlockResidence + 1)
            for i = 1, #unlockResidence do
                unlockResidence[i]._timestamp = timestamp
                unlockResidence[i]._remainRes = remainRes
            end
            v._remainRes = remainRes
        end
    end
end

function _M:getBlacksmithUnlockLevel()
    return Data._fixityInfo[Data.FixityId.blacksmith]._unlockLevel[1]
end

function _M:getStableUnlockLevel()
    return Data._fixityInfo[Data.FixityId.stable]._unlockLevel[1]
end

function _M:getLibraryUnlockLevel()
    return Data._fixityInfo[Data.FixityId.library]._unlockLevel[1]
end

function _M:getMarketUnlockLevel()
    return Data._fixityInfo[Data.FixityId.market]._unlockLevel[1]
end

function _M:getGuardUnlockLevel()
    return Data._fixityInfo[Data.FixityId.guard]._unlockLevel[1]
end

function _M:getUnionUnlockLevel()
    return Data._fixityInfo[Data.FixityId.union]._unlockLevel[1]
end

function _M:getFixity(infoId)
    for k, v in pairs(self._fixities) do
        if v._infoId == infoId then
            return v
        end
    end
end

function _M:getUnlockFarmlands()
    local farmlands = {}
    for i = 1, #self._fixities do
        if self._fixities[i]._infoId == Data.FixityId.farmland then
            if not self._fixities[i]._isLock then
                table.insert(farmlands, self._fixities[i])
            end
        end
    end

    return farmlands
end

function _M:getUnlockResidences()
    local residences = {}
    for i = 1, #self._fixities do
        if self._fixities[i]._infoId == Data.FixityId.residence then
            if not self._fixities[i]._isLock then
                table.insert(residences, self._fixities[i])
            end
        end
    end

    return residences
end



return _M
