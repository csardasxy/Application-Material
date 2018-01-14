local _M = ClientView


function _M.checkNewFlag(item, flag, offX, offY, flagBase)
    local isNew = (type(flag) == "boolean" and flag) or (type(flag) == "number" and flag > (flagBase or 0))
    if isNew then
        if item._newFlag == nil then
            local flagBg = lc.createSprite("img_new")
            flagBg:setPosition(lc.w(item) - 40 + (offX or 0), lc.h(item) - 10 + (offY or 0))
            item:addChild(flagBg)

            if type(flag) == "number" then
                flagBg._value = _M.createBMFont(_M.BMFont.huali_20, "00")
                flagBg._value:setScale(0.8)
                lc.addChildToPos(flagBg, flagBg._value, cc.p(lc.w(flagBg) / 2, lc.h(flagBg) / 2 + 2))
            else
                flagBg:setScale(0.9)
            end

            flagBg:setCameraMask(item:getCameraMask())
            item._newFlag = flagBg
        end

        if item._newFlag._value and type(flag) == "number" then
            item._newFlag._value:setString(string.format("%d", flag))
        end
    else
        if item._newFlag then
            item._newFlag:removeFromParent()
            item._newFlag = nil
        end
    end

    return item._newFlag
end

function _M.checkDiscountFlag(item, disCount, offX, offY)
    local disCounts = Data._globalInfo._unionShopDiscount
    if lc._runningScene._sceneId == ClientData.SceneId.tavern then
        disCounts = Data._globalInfo._magicShopDiscount
    end
    local str = ""
    if disCount > 0 and disCount <= #disCounts then
        local disCountNum = disCounts[disCount]
        str = disCountNum / 10
    end 

    

    if  str == "" then
        return nil
    end

    if item._discountFlag == nil and str ~= "" then
        local flagBg = lc.createSprite("discount_bg")
        flagBg:setPosition(lc.w(item) - 40 + (offX or 0), lc.h(item) - 10 + (offY or 0))
        flagBg:setScale(0.8)
        item:addChild(flagBg)

        flagBg._value = _M.createTTF("", V.FontSize.B2)
        lc.addChildToPos(flagBg, flagBg._value, cc.p(lc.w(flagBg) / 2 - 6, lc.h(flagBg) / 2 + 2))

        flagBg:setCameraMask(item:getCameraMask())
        item._discountFlag = flagBg
    end

    if item._discountFlag._value then
        item._discountFlag._value:setString(str)
        item._discountFlag._value:setColor(lc.Color3B.yellow)
    end

    return item._discountFlag

end