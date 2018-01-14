-- Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf"
local SglMsg_pb = require("SglMsg_pb")
module('Feedback_pb')


FEEDBACKTYPE = protobuf.EnumDescriptor()
local FEEDBACKTYPE_E = {}
FEEDBACKTYPE_E.PB_FEEDBACK_CONSULT = protobuf.EnumValueDescriptor();
FEEDBACKTYPE_E.PB_FEEDBACK_BUG = protobuf.EnumValueDescriptor();
FEEDBACKTYPE_E.PB_FEEDBACK_COMPLAINT = protobuf.EnumValueDescriptor();
FEEDBACKTYPE_E.PB_FEEDBACK_SUGGESTION = protobuf.EnumValueDescriptor();
FEEDBACKREQ = protobuf.Descriptor()
local FEEDBACKREQ_F = {}
FEEDBACKREQ_F.TYPE_FIELD = protobuf.FieldDescriptor()
FEEDBACKREQ_F.CONTENT_FIELD = protobuf.FieldDescriptor()
SGLFEEDBACKMSG = protobuf.Descriptor()
local SGLFEEDBACKMSG_F = {}
SGLFEEDBACKMSG_F.FEEDBACK_REQ_FIELD = protobuf.FieldDescriptor()

FEEDBACKTYPE_E.PB_FEEDBACK_CONSULT.name = "PB_FEEDBACK_CONSULT"
FEEDBACKTYPE_E.PB_FEEDBACK_CONSULT.index = 0
FEEDBACKTYPE_E.PB_FEEDBACK_CONSULT.number = 1
FEEDBACKTYPE_E.PB_FEEDBACK_BUG.name = "PB_FEEDBACK_BUG"
FEEDBACKTYPE_E.PB_FEEDBACK_BUG.index = 1
FEEDBACKTYPE_E.PB_FEEDBACK_BUG.number = 2
FEEDBACKTYPE_E.PB_FEEDBACK_COMPLAINT.name = "PB_FEEDBACK_COMPLAINT"
FEEDBACKTYPE_E.PB_FEEDBACK_COMPLAINT.index = 2
FEEDBACKTYPE_E.PB_FEEDBACK_COMPLAINT.number = 3
FEEDBACKTYPE_E.PB_FEEDBACK_SUGGESTION.name = "PB_FEEDBACK_SUGGESTION"
FEEDBACKTYPE_E.PB_FEEDBACK_SUGGESTION.index = 3
FEEDBACKTYPE_E.PB_FEEDBACK_SUGGESTION.number = 4
FEEDBACKTYPE.name = "FeedbackType"
FEEDBACKTYPE.full_name = ".sgland.FeedbackType"
FEEDBACKTYPE.values = {FEEDBACKTYPE_E.PB_FEEDBACK_CONSULT,FEEDBACKTYPE_E.PB_FEEDBACK_BUG,FEEDBACKTYPE_E.PB_FEEDBACK_COMPLAINT,FEEDBACKTYPE_E.PB_FEEDBACK_SUGGESTION}
FEEDBACKREQ_F.TYPE_FIELD.name = "type"
FEEDBACKREQ_F.TYPE_FIELD.full_name = ".sgland.FeedbackReq.type"
FEEDBACKREQ_F.TYPE_FIELD.number = 1
FEEDBACKREQ_F.TYPE_FIELD.index = 0
FEEDBACKREQ_F.TYPE_FIELD.label = 2
FEEDBACKREQ_F.TYPE_FIELD.has_default_value = false
FEEDBACKREQ_F.TYPE_FIELD.default_value = nil
FEEDBACKREQ_F.TYPE_FIELD.enum_type = FEEDBACKTYPE
FEEDBACKREQ_F.TYPE_FIELD.type = 14
FEEDBACKREQ_F.TYPE_FIELD.cpp_type = 8

FEEDBACKREQ_F.CONTENT_FIELD.name = "content"
FEEDBACKREQ_F.CONTENT_FIELD.full_name = ".sgland.FeedbackReq.content"
FEEDBACKREQ_F.CONTENT_FIELD.number = 2
FEEDBACKREQ_F.CONTENT_FIELD.index = 1
FEEDBACKREQ_F.CONTENT_FIELD.label = 2
FEEDBACKREQ_F.CONTENT_FIELD.has_default_value = false
FEEDBACKREQ_F.CONTENT_FIELD.default_value = ""
FEEDBACKREQ_F.CONTENT_FIELD.type = 9
FEEDBACKREQ_F.CONTENT_FIELD.cpp_type = 9

FEEDBACKREQ.name = "FeedbackReq"
FEEDBACKREQ.full_name = ".sgland.FeedbackReq"
FEEDBACKREQ.nested_types = {}
FEEDBACKREQ.enum_types = {}
FEEDBACKREQ.fields = {FEEDBACKREQ_F.TYPE_FIELD, FEEDBACKREQ_F.CONTENT_FIELD}
FEEDBACKREQ.is_extendable = false
FEEDBACKREQ.extensions = {}
SGLFEEDBACKMSG_F.FEEDBACK_REQ_FIELD.name = "feedback_req"
SGLFEEDBACKMSG_F.FEEDBACK_REQ_FIELD.full_name = ".sgland.SglFeedbackMsg.feedback_req"
SGLFEEDBACKMSG_F.FEEDBACK_REQ_FIELD.number = 1300
SGLFEEDBACKMSG_F.FEEDBACK_REQ_FIELD.index = 0
SGLFEEDBACKMSG_F.FEEDBACK_REQ_FIELD.label = 1
SGLFEEDBACKMSG_F.FEEDBACK_REQ_FIELD.has_default_value = false
SGLFEEDBACKMSG_F.FEEDBACK_REQ_FIELD.default_value = nil
SGLFEEDBACKMSG_F.FEEDBACK_REQ_FIELD.message_type = FEEDBACKREQ
SGLFEEDBACKMSG_F.FEEDBACK_REQ_FIELD.type = 11
SGLFEEDBACKMSG_F.FEEDBACK_REQ_FIELD.cpp_type = 10

SGLFEEDBACKMSG.name = "SglFeedbackMsg"
SGLFEEDBACKMSG.full_name = ".sgland.SglFeedbackMsg"
SGLFEEDBACKMSG.nested_types = {}
SGLFEEDBACKMSG.enum_types = {}
SGLFEEDBACKMSG.fields = {}
SGLFEEDBACKMSG.is_extendable = false
SGLFEEDBACKMSG.extensions = {SGLFEEDBACKMSG_F.FEEDBACK_REQ_FIELD}

FeedbackReq = protobuf.Message(FEEDBACKREQ)
PB_FEEDBACK_BUG = 2
PB_FEEDBACK_COMPLAINT = 3
PB_FEEDBACK_CONSULT = 1
PB_FEEDBACK_SUGGESTION = 4
SglFeedbackMsg = protobuf.Message(SGLFEEDBACKMSG)

SglMsg_pb.SglReqMsg.RegisterExtension(SGLFEEDBACKMSG_F.FEEDBACK_REQ_FIELD)
