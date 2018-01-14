local _M = class("PlayerWorld")

function _M:ctor()
    --ClientData.addMsgListener(self, function(msg) return self:onMsg(msg) end, 0)
end

function _M:clear()
end

function _M:init(pbWorld)
    self._curLevel = {}
    for i = 1, #pbWorld.cur_levels do
        self._curLevel[#self._curLevel + 1] = pbWorld.cur_levels[i]
        print ('@@@@@@@@ LEVEL', self._curLevel[i])
    end
end

function _M:getChapterProgress(difficulty, chapterId)
    local diffcultyChapterId = difficulty * 100 + chapterId
    local totalCount, passedCount = 0, 0
    local levelInfos = {}
    for _, v in pairs(Data._levelInfo) do
        if math.floor(v._id  / 100) == diffcultyChapterId then
            totalCount = totalCount + 1
            if v._id < self._curLevel[difficulty] then passedCount = passedCount + 1 end
        end
    end
    return totalCount, passedCount
end


return _M
