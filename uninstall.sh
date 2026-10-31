#!/bin/bash
# 卸载：移除适配层并把 Open Design 的设置项清掉。
set -euo pipefail

OD_DATA="${OD_DATA_DIR:-$HOME/Library/Application Support/Open Design/namespaces/release-stable/data}"
CONFIG="$OD_DATA/app-config.json"
TARGET_DIR="$OD_DATA/opencode-adapter"

if [ -f "$CONFIG" ]; then
    STAMP="$(date +%Y%m%d%H%M%S)"
    cp "$CONFIG" "$CONFIG.bak-$STAMP"
    python3 - "$CONFIG" <<'PY'
import json, sys
path = sys.argv[1]
with open(path) as f:
    cfg = json.load(f)
env = cfg.get("agentCliEnv", {}).get("opencode")
if env and "opencode-adapter" in env.get("OPENCODE_BIN", ""):
    env.pop("OPENCODE_BIN", None)
    if not env:
        cfg["agentCliEnv"].pop("opencode", None)
    if not cfg["agentCliEnv"]:
        cfg.pop("agentCliEnv", None)
with open(path, "w") as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
print("已清除 Open Design 中的适配层路径（备份保留）")
PY
fi

rm -rf "$TARGET_DIR"
echo "已删除 $TARGET_DIR"
echo "重启 Open Design 生效。"