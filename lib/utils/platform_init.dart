import 'platform_init_stub.dart'
    if (dart.library.js_interop) 'platform_init_web.dart';

/// 跨平台插件确定性初始化守卫（抹平 Web/PWA 与移动端环境差异）
void ensurePlatformPluginsInitialized() {
  initPlatformPlugins();
}
