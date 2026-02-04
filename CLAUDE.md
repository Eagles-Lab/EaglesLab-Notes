# CLAUDE.md

本文件用于指导 Claude Code（claude.ai/code）在 **EaglesLab-Notes** 仓库中工作时的约定与操作方式。

## 项目概览

EaglesLab-Notes 是一个基于 **GitBook/HonKit** 的技术文档平台，面向 IT 学习者沉淀教学资料。仓库包含多个课程书籍（SRE、Security、Java、Base），并配套自动化构建与部署流水线。

### 当前状态

- **构建系统**：HonKit 6.1.6（从 GitBook 3.2.3 迁移，2026-02-04）
- **Node.js**：v22（从 10.24.1 升级）
- **内容规模**：918 个 Markdown 文件，约 45,000 行
- **分支**：main（生产），zhaohao1004（开发）

---

## 构建命令

### 本地开发

构建并预览某个课程：

```bash
cd SRE  # or Security, Java, Base
honkit build   # Generates _book/ directory
honkit serve    # Starts preview server at http://localhost:4000
```

### CI/CD 构建

自动化构建由 `scripts/build.sh` 负责：

- 支持增量构建（仅构建发生变更的课程）
- 支持通过 `deploy-config.json` 强制构建
- 输出到 `dist/` 目录
- 使用 `honkit build`（HonKit 6.x 不需要 `honkit install`）

本地运行：

```bash
./scripts/build.sh
```

---

## 部署

### 配置文件

`deploy-config.json` 用于控制哪些课程需要构建与部署：

```json
{
  "build": {
    "force": false,
    "ignore_changes": false
  },
  "SRE": {
    "host": "110.42.61.198",
    "path": "/opt/1panel/www/sites/ncloud.eagleslab.com/index/_book",
    "enabled": true
  },
  "Security": {
    "host": "110.42.61.198",
    "path": "/opt/1panel/www/sites/security.eagleslab.com/index/_book",
    "enabled": false
  }
}
```

### 部署脚本

自动化部署由 `scripts/deploy.sh` 负责：

- 通过 `setup_ssh_key()` 配置 SSH key
- 文件传输优先使用 `rsync`，失败时回退到 `tar+scp`
- 仅部署 `enabled: true` 的课程

运行部署：

```bash
# Requires SSH key set in environment
./scripts/deploy.sh
```

### CI/CD 流水线

推送到 main 后，GitHub Actions 会自动触发：

1. 安装 Node.js 22
2. 全局安装 HonKit
3. 全局安装插件（mermaid-hybrid、expandable-chapters、expandable-chapters-small、search-plus、flexible-alerts、intopic-toc）
4. 运行 `scripts/build.sh`
5. 配置 SSH agent
6. 运行 `scripts/deploy.sh`

---

## 项目结构

```
EaglesLab-Notes/
├── .github/workflows/github-actions.yml  # CI/CD 配置 (Node.js 22, HonKit 6.x)
├── scripts/
│   ├── build.sh                         # 构建自动化脚本
│   └── deploy.sh                       # 部署自动化脚本
├── deploy-config.json                  # 构建与部署配置
├── .gitignore                          # 忽略 node_modules/, dist/, _book/
├── SRE/                               # SRE 课程
│   ├── book.json                      # HonKit 配置
│   ├── SUMMARY.md                     # 课程目录
│   ├── Python/, Linux/, Docker/, etc.   # 课程章节
│   └── styles/                        # 自定义样式
├── Security/                          # Security 课程
│   ├── book.json
│   ├── SUMMARY.md
│   └── styles/
├── Java/                              # Java 课程
└── Base/                              # 计算机基础课程
```

---

## 内容结构

### 课程配置（`book.json`）

每个课程目录下都有独立的 `book.json`：

**关键字段：**

```json
{
  "title": "英格网络实验室",
  "language": "zh-hans",
  "plugins": [...],
  "pluginsConfig": {...},
  "styles": {
    "website": "styles/website.css"
  }
}
```

### 目录组织（`SUMMARY.md`）

`SUMMARY.md` 通过 Markdown 链接定义课程结构：

```
# 目录

- [前言](README.md)
- [Python](Python/Python介绍.md)
  - [Python基础](Python/Python基础/Python环境部署.md)
    - [01.Python环境部署](Python/Python基础/Python环境部署.md)
```

### 文档规范

遵循仓库 `README.md` 的规范保持一致性：

- 中英文混排：中文与英文/数字之间加空格
- 标题层级：最多 4 级，前后加空行
- 列表：项目符号/序号后加空格
- 表格：使用 `|` 作为分隔符，`---` 控制对齐
- 图片：使用有意义的命名，格式为 `![alt-text](path)`

---

## 插件系统说明

### HonKit 6.x 第三方插件支持

**重要**：HonKit 6.x 支持第三方插件，但需要**全局安装**：

| GitBook Plugin      | HonKit 6.x 方案 | 安装命令 |
| ------------------- | --------------- | -------- |
| code                | 需要 fork/移植 | - |
| mermaid-gb3         | mermaid-hybrid | `npm install -g honkit-plugin-mermaid-hybrid` |
| toggle-chapters     | expandable-chapters | `npm install -g gitbook-plugin-expandable-chapters` |
| expandable-chapters | expandable-chapters | `npm install -g gitbook-plugin-expandable-chapters` |
| expandable-chapters-small | expandable-chapters-small | `npm install -g gitbook-plugin-expandable-chapters-small` |
| search-pro          | search-plus | `npm install -g honkit-plugin-search-plus` |
| flexible-alerts     | flexible-alerts | `npm install -g gitbook-plugin-flexible-alerts` |
| intopic-toc         | intopic-toc | `npm install -g gitbook-plugin-intopic-toc` |

**为什么需要全局安装？**

HonKit 6.x 的 `PluginResolver` 在初始化时没有传入正确的 `baseDirectory`，导致无法解析本地安装的第三方插件。全局安装后，插件可以通过 Node.js 标准模块解析路径被找到。

**推荐插件：**

```json
{
  "plugins": [
    "search-plus",              // 增强搜索
    "flexible-alerts",          // 灵活告警框
    "intopic-toc",              // 页面内目录
    "mermaid-hybrid",           // Mermaid 流程图支持
    "expandable-chapters",      // 章节折叠
    "expandable-chapters-small" // 章节样式优化
  ]
}
```

**expandable-chapters 配置（实现按需展开章节）：**

```json
{
  "pluginsConfig": {
    "expandable-chapters": {},
    "expandable-chapters-small": {
      "closeOther": true  // 点击展开一个章节时关闭其他章节
    }
  }
}
```

**HonKit 6.x 内置插件：**

- `@honkit/honkit-plugin-highlight` - 代码高亮（默认加载）
- `gitbook-plugin-search` - 搜索功能
- `gitbook-plugin-lunr` - 搜索引擎
- `@honkit/honkit-plugin-fontsettings` - 字体设置
- `theme-default` - 默认主题
- `livereload` - 文件改动自动刷新（serve 时）

### 插件依赖（`package.json`）

HonKit 6.x 不需要在每个课程目录使用 `package.json` 管理插件依赖。项目已删除所有本地 `node_modules` 和 `package.json`，插件通过全局安装：

```bash
# 全局安装推荐插件（CI 已预装）
npm install -g honkit
npm install -g honkit-plugin-mermaid-hybrid
npm install -g gitbook-plugin-expandable-chapters gitbook-plugin-expandable-chapters-small
npm install -g honkit-plugin-search-plus gitbook-plugin-flexible-alerts gitbook-plugin-intopic-toc
```

---

## 测试

### 本地验证

本地验证课程改动：

```bash
cd SRE
honkit serve          # 访问 http://localhost:4000
# 在浏览器中打开并验证
```

### 验证项

- 页面渲染与中文显示
- 导航与链接可用
- 代码块高亮正常
- 搜索功能（大体量书籍可能会被禁用）

### 已知问题

**搜索索引被禁用**：

- 原因：页面/内容过多（会提示 “search index is too big”）
- 影响：搜索框存在但不可用
- 解决：配置 `maxIndexSize` 或使用外部搜索服务

**“plain” 语言警告**：

- 原因：代码块使用了 plain 语言标识
- 影响：构建会告警，但通常不影响成功产物
- 解决：将代码块语言标识从 plain 改为 text 或更具体的语言名称

---

## 常用工作流

### 新增内容

1. 在对应课程目录创建新的 Markdown 文件
2. 在同目录的 `SUMMARY.md` 中加入目录项
3. 本地测试：`honkit build && honkit serve`
4. 提交并推送，触发 CI/CD

### 修复错别字/错误

1. 按仓库 `README.md` 的文档规范编辑 Markdown 文件
2. 本地重建并验证
3. 按约定格式提交：`docs(scope): description`

### 更新配置

1. 修改 `book.json` 或 `deploy-config.json`
2. 本地验证改动
3. 在提交信息中记录变更

### 迁移到其他课程

在课程之间复制结构：

- 复制 `book.json` 并调整标题/作者等信息
- 复制 `SUMMARY.md` 并更新链接
- 复制相关 Markdown 文件和样式文件
- 不需要创建 `package.json`（插件全局安装）

---

## 重要说明

### GitBook → HonKit 迁移（2026-02-04）

项目已从 GitBook 3.2.3 迁移到 HonKit 6.1.6，PR #58 已合并到 main：

- Node.js 从 10.24.1 升级到 22
- 构建脚本更新（移除 `honkit install`，使用 `honkit build`）
- GitHub Actions workflow 更新（Node.js 22 + 全局插件安装）
- 第三方插件支持：通过全局安装实现
- 清理本地 node_modules（删除 23,595 个文件）
- .gitignore 新增 node_modules/ 和 package-lock.json

**当前状态**：
- 内置插件（highlight、search、lunr、fontsettings、theme-default）正常工作
- 第三方插件通过全局安装支持（mermaid-hybrid、toggle-chapters）

**CI 测试记录**：
- 手动触发测试 (Run #21668361719) - Success
- 自动触发测试 (合并到 main) - Success

### 分支策略

- **main**：生产分支，启用分支保护，只能通过 PR 合并
- **zhaohao1004**：开发分支，用于测试与验证
- 开发工作流：在开发分支提交 → 创建 PR → 合并到 main → 自动触发 CI/CD

### URL 格式修复

在 Markdown 中添加链接时，注意 URL 的正确格式：

```markdown
# ✅ 正确

https://www.example.com/path

# ❌ 错误（会导致构建失败）

https://[www.example.com/path](http://www.example.com/path)
```

### 环境变量

- `DEPLOY_SSH_KEY`：用于部署的 GitHub Secret
- `GH_TOKEN`：GitHub API token（保存在 `.env` 中并已 gitignore）
- `GITHUB_SHA`：当前提交的 SHA（仅 CI）
- `BEFORE_SHA`：上一个提交的 SHA（仅 CI）

---

## 速查

### 构建单个课程

```bash
cd <course-name> && honkit build
```

### 构建所有课程（CI 模式）

```bash
./scripts/build.sh
```

### 本地预览

```bash
cd <course-name> && honkit serve
# 访问 http://localhost:4000
```

### 手动部署

```bash
./scripts/deploy.sh
# 仅部署 deploy-config.json 中 enabled: true 的课程
```

### Commit 信息格式

```bash
git commit -m "docs(SRE): update Redis chapter"
git commit -m "fix(build): remove broken link in MySQL.md"
git commit -m "feat(security): add XSS prevention guide"
```

---

## 变更日志

- 2026-02-04：插件系统更新 - 替换为 expandable-chapters
  - 替换 toggle-chapters 为 expandable-chapters
  - 添加 expandable-chapters-small 配合使用
  - 启用 closeOther 选项实现按需展开章节
  - 新增 flexible-alerts、intopic-toc 插件
- 2026-02-04：分支保护规则启用
  - main 分支只能通过 PR 合并
  - 禁止绕过分支保护设置
- 2026-02-04：完成 GitBook → HonKit 6.x 迁移（PR #58 合并）
  - Node.js 升级到 22
  - 删除本地 node_modules（23,595 个文件）
  - 插件改用全局安装
  - CI 测试通过，生产部署成功
- 2026-02-04：添加 workflow_dispatch 支持手动触发 CI
- 2026-02-04：更新 .gitignore 忽略 node_modules 和 package-lock.json
- 2026-02-04：GitHub Actions 添加插件安装步骤
- 2026-02-04：将本文件中文化（保留命令与技术名词原样）
