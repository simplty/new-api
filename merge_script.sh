#!/bin/bash

# 分支合并脚本 - 用于合并本地分支到 feat/custom_use_combine
# 作者: Claude Code
# 版本: 1.0
#
# 配置说明：
# 1. 修改 ALLOWED_BRANCHES 数组来定义允许合并的分支
# 2. 设置 ENABLE_BRANCH_WHITELIST=false 可以禁用分支白名单检查
# 3. 脚本只能在 feat/custom_use_combine 分支上运行

set -e  # 遇到错误立即退出

# 添加陷阱处理，确保在出错时清理
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "脚本异常退出 (退出码: $exit_code)"
        
        # 如果合并过程中出错，提供恢复选项
        if git status --porcelain | grep -q "^UU\|^AA\|^DD"; then
            echo
            log_warning "检测到未完成的合并，您可以："
            echo "1. 继续解决冲突: 编辑冲突文件，然后运行 'git add . && git commit'"
            echo "2. 取消合并: git merge --abort"
            echo "3. 恢复到备份分支: git reset --hard [backup_branch_name]"
        fi
    fi
}

trap cleanup EXIT

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 目标分支
TARGET_BRANCH="feat/custom_use_combine"
BASE_BRANCH="alpha"

# 用户可配置：允许合并的分支列表
# 用户可以修改这个数组来定义哪些分支可以合并到当前分支
ALLOWED_BRANCHES=(
    "alpha"
    "feat/custom_func"
    "feat/admin_query_token"
    "feat/custompass"
    "main"
)

# 是否启用分支白名单检查 (true/false)
ENABLE_BRANCH_WHITELIST=true

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

# 检查必要的工具
check_dependencies() {
    log_info "检查依赖工具..."
    
    if ! command -v git &> /dev/null; then
        log_error "Git 未安装或不在 PATH 中"
        exit 1
    fi
    
    if ! command -v code &> /dev/null; then
        log_warning "VSCode 未安装或不在 PATH 中，冲突解决将使用默认编辑器"
        VSCODE_AVAILABLE=false
    else
        VSCODE_AVAILABLE=true
    fi
}

# 检查当前分支
check_current_branch() {
    log_info "检查当前分支..."
    
    current_branch=$(git branch --show-current)
    
    if [ "$current_branch" != "$TARGET_BRANCH" ]; then
        log_error "当前分支是 '$current_branch'，不是目标分支 '$TARGET_BRANCH'"
        echo "请先切换到 $TARGET_BRANCH 分支："
        echo "  git checkout $TARGET_BRANCH"
        exit 1
    fi
    
    log_success "当前分支正确: $TARGET_BRANCH"
}

# 检查工作区状态
check_working_directory() {
    log_info "检查工作区状态..."
    
    if ! git diff --quiet || ! git diff --cached --quiet; then
        log_error "工作区有未提交的更改"
        echo "请先提交或储藏您的更改："
        echo "  git add . && git commit -m 'your message'"
        echo "  或者: git stash"
        exit 1
    fi
    
    log_success "工作区干净"
}

# 检查分支是否在允许列表中
is_branch_allowed() {
    local branch="$1"
    
    # 如果未启用白名单检查，允许所有分支
    if [ "$ENABLE_BRANCH_WHITELIST" != "true" ]; then
        return 0
    fi
    
    # 检查分支是否在允许列表中
    for allowed_branch in "${ALLOWED_BRANCHES[@]}"; do
        if [ "$branch" = "$allowed_branch" ]; then
            return 0
        fi
    done
    
    return 1
}

# 显示可用分支
show_available_branches() {
    if [ "$ENABLE_BRANCH_WHITELIST" = "true" ]; then
        log_info "允许合并的分支："
        local index=1
        AVAILABLE_BRANCHES_FOR_SELECTION=()
        for branch in "${ALLOWED_BRANCHES[@]}"; do
            # 检查分支是否实际存在
            if git show-ref --quiet --heads "$branch"; then
                echo -e "  ${GREEN}$index)${NC} $branch"
                AVAILABLE_BRANCHES_FOR_SELECTION+=("$branch")
                ((index++))
            else
                echo -e "  ${YELLOW}⚠${NC} $branch (不存在)"
            fi
        done
    else
        log_info "可用的本地分支："
        local index=1
        AVAILABLE_BRANCHES_FOR_SELECTION=()
        # 获取所有分支但排除当前分支
        while IFS= read -r branch; do
            branch=$(echo "$branch" | sed 's/^[[:space:]]*//')  # 去掉前导空格
            if [ "$branch" != "$TARGET_BRANCH" ]; then
                echo -e "  ${GREEN}$index)${NC} $branch"
                AVAILABLE_BRANCHES_FOR_SELECTION+=("$branch")
                ((index++))
            fi
        done < <(git branch | grep -v "^*" | grep -v "$TARGET_BRANCH")
    fi
}

# 获取用户输入的分支名
get_source_branch() {
    echo
    show_available_branches
    echo
    
    while true; do
        read -p "请输入要合并到 $TARGET_BRANCH 的分支名或序号: " user_input
        
        if [ -z "$user_input" ]; then
            log_warning "输入不能为空"
            continue
        fi
        
        # 检查输入是否为数字
        if [[ "$user_input" =~ ^[0-9]+$ ]]; then
            # 数字输入处理
            local branch_index=$((user_input - 1))
            
            if [ $branch_index -lt 0 ] || [ $branch_index -ge ${#AVAILABLE_BRANCHES_FOR_SELECTION[@]} ]; then
                log_error "无效的序号 '$user_input'，请输入 1 到 ${#AVAILABLE_BRANCHES_FOR_SELECTION[@]} 之间的数字"
                continue
            fi
            
            source_branch="${AVAILABLE_BRANCHES_FOR_SELECTION[$branch_index]}"
        else
            # 分支名输入处理
            source_branch="$user_input"
            
            if [ "$source_branch" = "$TARGET_BRANCH" ]; then
                log_warning "不能合并分支到自己"
                continue
            fi
            
            if ! git show-ref --quiet --heads "$source_branch"; then
                log_error "分支 '$source_branch' 不存在"
                continue
            fi
            
            # 检查分支是否在允许列表中
            if ! is_branch_allowed "$source_branch"; then
                log_error "分支 '$source_branch' 不在允许合并的分支列表中"
                if [ "$ENABLE_BRANCH_WHITELIST" = "true" ]; then
                    echo "允许的分支："
                    for i in "${!AVAILABLE_BRANCHES_FOR_SELECTION[@]}"; do
                        echo "  $((i+1)). ${AVAILABLE_BRANCHES_FOR_SELECTION[$i]}"
                    done
                fi
                continue
            fi
        fi
        
        break
    done
    
    log_success "选择的源分支: $source_branch"
}

# 检查分支的 alpha 基础版本
check_alpha_base() {
    log_info "检查分支的 alpha 基础版本..."
    
    # 获取当前分支基于的 alpha 版本
    target_base=$(git merge-base "$TARGET_BRANCH" "$BASE_BRANCH" 2>/dev/null || echo "")
    if [ -z "$target_base" ]; then
        log_error "无法找到 $TARGET_BRANCH 与 $BASE_BRANCH 的共同祖先"
        exit 1
    fi
    
    # 获取源分支基于的 alpha 版本
    source_base=$(git merge-base "$source_branch" "$BASE_BRANCH" 2>/dev/null || echo "")
    if [ -z "$source_base" ]; then
        log_error "无法找到 $source_branch 与 $BASE_BRANCH 的共同祖先"
        exit 1
    fi
    
    # 比较两个分支的 alpha 基础版本
    if [ "$target_base" = "$source_base" ]; then
        log_success "两个分支基于相同的 alpha 版本 (${target_base:0:8})"
        return 0
    else
        log_warning "两个分支基于不同的 alpha 版本："
        echo "  $TARGET_BRANCH 基于: ${target_base:0:8}"
        echo "  $source_branch 基于: ${source_base:0:8}"
        echo
        
        # 判断哪个分支更新
        if git merge-base --is-ancestor "$target_base" "$source_base"; then
            log_warning "$TARGET_BRANCH 基于较老的 alpha 版本，建议先更新"
        elif git merge-base --is-ancestor "$source_base" "$target_base"; then
            log_warning "$source_branch 基于较老的 alpha 版本，建议先更新"
        else
            log_warning "两个分支基于不同的 alpha 版本，需要检查冲突"
        fi
        
        echo
        read -p "是否继续合并? (y/N): " continue_merge
        if [[ ! "$continue_merge" =~ ^[Yy]$ ]]; then
            log_info "操作已取消"
            exit 0
        fi
        
        return 0
    fi
}

# 执行合并操作
perform_merge() {
    log_info "开始合并操作..."
    
    # 创建备份分支
    backup_branch="${TARGET_BRANCH}_backup_$(date +%Y%m%d_%H%M%S)"
    git branch "$backup_branch"
    log_success "创建备份分支: $backup_branch"
    
    # 尝试合并
    log_info "尝试合并 $source_branch 到 $TARGET_BRANCH..."
    
    if git merge "$source_branch" --no-edit; then
        log_success "合并成功！无冲突。"
        
        # 显示合并结果
        echo
        log_info "合并摘要："
        git show --stat --oneline HEAD
        
        # 询问是否保留备份分支
        echo
        read -p "合并成功，是否删除备份分支 $backup_branch? (Y/n): " delete_backup
        if [[ "$delete_backup" =~ ^[Nn]$ ]]; then
            log_info "保留备份分支: $backup_branch"
        else
            git branch -d "$backup_branch"
            log_success "删除备份分支: $backup_branch"
        fi
        
        return 0
    else
        log_warning "合并存在冲突，需要手动解决"
        return 1
    fi
}

# 处理合并冲突
handle_conflicts() {
    log_info "检测到合并冲突，准备启动解决工具..."
    
    # 显示冲突文件
    echo
    log_info "存在冲突的文件："
    git status --porcelain | grep "^UU\|^AA\|^DD" | awk '{print "  " $2}'
    
    echo
    if [ "$VSCODE_AVAILABLE" = true ]; then
        log_info "启动 VSCode 解决冲突..."
        echo "请在 VSCode 中解决冲突，然后关闭 VSCode 继续。"
        echo
        
        # 启动 VSCode 并等待
        code --wait .
        
        # 检查是否还有冲突
        if git status --porcelain | grep -q "^UU\|^AA\|^DD"; then
            log_error "仍有未解决的冲突，请手动解决"
            show_manual_resolution_help
            return 1
        fi
        
        log_success "冲突已解决"
        
        # 完成合并
        log_info "提交合并结果..."
        git commit --no-edit
        
        log_success "合并完成！"
        return 0
    else
        log_warning "VSCode 不可用，请手动解决冲突"
        show_manual_resolution_help
        return 1
    fi
}

# 显示手动解决冲突的帮助信息
show_manual_resolution_help() {
    echo
    log_info "手动解决冲突的步骤："
    echo "1. 编辑冲突文件，解决所有 <<<<<<< 和 >>>>>>> 标记"
    echo "2. 添加解决后的文件: git add <file>"
    echo "3. 完成合并: git commit"
    echo "4. 或者取消合并: git merge --abort"
    echo
    echo "当前状态："
    git status
}

# 主函数
main() {
    echo "=================================="
    echo "    分支合并脚本启动"
    echo "=================================="
    echo
    
    # 1. 检查依赖
    check_dependencies
    
    # 2. 检查当前分支
    check_current_branch
    
    # 3. 检查工作区
    check_working_directory
    
    # 4. 获取源分支
    get_source_branch
    
    # 5. 检查 alpha 基础版本
    check_alpha_base
    
    echo
    log_info "准备合并 $source_branch -> $TARGET_BRANCH"
    
    # 询问用户确认
    read -p "是否继续? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "操作已取消"
        exit 0
    fi
    
    # 6. 执行合并
    if perform_merge; then
        log_success "合并操作成功完成"
    else
        # 7. 处理冲突
        if handle_conflicts; then
            log_success "冲突解决完成，合并成功"
        else
            log_error "合并失败，请手动解决"
            exit 1
        fi
    fi
    
    echo
    echo "=================================="
    echo "    合并完成"
    echo "=================================="
    
    # 显示最终状态
    echo
    log_info "当前分支状态："
    git log --oneline -5
    
    echo
    log_success "分支合并脚本执行完成！"
}

# 运行主函数
main "$@"