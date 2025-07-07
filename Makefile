# Makefile
# 用于管理 Proto 和 RPC 服务生成

# 设置变量
SCRIPT := ./scripts/gen-proto.sh

# 自动扫描服务或使用默认值
PROTO_DIR := proto
AVAILABLE_SERVICES := $(shell find $(PROTO_DIR) -maxdepth 1 -type d -not -path $(PROTO_DIR) -not -path $(PROTO_DIR)/common -exec basename {} \; 2>/dev/null | sort)
SERVICES ?= $(if $(AVAILABLE_SERVICES),$(AVAILABLE_SERVICES),fund game manage platform temporal)

# 颜色定义
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# 默认目标
.PHONY: all
all: gengo genrpc
	@echo "$(GREEN)✓ 所有任务完成！$(NC)"

# 显示帮助
.PHONY: help
help:
	@echo "$(BLUE)============================================$(NC)"
	@echo "$(BLUE)Game Center Model - Makefile$(NC)"
	@echo "$(BLUE)============================================$(NC)"
	@echo ""
	@echo "$(YELLOW)当前检测到的服务:$(NC) $(SERVICES)"
	@echo ""
	@echo "$(YELLOW)基础命令:$(NC)"
	@echo "  make gengo              # 生成所有 Proto PB 文件"
	@echo "  make genrpc             # 生成所有 RPC 服务"
	@echo "  make all                # 生成 Proto 和 RPC（默认）"
	@echo "  make info               # 显示服务信息"
	@echo "  make clean              # 清理所有生成的文件"
	@echo ""
	@echo "$(YELLOW)RPC 相关:$(NC)"
	@echo "  make genrpc-SERVICE     # 生成指定服务 (可用: $(SERVICES))"
	@echo ""
	@echo "$(YELLOW)服务控制:$(NC)"
	@echo "  SERVICES='game fund' make gengo    # 只处理指定的服务"
	@echo "  SERVICES='game' make genrpc        # 只生成指定服务的 RPC"
	@echo ""
	@echo "$(YELLOW)其他命令:$(NC)"
	@echo "  make install-deps       # 安装必要的依赖工具"
	@echo "  make check-deps         # 检查依赖是否已安装"
	@echo ""
	@echo "$(YELLOW)环境变量:$(NC)"
	@echo "  VERBOSE=1 make gengo    # 启用详细输出"
	@echo "  SERVICES='...'          # 指定要处理的服务列表"

# 生成所有 Proto PB 文件
.PHONY: gengo
gengo: check-script
	@echo "$(YELLOW)>>> 生成 Proto PB 文件...$(NC)"
	@echo "$(BLUE)处理服务: $(SERVICES)$(NC)"
	@SERVICES_LIST="$(SERVICES)" $(SCRIPT) proto $(if $(VERBOSE),-v)

# 生成所有 RPC 服务
.PHONY: genrpc
genrpc: check-script
	@echo "$(YELLOW)>>> 生成 RPC 服务...$(NC)"
	@echo "$(BLUE)处理服务: $(SERVICES)$(NC)"
	@SERVICES_LIST="$(SERVICES)" $(SCRIPT) rpc $(if $(SERVICE),$(SERVICE)) $(if $(VERBOSE),-v)

# 通用规则：生成特定的 RPC 服务
# 使用模式规则，这样任何 genrpc-xxx 都会被匹配
.PHONY: genrpc-%
genrpc-%: check-script
	@service=$$(echo $* | tr A-Z a-z); \
	if echo " $(SERVICES) " | grep -q " $$service "; then \
		echo "$(YELLOW)>>> 生成 $$service RPC 服务...$(NC)"; \
		SERVICES_LIST="$$service" $(SCRIPT) rpc $$service $(if $(VERBOSE),-v); \
	else \
		echo "$(RED)错误: 未知的服务 '$$service'$(NC)"; \
		echo "$(YELLOW)可用的服务: $(SERVICES)$(NC)"; \
		exit 1; \
	fi

# 显示服务信息
.PHONY: info
info: check-script
	@SERVICES_LIST="$(SERVICES)" $(SCRIPT) info

# 清理生成的文件
.PHONY: clean
clean: check-script
	@echo "$(YELLOW)>>> 清理生成的文件...$(NC)"
	@SERVICES_LIST="$(SERVICES)" $(SCRIPT) clean

# 安装依赖
.PHONY: install-deps
install-deps:
	@echo "$(YELLOW)>>> 安装依赖工具...$(NC)"
	@echo "$(BLUE)安装 protoc-gen-go...$(NC)"
	@go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	@echo "$(BLUE)安装 protoc-gen-go-grpc...$(NC)"
	@go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
	@echo "$(BLUE)安装 goctl...$(NC)"
	@go install github.com/zeromicro/go-zero/tools/goctl@latest
	@echo "$(GREEN)✓ 依赖安装完成！$(NC)"
	@echo ""
	@echo "$(YELLOW)注意: protoc 需要手动安装$(NC)"
	@echo "访问: https://grpc.io/docs/protoc-installation/"

# 检查依赖
.PHONY: check-deps
check-deps:
	@echo "$(YELLOW)>>> 检查依赖工具...$(NC)"
	@command -v protoc >/dev/null 2>&1 && echo "$(GREEN)✓ protoc 已安装$(NC)" || echo "$(RED)✗ protoc 未安装$(NC)"
	@command -v protoc-gen-go >/dev/null 2>&1 && echo "$(GREEN)✓ protoc-gen-go 已安装$(NC)" || echo "$(RED)✗ protoc-gen-go 未安装$(NC)"
	@command -v protoc-gen-go-grpc >/dev/null 2>&1 && echo "$(GREEN)✓ protoc-gen-go-grpc 已安装$(NC)" || echo "$(RED)✗ protoc-gen-go-grpc 未安装$(NC)"
	@command -v goctl >/dev/null 2>&1 && echo "$(GREEN)✓ goctl 已安装$(NC)" || echo "$(RED)✗ goctl 未安装$(NC)"

# 快速命令（简写）
.PHONY: g r a c i
g: gengo
r: genrpc
a: all
c: clean
i: info

# 开发工作流
.PHONY: dev
dev: clean gengo genrpc
	@echo "$(GREEN)✓ 开发环境准备完成！$(NC)"

# 检查脚本是否存在
.PHONY: check-script
check-script:
	@if [ ! -f "$(SCRIPT)" ]; then \
		echo "$(RED)错误: $(SCRIPT) 不存在$(NC)"; \
		echo "请确保 gen-proto.sh 在 scripts 目录"; \
		exit 1; \
	fi
	@if [ ! -x "$(SCRIPT)" ]; then \
		echo "$(YELLOW)添加执行权限...$(NC)"; \
		chmod +x $(SCRIPT); \
	fi

# 列出所有服务
.PHONY: list-services
list-services:
	@echo "$(YELLOW)可用的服务:$(NC)"
	@for service in $(SERVICES); do \
		echo "  - $$service"; \
	done
