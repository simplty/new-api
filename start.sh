#!/bin/bash

# start.sh - Go项目启动脚本
# 基准目录配置
BASE_DIR="/Users/zhao/Documents/workspace/coding/tools/smart_scripts/new-api_scripts"
SCRIPT_NAME="start.sh"
CURRENT_SCRIPT="$0"

# =================
# CHANGELOG
# =================
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

# 环境变量设置
setup_environment() {
    print_message $BLUE "设置环境变量..."
    
    # 设置SQLite数据库文件路径
    export SQLITE_PATH="../one-api.db"
    
    # 设置其他常用环境变量
    export DEBUG=true
    export GIN_MODE=debug
    
    print_message $GREEN "环境变量设置完成"
    print_message $YELLOW "SQLite数据库文件路径: $SQLITE_PATH"
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
    echo "  -s, --sync      同步脚本到基准目录"
    echo "  -h, --help      显示帮助信息"
    echo ""
    echo "不带参数直接运行则为直接启动模式"
    echo ""
    echo "Examples:"
    echo "  $0              # 直接启动"
    echo "  $0 -b           # 编译前后端后启动"
    echo "  $0 --frontend   # 编译前端后启动"
    echo "  $0 -bk          # 编译后端后启动"
    echo "  $0 -s           # 同步脚本"
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

# 同步脚本到基准目录
sync_script() {
    print_message $BLUE "同步脚本到基准目录..."
    
    # 确保基准目录存在
    if [ ! -d "$BASE_DIR" ]; then
        print_message $YELLOW "创建基准目录: $BASE_DIR"
        mkdir -p "$BASE_DIR"
    fi
    
    local base_script="${BASE_DIR}/${SCRIPT_NAME}"
    
    # 复制当前脚本到基准目录
    cp "$CURRENT_SCRIPT" "$base_script"
    chmod +x "$base_script"
    
    print_message $GREEN "脚本已同步到基准目录: $base_script"
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
        -s|--sync)
            sync_script
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