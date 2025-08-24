#!/bin/bash

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 获取脚本路径
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MODEL_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$MODEL_ROOT")"

# 路径定义
PROTO_ROOT="${MODEL_ROOT}/proto"
RPC_GATEWAY_ROOT="${PROJECT_ROOT}/rpc-gateway"
APP_DIR="${RPC_GATEWAY_ROOT}/app"
PROTO_GEN_GO="${MODEL_ROOT}/proto-gen-go"
LOCAL_PROTOBUF_DIR="${MODEL_ROOT}/.protobuf-deps"

# 服务列表 - 可以从环境变量或参数传入
if [ -n "$SERVICES_LIST" ]; then
    IFS=' ' read -ra SERVICES <<< "$SERVICES_LIST"
else
    SERVICES=("fund" "notifier" "manage" "platform" "temporal" "workflow")
fi

# 检查依赖
check_dependencies() {
    echo -e "${YELLOW}检查依赖工具...${NC}"

    local deps_missing=false

    if ! command -v protoc &> /dev/null; then
        echo -e "${RED}✗ protoc 未安装${NC}"
        deps_missing=true
    else
        echo -e "${GREEN}✓ protoc 已安装${NC}"
    fi

    if ! command -v protoc-gen-go &> /dev/null; then
        echo -e "${RED}✗ protoc-gen-go 未安装${NC}"
        deps_missing=true
    else
        echo -e "${GREEN}✓ protoc-gen-go 已安装${NC}"
    fi

    if ! command -v protoc-gen-go-grpc &> /dev/null; then
        echo -e "${RED}✗ protoc-gen-go-grpc 未安装${NC}"
        deps_missing=true
    else
        echo -e "${GREEN}✓ protoc-gen-go-grpc 已安装${NC}"
    fi

    if ! command -v goctl &> /dev/null; then
        echo -e "${RED}✗ goctl 未安装${NC}"
        deps_missing=true
    else
        echo -e "${GREEN}✓ goctl 已安装${NC}"
    fi

    if [ "$deps_missing" = true ]; then
        echo -e "${RED}请安装缺失的依赖后重试${NC}"
        exit 1
    fi

    echo -e "${GREEN}所有依赖检查通过！${NC}"
}


# 检查 protobuf 标准库文件
check_protobuf_stdlib() {
    echo -e "\n${YELLOW}检查 protobuf 标准库...${NC}"

    local protobuf_paths=()

    # 检查 Homebrew 路径
    if command -v brew >/dev/null 2>&1; then
        local brew_protobuf="$(brew --prefix protobuf 2>/dev/null || true)"
        if [ -n "$brew_protobuf" ] && [ -f "$brew_protobuf/include/google/protobuf/timestamp.proto" ]; then
            protobuf_paths+=("$brew_protobuf/include")
            echo -e "${GREEN}✓ 找到 Homebrew protobuf: $brew_protobuf/include${NC}"
        fi
    fi

    # 检查系统路径
    for sys_path in "/usr/local/include" "/usr/include" "/opt/local/include"; do
        if [ -f "$sys_path/google/protobuf/timestamp.proto" ]; then
            protobuf_paths+=("$sys_path")
            echo -e "${GREEN}✓ 找到系统 protobuf: $sys_path${NC}"
            break
        fi
    done

    # 检查本地下载路径
    if [ -f "$LOCAL_PROTOBUF_DIR/include/google/protobuf/timestamp.proto" ]; then
        protobuf_paths+=("$LOCAL_PROTOBUF_DIR/include")
        echo -e "${GREEN}✓ 找到本地 protobuf: $LOCAL_PROTOBUF_DIR/include${NC}"
    fi

    if [ ${#protobuf_paths[@]} -eq 0 ]; then
        echo -e "${YELLOW}✗ 未找到 protobuf 标准库，将自动下载${NC}"
        return 1
    fi

    # 导出找到的路径供其他函数使用
    export PROTOBUF_INCLUDE_PATHS="${protobuf_paths[*]}"
    return 0
}

# 自动安装 protobuf 依赖
install_protobuf_deps() {
    echo -e "\n${YELLOW}========== 自动安装 protobuf 依赖 ==========${NC}"

    # 方法1: 尝试使用 Homebrew 安装
    if command -v brew >/dev/null 2>&1; then
        echo -e "${CYAN}尝试使用 Homebrew 安装 protobuf...${NC}"

        if brew install protobuf 2>/dev/null; then
            echo -e "${GREEN}✓ Homebrew 安装 protobuf 成功${NC}"

            # 验证安装
            local brew_protobuf="$(brew --prefix protobuf)"
            if [ -f "$brew_protobuf/include/google/protobuf/timestamp.proto" ]; then
                export PROTOBUF_INCLUDE_PATHS="$brew_protobuf/include"
                echo -e "${GREEN}✓ 验证 Homebrew protobuf 安装成功${NC}"
                return 0
            fi
        else
            echo -e "${YELLOW}! Homebrew 安装失败，尝试手动下载${NC}"
        fi
    else
        echo -e "${YELLOW}! 未找到 Homebrew，尝试手动下载${NC}"
    fi

    # 方法2: 手动下载标准 proto 文件
    echo -e "${CYAN}手动下载 protobuf 标准库文件...${NC}"

    local include_dir="$LOCAL_PROTOBUF_DIR/include/google/protobuf"
    mkdir -p "$include_dir"

    # 要下载的标准 proto 文件列表
    local proto_files=(
        "timestamp.proto"
        "any.proto"
        "duration.proto"
        "descriptor.proto"
        "empty.proto"
        "field_mask.proto"
        "struct.proto"
        "wrappers.proto"
        "source_context.proto"
        "type.proto"
        "api.proto"
    )

    local base_url="https://raw.githubusercontent.com/protocolbuffers/protobuf/main/src/google/protobuf"
    local success_count=0

    for proto_file in "${proto_files[@]}"; do
        echo -e "  ${CYAN}下载: $proto_file${NC}"

        if curl -sSL -o "$include_dir/$proto_file" "$base_url/$proto_file" 2>/dev/null; then
            echo -e "    ${GREEN}✓ 成功${NC}"
            ((success_count++))
        else
            echo -e "    ${YELLOW}! 失败，但继续${NC}"
        fi
    done

    if [ $success_count -gt 0 ]; then
        export PROTOBUF_INCLUDE_PATHS="$LOCAL_PROTOBUF_DIR/include"
        echo -e "${GREEN}✓ 手动下载 protobuf 文件成功 ($success_count 个文件)${NC}"

        # 验证关键文件
        if [ -f "$include_dir/timestamp.proto" ] && [ -f "$include_dir/any.proto" ]; then
            echo -e "${GREEN}✓ 验证关键文件存在${NC}"
            return 0
        fi
    fi

    echo -e "${RED}✗ 无法获取 protobuf 标准库文件${NC}"
    return 1
}

# 确保 protobuf 依赖可用
ensure_protobuf_deps() {
    if ! check_protobuf_stdlib; then
        echo -e "${YELLOW}正在自动下载 protobuf 依赖...${NC}"

        if ! install_protobuf_deps; then
            echo -e "${RED}错误: 无法安装 protobuf 依赖${NC}"
            echo -e "${YELLOW}请手动安装: brew install protobuf${NC}"
            exit 1
        fi

        # 重新检查
        if ! check_protobuf_stdlib; then
            echo -e "${RED}错误: 安装后仍无法找到 protobuf 标准库${NC}"
            exit 1
        fi
    fi

    echo -e "${GREEN}✓ protobuf 依赖已就绪${NC}"
}


# 生成 Proto PB 文件
generate_proto() {
    echo -e "\n${YELLOW}========== 生成 Proto PB 文件 ==========${NC}"

    # 确保 protobuf 依赖可用
    ensure_protobuf_deps

    # 确保输出目录存在
    mkdir -p "$PROTO_GEN_GO"

    # 获取 protobuf 包含路径
    local protobuf_paths=($PROTOBUF_INCLUDE_PATHS)
    echo -e "${CYAN}使用 protobuf 包含路径: ${protobuf_paths[*]}${NC}"

    # 查找所有 proto 文件
    local proto_files=$(find "${PROTO_ROOT}" -name "*.proto" -type f)
    local count=0
    local failed=0

    for proto_file in $proto_files; do
        # 获取相对路径
        local relative_path="${proto_file#${PROTO_ROOT}/}"
        local output_dir="${PROTO_GEN_GO}/$(dirname "$relative_path")"

        # 创建输出目录
        mkdir -p "$output_dir"

        echo -e "${CYAN}生成: ${relative_path}${NC}"

        # 构建 protoc 参数
        local protoc_args=(
            "--proto_path=${PROTO_ROOT}"
        )

        # 添加所有 protobuf 包含路径
        for path in "${protobuf_paths[@]}"; do
            if [ -n "$path" ]; then
                protoc_args+=("--proto_path=${path}")
            fi
        done

        protoc_args+=(
            "--go_out=${PROTO_GEN_GO}"
            "--go_opt=paths=source_relative"
            "--go-grpc_out=${PROTO_GEN_GO}"
            "--go-grpc_opt=paths=source_relative"
            "$proto_file"
        )

        # 生成 pb 文件
        if protoc "${protoc_args[@]}"; then
            ((count++))
        else
            echo -e "${RED}  ✗ 失败: ${relative_path}${NC}"
            ((failed++))
        fi
    done

    echo -e "\n${YELLOW}========== Proto 生成结果 ==========${NC}"
    echo -e "成功: ${GREEN}${count}${NC} 个文件"
    echo -e "失败: ${RED}${failed}${NC} 个文件"

    [ $failed -eq 0 ]
}



# 生成 Proto PB 文件
#generate_proto() {
#    echo -e "\n${YELLOW}========== 生成 Proto PB 文件 ==========${NC}"
#
#    # 确保输出目录存在
#    mkdir -p "$PROTO_GEN_GO"
#
#    # 查找所有 proto 文件
#    local proto_files=$(find "${PROTO_ROOT}" -name "*.proto" -type f)
#    local count=0
#    local failed=0
#
#    for proto_file in $proto_files; do
#        # 获取相对路径
#        local relative_path="${proto_file#${PROTO_ROOT}/}"
#        local output_dir="${PROTO_GEN_GO}/$(dirname "$relative_path")"
#
#        # 创建输出目录
#        mkdir -p "$output_dir"
#
#        echo -e "${CYAN}生成: ${relative_path}${NC}"
#
#        # 生成 pb 文件
#        if protoc \
#            --proto_path="${PROTO_ROOT}" \
#            --go_out="${PROTO_GEN_GO}" \
#            --go_opt=paths=source_relative \
#            --go-grpc_out="${PROTO_GEN_GO}" \
#            --go-grpc_opt=paths=source_relative \
#            "$proto_file"; then
#            ((count++))
#        else
#            echo -e "${RED}  ✗ 失败: ${relative_path}${NC}"
#            ((failed++))
#        fi
#    done
#
#    echo -e "\n${YELLOW}========== Proto 生成结果 ==========${NC}"
#    echo -e "成功: ${GREEN}${count}${NC} 个文件"
#    echo -e "失败: ${RED}${failed}${NC} 个文件"
#
#    [ $failed -eq 0 ]
#}

# 查找服务的主 proto 文件（优先查找 v1 目录）
find_main_proto() {
    local service=$1

    # 首先检查 v1 目录下的同名文件
    if [ -f "${PROTO_ROOT}/${service}/v1/${service}.proto" ]; then
        echo "${service}/v1/${service}.proto"
        return 0
    fi

    # 查找包含 service 定义的 proto 文件
    local proto_files=$(find "${PROTO_ROOT}/${service}" -name "*.proto" -type f 2>/dev/null)

    for proto_file in $proto_files; do
        if grep -q "^service" "$proto_file" 2>/dev/null; then
            echo "${proto_file#${PROTO_ROOT}/}"
            return 0
        fi
    done

    return 1
}

# 解析 proto 文件的依赖
parse_proto_dependencies() {
    local proto_file=$1
    local dependencies=()

    echo -e "${CYAN}  分析 proto 文件依赖: $(basename "$proto_file")${NC}"

    # 解析 import 语句
    while IFS= read -r line; do
        if [[ $line =~ ^import[[:space:]]+\"(.+)\" ]]; then
            local import_file="${BASH_REMATCH[1]}"
            dependencies+=("$import_file")
            echo -e "    ${YELLOW}发现依赖: $import_file${NC}"
        fi
    done < "$proto_file"

    printf '%s\n' "${dependencies[@]}"
}

# 复制依赖的 pb 文件到服务目录
copy_proto_dependencies() {
    local service=$1
    local main_proto_file="${PROTO_ROOT}/$(find_main_proto "$service")"
    local service_pb_dir="${APP_DIR}/${service}/pb/v1"

    echo -e "${CYAN}  复制 ${service} 相关的 PB 文件...${NC}"

    # 确保 pb 目录存在
    mkdir -p "$service_pb_dir"

    # 解析依赖
    local dependencies=($(parse_proto_dependencies "$main_proto_file"))

    # 复制依赖的 pb 文件
    for dep in "${dependencies[@]}"; do

         # 跳过 common 目录下的依赖
         if [[ "$dep" == common/* ]]; then
             echo -e "    ${YELLOW}跳过 common 依赖: $dep${NC}"
             continue
         fi

        # 将 import 路径转换为对应的 pb 文件路径
        local dep_dir=$(dirname "$dep")
        local dep_name=$(basename "$dep" .proto)

        echo -e "    ${CYAN}处理依赖: $dep${NC}"

        # 查找对应的 pb 文件（包括 _grpc.pb.go 和 .pb.go）
        local pb_files=$(find "${PROTO_GEN_GO}/${dep_dir}" -name "${dep_name}*.pb.go" 2>/dev/null)

        if [ -n "$pb_files" ]; then
            for pb_file in $pb_files; do
                if [ -f "$pb_file" ]; then
                    local filename=$(basename "$pb_file")
                    cp "$pb_file" "$service_pb_dir/$filename"
                    echo -e "      ${GREEN}✓ 复制: $filename${NC}"
                fi
            done
        else
            echo -e "      ${YELLOW}! 未找到对应的 pb 文件: ${dep_name}*.pb.go${NC}"
        fi
    done

    # 复制服务自己的 pb 文件
    echo -e "    ${CYAN}复制 ${service} 自己的 pb 文件...${NC}"
    local service_pb_source="${PROTO_GEN_GO}/${service}"

    if [ -d "$service_pb_source" ]; then
        find "$service_pb_source" -name "*.pb.go" -type f | while read pb_file; do
            local filename=$(basename "$pb_file")
            cp "$pb_file" "$service_pb_dir/$filename"
            echo -e "      ${GREEN}✓ 复制: $filename${NC}"
        done
    else
        echo -e "      ${YELLOW}! 未找到 ${service} 的 pb 文件目录${NC}"
    fi

    # 显示最终复制的文件统计
    local total_pb_files=$(ls "$service_pb_dir"/*.pb.go 2>/dev/null | wc -l)
    echo -e "    ${GREEN}✓ 总共复制了 ${total_pb_files} 个 PB 文件到 ${service}/pb/v1/${NC}"
}

# 清理自带pb文件并修复导入路径
cleanup_and_fix_imports() {
    local service=$1
    local service_dir="${APP_DIR}/${service}"
    local pb_dir="${service_dir}/pb/v1"

    echo -e "${CYAN}  清理自带pb文件并修复导入路径...${NC}"

    # 1. 删除深层嵌套的pb文件目录
    if [ -d "${service_dir}/github.com" ]; then
        echo -e "    ${YELLOW}删除深层pb目录: github.com/${NC}"
        rm -rf "${service_dir}/github.com"
    fi

    if [ -d "${service_dir}/types" ]; then
        echo -e "    ${YELLOW}删除types目录${NC}"
        rm -rf "${service_dir}/types"
    fi

    # 2. 移动任何散落的pb文件到pb/v1目录
    find "$service_dir" -name "*.pb.go" -not -path "*/pb/*" | while read pb_file; do
        if [ -f "$pb_file" ]; then
            local filename=$(basename "$pb_file")
            echo -e "    ${YELLOW}移动pb文件: $filename 到 pb/v1/${NC}"
            mkdir -p "$pb_dir"
            mv "$pb_file" "$pb_dir/$filename"
        fi
    done

    # 3. 修复所有Go文件中的导入路径
    echo -e "    ${CYAN}修复导入路径...${NC}"
    fix_import_paths "$service"

    # 4. 验证pb目录是否包含必要文件
    local pb_count=$(ls "$pb_dir"/*.pb.go 2>/dev/null | wc -l)
    if [ $pb_count -gt 0 ]; then
        echo -e "    ${GREEN}✓ pb/v1目录包含 ${pb_count} 个pb文件${NC}"
    else
        echo -e "    ${RED}✗ pb/v1目录为空，可能存在问题${NC}"
    fi
}

# 修复导入路径
fix_import_paths() {
    local service=$1
    local service_dir="${APP_DIR}/${service}"
    local old_import_pattern="rpc-gateway/app/${service}/github.com/og-game/game-proto/proto-gen-go/${service}/v1"
    local new_import="rpc-gateway/app/${service}/pb/v1"

    # 查找所有Go文件并修复导入路径
    find "$service_dir" -name "*.go" -type f | while read go_file; do
        # 检查文件是否包含需要替换的导入
        if grep -q "$old_import_pattern" "$go_file" 2>/dev/null; then
            echo -e "      ${CYAN}修复文件: $(basename "$go_file")${NC}"

            # 备份文件
            cp "$go_file" "$go_file.bak"

            if [[ "$OSTYPE" == "darwin"* ]]; then
                # MacOS
                sed -i '' \
                    -e "s|\"${old_import_pattern}\"|\"${new_import}\"|g" \
                    -e "s|\"rpc-gateway/app/${service}/github\.com/[^\"]*\"|\"${new_import}\"|g" \
                    "$go_file"
            else
                # Linux
                sed -i \
                    -e "s|\"${old_import_pattern}\"|\"${new_import}\"|g" \
                    -e "s|\"rpc-gateway/app/${service}/github\.com/[^\"]*\"|\"${new_import}\"|g" \
                    "$go_file"
            fi

            # 验证修改是否成功
            if go fmt "$go_file" > /dev/null 2>&1; then
                rm "$go_file.bak"
                echo -e "        ${GREEN}✓ 成功修复导入路径${NC}"
            else
                echo -e "        ${RED}✗ 修复失败，恢复备份${NC}"
                mv "$go_file.bak" "$go_file"
            fi
        fi
    done

    # 额外处理一些可能的导入模式
    find "$service_dir" -name "*.go" -type f -exec grep -l "github\.com/og-game/game-proto" {} \; | while read go_file; do
        echo -e "      ${CYAN}处理额外导入: $(basename "$go_file")${NC}"

        cp "$go_file" "$go_file.bak"

        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' \
                -e "s|\"[^\"]*github\.com/og-game/game-proto/proto-gen-go/${service}/v1\"|\"${new_import}\"|g" \
                "$go_file"
        else
            sed -i \
                -e "s|\"[^\"]*github\.com/og-game/game-proto/proto-gen-go/${service}/v1\"|\"${new_import}\"|g" \
                "$go_file"
        fi

        if go fmt "$go_file" > /dev/null 2>&1; then
            rm "$go_file.bak"
            echo -e "        ${GREEN}✓ 处理完成${NC}"
        else
            mv "$go_file.bak" "$go_file"
            echo -e "        ${YELLOW}! 跳过此文件${NC}"
        fi
    done
}

# 生成单个 RPC 服务
generate_rpc_service() {
    local service=$1
    local service_dir="${APP_DIR}/${service}"

    echo -e "\n${CYAN}========== 生成 ${service} RPC 服务 ==========${NC}"

    # 查找主 proto 文件
    local main_proto=$(find_main_proto "$service")

    if [ -z "$main_proto" ]; then
        echo -e "${RED}✗ 未找到 ${service} 服务的 proto 文件${NC}"
        return 1
    fi

    echo -e "${YELLOW}使用 proto 文件: ${main_proto}${NC}"

    # 确保服务目录存在
    mkdir -p "$service_dir"

    echo -e "${YELLOW}生成 RPC 服务代码...${NC}"

    # 使用 goctl 生成服务直接在目标目录生成
    if goctl rpc protoc \
        "${PROTO_ROOT}/${main_proto}" \
        --proto_path="${PROTO_ROOT}" \
        --go_out="${service_dir}" \
        --go-grpc_out="${service_dir}" \
        --zrpc_out="${service_dir}" \
        --client=true \
        --style=goZero -m \
        -I "${PROTO_ROOT}"; then

        echo -e "${GREEN}✓ ${service} RPC 服务生成成功${NC}"

        # 合并客户端代码到 proto-gen-go
        merge_client_code "$service"

        # 复制所有相关的 pb 文件到服务目录
        copy_proto_dependencies "$service"

        # 清理自带pb文件并更新导入路径
        cleanup_and_fix_imports "$service"

        return 0
    else
        echo -e "${RED}✗ ${service} RPC 服务生成失败${NC}"
        return 1
    fi
}

# 合并客户端代码到 proto-gen-go
merge_client_code() {
    local service=$1
    local client_dir="${APP_DIR}/${service}/client"
    local target_dir="${PROTO_GEN_GO}/${service}/v1"

    if [ ! -d "$client_dir" ]; then
        echo -e "${YELLOW}  未找到客户端代码目录: ${client_dir}${NC}"
        return 0
    fi

    echo -e "${CYAN}  合并客户端代码到: ${target_dir}${NC}"

    # 确保目标目录存在
    mkdir -p "$target_dir"

    # 复制客户端代码
    cp -rf "${client_dir}"/* "${target_dir}/" 2>/dev/null || true

    # 删除原客户端目录
    rm -rf "$client_dir"

    # 替换导入路径
   echo -e "\n${CYAN} 原路径 ${APP_DIR#$PROJECT_ROOT}/${service} ${NC}"
    echo -e "${CYAN}  更新导入路径...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # MacOS
        find "$target_dir" -type f -name "*.go" -exec sed -i '' \
            "s|${APP_DIR#$PROJECT_ROOT/}/${service}/|""|g" \
            {} \;
    else
        # Linux
        find "$target_dir" -type f -name "*.go" -exec sed -i \
            "s|${APP_DIR#$PROJECT_ROOT/}/${service}/|""|g" \
            {} \;
    fi

    echo -e "${GREEN}  ✓ 客户端代码合并完成${NC}"
}

# 生成所有 RPC 服务
generate_all_rpc() {
    echo -e "${YELLOW}========== 生成 RPC 服务 ==========${NC}"

    # 确保 app 目录存在
    mkdir -p "$APP_DIR"

    local success=0
    local failed=0

    for service in "${SERVICES[@]}"; do
        if generate_rpc_service "$service"; then
            ((success++))
        else
            ((failed++))
        fi
    done

    echo -e "\n${YELLOW}========== RPC 服务生成结果 ==========${NC}"
    echo -e "成功: ${GREEN}${success}${NC} 个服务"
    echo -e "失败: ${RED}${failed}${NC} 个服务"
}

# 显示服务信息
show_info() {
    echo -e "${YELLOW}========== 服务信息 ==========${NC}"
    echo -e "${CYAN}工作目录: ${MODEL_ROOT}${NC}"
    echo -e "${CYAN}Proto 根目录: ${PROTO_ROOT}${NC}"
    echo -e "${CYAN}Proto 输出: ${PROTO_GEN_GO}${NC}"
    echo -e "${CYAN}RPC 输出: ${APP_DIR}${NC}"
    echo -e "${CYAN}当前服务: ${SERVICES[*]}${NC}"
    echo ""

    echo -e "${YELLOW}服务状态:${NC}"
    for service in "${SERVICES[@]}"; do
        printf "  %-15s" "$service"

        # 检查 proto 文件
        if find_main_proto "$service" >/dev/null 2>&1; then
            printf "${GREEN}[Proto ✓]${NC} "
        else
            printf "${RED}[Proto ✗]${NC} "
        fi

        # 检查 RPC 服务
        if [ -d "${APP_DIR}/${service}" ]; then
            printf "${GREEN}[RPC ✓]${NC} "
        else
            printf "${YELLOW}[RPC -]${NC} "
        fi

        # 检查 PB 文件
        if [ -d "${APP_DIR}/${service}/pb" ] && [ "$(ls -A "${APP_DIR}/${service}/pb"/*.pb.go 2>/dev/null)" ]; then
            printf "${GREEN}[PB ✓]${NC}"
        else
            printf "${YELLOW}[PB -]${NC}"
        fi

        echo ""
    done
}

# 清理生成的文件
clean() {
    echo -e "${YELLOW}清理生成的文件...${NC}"

    # 清理 proto 生成的文件
    if [ -d "$PROTO_GEN_GO" ]; then
        echo -e "${YELLOW}删除: ${PROTO_GEN_GO}${NC}"
        rm -rf "$PROTO_GEN_GO"
    fi

    # 清理 RPC 服务（需要确认）
    echo -e "${RED}警告: 这将删除所有 RPC 服务目录，包括你的实现代码！${NC}"
    echo -n "确定要继续吗？(y/N): "
    read -r confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        for service in "${SERVICES[@]}"; do
            local service_dir="${APP_DIR}/${service}"
            if [ -d "$service_dir" ]; then
                echo -e "${YELLOW}删除: ${service_dir}${NC}"
                rm -rf "$service_dir"
            fi
        done
        echo -e "${GREEN}✓ 清理完成${NC}"
    else
        echo -e "${YELLOW}取消清理 RPC 服务目录${NC}"
    fi
}

# 显示帮助信息
show_help() {
    echo "用法: $0 [命令] [服务名...]"
    echo ""
    echo "命令:"
    echo "  proto    只生成 Proto PB 文件"
    echo "  rpc      只生成 RPC 服务代码"
    echo "  all      生成 Proto 和 RPC（默认）"
    echo "  info     显示服务信息"
    echo "  clean    清理生成的文件"
    echo "  help     显示帮助信息"
    echo ""
    echo "服务名:"
    echo "  可用服务: ${SERVICES[*]}"
    echo "  不指定服务名时处理所有服务"
    echo ""
    echo "说明:"
    echo "  - goctl 使用 -m 参数自动保留用户实现的代码"
    echo "  - 自动分析并复制所有依赖的 PB 文件到服务目录"
    echo "  - 客户端代码会自动合并到 proto-gen-go 目录"
    echo ""
    echo "示例:"
    echo "  $0              # 生成所有 proto 和 rpc"
    echo "  $0 proto        # 只生成 proto pb 文件"
    echo "  $0 rpc game     # 只生成 game 的 rpc 服务"
    echo "  $0 info         # 显示服务信息"
    echo "  $0 clean        # 清理所有生成的文件"
}

# 主函数
main() {
    local command="all"
    local specified_services=()

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            proto|rpc|all|info|clean)
                command="$1"
                shift
                ;;
            help|-h|--help)
                show_help
                exit 0
                ;;
            *)
                # 检查是否是有效的服务名
                local is_valid_service=false
                for svc in "${SERVICES[@]}"; do
                    if [[ "$svc" == "$1" ]]; then
                        is_valid_service=true
                        break
                    fi
                done

                if [ "$is_valid_service" = true ]; then
                    specified_services+=("$1")
                else
                    echo -e "${RED}未知的参数或服务: $1${NC}"
                    echo -e "${YELLOW}可用的服务: ${SERVICES[*]}${NC}"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # 如果指定了服务，更新服务列表
    if [ ${#specified_services[@]} -gt 0 ]; then
        SERVICES=("${specified_services[@]}")
    fi

    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Go-Zero RPC 服务生成脚本${NC}"
    echo -e "${BLUE}工作目录: ${MODEL_ROOT}${NC}"
    echo -e "${BLUE}========================================${NC}"

    # 执行命令
    case $command in
        proto)
            check_dependencies
            generate_proto
            ;;
        rpc)
            check_dependencies
            generate_all_rpc
            ;;
        all)
            check_dependencies
            generate_proto && generate_all_rpc
            ;;
        info)
            show_info
            ;;
        clean)
            clean
            ;;
    esac
}

# 执行主函数
main "$@"
