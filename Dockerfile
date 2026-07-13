# =============================================================================
# RoboSoccer Brain 编译 Docker 镜像
#
# 基于 ROS2 Humble，包含编译 brain 包所需的所有依赖：
#   - ROS2 Humble (rclcpp, tf2, sensor_msgs, geometry_msgs 等)
#   - BehaviorTree.CPP 4.x (从源码编译安装)
#   - Rerun C++ SDK (从 GitHub Release 下载预编译包)
#   - Eigen3 / OpenCV / yaml-cpp / ccache 等系统依赖
#   - Booster Robotics SDK 1.3.6 (从 GitHub Release 下载)
#   - Booster Internal SDK stub (提供 LocoInternalApiId 枚举)
#
# 用法:
#   docker build -t robosoccer-brain-builder .
#   docker run --rm -v $(pwd):/robosoccer robosoccer-brain-builder \
#       bash -c 'source /opt/ros/humble/setup.bash && bash ./scripts/build_brain.sh'
#
# 可选构建参数:
#   --build-arg BTCPP_VERSION=4.6.2       指定 BT.CPP 版本
#   --build-arg RERUN_VERSION=0.19.0      指定 Rerun SDK 版本
#   --build-arg BOOSTER_SDK_URL=<url>     指定 Booster SDK 下载地址
# =============================================================================

FROM ros:humble

# 设置非交互模式，避免 apt 交互
ENV DEBIAN_FRONTEND=noninteractive

# -----------------------------------------------------------------------------
# 1. 安装系统级编译依赖
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    ccache \
    git \
    wget \
    unzip \
    pkg-config \
    libeigen3-dev \
    libopencv-dev \
    libyaml-cpp-dev \
    libzmq3-dev \
    libsqlite3-dev \
    python3-colcon-common-extensions \
    python3-rosdep \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# 2. 安装 ROS2 Humble 依赖包
#    (rclcpp / std_msgs / ament_cmake 等已包含在 ros:humble 基础镜像中)
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-humble-sensor-msgs \
    ros-humble-geometry-msgs \
    ros-humble-tf2 \
    ros-humble-tf2-ros \
    ros-humble-tf2-geometry-msgs \
    ros-humble-rosidl-default-generators \
    ros-humble-rosidl-default-runtime \
    ros-humble-backward-ros \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# 3. 从源码编译安装 BehaviorTree.CPP 4.x
#    项目 CMakeLists.txt 使用 find_package(behaviortree_cpp REQUIRED)，
#    对应 BT.CPP 4.x (ros-humble-behaviortree-cpp-v3 仅提供 3.x 的
#    behaviortree_cpp_v3 cmake 包，不兼容)。
# -----------------------------------------------------------------------------
ARG BTCPP_VERSION=4.6.2
RUN git clone --depth 1 --branch ${BTCPP_VERSION} \
        https://github.com/BehaviorTree/BehaviorTree.CPP.git /tmp/bt_cpp && \
    cd /tmp/bt_cpp && \
    mkdir build && cd build && \
    cmake .. \
        -DBTCPP_EXAMPLES=OFF \
        -DBTCPP_UNIT_TESTS=OFF \
        -DBTCPP_GROOT_INTERFACE=ON \
        -DCMAKE_BUILD_TYPE=Release && \
    make -j"$(nproc)" && \
    make install && \
    ldconfig && \
    rm -rf /tmp/bt_cpp

# -----------------------------------------------------------------------------
# 4. 安装 Rerun C++ SDK
#    项目 CMakeLists.txt 使用 find_package(rerun_sdk REQUIRED)。
#    从 GitHub Release 下载预编译包，解压到 /opt/rerun_sdk。
# -----------------------------------------------------------------------------
ARG RERUN_VERSION=0.19.0
RUN wget -q "https://github.com/rerun-io/rerun/releases/download/${RERUN_VERSION}/rerun_cpp_sdk.zip" \
        -O /tmp/rerun_cpp_sdk.zip && \
    unzip -q /tmp/rerun_cpp_sdk.zip -d /opt/ && \
    rm /tmp/rerun_cpp_sdk.zip

# rerun_cpp_sdk.zip 解压后生成 /opt/rerun_sdk/ 目录，其中包含
# rerun_sdkConfig.cmake。设置 rerun_sdk_DIR 环境变量使 CMake
# 的 find_package(rerun_sdk) 能直接找到该配置文件。
ENV rerun_sdk_DIR="/opt/rerun_sdk"
ENV CMAKE_PREFIX_PATH="/opt:/opt/rerun_sdk:${CMAKE_PREFIX_PATH}"

# -----------------------------------------------------------------------------
# 5. 安装 Booster Robotics SDK
#    下载 SDK 压缩包，解压后将头文件和库安装到系统路径。
#    SDK 提供 booster/robot/b1/b1_api_const.hpp 等公开头文件。
# -----------------------------------------------------------------------------
ARG BOOSTER_SDK_URL=https://github.com/rickey201xrz/static/releases/download/2/sdk_release_1.3.6.zip
RUN wget -q "${BOOSTER_SDK_URL}" -O /tmp/booster_sdk.zip && \
    unzip -q /tmp/booster_sdk.zip -d /tmp/ && \
    cp -r /tmp/sdk_release_*/include/* /usr/local/include/ && \
    cp -r /tmp/sdk_release_*/lib /usr/local/lib/booster_sdk && \
    cp -r /tmp/sdk_release_*/third_party /usr/local/lib/booster_sdk_third_party && \
    rm -rf /tmp/booster_sdk.zip /tmp/sdk_release_*

# 将 Booster SDK 库路径加入链接器搜索路径
RUN echo "/usr/local/lib/booster_sdk" >> /etc/ld.so.conf.d/booster.conf && \
    echo "/usr/local/lib/booster_sdk/x86_64" >> /etc/ld.so.conf.d/booster.conf && \
    ldconfig

# -----------------------------------------------------------------------------
# 6. 安装 Booster Internal SDK stub 头文件
#    brain 包引用 booster_internal/robot/b1/b1_loco_internal_api.hpp，
#    该头文件不在公开 SDK 中。此处提供 stub 定义 LocoInternalApiId 枚举，
#    使 brain 可以编译。实际运行时使用 Jetson 设备上的真实 SDK。
# -----------------------------------------------------------------------------
COPY docker/booster_internal/ /usr/local/include/booster_internal/

# -----------------------------------------------------------------------------
# 7. 设置工作环境
# -----------------------------------------------------------------------------
WORKDIR /robosoccer

# 每次 shell 都自动 source ROS2 环境
RUN echo 'source /opt/ros/humble/setup.bash' >> /etc/bash.bashrc

# 默认命令：进入交互式 shell
CMD ["/bin/bash"]
