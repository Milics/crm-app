'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "90f2f32d7eab0016307c33677c7796db",
"app_version.json": "c82dd58c45aaddcffc1b5eba3851b280",
"version.json": "6a7fd87efd85eb73d22f389f94fa3840",
"index.html": "21c335bab511b3a78b22a373038232de",
"/": "21c335bab511b3a78b22a373038232de",
"main.dart.js": "f40f62ce01485b46acb7a10fe0f37ab2",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"favicon.png": "a19eb9e9f4de29d9a231a8099fcd1568",
"icons/Icon-192.png": "d877cb8959d2b2c43c3a1506c7b02173",
"icons/Icon-maskable-192.png": "d877cb8959d2b2c43c3a1506c7b02173",
"icons/Icon-maskable-512.png": "c03ae6fe65e545a96241e6da70746bbb",
"icons/Icon-512.png": "c03ae6fe65e545a96241e6da70746bbb",
"manifest.json": "3dff9a4d8f92a2b5f7ec0635a7bd8ac9",
"download.html": "00bf3c0730a4200ac922059053e23f97",
".git/ORIG_HEAD": "932aac7139b09af748f24fbf55a7717c",
".git/config": "0d7e99387a7afa4998bed9e01d2abf3a",
".git/objects/0d/bc133059c3fdfbd3f95007df4dd539bc5b0f80": "897db88e590292282dcba057b643412f",
".git/objects/3e/fba94c34a0d1e74061b7797ff3d2fa2402fc96": "5d099a000f978827f715b4b97ea1b37e",
".git/objects/68/43fddc6aef172d5576ecce56160b1c73bc0f85": "2a91c358adf65703ab820ee54e7aff37",
".git/objects/3b/3dbb663aab3ffece2d13dc3613ef9881528f21": "b1a0f941091fa5fcf18d30255d665c4c",
".git/objects/6f/7661bc79baa113f478e9a717e0c4959a3f3d27": "985be3a6935e9d31febd5205a9e04c4e",
".git/objects/32/4a7d8d96ce7147b6dcad895d8c164d49fdcb8f": "d12d6ddea6c50eb6af11d5745d746d12",
".git/objects/69/b2023ef3b84225f16fdd15ba36b2b5fc3cee43": "6ccef18e05a49674444167a08de6e407",
".git/objects/3c/ddb24deff35e059565682f84622d6b1d0efe94": "cbce81e38634c25776eb785192ba975d",
".git/objects/51/03e757c71f2abfd2269054a790f775ec61ffa4": "d437b77e41df8fcc0c0e99f143adc093",
".git/objects/67/39a1d329a4185654f7023f50d6f685cee00f45": "e9b2c4982329897ad0ca47c09d934323",
".git/objects/93/faa02ebe4c9eef278163180b02aaec8d371899": "6f305dc2ebabc11e02de75bfc12e0ca2",
".git/objects/93/b363f37b4951e6c5b9e1932ed169c9928b1e90": "c8d74fb3083c0dc39be8cff78a1d4dd5",
".git/objects/0e/366e74a61d12d2c0e36431e393ec39a0f85716": "b557a3bccff9d34e54f7ac6854061a11",
".git/objects/60/7b99f0c23cbb161ff396e93bd5b6b47f7da292": "4403fd6fa52058c2e6e845a536daac48",
".git/objects/5f/773c1f1a608e50d45b066a18b749ac8c0b104d": "60972755166e56c4d59a52c4f33c65a5",
".git/objects/05/61795b97ffa4b1f4dd26798d3a1e06a23744c1": "16c16bec95bb1d1de770f4be1a3cdf71",
".git/objects/9d/75684b5391905479a7c91d3bc904073cb91737": "c7ce1a4ccb05170fa65ff73386765c16",
".git/objects/9c/ab93178f720ef28f0266688b8b9a9fb67a0ae6": "5840773cdad84909562d3dd720468ed0",
".git/objects/9c/17058164890ae0665704eab513ce6233ccf4ba": "bdbdb4a173364cfa6ffc4881bc8e8932",
".git/objects/b5/2d15abb1bfd8441e1867fb35c86e31d0379c06": "2121cbe855c68f334fb3f8ce16601b75",
".git/objects/d9/2327c4549d8fdd1429f772883d5ec6d20acad0": "c32df7c14192137f448ee388fb46f40e",
".git/objects/d9/5b1d3499b3b3d3989fa2a461151ba2abd92a07": "a072a09ac2efe43c8d49b7356317e52e",
".git/objects/ac/66f756dd94a751ce067bc5be894e4a6d854b54": "95ad60780c29e0d521237733776e56be",
".git/objects/ad/ced61befd6b9d30829511317b07b72e66918a1": "37e7fcca73f0b6930673b256fac467ae",
".git/objects/d7/26fa2657e6cf005116fdf77d78aa4523676f59": "1288ef072ee7885beea7c2aedb32c704",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "9c0876641083076714600718b0dab097",
".git/objects/d7/f7b043794415c18cd82793d86bc712f688e752": "b73ad847e7e0a272af16948573ef7b2e",
".git/objects/d0/bf148fcc5d53739f9ce8f2e1b7a3bef471209a": "239a3ac3d5b1d8beb368894dd84b65a5",
".git/objects/be/3bf6aca44741671babd2279384f9d3ad8621d9": "869793e3df31f0eff0ffbcf93594f0b1",
".git/objects/df/aeb8f1a5db1d2c0837918316caf7a0facd0cdb": "934cf6cac6ce0323d1a81090f60fd418",
".git/objects/d6/f23319536f2a8b37d34e05b91d6630bfa6df64": "7aff1ee33a7a67c03fc35e85c21cef6a",
".git/objects/ae/1ef17f61176cd6f74ffbdf29161b8f0ca563f0": "d2d569e9c20539909a515c6f777bea10",
".git/objects/d8/69c9fb72e632ccfb7fd9a141f747982060caef": "931c3078d5cc170b6e832802eb27a0e0",
".git/objects/ab/4df7a6da90748ef5b0267251fb34a8f772e261": "c929bb294ab7f7a7411ab02e792ede66",
".git/objects/e5/3e08ebedf684df3d09a521b974405f4df42270": "c5b70d58693d86c5b3f8d931677bf3f5",
".git/objects/e2/3e31a90799abbe06551486c93d48ff29a07140": "3347ebf65d3e3e90554a50017316cf85",
".git/objects/f4/c6e7c207e28a2d2ed500cada40d1a0f8e6d524": "22386d01eeb4191bbf2324f448d93b50",
".git/objects/f3/3e0726c3581f96c51f862cf61120af36599a32": "afcaefd94c5f13d3da610e0defa27e50",
".git/objects/c9/f3a16690eda93a72311e45cb0fb3ecf64f248c": "e33bf56e3dcd022e1be7cfde12629583",
".git/objects/fd/05cfbc927a4fedcbe4d6d4b62e2c1ed8918f26": "5675c69555d005a1a244cc8ba90a402c",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/e4/415d4db6fed75b312ba334049ad749f0b1235a": "8f0ab3c4d6a9154f13adf97e7e2a11ec",
".git/objects/c8/3af99da428c63c1f82efdcd11c8d5297bddb04": "144ef6d9a8ff9a753d6e3b9573d5242f",
".git/objects/fb/296f2f157a06a8ffce452010d46216b566d3cd": "d13f6873685d68148202e7636fefd968",
".git/objects/fb/3918c0bbe8b4dbf979476dd9b52910b1edab3b": "097424452e30e4bf64dddb77f3e8c25e",
".git/objects/c6/6cba2c4aeb35d083ddc790d6814327d8460aab": "bc657a43adceb40b00f747d255355bc0",
".git/objects/27/be907ae07d8adb58992f95b18091ac3c836d4f": "135ea6c08f6856d6a2021759e1b3081b",
".git/objects/7c/3463b788d022128d17b29072564326f1fd8819": "37fee507a59e935fc85169a822943ba2",
".git/objects/45/8d9576e42cb011921828a754f75d6830913890": "6394da5365236c00590aafc03d6d74f0",
".git/objects/87/076724ebb549ab075e90bd518c885128dc63d1": "26642f406493432b81146ca85828a69e",
".git/objects/87/a6dd5f1fe50ec08135b8cbb2ed2c460ba07df6": "3e9453b7673366d9fb4a2adbfc988203",
".git/objects/80/33784732962ad6d200babaef3f515ed15aed9e": "07a5e0b9d16c862e485859fbc8627511",
".git/objects/8f/5d19f9547a1936505563feddccafb63186813d": "61a61bccd37b6177dce12c60e57132ba",
".git/objects/2f/30826964a56a3f53ae650e6cd4cdb96f68e38c": "57a1a53258f021097c0627133c96c842",
".git/objects/88/d123c511cd8d61dd01a5c80ad622c0df87c9d8": "943548ee43f77ccc4f2b4bd4fa032151",
".git/objects/88/725040ee6707e0a5e3a0841142c738b95ff38c": "b301158b9eae9e900540ffa6b18fa7a1",
".git/objects/9f/4d08985a4df8e403f129bc412aa71fb91b1140": "ff30b64b917d40727f47e2d014ca9706",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/07/d1677ffac0dbd8bb44a3d08cb8980f54b6b9c2": "4cc8394c0e63830a53475581833bd130",
".git/objects/00/9ebfdbb82d19f2b5c7aecad095f3d2f7d6a65e": "b18d376ccdcb559fab10bbb79b795aed",
".git/objects/36/c6d1d3f7d4ce4baed839ec42f013d9a7b1ce48": "7340934c62aa895990de3bf8975011ee",
".git/objects/36/c64271ca839105ae7f4595bd0ae9197f98311b": "6c93934418ef6b4db2da751e33045d3f",
".git/objects/3a/8cda5335b4b2a108123194b84df133bac91b23": "1636ee51263ed072c69e4e3b8d14f339",
".git/objects/54/a98682e3a7ee88623ec44002ec520aaeee0922": "4ff6ac095cdb904615be637e08159af5",
".git/objects/98/92ebce212a820da98632ff1146a20284dbc88a": "c402d6c6b63b4d07029d85b954e6866a",
".git/objects/5e/f3568226ec7caa075c71efb925f87bf1f3c73b": "3cb188b817c451e7cf8812caac3cf995",
".git/objects/5e/036c07d768c8ddea4995fcdaa4b07de22f1579": "45b59cfd2970be2fdac4cb2c6bed5746",
".git/objects/08/27c17254fd3959af211aaf91a82d3b9a804c2f": "360dc8df65dabbf4e7f858711c46cc09",
".git/objects/01/c7c51d777f57cc2e55b57c3ad463fd621e408a": "50c30989275260e77bc91f239fedf990",
".git/objects/06/074ebdddde36338bbcfe1c2f53b1c874c11bb3": "a08d19104171d83f48fc748c7fd1cd69",
".git/objects/6c/f6a631fcff367564e7f904e1c4225cd960ed99": "cdbddc1cb6bb34e36d341aec25409552",
".git/objects/97/d3032f2bd73f9df7d3c6dcd4582e0cf1d76d2f": "8f3c22265bfbfbc7142a83becb850b7b",
".git/objects/0f/a4d5c42d03650f6c750646d564ba809114730a": "b36bbcd2589a5d6e5d4d96b0e7dade01",
".git/objects/0a/6fe1bce0c2e3b5eb780a50d5a886b2cba23950": "6674a4d73ba2ffa69812804856bb3a87",
".git/objects/90/4eee763d0478ca0bca264b6c998c0f1a1e689d": "a889af6bbce92c0cad6d91bfa48262a0",
".git/objects/d3/2c8ee3d486e39ad334135fdbe14bff2e2e3542": "084de57386b45f3eb7c653d41a6d5aed",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/b8/95e40c48f3f3f404674c6a6028af0231a1ad2b": "35570f1974f8894fcd4f77146edf9830",
".git/objects/b8/ff2fa932e9e93af097bd7af71e660de0116571": "bdaad1b498fa624bd8a6cd0a570aabea",
".git/objects/b1/7efac9bb9feef02676413f8cf90efb04781004": "d5bb15c7ee7c83124d2e0e0cca498a97",
".git/objects/dd/0b2274bcb14524856a7adbe201efc6c62ae5bc": "53049e1d022408fd5c6305257ca3f921",
".git/objects/dd/f915321743ea28203436e927684e62148ece9a": "9a430bebe538c6dab97a30fdafe26a62",
".git/objects/a9/92d4b0301dffbdd2aa2e00376bd7458951c194": "2c52ddad80b6a9f49d3f2370e035a149",
".git/objects/aa/35289df414f5d422a5388ff35f47cb40c6ff5a": "24a91554c9efb96e224f002953b0abbb",
".git/objects/b9/3e39bd49dfaf9e225bb598cd9644f833badd9a": "666b0d595ebbcc37f0c7b61220c18864",
".git/objects/e6/eb8f689cbc9febb5a913856382d297dae0d383": "466fce65fb82283da16cdd7c93059ff3",
".git/objects/e6/9de29bb2d1d6434b8b29ae775ad8c2e48c5391": "c70c34cbeefd40e7c0149b7a0c2c64c2",
".git/objects/f6/e6c75d6f1151eeb165a90f04b4d99effa41e83": "95ea83d65d44e4c524c6d51286406ac8",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/f1/82112656724f82b7c69c172a13e4a3a6cf4718": "8a9e255523bf0d7c100d1572cd7532ca",
".git/objects/f8/63cb6138435d6d442cc335b18fbb1065f8a83d": "105d80f9a26363761824a2a18caf1545",
".git/objects/ce/ebfe76559e205ee5add282506accfc69dcaf99": "f2c41d23f2c73239129cb7710e1b9cf2",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/46/78728a148fe7e82d3b2693a50e18510a208303": "15d34c20b89c8658ed8cbafdc708f6aa",
".git/objects/79/c7bb3be6865b98950f3add09e5c225efac7198": "b8bbc08879f54e7c2aabb330578ab238",
".git/objects/77/83eaf573b64555e02492941f1f5f5ee4be5f6f": "d788e4970702f9e6d4940492ae8fe1c3",
".git/objects/77/c2d7d71d79d64a6c5449df3b52826960a8d397": "99dd4008319d691c21af8c48b744d35d",
".git/objects/1e/7976cd78c81e85afe7cf5b8b06c18f2a3cc55f": "21de8e0e26dd2392c1098b3fa6b86cee",
".git/objects/4a/bb4362bd0e2a7e6059bf05606286d83ecc852c": "51c2f8c09f03b1736b1511c8319ca9dd",
".git/objects/24/e099d40be9fa16493b53360195d06e2839b19f": "89e3b293aa255f5445be87051d9805c1",
".git/objects/85/63aed2175379d2e75ec05ec0373a302730b6ad": "997f96db42b2dde7c208b10d023a5a8e",
".git/objects/71/515da2c21f074ac7c3700974e66c7ea9358d19": "0c3fb9bcbdceb1865748278f211708e9",
".git/objects/40/0f211b8d9aab0c88b944ac024478da5b753693": "fa2a0b65f5cb45d2d335d4eb78368765",
".git/objects/47/639b5c36abbc8b2ea939bbc8b94068c1fdb8b0": "58da26e0d857d6f2953b32d739d4c46e",
".git/objects/7f/14de3405072b2758144cf51334d60768f27b1b": "36f861572240463d79b2f36a408d280f",
".git/objects/14/222c71e070ec1e9de5c5fedada90257ca58a72": "ba7ae20b792a6bea32982af23e99e1be",
".git/objects/22/03d50668939a3cd91fcecca1db5b65b2300591": "0b1dbf31aa4130de3b278ecb37e72aed",
".git/objects/25/df03efbb1cd9919c205bb0d37c558884271303": "1885529d1d44fc5adb13d97e15cc3695",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "0b36b7f1fb88008e499896afe17e4b7f",
".git/logs/refs/heads/gh-pages": "3d8c1263bc01f73d8ddb666eb2e9adcc",
".git/logs/refs/heads/main": "ca132ff001b59dbc0fbd61c25a33ae8d",
".git/logs/refs/remotes/origin/gh-pages": "43d407120cbb617e30655ecf20d24cdf",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-commit.sample": "305eadbbcd6f6d2567e033ad12aabbc4",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/refs/heads/gh-pages": "a269f2dedf8ba8aec1f713958a29852d",
".git/refs/heads/main": "a298c3ee5ac65e17ca73a2b2da5fbeed",
".git/refs/remotes/origin/gh-pages": "a269f2dedf8ba8aec1f713958a29852d",
".git/index": "77ccbba59b774a3d4639842cd99c4804",
".git/COMMIT_EDITMSG": "747c699a6ba1b7f177b34724d573d5c7",
".git/FETCH_HEAD": "b47232b528506aedffcad764e6ea57bc",
"assets/NOTICES": "90fc6888bcafb155db5e84567d5d81bc",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "7316e8b8262f0d3839a51a7f915f0c9a",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/AssetManifest.bin": "1cec29c6a0a66289aadbe7c0caf3f38e",
"assets/fonts/MaterialIcons-Regular.otf": "0f8f6fbe825e6111c6091428888152b1",
"assets/assets/images/logo.png": "1a89f55eec25c9d9545a90cdabfd2408",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
