# /api/admin/token/search API 功能说明文档

## API 概述

`/api/admin/token/search` 是一个超级管理员专用的 API 接口，用于根据 token key 查询 token 信息和关联的用户信息。

## 接口信息

- **路径**: `/api/admin/token/search`
- **方法**: `GET`
- **权限**: 超级管理员 (RootAuth)
- **处理函数**: `controller.AdminSearchTokenByKey`

## 权限验证

该接口使用 `middleware.RootAuth()` 中间件进行权限验证，只有超级管理员才能访问。

## 请求参数

### Query 参数

| 参数名 | 类型   | 必填 | 说明                                    |
|--------|--------|------|----------------------------------------|
| token  | string | 是   | 要查询的 token key，长度32位，支持带 sk- 前缀或不带前缀 |

### 参数处理逻辑

1. 检查 `token` 参数是否为空
2. 如果 token 以 `sk-` 前缀开头，自动去除该前缀
3. 使用处理后的 token key 进行查询

## 响应格式

### 成功响应

```json
{
  "success": true,
  "message": "",
  "data": {
    "token": {
      "id": 123,
      "user_id": 456,
      "key": null,  // 已清空，不返回真实 key
      "status": 1,
      "name": "token名称",
      "created_time": 1234567890, // Unix 时间戳
      "accessed_time": 1234567890, // Unix 时间戳
      "expired_time": -1,
      "remain_quota": 1000,
      "unlimited_quota": false,
      "model_limits_enabled": false,
      "model_limits": "",
      "allow_ips": "",
      "used_quota": 0,
      "group": ""
    },
    "user": {
      "id": 456,
      "username": "用户名",
      "display_name": "显示名称",
      "email": "user@example.com",
      "role": 1,
      "status": 1,
      "quota": 5000,
      "used_quota": 2000,
      "group": "default"
      // ... 其他用户信息
    }
  }
}
```

### 错误响应

#### 参数错误
```json
{
  "success": false,
  "message": "token参数不能为空"
}
```

#### Token 不存在
```json
{
  "success": false,
  "message": "未找到该令牌: record not found"
}
```

#### 权限验证失败
```json
{
  "success": false,
  "message": "无权限访问"
}
```

#### 用户信息获取失败
```json
{
  "success": false,
  "message": "获取用户信息失败: record not found"
}
```

#### 服务器内部错误
```json
{
  "success": false,
  "message": "服务器内部错误"
}
```

## 功能特性

### 1. Token 查询
- 通过 `model.GetTokenByKey()` 查询 token 信息
- 支持从缓存或数据库查询 (第二个参数为 true，强制从数据库查询)
- 自动处理 `sk-` 前缀

### 2. 用户信息关联
- 自动查询 token 所属用户的详细信息
- 通过 `model.GetUserById()` 获取用户数据

### 3. 安全处理
- 返回前清空 token key，避免泄露敏感信息
- 只有超级管理员才能使用此接口

### 4. 错误处理
- 完整的参数验证
- 详细的错误信息返回
- 数据库查询异常处理

## 使用场景

1. **Token 管理**: 超级管理员查看特定 token 的详细信息
2. **用户支持**: 根据用户提供的 token 快速定位用户和相关信息
3. **安全审计**: 查看 token 的使用状态、配额情况等
4. **问题排查**: 当用户反馈 token 相关问题时，快速定位问题

## 示例用法

### 请求示例

```bash
# 使用 curl 查询带 sk- 前缀的 token
curl -X GET "http://localhost:3000/api/admin/token/search?token=sk-1234567890abcdef" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"

# 使用 curl 查询不带前缀的 token
curl -X GET "http://localhost:3000/api/admin/token/search?token=1234567890abcdef" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

### 响应示例

```json
{
  "success": true,
  "message": "",
  "data": {
    "token": {
      "id": 123,
      "user_id": 456,
      "key": null,
      "status": 1,
      "name": "API测试Token",
      "created_time": 1700000000,
      "accessed_time": 1700001000,
      "expired_time": -1,
      "remain_quota": 5000,
      "unlimited_quota": false,
      "model_limits_enabled": true,
      "model_limits": "gpt-3.5-turbo,gpt-4",
      "allow_ips": "192.168.1.0/24",
      "used_quota": 1500,
      "group": "premium"
    },
    "user": {
      "id": 456,
      "username": "testuser",
      "display_name": "测试用户",
      "email": "test@example.com",
      "role": 1,
      "status": 1,
      "quota": 10000,
      "used_quota": 3000,
      "group": "premium"
    }
  }
}
```

## 注意事项

1. 该接口仅限超级管理员使用
2. 返回的 token 对象中 key 字段已被清空，确保安全性
3. 支持自动处理 `sk-` 前缀，提升使用便利性
4. 返回数据包含 token 和用户的完整信息，便于管理和排查