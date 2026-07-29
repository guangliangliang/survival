import "./weapp-adapter";
import "./godot-loader";
import "./share-helper";
function checkUpdate() {
  const updateManager = wx.getUpdateManager();
  updateManager.onCheckForUpdate(() => {
    // 请求完新版本信息的回调
    // console.log(res.hasUpdate)
  });
  updateManager.onUpdateReady(() => {
    wx.showModal({
      title: "更新提示",
      content: "新版本已经准备好，是否重启应用？",
      success(res) {
        if (res.confirm) {
          // 新的版本已经下载好，调用 applyUpdate 应用新版本并重启
          updateManager.applyUpdate();
        }
      },
    });
  });
  updateManager.onUpdateFailed(() => {
    // 新版本下载失败
  });
}
checkUpdate();

function initShare() {
  wx.showShareMenu({
    withShareTicket: true,
    menus: ["shareAppMessage", "shareTimeline"],
    success() {
      console.log("分享菜单设置成功");
    },
    fail(err) {
      console.error("分享菜单设置失败:", err);
    },
  });

  wx.onShareAppMessage(() => {
    return {
      title: "守住边境，击退来袭的动物和强盗！",
      imageUrl: "https://mmocgame.qpic.cn/wechatgame/3HEWh0Q0hvCPqLkuDS4TompEOJIdMLOJzVP7FhE4MY7sOPebbjBKP10FibpyMqxAc/0",
      imageUrlId: "3WUIs6HPQSe8zNVQc2Dyug==",
      query: "",
    };
  });

  wx.onShareTimeline(() => {
    return {
      title: "守住边境，击退来袭的动物和强盗！",
      imageUrl: "https://mmocgame.qpic.cn/wechatgame/3HEWh0Q0hvCPqLkuDS4TompEOJIdMLOJzVP7FhE4MY7sOPebbjBKP10FibpyMqxAc/0",
      imageUrlId: "3WUIs6HPQSe8zNVQc2Dyug==",
      query: "",
    };
  });
}
initShare();

GameGlobal.shareGame = function () {
  wx.shareAppMessage({
    title: "守住边境，击退来袭的动物和强盗！",
    imageUrl: "https://mmocgame.qpic.cn/wechatgame/3HEWh0Q0hvCPqLkuDS4TompEOJIdMLOJzVP7FhE4MY7sOPebbjBKP10FibpyMqxAc/0",
    imageUrlId: "3WUIs6HPQSe8zNVQc2Dyug==",
    query: "",
    success() {
      console.log("分享成功");
    },
    fail(err) {
      console.error("分享失败:", err);
    },
  });
};

GameGlobal.showShareMenu = function () {
  wx.showShareMenu({
    withShareTicket: true,
    menus: ["shareAppMessage", "shareTimeline"],
  });
};

// Configuration
const config = {
  textConfig: {
    firstStartText: "首次加载请耐心等待",
    downloadingText: ["正在加载资源", "加载中...", "请稍候..."],
    compilingText: "编译中",
    initText: "引擎初始化中",
    completeText: "开始游戏",
    textDuration: 1500,
    style: {
      color: "#ffffff",
      fontSize: 14,
    },
  },
  barConfig: {
    style: {
      width: 240,
      height: 25,
      backgroundColor: "rgba(0, 0, 0, 0.5)",
      foregroundColor: "#4CAF50",
      borderRadius: 20,
      padding: 2,
    },
  },
  iconConfig: {
    visible: true,
    style: {
      width: 74,
      height: 30,
      bottom: 20,
    },
  },
  materialConfig: {
    // 背景图或背景视频，两者都填时，先展示背景图，视频可播放后，播放视频
    backgroundImage: "images/background.jpg",
    backgroundVideo: "",
    iconImage: "images/logo.png",
    // icon图片，一般不更换
  },
};
GameGlobal.godotLoader = new GodotLoader(canvas, config);
