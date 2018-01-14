---------------------------------------- DataBonusItem ----------------------------------------
local DateBonusItem = class("DateBonusItem", lc.ExtendUIWidget)

function DateBonusItem.create(size, date, bonus)
    local item = DateBonusItem.new(lc.EXTEND_LAYOUT)
    item:setContentSize(size)
    item:setAnchorPoint(0.5, 0.5)
    item:init(date, bonus)
    return item
end

function DateBonusItem:init(date, bonus)
    self._bonus = bonus
    
    self:setCascadeColorEnabled(true)
    self:addTouchEventListener(function(sender, type) 
        if type == ccui.TouchEventType.ended then
            if self._claimHandler ~= nil then
                self._claimHandler(bonus)
            end
        end
    end)
    
    local icon = IconWidget.createByBonus(bonus._info, 1)
    icon._name:setColor(lc.Color3B.white)
    lc.addChildToCenter(self, icon)

    if bonus._checkinInfo and bonus._checkinInfo._vip > 0 then
        icon._name:setVisible(false)

        local bg = lc.createSprite{_name = "img_com_bg_34", _crect = V.CRECT_COM_BG34, _size = cc.size(100, V.CRECT_COM_BG34.height)}
        lc.addChildToPos(icon, bg, cc.p(icon._name:getPosition()))

        local vip = V.createTTF(string.format("V%d %s", bonus._checkinInfo._vip, Str(STR.DOUBLE)), V.FontSize.S1, lc.Color3B.yellow)        
        vip:setScale(0.7)
        lc.addChildToPos(bg, vip, cc.p(lc.w(bg) / 2, lc.sh(bg) / 2 + 2))
    end
    
    self._icon = icon
end

function DateBonusItem:onEnter()
    self._listener = lc.addEventListener(Data.Event.bonus_dirty, function(event) 
        if event._data._type == self._bonus._type then
            self:updateView()
        end
    end)
    self:updateView()
end

function DateBonusItem:onExit()
    lc.Dispatcher:removeEventListener(self._listener)
end

function DateBonusItem:registerClaimHandler(handler)
    self._claimHandler = handler
end

function DateBonusItem:updateView()
    local sprite
    if self._bonus._isClaimed then
        sprite = cc.Sprite:createWithSpriteFrameName("activity5_img_claimed")
        sprite:setPosition(lc.w(sprite) / 2, lc.h(self) - lc.h(sprite) / 2)
        self:setTouchEnabled(false)
        self._icon:setEnabled(false) 
    else
        if self._bonus._value >= self._bonus._info._val then
            sprite = cc.Sprite:createWithSpriteFrameName("activity5_rect_claimable")
            sprite:setPosition(lc.w(self) / 2, lc.h(self) / 2 + 15)
            self:setTouchEnabled(true)
            self:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)
            self._icon:setTouchEnabled(false)
        else          
            local hasClaimable = false
            local bonuses = P._playerBonus._bonusMonthCheckin
            for i = 1, #bonuses do
                if bonuses[i]._value >= bonuses[i]._info._val and (not bonuses[i]._isClaimed) then
                    hasClaimable = true
                    break
                end
            end
        
            if P._dayOfMonth >= self._bonus._info._val and self._bonus._info._val - self._bonus._value == 1 and (not hasClaimable) then
                sprite = lc.createSprite("activity5_img_supply")
                sprite:setOpacity(250)
                sprite:setPosition(lc.w(self) / 2, lc.h(self) - 22)

                local label = V.createTTF(Str(STR.CHECKIN_RETRY), V.FontSize.S2, lc.Color3B.yellow)
                lc.addChildToCenter(sprite, label)

                self:setTouchEnabled(true) 
                self:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)
                self._icon:setTouchEnabled(false)                            
            else
                self:setTouchEnabled(false)
                self._icon:setTouchEnabled(true)  
                self._icon:setTouchEndCancelRange(lc.Gesture.BUDGE_LIMIT)              
            end
        end               
    end  
    
    if sprite == nil then return end
    
    if self._flag ~= nil then
        self._flag:removeFromParent()
    end
    self._flag = sprite
    self:addChild(self._flag) 
end

---------------------------------------- DataBonusItem ----------------------------------------
local _M = class("MonthCheckin", lc.ExtendUIWidget)

local COLUMN_NUM = 7
local ROW_HEIGHT = 136

function _M.create(bgName, size)
    local panel = _M.new(lc.EXTEND_LAYOUT)
    panel:setContentSize(size)
    panel:setAnchorPoint(0.5, 0.5)
    panel:init(bgName)

    return panel    
end

function _M:init(bgName)
    _, _, self._month, self._year = ClientData.getServerDate()

    --local titleBg = lc.createSprite('res/jpg/activity_top.jpg')
    --lc.addChildToPos(self, titleBg, cc.p(lc.w(self) / 2, lc.h(self) - lc.h(titleBg) / 2))

    local title = V.createCheckinTitle(string.format(Str(STR.MONTH_REGISTER), self._month), 0)
    lc.addChildToPos(self, title, cc.p(lc.w(self) / 2 + 140, lc.h(self) - lc.h(title) / 2 - 24))

    local checkinNum = V.createTTF(string.format(Str(STR.MONTH_REGISTER_NUM), 0), V.FontSize.S1, V.COLOR_TEXT_DARK)    
    lc.addChildToPos(self, checkinNum, cc.p(lc.x(title), lc.bottom(title) - lc.h(checkinNum) / 2 - 12))
    self._checkinNum = checkinNum

    local bonusBG = lc.createSprite{_name = "img_com_bg_11", _crect = V.CRECT_COM_BG11, _size = cc.size(lc.w(self) - 20, 390)}
    lc.addChildToPos(self, bonusBG, cc.p(lc.w(self) / 2, lc.h(bonusBG) / 2))

    local bonusList = lc.List.createV(cc.size(lc.w(bonusBG) - 32, lc.h(bonusBG) - 20), 16, 10)
    lc.addChildToPos(bonusBG, bonusList, cc.p(16, 10))
    self._list = bonusList
    
    local itemNum = math.ceil(self:getDaysOfMonth(self._month) / COLUMN_NUM)
    for i = 1, itemNum do
        local item = self:createItem(cc.size(lc.w(bonusList), ROW_HEIGHT), i)
        bonusList:pushBackCustomItem(item)
    end
   
end

function _M:createItem(size, index)
    local item = ccui.Widget:create()
    item:setContentSize(size)   
    
    local bonuses = P._playerBonus._bonusMonthCheckin
    table.sort(bonuses, function(a, b) return a._infoId < b._infoId end)     

    local childItemSize = cc.size(size.width / COLUMN_NUM, size.height)
    for i = 1, COLUMN_NUM do
        local count = (index - 1) * COLUMN_NUM + i
        if count > self:getDaysOfMonth(self._month) then break end
                         
        local bonus = bonuses[count]
        if bonus ~= nil then
            local childItem = DateBonusItem.create(childItemSize, count, bonus)
            childItem:registerClaimHandler(function(bonus) self:claimBonus(bonus) end)
            lc.addChildToPos(item, childItem, cc.p((i - 0.5) * lc.w(childItem), lc.h(item) / 2))
        end
    end
    
    return item
end

function _M:onEnter()
    self:updateView()
end

function _M:onExit()
end

function _M:claimBonus(bonus, isForce)
    if bonus._checkinInfo then
        if bonus._checkinInfo._vip > 0 and P._vip >= bonus._checkinInfo._vip then
            bonus._multiple = 2
        else
            bonus._multiple = nil
        end
    end

    local result = Data.ErrorType.error
    if not bonus._isClaimed then
        if bonus._value >= bonus._info._val then
            result = P._playerBonus:claimBonus(bonus._infoId)
            if result == Data.ErrorType.ok then
                ClientData.sendClaimBonus(bonus._infoId)
            end
        else
            if P._dayOfMonth >= bonus._info._val and bonus._info._val - bonus._value == 1 then
                if isForce then
                    result = P._playerBonus:supplyMonthCheckinBonus(bonus._infoId)
                    if result == Data.ErrorType.ok then
                        ClientData.sendSupplyMonthCheckinBonus(bonus._infoId)
                    elseif result == Data.ErrorType.need_more_ingot then
                        require("PromptForm").ConfirmBuyIngot.create():show()
                    end
                else
                    local recheckIngot = math.min(10 + P._monthlyRecheck * 10, Data._globalInfo._maxRecheckIngot)
                    require("Dialog").showDialog(string.format(Str(STR.SURE_TO_SUPPLY), recheckIngot), function() self:claimBonus(bonus, true) end)                    
                end
            end
        end   
    end
    
    if result == Data.ErrorType.ok then
        self:updateView()    

        --if not Data.hasBigCard(bonus._info._rid[1]) or bonus._info._isFragment[1] == 1 then
            local RewardPanel = require("RewardPanel")
            RewardPanel.create(bonus, RewardPanel.MODE_CLAIM):show()
        ---end

        lc.Audio.playAudio(AUDIO.E_CLAIM)
    elseif result == Data.ErrorType.need_more_ingot then
        require("PromptForm").ConfirmBuyIngot.create():show()       
    elseif result == Data.ErrorType.claimed then
        ToastManager.push(Str(STR.CLAIMED)..Str(STR.BONUS))
    elseif result == Data.ErrorType.claim_not_support then
        ToastManager.push(Str(STR.CANNOT_CLAIM)..Str(STR.BONUS))
    end   
end

function _M:getDaysOfMonth(month)
    if month == 2 then
        if self._year % 400 == 0 or (self._year % 4 == 0 and self._year % 100 ~= 0) then
            return 29
        else
            return 28
        end
    else
        if month <= 7 then
            return month % 2 == 0 and 30 or 31
        else
            return month % 2 == 0 and 31 or 30
        end
    end
end

function _M:updateView()
    local num = 0
    for i = 1, #P._playerBonus._bonusMonthCheckin do
        if P._playerBonus._bonusMonthCheckin[i]._isClaimed then
            num = num + 1
        end
    end

    self._checkinNum:setString(string.format(Str(STR.MONTH_REGISTER_NUM), num))

    -- Scroll list
    local pos, list = math.floor(num / 7) + 1, self._list
    list:forceDoLayout()
    list:gotoPos(pos * (ROW_HEIGHT + 10) - 370)
end

return _M