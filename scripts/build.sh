#!/bin/bash
set -e

# 读取配置文件
CONFIG_FILE="deploy-config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file $CONFIG_FILE not found!"
    exit 1
fi

# 获取构建配置
FORCE_BUILD=$(jq -r '.build.force' "$CONFIG_FILE")
IGNORE_CHANGES=$(jq -r '.build.ignore_changes' "$CONFIG_FILE")

# 清理旧构建产物
rm -rf dist
mkdir -p dist

# 获取变更的目录
get_changed_directories(){
    local changed_dirs

    # 如果配置了强制构建，返回所有包含 SUMMARY.md 的目录
    if [ "$FORCE_BUILD" = "true" ]; then
        echo "Force build enabled, building all courses..." >&2
        changed_dirs=$(find . -name "SUMMARY.md" -exec dirname {} \; | cut -d'/' -f2)
        echo "$changed_dirs"
        return
    fi

    # 如果配置了忽略变更，也返回所有目录
    if [ "$IGNORE_CHANGES" = "true" ]; then
        echo "Ignore changes enabled, building all courses..." >&2
        changed_dirs=$(find . -name "SUMMARY.md" -exec dirname {} \; | cut -d'/' -f2)
        echo "$changed_dirs"
        return
    fi

    # 检查是否在 CI 环境中
    if [ -n "$GITHUB_SHA" ]; then
        echo "In CI environment, checking changed files..." >&2
        changed_dirs=$(git diff --name-only "$BEFORE_SHA" "$GITHUB_SHA" | cut -d'/' -f1 | cut -d'"' -f2 | sort -u)
    else
        echo "In local environment, building all courses with SUMMARY.md..." >&2
        changed_dirs=$(find . -name "SUMMARY.md" -exec dirname {} \; | cut -d'/' -f2)
    fi
    echo "$changed_dirs"
}


# 构建指定目录的文档
build_course() {
    local course=$1
    echo "Building $course..."
    if [ -d "$course" ] && [ -f "$course/SUMMARY.md" ]; then
        (
            cd "$course"
            honkit build
            mkdir -p ../dist/"$course"
            mv _book/* ../dist/"$course"/
            rm -rf _book
        )
    fi
}

# 获取需要构建的目录列表
changed_courses=$(get_changed_directories)

# 构建每个变更的目录
for course in $changed_courses; do
    if [ -n "$course" ]; then
        build_course "$course"
        # echo "build_course $course"
    fi
done

# 检查是否有构建成功的目录
if [ -z "$(ls -A dist)" ]; then
    echo "Warning: No courses were built!"
    exit 1
fi
