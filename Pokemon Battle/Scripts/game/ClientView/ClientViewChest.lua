local _M = ClientView


function _M.createClashFieldChest(grade, index, quality, isView)
--    local frame = lc.createSprite('img_slot')
--    local bg = lc.createSprite("img_card_ico_bg")
--    bg:setScale(1.1)
--    lc.addChildToCenter(frame, bg, -1)

    local bonesNames = {"1baoxiang", "2baoxiang", "3baoxiang", "4baoxiang", "5baoxiang"}

    local chest = V.createShaderButton(nil, function(chest)
        local prop = P._propBag._props[chest._infoId]
        if prop._num > 0 and not prop._isOpened and not isView then
            V.getActiveIndicator():show(Str(STR.OPENING), nil, chest)
            ClientData.sendOpenBox(chest._infoId, 1)
        else
            require("ClashChestForm").create(grade, index, quality):show()
        end
    end)
    chest:setContentSize(cc.size(100, 100))

    local bones = DragonBones.create(bonesNames[index])
    bones:setScale(0.4)
    --bones:setAnchorPoint(0.5, 0.5)
    bones:gotoAndPlay("effect4")
    lc.addChildToCenter(chest, bones)
    chest._bones = bones

--    local clrs = {cc.c3b(120, 255, 120), cc.c3b(120, 200, 255), cc.c3b(255, 120, 200), cc.c3b(255, 240, 140)}
--    local glow = lc.createSprite("img_glow_s")
--    glow:setScale(3.5)
--    glow:setColor(clrs[quality])
--    lc.addChildToCenter(frame, glow)

--    if quality > Data.CardQuality.R then
--        glow = lc.createSprite("img_glow")
--        glow:setScale(0.4)
--        glow:setColor(clrs[quality])
--        glow:runAction(lc.rep(lc.rotateBy(2, 10)))
--        lc.addChildToCenter(frame, glow)
--    end
    
--    local chest = V.createShaderButton(string.format("img_chest_close_%d", quality), function(chest)
--        local prop = P._propBag._props[chest._infoId]
--        if prop._num > 0 and not prop._isOpened and not isView then
--            V.getActiveIndicator():show(Str(STR.OPENING), nil, chest)
--            ClientData.sendOpenBox(chest._infoId, 1)
--        else
--            require("ClashChestForm").create(grade, index, quality):show()
--        end
--    end)
--    lc.addChildToPos(frame, chest, cc.p(lc.w(frame) / 2, lc.h(frame) / 2 + 4))

    chest.update = function(chest, grade)
        chest._infoId = Data.PropsId.clash_chest + 10 * (grade - 1) + index
        local prop = P._propBag._props[chest._infoId]
        
--        frame:removeChildrenByTag(1)
--        chest:removeChildrenByTag(1)

        if prop._num == 0 or isView then
--            chest:loadTextureNormal(string.format("img_chest_close_%d", quality), ccui.TextureResType.plistType)
            bones:gotoAndPlay("effect4")
        else
            --[[
            local markBg = lc.createSprite("img_com_bg_19")
            markBg:setScale(0.7)
            lc.addChildToPos(frame, markBg, cc.p(lc.w(frame) / 2, 0), 0, 1)

            local mark = V.createTTF(Str(Data._ladderInfo[grade]._nameSid), V.FontSize.S3, V.COLORS_TEXT_CLASH_GRADE[grade])
            lc.addChildToPos(frame, mark, cc.p(lc.x(markBg), lc.y(markBg) + 1), 0, 1)
            ]]

            if prop._isOpened then
--                chest:loadTextureNormal(string.format("img_chest_open_%d", quality), ccui.TextureResType.plistType)
                bones:gotoAndPlay("effect5")
            else
--                chest:loadTextureNormal(string.format("img_chest_open_%d", quality), ccui.TextureResType.plistType)
--                local light = lc.createSprite("img_chest_light")
--                light:runAction(lc.rep(lc.sequence(lc.fadeTo(2, 180), lc.fadeTo(2, 255))))
--                lc.addChildToPos(chest, light, cc.p(lc.w(chest) / 2 - 8, lc.h(chest) / 2 + 10), 0, 1)                
                bones:gotoAndPlay("effect2")
            end
        end
    end

--    chest._quality = quality
    chest:update(grade)

    return chest
end

function _M.createClashTargetChest(targetStep, openCallback)
    local bonesNames = {"1baoxiang", "1baoxiang2", "2baoxiang", "3baoxiang", "4baoxiang", "5baoxiang"}
    local targetChest = V.createShaderButton(nil, function(sender) 
        local targetStep = P:getClashTargetStep()
        local bonus = P._playerBonus._bonusClashTarget[targetStep]
        if bonus and bonus:canClaim() then
            if ClientData.claimBonus(bonus) == Data.ErrorType.ok then
                local RewardPanel = require("RewardPanel")
                RewardPanel.create(bonus, RewardPanel.MODE_CLAIM):show()
--                sender.update()±‹√‚±º¿£
                if sender._openCallback then
                    sender._openCallback()
                end
            end
        else
            require("ClashTargetChestForm").create(targetStep):show()
        end
    end)
    targetChest._openCallback = openCallback
    targetChest:setContentSize(100, 100)

    local bonus = P._playerBonus._bonusClashTarget[targetStep]

    local bone = DragonBones.create(bonesNames[targetStep])
    bone:setScale(0.4)
    bone:gotoAndPlay(bonus:canClaim() and "effect2" or (bonus._isClaimed and "effect5" or "effect4"))
    lc.addChildToCenter(targetChest, bone)
    targetChest._bones = bone

    targetChest.update = function ()
        bone:gotoAndPlay(bonus:canClaim() and "effect2" or (bonus._isClaimed and "effect5" or "effect4"))
    end

--    local glow = lc.createSprite("img_glow")
--    glow:setScale(0.4)
--    glow:setColor(cc.c3b(255, 240, 140))
--    glow:runAction(lc.rep(lc.rotateBy(2, 10)))
--    lc.addChildToCenter(targetChest, glow, -1)

    return targetChest
end