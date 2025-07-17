# 脚本使用文档 / Scripts Usage Guide

本文档详细说明了项目中各个脚本的使用方法和功能。

## 目录 / Table of Contents

1. [start.sh - 项目启动脚本](#startsh---项目启动脚本)
2. [merge_script.sh - 本地分支合并脚本](#merge_scriptsh---本地分支合并脚本)
3. [rebuild_push_image.sh - 镜像重建推送脚本](#rebuild_push_imagesh---镜像重建推送脚本)

---

## start.sh - 项目启动脚本

### 功能概述 / Overview

`start.sh` 是一个智能的项目启动脚本，支持多种启动模式，并具有分支间脚本同步功能。该脚本以 `feat/custom_use_combine` 分支为基础分支，确保所有分支的启动脚本保持一致。

### 主要特性 / Key Features

- ✅ 多种启动模式（编译启动、直接启动、仅前端、仅后端）
- ✅ 分支间脚本差异检测和同步
- ✅ 自动环境检查和依赖安装
- ✅ 智能包管理器选择（Bun/NPM）
- ✅ 可配置端口设置
- ✅ 进程管理和清理
- ✅ 详细的日志输出

### 使用方法 / Usage

#### 1. 基本语法

```bash
# 给脚本添加执行权限
chmod +x start.sh

# 显示帮助信息
./start.sh --help

# 基本使用
./start.sh [MODE] [OPTIONS]
```

#### 2. 启动模式

##### 编译启动模式 (-c, --compile)
重新编译前端和后端，然后启动全栈项目：

```bash
./start.sh -c
./start.sh --compile
```

##### 直接启动模式 (-d, --direct)
直接启动已编译的程序：

```bash
./start.sh -d
./start.sh --direct
```

##### 仅前端模式 (-f, --frontend)
仅启动前端开发服务器：

```bash
./start.sh -f
./start.sh --frontend
```

##### 仅后端模式 (-b, --backend)
仅启动后端开发服务器：

```bash
./start.sh -b
./start.sh --backend
```

#### 3. 配置选项

```bash
# 指定后端端口
./start.sh -c --port 8080

# 指定前端端口
./start.sh -f --frontend-port 3002

# 跳过脚本差异检查
./start.sh -c --skip-check

# 组合使用
./start.sh -c --port 8080 --frontend-port 3002
```

#### 4. 脚本同步功能

脚本启动时会自动检查当前分支的脚本与基础分支（`feat/custom_use_combine`）的差异：

**如果当前分支是 `feat/custom_use_combine`**：
- 跳过差异检查，直接启动

**如果当前分支不是基础分支**：
- 自动比较脚本差异
- 如果有差异，提供5种选择：
  1. 继续执行当前脚本
  2. 同步基础分支脚本到当前分支
  3. 将当前脚本更新到基础分支
  4. 查看完整差异
  5. 退出脚本

#### 5. 自动环境检查

脚本会自动检查以下环境：
- ✅ Git仓库状态
- ✅ Go环境
- ✅ Node.js包管理器（Bun优先，NPM备选）
- ✅ 项目结构完整性

### 工作流程 / Workflow

#### 完整启动流程（编译模式）

1. **环境检查** - 检查Git、Go、Node.js环境
2. **脚本同步** - 检查并处理脚本差异
3. **依赖安装** - 安装前端依赖
4. **前端构建** - 构建前端静态文件
5. **后端构建** - 编译Go程序
6. **服务启动** - 启动后端和前端服务
7. **进程管理** - 监控和清理进程

#### 差异检查流程

1. **分支检测** - 获取当前分支名称
2. **脚本对比** - 与基础分支脚本比较
3. **差异展示** - 显示脚本差异概览
4. **用户选择** - 提供同步或继续选项
5. **执行操作** - 根据用户选择执行相应操作

### 示例 / Examples

#### 示例1: 开发环境启动

```bash
# 重新编译并启动，使用默认端口
./start.sh -c

# 输出示例:
# [INFO] New API 项目启动脚本
# [INFO] 启动模式: compile
# [INFO] 后端端口: 3000
# [INFO] 前端端口: 3001
# [INFO] 检查脚本差异...
# [SUCCESS] 脚本无差异，继续执行
```

#### 示例2: 脚本差异处理

```bash
./start.sh -c

# 如果检测到差异，输出示例:
# [WARNING] 检测到脚本差异!
# [INFO] 脚本差异详情:
# ----------------------------------------
# --- base_script.sh
# +++ current_script.sh
# @@ -1,3 +1,4 @@
#  #!/bin/bash
#  echo "Hello"
# +echo "World"
# ----------------------------------------
# 
# 请选择操作:
#   1) 继续执行当前脚本
#   2) 同步基础分支脚本到当前分支
#   3) 将当前脚本更新到基础分支
#   4) 查看完整差异
#   5) 退出脚本
```

#### 示例3: 自定义端口启动

```bash
# 后端使用8080端口，前端使用3002端口
./start.sh -c --port 8080 --frontend-port 3002
```

#### 示例4: 仅启动前端开发服务器

```bash
./start.sh -f --frontend-port 3002
```

### 进程管理 / Process Management

#### 自动清理
脚本支持优雅的进程清理：
- 捕获 `Ctrl+C` 信号
- 自动停止后台进程
- 清理残留进程

#### 手动清理
如果需要手动清理进程：

```bash
# 停止Go开发服务器
pkill -f "go run main.go"

# 停止编译后的程序
pkill -f "bin/new-api"

# 停止前端开发服务器
pkill -f "bun run dev"
pkill -f "npm run dev"
```

### 故障排除 / Troubleshooting

#### 常见问题

1. **脚本权限问题**
   ```bash
   chmod +x start.sh
   ```

2. **端口被占用**
   ```bash
   # 查找占用端口的进程
   lsof -i :3000
   
   # 使用不同端口
   ./start.sh -c --port 8080
   ```

3. **编译失败**
   ```bash
   # 检查Go环境
   go version
   
   # 检查Node.js环境
   node --version
   bun --version
   ```

4. **依赖安装失败**
   ```bash
   # 清理依赖缓存
   cd web && rm -rf node_modules
   cd web && bun install
   ```

#### 日志分析

脚本提供详细的彩色日志：
- 🔵 `[INFO]` - 一般信息
- 🟢 `[SUCCESS]` - 成功操作
- 🟡 `[WARNING]` - 警告信息
- 🔴 `[ERROR]` - 错误信息
- 🟣 `[DEBUG]` - 调试信息

### 配置建议 / Configuration Tips

#### 环境变量
可以通过环境变量预设端口：

```bash
# 在 .bashrc 或 .zshrc 中设置
export NEW_API_BACKEND_PORT=8080
export NEW_API_FRONTEND_PORT=3002
```

#### 别名设置
为常用命令设置别名：

```bash
# 在 .bashrc 或 .zshrc 中添加
alias start-dev='./start.sh -c'
alias start-fe='./start.sh -f'
alias start-be='./start.sh -b'
```

---

## merge_script.sh - 本地分支合并脚本

### 功能概述 / Overview

`merge_script.sh` 是一个智能分支合并脚本，专门用于安全地合并本地分支到 `feat/custom_use_combine` 分支。

### 主要特性 / Key Features

- ✅ 自动检查当前分支和工作区状态
- ✅ 比较分支的 alpha 基础版本
- ✅ 自动创建备份分支
- ✅ 集成 VSCode 进行冲突解决
- ✅ 完整的错误处理和恢复提示
- ✅ 彩色输出和详细日志

### 使用方法 / Usage

#### 1. 基本使用

```bash
# 给脚本添加执行权限
chmod +x merge_script.sh

# 运行脚本
./merge_script.sh
```

#### 2. 配置选项

脚本顶部提供了用户可配置的选项：

```bash
# 允许合并的分支列表
ALLOWED_BRANCHES=(
    "alpha"
    "feat/custom_func"
    "feat/admin_query_token"
    "feat/custompass"
    "main"
)

# 是否启用分支白名单检查 (true/false)
ENABLE_BRANCH_WHITELIST=true
```

- **ALLOWED_BRANCHES**：定义允许合并到当前分支的分支列表
- **ENABLE_BRANCH_WHITELIST**：设置为 `false` 可禁用白名单检查，允许合并任何分支

#### 3. 操作流程

1. **前置检查**：确认当前分支为 `feat/custom_use_combine`，工作区干净
2. **分支白名单检查**：显示允许合并的分支列表
3. **选择分支**：从允许的分支列表中选择要合并的分支
4. **版本检查**：比较两个分支的 alpha 基础版本
5. **执行合并**：自动尝试合并，如有冲突则启动 VSCode 解决

#### 4. Alpha 版本检查

脚本会使用 `git merge-base` 检查两个分支的共同祖先：
- 如果两个分支基于相同的 alpha 版本，直接合并
- 如果基于不同的 alpha 版本，会提示用户：
  - 哪个分支基于较老的 alpha 版本
  - 是否继续合并操作

#### 5. 冲突处理

当检测到合并冲突时：
1. 自动显示冲突文件列表
2. 如果 VSCode 可用，自动启动 VSCode 解决冲突
3. 用户在 VSCode 中解决冲突后关闭编辑器
4. 脚本检查冲突是否解决完成
5. 自动提交合并结果

#### 6. 备份机制

脚本会自动创建备份分支：
- 格式：`feat/custom_use_combine_backup_YYYYMMDD_HHMMSS`
- 合并成功后可选择删除备份分支
- 出现错误时可通过备份分支恢复

### 示例 / Examples

#### 示例1: 标准合并流程

```bash
./merge_script.sh

# 输出示例:
# ==================================
#     分支合并脚本启动
# ==================================
# 
# [INFO] 检查依赖工具...
# [INFO] 检查当前分支...
# [SUCCESS] 当前分支正确: feat/custom_use_combine
# [INFO] 检查工作区状态...
# [SUCCESS] 工作区干净
# 
# [INFO] 允许合并的分支：
#   ✓ alpha
#   ✓ feat/custom_func
#   ✓ feat/custompass
#   ✓ main
# 
# 请输入要合并到 feat/custom_use_combine 的分支名: feat/custom_func
# [SUCCESS] 选择的源分支: feat/custom_func
# [INFO] 检查分支的 alpha 基础版本...
# [SUCCESS] 两个分支基于相同的 alpha 版本 (a36ce199)
# 
# [INFO] 准备合并 feat/custom_func -> feat/custom_use_combine
# 是否继续? (y/N): y
```

#### 示例2: 版本差异处理

```bash
./merge_script.sh

# 输出示例:
# [WARNING] 两个分支基于不同的 alpha 版本：
#   feat/custom_use_combine 基于: a36ce199
#   feat/custom_func 基于: eb59f9c7
# 
# [WARNING] feat/custom_func 基于较老的 alpha 版本，建议先更新
# 
# 是否继续合并? (y/N): y
```

### VSCode 集成 / VSCode Integration

当检测到合并冲突时，脚本会：
1. 自动启动 VSCode 并等待用户操作
2. 显示冲突文件列表
3. 在 VSCode 中解决冲突后关闭编辑器
4. 脚本自动检查冲突是否解决完成
5. 自动提交合并结果

如果 VSCode 不可用，脚本会提供手动解决冲突的指导。

### 注意事项 / Important Notes

- ⚠️ 脚本只能在 `feat/custom_use_combine` 分支上运行
- ⚠️ 合并前请确保工作区干净（无未提交的更改）
- ⚠️ 建议在合并前备份重要更改
- ⚠️ 冲突解决需要用户具备Git基础知识

---

## rebuild_push_image.sh - 镜像重建推送脚本

### 功能概述 / Overview

`rebuild_push_image.sh` 是一个全自动的Docker镜像构建和推送脚本，支持多平台构建，可以将构建好的镜像推送到阿里云Docker Registry。

### 主要特性 / Key Features

- ✅ 多平台构建支持 (AMD64, ARM64)
- ✅ 自动版本管理
- ✅ 环境变量配置
- ✅ 镜像清理和优化
- ✅ 阿里云Registry集成
- ✅ 交互式配置界面
- ✅ 详细的构建日志

### 使用方法 / Usage

#### 1. 基本使用

```bash
# 给脚本添加执行权限
chmod +x rebuild_push_image.sh

# 运行脚本
./rebuild_push_image.sh
```

#### 2. 命令行参数

```bash
# 显示帮助信息
./rebuild_push_image.sh --help

# 跳过特定步骤
./rebuild_push_image.sh --skip-cleanup --skip-push

# 指定版本号
./rebuild_push_image.sh --version v1.2.3

# 跳过登录步骤（如果已经登录）
./rebuild_push_image.sh --skip-login
```

#### 3. 环境变量配置

脚本支持通过 `.env` 文件配置环境变量：

```bash
# Docker Registry 配置
REGISTRY_URL=crpi-eep0ohmpw8c1mmyv.cn-hangzhou.personal.cr.aliyuncs.com
REGISTRY_USERNAME=zhidateam
REGISTRY_PASSWORD=your_password
REGISTRY_NAMESPACE=zhidateam
REGISTRY_REPOSITORY=new-api

# 应用配置
PORT=3000
SESSION_SECRET=your_random_secret_string
DEBUG=false
```

#### 4. 交互式配置

如果没有 `.env` 文件，脚本会提供交互式配置：

1. **重新加载 .env 文件** - 如果已创建 `.env` 文件
2. **交互式配置** - 逐步引导创建 `.env` 文件
3. **使用默认配置** - 使用内置默认值
4. **退出程序** - 稍后手动配置

#### 5. 版本管理

脚本支持两种版本号设置方式：

1. **自动版本号** - 使用日期格式 (YYMMDD)
2. **手动版本号** - 用户自定义版本号

#### 6. 构建平台选择

支持多种构建平台：

1. **当前平台** - 根据系统架构自动选择
2. **Linux AMD64** - x86_64服务器
3. **Linux ARM64** - ARM服务器
4. **多平台构建** - 同时构建AMD64和ARM64

### 操作流程 / Workflow

#### 完整构建流程

1. **环境检查** - 检查 `.env` 文件和环境变量
2. **版本确认** - 选择或输入版本号
3. **平台选择** - 选择构建平台
4. **清理旧镜像** - 删除旧版本镜像和缓存
5. **构建新镜像** - 使用Docker Buildx构建
6. **登录Registry** - 登录阿里云Docker Registry
7. **推送镜像** - 推送到远程仓库
8. **清理标记** - 清理本地标记的镜像
9. **显示完成信息** - 显示拉取和使用命令

#### 多平台构建特殊流程

对于多平台构建，脚本会：
1. 自动检查和创建Docker Buildx构建器
2. 直接在构建时推送到远程仓库
3. 跳过本地镜像操作步骤

### 示例 / Examples

#### 示例1: 标准构建流程

```bash
./rebuild_push_image.sh
# 选择版本: y (使用默认版本)
# 选择平台: 1 (当前平台)
# 等待构建完成...
```

#### 示例2: 多平台构建

```bash
./rebuild_push_image.sh
# 选择版本: m -> 输入: v2.1.0
# 选择平台: 4 (多平台构建)
# 等待构建完成...
```

#### 示例3: 跳过特定步骤

```bash
# 只构建不推送
./rebuild_push_image.sh --skip-push

# 指定版本号并跳过清理
./rebuild_push_image.sh --version v1.0.0 --skip-cleanup
```

### 输出信息 / Output Information

构建完成后，脚本会显示：

- 本地镜像标签
- 远程镜像地址
- 镜像拉取命令
- 容器运行命令
- 部署建议

### 故障排除 / Troubleshooting

#### 常见问题

1. **Docker Buildx不可用**
   - 确保Docker版本支持Buildx
   - 运行 `docker buildx version` 检查

2. **Registry登录失败**
   - 检查用户名和密码
   - 确认Registry地址正确

3. **多平台构建失败**
   - 确保Docker Desktop开启了实验性功能
   - 检查网络连接

4. **构建超时**
   - 检查网络连接
   - 清理Docker缓存

#### 日志分析

脚本提供详细的彩色日志输出：
- 🔵 `[INFO]` - 信息提示
- 🟢 `[SUCCESS]` - 成功操作
- 🟡 `[WARNING]` - 警告信息
- 🔴 `[ERROR]` - 错误信息

### 安全注意事项 / Security Notes

- ⚠️ 不要在代码中硬编码密码
- ⚠️ 使用 `.env` 文件存储敏感信息
- ⚠️ 确保 `.env` 文件不被提交到版本控制
- ⚠️ 定期更新Registry密码

---

## 总结 / Summary

这两个脚本为开发工作流提供了强大的自动化支持：

- **merge_script.sh** 简化了本地分支合并操作，提供了安全的冲突处理机制
- **rebuild_push_image.sh** 自动化了Docker镜像的构建和部署流程

使用这些脚本可以显著提高开发效率，减少手动操作错误，确保操作的一致性和可靠性。

---

## 更新记录 / Update Log

- **2024-01-15**: 创建文档，添加两个脚本的详细使用说明
- 后续更新将记录在此处...