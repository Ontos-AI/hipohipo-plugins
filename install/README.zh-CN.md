# 安装 Hipohipo

在当前客户端安装或更新 `hipohipo` 至最新稳定非草稿版本，完成登录并核验当前 MCP。
自行执行可完成的步骤，只向用户解释需要其操作的部分。按客户端实际能力调整命令示例；
测试机版本、用户名和绝对路径都不是用户安装前提。

## 1. 安装或更新

复用已确认的客户端、环境、活动配置、渠道和作用域。确认安装路径与目标版本后，
执行必要的原生安装或更新；可靠核实的目标安装可复用，不降级较新版本。
按需要注册或刷新市场，下载或列表查询不等于安装。缺少信息或报错时再查帮助或
已核验包内的 `SUPPORT.md`。

保留可诊断的 stdout/stderr 和安装命令的真实退出码。允许摘要或过滤显示，
前提是原始诊断与结果仍可查；不能只凭过滤器退出码判断安装成功。

- Cursor：沿用已有市场渠道。本地安装下载稳定版 Cursor 包，按完整文件名匹配
  `SHA256SUMS-<version>.txt` 核验，解压后执行包内 `hipohipo install`，
  Windows 使用 `hipohipo.cmd install`；此安装器只适用于 Cursor。
- WorkBuddy：优先原生第三方插件管理入口，否则从当前应用安装元数据和包的 `bin`
  入口定位内置 CLI 与运行时，使用下面的国内来源。
- Claude Code、Codex：使用原生插件入口或当前安装的 CLI，市场为
  `https://github.com/Ontos-AI/hipohipo-plugins`，按实际能力安装或更新。
  `claude plugin install`、`codex plugin add` 等只是示例，不是固定清单。

主清单 `SHA256SUMS-<version>.txt` 覆盖八个客户端归档。从原生返回、可用清单或
返回位置的包元数据核验安装版本、来源、作用域和启用状态，不强制某个查询命令。

### WorkBuddy 国内来源

**独立 CLI 子进程从第一次调用起移除 `SERVER__PORT`、`SERVER__HOST`。**
它们可能使 CLI 继承宿主服务模式而拒绝命令。仅修改子进程，保留父进程环境、代理、
工作目录、运行时参数与活动配置。内置 `codebuddy` 入口不等于独立 CodeBuddy 产品。

读取 `https://ai-bid-server.oss-cn-beijing.aliyuncs.com/hipohipo/releases/latest.json`，
要求 `schemaVersion: 1`、合法稳定版本、完整 `sourceCommit`，包地址位于同一 OSS
主机的 `hipohipo/releases/<version>/` 下。下载 `marketplace.url`，核对字节数与
SHA256，不符即停止。解压前确保所有条目位于 `hipohipo-plugin-marketplace/` 内，
不含绝对路径、`..`、符号链接或硬链接。核对 `release.json` 版本、来源提交与索引
一致，确认 `.codebuddy-plugin/marketplace.json` 及 `plugins/hipohipo-workbuddy/`
存在。使用当前可用工具，不要求用户安装 Go、Node.js 或 Python，也无需转向 GitHub 查询。

把完整市场保存在用户可写的持久位置，与宿主管理的插件缓存分开。更新先暂存并核验，
保留旧来源、授权和采集状态直到原生更新成功。按需要使用受支持的市场注册与安装/更新
入口，例如 `plugin marketplace add <完整市场目录>` 和
`plugin install hipohipo@hipohipo-plugins --scope user`，已有安装可调用原生更新命令。
“上传技能”不等于完整插件安装。

不要手动删锁、改私有注册表、静默删除市场、启用重复插件、关闭安全保护或绕过宿主保护。
报错后先核对实际安装状态再决定是否重试；恢复细节见 `SUPPORT.md`。

## 2. 复用授权或登录

复用有效授权，包括只读授权。否则使用当前安装的认证工具，MCP 尚未加载时也可使用
已安装 CLI，例如 `./hipohipo login --host "$targetHost"`，客户端身份为已确认的
`cursor`、`workbuddy`、`codex` 或 `claude-code`，Windows 使用包内 `.cmd` 入口。
保留配置环境和显式覆盖，引用路径并分别传递参数。

**不要查找或猜测 `--state-dir`。** 插件自行定位或创建持久实例，健康旧实例原地保留。
旧状态缺少字段不代表应丢弃有效授权。不查看凭据。

提前告知浏览器授权，返回浏览器或设备链接、公开用户码时立即展示。等待当前登录，
按 `nextAction` 继续，批准后续接同一流程；不并发登录。拒绝、取消或终止性失败后不自动重试。
恢复与超时细节见 `SUPPORT.md`；新登录不代表历史数据已恢复。

## 3. 加载并核验

登录完成或复用有效授权后，核验当前 MCP 目标版本。若工具不可用（包括首次安装后）
或仍运行旧版，先等待 **30 秒**，再重新发现工具并核验。已加载则跳过等待；仅等待一次。
等待本身不证明加载成功，也不代替未完成的登录或准备动作。仍未加载时继续以下操作：

- WorkBuddy：请用户正常退出再打开应用，回原安装对话核验；新对话也可能沿用旧共享连接。
- Cursor：本地插件可使用官方 `Developer: Reload Window`，前提是当前界面确有入口，
  否则正常重启 Cursor。
- Claude Code、Codex：按当前客户端的加载说明继续；当前会话无法加载新版时，
  在新的客户端会话中续验。

仅在 MCP 确实被禁用时启用。安装器给出的命令提示不能单独证明当前客户端支持它。
需要其他对话或会话时，给用户简短的续验请求，附上已安装目标版本和已完成步骤。
保留已完成的登录，不为加载而重复安装、登录或再次等待。

以当前 MCP 的 `serverVersion` 和授权结果确认就绪；CLI 状态或 enabled 均不足以
单独证明 MCP 已加载。一次状态足够时直接复用。报告安装、登录、加载和剩余用户动作，
核验前加载仍标为待完成，失败保留诊断 ID。完成后停止，不额外执行业务搜索、上传、
Skills/Hooks 或采集测试。
