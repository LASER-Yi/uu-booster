# UU Booster for OpenWRT

UU Game Booster OpenWRT 管理工具 - 非官方实现

## 项目简介

本项目提供 UU 游戏加速器在 OpenWRT 路由器上的便捷管理方案。通过一个简单的安装包，即可自动下载和配置官方 UU 插件。

## 主要特性

- **便捷管理** - 一键安装、启动、停止、更新 UU 插件
- **自动架构检测** - 自动识别路由器架构并下载对应的官方二进制文件
- **多架构支持** - 单一安装包支持 aarch64、arm、mipsel、x86_64
- **安全验证** - MD5 校验确保下载文件完整性
- **故障恢复** - 主备 URL 自动切换，下载失败自动重试
- **服务管理** - 集成 OpenWRT procd 服务管理
- **防火墙配置** - 自动配置必要的防火墙规则
- ⚠️ **测试说明** - 仅在 OpenWRT 24.10.1 上测试通过，其他版本可能需要适配

## 支持的设备

- **aarch64**: 树莓派 4、瑞芯微板子、ARM64 路由器
- **arm**: 树莓派 2/3、各种 ARMv7 板子
- **mipsel**: MT7620/7621、联发科路由器
- **x86_64**: x86 路由器、运行 OpenWRT 的 PC

## 快速安装

### 方法 1：LuCI 网页界面安装（最简单）

1. 登录 OpenWRT 路由器的 LuCI 网页界面（通常是 http://192.168.1.1）
2. 进入 "系统" → "软件包"
3. 点击 "上传软件包"
4. 选择下载的 `uu-booster_*.ipk` 文件并上传
5. 点击 "安装"
6. 安装完成后，服务会自动启动

### 方法 2：从 GitHub Releases 安装（推荐）

⚠️ **注意**：本项目仅在 OpenWRT 24.10.1 上测试通过。如果您在其他版本遇到问题，请提交 Issue。

1. 下载对应架构的安装包
2. 上传到 OpenWRT 路由器
3. 通过 SSH 连接到路由器并安装：

```bash
opkg install uu-booster_*.ipk
```

安装包会自动：
- 检测路由器架构
- 从网易官方服务器下载对应的二进制文件
- 配置防火墙规则
- 启动服务

## 快速开始

安装后，使用简单的命令管理 UU 加速器：

```bash
# 查看服务状态
uu status

# 检查更新
uu check

# 更新到最新版本
uu update

# 重启服务
uu restart
```

## 文档

- [安装指南](docs/user/INSTALLATION.md) - 详细安装说明
- [使用指南](docs/user/USAGE.md) - 命令行用法和配置
- [故障排除](docs/user/TROUBLESHOOTING.md) - 常见问题和解决方案

## 参考项目

- [ttc0419/uuplugin](https://github.com/ttc0419/uuplugin) - 参考实现
- [luci-app-uugamebooster](https://github.com/coolsnowwolf/luci/tree/master/applications/luci-app-uugamebooster) - LuCI 网页界面

## AI 使用说明

本项目的大部分代码由 AI 辅助编写和生成，包括：
- OpenWRT 包管理脚本
- GitHub Actions 工作流配置
- 文档编写和维护
- 测试脚本和工具

虽然代码经过人工审核，但可能存在未发现的问题。如果您在使用过程中遇到任何异常行为，请：
1. 检查 [故障排除文档](docs/user/TROUBLESHOOTING.md)
2. 在 GitHub 上 [提交 Issue](https://github.com/LASER-Yi/uu-booster/issues)
3. 提供详细的错误信息和系统环境

您的反馈将帮助改进这个项目！

## 许可证

[License](LICENSE)
