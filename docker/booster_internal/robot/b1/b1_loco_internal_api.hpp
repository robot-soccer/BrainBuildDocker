#ifndef BOOSTER_INTERNAL_ROBOT_B1_B1_LOCO_INTERNAL_API_HPP
#define BOOSTER_INTERNAL_ROBOT_B1_B1_LOCO_INTERNAL_API_HPP

/**
 * Booster Robotics Internal SDK - B1 Loco Internal API
 *
 * 此文件为 stub 头文件，提供 brain 包编译所需的内部 API ID 枚举定义。
 * 公开 SDK (sdk_release_1.3.6) 不包含此头文件。
 * 实际运行时使用 Jetson 设备上安装的完整内部 SDK。
 *
 * 枚举值基于内部 SDK 1.3.6 版本，与 robot_client.cpp 中的
 * constexpr 值一致 (kRLKickBall=100011, kRLFancyKickBall=100012)。
 */

namespace booster_internal {
namespace robot {
namespace b1 {

enum class LocoInternalApiId {
    kEnableRobocupWalkMode = 100010,
    kRLKickBall            = 100011,
    kRLFancyKickBall       = 100012,
};

}  // namespace b1
}  // namespace robot
}  // namespace booster_internal

#endif  // BOOSTER_INTERNAL_ROBOT_B1_B1_LOCO_INTERNAL_API_HPP
