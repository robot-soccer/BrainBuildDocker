# BrainBuildDocker

用于编译 [RoboSoccer](https://github.com/robot-soccer/robosoccer) 项目 `brain` 包的 Docker 镜像。

## 镜像内容

| 依赖 | 版本 | 来源 |
|------|------|------|
| ROS2 | Humble | `ros:humble` 基础镜像 |
| BehaviorTree.CPP | 4.6.2 | 源码编译 |
| Rerun C++ SDK | 0.19.0 | GitHub Release 预编译包 |
| Booster Robotics SDK | 1.3.6 | GitHub Release |
| Eigen3 / OpenCV / yaml-cpp | 系统包 | apt |

## 使用方法

### 拉取预构建镜像

```bash
docker pull ghcr.io/robot-soccer/brain-build:latest
```

### 在容器内编译 brain

```bash
cd /path/to/robosoccer
docker run --rm -v "$(pwd):/robosoccer" ghcr.io/robot-soccer/brain-build:latest \
    bash -c 'source /opt/ros/humble/setup.bash && bash ./scripts/build_brain.sh'
```

### 本地构建镜像

```bash
git clone https://github.com/robot-soccer/BrainBuildDocker.git
cd BrainBuildDocker
docker build -t robosoccer-brain-builder .
```

### 自定义版本

```bash
docker build \
    --build-arg BTCPP_VERSION=4.6.2 \
    --build-arg RERUN_VERSION=0.19.0 \
    --build-arg BOOSTER_SDK_URL=https://github.com/rickey201xrz/static/releases/download/2/sdk_release_1.3.6.zip \
    -t robosoccer-brain-builder .
```

## GitHub Actions

推送到 `main` 分支或手动触发 workflow 会自动构建镜像并推送到 GitHub Container Registry:

```
ghcr.io/robot-soccer/brain-build:latest
ghcr.io/robot-soccer/brain-build:<branch>
ghcr.io/robot-soccer/brain-build:sha-<short-sha>
```

## 注意事项

- Booster Internal SDK (`b1_loco_internal_api.hpp`) 不在公开 SDK 中，本仓库提供 stub 头文件用于编译。
- 编译产物运行时需使用 Jetson 设备上的完整 SDK。
- Apple Silicon 用户如遇架构问题，可使用 `--platform linux/amd64` 构建。
