# Game Proto & RPC Gateway 使用说明

本项目依赖于 `game-proto` 和 `rpc-gateway` 目录结构，务必将两个项目目录保持在**同一级目录**下，例如：

```
/your-workspace/
├── game-proto
└── rpc-gateway
```

## 一、生成 proto Go 文件

进入 `game-proto` 项目目录，执行以下命令以生成 `.pb.go` 文件：

```bash
make gengo
```

> 该命令会根据 proto 文件生成对应的 Go 文件，供各 RPC 服务调用。

## 二、生成 RPC 服务代码

继续在 `game-proto` 目录中执行：

```bash
make genrpc-服务名
```

支持的服务名包括（默认）：

* `fund`
* `game`
* `manage`
* `platform`

示例：

```bash
make genrpc-fund
```

将会根据对应的 proto 文件生成该服务的 go-zero RPC 模块代码。

## 三、新增 RPC 服务

如需新增其他服务，有两种方式配置服务名：

### 方法一：修改 `gen-proto.sh`

编辑 `gen-proto.sh` 脚本，向 `SERVICES` 变量中添加新的服务名，例如：

```bash
SERVICES=("fund" "game" "manage" "platform" "newservice")
```

### 方法二：使用环境变量指定服务列表

你也可以在执行 `make` 前，通过 `SERVICES_LIST` 环境变量覆盖默认服务列表：

```bash
SERVICES_LIST="newservice otherservice" make genrpc-newservice
```

---

## 四、在其他服务中使用 game-proto

如需在其他服务中引用 `game-proto` 中的 `.pb.go` 文件和定义，需要在对应项目中执行以下命令拉取依赖：

```bash
go get github.com/og-game/game-proto
```

确保 `game-proto` 已经推送至对应的 Git 仓库，且路径正确。

---
