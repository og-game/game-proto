#!/bin/bash

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 获取脚本所在目录（scripts）
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# 获取 game-center-model 目录（上一级）
MODEL_ROOT="$(dirname "$SCRIPT_DIR")"
# 获取项目根目录（包含 rpc-gateway 的目录）
PROJECT_ROOT="$(dirname "$MODEL_ROOT")"

# 路径定义
PROTO_ROOT="${MODEL_ROOT}/proto"
RPC_GATEWAY_ROOT="${PROJECT_ROOT}/rpc-gateway"
APP_DIR="${RPC_GATEWAY_ROOT}/app"
PROTO_GEN_GO="${MODEL_ROOT}/proto-gen-go"

# 服务列表 - 可以从环境变量或参数传入，否则自动扫描
if [ -n "$SERVICES_LIST" ]; then
    # 从环境变量读取服务列表（以空格分隔）
    IFS=' ' read -ra SERVICES <<< "$SERVICES_LIST"
    echo -e "${CYAN}使用指定的服务列表: ${SERVICES[*]}${NC}"
else
    # 自动扫描 proto 目录下的服务（排除 common）
    SERVICES=()
    if [ -d "$PROTO_ROOT" ]; then
        for service_dir in "${PROTO_ROOT}"/*/; do
            if [ -d "$service_dir" ]; then
                service_name=$(basename "$service_dir")
                # 排除 common 目录
                if [ "$service_name" != "common" ]; then
                    # 检查是否有 proto 文件
                    if find "$service_dir" -name "*.proto" -type f | grep -q .; then
                        SERVICES+=("$service_name")
                    fi
                fi
            fi
        done
    fi

    # 如果扫描失败，使用默认列表
    if [ ${#SERVICES[@]} -eq 0 ]; then
        SERVICES=("fund" "game" "manage" "platform")
        echo -e "${YELLOW}使用默认服务列表: ${SERVICES[*]}${NC}"
    else
        echo -e "${CYAN}自动扫描到的服务: ${SERVICES[*]}${NC}"
    fi
fi

# 全局变量
VERBOSE=false

# 检查依赖
check_dependencies() {
    echo -e "${YELLOW}检查依赖工具...${NC}"

    local deps_missing=false

    # 检查 protoc
    if ! command -v protoc &> /dev/null; then
        echo -e "${RED}✗ protoc 未安装${NC}"
        echo "  请安装 protoc: https://grpc.io/docs/protoc-installation/"
        deps_missing=true
    else
        echo -e "${GREEN}✓ protoc $(protoc --version)${NC}"
    fi

    # 检查 protoc 插件
    if ! command -v protoc-gen-go &> /dev/null; then
        echo -e "${RED}✗ protoc-gen-go 未安装${NC}"
        echo "  请运行: go install google.golang.org/protobuf/cmd/protoc-gen-go@latest"
        deps_missing=true
    else
        echo -e "${GREEN}✓ protoc-gen-go 已安装${NC}"
    fi

    if ! command -v protoc-gen-go-grpc &> /dev/null; then
        echo -e "${RED}✗ protoc-gen-go-grpc 未安装${NC}"
        echo "  请运行: go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest"
        deps_missing=true
    else
        echo -e "${GREEN}✓ protoc-gen-go-grpc 已安装${NC}"
    fi

    # 检查 goctl
    if ! command -v goctl &> /dev/null; then
        echo -e "${RED}✗ goctl 未安装${NC}"
        echo "  请运行: go install github.com/zeromicro/go-zero/tools/goctl@latest"
        deps_missing=true
    else
        echo -e "${GREEN}✓ goctl $(goctl --version 2>&1 | head -n1)${NC}"
    fi

    if [ "$deps_missing" = true ]; then
        echo -e "${RED}请安装缺失的依赖后重试${NC}"
        exit 1
    fi

    echo -e "${GREEN}所有依赖检查通过！${NC}"
}

# 扫描服务的所有版本
scan_service_versions() {
    local service=$1
    local versions=()

    # 扫描服务目录下的所有版本
    if [ -d "${PROTO_ROOT}/${service}" ]; then
        for version_dir in "${PROTO_ROOT}/${service}"/*/; do
            if [ -d "$version_dir" ]; then
                version=$(basename "$version_dir")
                # 检查是否有 proto 文件
                if ls "${version_dir}"*.proto 1> /dev/null 2>&1; then
                    versions+=("$version")
                fi
            fi
        done
    fi

    echo "${versions[@]}"
}

# 扫描版本目录下的所有 proto 文件
scan_proto_files() {
    local service=$1
    local version=$2
    local proto_files=()

    local proto_dir="${PROTO_ROOT}/${service}/${version}"
    if [ -d "$proto_dir" ]; then
        for proto_file in "${proto_dir}"/*.proto; do
            if [ -f "$proto_file" ]; then
                # 获取相对路径
                local relative_path="${service}/${version}/$(basename "$proto_file")"
                proto_files+=("$relative_path")
            fi
        done
    fi

    echo "${proto_files[@]}"
}

# 生成 Proto PB 文件
generate_proto() {
    echo -e "\n${YELLOW}========== 生成 Proto PB 文件 ==========${NC}"

    # 确保输出目录存在
    mkdir -p "$PROTO_GEN_GO"

    # 获取所有 proto 文件
    local all_proto_files=()

    # 先添加 common 目录的文件
    if [ -d "${PROTO_ROOT}/common" ]; then
        while IFS= read -r -d '' file; do
            all_proto_files+=("${file#${PROTO_ROOT}/}")
        done < <(find "${PROTO_ROOT}/common" -name "*.proto" -type f -print0)
    fi

    # 添加各服务的文件
    for service in "${SERVICES[@]}"; do
        local versions=($(scan_service_versions "$service"))
        for version in "${versions[@]}"; do
            local proto_files=($(scan_proto_files "$service" "$version"))
            all_proto_files+=("${proto_files[@]}")
        done
    done

    # 生成所有 proto 文件
    echo -e "${CYAN}找到 ${#all_proto_files[@]} 个 proto 文件${NC}"

    local success=0
    local failed=0

    for proto_file in "${all_proto_files[@]}"; do
        if [ "$VERBOSE" = true ]; then
            echo -e "${CYAN}生成: ${proto_file}${NC}"
        fi

        # 确保输出目录存在
        local output_dir="${PROTO_GEN_GO}/$(dirname "$proto_file")"
        mkdir -p "$output_dir"

        # 生成 pb 文件
        if protoc \
            --proto_path="${PROTO_ROOT}" \
            --go_out="${PROTO_GEN_GO}" \
            --go_opt=paths=source_relative \
            --go-grpc_out="${PROTO_GEN_GO}" \
            --go-grpc_opt=paths=source_relative \
            "${PROTO_ROOT}/${proto_file}" 2>/dev/null; then
            ((success++))
            [ "$VERBOSE" = true ] && echo -e "${GREEN}  ✓ 成功${NC}"
        else
            ((failed++))
            echo -e "${RED}  ✗ 失败: ${proto_file}${NC}"
        fi
    done

    echo -e "\n${YELLOW}========== Proto 生成结果 ==========${NC}"
    echo -e "成功: ${GREEN}${success}${NC} 个文件"
    echo -e "失败: ${RED}${failed}${NC} 个文件"

    [ $failed -eq 0 ]
}

# 查找服务的主 proto 文件
find_main_proto() {
    local service=$1
    local versions=($(scan_service_versions "$service"))

    for version in "${versions[@]}"; do
        # 优先查找与服务同名的 proto 文件
        if [ -f "${PROTO_ROOT}/${service}/${version}/${service}.proto" ]; then
            echo "${service}/${version}/${service}.proto"
            return 0
        fi

        # 查找包含 service 定义的文件
        for proto_file in "${PROTO_ROOT}/${service}/${version}"/*.proto; do
            if [ -f "$proto_file" ] && grep -q "^service" "$proto_file" 2>/dev/null; then
                echo "${service}/${version}/$(basename "$proto_file")"
                return 0
            fi
        done
    done

    return 1
}

# 生成单个 RPC 服务
generate_rpc_service() {
    local service=$1
    local service_dir="${APP_DIR}/${service}"

    echo -e "\n${CYAN}========== 生成 ${service} RPC 服务 ==========${NC}"

    # 查找主 proto 文件
    local main_proto=$(find_main_proto "$service")

    if [ -z "$main_proto" ]; then
        echo -e "${RED}✗ 未找到 ${service} 服务的主 proto 文件${NC}"
        return 1
    fi

    echo -e "${YELLOW}使用主 proto 文件: ${main_proto}${NC}"

    # 如果服务目录已存在，询问是否覆盖
    if [ -d "$service_dir" ]; then
        echo -e "${YELLOW}⚠️  服务目录已存在: ${service_dir}${NC}"
        echo -e "${YELLOW}是否覆盖? (y/n/s[kip])${NC}"
        read -r overwrite
        case "$overwrite" in
            y|Y)
                echo -e "${YELLOW}备份现有目录...${NC}"
                mv "$service_dir" "${service_dir}.bak.$(date +%Y%m%d%H%M%S)"
                ;;
            s|S)
                echo -e "${YELLOW}跳过 ${service} 服务${NC}"
                return 0
                ;;
            *)
                echo -e "${RED}取消生成 ${service} 服务${NC}"
                return 1
                ;;
        esac
    fi

    # 创建服务目录
    mkdir -p "$service_dir"

    # 使用 goctl 生成服务
    cd "$APP_DIR"

    echo -e "${YELLOW}生成 RPC 服务代码...${NC}"

    if goctl rpc protoc \
        "${PROTO_ROOT}/${main_proto}" \
        --go_out="${service_dir}/types" \
        --go-grpc_out="${service_dir}/types" \
        --zrpc_out="${service_dir}" \
        --style=goZero -m \
        -I "${PROTO_ROOT}"; then
        echo -e "${GREEN}✓ ${service} RPC 服务生成成功${NC}"

        # 显示生成的目录结构
        echo -e "${CYAN}生成的目录结构:${NC}"
        tree -L 2 "$service_dir" 2>/dev/null || ls -la "$service_dir"

        return 0
    else
        echo -e "${RED}✗ ${service} RPC 服务生成失败${NC}"
        return 1
    fi
}

# 生成所有 RPC 服务
generate_all_rpc() {
    local success=0
    local failed=0

    echo -e "${YELLOW}========== 生成所有 RPC 服务 ==========${NC}"

    # 确保 app 目录存在
    mkdir -p "$APP_DIR"

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
    echo -e "${CYAN}当前服务: ${SERVICES[*]}${NC}"
    echo ""
    printf "%-15s %-10s %s\n" "服务" "版本" "Proto 文件"
    printf "%-15s %-10s %s\n" "------" "------" "----------"

    for service in "${SERVICES[@]}"; do
        local versions=($(scan_service_versions "$service"))
        if [ ${#versions[@]} -gt 0 ]; then
            for version in "${versions[@]}"; do
                local proto_files=($(scan_proto_files "$service" "$version"))
                for proto_file in "${proto_files[@]}"; do
                    printf "%-15s %-10s %s\n" "$service" "$version" "$(basename "$proto_file")"
                done
            done
        else
            printf "%-15s %-10s %s\n" "$service" "-" "未找到 proto 文件"
        fi
    done

    echo ""
    echo -e "${CYAN}Proto 根目录: ${PROTO_ROOT}${NC}"
    echo -e "${CYAN}Proto 输出: ${PROTO_GEN_GO}${NC}"
    echo -e "${CYAN}RPC 输出: ${APP_DIR}${NC}"
}

# 清理生成的文件
clean() {
    echo -e "${YELLOW}清理生成的文件...${NC}"

    # 清理 proto 生成的文件
    if [ -d "$PROTO_GEN_GO" ]; then
        echo -e "${YELLOW}删除: ${PROTO_GEN_GO}${NC}"
        rm -rf "$PROTO_GEN_GO"
    fi

    # 清理 RPC 服务
    for service in "${SERVICES[@]}"; do
        local service_dir="${APP_DIR}/${service}"
        if [ -d "$service_dir" ]; then
            echo -e "${YELLOW}删除: ${service_dir}${NC}"
            rm -rf "$service_dir"
        fi
    done

    echo -e "${GREEN}✓ 清理完成${NC}"
}

# 显示帮助信息
show_help() {
    echo "用法: $0 [命令] [选项] [服务名...]"
    echo ""
    echo "命令:"
    echo "  proto           只生成 Proto PB 文件"
    echo "  rpc             只生成 RPC 服务代码"
    echo "  all             生成 Proto 和 RPC（默认）"
    echo "  info            显示服务信息"
    echo "  clean           清理生成的文件"
    echo ""
    echo "选项:"
    echo "  -h, --help      显示帮助信息"
    echo "  -v, --verbose   显示详细输出"
    echo ""
    echo "环境变量:"
    echo "  SERVICES_LIST   指定要处理的服务列表（空格分隔）"
    echo "                  例: SERVICES_LIST='game fund' $0 proto"
    echo ""
    echo "服务名:"
    echo "  当前可用: ${SERVICES[*]}"
    echo "  指定服务名时只处理指定的服务"
    echo ""
    echo "示例:"
    echo "  $0                    # 生成所有 proto 和 rpc"
    echo "  $0 proto              # 只生成 proto pb 文件"
    echo "  $0 rpc                # 只生成 rpc 服务"
    echo "  $0 rpc game fund      # 只生成 game 和 fund 的 rpc 服务"
    echo "  $0 info               # 显示服务信息"
    echo "  $0 clean              # 清理所有生成的文件"
}

# 检查服务名是否有效
is_valid_service() {
    local service=$1
    local valid_service
    for valid_service in "${SERVICES[@]}"; do
        if [[ "$valid_service" == "$service" ]]; then
            return 0
        fi
    done
    return 1
}

# 主函数
main() {
    local command="all"
    local specified_services=()

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            proto|rpc|all|info|clean)
                command="$1"
                shift
                ;;
            *)
                # 检查是否是有效的服务名
                if is_valid_service "$1"; then
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
        echo -e "${CYAN}处理指定的服务: ${SERVICES[*]}${NC}"
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

# 如果直接运行脚本，执行主函数
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
