{{flutter_js}}
{{flutter_build_config}}

// 🛡️ iOS Standalone PWA 极速引导盾：
// 1. 在 iOS PWA（添加到主屏幕）环境下，ServiceWorker 极易受 WebKit 挂起影响导致资源请求无限期 pending。
// 2. 将 serviceWorker 超时时间设置为 1500ms（1.5秒），超时立即跳过并回退到极速 HTTP/磁盘缓存加载。
// 3. 拦截任何 ServiceWorker 注册异常，确保永远不阻塞 Flutter 主入口 main.dart.js 的注入与执行。
var _isIosStandalone = (window.navigator.standalone === true) ||
  (window.matchMedia && window.matchMedia('(display-mode: standalone)').matches);

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
    timeoutMillis: _isIosStandalone ? 1500 : 3000,
  },
  config: {
    canvasKitBaseUrl: "canvaskit/",
  }
}).catch(function(err) {
  console.warn("Flutter load failed, attempting direct fallback without service worker:", err);
  if (typeof _flutter !== 'undefined' && _flutter.loader && _flutter.loader.load) {
    _flutter.loader.load({
      config: {
        canvasKitBaseUrl: "canvaskit/",
      }
    });
  }
});


