import 'package:image_picker_for_web/image_picker_for_web.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// Web 平台（浏览器、PWA）专属插件确定性初始化与绑定
void initPlatformPlugins() {
  // 确保在 Web 环境下 ImagePicker 始终绑定为 Web 插件实现，彻底杜绝 MissingPluginException
  if (ImagePickerPlatform.instance is! ImagePickerPlugin) {
    ImagePickerPlatform.instance = ImagePickerPlugin();
  }
}
