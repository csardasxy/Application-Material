local _M = ClientView


function _M.popScene(isToRoot)
    -- Make sure all guide stuffs are released
    GuideManager.stopGuide()
    
    if isToRoot then
        lc.Director:popToRootScene()
    else
        lc.Director:popScene()
    end
end

function _M.popSceneTo(sceneId)
    local sceneList, level = BaseScene._sceneList
    for i, scene in ipairs(sceneList) do
        if scene._sceneId == sceneId then
            level = i
            break
        end
    end

    if level then
        -- Make sure all guide stuffs are released
        GuideManager.stopGuide()

        lc.Director:popToSceneStackLevel(level)
    end
end

function _M.isInBattleScene()
    local rootScene = BaseScene._sceneList[1]
    if rootScene then
        return rootScene._sceneId == ClientData.SceneId.battle
    end

    return false
end

function _M.hasWorldScene()
    local scene = BaseScene._sceneList[2]
    return scene and scene._sceneId == ClientData.SceneId.world
end
