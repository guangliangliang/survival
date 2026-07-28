GameGlobal.ShareHelper = {
  shareConfig: {
    title: "边境守夜人",
    imageUrl:
      "https://mmocgame.qpic.cn/wechatgame/3HEWh0Q0hvCPqLkuDS4TompEOJIdMLOJzVP7FhE4MY7sOPebbjBKP10FibpyMqxAc/0",
    imageUrlId: "3WUIs6HPQSe8zNVQc2Dyug==",
    query: "",
  },

  init: function () {
    wx.showShareMenu({
      withShareTicket: true,
      menus: ["shareAppMessage", "shareTimeline"],
      success: function () {
        console.log("ShareHelper: 分享菜单初始化成功");
      },
      fail: function (err) {
        console.error("ShareHelper: 分享菜单初始化失败", err);
      },
    });

    wx.onShareAppMessage(function () {
      return {
        title: ShareHelper.shareConfig.title,
        imageUrl: ShareHelper.shareConfig.imageUrl,
        imageUrlId: ShareHelper.shareConfig.imageUrlId,
        query: ShareHelper.shareConfig.query,
      };
    });

    wx.onShareTimeline(function () {
      return {
        title: ShareHelper.shareConfig.title,
        imageUrl: ShareHelper.shareConfig.imageUrl,
        imageUrlId: ShareHelper.shareConfig.imageUrlId,
        query: ShareHelper.shareConfig.query,
      };
    });
  },

  setShareConfig: function (config) {
    if (config.title) {
      this.shareConfig.title = config.title;
    }
    if (config.imageUrl) {
      this.shareConfig.imageUrl = config.imageUrl;
    }
    if (config.imageUrlId) {
      this.shareConfig.imageUrlId = config.imageUrlId;
    }
    if (config.query) {
      this.shareConfig.query = config.query;
    }
  },

  shareToFriend: function () {
    wx.shareAppMessage({
      title: this.shareConfig.title,
      imageUrl: this.shareConfig.imageUrl,
      imageUrlId: this.shareConfig.imageUrlId,
      query: this.shareConfig.query,
      success: function () {
        console.log("ShareHelper: 分享给好友成功");
      },
      fail: function (err) {
        console.error("ShareHelper: 分享给好友失败", err);
      },
    });
  },

  updateShareMenu: function () {
    wx.updateShareMenu({
      withShareTicket: true,
      isPrivateMessage: false,
      success: function () {
        console.log("ShareHelper: 更新分享菜单成功");
      },
      fail: function (err) {
        console.error("ShareHelper: 更新分享菜单失败", err);
      },
    });
  },
};

ShareHelper.init();
