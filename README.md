# Open Design × OpenCode 2.x 适配层

让 **Open Design**（0.26.x）能直接驱动 **OpenCode 2.x**，而不用把 OpenCode 降级回 1.x。

## 问题

Open Design 启动 OpenCode 时仍使用 1.x 的参数，2.x 已删除或改名，于是报：

```
ERRORS Unrecognized flag: --dir in command opencode run
ERRORS Unrecognized flag: --pure in command opencode run
```

即使绕过启动，也会出现「找不到模型」「选不到星链/百炼」「改动 OpenCode 配置影响日常使用」等连锁问题。

## 原理

两代 OpenCode 的**事件流格式完全一致**（`run --format json` 输出 `step_start` / `text` / `step_finish`），
所以不需要转换输出，只要把命令行参数翻译过去：

| Open Design 发出的参数 | OpenCode 2.x 的情况 | 适配层处理 |
|---|---|---|
| `--dir <目录>` | 已删除 | 先 `cd` 到该目录再执行 |
| `--pure` | 已删除 | 丢弃 |
| `--dangerously-skip-permissions` | 改名为 `--auto` | 替换 |
| `models --verbose` | 无 `--verbose` | 去掉该参数 |
| `run ...` | 需要后台服务 | 追加 `--standalone` 起私有服务 |

适配层是一个纯 bash 脚本，不常驻、不注入、不改动 OpenCode 本身的任何配置。

## 安装

```sh
git clone <this-repo> && cd opendesign-opencode-adapter
./install.sh
```

安装脚本会：

1. 自动定位 OpenCode 2.x（优先 `OPENCODE_V2_BIN`，其次 `~/.opencode/bin/opencode`、Homebrew 路径）
2. 把适配层复制到 Open Design 数据目录下的 `opencode-adapter/opencode`
3. 备份并写入 Open Design 的 `app-config.json`：`agentCliEnv.opencode.OPENCODE_BIN`
4. 自检：打印版本与模型列表

安装完 **Cmd+Q 彻底退出 Open Design 再打开**，然后正常发消息即可。

## 指定 OpenCode 路径

```sh
OPENCODE_V2_BIN=/path/to/opencode ./install.sh
```

## 卸载

```sh
./uninstall.sh
```

会清掉设置项并删除适配层，`app-config.json` 自动备份。

## 已知限制

- 每次对话会起一个私有 OpenCode 服务（`--standalone`），首句可能慢 1~2 秒。
- Open Design 在运行时保存设置时，会用内存里的旧值覆盖 `app-config.json`；若界面里又把 CLI 路径改回别处，重新执行 `./install.sh` 或重启 App 即可。
- 仅验证于 macOS + Open Design 0.26.x + OpenCode 2.2.x。

## 目录

```
bin/opencode   适配层脚本（核心）
install.sh     安装：落到 Open Design 数据目录并写入设置
uninstall.sh   卸载
```