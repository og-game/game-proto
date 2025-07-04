// Code generated by goctl. DO NOT EDIT.
// goctl 1.8.4
// Source: fund.proto

package fundapiservice

import (
	"context"

	"github.com/og-game/game-proto/proto-gen-go/fund/v1"

	"github.com/zeromicro/go-zero/zrpc"
	"google.golang.org/grpc"
)

type (
	FundReq                 = v1.FundReq
	FundResp                = v1.FundResp
	GetUserBalanceListReq   = v1.GetUserBalanceListReq
	GetUserBalanceListResp  = v1.GetUserBalanceListResp
	GetUserBalanceReq       = v1.GetUserBalanceReq
	GetUserBalanceResp      = v1.GetUserBalanceResp
	TransactionReq          = v1.TransactionReq
	TransactionResp         = v1.TransactionResp
	TransferInProgressReq   = v1.TransferInProgressReq
	TransferInProgressResp  = v1.TransferInProgressResp
	TransferInReq           = v1.TransferInReq
	TransferInResp          = v1.TransferInResp
	TransferOutProgressReq  = v1.TransferOutProgressReq
	TransferOutProgressResp = v1.TransferOutProgressResp
	TransferOutReq          = v1.TransferOutReq
	TransferOutResp         = v1.TransferOutResp
	TransferProgressInfo    = v1.TransferProgressInfo
	UserBalanceInfo         = v1.UserBalanceInfo
	UserBalanceListReq      = v1.UserBalanceListReq
	UserBalanceListResp     = v1.UserBalanceListResp

	FundApiService interface {
		// 批量获取用户余额[实时更新的余额]
		GetUserBalanceList(ctx context.Context, in *UserBalanceListReq, opts ...grpc.CallOption) (*UserBalanceListResp, error)
		// 发起转入操作
		TransferIn(ctx context.Context, in *TransferInReq, opts ...grpc.CallOption) (*TransferInResp, error)
		// 获取转出进度状态
		GetTransferInProgress(ctx context.Context, in *TransferInProgressReq, opts ...grpc.CallOption) (*TransferInProgressResp, error)
		// 发起转出操作
		TransferOut(ctx context.Context, in *TransferOutReq, opts ...grpc.CallOption) (*TransferOutResp, error)
		// 获取转出进度状态
		GetTransferOutProgress(ctx context.Context, in *TransferOutProgressReq, opts ...grpc.CallOption) (*TransferOutProgressResp, error)
	}

	defaultFundApiService struct {
		cli zrpc.Client
	}
)

func NewFundApiService(cli zrpc.Client) FundApiService {
	return &defaultFundApiService{
		cli: cli,
	}
}

// 批量获取用户余额[实时更新的余额]
func (m *defaultFundApiService) GetUserBalanceList(ctx context.Context, in *UserBalanceListReq, opts ...grpc.CallOption) (*UserBalanceListResp, error) {
	client := v1.NewFundApiServiceClient(m.cli.Conn())
	return client.GetUserBalanceList(ctx, in, opts...)
}

// 发起转入操作
func (m *defaultFundApiService) TransferIn(ctx context.Context, in *TransferInReq, opts ...grpc.CallOption) (*TransferInResp, error) {
	client := v1.NewFundApiServiceClient(m.cli.Conn())
	return client.TransferIn(ctx, in, opts...)
}

// 获取转出进度状态
func (m *defaultFundApiService) GetTransferInProgress(ctx context.Context, in *TransferInProgressReq, opts ...grpc.CallOption) (*TransferInProgressResp, error) {
	client := v1.NewFundApiServiceClient(m.cli.Conn())
	return client.GetTransferInProgress(ctx, in, opts...)
}

// 发起转出操作
func (m *defaultFundApiService) TransferOut(ctx context.Context, in *TransferOutReq, opts ...grpc.CallOption) (*TransferOutResp, error) {
	client := v1.NewFundApiServiceClient(m.cli.Conn())
	return client.TransferOut(ctx, in, opts...)
}

// 获取转出进度状态
func (m *defaultFundApiService) GetTransferOutProgress(ctx context.Context, in *TransferOutProgressReq, opts ...grpc.CallOption) (*TransferOutProgressResp, error) {
	client := v1.NewFundApiServiceClient(m.cli.Conn())
	return client.GetTransferOutProgress(ctx, in, opts...)
}
