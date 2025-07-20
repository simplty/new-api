#!/bin/bash

# start.sh - Go项目启动脚本
# 基准目录配置
BASE_DIR="/Users/zhao/Documents/workspace/coding/tools/smart_scripts/new-api_scripts"
SCRIPT_NAME="start.sh"
CURRENT_SCRIPT="$0"

# ============================================
# 🤖 重要提醒：AI/LLM 修改此脚本时的要求
# ============================================
# 1. 必须在下方CHANGELOG部分添加今天的修改记录
# 2. 格式：# YYYY-MM-DD: 
# 3. 格式：# - 具体修改内容描述  
# 4. 请保持CHANGELOG的时间顺序（最新的在上面）
# ============================================

# =================
# CHANGELOG
# =================
# 
# ⚠️  AI/LLM 修改指南 ⚠️
# 当您（AI/LLM）修改此脚本时，请务必在CHANGELOG中添加今天日期的修改记录
# 格式：# YYYY-MM-DD: 
# 格式：# - 具体修改内容描述
# 
# 2025-07-18:
# - 新增端口冲突检测和处理功能
# - 添加进程信息显示，显示占用端口的PID、进程名和完整命令
# - 提供三种处理方式：结束进程、使用其他端口、退出
# - 实现智能端口查找，自动寻找可用端口
# - 支持手动指定端口号
# - 添加AI/LLM修改指导注释，引导AI自动更新CHANGELOG
# - 移除复杂的自动CHANGELOG命令，采用注释指导方式
# - 将 -s 命令改为 --push，更直观地表示推送操作
# - 新增 --pull 命令，支持从基准目录拉取脚本到当前目录
# - 添加脚本备份机制，pull时自动备份当前脚本
# 
# 2025-07-17:
# - 修复前端构建问题：从npm改为bun，与项目实际使用的包管理器一致
# - 修复依赖冲突问题：添加 --legacy-peer-deps 选项处理React版本冲突
# - 改进错误处理：增加更详细的错误信息和构建状态检查
# - 禁用自动更新检查功能，避免覆盖本地修改
# - 添加环境变量设置：配置SQLite数据库文件路径为../one-api.db

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认端口配置
DEFAULT_PORT=3000

# 环境变量设置
setup_environment() {
    print_message $BLUE "设置环境变量..."
    
    # 设置SQLite数据库文件路径
    export SQLITE_PATH="../one-api.db"
    
    # 设置其他常用环境变量
    export DEBUG=true
    export GIN_MODE=debug
    
    # 设置端口（如果没有设置PORT环境变量）
    if [ -z "$PORT" ]; then
        export PORT=$DEFAULT_PORT
    fi
    
    print_message $GREEN "环境变量设置完成"
    print_message $YELLOW "SQLite数据库文件路径: $SQLITE_PATH"
    print_message $YELLOW "服务端口: $PORT"
}

# 检查端口是否被占用
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0  # 端口被占用
    else
        return 1  # 端口可用
    fi
}

# 获取占用端口的进程信息
get_port_process_info() {
    local port=$1
    local pid=$(lsof -Pi :$port -sTCP:LISTEN -t 2>/dev/null | head -1)
    if [ -n "$pid" ]; then
        local process_name=$(ps -p $pid -o comm= 2>/dev/null)
        local process_args=$(ps -p $pid -o args= 2>/dev/null)
        echo "PID: $pid, 进程名: $process_name"
        echo "完整命令: $process_args"
    fi
}

# 处理端口冲突
handle_port_conflict() {
    local port=$1
    print_message $RED "端口 $port 已被占用！"
    print_message $YELLOW "占用端口的进程信息："
    get_port_process_info $port
    echo ""
    
    print_message $YELLOW "请选择处理方式："
    echo "1) 结束占用端口的进程"
    echo "2) 使用其他端口"
    echo "3) 退出"
    echo -n "请输入选择 (1-3): "
    
    read -r choice
    case $choice in
        1)
            kill_port_process $port
            ;;
        2)
            choose_alternative_port
            ;;
        3)
            print_message $YELLOW "退出启动"
            exit 0
            ;;
        *)
            print_message $RED "无效选择，退出启动"
            exit 1
            ;;
    esac
}

# 结束占用端口的进程
kill_port_process() {
    local port=$1
    local pid=$(lsof -Pi :$port -sTCP:LISTEN -t 2>/dev/null | head -1)
    
    if [ -n "$pid" ]; then
        print_message $YELLOW "正在结束进程 PID: $pid..."
        if kill $pid 2>/dev/null; then
            sleep 2
            # 检查进程是否确实被终止
            if check_port $port; then
                print_message $YELLOW "进程未完全结束，尝试强制终止..."
                kill -9 $pid 2>/dev/null
                sleep 1
            fi
            
            if check_port $port; then
                print_message $RED "无法结束占用端口的进程，请手动处理"
                exit 1
            else
                print_message $GREEN "成功结束占用端口的进程"
            fi
        else
            print_message $RED "无法结束进程，可能需要管理员权限"
            exit 1
        fi
    else
        print_message $YELLOW "未找到占用端口的进程"
    fi
}

# 选择其他端口
choose_alternative_port() {
    print_message $BLUE "正在寻找可用端口..."
    
    # 从当前端口开始，寻找下一个可用端口
    local new_port=$((PORT + 1))
    local max_attempts=100
    local attempts=0
    
    while [ $attempts -lt $max_attempts ]; do
        if ! check_port $new_port; then
            print_message $GREEN "找到可用端口: $new_port"
            export PORT=$new_port
            return 0
        fi
        new_port=$((new_port + 1))
        attempts=$((attempts + 1))
    done
    
    # 如果没找到可用端口，让用户手动输入
    print_message $YELLOW "未找到可用端口，请手动输入端口号："
    echo -n "端口号: "
    read -r manual_port
    
    if [[ "$manual_port" =~ ^[0-9]+$ ]] && [ "$manual_port" -ge 1024 ] && [ "$manual_port" -le 65535 ]; then
        if check_port $manual_port; then
            print_message $RED "端口 $manual_port 也被占用"
            exit 1
        else
            export PORT=$manual_port
            print_message $GREEN "将使用端口: $PORT"
        fi
    else
        print_message $RED "无效的端口号"
        exit 1
    fi
}

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 显示帮助信息
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Go项目启动脚本"
    echo ""
    echo "OPTIONS:"
    echo "  -b, --build     编译前后端后启动"
    echo "  -f, --frontend  编译前端后启动"
    echo "  -bk, --backend  编译后端后启动"
    echo "  --push          推送当前脚本到基准目录"
    echo "  --pull          从基准目录拉取脚本到当前目录"
    echo "  -h, --help      显示帮助信息"
    echo ""
    echo "不带参数直接运行则为直接启动模式"
    echo ""
    echo "Examples:"
    echo "  $0              # 直接启动"
    echo "  $0 -b           # 编译前后端后启动"
    echo "  $0 --frontend   # 编译前端后启动"
    echo "  $0 -bk          # 编译后端后启动"
    echo "  $0 --push       # 推送脚本到基准目录"
    echo "  $0 --pull       # 从基准目录拉取脚本"
}

# 检查脚本更新
check_update() {
    print_message $BLUE "检查脚本更新..."
    
    local base_script="${BASE_DIR}/${SCRIPT_NAME}"
    
    # 检查基准目录是否存在
    if [ ! -d "$BASE_DIR" ]; then
        print_message $YELLOW "基准目录不存在，创建目录: $BASE_DIR"
        mkdir -p "$BASE_DIR"
        return 0
    fi
    
    # 检查基准脚本是否存在
    if [ ! -f "$base_script" ]; then
        print_message $YELLOW "基准脚本不存在，跳过更新检查"
        return 0
    fi
    
    # 比较文件内容
    if ! diff -q "$CURRENT_SCRIPT" "$base_script" > /dev/null 2>&1; then
        print_message $YELLOW "发现脚本更新，是否更新当前脚本？"
        echo -n "更新？[Y/n] "
        read -r response
        response=${response:-Y}
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            cp "$base_script" "$CURRENT_SCRIPT"
            chmod +x "$CURRENT_SCRIPT"
            print_message $GREEN "脚本已更新，请重新运行"
            exit 0
        else
            print_message $YELLOW "跳过更新"
        fi
    else
        print_message $GREEN "脚本已是最新版本"
    fi
}


# 推送脚本到基准目录
push_script() {
    print_message $BLUE "推送脚本到基准目录..."
    
    # 确保基准目录存在
    if [ ! -d "$BASE_DIR" ]; then
        print_message $YELLOW "创建基准目录: $BASE_DIR"
        mkdir -p "$BASE_DIR"
    fi
    
    local base_script="${BASE_DIR}/${SCRIPT_NAME}"
    
    # 复制当前脚本到基准目录
    cp "$CURRENT_SCRIPT" "$base_script"
    chmod +x "$base_script"
    
    print_message $GREEN "脚本已推送到基准目录: $base_script"
}

# 拉取基准目录的脚本到当前目录
pull_script() {
    print_message $BLUE "从基准目录拉取脚本..."
    
    local base_script="${BASE_DIR}/${SCRIPT_NAME}"
    
    # 检查基准目录是否存在
    if [ ! -d "$BASE_DIR" ]; then
        print_message $RED "基准目录不存在: $BASE_DIR"
        return 1
    fi
    
    # 检查基准脚本是否存在
    if [ ! -f "$base_script" ]; then
        print_message $RED "基准脚本不存在: $base_script"
        return 1
    fi
    
    # 备份当前脚本
    local backup_script="${CURRENT_SCRIPT}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$CURRENT_SCRIPT" "$backup_script"
    print_message $YELLOW "当前脚本已备份为: $backup_script"
    
    # 复制基准脚本到当前目录
    cp "$base_script" "$CURRENT_SCRIPT"
    chmod +x "$CURRENT_SCRIPT"
    
    print_message $GREEN "脚本已从基准目录拉取: $base_script"
    print_message $YELLOW "请重新运行脚本以使用新版本"
}

# 编译前端
build_frontend() {
    print_message $BLUE "编译前端..."
    
    if [ -d "web" ]; then
        cd web
        if [ -f "package.json" ]; then
            # 检查是否存在 bun.lock，优先使用 bun
            if [ -f "bun.lock" ]; then
                print_message $BLUE "使用 bun 安装依赖..."
                bun install
                if [ $? -ne 0 ]; then
                    print_message $RED "bun install 失败"
                    cd ..
                    return 1
                fi
                print_message $BLUE "使用 bun 构建前端..."
                ./node_modules/.bin/vite build
                if [ $? -ne 0 ]; then
                    print_message $RED "vite build 失败"
                    cd ..
                    return 1
                fi
            else
                print_message $BLUE "使用 npm 安装依赖..."
                npm install --legacy-peer-deps
                if [ $? -ne 0 ]; then
                    print_message $RED "npm install 失败"
                    cd ..
                    return 1
                fi
                print_message $BLUE "使用 npm 构建前端..."
                npm run build
                if [ $? -ne 0 ]; then
                    print_message $RED "npm run build 失败"
                    cd ..
                    return 1
                fi
            fi
            cd ..
            print_message $GREEN "前端编译完成"
        else
            print_message $RED "未找到 package.json 文件"
            cd ..
            return 1
        fi
    else
        print_message $YELLOW "未找到 web 目录，跳过前端编译"
    fi
}

# 编译后端
build_backend() {
    print_message $BLUE "编译后端..."
    
    if [ -f "go.mod" ]; then
        go mod download
        go build -o new-api
        print_message $GREEN "后端编译完成"
    else
        print_message $RED "未找到 go.mod 文件"
        return 1
    fi
}

# 启动服务
start_service() {
    print_message $BLUE "启动服务..."
    
    # 设置环境变量
    setup_environment
    
    # 检查端口冲突
    if check_port $PORT; then
        handle_port_conflict $PORT
    fi
    
    print_message $GREEN "准备在端口 $PORT 启动服务..."
    
    if [ -f "./new-api" ]; then
        ./new-api
    elif [ -f "main.go" ]; then
        go run main.go
    else
        print_message $RED "未找到可执行文件或 main.go"
        return 1
    fi
}

# 编译前后端后启动
build_and_start() {
    print_message $BLUE "正在执行：编译前后端后启动..."
    
    if build_frontend && build_backend; then
        start_service
    else
        print_message $RED "编译失败"
        exit 1
    fi
}

# 编译前端后启动
frontend_and_start() {
    print_message $BLUE "正在执行：编译前端后启动..."
    
    if build_frontend; then
        start_service
    else
        print_message $RED "前端编译失败"
        exit 1
    fi
}

# 编译后端后启动
backend_and_start() {
    print_message $BLUE "正在执行：编译后端后启动..."
    
    if build_backend; then
        start_service
    else
        print_message $RED "后端编译失败"
        exit 1
    fi
}

# 直接启动
direct_start() {
    print_message $BLUE "正在执行：直接启动..."
    start_service
}

# 主函数
main() {
    # 首先检查更新 (已禁用以避免覆盖本地修改)
    # check_update
    
    # 解析命令行参数
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -b|--build)
            build_and_start
            ;;
        -f|--frontend)
            frontend_and_start
            ;;
        -bk|--backend)
            backend_and_start
            ;;
        --push)
            push_script
            exit 0
            ;;
        --pull)
            pull_script
            exit 0
            ;;
        "")
            direct_start
            ;;
        *)
            print_message $RED "未知参数: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"

# ============================================
# 🤖 AI/LLM 修改提醒：
# 如果您修改了此脚本，请确认已在顶部CHANGELOG中
# 添加了今天日期的修改记录！
# ============================================