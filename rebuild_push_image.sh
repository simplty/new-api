#!/bin/bash

# 重新构建并推送镜像脚本
# 用于重新构建镜像并推送到阿里云Docker Registry

set -e

# 加载环境变量
if [ -f ".env" ]; then
    export $(cat .env | grep -v ^# | xargs)
else
    handle_env_file_warning
fi

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 阿里云Registry配置（从环境变量读取）
REGISTRY_URL="${REGISTRY_URL:-crpi-eep0ohmpw8c1mmyv.cn-hangzhou.personal.cr.aliyuncs.com}"
REGISTRY_USERNAME="${REGISTRY_USERNAME:-zhidateam}"
REGISTRY_PASSWORD="${REGISTRY_PASSWORD:-cfplhys233}"
NAMESPACE="${REGISTRY_NAMESPACE:-zhidateam}"
REPOSITORY="${REGISTRY_REPOSITORY:-new-api}"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 处理 .env 文件警告
handle_env_file_warning() {
    echo -e "${YELLOW}===========================================================${NC}"
    echo -e "${YELLOW}                   环境变量配置警告${NC}"
    echo -e "${YELLOW}               Environment Variable Warning${NC}"
    echo -e "${YELLOW}===========================================================${NC}"
    log_warning "未找到 .env 文件"
    log_warning "No .env file found"
    echo ""
    
    # 显示需要配置的环境变量信息
    show_required_env_vars
    
    # 显示用户选项
    show_user_options
    
    # 等待用户输入
    while true; do
        echo -n "请选择操作 (Please choose an option): "
        read choice
        
        case $choice in
            1)
                reload_env_file
                break
                ;;
            2)
                interactive_env_setup
                break
                ;;
            3)
                log_info "继续使用默认配置... (Continuing with default configuration...)"
                break
                ;;
            4)
                log_info "程序退出 (Exiting program)"
                exit 0
                ;;
            *)
                log_error "无效选择，请重新输入 (Invalid choice, please try again)"
                ;;
        esac
    done
}

# 显示需要配置的环境变量
show_required_env_vars() {
    log_info "需要配置的环境变量 (Required Environment Variables):"
    echo "-----------------------------------------------------------"
    
    # 定义环境变量信息
    declare -A env_vars=(
        ["REGISTRY_URL"]="Docker镜像仓库地址 (Docker Registry URL)|可选 (Optional)|crpi-eep0ohmpw8c1mmyv.cn-hangzhou.personal.cr.aliyuncs.com"
        ["REGISTRY_USERNAME"]="Registry用户名 (Registry Username)|可选 (Optional)|zhidateam"
        ["REGISTRY_PASSWORD"]="Registry密码 (Registry Password)|可选 (Optional)|cfplhys233"
        ["REGISTRY_NAMESPACE"]="Registry命名空间 (Registry Namespace)|可选 (Optional)|zhidateam"
        ["REGISTRY_REPOSITORY"]="Registry仓库名 (Registry Repository)|可选 (Optional)|new-api"
        ["PORT"]="服务端口 (Server Port)|可选 (Optional)|3000"
        ["FRONTEND_BASE_URL"]="前端基础URL (Frontend Base URL)|可选 (Optional)|未设置"
        ["SQL_DSN"]="数据库连接字符串 (Database Connection String)|可选 (Optional)|SQLite (default)"
        ["REDIS_CONN_STRING"]="Redis连接字符串 (Redis Connection String)|可选 (Optional)|禁用 (disabled)"
        ["SESSION_SECRET"]="会话密钥 (Session Secret)|重要 (Important)|random_string (必须修改!)"
        ["DEBUG"]="调试模式 (Debug Mode)|可选 (Optional)|false"
        ["ENABLE_PPROF"]="性能分析 (Performance Profiling)|可选 (Optional)|false"
    )
    
    # 显示环境变量信息
    for var in "${!env_vars[@]}"; do
        IFS='|' read -r description status default_val <<< "${env_vars[$var]}"
        current_val=$(printenv "$var" 2>/dev/null || echo "$default_val")
        
        echo -e "  ${BLUE}$var${NC}: $description"
        echo -e "    状态 (Status): $status"
        echo -e "    当前值 (Current): $current_val"
        echo ""
    done
}

# 显示用户选项
show_user_options() {
    log_info "可用选项 (Available Options):"
    echo "-----------------------------------------------------------"
    echo "1. 重新加载 .env 文件 (Reload .env file)"
    echo "   - 如果您已经创建了 .env 文件，选择此选项重新加载"
    echo "   - If you have created a .env file, choose this to reload"
    echo ""
    echo "2. 交互式配置环境变量 (Interactive environment setup)"
    echo "   - 逐个引导您输入环境变量并自动创建 .env 文件"
    echo "   - Guide you through setting environment variables and create .env file"
    echo ""
    echo "3. 继续使用默认配置 (Continue with default configuration)"
    echo "   - 使用脚本内置默认值继续运行"
    echo "   - Continue running with built-in default values"
    echo ""
    echo "4. 退出程序 (Exit program)"
    echo "   - 退出程序，稍后手动配置环境变量"
    echo "   - Exit program to manually configure environment variables later"
    echo ""
}

# 重新加载 .env 文件
reload_env_file() {
    if [ -f ".env" ]; then
        export $(cat .env | grep -v ^# | xargs)
        log_success "成功重新加载 .env 文件 (Successfully reloaded .env file)"
    else
        log_error "重新加载 .env 文件失败: 文件不存在 (Failed to reload .env file: file not found)"
        log_error "请确保 .env 文件存在并且格式正确 (Please ensure .env file exists and is properly formatted)"
        handle_env_file_warning
    fi
}

# 交互式环境变量配置
interactive_env_setup() {
    log_info "交互式环境变量配置 (Interactive Environment Setup)"
    echo "================================================="
    log_info "我将引导您配置重要的环境变量并创建 .env 文件"
    log_info "I will guide you through configuring important environment variables and create a .env file"
    echo ""
    
    # 创建临时数组存储配置
    declare -A env_config=()
    
    # 重要的环境变量配置
    configure_env_var "REGISTRY_URL" "Docker镜像仓库地址 (Docker Registry URL)" "crpi-eep0ohmpw8c1mmyv.cn-hangzhou.personal.cr.aliyuncs.com" false
    configure_env_var "REGISTRY_USERNAME" "Registry用户名 (Registry Username)" "zhidateam" false
    configure_env_var "REGISTRY_PASSWORD" "Registry密码 (Registry Password)" "cfplhys233" false
    configure_env_var "REGISTRY_NAMESPACE" "Registry命名空间 (Registry Namespace)" "zhidateam" false
    configure_env_var "REGISTRY_REPOSITORY" "Registry仓库名 (Registry Repository)" "new-api" false
    configure_env_var "PORT" "服务端口 (Server Port)" "3000" false
    configure_env_var "SESSION_SECRET" "会话密钥 (Session Secret) - 用于加密会话数据" "" true
    configure_env_var "DEBUG" "调试模式 (Debug Mode) - true/false" "false" false
    
    # 创建 .env 文件
    create_env_file
    
    log_success "成功创建 .env 文件 (Successfully created .env file)"
    log_info "正在重新加载配置... (Reloading configuration...)"
    
    # 重新加载新创建的 .env 文件
    reload_env_file
}

# 配置单个环境变量
configure_env_var() {
    local var_name="$1"
    local description="$2"
    local default_val="$3"
    local required="$4"
    
    while true; do
        echo ""
        echo "$description"
        if [ -n "$default_val" ]; then
            echo "默认值 (Default): $default_val"
        fi
        echo -n "请输入值 (Enter value): "
        read input_value
        
        # 使用默认值如果输入为空且存在默认值
        if [ -z "$input_value" ] && [ -n "$default_val" ]; then
            input_value="$default_val"
        fi
        
        # 必需字段检查
        if [ "$required" = true ] && [ -z "$input_value" ]; then
            log_error "此字段为必需字段，不能为空 (This field is required and cannot be empty)"
            continue
        fi
        
        # SESSION_SECRET 特殊验证
        if [ "$var_name" = "SESSION_SECRET" ]; then
            if [ -z "$input_value" ] || [ "$input_value" = "random_string" ]; then
                log_error "SESSION_SECRET不能为空或默认值，请设置为随机字符串"
                continue
            fi
            if [ ${#input_value} -lt 16 ]; then
                log_error "SESSION_SECRET长度至少16个字符"
                continue
            fi
        fi
        
        # PORT 数字验证
        if [ "$var_name" = "PORT" ] && [ -n "$input_value" ]; then
            if ! [[ "$input_value" =~ ^[0-9]+$ ]]; then
                log_error "PORT必须是数字"
                continue
            fi
        fi
        
        # DEBUG 布尔值验证
        if [ "$var_name" = "DEBUG" ] && [ -n "$input_value" ]; then
            if [ "$input_value" != "true" ] && [ "$input_value" != "false" ]; then
                log_error "DEBUG必须是true或false"
                continue
            fi
        fi
        
        # 保存配置
        if [ -n "$input_value" ]; then
            env_config["$var_name"]="$input_value"
        fi
        break
    done
}

# 创建 .env 文件
create_env_file() {
    {
        echo "# New API Environment Configuration"
        echo "# Generated automatically by rebuild_push_image.sh"
        echo "# 自动生成的环境变量配置文件"
        echo ""
        
        # 写入配置的变量
        for var in "${!env_config[@]}"; do
            echo "$var=${env_config[$var]}"
        done
        
        echo ""
        echo "# Add other environment variables as needed"
        echo "# 根据需要添加其他环境变量"
    } > .env
}

# 获取版本号函数
get_version() {
    # 生成默认版本号（日期格式：YYMMDD）
    local default_version=$(date +%y%m%d)

    log_info "镜像版本确认"
    echo "默认版本号: $default_version"
    echo ""
    echo "请选择："
    echo "  y - 使用默认版本号 ($default_version)"
    echo "  m - 手动输入版本号"
    echo ""

    while true; do
        read -p "请输入选择 (y/m): " choice
        case $choice in
            [Yy]* )
                VERSION=$default_version
                break
                ;;
            [Mm]* )
                read -p "请输入自定义版本号: " custom_version
                if [ -n "$custom_version" ]; then
                    VERSION=$custom_version
                    break
                else
                    log_error "版本号不能为空，请重新输入"
                fi
                ;;
            * )
                log_error "请输入 y 或 m"
                ;;
        esac
    done

    log_success "确认使用版本号: $VERSION"
    echo ""
}

# 获取构建平台函数
get_platform() {
    local current_arch=$(uname -m)
    local current_platform=""

    # 检测当前平台
    case $current_arch in
        x86_64)
            current_platform="linux/amd64"
            ;;
        aarch64|arm64)
            current_platform="linux/arm64"
            ;;
        *)
            current_platform="linux/amd64"
            ;;
    esac

    log_info "构建平台选择"
    echo "当前系统架构: $current_arch"
    echo "当前平台: $current_platform"
    echo ""
    echo "请选择构建平台："
    echo "  1 - 当前平台 ($current_platform)"
    echo "  2 - Linux AMD64 (x86_64服务器)"
    echo "  3 - Linux ARM64 (ARM服务器)"
    echo "  4 - 多平台构建 (linux/amd64,linux/arm64)"
    echo ""

    while true; do
        read -p "请输入选择 (1-4): " choice
        case $choice in
            1)
                PLATFORM=$current_platform
                MULTI_PLATFORM=false
                break
                ;;
            2)
                PLATFORM="linux/amd64"
                MULTI_PLATFORM=false
                break
                ;;
            3)
                PLATFORM="linux/arm64"
                MULTI_PLATFORM=false
                break
                ;;
            4)
                PLATFORM="linux/amd64,linux/arm64"
                MULTI_PLATFORM=true
                break
                ;;
            *)
                log_error "请输入 1-4 之间的数字"
                ;;
        esac
    done

    log_success "确认使用构建平台: $PLATFORM"
    if [ "$MULTI_PLATFORM" = true ]; then
        log_info "多平台构建模式已启用"
    fi
    echo ""
}

# 清理旧镜像
cleanup_old_images() {
    log_info "清理旧镜像..."
    
    # 删除旧的镜像
    docker rmi new-api:$VERSION 2>/dev/null || log_warning "镜像 new-api:$VERSION 不存在，跳过删除"
    docker rmi new-api:local 2>/dev/null || log_warning "镜像 new-api:local 不存在，跳过删除"
    
    # 清理构建缓存
    log_info "清理构建缓存..."
    docker builder prune -f || true
    
    log_success "清理完成"
}

# 构建新镜像
build_image() {
    log_info "开始构建新镜像..."

    # 检查 Dockerfile 是否存在
    if [ ! -f "Dockerfile" ]; then
        log_error "Dockerfile 不存在"
        exit 1
    fi

    # 检查是否需要创建 buildx builder
    if [ "$MULTI_PLATFORM" = true ] || [ "$PLATFORM" != "$(docker version --format '{{.Server.Os}}/{{.Server.Arch}}')" ]; then
        log_info "检查 Docker Buildx..."

        # 检查是否已有多架构构建器
        if docker buildx ls | grep -q "multiarch-builder"; then
            log_info "使用现有的多架构构建器 (multiarch-builder)..."
            docker buildx use multiarch-builder
        elif docker buildx ls | grep -q "multiarch"; then
            log_info "使用现有的多架构构建器 (multiarch)..."
            docker buildx use multiarch
        else
            log_info "创建多架构构建器..."
            docker buildx create --name multiarch-builder --use --bootstrap
        fi
    fi

    # 构建镜像
    log_info "构建 Docker 镜像 (new-api:$VERSION)..."
    log_info "目标平台: $PLATFORM"

    if [ "$MULTI_PLATFORM" = true ]; then
        # 多平台构建，直接推送到远程仓库
        local remote_tag="$REGISTRY_URL/$NAMESPACE/$REPOSITORY:$VERSION"
        local latest_tag="$REGISTRY_URL/$NAMESPACE/$REPOSITORY:latest"

        log_info "多平台构建模式，将直接推送到远程仓库..."

        if docker buildx build \
            --platform "$PLATFORM" \
            --tag "$remote_tag" \
            --tag "$latest_tag" \
            --push \
            --no-cache \
            .; then
            log_success "多平台镜像构建并推送成功 (版本: $VERSION)"
            MULTI_PLATFORM_PUSHED=true
        else
            log_error "多平台镜像构建失败"
            exit 1
        fi
    else
        # 单平台构建
        if docker buildx build \
            --platform "$PLATFORM" \
            --tag "new-api:$VERSION" \
            --load \
            --no-cache \
            .; then
            # 同时创建 local 标签
            docker tag new-api:$VERSION new-api:local
            log_success "镜像构建成功 (版本: $VERSION, 平台: $PLATFORM)"
        else
            log_error "镜像构建失败"
            exit 1
        fi

        # 显示镜像信息
        log_info "镜像信息:"
        docker images new-api:$VERSION
        docker images new-api:local
    fi
}

# 登录阿里云Registry
login_registry() {
    log_info "登录阿里云Docker Registry..."
    
    # 使用非交互式方式登录
    echo "$REGISTRY_PASSWORD" | docker login --username="$REGISTRY_USERNAME" --password-stdin "$REGISTRY_URL"
    
    if [ $? -eq 0 ]; then
        log_success "登录成功"
    else
        log_error "登录失败"
        exit 1
    fi
}

# 标记并推送镜像
tag_and_push_image() {
    # 如果是多平台构建，镜像已经推送了
    if [ "$MULTI_PLATFORM_PUSHED" = true ]; then
        log_info "多平台镜像已在构建时推送，跳过推送步骤"
        return 0
    fi

    local remote_tag="$REGISTRY_URL/$NAMESPACE/$REPOSITORY:$VERSION"
    local latest_tag="$REGISTRY_URL/$NAMESPACE/$REPOSITORY:latest"

    log_info "标记镜像..."
    log_info "源镜像: new-api:$VERSION"
    log_info "目标镜像: $remote_tag"
    log_info "Latest镜像: $latest_tag"

    # 标记版本号镜像
    if docker tag "new-api:$VERSION" "$remote_tag"; then
        log_success "版本镜像标记成功"
    else
        log_error "版本镜像标记失败"
        exit 1
    fi

    # 标记latest镜像
    if docker tag "new-api:$VERSION" "$latest_tag"; then
        log_success "Latest镜像标记成功"
    else
        log_error "Latest镜像标记失败"
        exit 1
    fi

    log_info "推送镜像到阿里云Registry..."

    # 推送版本号镜像
    log_info "推送版本镜像: $remote_tag"
    if docker push "$remote_tag"; then
        log_success "版本镜像推送成功"
    else
        log_error "版本镜像推送失败"
        exit 1
    fi

    # 推送latest镜像
    log_info "推送Latest镜像: $latest_tag"
    if docker push "$latest_tag"; then
        log_success "Latest镜像推送成功"
    else
        log_error "Latest镜像推送失败"
        exit 1
    fi

    # 清理本地标记的镜像
    log_info "清理本地标记的镜像..."
    if docker rmi "$remote_tag" 2>/dev/null; then
        log_success "版本镜像清理完成"
    else
        log_warning "版本镜像清理失败或镜像不存在"
    fi

    if docker rmi "$latest_tag" 2>/dev/null; then
        log_success "Latest镜像清理完成"
    else
        log_warning "Latest镜像清理失败或镜像不存在"
    fi
}

# 显示完成信息
show_completion_info() {
    local remote_tag="$REGISTRY_URL/$NAMESPACE/$REPOSITORY:$VERSION"
    local latest_tag="$REGISTRY_URL/$NAMESPACE/$REPOSITORY:latest"

    log_info "构建和推送完成信息:"
    echo "=================================="
    echo "本地镜像: new-api:$VERSION, new-api:local"
    echo "远程镜像: $remote_tag"
    echo "Latest镜像: $latest_tag"
    echo "镜像仓库: $REGISTRY_URL"
    echo "命名空间: $NAMESPACE"
    echo "仓库名称: $REPOSITORY"
    echo "镜像版本: $VERSION"
    echo "=================================="
    echo ""

    log_info "拉取镜像命令:"
    echo "# 拉取指定版本"
    echo "docker pull $remote_tag"
    echo ""
    echo "# 拉取最新版本"
    echo "docker pull $latest_tag"
    echo ""

    log_info "在其他机器上使用:"
    echo "# 使用指定版本"
    echo "docker run -d --name new-api -p 3000:3000 $remote_tag"
    echo ""
    echo "# 使用最新版本"
    echo "docker run -d --name new-api -p 3000:3000 $latest_tag"
    echo ""

    log_info "本地部署命令:"
    echo "docker-compose up -d"
}

# 主函数
main() {
    log_info "开始重新构建并推送 new-api 镜像..."
    echo "=================================="
    
    # 检查参数
    SKIP_CLEANUP=false
    SKIP_BUILD=false
    SKIP_PUSH=false
    SKIP_LOGIN=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-cleanup)
                SKIP_CLEANUP=true
                shift
                ;;
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --skip-push)
                SKIP_PUSH=true
                shift
                ;;
            --skip-login)
                SKIP_LOGIN=true
                shift
                ;;
            --version)
                VERSION="$2"
                shift 2
                ;;
            --help|-h)
                echo "用法: $0 [选项]"
                echo "选项:"
                echo "  --skip-cleanup    跳过清理步骤"
                echo "  --skip-build      跳过构建步骤"
                echo "  --skip-push       跳过推送步骤"
                echo "  --skip-login      跳过登录步骤"
                echo "  --version VERSION 指定版本号"
                echo "  --help, -h        显示帮助信息"
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                exit 1
                ;;
        esac
    done
    
    # 如果没有指定版本号，则获取版本号
    if [ -z "$VERSION" ]; then
        get_version
    fi

    # 获取构建平台
    get_platform
    
    # 执行构建步骤
    if [ "$SKIP_CLEANUP" = false ]; then
        cleanup_old_images
    else
        log_warning "跳过清理步骤"
    fi
    
    if [ "$SKIP_BUILD" = false ]; then
        build_image
    else
        log_warning "跳过构建步骤"
    fi
    
    # 执行推送步骤
    if [ "$SKIP_PUSH" = false ]; then
        if [ "$SKIP_LOGIN" = false ]; then
            login_registry
        else
            log_warning "跳过登录步骤"
        fi
        
        tag_and_push_image
    else
        log_warning "跳过推送步骤"
    fi
    
    show_completion_info
    log_success "重新构建并推送完成！"
}

# 捕获中断信号
trap 'log_error "操作被中断"; exit 1' INT TERM

# 执行主函数
main "$@"
