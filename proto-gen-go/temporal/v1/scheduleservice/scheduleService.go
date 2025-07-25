// Code generated by goctl. DO NOT EDIT.
// goctl 1.8.4
// Source: temporal.proto

package scheduleservice

import (
	"context"

	"github.com/og-game/game-proto/proto-gen-go/temporal/v1"

	"github.com/zeromicro/go-zero/zrpc"
	"google.golang.org/grpc"
)

type (
	BatchConfig                   = v1.BatchConfig
	BatchControlResult            = v1.BatchControlResult
	BatchResult                   = v1.BatchResult
	BatchTarget                   = v1.BatchTarget
	ControlOperationInfo          = v1.ControlOperationInfo
	ControlOptions                = v1.ControlOptions
	ControlWorkflowData           = v1.ControlWorkflowData
	ControlWorkflowRequest        = v1.ControlWorkflowRequest
	ControlWorkflowResponse       = v1.ControlWorkflowResponse
	DelayOptions                  = v1.DelayOptions
	ExecutionConfig               = v1.ExecutionConfig
	ExecutionInfo                 = v1.ExecutionInfo
	ListOptions                   = v1.ListOptions
	ListScheduleOptions           = v1.ListScheduleOptions
	ListSchedulesData             = v1.ListSchedulesData
	ListSchedulesRequest          = v1.ListSchedulesRequest
	ListSchedulesResponse         = v1.ListSchedulesResponse
	ListWorkflowsData             = v1.ListWorkflowsData
	ListWorkflowsRequest          = v1.ListWorkflowsRequest
	ListWorkflowsResponse         = v1.ListWorkflowsResponse
	ManageScheduleData            = v1.ManageScheduleData
	ManageScheduleRequest         = v1.ManageScheduleRequest
	ManageScheduleResponse        = v1.ManageScheduleResponse
	QueryControlOperationData     = v1.QueryControlOperationData
	QueryControlOperationRequest  = v1.QueryControlOperationRequest
	QueryControlOperationResponse = v1.QueryControlOperationResponse
	QueryOptions                  = v1.QueryOptions
	QueryScheduleRequest          = v1.QueryScheduleRequest
	QueryScheduleResponse         = v1.QueryScheduleResponse
	QueryWorkflowData             = v1.QueryWorkflowData
	QueryWorkflowRequest          = v1.QueryWorkflowRequest
	QueryWorkflowResponse         = v1.QueryWorkflowResponse
	QueryWorkflowStateData        = v1.QueryWorkflowStateData
	QueryWorkflowStateRequest     = v1.QueryWorkflowStateRequest
	QueryWorkflowStateResponse    = v1.QueryWorkflowStateResponse
	ReplaceWorkflowData           = v1.ReplaceWorkflowData
	ReplaceWorkflowRequest        = v1.ReplaceWorkflowRequest
	ReplaceWorkflowResponse       = v1.ReplaceWorkflowResponse
	ScheduleInfo                  = v1.ScheduleInfo
	SchedulePolicy                = v1.SchedulePolicy
	ScheduleResult                = v1.ScheduleResult
	ScheduleSpec                  = v1.ScheduleSpec
	SignalWithStartData           = v1.SignalWithStartData
	SignalWithStartRequest        = v1.SignalWithStartRequest
	SignalWithStartResponse       = v1.SignalWithStartResponse
	SignalWorkflowData            = v1.SignalWorkflowData
	SignalWorkflowRequest         = v1.SignalWorkflowRequest
	SignalWorkflowResponse        = v1.SignalWorkflowResponse
	SingleResult                  = v1.SingleResult
	StackFrame                    = v1.StackFrame
	StartWorkflowData             = v1.StartWorkflowData
	StartWorkflowRequest          = v1.StartWorkflowRequest
	StartWorkflowResponse         = v1.StartWorkflowResponse
	WorkflowAction                = v1.WorkflowAction
	WorkflowEvent                 = v1.WorkflowEvent
	WorkflowHistory               = v1.WorkflowHistory
	WorkflowInfo                  = v1.WorkflowInfo
	WorkflowItem                  = v1.WorkflowItem
	WorkflowStackTrace            = v1.WorkflowStackTrace
	WorkflowStatus                = v1.WorkflowStatus
	WorkflowTarget                = v1.WorkflowTarget

	ScheduleService interface {
		// 管理调度 (创建/更新/删除/暂停/恢复)
		ManageSchedule(ctx context.Context, in *ManageScheduleRequest, opts ...grpc.CallOption) (*ManageScheduleResponse, error)
		// 查询调度
		QuerySchedule(ctx context.Context, in *QueryScheduleRequest, opts ...grpc.CallOption) (*QueryScheduleResponse, error)
		// 列出调度
		ListSchedules(ctx context.Context, in *ListSchedulesRequest, opts ...grpc.CallOption) (*ListSchedulesResponse, error)
	}

	defaultScheduleService struct {
		cli zrpc.Client
	}
)

func NewScheduleService(cli zrpc.Client) ScheduleService {
	return &defaultScheduleService{
		cli: cli,
	}
}

// 管理调度 (创建/更新/删除/暂停/恢复)
func (m *defaultScheduleService) ManageSchedule(ctx context.Context, in *ManageScheduleRequest, opts ...grpc.CallOption) (*ManageScheduleResponse, error) {
	client := v1.NewScheduleServiceClient(m.cli.Conn())
	return client.ManageSchedule(ctx, in, opts...)
}

// 查询调度
func (m *defaultScheduleService) QuerySchedule(ctx context.Context, in *QueryScheduleRequest, opts ...grpc.CallOption) (*QueryScheduleResponse, error) {
	client := v1.NewScheduleServiceClient(m.cli.Conn())
	return client.QuerySchedule(ctx, in, opts...)
}

// 列出调度
func (m *defaultScheduleService) ListSchedules(ctx context.Context, in *ListSchedulesRequest, opts ...grpc.CallOption) (*ListSchedulesResponse, error) {
	client := v1.NewScheduleServiceClient(m.cli.Conn())
	return client.ListSchedules(ctx, in, opts...)
}
