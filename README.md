# QLean

> **QLean / 轻盘**：QuarkCloudDrive 3.23.2 的本地精简补丁集。  
> 只保留常用功能，所有改动可从原版 asar 重建。

项目根目录就是 `QLean/`，下面的命令默认都在这个目录执行。

## 目录

```text
QLean/
├─ build-current.js     # 从原版重建当前版，并校验 SHA256
├─ app.asar-3.23.2      # 原版输入（默认源，同目录）
├─ manifest.json        # 原版/当前版哈希、6 个改动文件、功能清单
├─ files/               # 6 个最终 patched 文件
│  ├─ main/main.js
│  └─ renderer/
│     ├─ floating-window-list.js
│     ├─ index.html
│     ├─ index.js
│     ├─ modal-preference.html
│     └─ modal-preference.js
└─ out/                 # 构建输出（运行后生成，不默认保留）
```

> `files/` 目录省略了 asar 内的 `dist/` 前缀；`manifest.json` 仍记录 asar 路径 `dist/main/main.js`、`dist/renderer/...`，构建脚本会自动映射。

## 一条命令构建

在 `QLean/` 目录下：

```powershell
node .\build-current.js
```

默认：

- 输入：同目录 `app.asar-3.23.2`
- 输出：`.\out\app.asar`

脚本会：

1. 校验输入 asar 必须是原版（SHA256 匹配）；
2. 用 `files/` 下 6 个最终文件替换；
3. 重算全部 offset / size / SHA256 integrity；
4. 校验输出 SHA256 必须为当前版哈希，否则报错退出。

成功输出：

```text
outputSize: 132227236
outputHash: 7abfa4f8…41e62a9
```

## 两个唯一版本

| 版本 | 文件 | 大小 | SHA256 |
|---|---|---|---|
| 原版 | `QLean/app.asar-3.23.2` | 132,724,203 B | `8489F979…F50CB0` |
| 当前版 | `resources/app.asar` | 132,227,236 B | `7ABFA4F8…41E62A9` |

不再保留任何中间版本 asar。

## 应用补丁

构建完成后，先退出夸克网盘，然后**手动**将：

```text
QLean\out\app.asar
```

替换到：

```text
D:\QuarkCloudDrive\app-3.23.2\resources\app.asar
```

替换后再启动客户端。不要同时保留旧文件。

## 回滚原版

先退出夸克网盘，然后**手动**将：

```text
QLean\app.asar-3.23.2
```

替换回：

```text
D:\QuarkCloudDrive\app-3.23.2\resources\app.asar
```

替换后再启动客户端。

## 安装脚本

```text
QLean\installer\QuarkCloudDrive.iss
```

打包前确保存在：

```text
QLean\{app}\
QLean\{userappdata}\quark-cloud-drive\
```

编译：

```powershell
& "D:\Inno Setup 6.6.1\ISCC.exe" "QLean\installer\QuarkCloudDrive.iss"
```

产物默认在：

```text
QLean\installer\Output\QuarkCloudDrive-Setup-3.23.2-x64.exe
```

## 当前功能

- 左侧导航仅保留首页/传输/快传，隐藏备份/工具箱并加路由守卫
- 恢复窗口大小/位置记忆
- 设置页移除备份设置/客服咨询/安全公告/插件管理；禁用更新检查并预隐藏更新信息
- 首页常用工具只保留回收站；移除删除弹窗/回收站续费链接、Office 备份入口、手机图标
- 移除文件恢复服务入口与设置项，深链重定向
- 移除隐私设置中的自动备份记录开关
- 抑制极速下载试用通知
- 删除下载页下载速度/体验券整条组件
- 隐藏上传/云收藏升级提示、右上角 VIP 推广、悬停“立即加速”，恢复设置按钮原位置
- 搜索只保留网盘搜索
- 删除悬浮球文件嗅探 tab 与托盘“本地文件嗅探”菜单
- 移除首次启动的网页书签/全网搜索引导弹窗
- 移除资源管理器文件夹右键“自动备份该文件夹”
- 删除本地右键菜单五项转换/备份设置
- 删除云解压工具栏按钮和悬浮菜单云解压图标
- 新增“快传下载”一键按钮和“默认此路径为快传下载路径”开关，复用默认下载目录

## 注意

- 这是对打包后 `app.asar` 的非官方补丁，客户端更新会覆盖。
- 不修改 `app.asar.unpacked` 内的原生模块。
- 当前客户端不计划更新；如换新版本，需要以新版本原版为基础重新生成这 6 个文件。
- 补丁不涉及登录、传输、限速、会员校验逻辑。
