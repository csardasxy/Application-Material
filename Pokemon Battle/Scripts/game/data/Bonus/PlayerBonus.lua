local Bonus = require "Bonus"

local _M = class("PlayerBonus")

function _M:ctor()
    self._bonuses = {}
    self._serverBonuses = {}
    self._sendBonuses = {}
    self._bonusCount = 0
    self._achievePoint = 0
    
    lc.addEventListener(Data.Event.daily_active_dirty, function(event)        
        self:onDailyActiveDirty()
    end)

    lc.addEventListener(Data.Event.level_dirty, function(event)        
        self:onLevelDirty()
    end)

    lc.addEventListener(Data.Event.card_dirty, function(event)
        self:onCardDirty(event._infoId)
    end)

    lc.addEventListener(Data.Event.card_add, function(event)        
        self:onCardAdd(event._infoId)
    end)

    lc.addEventListener(Data.Event.recharge_success, function(event)        
        if event._type == Data.PurchaseType.month_card_1 or event._type == Data.PurchaseType.month_card_2 then
            self:onMonthCardDirty(event._type)
        end
    end)    
    
    lc.addEventListener(Data.Event.chapter_level_dirty, function(event)        
        self:onChapterLevelDirty(event._levelId)
    end)

    lc.addEventListener(Data.Event.city_sweep, function(event)        
        self:onNoviceTaskDirty(2, event._times)
    end)

    lc.addEventListener(Data.Event.hero_guard_dirty, function(event)
        if event._data._taskId == 0 then
            self:onNoviceTaskDirty(3)
        end
    end)

    lc.addEventListener(Data.Event.pk_join, function(event)        
        self:onNoviceTaskDirty(5)
    end)

    lc.addEventListener(Data.Event.hero_lottery, function(event)
        self:onNoviceTaskDirty(4, event._times)
    end)
        
    lc.addEventListener(Data.Event.mix_hero, function(event)        
        self:onNoviceTaskDirty(7)
    end)

    ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
end

function _M:clear()
    self._bonusCount = 0

    self._bonuses = {}
    self._serverBonuses = {}
    self._sendBonuses = {}

    self:stopSchedule()
end

function _M.splitBonus(bonuses, genBonusCallback)
    local claimableBonuses, unclaimBonuses, claimedBonuses = {}, {}, {}
    for i, bonus in ipairs(bonuses) do
        local data = genBonusCallback and genBonusCallback(i, bonus) or bonus
        if bonus._value >= bonus._info._val then
            if bonus._isClaimed then
                table.insert(claimedBonuses, data)
            else
                table.insert(claimableBonuses, data)
            end
        else
            table.insert(unclaimBonuses, data)
        end
    end

    return claimableBonuses, unclaimBonuses, claimedBonuses
end

function _M.hashPbBonus(pb)
    local valueMap, claimedMap = {}, {}
    for _, bonus in ipairs(pb.bonuses) do
        valueMap[bonus.cid] = bonus.value
    end

    for _, id in ipairs(pb.claimed) do
        claimedMap[id] = true
    end
    return valueMap, claimedMap
end

function _M:init(pbBonus , isInit)
    self._fundResetCount = pbBonus.task_reset_count or 0
    local valueMap, claimedMap = _M.hashPbBonus(pbBonus)
    if isInit==nil then isInit=true end

    self._bonusLord = {}
    self._bonusLevel = {}
    self._bonusChapter = {}
    self._bonusCharacter = {}
    self._bonusPassChapter = {}
    self._bonusEquip = {}
    self._bonusHorse = {}
    self._bonusBook = {}    
    self._bonusDailyTask = {}
    self._bonusGrainTask = {}
    if isInit then
        self._bonusOnlineTask = {}
    end

    self._bonusNoviceTask = {}
    self._bonusFacebookTask = {}

    self._bonusWeekCheckin = {}    
    self._bonusLogin = {}
    self._bonusMonthCheckin = {}
    self._bonusVipDaily = {}    
    self._bonusMonthCard = {}
    self._bonusMonthCardBought = {}
    self._bonusMonthCardPackage = {}

    self._bonusActivity = {}

    self._bonusFundLevel = {}
    self._bonusFundAll = {}

    self._bonusInvite = {}

    self._bonusClashTarget = {}

    self._bonusClash = {}
    self._bonusClashConti = {}
    self._bonusClashLegacy = {}
    self._bonusClashLocal = {}
    self._bonusClashZone = {}

    self._bonusArenaOnce = {}
    self._bonusArenaAll = {}
    self._bonusArena12 = {}

    self._bonusGoldGain = {}
    self._bonusGoldCost = {}
    self._bonusGemCost = {}
    self._bonusBottle = {}

    self._bonusCardSr = {}
    self._bonusCardUr = {}
    self._bonusCardPackage = {}

    self._bonusTeach = {}

    self._bonusDailyActive = {}

    self._loginDayBonus = {}

    self._bonusFundTasks = {}
    self._changedFundTasks = {}
    self._allFundTasks = {}

    self._anyLevelBonus = {}

    self._clashBonuses =
    {
        self._bonusClash,
        self._bonusClashConti,
        self._bonusClashLegacy,
        self._bonusClashLocal,
        self._bonusClashZone,
    }

    self._arenaBonuses = 
    {
        self._bonusArenaOnce,
        self._bonusArenaAll,
        self._bonusArena12,
    }

    self._collectBonuses = 
    {
        self._bonusGoldGain,
        self._bonusCardSr,
        self._bonusCardUr,
        self._loginDayBonus,
        self._anyLevelBonus,
    }

    self._costBonuses = 
    {
        self._bonusGoldCost,
        self._bonusGemCost,
        self._bonusCardPackage,
        self._bonusBottle,
    }

    for k, v in pairs(Data._bonusInfo) do
        if v._cid > 0 or v._type > 0 then
            local bonus = Bonus.new(k)
            local type = bonus._type
            bonus._value = valueMap[v._cid] or bonus._value
            bonus._isClaimed = claimedMap[k] or bonus._isClaimed

            bonus._isDefaultClaimable = (bonus._value >= v._val)
            if type~=Data.BonusType.online or isInit==true then
                self._bonuses[k] = bonus
            end

            if type == Data.BonusType.lord then
                if v._cid == 101 then
                    table.insert(self._bonusLord, bonus)
                else
                    table.insert(self._bonusChapter, bonus)
                end

            elseif type == Data.BonusType.level then
                table.insert(self._bonusLevel, bonus)

            elseif type == Data.BonusType.character then
                table.insert(self._bonusCharacter, bonus)
                      
            elseif type == Data.BonusType.equip  then
                table.insert(self._bonusEquip, bonus)
                      
            elseif type == Data.BonusType.book then
                table.insert(self._bonusBook, bonus)
                        
            elseif type == Data.BonusType.horse then
                table.insert(self._bonusHorse, bonus)   
                         
            elseif type == Data.BonusType.daily_task then
                table.insert(self._bonusDailyTask, bonus)
                
            elseif type == Data.BonusType.week_checkin  then
                table.insert(self._bonusWeekCheckin, bonus)                                 
                            
            elseif type == Data.BonusType.login then
                table.insert(self._bonusLogin, bonus)
                
            elseif type == Data.BonusType.vip_daily then
                if (v._cid >= 1120 and v._cid <= 1126) or (v._cid >= 1304 and v._cid <= 1306) then
                    self._packageBonus = self._packageBonus or {}
                    self._packageBonus[v._cid] = bonus
                elseif v._cid >= 1401 and v._cid <= 1402 then
                    self._limitBonus = self._limitBonus or {}
                    self._limitBonus[v._cid] = bonus
                else
                    table.insert(self._bonusVipDaily, bonus)
                end    
            
            elseif type == Data.BonusType.month_card then
                if v._cid == 1321 or v._cid == 1322 then
                    self._bonusMonthCardBought[v._cid - 1320] = bonus
                elseif v._cid >= 1308 and v._cid <= 1311 then
                    self._bonusMonthCardPackage[v._cid - 1307] = bonus
                else
                    table.insert(self._bonusMonthCard, bonus)
                end

            elseif type == Data.BonusType.grain then
                table.insert(self._bonusGrainTask, bonus)

            elseif type == Data.BonusType.online then
                if v._id == 4009 then
                    self._cardBonus = bonus
                elseif isInit then
                    table.insert(self._bonusOnlineTask, bonus)
                end
            
            elseif type == Data.BonusType.novice then
                table.insert(self._bonusNoviceTask, bonus)

            elseif type == Data.BonusType.activity then
                table.insert(self._bonusActivity, bonus)

            elseif type == Data.BonusType.pass_chapter then
                table.insert(self._bonusPassChapter, bonus)

            elseif type == Data.BonusType.fund_level then
                bonus._value = P:getMaxCharacterLevel()
                table.insert(self._bonusFundLevel, bonus)

            elseif type == Data.BonusType.fund_all then
                table.insert(self._bonusFundAll, bonus)

            elseif type == Data.BonusType.invite then
                if v._cid == 108 then
                    table.insert(self._bonusInvite, bonus)

                    local maxTimes = {50, 35, 20, 10, 5}
                    bonus._claimTimesMax = maxTimes[v._cid - 108 + 1]
                    bonus._claimTimes = 0
                elseif v._cid == 113 then
                    self._invitedBonus = bonus
                end

            elseif type == Data.BonusType.facebook then
                table.insert(self._bonusFacebookTask, bonus)

            elseif type == Data.BonusType.clash_target then
                table.insert(self._bonusClashTarget, bonus)

            elseif type ==Data.BonusType.clash then
                table.insert(self._bonusClash, bonus)

            elseif type ==Data.BonusType.clash_conti then
                table.insert(self._bonusClashConti, bonus)

            elseif type ==Data.BonusType.clash_legacy then
                table.insert(self._bonusClashLegacy, bonus)

            elseif type ==Data.BonusType.clash_local then
                table.insert(self._bonusClashLocal, bonus)

            elseif type ==Data.BonusType.clash_zone then
                table.insert(self._bonusClashZone, bonus)

            elseif type ==Data.BonusType.arena_once then
                table.insert(self._bonusArenaOnce, bonus)

            elseif type ==Data.BonusType.arena_all then
                table.insert(self._bonusArenaAll, bonus)

            elseif type ==Data.BonusType.arena_12 then
                table.insert(self._bonusArena12, bonus)

            elseif type ==Data.BonusType.gold_cost then
                table.insert(self._bonusGoldCost, bonus)

            elseif type ==Data.BonusType.gold_gain then
                table.insert(self._bonusGoldGain, bonus)

            elseif type ==Data.BonusType.gem_cost then
                table.insert(self._bonusGemCost, bonus)

            elseif type ==Data.BonusType.bottle then
                table.insert(self._bonusBottle, bonus)

            elseif type ==Data.BonusType.card_sr then
                table.insert(self._bonusCardSr, bonus)

            elseif type ==Data.BonusType.card_ur then
                table.insert(self._bonusCardUr, bonus)

            elseif type ==Data.BonusType.card_package then
                table.insert(self._bonusCardPackage, bonus)

            elseif type == Data.BonusType.teach then
                self._bonusTeach[bonus._infoId] = bonus

            elseif type == Data.BonusType.login_day then
                table.insert(self._loginDayBonus, bonus)

            elseif type == Data.BonusType.any_level then
                table.insert(self._anyLevelBonus, bonus)

            elseif type == Data.BonusType.daily_active then
                table.insert(self._bonusDailyActive, bonus)
                if not P._dailyActive and bonus._value then
                    P._dailyActive = bonus._value
                end

            elseif type == Data.BonusType.return_to_game then
                self._returnBonus = bonus

            elseif type == Data.BonusType.fund_task then
                self._allFundTasks[bonus._info._cid] = bonus
                if valueMap[bonus._info._cid] ~= nil and not bonus._isClaimed then
                    self._bonusFundTasks[bonus._info._cid] = bonus
                    self._changedFundTasks[bonus._info._cid] = bonus._info._cid
                end
            end
        end
    end

    -- Set month checkin bonus
    local _, _, month = ClientData.getServerDate()
    for _, info in pairs(Data._monthCheckinInfo) do
        if info._month == month then
            local bonus = self._bonuses[info._bonusId]
            bonus._checkinInfo = info            
            table.insert(self._bonusMonthCheckin, bonus)
        end
    end



    local bonuses =
    {
        self._bonusDailyTask,
        self._bonusLevel,
        self._bonusGrainTask,
        self._bonusOnlineTask,
        self._bonusWeekCheckin,        
        self._bonusLogin,
        self._bonusMonthCheckin,
        self._bonusVipDaily,        
        self._bonusMonthCard,
        self._bonusLord,
        self._bonusChapter,
        self._bonusCharacter,
        self._bonusEquip,
        self._bonusHorse,
        self._bonusBook,
        self._bonusClashTarget,
        self._bonusClash,
        self._bonusClashConti,
        self._bonusClashLegacy,
        self._bonusClashLocal,
        self._bonusClashZone,
        self._bonusArenaOnce,
        self._bonusArenaAll,
        self._bonusArena12,
        self._bonusGoldCost,
        self._bonusGoldGain,
        self._bonusGemCost,
        self._bonusBottle,
        self._bonusCardSr,
        self._bonusCardUr,
        self._bonusCardPackage,
        self._bonusTeach,
    }
    
    for _, bonus in ipairs(bonuses) do
        table.sort(bonus, function(a, b)
            if a._info._cid == b._info._cid then
                return a._info._val < b._info._val
            end

            return a._info._cid < b._info._cid
        end)
    end

    table.sort(self._bonusNoviceTask, function(a, b) return a._info._id < b._info._id end)

    table.sort(self._bonusDailyActive, function(a, b) return a._info._id < b._info._id end)

    -- Initial online bonus value
    for _, bonus in ipairs(self._bonusOnlineTask) do
        local prevBonus = bonus:getPrevBonus()
        if prevBonus and bonus._value < prevBonus._info._val then
            bonus._value = prevBonus._info._val
        end

        bonus._timestamp = ClientData.getCurrentTime()
    end

     self:startSchedule()

    -- Initial invite bonus
    for _, item in ipairs(pbBonus.items) do
        local bonus = self._bonuses[item.info_id]
        bonus._claimTimes = item.num

        if bonus._claimTimes >= bonus._claimTimesMax then
            bonus._isClaimed = true
        end
    end

    self:initIapCount(pbBonus)

    self:checkOnlineBonus()
end

function _M:startSchedule()
    self:stopSchedule()
    self._schedulerId = lc.Scheduler:scheduleScriptFunc(function(dt)
        self:checkOnlineBonus()
    end, 1, false)
end

function _M:stopSchedule()
    if self._schedulerId then
        lc.Scheduler:unscheduleScriptEntry(self._schedulerId)
        self._schedulerId = nil
    end
end

function _M:checkOnlineBonus()
    if self._bonusOnlineTask then
        for _, bonus in ipairs(self._bonusOnlineTask) do
            local prevBonus = bonus:getPrevBonus()
            if (prevBonus == nil or prevBonus._isClaimed) and (not bonus._isClaimed) then
                local curTime = ClientData.getCurrentTime()
                bonus._value = bonus._value + (curTime - bonus._timestamp)
                bonus._timestamp = curTime

                if bonus._value >= bonus._info._val then
                    bonus:sendBonusDirty()
                end

                break
            end
        end
    end

    if self._cardBonus and not self._cardBonus._isClaimed then
        self._cardBonus._value = math.floor((ClientData.getCurrentTime() - P._regTime) / 3600)
    end
end

function _M:getCommonBonusFlag(bonuses, cid)
    local number = 0
    for _, bonus in ipairs(bonuses) do
        if bonus._value >= bonus._info._val and (not bonus._isClaimed) and (cid == nil or bonus._info._cid == cid)then
            number = number + 1
        end
    end

    return number
end

function _M:getActivityBonusFlag()
    return self:getFirstRechargeBonusFlag() + self:getVipGiftBonusFlag()
end

function _M:getCheckinBonusFlag()
    --self:getVipDailyBonusFlag() +
    return self:getMonthCardBonusFlag() + self:getWeekCheckinBonusFlag() + self:getMonthCheckinBonusFlag() + self:getLoginBonusFlag() + self:getOnlineTaskBonusFlag()
end

function _M:getFundBonusFlag()
    return self:getFundLevelBonusFlag() + self:getFundAllBonusFlag()
end

function _M:getFirstRechargeFlag()
    local bonus = P._playerBonus._packageBonus[1120]
    if ClientData.isGemRecharged() and bonus._value >= bonus._info._val and (not bonus._isClaimed) then
        return 1
    end

    return 0
end

function _M:getRecharge7Flag()
    local bonus = P._playerBonus._packageBonus[1306]
    if bonus._value >= bonus._info._val and (not bonus._isClaimed) then
        return 1
    end

    return 0
end

function _M:getReturnPackageFlag()
    local bonus = P._playerBonus._returnBonus
    if bonus and bonus._value >= bonus._info._val and (not bonus._isClaimed) then
        return 1
    end

    return 0
end

function _M:getInviteBonusFlag()
    local number = 0
    for _, bonus in pairs(self._bonusInvite) do
        if bonus._value >= bonus._info._val and not bonus._isClaimed then
            number = number + 1
        end
    end
    return number
end

function _M:getClaimCenterBonusFlag()
    local number = 0
    for _, bonus in ipairs(self._serverBonuses) do
        if not bonus._isClaimed then
            number = number + 1
        end
    end

    return number
end

function _M:getSendBonusFlag()
    local number = 0
    for _, bonus in ipairs(self._sendBonuses) do
        if not bonus._isClaimed then
            number = number + 1
        end
    end

    return number
end

function _M:getTaskBonusFlag()
    --return self:getDailyTaskBonusFlag() + self:getLevelTaskBonusFlag() + self:getMainTaskBonusFlag() + self:getGrainTaskBonusFlag() + self:getOnlineTaskBonusFlag() + self:getNoviceTaskBonusFlag() + self:getFacebookTaskBonusFlag()
    --return self:getLevelTaskBonusFlag() + self:getMainTaskBonusFlag() + self:getGrainTaskBonusFlag() + self:getOnlineTaskBonusFlag()
    if ClientData.isAppStoreReviewing() then
        return self:getOnlineTaskBonusFlag()
    else
        return self:getLevelTaskBonusFlag() + self:getMainTaskBonusFlag() + self:getOnlineTaskBonusFlag()
    end
end

function _M:getDailyActiveBonusFlag()
    local number = 0
    for _, bonus in ipairs(self._bonusDailyActive) do        
        if bonus:canClaim() then
            number = number + 1
        end
    end
    
    return number
end

function _M:getFundTasksFlag()
    local number = 0
    for _, bonus in pairs(self._bonusFundTasks) do        
        if bonus:canClaim() then
            number = number + 1
        end
    end
    
    return number
end

function _M:getAchieveBonusFlag()
    local count = self:getLevelTaskBonusFlag() + self:getMainTaskBonusFlag() + self:getClashBonusesFlag() + self:getArenaBonusesFlag() + self:getCollectBonusFlag() + self:getCostBonusFlag()
    self._bonusCount = count
    return count
end

function _M:getClashBonusesFlag()
    local number = 0
    for _,clashBonus in ipairs(self._clashBonuses) do
        for _, bonus in ipairs(clashBonus) do
            if bonus:canClaim() then
                number = number + 1
                break
            end
        end
    end
    
    return number
end

function _M:getClashBonusFlag()
    local number = 0
    for _, bonus in ipairs(self._bonusClash) do        
        if bonus:canClaim() then
            number = number + 1
        end
    end
    
    return number
end

function _M:getClashContiBonusFlag()
    local number = 0
    for _, bonus in ipairs(self._bonusClashConti) do        
        if bonus:canClaim() then
            number = number + 1
        end
    end
    
    return number
end

function _M:getClashLegacyBonusFlag()
    local number = 0
    for _, bonus in ipairs(self._bonusClashLegacy) do        
        if bonus:canClaim() then
            number = number + 1
        end
    end
    
    return number
end

function _M:getClashLocalBonusFlag()
    local number = 0
    for _, bonus in ipairs(self._bonusClashLocal) do        
        if bonus:canClaim() then
            number = number + 1
        end
    end
    
    return number
end

function _M:getClashZoneBonusFlag()
    local number = 0
    for _, bonus in ipairs(self._bonusClashZone) do        
        if bonus:canClaim() then
            number = number + 1
        end
    end
    
    return number
end

function _M:getArenaBonusesFlag()
    local number = 0
    for _,arenaBonus in ipairs(self._arenaBonuses) do
        for _, bonus in ipairs(arenaBonus) do
            if bonus:canClaim() then
                number = number + 1
                break
            end
        end
    end
    
    return number
end

function _M:getArenaOnceBonusFlag()
    local number = 0
    for _, bonus in ipairs(self._bonusArenaOnce) do        
        if bonus:canClaim() then
            number = number + 1
        end
    end
    
    return number
end

function _M:getArenaAllBonusFlag()
    local number = 0
    for _, bonus in ipairs(self._bonusArenaAll) do        
        if bonus:canClaim() then
            number = number + 1
        end
    end
    
    return number
end

function _M:getArena12BonusFlag()
    local number = 0
    for _, bonus in ipairs(self._bonusArena12) do        
        if bonus:canClaim() then
            number = number + 1
        end
    end
    
    return number
end

function _M:getCostBonusFlag()
    local number = 0
    for _,consumBonus in ipairs(self._costBonuses) do
        for _, bonus in ipairs(consumBonus) do
            if bonus:canClaim() then
                number = number + 1
                break
            end
        end
    end
    
    return number
end



function _M:getGoldGainBonusFlag()
    local number = 0
    for _, bonus in ipairs(self._bonusGoldGain) do        
        if bonus:canClaim() then
            number = number + 1
        end
    end
    
    return number
end

function _M:getGoldCostBonusFlag()
    local number = 0
    for _, bonus in ipairs(self._bonusGoldCost) do        
        if bonus:canClaim() then
            number = number + 1
        end
    end
    
    return number
end

function _M:getGemCostBonusFlag()
    local number = 0
    for _, bonus in ipairs(self._bonusGemCost) do        
        if bonus:canClaim() then
            number = number + 1
        end
    end
    
    return number
end

function _M:getBottleBonusFlag()
    local number = 0
    for _, bonus in ipairs(self._bonusBottle) do        
        if bonus:canClaim() then
            number = number + 1
        end
    end
    
    return number
end

function _M:getCollectBonusFlag()
    local number = 0
    for _,cardBonus in ipairs(self._collectBonuses) do
        for _, bonus in ipairs(cardBonus) do
            if bonus:canClaim() then
                number = number + 1
                break
            end
        end
    end
    
    return number
end

function _M:getCardSrBonusFlag()
    local number = 0
    for _, bonus in ipairs(self._bonusCardSr) do        
        if bonus:canClaim() then
            number = number + 1
        end
    end
    
    return number
end

function _M:getCardUrBonusFlag()
    local number = 0
    for _, bonus in ipairs(self._bonusCardUr) do        
        if bonus:canClaim() then
            number = number + 1
        end
    end
    
    return number
end

function _M:getCardPackageBonusFlag()
    local number = 0
    for _, bonus in ipairs(self._bonusCardPackage) do        
        if bonus:canClaim() then
            number = number + 1
        end
    end
    
    return number
end

function _M:getDailyTaskBonusFlag()
    local number = 0
    for _, bonus in ipairs(self._bonusDailyTask) do
        local level = P._playerAchieve:getDailyTaskLevel(bonus._info._cid % 100)
        if P._level >= level and bonus._value >= bonus._info._val and not bonus._isClaimed then
            number = number + 1
        end
    end
    
    return number
end

function _M:getMainTaskBonusFlag()
    local number = 0
    for k, v in pairs(P._playerAchieve._mainTasks) do
        local bonus = v:getBonus()
        if v:isValid() and bonus._value >= bonus._info._val then
            number = number + 1
        end
    end
    
    return number
end

function _M:getGrainTaskBonusFlag()
    local number = 0
    for _, bonus in ipairs(self._bonusGrainTask) do        
        if bonus:canClaim() then
            number = number + 1
        end
    end
    
    return number
end

function _M:getOnlineTaskBonusFlag()
    for _, bonus in ipairs(self._bonusOnlineTask) do        
        if bonus:canClaim() then
            return 1
        end
    end

    return 0
end

function _M:getNoviceTaskBonusFlag()
    local number = 0
    for _, bonus in ipairs(self._bonusNoviceTask) do
        local requiredDay = bonus._infoId % 100
        local loginDay = self._bonusLogin[1]._value

        if bonus._value >= bonus._info._val and not bonus._isClaimed and loginDay >= requiredDay then
            number = number + 1
        end
    end
    
    return number
end

function _M:getFacebookTaskBonusFlag()
    local number = 0
    for _, bonus in ipairs(self._bonusFacebookTask) do
        if bonus._value >= bonus._info._val and not bonus._isClaimed then
            number = number + 1
        end
    end
    
    return number
end

function _M:isAllNoviceTaskClaimed()
    local number = 0
    for _, bonus in ipairs(self._bonusNoviceTask) do
        if not bonus._isClaimed then
            return false
        end
    end
    
    return true
end

function _M:getLevelTaskBonusFlag(cid)
    return self:getCommonBonusFlag(self._bonusLevel, cid)
end

function _M:getMonthCardBonusFlag()
    return self:getCommonBonusFlag(self._bonusMonthCard)
end

function _M:getWeekCheckinBonusFlag()
    return self:getCommonBonusFlag(self._bonusWeekCheckin)
end

function _M:getMonthCheckinBonusFlag()
    return self:getCommonBonusFlag(self._bonusMonthCheckin)
end

function _M:getLoginBonusFlag()
    return self:getCommonBonusFlag(self._bonusLogin)
end

function _M:getVipDailyBonusFlag()
    return self:getCommonBonusFlag(self._bonusVipDaily)
end

function _M:getFundLevelBonusFlag()
    local number, hasFund = 0, ClientData.isRecharged(Data.PurchaseType.fund) or P:isUnionFundValid()
    for _, bonus in ipairs(self._bonusFundLevel) do
        if hasFund and bonus._value >= bonus._info._val and (not bonus._isClaimed) then
            number = number + 1
        end
    end

    return number
end

function _M:getFundAllBonusFlag()
    return self:getCommonBonusFlag(self._bonusFundAll)
end

function _M:getFundTaskBonusFlag()
    local number = 0
    for _, bonus in pairs(self._bonusFundTasks) do
        if bonus._value >= bonus._info._val and not bonus._isClaimed then
            number = number + 1
        end
    end
    
    return number
end

function _M:initIapCount(pb)
    self._iapCount = {0, 0}
    for _, bonus in ipairs(pb.bonuses) do
        if bonus.cid == 4001 or bonus.cid == 4002 then
            self._iapCount[bonus.cid - 4000] = bonus.value     
        end
    end
end

function _M:getIapCount(purchaseType)
    if purchaseType == 1 or purchaseType == 2 then return (self._iapCount[1] or 0) + (self._iapCount[2] or 0)
    else return self._iapCount[purchaseType] or 0
    end
end

function _M:incIapCount(purchaseType)
    if self._iapCount[purchaseType] ~= nil then
        self._iapCount[purchaseType] = self._iapCount[purchaseType] +1
    end
end

function _M:claimServerBonus(bonus)
    if bonus ~= nil then
        if bonus._isClaimed then
            return Data.ErrorType.claimed
        end
        
        if bonus._info then
            local info = bonus._info
            P:addResources(info._rid, info._level, info._count, info._isFragment)
        else
            P:addResourcesData(bonus._extraBonus)
        end
        
        bonus._isClaimed = true
        bonus:sendBonusDirty()
                
        return Data.ErrorType.ok
    end
    
    return Data.ErrorType.error    
end

function _M:claimBonus(infoId)
    local bonus = self._bonuses[infoId]
    if bonus then
        local info = bonus._info
        if bonus._isClaimed then
            return Data.ErrorType.claimed
        end
        
        if bonus._value < bonus._info._val then
            return Data.ErrorType.claim_not_support
        end
        
        local counts = {}
        for _, count in ipairs(info._count) do
            table.insert(counts, count * (bonus._multiple or 1))
        end

        P:addResources(info._rid, info._level, counts, info._isFragment)

        self:tryClaimBonusExtra(infoId)

        if bonus._claimTimesMax then
            bonus._claimTimes = bonus._claimTimes + 1
            bonus._isClaimed = (bonus._claimTimes >= bonus._claimTimesMax)

        else
            if info._type == Data.BonusType.online then
                local curTime = ClientData.getCurrentTime()
                for _, b in ipairs(self._bonusOnlineTask) do
                    b._timestamp = curTime
                end
            elseif info._type == Data.BonusType.pass_chapter then
                self:onNoviceTaskDirty(1)

            end

            bonus._isClaimed = true
        end

        bonus:sendBonusDirty()

        return Data.ErrorType.ok
    end
    
    return Data.ErrorType.error
end

function _M:tryClaimBonusExtra(infoId)
    local activityInfo, pos = ClientData.getValidActivityByTypeAndParam(525, infoId)
    if activityInfo == nil then return end
    local extraBonusId = activityInfo._bonusId[pos]
    local info = Data._bonusInfo[extraBonusId]
    if info == nil then return end
    P:addResources(info._rid, info._level, info._count, info._isFragment)
end

function _M:supplyMonthCheckinBonus(infoId)
    local bonus = self._bonuses[infoId]
    
    if bonus ~= nil and bonus._type == Data.BonusType.month_checkin then
        if bonus._isClaimed then
            return Data.ErrorType.claimed
        end
        
        local recheckIngot = math.min(10 + P._monthlyRecheck * 10, Data._globalInfo._maxRecheckIngot)
        if not P:hasResource(Data.ResType.ingot, recheckIngot) then
            return Data.ErrorType.need_more_ingot
        end
        
        if P._dayOfMonth >= bonus._info._val and bonus._info._val - bonus._value == 1 then           
            for i = 1, #self._bonusMonthCheckin do                
                self._bonusMonthCheckin[i]._value = self._bonusMonthCheckin[i]._value + 1
                if self._bonusMonthCheckin[i] ~= bonus then
                    self._bonusMonthCheckin[i]:sendBonusDirty()
                end
            end
            P:changeResource(Data.ResType.ingot, -recheckIngot)
            P._monthlyRecheck = P._monthlyRecheck + 1
            return self:claimBonus(bonus._infoId)            
        end
    end
    
    return Data.ErrorType.error
end

function _M:onDailyActiveDirty()
    for _, bonus in ipairs(self._bonusDailyActive) do
        bonus._value = P._dailyActive
    end
end

function _M:checkBonusLevel(bonus)
    --if (bonus._info._cid % 100 == 1 or bonus._info._type == Data.BonusType.level) and bonus._value ~= P._level then
    local characterId = P:getCharacterId()
    local character = P._characters[characterId]
    if bonus._info._cid % 1000 == characterId and bonus._info._type == Data.BonusType.level and bonus._value ~= character._level then
        local lastValue = bonus._value
        bonus._value = character._level
        bonus:sendBonusDirty(lastValue)
    end
end

function _M:onLevelDirty()
    for _, bonus in ipairs(self._bonusLord) do
        self:checkBonusLevel(bonus)
    end

    for _, bonus in ipairs(self._bonusLevel) do
        self:checkBonusLevel(bonus)
    end

    self:onFundLevelDirty()
end

function _M:onFundLevelDirty(isForce)
    for _, bonus in ipairs(self._bonusFundLevel) do
        if bonus._value ~= P:getMaxCharacterLevel() or isForce then
            local lastValue = bonus._value
            bonus._value = P._level
            bonus:sendBonusDirty(lastValue)
        end
    end
end

function _M:onFundNumDirty()
    for _, bonus in ipairs(self._bonusFundAll) do
        local lastValue = bonus._value
        bonus._value = bonus._value + 1
        bonus:sendBonusDirty(lastValue)
    end
end

function _M:onCardDirty(infoId)
    local info, cardType = Data.getInfo(infoId)
    if cardType == Data.CardType.monster then
        for _, bonus in ipairs(self._bonusCharacter) do            
            local type = bonus._info._cid % 100
            local valueDirty = false
            local lastValue = bonus._value
            if type == 4 and cardType == Data.CardType.monster then
                -- valueDirty = true
            elseif type == 5 and cardType == Data.CardType.monster then
                --    valueDirty = true
            end

            if valueDirty then
                bonus:sendBonusDirty(lastValue)
            end
        end 
    end
end

function _M:onCardAdd(infoId)
    if infoId == nil then return end
    
    local info, cardType = Data.getInfo(infoId)
    if cardType == Data.CardType.monster then
        for i = 1, #self._bonusCharacter do
            local bonus = self._bonusCharacter[i]
            local type = bonus._info._cid % 100
            local valueDirty = false
            local lastValue = bonus._value
            if type == 2 and info._quality == Data.CardQuality.SR then                
                bonus._value = bonus._value + 1
                valueDirty = true
            elseif type == 3 and info._quality == Data.CardQuality.UR then
                bonus._value = bonus._value + 1
                valueDirty = true              
            end
            if valueDirty then                                           
                bonus:sendBonusDirty(lastValue)                
            end
        end           
    end
end

function _M:onMonthCardDirty(type)
    local index = type - Data.PurchaseType.month_card_1 + 1
    local bonus = self._bonusMonthCard[index]
    bonus._value = bonus._info._val
    bonus:sendBonusDirty()
end

function _M:onChapterLevelDirty(levelId)
    local checkBonus = function(bonus)
        local diffculty = math.floor(levelId / 10000)
        if diffculty == 1 then
            if bonus._info._cid % 100 == 3 then
                if bonus._value ~= levelId then
                    bonus._value = levelId
                    bonus:sendBonusDirty()
                end
            end        
        elseif diffculty == 2 then
            if bonus._info._cid % 100 == 4 then
                if bonus._value ~= levelId then
                    bonus._value = levelId
                    bonus:sendBonusDirty()
                end
            end         
        elseif diffculty == 3 then
            if bonus._info._cid % 100 == 5 then
                if bonus._value ~= levelId then
                    bonus._value = levelId
                    bonus:sendBonusDirty()
                end
            end         
        end
    end

    for _, bonus in ipairs(self._bonusChapter) do
        checkBonus(bonus)
    end

    for _, bonus in ipairs(self._bonusPassChapter) do
        checkBonus(bonus)
    end
end

function _M:onNoviceTaskDirty(index, value)
    --[[
    local bonus = self._bonusNoviceTask[index]
    local lastValue = bonus._value
    bonus._value = bonus._value + (value or 1)
    bonus:sendBonusDirty(lastValue)
    ]]
end

function _M:onFacebookTaskDirty(cid, value)
    for i = 1, #self._bonusFacebookTask do
        local bonus = self._bonusFacebookTask[i]
        if bonus._info._cid == cid then
            bonus._value = value or 1
            bonus:sendBonusDirty() 
            break       
        end
    end
end

function _M:sendBonusRequest()
    local msgType = SglMsgType_pb.PB_TYPE_BONUS_PLAYER_BONUS
    ClientData.sendBonusRequest(msgType)
end

function _M:onMsg(msg)
    local msgType = msg.type
    local msgStatus = msg.status
    
    if msgType == SglMsgType_pb.PB_TYPE_BONUS_PLAYER_BONUS then
        self:updateBonus(msg)
    elseif msgType == SglMsgType_pb.PB_TYPE_BONUS_PLAYER_BONUS_AVAILABLE then
        self._bonusCount = msg.Extensions[Bonus_pb.SglBonusMsg.bonus_count] or 0
        if V.MenuUI ~= nil then
            V.getMenuUI():updateAchieveFlag(self._bonusCount)
        end
    elseif msgType == SglMsgType_pb.PB_TYPE_BONUS_ACTIVITY then
        local bonuses = msg.Extensions[Bonus_pb.SglBonusMsg.bonus_activity_resp]
        for i = 1, #bonuses do
            local bonus = require("ServerBonus").new(bonuses[i])
            if bonus._infoId ~= 0 and Data._bonusInfo[bonus._infoId] and Data._bonusInfo[bonus._infoId]._type == Data.BonusType.send then
                table.insert(self._sendBonuses, bonus)
            else
                table.insert(self._serverBonuses, bonus)
            end
        end
        table.sort(self._sendBonuses, function(a, b) return a._timestamp > b._timestamp end)
        table.sort(self._serverBonuses, function(a, b) return a._timestamp > b._timestamp end)
        
        local eventCustom = cc.EventCustom:new(Data.Event.server_bonus_list_dirty)            
        lc.Dispatcher:dispatchEvent(eventCustom)     
    
        return true
        
    elseif msgType == SglMsgType_pb.PB_TYPE_USER_SPAWN_GOLD then
        local resp = msg.Extensions[User_pb.SglUserMsg.user_spawn_gold_resp]
        P._dailyClaimedGold = resp.gold
        P._dailyNextSpawn = resp.next_spawn / 1000
        ClientData._isNewGoldClaim = true   
        lc.Dispatcher:dispatchEvent(cc.EventCustom:new(Data.Event.daily_gold_dirty))
        
        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_BUY_FUND then
        self:onFundNumDirty()

        return true

    elseif msgType == SglMsgType_pb.PB_TYPE_BONUS_DAILY_TASK or msgType == SglMsgType_pb.PB_TYPE_BONUS_DAILY_TASK_RESET then
        local bonuses = msg.Extensions[Bonus_pb.SglBonusMsg.daily_task]
        for _, bonus in ipairs(bonuses) do
            if self._bonusFundTasks[bonus.cid] then
                if self._bonusFundTasks[bonus.cid]._value ~= bonus.value then
                    if not self._bonusFundTasks[bonus.cid]:canClaim() and not self._bonusFundTasks[bonus.cid]._isClaimed and bonus.value > 0 then
                        self._changedFundTasks[bonus.cid] = bonus.cid
                    end
                    self._bonusFundTasks[bonus.cid]._value = bonus.value
                end
                -- fix later
            elseif not bonus._isClaimed and self._allFundTasks[bonus.cid] ~= nil then
                self._bonusFundTasks[bonus.cid] = self._allFundTasks[bonus.cid]
                self._bonusFundTasks[bonus.cid]._value = bonus.value
                self._bonusFundTasks[bonus.cid]._isClaimed = false
                self._changedFundTasks[bonus.cid] = bonus.cid
            end
        end
        lc.Dispatcher:dispatchEvent(cc.EventCustom:new(Data.Event.fund_task_dirty))
        NoticeManager.hideAll()
        local i = 1
        for _, bonus in pairs(self._bonusFundTasks) do
            if i > 5 then break end
            if self._changedFundTasks[bonus._info._cid] and bonus._value > 0 then
                local layout = lc.createNode()
                local title = lc.createSprite("fund_task_spr")
                title:setScale(0.5)
                local msg = V.createTTF(string.gsub(string.format(Str(bonus._info._nameSid), bonus._info._val), "\\n", "")..": ", V.FontSize.S1, V.COLOR_TEXT_DARK)
                local msg2 = V.createTTF(bonus._value.."/"..bonus._info._val, V.FontSize.S1, V.COLOR_TEXT_INGOT)
                layout:setContentSize(cc.size(lc.w(title) + lc.w(msg) + lc.w(msg2) + 30, 50))
                lc.addNodesToCenterH(layout, {title, msg, msg2}, 10)
                local richText = ccui.RichTextEx:create()
                richText:insertElement(ccui.RichItemCustom:create(0, lc.Color3B.white, 255, layout))
--                richText:insertElement(ccui.RichItemText:create(1, V.COLOR_TEXT_DARK, 255, msg, V.TTF_FONT, V.FontSize.S1))
--                richText:insertElement(ccui.RichItemText:create(2, V.COLOR_TEXT_INGOT, 255, msg2, V.TTF_FONT, V.FontSize.S1))
                NoticeManager.show(richText, 5, 100)
            end
            i = i + 1
        end
        self._changedFundTasks = {}
        return true

    end
    
    return false
end

function _M:updateBonus(msg)
    local pbBonus = msg.Extensions[Bonus_pb.SglBonusMsg.player_bonus]
    self:init(pbBonus, false)
    P._playerAchieve:sendAchieveListDirty()
end

function _M:sendResetFundTask(cid)
    self._bonusFundTasks[cid] = nil
    ClientData.sendResetFundTask(cid)
    self._fundResetCount = self._fundResetCount - 1
end

return _M
