#!/bin/bash
# 安装：把适配层挂到 Open Design 的 OPENCODE_BIN 上，让它调用 OpenCode 2.x。
#
#   ./install.sh              # 默认安装
#   OPENCODE_V2_BIN=/path/to/opencode ./install.sh
#
# Open Design 运行时会把设置在内存里的旧值写回配置文件，所以安装前建议先用
# Cmd+Q 彻底退出 Open Design；否则装完还要重启一次才会生效。

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OD_DATA="${OD_DATA_DIR:-$HOME/Library/Application Support/Open Design/namespaces/release-stable/data}"
CONFIG="$OD_DATA/app-config.json"
TARGET_DIR="$OD_DATA/opencode-adapter"
TARGET="$TARGET_DIR/opencode"

echo "==> Open Design 数据目录: $OD_DATA"
[ -f "$CONFIG" ] || { echo "找不到 $CONFIG，Open Design 可能没装过或路径不同" >&2; exit 1; }

# 1) 检测 OpenCode 2.x
for candidate in "${OPENCODE_V2_BIN:-}" "$HOME/.opencode/bin/opencode" /opt/homebrew/bin/opencode /usr/local/bin/opencode; do
    [ -n "$candidate" ] && [ -x "$candidate" ] && V2="$candidate" && break
done
[ -n "${V2:-}" ] || { echo "未找到 OpenCode 2.x，可用 OPENCODE_V2_BIN 指定" >&2; exit 1; }
VERSION="$("$V2" --version 2>/dev/null || true)"
echo "==> 使用 OpenCode: $V2 ($VERSION)"
case "$VERSION" in
    *1.*) echo "警告: 该版本是 1.x，适配层主要针对 2.x" >&2 ;;
esac

# 2) 安装适配脚本
mkdir -p "$TARGET_DIR"
cp "$ROOT/bin/opencode" "$TARGET"
chmod +x "$TARGET"
echo "==> 已安装: $TARGET"

# 3) 写入 Open Design 设置（先备份）
STAMP="$(date +%Y%m%d%H%M%S)"
cp "$CONFIG" "$CONFIG.bak-$STAMP"
echo "==> 已备份设置: $CONFIG.bak-$STAMP"

python3 - "$CONFIG" "$TARGET" <<'PY'
import json, sys
path, target = sys.argv[1], sys.argv[2]
with open(path) as f:
    cfg = json.load(f)
cfg.setdefault("agentCliEnv", {}).setdefault("opencode", {})["OPENCODE_BIN"] = target
with open(path, "w") as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
print("==> agentCliEnv.opencode.OPENCODE_BIN =", target)
PY

# 4) 自检
echo "==> 自检"
"$TARGET" --version
echo "   模型（星链/百炼/免费）:"
"$TARGET" models 2>/dev/null | sed 's/^/     /' | head -20

cat <<'EOF'

完成。接下来：
  1. Cmd+Q 彻底退出 Open Design 再打开（让它读到新路径）
  2. 在 App 里发一条消息验证

卸载：./uninstall.sh
EOF