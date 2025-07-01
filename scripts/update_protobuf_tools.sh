#!/bin/bash

set -e

echo "📦 开始更新 Protocol Buffers 开发工具链..."

# 1. 更新 protoc (需要 Homebrew)
if ! command -v brew &>/dev/null; then
  echo "❌ 未安装 Homebrew，请先安装：https://brew.sh/"
  exit 1
fi

echo "🔄 正在安装/升级 protoc..."
brew install protobuf || brew upgrade protobuf

# 2. 安装最新版本的 protoc-gen-go
echo "🔄 安装最新的 protoc-gen-go..."
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest

# 3. 安装最新版本的 protoc-gen-go-grpc
echo "🔄 安装最新的 protoc-gen-go-grpc..."
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# 4. 检查路径配置
GOPATH_BIN=$(go env GOPATH)/bin
if [[ ":$PATH:" != *":$GOPATH_BIN:"* ]]; then
  echo "⚠️ 提示：$GOPATH_BIN 不在你的 PATH 中。"
  echo "➡️ 请将以下内容添加到你的 ~/.zshrc 或 ~/.bash_profile:"
  echo "export PATH=\$PATH:$GOPATH_BIN"
fi

# 5. 显示版本
echo
echo "✅ 工具安装完成，当前版本："
echo -n "protoc: "; protoc --version
echo -n "protoc-gen-go: "; protoc-gen-go --version
echo -n "protoc-gen-go-grpc: "; protoc-gen-go-grpc --version
