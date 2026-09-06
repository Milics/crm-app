'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "1777939913d51821bce223e0db1bb1dc",
"version.json": "d3c409e1edcb01ac0d00b7e119f1a5d8",
"index.html": "e6f9a3606df698493893769a69ccb7dc",
"/": "e6f9a3606df698493893769a69ccb7dc",
"main.dart.js": "10b971f1482d012055df6487abc58439",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"favicon.png": "a19eb9e9f4de29d9a231a8099fcd1568",
"icons/Icon-192.png": "d877cb8959d2b2c43c3a1506c7b02173",
"icons/Icon-maskable-192.png": "d877cb8959d2b2c43c3a1506c7b02173",
"icons/Icon-maskable-512.png": "c03ae6fe65e545a96241e6da70746bbb",
"icons/Icon-512.png": "c03ae6fe65e545a96241e6da70746bbb",
"manifest.json": "3dff9a4d8f92a2b5f7ec0635a7bd8ac9",
".git/config": "876cd016687587305dde7207bebbd60b",
".git/objects/61/ee93e0dfcf2b5dbbab855e493212943780d5f9": "17dd5ea8cd029c25e112c37317654e51",
".git/objects/0d/4492ec8df8955ceff61877fd699489ea698b0b": "e6ceb164659e3260041e4d892994c896",
".git/objects/59/5c0de0bffb66d10b95a6ce839ece4afd641e6f": "ff0dd2e176238cd6eadf0551508bcb57",
".git/objects/66/a91c347ca361869d3aadc7ea970afdc3529969": "3d3f3a294487e5efd1baceb191a88599",
".git/objects/50/86fe89a83527451ce8a2c0e0277ea9720d9a4f": "fc7f41c503d043736f30d147b82a05d9",
".git/objects/68/43fddc6aef172d5576ecce56160b1c73bc0f85": "2a91c358adf65703ab820ee54e7aff37",
".git/objects/68/7b003b797969a94b77a24eeb118343e7e96aea": "3f131be62d1b03036a17839dd359b798",
".git/objects/57/70de7d926d2c4bebee68fe529587d1861d32a7": "bba295dd103de555c03edd3a69926042",
".git/objects/6f/7661bc79baa113f478e9a717e0c4959a3f3d27": "985be3a6935e9d31febd5205a9e04c4e",
".git/objects/6f/b84309bc0bd08369035d7ae380320ba618950c": "50432875e8a574d52a656be75ab35cea",
".git/objects/03/7d6fdbc8c704496fa1863e34d2c123fbe50599": "a59f95923f94fd914f1cc6e718568306",
".git/objects/03/7820b79e80dda6acf663bb49c3f2db08cf0243": "275d0b84b265fd4a21541eac2a844d22",
".git/objects/9e/e4194f49061503771378fb89c86900714887e8": "833a0ef91ce615db1a4e92398fa8089a",
".git/objects/6a/541820f67554bdc172aece520f2b71edeff418": "9d9a1e18256a705657351d8bb1ce47c3",
".git/objects/6a/fefd4da6fb59e90903ede094a579c6c44f32cb": "0b1026bb827ea8a6bb28e19af157ef8e",
".git/objects/35/cf21af1472da12b8c0eb7fd55f079fc69cbb07": "3f7921b2c9d66fb00185cf80503ecc47",
".git/objects/69/b2023ef3b84225f16fdd15ba36b2b5fc3cee43": "6ccef18e05a49674444167a08de6e407",
".git/objects/69/dd618354fa4dade8a26e0fd18f5e87dd079236": "8cc17911af57a5f6dc0b9ee255bb1a93",
".git/objects/3c/fd062bef7ce6e2e1e300c6b369878b4482bb1f": "30d036ed57b387c49d551ea98e1199ed",
".git/objects/3c/4d2926b39a9c9ece0036b54ce54823f546c0e5": "599512b54d3c0bb106f71a832501ff7c",
".git/objects/3c/52e1de74c87f1b2ec2565a7bc619208c7d2e99": "6488b244d518a980b776ed96b4ba333d",
".git/objects/3c/13d8e10db8da8304ae0332ef47ac22142e0ff8": "2e4c77f5c90be3cfd970559f47b79a46",
".git/objects/51/4e027a37512ff30f354c10453238f8690cca26": "0a608db8e1ac1104b8e784649973620d",
".git/objects/51/03e757c71f2abfd2269054a790f775ec61ffa4": "d437b77e41df8fcc0c0e99f143adc093",
".git/objects/3d/253fb772e4588cb3d4fdced18e72ec32f3df45": "73ce344e0e64452536e19fb99eea2273",
".git/objects/3d/cf1d367d6fb3ef9354bbab29ba2c6b1c100264": "1961988f57dfed3d59bf1c3bca0c1408",
".git/objects/58/f81405dc9e268c78521487e12a9dabcdbb20a1": "569a1ad8c1bf01908479f6de447569b9",
".git/objects/67/ca368c5df7c32de0258cbef752b050066faf84": "9dcac67b434fa397ef1a20eb7ca7a87d",
".git/objects/93/1c9389a218f8097653154cdc815b0036062b55": "044c07cad9e7abfb89f46fc8ab98fc69",
".git/objects/93/b363f37b4951e6c5b9e1932ed169c9928b1e90": "c8d74fb3083c0dc39be8cff78a1d4dd5",
".git/objects/94/133bb1992cf4d2369a9d45cea5320253ab423e": "e804e1da4e57aae0821ff8465053179b",
".git/objects/94/ccf51e4597a08d6c55910d9b5342ef01016ede": "10d2705634339d65626489c4715d095f",
".git/objects/60/c3e182d83c2fd75d019799a0de82f9993a768c": "61e8d28416d827840757d822f27c1bdd",
".git/objects/60/af39722235a274097b20fa0264eef04a8b3c01": "5053f1b4bf0649df5e4dad8a1cd230fe",
".git/objects/60/fd34fb3721d40a670f42e458405f5bdcbef537": "af66a7ef7f957058d9f0f9c30af4aa41",
".git/objects/5a/5181badf7fd3d2cde48957a79c524f062d355c": "bbfa432046c7349097429295b2e0e083",
".git/objects/5a/5bed31b213578217f4ef7e48f3f2af97e0a21f": "81c18953f98ab3d0c343b50d2cee5961",
".git/objects/33/1568824205dbacae1db27377699b08c8a60cb0": "9892d73239680c6e89636de005a42ae5",
".git/objects/05/c9a58e44052ccf1bb115faf3731315b47a2d6a": "7633da2785147971bbc9fcf34bc05d11",
".git/objects/05/f0e45bf8641a0bf8729f54e38342af12cc6295": "f840119b1c0d0c41dce008345a795833",
".git/objects/05/67ac794b038cb86042c8ed82461c0491dc4ffd": "adb726ab37b73c1619f7858b309e5b74",
".git/objects/9d/75684b5391905479a7c91d3bc904073cb91737": "c7ce1a4ccb05170fa65ff73386765c16",
".git/objects/9d/570cef534ea2b4a24823458d0b16e82783fe52": "dac33ec9148d1db14229df5bdd3bb27f",
".git/objects/9d/99c6b80cd0ea697117ccd438ebd0bfa5c1c13b": "345389470f49f05c67be6f5de0c94658",
".git/objects/9c/a0591351cf46fc8a0e96fb00a4502698a32e69": "e6c9d44be2fb5e881c1bb668d953ee58",
".git/objects/a3/fc07edcb781dd3fa049f2d34383dfe2bd3933f": "d036da6614aebe6dfd53a4a04b38a3a6",
".git/objects/b2/8d91f9fbd8c1fd2bb4bc970ce52479149858bd": "20591bc2aad2c2b0f6f77eb9b210a226",
".git/objects/d9/5b1d3499b3b3d3989fa2a461151ba2abd92a07": "a072a09ac2efe43c8d49b7356317e52e",
".git/objects/ac/828bb5609bd2943243612bb086971708952524": "ac22746f157c50911e37530e67d8a327",
".git/objects/ad/ced61befd6b9d30829511317b07b72e66918a1": "37e7fcca73f0b6930673b256fac467ae",
".git/objects/bb/1e477f3132d9fa5e376aed3db85f8d017f40e6": "a5a28a28777db4e5b8825ff430857577",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "9c0876641083076714600718b0dab097",
".git/objects/d0/bf148fcc5d53739f9ce8f2e1b7a3bef471209a": "239a3ac3d5b1d8beb368894dd84b65a5",
".git/objects/be/939a8a84bc516e6dcf3f2afdca1837b67e14b2": "4c8cec0aa67fe67bfbbdf94dc12b79b8",
".git/objects/be/3bf6aca44741671babd2279384f9d3ad8621d9": "869793e3df31f0eff0ffbcf93594f0b1",
".git/objects/b3/98d11f0df670d80e0deedbd613cc9fc2230c22": "b42bf54c41a427a4e6c5b4f4a4bdbc66",
".git/objects/df/aeb8f1a5db1d2c0837918316caf7a0facd0cdb": "934cf6cac6ce0323d1a81090f60fd418",
".git/objects/df/900368159d499bedb4ba0e462f51d7222ae216": "511023203e1302dbdb2f083cdf0002bd",
".git/objects/da/9393cf8096c018a749c6df13fb3e53f87a15a7": "3f3d8e61ab7586685ea8bb3327a2038f",
".git/objects/b4/a96b2a787faf6d45813e1ba6013b63fc1e44a3": "9df116aa492aed0b27267cb6eec44d57",
".git/objects/b4/8176e937a92cba32694673ff5022e3a81034b9": "c29665dc9d49a94b2bc55e265317b2c4",
".git/objects/a2/e7982856caf660fb89ab60fe5e974aa223d90c": "e191eee003558734b7ab34779a968022",
".git/objects/a5/936cb2bee31a298babc7a84f96881485e2bc81": "b2be3ab6a352c829c85586d41ec15ea5",
".git/objects/bd/95685014cdbbf8103977241094e6008f33a8cc": "f25a3a4cd02f74d940fa19a49b3e4a42",
".git/objects/bd/88eaa6b6b3a8183e0da1d4eee0a1c353baa20d": "063430bdb60e046de6700d0485b002ac",
".git/objects/d1/12a58d38679fb323d3b34b7886a7478c98925c": "f1c79953253d3bebb8165e688b72a51a",
".git/objects/d1/52e60ebb99b4218c6a09c9607dfb8a829a1860": "b4f969c7f441f4c586b8109c3667938a",
".git/objects/d6/924ef3e9dd235138e00deca128e2ec4b374160": "1670bf7daa6c1159532ff68c1218520d",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/bc/2c054584546b67fa0894c6f87697dc1b6b3187": "650918a586ec0fbeade5ad79a481b3f8",
".git/objects/ae/cf77de194ec99acf1f9c30e9e82979a043b6eb": "892ea7aefdb88a6fc37a47bb43080786",
".git/objects/ae/d7724ef1cc2b6d079e35b604468d33c43c6171": "785621e5fb9eefaa5139956da4ca2cd4",
".git/objects/ae/1ef17f61176cd6f74ffbdf29161b8f0ca563f0": "d2d569e9c20539909a515c6f777bea10",
".git/objects/d8/de15f2ff4644a265b93918166c0227599d688e": "f6f54442691e52cf4d32399b9018b96f",
".git/objects/d8/2a8f0495a9d87b3fbddfd5963edf89f82b29be": "65d072e02807f1f0622fdc7ffd8a45d1",
".git/objects/d8/276f8d0a78ff0b55f0afed2e87218c8c0321a1": "bd19407ee31e777fd8b1d9267e880393",
".git/objects/ab/e987a567d3da1f22413f6a2026a03b89e4ded1": "e280dc3bcdaa5fcb6585bbd39401eafb",
".git/objects/e5/9ade53688ee1e9894f93a4197cba0ae247e74a": "20d5cc19f8a052211173adab7b44b61c",
".git/objects/e2/b311beab6b190021cf6c0b69cd21e8af21208a": "a297e669ab7374630dd6761fd47c280d",
".git/objects/e2/57dd0aabaf904ee384e9fa8e3023c88656be21": "fce3cad2a393ab73338b8687cd138c61",
".git/objects/e2/225cb92bf6be7cf60a0d508fca1baca4715b6a": "317d79eca66c78bd62cf89110cac9b18",
".git/objects/e2/3b0635fcc22058429d6f0549c1002eb2a5d94d": "deb30f36615110f343314ed97da24259",
".git/objects/f4/005a274e324a959ebc1b019b5871b2e3242a0b": "ff5a0718b8fd389298d981c59637febf",
".git/objects/f3/3e0726c3581f96c51f862cf61120af36599a32": "afcaefd94c5f13d3da610e0defa27e50",
".git/objects/f3/2c8b7acc0ce159772996963bb14f2e144096c5": "cf33fd69dd72e75d239cf64efd8acf76",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/eb/c02c9ba2f80d34cc51702765a14ce8b95d7cf5": "a82cc02dcbda8924b27e454d087a14f0",
".git/objects/eb/64de7cc534e01c457e921622a69baab1478a2c": "b6724bcf6a9719bdfd3be2eddffe1c66",
".git/objects/eb/c5b80a3c02eedcf04c1e839e3ab0512bb4715e": "104eb5f89b98b989ab8eef496d53c164",
".git/objects/c7/b0d6ee750fde314f6c5c25544f1e36f53f7bc0": "24c39fe2203922d6157129c06d11415e",
".git/objects/c7/3d9d2eebd7a599b8b3a72ec75a8863b06fb650": "1229a01327a59e02f1bd5d1c708c0d58",
".git/objects/c0/3ddc97b18617c4aee1ea7dfad812711cd9cbce": "03e18d56f2ef2e80f7971c0a10ab9783",
".git/objects/ee/e3021761765013ffb12cbed22d23cce6c8a938": "0b9bbe692b1f6314d2a1bd8ca800d0e5",
".git/objects/ee/dc77f58d81a10b02380547217f392d104478e9": "4d126fef87d6ba0cb80b44d6d26b1501",
".git/objects/ee/7abdc68236324e8aa34f0ef463b29e695402df": "5ba98e9b4c21c145d5b0910509181489",
".git/objects/c9/c4f87447da0d4060a4e14184d06472b7a29a4e": "208096c679cd33bf0e669594e9084a11",
".git/objects/fc/232896d9d1c25009eea024a218ea6a9a4692c8": "fb452e11a2d517fe3588e3f3a0dc199d",
".git/objects/fc/b9ff17d02b21f11ce5b456f32869d1f65abc35": "2590ec6b51de24251469a9bc7289c7f7",
".git/objects/fd/05cfbc927a4fedcbe4d6d4b62e2c1ed8918f26": "5675c69555d005a1a244cc8ba90a402c",
".git/objects/f2/e5e7ded6f7f325b024a58813f8db6bbcc11b24": "aefc87478258a5ddd6ebf31be7853c42",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/f5/9d5b986bb1345e8f34f56de5ce3e8f2f9178d8": "91e1bbc6ea07a425df29a4fda0e0b620",
".git/objects/e4/de9c5b66d815271634b870fb2c4a78d9131ebf": "7268aa821d10b85254c0f829df2fb93f",
".git/objects/e4/8edff94a2ea6fb7ea3d7f672db5a1acd1b63ff": "dbbfbd1cd1985d7bdac0407d0bc9cc4d",
".git/objects/fe/ad9b7110f9f94b3b5836c39355d3f5312bcf32": "403575810380f25fe56b601a56b3cbbd",
".git/objects/fe/8b626024fddb323f7100141063f71fc6e36133": "db74a5923eeeb61d9dad63eaf51be86a",
".git/objects/c8/93595cf06f694f609ea72a661f418b7567c352": "26ec4d7a6a0c6bf28984318632ceb53d",
".git/objects/c8/bea27e8d90e2a0d57e428bc985f514d6829289": "3bc0f1765c19f87a7b7728cfb840fb44",
".git/objects/c8/3af99da428c63c1f82efdcd11c8d5297bddb04": "144ef6d9a8ff9a753d6e3b9573d5242f",
".git/objects/fb/3918c0bbe8b4dbf979476dd9b52910b1edab3b": "097424452e30e4bf64dddb77f3e8c25e",
".git/objects/ed/9968fa623775901a0c48c6c07ee5b82f533a43": "56d7e0593b877846139590e7051c9601",
".git/objects/ed/98a136aae67538649bd270a53858234d13e463": "bed05dfed0922f10127a74fa4074caa4",
".git/objects/c6/8eb6b34fd9ea62b55c494a779cd9efe235cbae": "15932213b9c37c3e790aae62f362fccd",
".git/objects/c6/b224d4b2d7f3a7ea39c40ceb71c7da4ebf143b": "745787fd2603547f1a0ecb59b6170ca0",
".git/objects/18/33520ab5a4bfb9ecbd58b8d307b922e943cf2b": "f040bf324411e2a4ca0a99a934b0fd81",
".git/objects/27/be907ae07d8adb58992f95b18091ac3c836d4f": "135ea6c08f6856d6a2021759e1b3081b",
".git/objects/4b/ebad53fe77224a118812d753cdb6f6861b216e": "386dd657d6c08ee82fac75767a50f9ea",
".git/objects/11/0ec054b640b70aee3e033cb8b4dac9a096de15": "4b7c98ba07022ad88d2ea8e2135769bc",
".git/objects/7c/dcee58b8c487d5f4e872218764da48e8120519": "963a29aa2fde55c7be41bbb7aa2eac56",
".git/objects/7c/3463b788d022128d17b29072564326f1fd8819": "37fee507a59e935fc85169a822943ba2",
".git/objects/7c/364f33e3a1b1a0093ef279238527fd640ba4d6": "d2e40c5509bc7e5cf6279fb13ada5919",
".git/objects/16/4af706fa48825bc7d0d896f81181178ac3dbac": "98c0c4e46bfc9d80dd853c0abcd1e322",
".git/objects/45/579524ad036d88517c8a3a6ab9fe8e6465b741": "70e37e15c2990ba7a0920cac8d384df4",
".git/objects/45/32289fab9d677ba2d9fe6e2ad9e963b99ba8b1": "7be7d4ec1c322c38613d645476ca0e80",
".git/objects/1f/c2bd3cae155d9ed6064b80d224229c611eb506": "deafec29e0af2e2d999608a3e1b7c5a0",
".git/objects/73/fed98536aa178888e91770e41322fc0f5e0109": "31066b0f2b0f2561405b06287d6b995b",
".git/objects/73/da96febb047c7e26fc6b57131ac9886261fc56": "65d574481c426809efb4920ce967f017",
".git/objects/87/68566b99805522b4b21b75f6bb0fa1010da744": "1cb8f917233757cfe260ad6fc0317872",
".git/objects/87/e0dbc8cb7a30093191e888ec73d82282534009": "6265b6fb931048863046a1b247bb6606",
".git/objects/80/33784732962ad6d200babaef3f515ed15aed9e": "07a5e0b9d16c862e485859fbc8627511",
".git/objects/74/98b806f5d133737981b7c32f097da12d735dd5": "ed58b14f5a14953a087eeeb7ee53da4c",
".git/objects/1a/f557914404b7ebb43809ed221545f158c09ead": "df9dcd02a448a8585caa0e4335db9166",
".git/objects/1a/2d251890b5fdf5f94b3c3686ab0efe2b27084b": "39106ec6f74240d296b1dc2ac6003808",
".git/objects/17/448e9ebf040530605616a610f7a2bc9d500d6b": "5267c7a8aa576a933ca927208e440407",
".git/objects/17/5e7ac0949669c2c62b83f3b04306ef05a63f9e": "28f55cf9d2aa5e159d17dcdc66bdfae9",
".git/objects/7b/fe3ce7e7470aaa76c5dcf441321aeabf5c7fc3": "97776a2b60e82171cef03b885876f53b",
".git/objects/7b/d5ead762f95e368f931d8f7dc1d65e38e25f2f": "13305933b0326141ac1bcd4e77ceec36",
".git/objects/7b/030561b8d02610285bb76b59c15e2a3ff978cd": "f71b66d06277c7d9dfd266f0cef643b3",
".git/objects/7b/5b47e5940de3961f1d5f4683a16aa1d1eb8ccd": "4dadb371f0ac9198ee2fca955c50fc54",
".git/objects/7b/3a56b52a49bd65aa131bdbb2422dcb41ac7940": "fdcfe5f2172d2441d316e317539fdf85",
".git/objects/7b/5f46bca7fdb687318831b792a8383891e12e05": "d93f65a2d222d0150bc19fe2a7f1663d",
".git/objects/8f/952688d89b96c86ca76ba35d12205bee84f61d": "398c0b27c09a40c409bddf355099053d",
".git/objects/8f/5d232de40c21465dc422f54793caee0e2a79fc": "dba28b725391bea3023bccf8f83a38ff",
".git/objects/8f/e7af5a3e840b75b70e59c3ffda1b58e84a5a1c": "e3695ae5742d7e56a9c696f82745288d",
".git/objects/8a/1640c564106b85aa060b6a173671b8d903f82e": "4f64cc7ae7edceac29984771d31dffa2",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/7e/9d2ff64bd77e10db0a33bf9eea4d0679258117": "b1695c7f69ec27c65f9df2beafc45b9b",
".git/objects/7e/c70a4591b538fd5e54e7084ee0e79ed25830ad": "286e213a073eb893ee2cbb806153a08e",
".git/objects/10/1a5e30a3fccaeb7fded418df6930e888e9f9f4": "aa0c9ce4a3edd531c2345a825da37c09",
".git/objects/10/956521b746be8622481bfcba63db1abd04933c": "6727f9902c0c5c5ff9779182d0dc2592",
".git/objects/19/588cea440479e323c320ace881e4f6df58f1d9": "395b68602787306c54d2255ffd45c821",
".git/objects/19/f7deea8665b7641a2ad81bc313f9e76f0c8aa5": "5885428791775443f9dd4a3df1c69ebd",
".git/objects/4c/e5c486ec22231558860fa1f3fb74920d1076bc": "2cf0ed79ca485a35838f37f6059dc86d",
".git/objects/26/f8dc2034026c32db1b57cde623fb7fd3f93c77": "89dc4e149084d06c210ebc43acc23a77",
".git/objects/26/9e1e731bf23506e6e022d32f5a52b6bd0a2954": "01407f5d87ae745021d750b19b2dcdd7",
".git/objects/21/0e5ef49f0a270f63df00cd67db2b11f5ace7e0": "75d813882e073a7043d4fc8577d80205",
".git/objects/4d/8286e869c7765a9a8fb1b2102123abae05845a": "d96d309e5822e78bd82869b036be5e39",
".git/objects/4d/78e00ad9491f43e318e41c98b0494cd3912bef": "af9869a97235b3b052151a555084e6fe",
".git/objects/75/3d97e718a3ce358848769c935cc7b7f48fb575": "aae6f52e4517e45a7be35e9f7c13a4ea",
".git/objects/86/8bf3faffe8059dd13d835bad4a2f48ed9a4d60": "00aab25d3a65c0c5911ac7246780dd28",
".git/objects/86/9710bf3f2139c9e00db516fc9db0bba7d5f9df": "8494a8002b4ae11189042d04b7c53878",
".git/objects/72/ebf8e79aaaf81033ffa335e459fd0e6ed4c06f": "a6e83042022f70f36fa2af95dedb8243",
".git/objects/44/dcbe49b9a826829e53ea7adfccc1f9de20fa78": "fa0d063d18aa1ca5dd537b3ae31b4374",
".git/objects/44/fe6ff39645b7d64a8e3d5d951a837a2891a031": "2b8ab03a79253512c7664b5a2c000cbd",
".git/objects/2a/bdd35085ffc66c9a4accb60a9f9dd350f144fd": "f033f33c5b8ed3bc0010ef6eb728bd6c",
".git/objects/2a/b37127358d8f25caf870b9f1ac4bf4be13efde": "5a5198bf38ec1745264400d7418025fe",
".git/objects/2f/f8a24e654e49fdc7f93692cc1e6ec816ab1f9d": "6e6fdc2866e14c6295a94ffc9230078f",
".git/objects/88/2d6df32b3242611d82c1eb784bf52d8649dce1": "18dadffff720b8e3ae3021e9ba2b5214",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/88/41b6bf3a96bafd8865e83bd82948542a422bec": "cb408af97358f4d6eed3708cb6a5d4a9",
".git/objects/88/7be452d9d361e5bdfce7be399ba2d7b03ee00e": "6ea85f1bbca741adf673c7b33ab3fccf",
".git/objects/9f/f03e91d3608cd65eaab41f5099a87b926103de": "fee2814b514aa9f4c4f7755f5988dc37",
".git/objects/6b/68864ad2d0b4ed45d017257276a4304a1dd001": "039af5d933ed30860d50146f33621304",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/07/87c0fc5ba2972223ef4a67f0aea3733b5691c2": "ea41afaaa29d4bfc051a9a556e4cfe32",
".git/objects/07/cc85d27cb8e284c666412b8f263c8e83329d50": "cc69182b214c87895cb0e88735db96b7",
".git/objects/38/6ace24ab55bc6e637fadce076d4e54f8bf6713": "cbd429f116ef2730a3cbde0b74f31070",
".git/objects/38/6d0bd43a40fe45a0e2f9929c994a8b71accfcb": "d9d8b9245efd4b26c579cd999f9d4872",
".git/objects/6e/93470c3674791e244486477acf24343841f70f": "cc02487fccea21acbab95b74d7375e0e",
".git/objects/6e/26794c9ec26b40bd647b2a2bcbe4be09f54b31": "1791006f233adce4f77365e09e3741b0",
".git/objects/9a/4e6b206bd3ecd6a225b5381f982bc2aa8e15d3": "7b92ff97fa4a5db470f2c3c986fb6394",
".git/objects/9a/c04ef65870a77b7cf0a49ec2afbc5b38509c9f": "e7fa2ca292d944dffa0cf5783ed2ea67",
".git/objects/36/5d44093130ff6009537ab17f09f8ca81461fd3": "e2fbd7b601af1b592a6c8ef433937ec4",
".git/objects/5d/ea50decd10f87ea6f390168e079d1ed4cb829a": "1d734d24912ff31dd438b05d2a6d2d11",
".git/objects/5d/82691facb9b4f1c940cc1c648099ffdaf03952": "44ec5794328c6e689b7cfcc4e38f9905",
".git/objects/5d/bf62f77e2a78de0f6453fffbb9a34a101a2eea": "93a474cb0736ff41a639f46e9bd979ca",
".git/objects/31/aee5eecc4e58d25cd1f83decd5a5382590a533": "d5789dbeb6136071454bc37d7c080299",
".git/objects/91/a47915b9b58ae4f5ab3c6fead5bbc2ad8be8bf": "8c9c816af0f0737e943f05d9560deba5",
".git/objects/91/c191cd2056686aae3e9d77c454cbd3789ddd23": "8b8160d6747e025099b7cf1035881bf4",
".git/objects/65/b206dc8965eeb770356ff500892c562cfd3b1e": "7126adfe2d3c3a74893d37b391a0d0d5",
".git/objects/65/0e3419c7692e3bfc3b3196914edaff716b73d2": "f41887bbbf42f2914e71d8574ad2d1b5",
".git/objects/65/6b1f1b2aba7ef7229da1ccaf7d448bae69f271": "92d24756b245a0ca5c4f488d46b5cf43",
".git/objects/62/223d89999b3650106255df53872be2a8e85b23": "6137076ed0ee2bb392bd6a98b988f4d6",
".git/objects/96/83320846276c9b8282f15d9e46a9a04b5656f0": "28c59bde7e93383a1d488e057b85d25c",
".git/objects/96/9824d174fe31abd061aab2ff461886605c746a": "68b70b9a72fa34da79c539988dd4d105",
".git/objects/3a/8cda5335b4b2a108123194b84df133bac91b23": "1636ee51263ed072c69e4e3b8d14f339",
".git/objects/53/b186008d6249d4f0504a3ce74e16e116042cdb": "45055f6d9a0db3a3cabaa7dd2b8eb325",
".git/objects/3f/67362d7f26cdeba1915e117286375a9917547f": "cb0b9855e23b16519b234c506401b192",
".git/objects/30/9a46c4a71abf7cfe5b421974e5d2321a74bfe3": "fb52fe5e22a29987941cf512200fa5d3",
".git/objects/5e/fcaadb6bc72e772d2db7dcd80963e5a411dd97": "0f71bcff0f19f8d745d13f389874bb98",
".git/objects/5e/70f5ee3f5037d4940143fa061cfe1e46c558a1": "c39fedc0d81f3fdd90329406d0db0132",
".git/objects/5e/865490e3bc8469ae8426e9f6b1c4d765a802bd": "d64cfa25cbad0ec4803b06eb61045d7f",
".git/objects/5b/f402b8312fd4bd7b249e23f0880e2e534e02df": "0c8eadb3909aa397beb03bc1fd6fdcc7",
".git/objects/37/b5f445e690d3326397a1a4e33e1224cabc2fd6": "024eb146c5dfa0830c66a552ce9fe558",
".git/objects/37/8a97bc53b50ac73cf75a869efc1d65222404b2": "ab30dfb01e9245cef89e0d48e2c1aed2",
".git/objects/08/27c17254fd3959af211aaf91a82d3b9a804c2f": "360dc8df65dabbf4e7f858711c46cc09",
".git/objects/6d/6bdc520711cfc808cc5e5a93f904b4dccf5a25": "6a7ecd1b49e3da2d75d7d1602beb3caa",
".git/objects/6d/632a670772610408d8621a025480ae93f29f29": "a00027894387d457d7a52f0c49274a58",
".git/objects/6d/bbcea0bbfa40cf839dced26ffab96e72ba0e90": "a2841a490b079f58aacbac3e1259a5aa",
".git/objects/01/c7c51d777f57cc2e55b57c3ad463fd621e408a": "50c30989275260e77bc91f239fedf990",
".git/objects/01/ff92509ab641151b0e66ab2a1da480c10f2a04": "79e8b25728efe558fe461a849fa51ca8",
".git/objects/06/6de273afeaa577219519267ded873206848583": "e95496af85a737ed4d1cf440a8ab88fc",
".git/objects/99/30bb67e11199fa574d5a9455e8da0252e53ba7": "0e374f89527f006f94a14ea13593be53",
".git/objects/52/0eb8c84fd3d810ab803c30a317567cbdcfd430": "9a01d0fd94d9bf3605e3bad1a7e0efb9",
".git/objects/52/e31057724737a5a83016d6d976970ff6078a7e": "e002b082091836673d4eba665ebe9fc9",
".git/objects/55/97c02917aa960c9c25e54b704ab86affe097b6": "af350a2ceab4be865f028121d3b52437",
".git/objects/55/637400116b88f95254d39de998d329525b6c25": "25ffce60bd8423f98b1ba1da20d5da46",
".git/objects/55/80fe548df9763fa30bbb699a98177cba2721c3": "813b4de8fd64afb880646d99b69d7595",
".git/objects/97/fe2323cbd02aa2c3fab0fed6ccfdc3583fb614": "a486df53096d75bbf0a02847a3d7ea5d",
".git/objects/97/ddc09e714bd2a59a2904c645e9dea2148b069b": "2c608e303c396da7b17c8dd1b9768638",
".git/objects/63/982487edd4fe371b3121268ba4d6d1198e705a": "bbb26f778205c235a75d49f4c93ab2e5",
".git/objects/0a/878412bc1bcc1f111de709f1cf8bfafdabc703": "0d0aaa808a13a775348a41c863873448",
".git/objects/90/49e9135b56b1511c31845e05faaf548cd3d8ff": "5ed2ed38c1c1f78dbbf4c539e97e4c5d",
".git/objects/bf/f459d27e1d8b16118e6842037bc8d8db7c9e8e": "1749f2ea10c5f92a602c2aeec8a4bfa9",
".git/objects/bf/db74ac9eb713b6ff3e3b88cec4f33d556761dd": "ab7c7e98247a7eb1ffc6eb6c4b254264",
".git/objects/bf/f0bc1cbbcfe1c5789fa182db86de992786df9f": "1e1da1e5db0f7f3d3d0d401e51ce570b",
".git/objects/d3/61103949cf8fc4383116ed0700e7ec4387aff0": "dd4f3545267ad520bfb9a09220dde52d",
".git/objects/d3/bae95f68bce770cfeffaa91a565f81f26c894b": "94db6ddf26672c8abd7606f26d25066b",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/ba/1e19a8284b0c3bb8a40c0d55812777c53c761a": "08a56f207fccedf3da2a78e48f1fac87",
".git/objects/a7/321fc5f4c788c212f904ef1a0cbae8c89fc95d": "c0f7c0d1700021670527c51f1c2f8ebf",
".git/objects/b8/36d7d61646bd1ac13b7ae644b8b67b6d0aa953": "da7a5e8d4b2d1c631890ac358aaabd14",
".git/objects/b8/19fa9114ff45a9d40bb488c92b1998a7bbb1b7": "1875a908acd6c04967b9d15b317b07cc",
".git/objects/b1/836e8a4b364c40054169d0062a962a6807c881": "b729b3402b5aad294ce79b2f5aff95e5",
".git/objects/dd/10c5a891678288ceb84b67abd70e1debbab4f4": "44e155c7a1ff5d70d42a828806ef0f9b",
".git/objects/dd/2617c61a79d13fcb1de991d325c27d734b59b0": "3ec076382bf05f696728aae7119824c2",
".git/objects/dc/8760a885f6d55f59963d2111148561fb9046b8": "834da0d3336d416f98e33f13697bd8b7",
".git/objects/dc/7995f9a3248a2b3812f07dab7da236f7c20502": "fa3937f29adc8998c2dee8c52bce0cbb",
".git/objects/b6/e6046304a5449323958a22d0252bb4d54c6a80": "11f96b5e11f171d12a9083af48ce77a7",
".git/objects/a9/38d3dda5ab86b149ea44968d80879d49f0e73b": "aef3fa4e689b98a9f84069bca85352e7",
".git/objects/d2/45e586f08c1ebcd3aa0b98715b0682b2944607": "24a1fc006cfec5fb07a3a68e0470a350",
".git/objects/d2/ea9e7f2ea393b773107d5499b331ee9459c0c6": "e836c2b71950930949c067e3144407a6",
".git/objects/af/1d5826e55b830af1997625c89bee39a7591021": "ffaac3543122d5dcf700477e89dc7266",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/de/7e2999d1abb4bacb9db390ff7f6c17201fc272": "1379537130b8975b7b4e798a096ce327",
".git/objects/a6/dd9464dc6176847acdf582ec87abf72179a4b0": "e277791d710cbde19571e400d46559a1",
".git/objects/a6/eb19129fc20b16976a7501860ea6869886c69b": "983fc22cff5f2f205646a788aefc0c72",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/3e39bd49dfaf9e225bb598cd9644f833badd9a": "666b0d595ebbcc37f0c7b61220c18864",
".git/objects/ef/95212933b7c482fe3839743cd43910a48e1dbf": "5921c161fb7a9845dcc3282336b62fea",
".git/objects/ef/4c8f91eb1f1db9b69ff60c991df15c54fbd030": "1e6caafffb038d9fdf3492edd6e4b217",
".git/objects/ef/1e1ed71fdfd1fdb23b466aee379c5e8ca12749": "a002dc3fb57f9740fca66b93dca08fed",
".git/objects/c3/fc31e9256506c1130166f3d440633f0252a08b": "7031c17d301744b8ac8a308ce4e3a076",
".git/objects/c3/66789ded6110b779cc84617999e9137313d613": "3b70d79e71132eec5bf685da820885de",
".git/objects/c3/c17478329a4edb029b3afe3a8d496ca3aacdb7": "201e83ab34457640f54c54d4875513a6",
".git/objects/c3/a77321f1b6bfdb7ccb33c726d6cd0927f2d39b": "3b4df35e7b611b1896433d33a7c81392",
".git/objects/c4/bb47d4f712aaf34bbc65addca90ddfd7155dd0": "a8f8ee9aa46aa5c737c5a4f20dd832a1",
".git/objects/ea/66a15cc831775983dde20bd3c975db4b2178b7": "0118d58187e3ca7893e7c253aad3ee7f",
".git/objects/ea/ee36202a2a2a41aa5d747faed6d5e60d44bbd3": "f3d6e1353987c09fc9a5a6169309353d",
".git/objects/cd/6b50be8a050ad1ee888175fc9c1e8ad66abc89": "95d68802409ed160b8d79e76af0030f8",
".git/objects/e6/1d5466ad533b6e32a25eb73eb4690b63f7d307": "d33a9434625dbf26bc71e4eed9145fd8",
".git/objects/e6/eb8f689cbc9febb5a913856382d297dae0d383": "466fce65fb82283da16cdd7c93059ff3",
".git/objects/e6/9de29bb2d1d6434b8b29ae775ad8c2e48c5391": "c70c34cbeefd40e7c0149b7a0c2c64c2",
".git/objects/f0/9d84d5d1870c6689beb9a73ad727f186787725": "3714f3b4e4d30608cddfb3743787f605",
".git/objects/f0/b7c56736684f93dfd59ed2c7ff9ffe1bb5fc05": "c438bbba87bc028e3c18759c84e4dc2a",
".git/objects/e8/e33d49b58b8b3c33d8ba11adbb87760399c9c4": "131704e01cf4374c7818027302395741",
".git/objects/e8/ae4f91fa44739609b8c1ed3d28347d02a9132d": "6cfc37ca62cbdc1026bac96fedfa8f01",
".git/objects/fa/2030d79141425b6217455a6611a9cf569c393b": "a044a538801ac2657a19d7e236c0de4e",
".git/objects/fa/72fde890cfe50ba406b9772071f7131bd03869": "9e17a34c138f8f2a602cf735f2187b78",
".git/objects/fa/e1d0e64477dd65dac8843e387a60e35b097a9b": "886493ae27cd41f0640d70548f1e5b19",
".git/objects/c5/db0266a68aab027062f8b293595dd0a0130a2c": "b5e688cbf4c970566ae694ef5f0e2c17",
".git/objects/c5/386ce67a2817bc81225fa4e05311228fde0e40": "2a6fbb3163b27ab6bbc3fc3686dd8e10",
".git/objects/c5/3e479daaab5f83a71b289b42ddd7e8e71ee22d": "f9e5309c58c95567d4b14bd86e80a0ca",
".git/objects/f6/335b71a3174dd8b20a7a7f16ad732529efbbde": "fae00c5a5a4f8d30ab04293859b9cdc5",
".git/objects/f6/e6c75d6f1151eeb165a90f04b4d99effa41e83": "95ea83d65d44e4c524c6d51286406ac8",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/f1/b1b9acb9c7840f24547a08993822a4c61b5f81": "5dcb9a53b91930a182fe7d78f1d242b8",
".git/objects/f1/24e185364a3093c17babf71efb162b1d9e39d1": "fd111f77d10d733056621a7a77d7cdd1",
".git/objects/e7/9801ed07e5139f7ca0b666a88a52fb3fbe7489": "b81daea3f1db272fa058b29ca8238d2a",
".git/objects/ce/6619c36b88f554797bcf6134705d8e901e8b8f": "723edf39e2f85a5dab81e9e54455826c",
".git/objects/ce/60628e182845b86684404e18d267bfae15989b": "b8b4cf078a679ef3580d23455a55fc53",
".git/objects/e0/5708689ae31066720ec5a2e1ede507d4886e09": "98d2126ddb50b198aa0ef425ba4b079d",
".git/objects/e0/60e0dfc217b5d08d2ed7fc896682eb61524497": "b105eefc40858e7238e64b99a168d59c",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/46/89d77a0c923664f6cf0aeba8c55fe918262021": "cb7aef78bbc4db2d7a25aa3571bc6030",
".git/objects/2c/f679676c0b171ec2c5cc8f62af3289ac87bc87": "2608412026c51aa87379668bc5b5c99d",
".git/objects/2c/4d88e17f3441ffc7983fb9fbb3dc045160406a": "9c6d382ffe58f6ace7309a1b0f360641",
".git/objects/2d/f7141e4a4c675f0ca9323595fa7c1ea69541ab": "0b86fb5470ab1c07727d35ed5e471d52",
".git/objects/2d/d595c2d97d7579deaeee70578fa986fc452624": "6e971c1cd7abd04e070560a74721cbe5",
".git/objects/48/8009469760d79004cadaf399c321c0dd942d9b": "697d7bc6b62082530afc0fa8dafb0a29",
".git/objects/70/d219f6cc1f5678908581c7d19527b233728b89": "6cef0e5a14c8a403c900d222b86ab132",
".git/objects/1e/567be1df980e1e69d526cf6aeaed20c3d15b10": "0709b8e62724496bf9294af18b44085b",
".git/objects/4a/bb4362bd0e2a7e6059bf05606286d83ecc852c": "51c2f8c09f03b1736b1511c8319ca9dd",
".git/objects/4a/a6c702c410267e681f218bc17850f3126bf98c": "82b00e24f6f565903e4dc6d6ccb0a54e",
".git/objects/23/1c676e9df4510f12233bcc41df4c284f1176e8": "2f16e9e737900252428341d14cc38867",
".git/objects/23/cd53219ce824fc8f526af4f400869930d5743d": "10a89783fb04663f7136a2db50db8f23",
".git/objects/23/1bbdca96a820110aa94d1451b24df002c01795": "7880981b28d5ba3c0e954d6c3e29dd16",
".git/objects/4f/b055258d151b0bff6015524019a1da3c1ff0ad": "16afb688b3d348e0e0131561aac8b1dc",
".git/objects/4f/fe82360e17919382e9c62574cd37f8ec992c80": "54feb3f4f6137d311065196e2cd78af8",
".git/objects/8d/cf596dd772676d1b799823e120feb2de734891": "d2cec1b4cc6bff9cecc89c0e4262dc6b",
".git/objects/15/369925f89d4a899088f22a859cb74ec388c749": "9dc40df0a904f464a03d57a4482fa5cd",
".git/objects/8c/56056e4141f7022b65ee149471f6b46ca6d7a8": "62d9acf45e459cc8fc1530267f33761b",
".git/objects/8c/c07425932e124711068d3c383d8794d1694eeb": "7d72365ebc750de48bf0f555363c2ec0",
".git/objects/85/c4c70c1cb0e933112afeb941ea15e199784711": "4fba58901fdc778db82a80d773a93dbd",
".git/objects/85/e867f38601b538fe976c26715bb7e2ffa05bbf": "f79afd81a1d559aaedc71601eee3f36e",
".git/objects/85/63aed2175379d2e75ec05ec0373a302730b6ad": "997f96db42b2dde7c208b10d023a5a8e",
".git/objects/1d/8d84d6e8219e0f21dc65fc49e75ac7c9eb38c8": "432a2ed2d5da5c2f411446a70551cbb8",
".git/objects/71/eee39df154cd3d25510c5656057cbb5d594ae3": "19fc8fa18135c65adc5042b075a52f3f",
".git/objects/1c/7124219d1a0f0305eb3d24c63d5e6a43002f67": "0579e3a7d069041c17fc48f6bb24c3b9",
".git/objects/1c/63384774bef4e14ab26424b9d63161b15d4585": "3c98a19a68be49797c3f85b24a44cc79",
".git/objects/82/71f5257b9b8e7d5955b99d5a492675e71ec4cc": "e2bd2fbef5b56135ff42acdca53d115e",
".git/objects/82/ac5de484d185e8301fe4c3fe041be5455dc82a": "e7752a160270df7e7b9c9521610abd19",
".git/objects/40/de39d3c8880b54c11388f45048c65b3858cb08": "029f37fbf723849f8924cdaf5214ff8e",
".git/objects/2b/80dba6233809df0840d63784f5dc3efc4cf232": "d8e77149a6e5c64cd200a14fca271cb1",
".git/objects/47/1559811e11a8a8fa16a6967ccf31c26b4b9040": "e75ebc2d41eaa2cc9e101eba30ebbb79",
".git/objects/47/639b5c36abbc8b2ea939bbc8b94068c1fdb8b0": "58da26e0d857d6f2953b32d739d4c46e",
".git/objects/47/10b584a2e5d9fb8dcaec3d44868cf2bc460f99": "4c1cd84c168ca64ed0a57a7c4c3c66ba",
".git/objects/78/2a432c742f44df2b5eda91222db34fc3e26296": "3e912d1765ea6fc5516650a7b6100723",
".git/objects/8b/672f332e227f8f63644f4e225de1ca764f3221": "3ee8c76658256eb64592b17d4973174d",
".git/objects/7a/d08afccecbd5e1153f72008cadb268ad8c5cdb": "0cfab7119bf05096bd0ea9dcfc072ef0",
".git/objects/7a/13b4797721aba8adb61936bc6573ab5c25520d": "e8045ff44e439f4e3d9ab78dbd81022e",
".git/objects/7a/9f048530ccbc402dab9867f436813532630e42": "840759ac85c45aea366c2579c892f800",
".git/objects/7a/66e585fd115cfab714038aaf5891ff75b4b1f4": "26ac6b32907dde723592d1ebbbf7817a",
".git/objects/7a/fb76fa430ec129d364059518a4d99856becf58": "21f785014e805f40d0679a28f40e1765",
".git/objects/14/751265bd95f49f1c853c68819c36280637dfe7": "ea11955d3bf701edde4f81ed7e01478b",
".git/objects/14/480c4827752322890177a4f891cdc573a12dfd": "ce2fdbf8e0aca048374bd37e0da88bca",
".git/objects/14/483a9aa4490842359be6dba096f4aed75eef1e": "1e457be4cbef92b11b77fd510bc1e762",
".git/objects/22/6da5b0a57e9000ff5304264e9656186974f2f4": "fd20132a6c6fb7a57abdf18fa28a47c8",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "d6e78f7afe8c7be2abbaea3aa97bda36",
".git/logs/refs/heads/gh-pages": "14788a91ba98a84196aff6f3dd984b1c",
".git/logs/refs/remotes/origin/gh-pages": "24526f05d54609c13cebc8a901414173",
".git/logs/refs/remotes/origin/main": "f9a0511029512e1851b8bfe0dd6a1b05",
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
".git/refs/heads/gh-pages": "e3dca3ca36763a42421f476a9d562392",
".git/refs/remotes/origin/gh-pages": "e3dca3ca36763a42421f476a9d562392",
".git/refs/remotes/origin/main": "28dbc4762e1f59052a3b5f5030e68257",
".git/index": "7d427f750240e37a4c1598acfb66aab8",
".git/COMMIT_EDITMSG": "5a75d5951bf64a4edb85f41d8c47f80c",
"assets/NOTICES": "dea65752bfd508eec85d2bf97cfbfb19",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "7316e8b8262f0d3839a51a7f915f0c9a",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/AssetManifest.bin": "1cec29c6a0a66289aadbe7c0caf3f38e",
"assets/fonts/MaterialIcons-Regular.otf": "97c6704c2567774230eeda22771d2663",
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
