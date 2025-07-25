// Code generated by goctl. DO NOT EDIT.
// goctl 1.8.4
// Source: platform.proto

package platforminnerservice

import (
	"context"

	"github.com/og-game/game-proto/proto-gen-go/platform/v1"

	"github.com/zeromicro/go-zero/zrpc"
	"google.golang.org/grpc"
)

type (
	BetRecordListItem           = v1.BetRecordListItem
	GameInfo                    = v1.GameInfo
	GetBetRecordListReq         = v1.GetBetRecordListReq
	GetBetRecordListResp        = v1.GetBetRecordListResp
	GetDemoGameLinkReq          = v1.GetDemoGameLinkReq
	GetGameHTMLReq              = v1.GetGameHTMLReq
	GetGameHTMLResp             = v1.GetGameHTMLResp
	GetGameLinkReq              = v1.GetGameLinkReq
	GetGameLinkResp             = v1.GetGameLinkResp
	GetGameListReq              = v1.GetGameListReq
	GetGameListResp             = v1.GetGameListResp
	GetTransferRecordStatusReq  = v1.GetTransferRecordStatusReq
	GetTransferRecordStatusResp = v1.GetTransferRecordStatusResp
	GetUserBalanceReq           = v1.GetUserBalanceReq
	GetUserBalanceResp          = v1.GetUserBalanceResp
	TransferReq                 = v1.TransferReq
	TransferResp                = v1.TransferResp

	PlatformInnerService interface {
		// 获取游戏链接
		GetGameLink(ctx context.Context, in *GetGameLinkReq, opts ...grpc.CallOption) (*GetGameLinkResp, error)
		// 获取游戏试玩链接
		GetDemoGameLink(ctx context.Context, in *GetDemoGameLinkReq, opts ...grpc.CallOption) (*GetGameLinkResp, error)
		// 获取用户余额
		GetUserBalance(ctx context.Context, in *GetUserBalanceReq, opts ...grpc.CallOption) (*GetUserBalanceResp, error)
		// 转账
		Transfer(ctx context.Context, in *TransferReq, opts ...grpc.CallOption) (*TransferResp, error)
		// 获取厂商游戏列表
		GetGameList(ctx context.Context, in *GetGameListReq, opts ...grpc.CallOption) (*GetGameListResp, error)
		// 获取存取款记录状态
		GetTransferRecordStatus(ctx context.Context, in *GetTransferRecordStatusReq, opts ...grpc.CallOption) (*GetTransferRecordStatusResp, error)
		// 获取投注记录
		GetBetRecordList(ctx context.Context, in *GetBetRecordListReq, opts ...grpc.CallOption) (*GetBetRecordListResp, error)
		// 获取游戏HTML
		GetGameHTML(ctx context.Context, in *GetGameHTMLReq, opts ...grpc.CallOption) (*GetGameHTMLResp, error)
	}

	defaultPlatformInnerService struct {
		cli zrpc.Client
	}
)

func NewPlatformInnerService(cli zrpc.Client) PlatformInnerService {
	return &defaultPlatformInnerService{
		cli: cli,
	}
}

// 获取游戏链接
func (m *defaultPlatformInnerService) GetGameLink(ctx context.Context, in *GetGameLinkReq, opts ...grpc.CallOption) (*GetGameLinkResp, error) {
	client := v1.NewPlatformInnerServiceClient(m.cli.Conn())
	return client.GetGameLink(ctx, in, opts...)
}

// 获取游戏试玩链接
func (m *defaultPlatformInnerService) GetDemoGameLink(ctx context.Context, in *GetDemoGameLinkReq, opts ...grpc.CallOption) (*GetGameLinkResp, error) {
	client := v1.NewPlatformInnerServiceClient(m.cli.Conn())
	return client.GetDemoGameLink(ctx, in, opts...)
}

// 获取用户余额
func (m *defaultPlatformInnerService) GetUserBalance(ctx context.Context, in *GetUserBalanceReq, opts ...grpc.CallOption) (*GetUserBalanceResp, error) {
	client := v1.NewPlatformInnerServiceClient(m.cli.Conn())
	return client.GetUserBalance(ctx, in, opts...)
}

// 转账
func (m *defaultPlatformInnerService) Transfer(ctx context.Context, in *TransferReq, opts ...grpc.CallOption) (*TransferResp, error) {
	client := v1.NewPlatformInnerServiceClient(m.cli.Conn())
	return client.Transfer(ctx, in, opts...)
}

// 获取厂商游戏列表
func (m *defaultPlatformInnerService) GetGameList(ctx context.Context, in *GetGameListReq, opts ...grpc.CallOption) (*GetGameListResp, error) {
	client := v1.NewPlatformInnerServiceClient(m.cli.Conn())
	return client.GetGameList(ctx, in, opts...)
}

// 获取存取款记录状态
func (m *defaultPlatformInnerService) GetTransferRecordStatus(ctx context.Context, in *GetTransferRecordStatusReq, opts ...grpc.CallOption) (*GetTransferRecordStatusResp, error) {
	client := v1.NewPlatformInnerServiceClient(m.cli.Conn())
	return client.GetTransferRecordStatus(ctx, in, opts...)
}

// 获取投注记录
func (m *defaultPlatformInnerService) GetBetRecordList(ctx context.Context, in *GetBetRecordListReq, opts ...grpc.CallOption) (*GetBetRecordListResp, error) {
	client := v1.NewPlatformInnerServiceClient(m.cli.Conn())
	return client.GetBetRecordList(ctx, in, opts...)
}

// 获取游戏HTML
func (m *defaultPlatformInnerService) GetGameHTML(ctx context.Context, in *GetGameHTMLReq, opts ...grpc.CallOption) (*GetGameHTMLResp, error) {
	client := v1.NewPlatformInnerServiceClient(m.cli.Conn())
	return client.GetGameHTML(ctx, in, opts...)
}
