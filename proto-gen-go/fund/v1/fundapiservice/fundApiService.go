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
	BaseResponse               = v1.BaseResponse
	CreateUserBalanceRecordReq = v1.CreateUserBalanceRecordReq
	FundReq                    = v1.FundReq
	FundResp                   = v1.FundResp
	GameTransactionReq         = v1.GameTransactionReq
	GameTransactionResp        = v1.GameTransactionResp
	GetUserBalanceReq          = v1.GetUserBalanceReq
	GetUserBalanceResp         = v1.GetUserBalanceResp
	SaveGameRecordReq          = v1.SaveGameRecordReq
	TransactionData            = v1.TransactionData
	TransactionReqInfo         = v1.TransactionReqInfo
	TransferInData             = v1.TransferInData
	TransferInReq              = v1.TransferInReq
	TransferInResp             = v1.TransferInResp
	TransferOutData            = v1.TransferOutData
	TransferOutReq             = v1.TransferOutReq
	TransferOutResp            = v1.TransferOutResp
	TransferProgressData       = v1.TransferProgressData
	TransferProgressInfo       = v1.TransferProgressInfo
	TransferProgressReq        = v1.TransferProgressReq
	TransferProgressResp       = v1.TransferProgressResp
	TransferStatusUpdateData   = v1.TransferStatusUpdateData
	TransferStatusUpdateReq    = v1.TransferStatusUpdateReq
	TransferStatusUpdateResp   = v1.TransferStatusUpdateResp
	UserBalanceInfo            = v1.UserBalanceInfo
	UserBalanceListData        = v1.UserBalanceListData
	UserBalanceListReq         = v1.UserBalanceListReq
	UserBalanceListResp        = v1.UserBalanceListResp
	UserBalanceRecordItem      = v1.UserBalanceRecordItem

	FundApiService interface {
		// 批量获取用户余额[实时更新的余额]
		GetUserBalanceList(ctx context.Context, in *UserBalanceListReq, opts ...grpc.CallOption) (*UserBalanceListResp, error)
		// 发起转入操作
		TransferIn(ctx context.Context, in *TransferInReq, opts ...grpc.CallOption) (*TransferInResp, error)
		// 发起转出操作
		TransferOut(ctx context.Context, in *TransferOutReq, opts ...grpc.CallOption) (*TransferOutResp, error)
		// 获取转账进度状态
		GetTransferProgress(ctx context.Context, in *TransferProgressReq, opts ...grpc.CallOption) (*TransferProgressResp, error)
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

// 发起转出操作
func (m *defaultFundApiService) TransferOut(ctx context.Context, in *TransferOutReq, opts ...grpc.CallOption) (*TransferOutResp, error) {
	client := v1.NewFundApiServiceClient(m.cli.Conn())
	return client.TransferOut(ctx, in, opts...)
}

// 获取转账进度状态
func (m *defaultFundApiService) GetTransferProgress(ctx context.Context, in *TransferProgressReq, opts ...grpc.CallOption) (*TransferProgressResp, error) {
	client := v1.NewFundApiServiceClient(m.cli.Conn())
	return client.GetTransferProgress(ctx, in, opts...)
}
