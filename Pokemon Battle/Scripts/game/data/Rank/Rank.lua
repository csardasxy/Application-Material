local _M = class("Rank")

function _M:set(pbRank, type, subType)
    if type == SglMsgType_pb.PB_TYPE_RANK_UNION_LEVEL or type == SglMsgType_pb.PB_TYPE_RANK_UBOSS_TIME or type == SglMsgType_pb.PB_TYPE_RANK_UNION_TROPHY then
        self._union = require("Union").create(pbRank.union_info)
        self._id = self._union._id

    elseif type == SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_TEAM or type == SglMsgType_pb.PB_TYPE_RANK_MASSWAR_MULTIPLE_PRE_TEAM then
        local groupInfo = pbRank.team
        local memInfos = groupInfo.user_info
        local mems = {}
        for j = 1,  #memInfos do
            local memInfo = memInfos[j]
            table.insert(mems, require("User").create(memInfo))
        end
        local group = require("Group").create({_pb = groupInfo, _members = mems})
        self._group = group
    else
        self._user = require("User").create(pbRank.user_info)
        self._id = self._user._id
    end

    self._value = pbRank.value
    self._rank = pbRank.rank
    self._type = type
    self._subType = subType
end

return _M
