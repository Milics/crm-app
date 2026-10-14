{{flutter_js}}
{{flutter_build_config}}

// 🛡️ 极速直载启动器：
// 彻底跳过不稳定的 ServiceWorker 拦截，直载核心渲染引擎与业务脚本，彻底根治 iOS Safari 与 PWA 挂起问题
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  }
}).catch(function(err) {
  console.error("Flutter loader error:", err);
  if (window.showFatalError) {
    window.showFatalError("引擎加载失败: " + (err ? (err.message || err) : "未知错误"));
  }
});
