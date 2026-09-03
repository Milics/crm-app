'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "45ca1a3e6cfa25c0c58dd99c54973c51",
"version.json": "d3c409e1edcb01ac0d00b7e119f1a5d8",
"index.html": "5d05080f8d1c23a0112d660388d8cebd",
"/": "5d05080f8d1c23a0112d660388d8cebd",
"main.dart.js": "328d946c131313c1e0489255e0e51217",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"favicon.png": "a19eb9e9f4de29d9a231a8099fcd1568",
"icons/Icon-192.png": "d877cb8959d2b2c43c3a1506c7b02173",
"icons/Icon-maskable-192.png": "d877cb8959d2b2c43c3a1506c7b02173",
"icons/Icon-maskable-512.png": "c03ae6fe65e545a96241e6da70746bbb",
"icons/Icon-512.png": "c03ae6fe65e545a96241e6da70746bbb",
"manifest.json": "3dff9a4d8f92a2b5f7ec0635a7bd8ac9",
".git/config": "876cd016687587305dde7207bebbd60b",
".git/objects/59/5c0de0bffb66d10b95a6ce839ece4afd641e6f": "ff0dd2e176238cd6eadf0551508bcb57",
".git/objects/66/a91c347ca361869d3aadc7ea970afdc3529969": "3d3f3a294487e5efd1baceb191a88599",
".git/objects/50/86fe89a83527451ce8a2c0e0277ea9720d9a4f": "fc7f41c503d043736f30d147b82a05d9",
".git/objects/68/43fddc6aef172d5576ecce56160b1c73bc0f85": "2a91c358adf65703ab820ee54e7aff37",
".git/objects/57/70de7d926d2c4bebee68fe529587d1861d32a7": "bba295dd103de555c03edd3a69926042",
".git/objects/6f/7661bc79baa113f478e9a717e0c4959a3f3d27": "985be3a6935e9d31febd5205a9e04c4e",
".git/objects/03/7820b79e80dda6acf663bb49c3f2db08cf0243": "275d0b84b265fd4a21541eac2a844d22",
".git/objects/9e/e4194f49061503771378fb89c86900714887e8": "833a0ef91ce615db1a4e92398fa8089a",
".git/objects/35/cf21af1472da12b8c0eb7fd55f079fc69cbb07": "3f7921b2c9d66fb00185cf80503ecc47",
".git/objects/69/b2023ef3b84225f16fdd15ba36b2b5fc3cee43": "6ccef18e05a49674444167a08de6e407",
".git/objects/69/dd618354fa4dade8a26e0fd18f5e87dd079236": "8cc17911af57a5f6dc0b9ee255bb1a93",
".git/objects/51/03e757c71f2abfd2269054a790f775ec61ffa4": "d437b77e41df8fcc0c0e99f143adc093",
".git/objects/3d/cf1d367d6fb3ef9354bbab29ba2c6b1c100264": "1961988f57dfed3d59bf1c3bca0c1408",
".git/objects/93/b363f37b4951e6c5b9e1932ed169c9928b1e90": "c8d74fb3083c0dc39be8cff78a1d4dd5",
".git/objects/60/c3e182d83c2fd75d019799a0de82f9993a768c": "61e8d28416d827840757d822f27c1bdd",
".git/objects/60/af39722235a274097b20fa0264eef04a8b3c01": "5053f1b4bf0649df5e4dad8a1cd230fe",
".git/objects/5a/5bed31b213578217f4ef7e48f3f2af97e0a21f": "81c18953f98ab3d0c343b50d2cee5961",
".git/objects/05/c9a58e44052ccf1bb115faf3731315b47a2d6a": "7633da2785147971bbc9fcf34bc05d11",
".git/objects/9d/75684b5391905479a7c91d3bc904073cb91737": "c7ce1a4ccb05170fa65ff73386765c16",
".git/objects/b2/8d91f9fbd8c1fd2bb4bc970ce52479149858bd": "20591bc2aad2c2b0f6f77eb9b210a226",
".git/objects/d9/5b1d3499b3b3d3989fa2a461151ba2abd92a07": "a072a09ac2efe43c8d49b7356317e52e",
".git/objects/ac/828bb5609bd2943243612bb086971708952524": "ac22746f157c50911e37530e67d8a327",
".git/objects/ad/ced61befd6b9d30829511317b07b72e66918a1": "37e7fcca73f0b6930673b256fac467ae",
".git/objects/bb/1e477f3132d9fa5e376aed3db85f8d017f40e6": "a5a28a28777db4e5b8825ff430857577",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "9c0876641083076714600718b0dab097",
".git/objects/d0/bf148fcc5d53739f9ce8f2e1b7a3bef471209a": "239a3ac3d5b1d8beb368894dd84b65a5",
".git/objects/be/3bf6aca44741671babd2279384f9d3ad8621d9": "869793e3df31f0eff0ffbcf93594f0b1",
".git/objects/b3/98d11f0df670d80e0deedbd613cc9fc2230c22": "b42bf54c41a427a4e6c5b4f4a4bdbc66",
".git/objects/df/aeb8f1a5db1d2c0837918316caf7a0facd0cdb": "934cf6cac6ce0323d1a81090f60fd418",
".git/objects/df/900368159d499bedb4ba0e462f51d7222ae216": "511023203e1302dbdb2f083cdf0002bd",
".git/objects/b4/a96b2a787faf6d45813e1ba6013b63fc1e44a3": "9df116aa492aed0b27267cb6eec44d57",
".git/objects/a2/e7982856caf660fb89ab60fe5e974aa223d90c": "e191eee003558734b7ab34779a968022",
".git/objects/a5/936cb2bee31a298babc7a84f96881485e2bc81": "b2be3ab6a352c829c85586d41ec15ea5",
".git/objects/d1/12a58d38679fb323d3b34b7886a7478c98925c": "f1c79953253d3bebb8165e688b72a51a",
".git/objects/d1/52e60ebb99b4218c6a09c9607dfb8a829a1860": "b4f969c7f441f4c586b8109c3667938a",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/ae/1ef17f61176cd6f74ffbdf29161b8f0ca563f0": "d2d569e9c20539909a515c6f777bea10",
".git/objects/d8/de15f2ff4644a265b93918166c0227599d688e": "f6f54442691e52cf4d32399b9018b96f",
".git/objects/e2/57dd0aabaf904ee384e9fa8e3023c88656be21": "fce3cad2a393ab73338b8687cd138c61",
".git/objects/e2/225cb92bf6be7cf60a0d508fca1baca4715b6a": "317d79eca66c78bd62cf89110cac9b18",
".git/objects/f3/3e0726c3581f96c51f862cf61120af36599a32": "afcaefd94c5f13d3da610e0defa27e50",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/eb/c02c9ba2f80d34cc51702765a14ce8b95d7cf5": "a82cc02dcbda8924b27e454d087a14f0",
".git/objects/ee/7abdc68236324e8aa34f0ef463b29e695402df": "5ba98e9b4c21c145d5b0910509181489",
".git/objects/fc/232896d9d1c25009eea024a218ea6a9a4692c8": "fb452e11a2d517fe3588e3f3a0dc199d",
".git/objects/fd/05cfbc927a4fedcbe4d6d4b62e2c1ed8918f26": "5675c69555d005a1a244cc8ba90a402c",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/fe/ad9b7110f9f94b3b5836c39355d3f5312bcf32": "403575810380f25fe56b601a56b3cbbd",
".git/objects/fe/8b626024fddb323f7100141063f71fc6e36133": "db74a5923eeeb61d9dad63eaf51be86a",
".git/objects/c8/bea27e8d90e2a0d57e428bc985f514d6829289": "3bc0f1765c19f87a7b7728cfb840fb44",
".git/objects/c8/3af99da428c63c1f82efdcd11c8d5297bddb04": "144ef6d9a8ff9a753d6e3b9573d5242f",
".git/objects/fb/3918c0bbe8b4dbf979476dd9b52910b1edab3b": "097424452e30e4bf64dddb77f3e8c25e",
".git/objects/c6/8eb6b34fd9ea62b55c494a779cd9efe235cbae": "15932213b9c37c3e790aae62f362fccd",
".git/objects/c6/b224d4b2d7f3a7ea39c40ceb71c7da4ebf143b": "745787fd2603547f1a0ecb59b6170ca0",
".git/objects/18/33520ab5a4bfb9ecbd58b8d307b922e943cf2b": "f040bf324411e2a4ca0a99a934b0fd81",
".git/objects/27/be907ae07d8adb58992f95b18091ac3c836d4f": "135ea6c08f6856d6a2021759e1b3081b",
".git/objects/7c/3463b788d022128d17b29072564326f1fd8819": "37fee507a59e935fc85169a822943ba2",
".git/objects/45/579524ad036d88517c8a3a6ab9fe8e6465b741": "70e37e15c2990ba7a0920cac8d384df4",
".git/objects/45/32289fab9d677ba2d9fe6e2ad9e963b99ba8b1": "7be7d4ec1c322c38613d645476ca0e80",
".git/objects/73/da96febb047c7e26fc6b57131ac9886261fc56": "65d574481c426809efb4920ce967f017",
".git/objects/87/68566b99805522b4b21b75f6bb0fa1010da744": "1cb8f917233757cfe260ad6fc0317872",
".git/objects/80/33784732962ad6d200babaef3f515ed15aed9e": "07a5e0b9d16c862e485859fbc8627511",
".git/objects/1a/f557914404b7ebb43809ed221545f158c09ead": "df9dcd02a448a8585caa0e4335db9166",
".git/objects/1a/2d251890b5fdf5f94b3c3686ab0efe2b27084b": "39106ec6f74240d296b1dc2ac6003808",
".git/objects/17/5e7ac0949669c2c62b83f3b04306ef05a63f9e": "28f55cf9d2aa5e159d17dcdc66bdfae9",
".git/objects/7b/d5ead762f95e368f931d8f7dc1d65e38e25f2f": "13305933b0326141ac1bcd4e77ceec36",
".git/objects/8f/e7af5a3e840b75b70e59c3ffda1b58e84a5a1c": "e3695ae5742d7e56a9c696f82745288d",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/26/9e1e731bf23506e6e022d32f5a52b6bd0a2954": "01407f5d87ae745021d750b19b2dcdd7",
".git/objects/21/0e5ef49f0a270f63df00cd67db2b11f5ace7e0": "75d813882e073a7043d4fc8577d80205",
".git/objects/88/2d6df32b3242611d82c1eb784bf52d8649dce1": "18dadffff720b8e3ae3021e9ba2b5214",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/88/7be452d9d361e5bdfce7be399ba2d7b03ee00e": "6ea85f1bbca741adf673c7b33ab3fccf",
".git/objects/9f/f03e91d3608cd65eaab41f5099a87b926103de": "fee2814b514aa9f4c4f7755f5988dc37",
".git/objects/6b/68864ad2d0b4ed45d017257276a4304a1dd001": "039af5d933ed30860d50146f33621304",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/07/87c0fc5ba2972223ef4a67f0aea3733b5691c2": "ea41afaaa29d4bfc051a9a556e4cfe32",
".git/objects/07/cc85d27cb8e284c666412b8f263c8e83329d50": "cc69182b214c87895cb0e88735db96b7",
".git/objects/6e/26794c9ec26b40bd647b2a2bcbe4be09f54b31": "1791006f233adce4f77365e09e3741b0",
".git/objects/9a/4e6b206bd3ecd6a225b5381f982bc2aa8e15d3": "7b92ff97fa4a5db470f2c3c986fb6394",
".git/objects/9a/c04ef65870a77b7cf0a49ec2afbc5b38509c9f": "e7fa2ca292d944dffa0cf5783ed2ea67",
".git/objects/31/aee5eecc4e58d25cd1f83decd5a5382590a533": "d5789dbeb6136071454bc37d7c080299",
".git/objects/91/a47915b9b58ae4f5ab3c6fead5bbc2ad8be8bf": "8c9c816af0f0737e943f05d9560deba5",
".git/objects/91/c191cd2056686aae3e9d77c454cbd3789ddd23": "8b8160d6747e025099b7cf1035881bf4",
".git/objects/65/b206dc8965eeb770356ff500892c562cfd3b1e": "7126adfe2d3c3a74893d37b391a0d0d5",
".git/objects/65/0e3419c7692e3bfc3b3196914edaff716b73d2": "f41887bbbf42f2914e71d8574ad2d1b5",
".git/objects/65/6b1f1b2aba7ef7229da1ccaf7d448bae69f271": "92d24756b245a0ca5c4f488d46b5cf43",
".git/objects/3a/8cda5335b4b2a108123194b84df133bac91b23": "1636ee51263ed072c69e4e3b8d14f339",
".git/objects/3f/67362d7f26cdeba1915e117286375a9917547f": "cb0b9855e23b16519b234c506401b192",
".git/objects/30/9a46c4a71abf7cfe5b421974e5d2321a74bfe3": "fb52fe5e22a29987941cf512200fa5d3",
".git/objects/5e/70f5ee3f5037d4940143fa061cfe1e46c558a1": "c39fedc0d81f3fdd90329406d0db0132",
".git/objects/37/b5f445e690d3326397a1a4e33e1224cabc2fd6": "024eb146c5dfa0830c66a552ce9fe558",
".git/objects/37/8a97bc53b50ac73cf75a869efc1d65222404b2": "ab30dfb01e9245cef89e0d48e2c1aed2",
".git/objects/08/27c17254fd3959af211aaf91a82d3b9a804c2f": "360dc8df65dabbf4e7f858711c46cc09",
".git/objects/6d/632a670772610408d8621a025480ae93f29f29": "a00027894387d457d7a52f0c49274a58",
".git/objects/6d/bbcea0bbfa40cf839dced26ffab96e72ba0e90": "a2841a490b079f58aacbac3e1259a5aa",
".git/objects/01/c7c51d777f57cc2e55b57c3ad463fd621e408a": "50c30989275260e77bc91f239fedf990",
".git/objects/52/e31057724737a5a83016d6d976970ff6078a7e": "e002b082091836673d4eba665ebe9fc9",
".git/objects/97/fe2323cbd02aa2c3fab0fed6ccfdc3583fb614": "a486df53096d75bbf0a02847a3d7ea5d",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/a7/321fc5f4c788c212f904ef1a0cbae8c89fc95d": "c0f7c0d1700021670527c51f1c2f8ebf",
".git/objects/dd/2617c61a79d13fcb1de991d325c27d734b59b0": "3ec076382bf05f696728aae7119824c2",
".git/objects/a9/38d3dda5ab86b149ea44968d80879d49f0e73b": "aef3fa4e689b98a9f84069bca85352e7",
".git/objects/d2/45e586f08c1ebcd3aa0b98715b0682b2944607": "24a1fc006cfec5fb07a3a68e0470a350",
".git/objects/d2/ea9e7f2ea393b773107d5499b331ee9459c0c6": "e836c2b71950930949c067e3144407a6",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/3e39bd49dfaf9e225bb598cd9644f833badd9a": "666b0d595ebbcc37f0c7b61220c18864",
".git/objects/ef/4c8f91eb1f1db9b69ff60c991df15c54fbd030": "1e6caafffb038d9fdf3492edd6e4b217",
".git/objects/c3/66789ded6110b779cc84617999e9137313d613": "3b70d79e71132eec5bf685da820885de",
".git/objects/c4/bb47d4f712aaf34bbc65addca90ddfd7155dd0": "a8f8ee9aa46aa5c737c5a4f20dd832a1",
".git/objects/cd/6b50be8a050ad1ee888175fc9c1e8ad66abc89": "95d68802409ed160b8d79e76af0030f8",
".git/objects/e6/eb8f689cbc9febb5a913856382d297dae0d383": "466fce65fb82283da16cdd7c93059ff3",
".git/objects/e6/9de29bb2d1d6434b8b29ae775ad8c2e48c5391": "c70c34cbeefd40e7c0149b7a0c2c64c2",
".git/objects/f0/9d84d5d1870c6689beb9a73ad727f186787725": "3714f3b4e4d30608cddfb3743787f605",
".git/objects/f0/b7c56736684f93dfd59ed2c7ff9ffe1bb5fc05": "c438bbba87bc028e3c18759c84e4dc2a",
".git/objects/e8/e33d49b58b8b3c33d8ba11adbb87760399c9c4": "131704e01cf4374c7818027302395741",
".git/objects/fa/2030d79141425b6217455a6611a9cf569c393b": "a044a538801ac2657a19d7e236c0de4e",
".git/objects/fa/72fde890cfe50ba406b9772071f7131bd03869": "9e17a34c138f8f2a602cf735f2187b78",
".git/objects/c5/386ce67a2817bc81225fa4e05311228fde0e40": "2a6fbb3163b27ab6bbc3fc3686dd8e10",
".git/objects/c5/3e479daaab5f83a71b289b42ddd7e8e71ee22d": "f9e5309c58c95567d4b14bd86e80a0ca",
".git/objects/f6/e6c75d6f1151eeb165a90f04b4d99effa41e83": "95ea83d65d44e4c524c6d51286406ac8",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/f1/b1b9acb9c7840f24547a08993822a4c61b5f81": "5dcb9a53b91930a182fe7d78f1d242b8",
".git/objects/e7/9801ed07e5139f7ca0b666a88a52fb3fbe7489": "b81daea3f1db272fa058b29ca8238d2a",
".git/objects/e0/60e0dfc217b5d08d2ed7fc896682eb61524497": "b105eefc40858e7238e64b99a168d59c",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/2c/f679676c0b171ec2c5cc8f62af3289ac87bc87": "2608412026c51aa87379668bc5b5c99d",
".git/objects/4a/bb4362bd0e2a7e6059bf05606286d83ecc852c": "51c2f8c09f03b1736b1511c8319ca9dd",
".git/objects/23/cd53219ce824fc8f526af4f400869930d5743d": "10a89783fb04663f7136a2db50db8f23",
".git/objects/23/1bbdca96a820110aa94d1451b24df002c01795": "7880981b28d5ba3c0e954d6c3e29dd16",
".git/objects/4f/b055258d151b0bff6015524019a1da3c1ff0ad": "16afb688b3d348e0e0131561aac8b1dc",
".git/objects/8d/cf596dd772676d1b799823e120feb2de734891": "d2cec1b4cc6bff9cecc89c0e4262dc6b",
".git/objects/15/369925f89d4a899088f22a859cb74ec388c749": "9dc40df0a904f464a03d57a4482fa5cd",
".git/objects/85/63aed2175379d2e75ec05ec0373a302730b6ad": "997f96db42b2dde7c208b10d023a5a8e",
".git/objects/1c/63384774bef4e14ab26424b9d63161b15d4585": "3c98a19a68be49797c3f85b24a44cc79",
".git/objects/82/71f5257b9b8e7d5955b99d5a492675e71ec4cc": "e2bd2fbef5b56135ff42acdca53d115e",
".git/objects/47/639b5c36abbc8b2ea939bbc8b94068c1fdb8b0": "58da26e0d857d6f2953b32d739d4c46e",
".git/objects/78/2a432c742f44df2b5eda91222db34fc3e26296": "3e912d1765ea6fc5516650a7b6100723",
".git/objects/7a/d08afccecbd5e1153f72008cadb268ad8c5cdb": "0cfab7119bf05096bd0ea9dcfc072ef0",
".git/objects/7a/66e585fd115cfab714038aaf5891ff75b4b1f4": "26ac6b32907dde723592d1ebbbf7817a",
".git/objects/7a/fb76fa430ec129d364059518a4d99856becf58": "21f785014e805f40d0679a28f40e1765",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "4ab0f0784c97fb76fd7a2070bfbbad2d",
".git/logs/refs/heads/gh-pages": "9a8ba9f1ecdcf70773dc29c838a570ec",
".git/logs/refs/remotes/origin/gh-pages": "aa7bca5498d645e748ec64d9c16933cc",
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
".git/refs/heads/gh-pages": "c4828993ad1d0e77aed47e126f53d294",
".git/refs/remotes/origin/gh-pages": "c4828993ad1d0e77aed47e126f53d294",
".git/refs/remotes/origin/main": "28dbc4762e1f59052a3b5f5030e68257",
".git/index": "9513f5cdbaf1775c0fa0f61929612d90",
".git/COMMIT_EDITMSG": "fbd2a1cba018f952a5d48a86ad8351fe",
"assets/NOTICES": "dea65752bfd508eec85d2bf97cfbfb19",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "7316e8b8262f0d3839a51a7f915f0c9a",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/AssetManifest.bin": "1cec29c6a0a66289aadbe7c0caf3f38e",
"assets/fonts/MaterialIcons-Regular.otf": "999004e674453a067fadb27bba93bd2c",
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
