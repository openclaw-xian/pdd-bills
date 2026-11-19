# 安装（Windows）

## 方式一：一键安装 / 目录联接（推荐）

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

默认把本目录作为 junction 接到 `%USERPROFILE%\.agents\skills\pdd-bills`，全机只有一份真实文件，改源码即生效。

可选参数：

| 参数 | 作用 |
|---|---|
| `-Copy` | 复制安装（不建 junction） |
| `-Target "D:\.agents\skills\pdd-bills"` | 自定义安装位置 |
| `-Force` | 目标已存在时，先改名成 `.bak-<时间戳>` 再安装 |

脚本会检查 `SKILL.md / batch-run.mjs / worker-export.mjs` 是否齐全，并提示 Node / ego-browser 是否可用；**不会删除或覆盖任何文件**（`-Force` 只是改名备份）。

## 方式二：手动复制

```powershell
mkdir -Force "$env:USERPROFILE\.agents\skills"
Copy-Item . "$env:USERPROFILE\.agents\skills\pdd-bills" -Recurse
```

## 安装完成后

1. 准备账单根目录（默认 `D:/对账账单`，非 C 盘；或配置 `root`）。
2. 店铺清单 `_stores.json` 可省略：首次运行 / doctor 会自动扫描 ego profiles 生成；也可只写店铺名。
3. 自检（只读、不导出）：

   ```powershell
   node "$env:USERPROFILE\.agents\skills\pdd-bills\batch-run.mjs" .\doctor.json
   ```

   `doctor.json`：

   ```json
   { "doctor": true, "from": "2026-08-01", "to": "2026-08-31" }
   ```

4. 正式跑：

   ```powershell
   node "$env:USERPROFILE\.agents\skills\pdd-bills\batch-run.mjs" .\batch-config.json
   ```

详细配置见 `SKILL.md`，实现与踩坑见 `references/`。
