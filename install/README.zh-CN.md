# 安装或更新 Hipohipo

在当前客户端安装或更新 Hipohipo，复用有效授权或完成登录，并核验当前 MCP 连接。
自行执行可完成的步骤，只向用户解释需要其操作的部分。

## 1. 安装或更新

沿用当前应用的有效配置，保留宿主传入的配置目录和环境，以及已有授权和历史。
保留已确认的现有渠道和作用域，不安装第二份活动副本，不降级较新版本。
普通更新沿用同一条目、来源和作用域，不要先禁用或卸载。
保留现有更新设置。不要重新开启用户已禁用的自动更新，除非用户要求更改。

如果因 Hipohipo 更新通知来到本指南，先完成当前操作，再执行通知给出的状态检查命令，
原样沿用其中的可执行文件和配置目录参数。该命令为当前客户端运行 `update-notice status`。
通知响应已关闭或通知已撤回时，
忽略该通知。重新核验当前生效的安装版本；已达到目标版本时，不要重新安装。
已安装版本不在通知影响范围时同样不要重装；若当前 MCP 仍受影响，只说明必要的加载操作。
核验当前连接的 MCP 后再说明必要的重新加载操作，不要自动关闭或重启宿主。
沿原渠道尝试一次更新；失败时说明原因，不进入自动重试循环。
通知偏好设置见已安装包中的 `SUPPORT.md`。

安装或更新前先确定目标版本。Cursor、Claude Code、Codex 和 WorkBuddy 已有 Git 安装以
[官方稳定发布](https://github.com/Ontos-AI/hipohipo-plugins/releases/latest)为准；
WorkBuddy 国内通路使用下方“WorkBuddy 国内来源”的版本索引。
记录该目标，用于核验已安装包和实际 MCP。原来源无法提供目标版本时，说明差距，
不静默更换来源或固定修订。

正常首装按下方客户端路径使用受支持的 CLI/API 操作，无需先取得完整插件清单。
清单查询失败本身不应阻止明确请求的首次安装。已有安装复用宿主提供的活动安装信息；
安装信息冲突时先澄清，再选择通路。历史缓存本身不代表活动安装。

仅使用受支持的 CLI/API 操作。不要自动操作桌面、浏览器或终端菜单，
或调用未公开的安装接口。需要界面操作时，向用户说明所需步骤。
保留 stdout/stderr 和命令的真实退出码。网络或文件访问受限时，使用宿主提供的正常单次审批。
命令示例仅适用于对应客户端和任务；按实际安装调整路径、参数和 shell 语法。

- Cursor：首次安装使用已校验归档；有 Agent CLI 时先注册官方市场。已有安装按 Local 或原市场渠道更新。
- WorkBuddy：从国内来源取得完整市场并原生安装；已知已有安装时优先使用原生更新，沿用原作用域。
- Claude Code：注册官方市场后安装 Claude Code 条目；已有安装在原作用域更新同一条目。
- Codex：注册官方市场后安装 Codex 条目；已有安装刷新原来源，并按当前客户端支持的流程核验插件更新。

### Cursor 安装

首次安装使用官方稳定版 Cursor 归档。若已有 Cursor Agent CLI（`agent` 或 `cursor-agent`），
先注册官方来源；同一来源已注册时复用：

```sh
agent plugin marketplace add https://github.com/Ontos-AI/hipohipo-plugins
```

这一步仅注册来源，不会安装或启用插件。
CLI 不存在或注册失败时，保留诊断并继续归档安装。
不要仅为注册市场安装或升级宿主 CLI。

从该官方发布下载 `hipohipo-cursor-<version>.tar.gz` 或 `.zip` 及
`SHA256SUMS-<version>.txt`，按完整文件名核验校验和。
要求所有条目位于 `hipohipo/` 内；拒绝绝对路径、目录穿越、符号链接和硬链接。
解压到新的暂存目录。执行前核对 `release.json` 的版本与目标一致，
`sourceCommit` 与公开发布说明的 `Source` 记录一致；无需访问源码仓库。
然后执行包内 `hipohipo install`，Windows 使用 `hipohipo.cmd install`。
此安装器只适用于 Cursor。后续 CLI 调用沿用安装结果返回的安装目录。

仅当用户明确选择市场安装时，用户可以自行手动安装已注册官方市场中的 Hipohipo，
由 Cursor 托管的自动更新取决于 Cursor 的设置及前提条件；安装成功本身不能确认自动更新已开启。
这是归档的替代通路，不要同时执行两条通路。
向用户说明所需操作，不代操作界面。

### Cursor 更新

已有市场安装保留在原市场更新，使用 Cursor 的市场更新功能。
若该操作没有受支持的 CLI/API，向用户说明所需操作，不用归档替换。
市场注册或来源刷新本身不能证明已安装插件及实际响应的 MCP 已更新。
市场设置和排障按需查看 [Cursor 更新说明](https://cursor.com/docs/plugins#keep-plugins-up-to-date)。

需要立即更新已有本地安装时，在安装目录运行已安装的 CLI，或使用其完整路径。
Windows 使用 `hipohipo.cmd`：

```sh
./hipohipo update --host cursor
```

通过现有安装的入口文件按示例运行，不追加登录或配置选项。

若命令不可用或不支持当前安装，按上方安装步骤使用已校验归档升级。
随后查看结果和更新设置：

```sh
./hipohipo update status --host cursor
```

新装的 Local 安装默认在 MCP 或会话启动时自动检查完整插件更新，每天最多一次。
旧版 Local 安装需要先用最新归档升级一次，才能获得自动更新。保留用户已有的更新设置。
以状态结果确认当前更新设置。
更新失败会保留可用旧包和原有授权。需要调整更新设置或回滚时，再查包内 `SUPPORT.md`。
更新后继续完成授权和实际 MCP 核验。

### WorkBuddy

首次安装使用下方“WorkBuddy 国内来源”中的完整市场，按需注册已校验市场，
再安装 `HipoHipo@hipohipo-plugins`。“上传技能”不等于完整插件安装。
已知已有安装时优先使用原生更新，沿用原作用域，不改为在其他作用域重新安装。

已有 Git 市场由原生更新同步远端来源，不替换为 OSS 目录；后续更新遵循宿主的更新设置。
由 OSS 归档注册为本地目录的来源，先按下文刷新原注册目录，再使用原生更新。
宿主不会为本地目录来源获取新版 OSS 归档。

使用可用的原生插件管理 API；否则从 WorkBuddy 自身的安装元数据和包的 `bin` 入口，
定位内置插件管理 CLI（`codebuddy`）与运行时。这是 WorkBuddy 的入口，不是独立 CodeBuddy 产品。

内置 CLI 从每次子进程调用中移除 `SERVER__PORT`、`SERVER__HOST`，
包括 `--help`、市场、安装和更新命令。POSIX 下用
`env -u SERVER__PORT -u SERVER__HOST "$workbuddyCli"` 加上受支持的参数，
`$workbuddyCli` 为已核实的宿主入口；其他 shell 使用等效的子进程环境处理。
保留父进程环境、代理、工作目录、运行时与 bundle 选择参数及活动配置。

### Claude Code

首次安装按需注册官方市场，再安装 Claude Code 条目。示例使用用户作用域；
用户要求其他作用域时相应调整：

```sh
claude plugin marketplace add https://github.com/Ontos-AI/hipohipo-plugins
claude plugin install hipohipo@hipohipo-plugins --scope user
```

已有安装更新同一条目，并显式沿用已核实的原作用域。
下例 `$scope` 指原作用域，不代表应更改它：

```sh
claude plugin update hipohipo@hipohipo-plugins --scope "$scope"
```

通过本指南的 GitHub 路径添加市场时，自动更新默认关闭。检查实际设置，不假定默认值仍然适用；
通过 claude.ai 添加的市场默认行为不同。保留用户偏好，上方命令用于立即更新。
按需设置自动更新时查看 [Claude Code 更新说明](https://code.claude.com/docs/en/discover-plugins#keep-plugins-updated)。
若设置需要界面操作，向用户说明。

读取真实更新结果和已安装版本，再按第 3 步使用当前客户端支持的加载方式。
安装成功本身不能证明当前 MCP 已加载更新。

### Codex

使用支持原生插件的 Codex 客户端。首次安装按需注册官方市场，再安装 Codex 条目：

```sh
codex plugin marketplace add https://github.com/Ontos-AI/hipohipo-plugins
codex plugin add hipohipo@hipohipo-plugins
```

已有安装仅刷新其原有的官方来源：

```sh
codex plugin marketplace upgrade hipohipo-plugins
```

随后核对实际已安装的插件版本；来源刷新成功不代表插件已更新。
已安装副本仍旧时，使用当前客户端公开支持的插件更新操作，沿用同一条目、来源和配置。
可用操作以当前客户端帮助为准，不假设它支持其他客户端的更新命令。
需要用户才能完成的操作时，说明所需步骤，保持更新未确认。
继续按第 3 步核验实际 MCP；桌面客户端已有对话尚未加载新版时也如此。

后续更新由 Codex 管理，遵循其当前设置。Hipohipo 不会另加更新器，也不承诺固定更新周期。
保留用户设置；需要更新时执行上方刷新和核验流程。

### 确认安装结果

将已安装包版本与目标比较，并从原生结果或可用包元数据核验来源、作用域和启用状态。
不强制某个清单查询命令。安装成功后继续完成登录和 MCP 核验。

只有实际报错或缺少必要信息阻碍下一步时，再查 CLI 帮助或已核验包内的 `SUPPORT.md`。
没有受支持的恢复方式时，报告阻碍原因，不修改宿主私有状态。

## 2. 复用授权或登录

通过可用状态结果复用有效授权，包括只读授权。`auth.login` 未暴露不代表 MCP 未加载或用户未登录。
需要登录时，使用当前安装暴露的 `auth.login` 工具。
若该登录工具未暴露，即使其他 MCP 工具可用，也使用同一安装的 CLI，沿用同一客户端和有效配置。
拒绝、取消或权限限制不属于工具缺失，不切换 CLI 绕过。例如在安装目录执行：

```sh
./hipohipo auth-status --host "$targetHost"
```

仅在需要登录时执行：

```sh
./hipohipo login --host "$targetHost"
```

`$targetHost` 是已确认的客户端：`cursor`、`workbuddy`、`codex` 或 `claude-code`。
Windows 使用已安装的 `.cmd` 入口。保留配置环境和显式覆盖，引用路径并分别传递参数。
缺少参数时查看 `./hipohipo --help`。需要进一步诊断时，使用
`./hipohipo status --host "$targetHost"`，沿用同一客户端和配置。

保留已有授权和历史，不为解决安装或加载问题而重置它们。不查看凭据。

提前告知浏览器授权，返回浏览器或设备链接、公开用户码时立即展示。等待当前登录，
按 `nextAction` 继续，批准后续接同一流程；不并发登录。拒绝、取消或终止性失败后不自动重试。
恢复与超时细节见 `SUPPORT.md`。

## 3. 加载并核验

登录完成或复用授权后，调用当前会话实际暴露的 Hipohipo MCP `auth.status` 工具，
工具名以该客户端暴露的名称为准。将响应的 `serverVersion` 与第 1 步选定的目标版本比较，
并确认授权有效。已有更高版本可以保留。CLI 状态、安装元数据或 enabled 设置，
均不足以证明当前 MCP 已加载目标版本。

若工具不可用或仍运行旧版，可对工具发现或状态核验做少量重试，给宿主完成加载的机会。
继续未完成的准备或登录动作；重试本身不证明加载成功。仍未加载时使用以下客户端流程：

- Cursor：新版仍未加载时，提示用户正常退出并重新打开应用；不要代操作界面。
- WorkBuddy：待宿主确认 MCP 就绪后，优先新开对话核验。若 MCP 无法启动，
  或新对话仍无工具或运行旧版，再正常退出再打开应用。
- Claude Code：使用已安装版本明确支持的重新加载操作；否则在新的 Claude Code 会话中继续核验实际连接。
- Codex：使用当前客户端支持的插件加载流程。已有对话保留旧连接时，在新的对话或会话中核验实际 MCP 响应。

仅在 MCP 确实被禁用时启用。保留已完成的登录，不为加载而重复安装或登录。
一次状态足够时直接复用。仅用必要的状态响应核验，不调用业务工具或上传用户内容；
尚未验证时不把加载视为完成。

最终回复使用当前对话语言，通常为 1–3 句话。连接核验完成时确认可以使用，简述可查找资料、
回顾记忆，并在当前授权范围内使用相关上下文，不列示例问题。
需要新开对话或正常重开应用时，说明已完成的部分和加载仍未确认，仅给出所需加载步骤；
不承诺重启后一定就绪，不要求用户重新粘贴指令、核验连接或反馈结果。
实际失败时简述原因和下一步，不宣称已经可用。
技术细节（版本、路径、校验和及诊断 ID）保留在已有工具输出中，
仅在用户要求或支持排障需要时展示。

## WorkBuddy 国内来源

本通路用于首次安装或已有 OSS 本地目录来源；已有 Git 市场沿用上方 Git 更新通路。

读取 `https://ai-bid-server.oss-cn-beijing.aliyuncs.com/hipohipo/releases/latest.json`，
要求 `schemaVersion: 1`、合法稳定版本、完整 `sourceCommit`，包地址位于同一 OSS
主机的 `hipohipo/releases/<version>/` 下。将该版本作为目标，下载 `marketplace.url`，
核对字节数与 SHA256，不符即停止。解压前确保所有条目位于 `hipohipo-plugin-marketplace/` 内，
不含绝对路径、`..`、符号链接或硬链接。核对 `release.json` 版本、来源提交与索引一致，
确认 `.codebuddy-plugin/marketplace.json` 及 `plugins/hipohipo-workbuddy/` 存在。
使用当前可用工具，不要求用户安装 Go、Node.js 或 Python，也无需转向 GitHub 查询。

把完整市场保存在用户可写的持久位置，与宿主管理的插件缓存分开。
首次安装在活动配置根下使用新目录，保留其他 profile 的市场来源。

已有本地目录来源更新时，先暂存并核验新的完整市场，再更新原先注册的来源目录。
先确认它属于当前配置的官方来源、由用户管理，且不是 Git 工作目录或宿主缓存。
保留旧来源备份直到原生更新成功；仅将新版下载到另一暂存目录不会更新已安装插件。
不修改注册路径、凭据或历史。来源替换失败时先恢复备份；宿主命令失败时先核对原生状态。

然后刷新市场并在原作用域 `$scope` 更新插件。下列参数沿用上方 WorkBuddy CLI 的调用方式：

```sh
plugin marketplace update hipohipo-plugins
plugin update HipoHipo@hipohipo-plugins --scope "$scope"
```

宿主不会自动下载后续 OSS 归档；需要新版时再次执行本指南，下载、核验并应用更新。
不要把本地来源安装描述为自动更新。

首次安装按需注册市场（`plugin marketplace add <完整市场目录>`），
再用 `plugin install HipoHipo@hipohipo-plugins --scope user`（或用户要求的作用域）安装。
不要手动删锁、改私有注册表、静默删除市场、启用重复插件、关闭安全保护或绕过宿主保护。
报错后先核对实际安装状态再决定是否重试；恢复细节见 `SUPPORT.md`。
