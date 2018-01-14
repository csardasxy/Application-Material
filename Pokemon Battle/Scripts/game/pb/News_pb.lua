-- Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf"
local SglMsg_pb = require("SglMsg_pb")
local Data_pb = require("Data_pb")
module('News_pb')


WHAT = protobuf.EnumDescriptor()
local WHAT_E = {}
WHAT_E.PB_NEWS_PURCHASE = protobuf.EnumValueDescriptor();
WHAT_E.PB_NEWS_WAR_DECLARE = protobuf.EnumValueDescriptor();
WHAT_E.PB_NEWS_WAR_WIN = protobuf.EnumValueDescriptor();
WHAT_E.PB_NEWS_WAR_LOSE = protobuf.EnumValueDescriptor();
WHAT_E.PB_NEWS_ATTACK_WIN = protobuf.EnumValueDescriptor();
WHAT_E.PB_NEWS_DEFEND_WIN = protobuf.EnumValueDescriptor();
WHAT_E.PB_NEWS_LOTTERY = protobuf.EnumValueDescriptor();
WHAT_E.PB_NEWS_MIX = protobuf.EnumValueDescriptor();
WHAT_E.PB_NEWS_TRANSFORM = protobuf.EnumValueDescriptor();
WHAT_E.PB_NEWS_EXPEDITION = protobuf.EnumValueDescriptor();
WHAT_E.PB_NEWS_RECRUIT = protobuf.EnumValueDescriptor();
WHAT_E.PB_NEWS_VISIT = protobuf.EnumValueDescriptor();
WHAT_E.PB_NEWS_UNION_CREATE = protobuf.EnumValueDescriptor();
WHAT_E.PB_NEWS_UNION_UPGRADE = protobuf.EnumValueDescriptor();
WHAT_E.PB_NEWS_OPEN_CHEST = protobuf.EnumValueDescriptor();
WHAT_E.PB_NEWS_BUY = protobuf.EnumValueDescriptor();
WHAT_E.PB_NEWS_RANK = protobuf.EnumValueDescriptor();
WHAT_E.PB_NEWS_RANK_LADDER = protobuf.EnumValueDescriptor();
NEWS = protobuf.Descriptor()
local NEWS_F = {}
NEWS_F.WHAT_FIELD = protobuf.FieldDescriptor()
NEWS_F.PARAM_FIELD = protobuf.FieldDescriptor()
NEWS_F.USER1_FIELD = protobuf.FieldDescriptor()
NEWS_F.USER2_FIELD = protobuf.FieldDescriptor()
NEWS_F.UNION1_FIELD = protobuf.FieldDescriptor()
NEWS_F.UNION2_FIELD = protobuf.FieldDescriptor()
NEWS_F.RESOURCE_FIELD = protobuf.FieldDescriptor()
NEWS_F.TIMESTAMP_FIELD = protobuf.FieldDescriptor()
SGLNEWSMSG = protobuf.Descriptor()
local SGLNEWSMSG_F = {}
SGLNEWSMSG_F.NEWS_MAINTENANCE_REQ_FIELD = protobuf.FieldDescriptor()
SGLNEWSMSG_F.NEWS_RECEIVE_RESP_FIELD = protobuf.FieldDescriptor()
SGLNEWSMSG_F.NEWS_ANNOUNCEMENT_RESP_FIELD = protobuf.FieldDescriptor()
SGLNEWSMSG_F.NEWS_MAINTENANCE_RESP_FIELD = protobuf.FieldDescriptor()

WHAT_E.PB_NEWS_PURCHASE.name = "PB_NEWS_PURCHASE"
WHAT_E.PB_NEWS_PURCHASE.index = 0
WHAT_E.PB_NEWS_PURCHASE.number = 1
WHAT_E.PB_NEWS_WAR_DECLARE.name = "PB_NEWS_WAR_DECLARE"
WHAT_E.PB_NEWS_WAR_DECLARE.index = 1
WHAT_E.PB_NEWS_WAR_DECLARE.number = 2
WHAT_E.PB_NEWS_WAR_WIN.name = "PB_NEWS_WAR_WIN"
WHAT_E.PB_NEWS_WAR_WIN.index = 2
WHAT_E.PB_NEWS_WAR_WIN.number = 3
WHAT_E.PB_NEWS_WAR_LOSE.name = "PB_NEWS_WAR_LOSE"
WHAT_E.PB_NEWS_WAR_LOSE.index = 3
WHAT_E.PB_NEWS_WAR_LOSE.number = 4
WHAT_E.PB_NEWS_ATTACK_WIN.name = "PB_NEWS_ATTACK_WIN"
WHAT_E.PB_NEWS_ATTACK_WIN.index = 4
WHAT_E.PB_NEWS_ATTACK_WIN.number = 5
WHAT_E.PB_NEWS_DEFEND_WIN.name = "PB_NEWS_DEFEND_WIN"
WHAT_E.PB_NEWS_DEFEND_WIN.index = 5
WHAT_E.PB_NEWS_DEFEND_WIN.number = 6
WHAT_E.PB_NEWS_LOTTERY.name = "PB_NEWS_LOTTERY"
WHAT_E.PB_NEWS_LOTTERY.index = 6
WHAT_E.PB_NEWS_LOTTERY.number = 7
WHAT_E.PB_NEWS_MIX.name = "PB_NEWS_MIX"
WHAT_E.PB_NEWS_MIX.index = 7
WHAT_E.PB_NEWS_MIX.number = 8
WHAT_E.PB_NEWS_TRANSFORM.name = "PB_NEWS_TRANSFORM"
WHAT_E.PB_NEWS_TRANSFORM.index = 8
WHAT_E.PB_NEWS_TRANSFORM.number = 9
WHAT_E.PB_NEWS_EXPEDITION.name = "PB_NEWS_EXPEDITION"
WHAT_E.PB_NEWS_EXPEDITION.index = 9
WHAT_E.PB_NEWS_EXPEDITION.number = 10
WHAT_E.PB_NEWS_RECRUIT.name = "PB_NEWS_RECRUIT"
WHAT_E.PB_NEWS_RECRUIT.index = 10
WHAT_E.PB_NEWS_RECRUIT.number = 11
WHAT_E.PB_NEWS_VISIT.name = "PB_NEWS_VISIT"
WHAT_E.PB_NEWS_VISIT.index = 11
WHAT_E.PB_NEWS_VISIT.number = 12
WHAT_E.PB_NEWS_UNION_CREATE.name = "PB_NEWS_UNION_CREATE"
WHAT_E.PB_NEWS_UNION_CREATE.index = 12
WHAT_E.PB_NEWS_UNION_CREATE.number = 13
WHAT_E.PB_NEWS_UNION_UPGRADE.name = "PB_NEWS_UNION_UPGRADE"
WHAT_E.PB_NEWS_UNION_UPGRADE.index = 13
WHAT_E.PB_NEWS_UNION_UPGRADE.number = 14
WHAT_E.PB_NEWS_OPEN_CHEST.name = "PB_NEWS_OPEN_CHEST"
WHAT_E.PB_NEWS_OPEN_CHEST.index = 14
WHAT_E.PB_NEWS_OPEN_CHEST.number = 15
WHAT_E.PB_NEWS_BUY.name = "PB_NEWS_BUY"
WHAT_E.PB_NEWS_BUY.index = 15
WHAT_E.PB_NEWS_BUY.number = 16
WHAT_E.PB_NEWS_RANK.name = "PB_NEWS_RANK"
WHAT_E.PB_NEWS_RANK.index = 16
WHAT_E.PB_NEWS_RANK.number = 17
WHAT_E.PB_NEWS_RANK_LADDER.name = "PB_NEWS_RANK_LADDER"
WHAT_E.PB_NEWS_RANK_LADDER.index = 17
WHAT_E.PB_NEWS_RANK_LADDER.number = 18
WHAT.name = "What"
WHAT.full_name = ".sgland.What"
WHAT.values = {WHAT_E.PB_NEWS_PURCHASE,WHAT_E.PB_NEWS_WAR_DECLARE,WHAT_E.PB_NEWS_WAR_WIN,WHAT_E.PB_NEWS_WAR_LOSE,WHAT_E.PB_NEWS_ATTACK_WIN,WHAT_E.PB_NEWS_DEFEND_WIN,WHAT_E.PB_NEWS_LOTTERY,WHAT_E.PB_NEWS_MIX,WHAT_E.PB_NEWS_TRANSFORM,WHAT_E.PB_NEWS_EXPEDITION,WHAT_E.PB_NEWS_RECRUIT,WHAT_E.PB_NEWS_VISIT,WHAT_E.PB_NEWS_UNION_CREATE,WHAT_E.PB_NEWS_UNION_UPGRADE,WHAT_E.PB_NEWS_OPEN_CHEST,WHAT_E.PB_NEWS_BUY,WHAT_E.PB_NEWS_RANK,WHAT_E.PB_NEWS_RANK_LADDER}
NEWS_F.WHAT_FIELD.name = "what"
NEWS_F.WHAT_FIELD.full_name = ".sgland.News.what"
NEWS_F.WHAT_FIELD.number = 1
NEWS_F.WHAT_FIELD.index = 0
NEWS_F.WHAT_FIELD.label = 2
NEWS_F.WHAT_FIELD.has_default_value = false
NEWS_F.WHAT_FIELD.default_value = nil
NEWS_F.WHAT_FIELD.enum_type = WHAT
NEWS_F.WHAT_FIELD.type = 14
NEWS_F.WHAT_FIELD.cpp_type = 8

NEWS_F.PARAM_FIELD.name = "param"
NEWS_F.PARAM_FIELD.full_name = ".sgland.News.param"
NEWS_F.PARAM_FIELD.number = 2
NEWS_F.PARAM_FIELD.index = 1
NEWS_F.PARAM_FIELD.label = 1
NEWS_F.PARAM_FIELD.has_default_value = false
NEWS_F.PARAM_FIELD.default_value = 0
NEWS_F.PARAM_FIELD.type = 5
NEWS_F.PARAM_FIELD.cpp_type = 1

NEWS_F.USER1_FIELD.name = "user1"
NEWS_F.USER1_FIELD.full_name = ".sgland.News.user1"
NEWS_F.USER1_FIELD.number = 3
NEWS_F.USER1_FIELD.index = 2
NEWS_F.USER1_FIELD.label = 1
NEWS_F.USER1_FIELD.has_default_value = false
NEWS_F.USER1_FIELD.default_value = nil
NEWS_F.USER1_FIELD.message_type = Data_pb.USERINFO
NEWS_F.USER1_FIELD.type = 11
NEWS_F.USER1_FIELD.cpp_type = 10

NEWS_F.USER2_FIELD.name = "user2"
NEWS_F.USER2_FIELD.full_name = ".sgland.News.user2"
NEWS_F.USER2_FIELD.number = 4
NEWS_F.USER2_FIELD.index = 3
NEWS_F.USER2_FIELD.label = 1
NEWS_F.USER2_FIELD.has_default_value = false
NEWS_F.USER2_FIELD.default_value = nil
NEWS_F.USER2_FIELD.message_type = Data_pb.USERINFO
NEWS_F.USER2_FIELD.type = 11
NEWS_F.USER2_FIELD.cpp_type = 10

NEWS_F.UNION1_FIELD.name = "union1"
NEWS_F.UNION1_FIELD.full_name = ".sgland.News.union1"
NEWS_F.UNION1_FIELD.number = 5
NEWS_F.UNION1_FIELD.index = 4
NEWS_F.UNION1_FIELD.label = 1
NEWS_F.UNION1_FIELD.has_default_value = false
NEWS_F.UNION1_FIELD.default_value = nil
NEWS_F.UNION1_FIELD.message_type = Data_pb.UNIONINFO
NEWS_F.UNION1_FIELD.type = 11
NEWS_F.UNION1_FIELD.cpp_type = 10

NEWS_F.UNION2_FIELD.name = "union2"
NEWS_F.UNION2_FIELD.full_name = ".sgland.News.union2"
NEWS_F.UNION2_FIELD.number = 6
NEWS_F.UNION2_FIELD.index = 5
NEWS_F.UNION2_FIELD.label = 1
NEWS_F.UNION2_FIELD.has_default_value = false
NEWS_F.UNION2_FIELD.default_value = nil
NEWS_F.UNION2_FIELD.message_type = Data_pb.UNIONINFO
NEWS_F.UNION2_FIELD.type = 11
NEWS_F.UNION2_FIELD.cpp_type = 10

NEWS_F.RESOURCE_FIELD.name = "resource"
NEWS_F.RESOURCE_FIELD.full_name = ".sgland.News.resource"
NEWS_F.RESOURCE_FIELD.number = 7
NEWS_F.RESOURCE_FIELD.index = 6
NEWS_F.RESOURCE_FIELD.label = 3
NEWS_F.RESOURCE_FIELD.has_default_value = false
NEWS_F.RESOURCE_FIELD.default_value = {}
NEWS_F.RESOURCE_FIELD.message_type = Data_pb.RESOURCE
NEWS_F.RESOURCE_FIELD.type = 11
NEWS_F.RESOURCE_FIELD.cpp_type = 10

NEWS_F.TIMESTAMP_FIELD.name = "timestamp"
NEWS_F.TIMESTAMP_FIELD.full_name = ".sgland.News.timestamp"
NEWS_F.TIMESTAMP_FIELD.number = 8
NEWS_F.TIMESTAMP_FIELD.index = 7
NEWS_F.TIMESTAMP_FIELD.label = 2
NEWS_F.TIMESTAMP_FIELD.has_default_value = false
NEWS_F.TIMESTAMP_FIELD.default_value = 0
NEWS_F.TIMESTAMP_FIELD.type = 3
NEWS_F.TIMESTAMP_FIELD.cpp_type = 2

NEWS.name = "News"
NEWS.full_name = ".sgland.News"
NEWS.nested_types = {}
NEWS.enum_types = {}
NEWS.fields = {NEWS_F.WHAT_FIELD, NEWS_F.PARAM_FIELD, NEWS_F.USER1_FIELD, NEWS_F.USER2_FIELD, NEWS_F.UNION1_FIELD, NEWS_F.UNION2_FIELD, NEWS_F.RESOURCE_FIELD, NEWS_F.TIMESTAMP_FIELD}
NEWS.is_extendable = false
NEWS.extensions = {}
SGLNEWSMSG_F.NEWS_MAINTENANCE_REQ_FIELD.name = "news_maintenance_req"
SGLNEWSMSG_F.NEWS_MAINTENANCE_REQ_FIELD.full_name = ".sgland.SglNewsMsg.news_maintenance_req"
SGLNEWSMSG_F.NEWS_MAINTENANCE_REQ_FIELD.number = 1600
SGLNEWSMSG_F.NEWS_MAINTENANCE_REQ_FIELD.index = 0
SGLNEWSMSG_F.NEWS_MAINTENANCE_REQ_FIELD.label = 1
SGLNEWSMSG_F.NEWS_MAINTENANCE_REQ_FIELD.has_default_value = false
SGLNEWSMSG_F.NEWS_MAINTENANCE_REQ_FIELD.default_value = ""
SGLNEWSMSG_F.NEWS_MAINTENANCE_REQ_FIELD.type = 9
SGLNEWSMSG_F.NEWS_MAINTENANCE_REQ_FIELD.cpp_type = 9

SGLNEWSMSG_F.NEWS_RECEIVE_RESP_FIELD.name = "news_receive_resp"
SGLNEWSMSG_F.NEWS_RECEIVE_RESP_FIELD.full_name = ".sgland.SglNewsMsg.news_receive_resp"
SGLNEWSMSG_F.NEWS_RECEIVE_RESP_FIELD.number = 1600
SGLNEWSMSG_F.NEWS_RECEIVE_RESP_FIELD.index = 1
SGLNEWSMSG_F.NEWS_RECEIVE_RESP_FIELD.label = 3
SGLNEWSMSG_F.NEWS_RECEIVE_RESP_FIELD.has_default_value = false
SGLNEWSMSG_F.NEWS_RECEIVE_RESP_FIELD.default_value = {}
SGLNEWSMSG_F.NEWS_RECEIVE_RESP_FIELD.message_type = NEWS
SGLNEWSMSG_F.NEWS_RECEIVE_RESP_FIELD.type = 11
SGLNEWSMSG_F.NEWS_RECEIVE_RESP_FIELD.cpp_type = 10

SGLNEWSMSG_F.NEWS_ANNOUNCEMENT_RESP_FIELD.name = "news_announcement_resp"
SGLNEWSMSG_F.NEWS_ANNOUNCEMENT_RESP_FIELD.full_name = ".sgland.SglNewsMsg.news_announcement_resp"
SGLNEWSMSG_F.NEWS_ANNOUNCEMENT_RESP_FIELD.number = 1601
SGLNEWSMSG_F.NEWS_ANNOUNCEMENT_RESP_FIELD.index = 2
SGLNEWSMSG_F.NEWS_ANNOUNCEMENT_RESP_FIELD.label = 1
SGLNEWSMSG_F.NEWS_ANNOUNCEMENT_RESP_FIELD.has_default_value = false
SGLNEWSMSG_F.NEWS_ANNOUNCEMENT_RESP_FIELD.default_value = ""
SGLNEWSMSG_F.NEWS_ANNOUNCEMENT_RESP_FIELD.type = 9
SGLNEWSMSG_F.NEWS_ANNOUNCEMENT_RESP_FIELD.cpp_type = 9

SGLNEWSMSG_F.NEWS_MAINTENANCE_RESP_FIELD.name = "news_maintenance_resp"
SGLNEWSMSG_F.NEWS_MAINTENANCE_RESP_FIELD.full_name = ".sgland.SglNewsMsg.news_maintenance_resp"
SGLNEWSMSG_F.NEWS_MAINTENANCE_RESP_FIELD.number = 1602
SGLNEWSMSG_F.NEWS_MAINTENANCE_RESP_FIELD.index = 3
SGLNEWSMSG_F.NEWS_MAINTENANCE_RESP_FIELD.label = 1
SGLNEWSMSG_F.NEWS_MAINTENANCE_RESP_FIELD.has_default_value = false
SGLNEWSMSG_F.NEWS_MAINTENANCE_RESP_FIELD.default_value = ""
SGLNEWSMSG_F.NEWS_MAINTENANCE_RESP_FIELD.type = 9
SGLNEWSMSG_F.NEWS_MAINTENANCE_RESP_FIELD.cpp_type = 9

SGLNEWSMSG.name = "SglNewsMsg"
SGLNEWSMSG.full_name = ".sgland.SglNewsMsg"
SGLNEWSMSG.nested_types = {}
SGLNEWSMSG.enum_types = {}
SGLNEWSMSG.fields = {}
SGLNEWSMSG.is_extendable = false
SGLNEWSMSG.extensions = {SGLNEWSMSG_F.NEWS_MAINTENANCE_REQ_FIELD, SGLNEWSMSG_F.NEWS_RECEIVE_RESP_FIELD, SGLNEWSMSG_F.NEWS_ANNOUNCEMENT_RESP_FIELD, SGLNEWSMSG_F.NEWS_MAINTENANCE_RESP_FIELD}

News = protobuf.Message(NEWS)
PB_NEWS_ATTACK_WIN = 5
PB_NEWS_BUY = 16
PB_NEWS_DEFEND_WIN = 6
PB_NEWS_EXPEDITION = 10
PB_NEWS_LOTTERY = 7
PB_NEWS_MIX = 8
PB_NEWS_OPEN_CHEST = 15
PB_NEWS_PURCHASE = 1
PB_NEWS_RANK = 17
PB_NEWS_RANK_LADDER = 18
PB_NEWS_RECRUIT = 11
PB_NEWS_TRANSFORM = 9
PB_NEWS_UNION_CREATE = 13
PB_NEWS_UNION_UPGRADE = 14
PB_NEWS_VISIT = 12
PB_NEWS_WAR_DECLARE = 2
PB_NEWS_WAR_LOSE = 4
PB_NEWS_WAR_WIN = 3
SglNewsMsg = protobuf.Message(SGLNEWSMSG)

SglMsg_pb.SglReqMsg.RegisterExtension(SGLNEWSMSG_F.NEWS_MAINTENANCE_REQ_FIELD)
SglMsg_pb.SglRespMsg.RegisterExtension(SGLNEWSMSG_F.NEWS_RECEIVE_RESP_FIELD)
SglMsg_pb.SglRespMsg.RegisterExtension(SGLNEWSMSG_F.NEWS_ANNOUNCEMENT_RESP_FIELD)
SglMsg_pb.SglRespMsg.RegisterExtension(SGLNEWSMSG_F.NEWS_MAINTENANCE_RESP_FIELD)
