# IP Location Alfred Workflow

一个基于 Shell 脚本的 IP 地址归属地查询 Alfred Workflow，参考 [ip138-alfredworkflow](https://github.com/hellosa/ip138-alfredworkflow) 项目开发。

## 功能特性

- ✅ **自动获取内网 IP**：显示本地网络 IPv4 地址
- ✅ **自动获取外网 IP**：显示公网 IPv4/IPv6 地址
- ✅ **IP 归属地查询**：支持查询任意 IP 地址的归属地信息
- ✅ **详细信息显示**：国家、地区、城市、ISP 信息
- ✅ **免费 API**：使用 ip-api.com 免费服务，无需 API Key
- ✅ **轻量快速**：基于 Shell 脚本，无额外依赖

## 安装方法

### 方法 1：直接安装（推荐）

1. 下载 `ip138-location.alfredworkflow` 文件
2. 双击文件，Alfred 会自动安装

### 方法 2：手动安装

1. 解压 `ip138-location.alfredworkflow`（实际上是一个 zip 文件）
2. 将解压后的文件夹复制到：
   ```
   ~/Library/Application Support/Alfred/Alfred.alfredpreferences/workflows/
   ```
3. 在 Alfred Preferences > Workflows 中重新加载

## 使用方法

### 基本使用

1. **查看内网和外网 IP**：
   - 输入关键词 `ip`
   - 自动显示内网 IPv4 和外网 IPv4/IPv6 及其归属地信息

2. **查询指定 IP 归属地**：
   - 输入 `ip 8.8.8.8`
   - 显示该 IP 的归属地信息

3. **复制 IP 地址**：
   - 选择结果后按 `Enter` 复制 IP 地址到剪贴板
   - 会显示复制成功的通知

## 输出示例

```
内网 IPv4: 192.168.1.100
本地网络

外网 IPv4: 123.45.67.89
中国 广东省 深圳市 | 中国联通
```

## API 说明

本 workflow 使用 [ip-api.com](http://ip-api.com) 免费服务：

- **免费限制**：45 次/分钟
- **无需 API Key**
- **支持中文**：自动使用中文语言返回结果
- **返回字段**：国家、地区、城市、ISP 信息

## 技术实现

### Shell 脚本功能

1. **获取内网 IP**：
   - 使用 `ipconfig getifaddr en0`（macOS）
   - 备用：`ifconfig` 和 `hostname`
   - 自动过滤 127.0.0.1 和链路本地地址

2. **获取外网 IP**：
   - 优先获取 IPv4（使用 `-4` 参数）
   - 多个服务备选（ipify.org, icanhazip.com, ifconfig.me）
   - 支持 IPv6 作为备选

3. **查询归属地**：
   - 调用 ip-api.com API
   - 错误处理和超时控制（5秒）
   - JSON 格式解析

### Workflow 结构

```
Script Filter (输入)
    ↓
执行 Shell 脚本
    ↓
显示结果列表（内网 IP + 外网 IP）
    ↓
用户选择
    ↓
复制到剪贴板
    ↓
显示通知
```

## 项目结构

```
ip138-location-workflow/
├── ip138.sh                    # Shell 脚本（核心逻辑）
├── info.plist                  # Alfred workflow 配置
├── icon.png                    # 图标文件
└── README.md                   # 说明文档
```

## 开发

### 本地开发

1. 克隆或下载项目
2. 修改 `ip138.sh` 脚本
3. 使用 `build_workflow.sh` 打包：
   ```bash
   ./build_workflow.sh
   ```

### 打包 workflow

运行打包脚本：
```bash
./build_workflow.sh
```

会生成 `ip138-location.alfredworkflow` 文件。

## 故障排除

### 问题：无法获取内网 IP

- 检查网络连接
- 确认 `ipconfig` 或 `ifconfig` 命令可用
- macOS 系统通常使用 `en0` 接口

### 问题：无法获取外网 IP

- 检查网络连接
- 确认 `curl` 命令可用：`which curl`
- 检查防火墙设置

### 问题：归属地查询失败

- 检查网络连接
- ip-api.com 可能有频率限制（45次/分钟）
- 等待一段时间后重试

### 问题：Workflow 不响应

- 检查 `info.plist` 中的脚本路径是否正确
- 确认 Shell 脚本有执行权限：`chmod +x ip138.sh`
- 查看 Alfred 的调试日志

## 自定义配置

### 修改关键词

在 `info.plist` 中修改 `keyword` 字段：

```xml
<key>keyword</key>
<string>ip</string>  <!-- 改为你想要的关键词 -->
```

### 修改 API 服务

如果需要使用其他 IP 归属地 API，可以修改 `ip138.sh` 中的 `query_ip_location` 函数。

## 与原项目的对比

| 特性 | 原项目 (ip138-alfredworkflow) | 本版本 |
|------|------------------------------|--------|
| 实现语言 | Shell | Shell |
| API 服务 | ip138.com | ip-api.com |
| 数据格式 | HTML（需解析） | JSON（易解析） |
| 稳定性 | 中等 | 较高 |
| 内网 IP | ❌ | ✅ |
| 外网 IP | ✅ | ✅ |
| IPv6 支持 | ❌ | ✅ |

## 参考项目

- [ip138-alfredworkflow](https://github.com/hellosa/ip138-alfredworkflow) - 原参考项目
- [ip-api.com 文档](http://ip-api.com/docs)

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## 更新日志

### v1.0.0
- 初始版本
- 支持内网和外网 IP 查询
- 支持 IPv4 和 IPv6
- 使用 ip-api.com 免费 API

