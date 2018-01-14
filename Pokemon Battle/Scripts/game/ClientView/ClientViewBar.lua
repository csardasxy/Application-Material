local _M = ClientView


function _M.createLevelExpBar(level, exp, expMax, width)
    local bar = _M.createLabelProgressBar(width or 200)
    if expMax and expMax > 0 then
        bar._bar:setPercent(exp * 100 / expMax)
    end
    bar:setLabel(exp, expMax)
    local levelArea = _M.createLevelAreaNew(level)
    lc.addChildToPos(bar, levelArea, cc.p(8, lc.h(bar) / 2))
    bar._level = levelArea._level

    return bar
end

function _M.createProgressBar(w, barColor)
    local h = _M.CRECT_PROGRESS_BG.height
    local bg = lc.createSprite{_name = "img_progress_bg", _crect = _M.CRECT_PROGRESS_BG, _size = cc.size(w, h)}

    local progressBar = ccui.LoadingBar:create()
    progressBar:loadTexture("img_progress_fg", ccui.TextureResType.plistType)
    progressBar:setDirection(ccui.LoadingBarDirection.LEFT)
    progressBar:setPosition(w / 2, h / 2)
    progressBar:setScale9Enabled(true)
    progressBar:setCapInsets(_M.CRECT_PROGRESS_FG)
    progressBar:setContentSize(w - 6, _M.CRECT_PROGRESS_FG.height)
    progressBar:setColor(barColor or lc.Color3B.yellow)
    bg:addChild(progressBar)
    progressBar:setPercent(0)
    bg._bar = progressBar
    
    return bg 
end

function _M.createLabelProgressBar(w, labelFont, labelColor, barColor)
    local bg = _M.createProgressBar(w, barColor)
    local w, h = lc.w(bg), lc.h(bg)
    
    local label = _M.createBMFont(labelFont or _M.BMFont.huali_26, "")
    label:setScale(0.9)
    label:setPosition(w / 2, h / 2)
    if labelColor then label:setColor(labelColor) end
    bg:addChild(label)
    bg._label = label

    bg.setLabel = function(self, val, max, isGold)
        if max then
            if isGold then
                self._label:setString(ClientData.formatNum(val, 99999).."/"..ClientData.formatNum(max, 99999))
            else
                self._label:setString(string.format("%d/%d", val, max))
            end
        else
            self._label:setString(tostring(val))
        end
    end
    
    return bg    
end

function _M.addUnionPersonalPowerBar(parent, resType, x, y, width)
    local icon = lc.createSprite("img_icon_res"..resType.."_s")
    lc.addChildToPos(parent, icon, cc.p(x, y))
    icon:setAnchorPoint(0.5, 1)
    local expBar = V.createProgressBar(width)
    expBar:setAnchorPoint(0, 0.5)
    lc.addChildToPos(parent, expBar, cc.p(lc.right(icon)+10, y-lc.ch(icon)))
    local label = _M.createBMFont(V.BMFont.huali_20, "")
--    label:setAnchorPoint(0, 1)
    lc.addChildToPos(expBar, label, cc.p(lc.cw(expBar)-lc.cw(label), lc.ch(expBar) + 2))
    expBar._label = label
    expBar.update = function (point, maxPoint)
        expBar._bar:setPercent(100 * point / maxPoint)
        label:setString(point.."/"..maxPoint)
    end
    expBar.update(1 , 100)
    return expBar
end

function _M.createBoxProgressBar(data, w, callBack)
    local h = 20
    local bg = lc.createSprite({_name = "img_progress_bg2", _crect = _M.CRECT_PROGRESS_BG, _size = cc.size(w, h)})

    local progressBar = ccui.LoadingBar:create()
    progressBar:loadTexture("img_progress_fg2", ccui.TextureResType.plistType)
    progressBar:setDirection(ccui.LoadingBarDirection.LEFT)
    progressBar:setPosition(w / 2, h / 2)
    progressBar:setScale9Enabled(true)
    progressBar:setCapInsets(_M.CRECT_PROGRESS_FG)
    progressBar:setContentSize(w - 6, _M.CRECT_PROGRESS_FG.height)
    progressBar:setColor(barColor or lc.Color3B.yellow)
    lc.addChildToPos(bg, progressBar, cc.p(lc.cw(bg) - 3, lc.ch(bg) + 8))
    progressBar:setPercent(60)
    bg._bar = progressBar

    local max = data[#data]._val
    
    local bonesNames = {"1baoxiang", "2baoxiang", "3baoxiang", "4baoxiang", "5baoxiang"}

    local nodes = {}

    for k, info in ipairs(data) do
        local val = info._val
        local x = (w - 10) * (val) / (max) + 3
        local claimed = info._claimed 
        
        local spr = lc.createSprite(info._darkSpr)
        lc.addChildToPos(progressBar, spr, cc.p(x, 7))
        local numLabel = V.createTTFBold(val, V.FontSize.S2, V.COLOR_TEXT_WHITE)
        lc.addChildToPos(bg, numLabel, cc.p(x, -lc.ch(numLabel) + 5))

        local bones = DragonBones.create(bonesNames[k])
        bones._claimed = claimed
        bones:setScale(0.4)
        bones:gotoAndPlay("effect4")
        local boxBtn = V.createShaderButton(nil, function (sender)  
            if callBack then
                callBack(sender)
            end
        end)
        boxBtn:setContentSize(cc.size(60, 60))
        lc.addChildToCenter(boxBtn, bones)
        boxBtn._bones = bones
        boxBtn._index = k
        lc.addChildToPos(bg, boxBtn, cc.p(x - 10, 80))

        local node = {}
        node._val = val
        node._spr = spr
        node._bones = bones
        table.insert(nodes, node)
    end

    bg.update = function (curVal)
        local percent = 100 * curVal / max
        progressBar:setPercent(percent)
        for _, node in ipairs(nodes) do
            node._spr:setSpriteFrame(curVal >= node._val and "light_point" or "dark_point")
            if curVal < node._val then
                node._bones:gotoAndPlay("effect4")
            elseif node._bones._claimed then
                node._bones:gotoAndPlay("effect5")
            else
                node._bones:gotoAndPlay("effect2")
            end
        end

    end


    return bg
end

function _M.createClashChestProgressBar(data)
    local progressBar = cc.ProgressTimer:create(lc.createSprite("daily_target_progress"))
    progressBar:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
    
    progressBar:setPercentage(0)

    local genChestParam = function(i)
        return P._playerFindClash:getChestGrade(i), i, Data.CardQuality.UR
    end

    local max = #data
    local rotPer = 2 * math.pi / max
    local r = lc.cw(progressBar)

    local nodes = {}

    for k, info in ipairs(data) do
        local node = {}
        local val = k
        node._val = val
        local x = (r - 10) * math.sin((val - 0) * rotPer) + r
        local y = (r - 10) * math.cos((val - 0) * rotPer) + r
        local numX = (r + 30) * math.sin((val - 0.5) * rotPer) + r
        local numY = (r + 30) * math.cos((val - 0.5) * rotPer) + r
        local chestX = (r + 120) * math.sin((val - 0.5) * rotPer) + r
        local chestY = (r + 120) * math.cos((val - 0.5) * rotPer) + r
        --[[
        local spr = lc.createSprite(info._darkSpr)
        spr:setRotation(val * rotPer * 360 / (2 * math.pi))
        node._spr = spr
        lc.addChildToPos(progressBar, spr, cc.p(x, y))
        ]]
        local numLabel = V.createTTFBold(string.format(Str(STR.WIN_CONTINOUS), val), V.FontSize.S2, V.COLOR_TEXT_WHITE)
        lc.addChildToPos(progressBar, numLabel, cc.p(numX, numY), 3)
        node._numLabel = numLabel

        table.insert(nodes, node)
    end

    progressBar.update = function (curVal)
        local percent = 100 * curVal / max
        progressBar:setPercentage(percent)
        for i, node in ipairs(nodes) do
            --node._spr:setSpriteFrame(curVal >= node._val and data[i]._lightSpr or data[i]._darkSpr)
            node._numLabel:setColor(curVal >= node._val and V.COLOR_TEXT_INGOT or V.COLOR_TEXT_WHITE)
        end

    end

    progressBar.updateWithAni = function ()
        progressBar:stopAllActions()
        local targetVal = #P._playerFindClash._chests
        local currentVal = progressBar:getPercentage() / 100 * max
        local times = 60
        local speed = (targetVal - currentVal) / times
        local totalTime = 1
        progressBar:runAction(lc.ease(lc.sequence(lc.rep(lc.sequence(function() progressBar.update(progressBar:getPercentage() * max / 100 + speed) end, totalTime / times), times), function() progressBar.update(targetVal) end), "SineIO"))
    end


    return progressBar
end

function _M.createClashSeasonProgressBar(data)
    local progressBar = cc.ProgressTimer:create(lc.createSprite("daily_target_progress"))
    progressBar:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
    
    progressBar:setPercentage(80)

    local genChestParam = function(i)
        return P._playerFindClash:getChestGrade(i), i, Data.CardQuality.UR
    end

    local startValue = data[1]._val
    local maxCount = #data
    local maxValue = data[#data]._val
    local rotPer = 2 * math.pi * (maxCount - 1) / maxCount / (maxValue - startValue)
    local r = lc.cw(progressBar)

    local nodes = {}

    for k, info in ipairs(data) do
--        local chest = V.createClashTargetChest(k)
        local node = {}
        local val = info._val
        node._val = val
        local x = (r - 10) * math.sin((val - startValue) * rotPer) + r
        local y = (r - 10) * math.cos((val - startValue) * rotPer) + r
        local numX = (r + 35) * math.sin((val - startValue) * rotPer) + r
        local numY = (r + 35) * math.cos((val - startValue) * rotPer) + r
        local chestX = (r + 120) * math.sin((val - startValue) * rotPer) + r
        local chestY = (r + 120) * math.cos((val - startValue) * rotPer) + r
        --[[
        local spr = lc.createSprite(info._darkSpr)
        spr:setRotation((val - startValue) * rotPer * 360 / (2 * math.pi))
        node._spr = spr
        lc.addChildToPos(progressBar, spr, cc.p(x, y))
        ]]
        local numNode = lc.createNode()
        local numLabel = V.createTTFBold(val, V.FontSize.S4, V.COLOR_TEXT_WHITE)
        local numSpr = lc.createSprite(string.format("img_icon_res%d_s", Data.ResType.clash_trophy))
        numSpr:setScale(0.6)
        lc.addNodesToCenterH(numNode, {numSpr, numLabel}, 0)
        lc.addChildToPos(progressBar, numNode, cc.p(numX, numY))
        node._numLabel = numLabel

        table.insert(nodes, node)
    end

    progressBar.update = function (curVal)
        curVal = math.min(curVal, maxValue)
        local percent = 100 * (maxCount - 1) / maxCount * (curVal - startValue) / (maxValue - startValue)
        progressBar:setPercentage(percent)
        for i, node in ipairs(nodes) do
            --node._spr:setSpriteFrame(curVal >= node._val and data[i]._lightSpr or data[i]._darkSpr)
            node._numLabel:setColor(curVal >= node._val and V.COLOR_TEXT_INGOT or V.COLOR_TEXT_WHITE)
        end
    end

    progressBar.updateWithAni = function (targetVal)
        progressBar:stopAllActions()
        targetVal = math.min(targetVal, maxValue)
        local currentVal = progressBar:getPercentage() / 100 * (maxValue - startValue) * maxCount / (maxCount - 1) + startValue
        local times = 60
        local speed = (targetVal - currentVal) / times
        local totalTime = 1
        progressBar:runAction(lc.ease(lc.sequence(lc.rep(lc.sequence(function()
            local percent = progressBar:getPercentage() / 100
            progressBar.update(percent * (maxValue - startValue) * maxCount / (maxCount - 1) + startValue + speed)
        end, totalTime / times), times), function() progressBar.update(targetVal) end), "SineIO"))
    end


    return progressBar
end

function _M.createTrophyProgressBar(w)
    local PlayerFindClash = P._playerFindClash
    local progressBar = V.createProgressBar(w - 100)

    local trophyIcon = lc.createSprite("img_icon_res6_s")
    trophyIcon:setScale(0.8)
    lc.addChildToPos(progressBar, trophyIcon, cc.p(70, lc.ch(progressBar)))
    local numLabel = V.createBMFont(V.BMFont.huali_20, "0/0", cc.TEXT_ALIGNMENT_LEFT)
    lc.addChildToPos(progressBar, numLabel, cc.p(150, lc.ch(progressBar)))
    
    progressBar.update = function()
        if progressBar._curSpine then
            progressBar._curSpine:removeFromParent()
        end
        if progressBar._nextSpine then
            progressBar._nextSpine:removeFromParent()
        end
        local grade = PlayerFindClash:getGrade(PlayerFindClash._trophy)
        local start = Data._ladderInfo[grade]._trophy
        local target
        if grade >= Data.FindClashGrade.legend then
            target = Data._ladderInfo[Data.FindClashGrade.legend]._trophy
        else
            target = Data._ladderInfo[grade + 1]._trophy
        end
        local percent = (PlayerFindClash._trophy) / (target) * 100
        percent = math.min(percent, 100)
        progressBar._bar:setPercent(percent)
        numLabel:setString(tostring(PlayerFindClash._trophy).."/"..tostring(target))
        
        local curSpine = V.createTrophyGradeDB(grade)
        curSpine:setScale(0.5)
        lc.addChildToPos(progressBar, curSpine, cc.p(-25, lc.ch(progressBar)))
        progressBar._curSpine = curSpine
        if grade < Data.FindClashGrade.legend then
            local nextSpine = V.createTrophyGradeDB(grade + 1)
            nextSpine:setScale(0.5)
            lc.addChildToPos(progressBar, nextSpine, cc.p(lc.w(progressBar) + 25, lc.ch(progressBar)))
            progressBar._nextSpine = nextSpine
        end
        
    end
    progressBar.update()
    return progressBar
end

function _M.createDailyTaskProgressBar(data)
    local progressBar = cc.ProgressTimer:create(lc.createSprite("daily_target_progress"))
    progressBar:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
    
    local genChestParam = function(i)
        return P._playerFindClash:getChestGrade(i), i, Data.CardQuality.UR
    end

    local startValue = data[1]._val
    local maxCount = #data
    local maxValue = data[#data]._val
    local rotPer = 2 * math.pi * (maxCount - 1) / maxCount / (maxValue - startValue)
    local r = lc.cw(progressBar)

    local nodes = {}
    --[[
    for k, info in ipairs(data) do
--        local chest = V.createClashTargetChest(k)
        local node = {}
        local val = info._val
        node._val = val
        local x = (r - 10) * math.sin((val - startValue) * rotPer) + r
        local y = (r - 10) * math.cos((val - startValue) * rotPer) + r
        local numX = (r + 35) * math.sin((val - startValue) * rotPer) + r
        local numY = (r + 35) * math.cos((val - startValue) * rotPer) + r
        local chestX = (r + 120) * math.sin((val - startValue) * rotPer) + r
        local chestY = (r + 120) * math.cos((val - startValue) * rotPer) + r
        --[[
        local spr = lc.createSprite(info._darkSpr)
        spr:setRotation((val - startValue) * rotPer * 360 / (2 * math.pi))
        node._spr = spr
        lc.addChildToPos(progressBar, spr, cc.p(x, y))
        ]]--[[
        local numNode = lc.createNode()
        local numLabel = V.createTTF(val, V.FontSize.S4, V.COLOR_TEXT_WHITE)
        local numSpr = lc.createSprite(string.format("img_icon_res%d_s", Data.ResType.clash_trophy))
        numSpr:setScale(0.6)
        lc.addNodesToCenterH(numNode, {numSpr, numLabel}, 0)
        lc.addChildToPos(progressBar, numNode, cc.p(numX, numY))
        node._numLabel = numLabel

        table.insert(nodes, node)
    end
    ]]
    progressBar.update = function (curVal)
        curVal = math.min(curVal, maxValue)
        local percent = 100 * (maxCount - 1) / maxCount * (curVal - startValue) / (maxValue - startValue)
        progressBar:setPercentage(percent)
        for i, node in ipairs(nodes) do
            --node._spr:setSpriteFrame(curVal >= node._val and data[i]._lightSpr or data[i]._darkSpr)
            --node._numLabel:setColor(curVal >= node._val and V.COLOR_TEXT_INGOT or V.COLOR_TEXT_WHITE)
        end
    end

    progressBar.updateWithAni = function (targetVal)
        progressBar:stopAllActions()
        targetVal = math.min(targetVal, maxValue)
        local currentVal = progressBar:getPercentage() / 100 * (maxValue - startValue) * maxCount / (maxCount - 1) + startValue
        local times = 60
        local speed = (targetVal - currentVal) / times
        local totalTime = 1
        progressBar:runAction(lc.ease(lc.sequence(lc.rep(lc.sequence(function()
            local percent = progressBar:getPercentage() / 100
            progressBar.update(percent * (maxValue - startValue) * maxCount / (maxCount - 1) + startValue + speed)
        end, totalTime / times), times), function() progressBar.update(targetVal) end), "SineIO"))
    end


    return progressBar
end
