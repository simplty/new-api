#!/bin/bash

# ============================================================================
# New API 项目启动脚本 
# Project Startup Script
# ============================================================================

# 脚本基础分支配置
BASE_BRANCH="feat/custom_use_combine"
BASE_WORKTREE_PATH="/Users/zhao/Documents/workspace/coding/zhida/new-api-worktrees/new-api:feat:custom_use_combine"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

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

log_debug() {
    echo -e "${PURPLE}[DEBUG]${NC} $1"
}

# 显示使用帮助
show_help() {
    echo "New API 项目启动脚本"
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help          显示帮助信息"
    echo "  -c, --compile       重新编译后启动"
    echo "  -d, --direct        直接启动已编译的程序"
    echo "  -f, --frontend      仅启动前端开发服务器"
    echo "  -b, --backend       仅启动后端服务器"
    echo "  --skip-check        跳过脚本差异检查"
    echo "  --port PORT         指定后端服务端口 (默认: 3000)"
    echo "  --frontend-port PORT 指定前端服务端口 (默认: 3001)"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 -c              重新编译并启动全栈项目"
    echo "  $0 -d              直接启动已编译的程序"
    echo "  $0 -f              仅启动前端开发服务器"
    echo "  $0 -b              仅启动后端服务器"
    echo "  $0 -c --port 8080  重新编译并在端口8080启动"
    echo ""
}

# 获取当前分支
get_current_branch() {
    git branch --show-current
}

# 检查是否在git仓库中
check_git_repo() {
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        log_error "当前目录不是git仓库"
        exit 1
    fi
}

# 获取当前工作目录的worktree路径
get_current_worktree_path() {
    git worktree list | grep "$(pwd)" | awk '{print $1}'
}

# 检查脚本差异
check_script_diff() {
    local current_branch=$(get_current_branch)
    local current_script="$0"
    local base_script="$BASE_WORKTREE_PATH/start.sh"
    
    log_info "检查脚本差异..."
    log_debug "当前分支: $current_branch"
    log_debug "基础分支: $BASE_BRANCH"
    log_debug "当前脚本: $current_script"
    log_debug "基础脚本: $base_script"
    
    # 如果当前分支就是基础分支，跳过检查
    if [ "$current_branch" = "$BASE_BRANCH" ]; then
        log_info "当前分支是基础分支，跳过脚本差异检查"
        return 0
    fi
    
    # 检查基础脚本是否存在
    if [ ! -f "$base_script" ]; then
        log_warning "基础分支脚本不存在: $base_script"
        log_info "将创建基础脚本..."
        
        # 创建基础脚本目录（如果不存在）
        mkdir -p "$(dirname "$base_script")"
        
        # 复制当前脚本到基础分支
        cp "$current_script" "$base_script"
        chmod +x "$base_script"
        
        log_success "已创建基础脚本: $base_script"
        return 0
    fi
    
    # 比较脚本差异
    if ! diff -q "$current_script" "$base_script" > /dev/null 2>&1; then
        log_warning "检测到脚本差异!"
        echo ""
        log_info "脚本差异详情:"
        echo "----------------------------------------"
        diff -u "$base_script" "$current_script" | head -20
        echo "----------------------------------------"
        echo ""
        
        log_warning "当前脚本与基础分支($BASE_BRANCH)的脚本存在差异"
        echo "请选择操作:"
        echo "  1) 继续执行当前脚本"
        echo "  2) 同步基础分支脚本到当前分支"
        echo "  3) 将当前脚本更新到基础分支"
        echo "  4) 查看完整差异"
        echo "  5) 退出脚本"
        echo ""
        
        while true; do
            read -p "请选择 (1-5): " choice
            case $choice in
                1)
                    log_info "继续执行当前脚本..."
                    break
                    ;;
                2)
                    log_info "同步基础分支脚本到当前分支..."
                    cp "$base_script" "$current_script"
                    chmod +x "$current_script"
                    log_success "脚本同步完成，请重新运行脚本"
                    exit 0
                    ;;
                3)
                    log_info "将当前脚本更新到基础分支..."
                    cp "$current_script" "$base_script"
                    chmod +x "$base_script"
                    log_success "基础脚本更新完成"
                    break
                    ;;
                4)
                    echo ""
                    log_info "完整差异:"
                    echo "========================================"
                    diff -u "$base_script" "$current_script"
                    echo "========================================"
                    echo ""
                    ;;
                5)
                    log_info "退出脚本"
                    exit 0
                    ;;
                *)
                    log_error "无效选择，请输入 1-5"
                    ;;
            esac
        done
    else
        log_success "脚本无差异，继续执行"
    fi
}

# 检查必要工具是否存在
check_prerequisites() {
    log_info "检查必要工具..."
    
    # 检查Go
    if ! command -v go &> /dev/null; then
        log_error "Go 未安装，请先安装 Go"
        exit 1
    fi
    
    # 检查Bun
    if ! command -v bun &> /dev/null; then
        log_warning "Bun 未安装，尝试使用 npm..."
        if ! command -v npm &> /dev/null; then
            log_error "Bun 和 npm 都未安装，请先安装其中一个"
            exit 1
        fi
        USE_NPM=true
    else
        USE_NPM=false
    fi
    
    log_success "必要工具检查完成"
}

# 检查项目结构
check_project_structure() {
    log_info "检查项目结构..."
    
    # 检查主要文件
    if [ ! -f "main.go" ]; then
        log_error "main.go 不存在，请确认在正确的项目根目录"
        exit 1
    fi
    
    if [ ! -d "web" ]; then
        log_error "web 目录不存在，请确认项目结构完整"
        exit 1
    fi
    
    if [ ! -f "web/package.json" ]; then
        log_error "web/package.json 不存在，请确认前端项目结构完整"
        exit 1
    fi
    
    log_success "项目结构检查完成"
}

# 安装前端依赖
install_frontend_deps() {
    log_info "安装前端依赖..."
    
    cd web
    if [ "$USE_NPM" = true ]; then
        npm install
    else
        bun install
    fi
    
    if [ $? -ne 0 ]; then
        log_error "前端依赖安装失败"
        exit 1
    fi
    
    cd ..
    log_success "前端依赖安装完成"
}

# 构建前端
build_frontend() {
    log_info "构建前端..."
    
    cd web
    if [ "$USE_NPM" = true ]; then
        DISABLE_ESLINT_PLUGIN='true' npm run build
    else
        DISABLE_ESLINT_PLUGIN='true' bun run build
    fi
    
    if [ $? -ne 0 ]; then
        log_error "前端构建失败"
        exit 1
    fi
    
    cd ..
    log_success "前端构建完成"
}

# 构建后端
build_backend() {
    log_info "构建后端..."
    
    # 创建bin目录
    mkdir -p bin
    
    # 构建后端
    go build -o bin/new-api main.go
    
    if [ $? -ne 0 ]; then
        log_error "后端构建失败"
        exit 1
    fi
    
    log_success "后端构建完成"
}

# 启动前端开发服务器
start_frontend_dev() {
    log_info "启动前端开发服务器..."
    
    cd web
    if [ "$USE_NPM" = true ]; then
        npm run dev -- --port $FRONTEND_PORT
    else
        bun run dev --port $FRONTEND_PORT
    fi
}

# 启动后端服务器
start_backend() {
    local use_compiled=$1
    
    if [ "$use_compiled" = true ]; then
        log_info "启动编译后的后端服务器..."
        
        if [ ! -f "bin/new-api" ]; then
            log_error "编译后的程序不存在，请先编译"
            exit 1
        fi
        
        PORT=$BACKEND_PORT ./bin/new-api
    else
        log_info "启动后端开发服务器..."
        PORT=$BACKEND_PORT go run main.go
    fi
}

# 启动全栈项目
start_fullstack() {
    local use_compiled=$1
    
    log_info "启动全栈项目..."
    
    # 启动后端服务器（后台运行）
    if [ "$use_compiled" = true ]; then
        log_info "启动编译后的后端服务器 (后台运行)..."
        
        if [ ! -f "bin/new-api" ]; then
            log_error "编译后的程序不存在，请先编译"
            exit 1
        fi
        
        PORT=$BACKEND_PORT ./bin/new-api &
        BACKEND_PID=$!
    else
        log_info "启动后端开发服务器 (后台运行)..."
        PORT=$BACKEND_PORT go run main.go &
        BACKEND_PID=$!
    fi
    
    # 等待后端启动
    sleep 3
    
    # 检查后端是否启动成功
    if kill -0 $BACKEND_PID 2>/dev/null; then
        log_success "后端服务器启动成功 (PID: $BACKEND_PID, Port: $BACKEND_PORT)"
    else
        log_error "后端服务器启动失败"
        exit 1
    fi
    
    # 启动前端开发服务器
    log_info "启动前端开发服务器..."
    cd web
    if [ "$USE_NPM" = true ]; then
        npm run dev -- --port $FRONTEND_PORT
    else
        bun run dev --port $FRONTEND_PORT
    fi
}

# 清理进程
cleanup() {
    log_info "清理进程..."
    
    if [ ! -z "$BACKEND_PID" ]; then
        log_info "停止后端服务器 (PID: $BACKEND_PID)..."
        kill $BACKEND_PID 2>/dev/null
    fi
    
    # 清理可能的残留进程
    pkill -f "go run main.go" 2>/dev/null
    pkill -f "bin/new-api" 2>/dev/null
    
    log_success "清理完成"
}

# 捕获中断信号
trap cleanup INT TERM

# 主函数
main() {
    local mode=""
    local skip_check=false
    
    # 默认端口
    BACKEND_PORT=3000
    FRONTEND_PORT=3001
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--compile)
                mode="compile"
                shift
                ;;
            -d|--direct)
                mode="direct"
                shift
                ;;
            -f|--frontend)
                mode="frontend"
                shift
                ;;
            -b|--backend)
                mode="backend"
                shift
                ;;
            --skip-check)
                skip_check=true
                shift
                ;;
            --port)
                BACKEND_PORT="$2"
                shift 2
                ;;
            --frontend-port)
                FRONTEND_PORT="$2"
                shift 2
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 如果没有指定模式，显示帮助
    if [ -z "$mode" ]; then
        show_help
        exit 1
    fi
    
    log_info "New API 项目启动脚本"
    log_info "启动模式: $mode"
    log_info "后端端口: $BACKEND_PORT"
    log_info "前端端口: $FRONTEND_PORT"
    echo ""
    
    # 基础检查
    check_git_repo
    check_project_structure
    check_prerequisites
    
    # 脚本差异检查
    if [ "$skip_check" = false ]; then
        check_script_diff
    else
        log_info "跳过脚本差异检查"
    fi
    
    echo ""
    log_info "开始启动项目..."
    
    # 根据模式执行不同操作
    case $mode in
        "compile")
            install_frontend_deps
            build_frontend
            build_backend
            start_fullstack true
            ;;
        "direct")
            start_fullstack true
            ;;
        "frontend")
            install_frontend_deps
            start_frontend_dev
            ;;
        "backend")
            start_backend false
            ;;
        *)
            log_error "无效的启动模式: $mode"
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"