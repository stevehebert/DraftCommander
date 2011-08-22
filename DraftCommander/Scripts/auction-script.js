(function() {
  var AuctionRuleLoadHandler, BidHandler, BidLoadHandler, HandlerBase, MessagePipeline, OwnerLoadHandler, OwnerRecord, OwnerUpdateHandler, PlayerLoadHandler, sam;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  HandlerBase = (function() {
    function HandlerBase() {}
    HandlerBase.prototype.GetOwnerData = function(ownerId) {
      var list;
      list = jQuery('#ownerlist');
      return list.jqGrid('getRowData', ownerId);
    };
    HandlerBase.prototype.SaveOwnerData = function(ownerId, data) {
      var list;
      list = jQuery('#ownerlist');
      return list.jqGrid('setRowData', ownerId, data);
    };
    HandlerBase.prototype.GetPlayerData = function(playerId) {
      var list;
      list = jQuery('#list');
      return list.jqGrid('getRowData', playerId);
    };
    HandlerBase.prototype.SavePlayerData = function(playerId, data) {
      var list;
      list = jQuery('#list');
      return list.jqGrid('setRowData', playerId, data);
    };
    return HandlerBase;
  })();
  PlayerLoadHandler = (function() {
    function PlayerLoadHandler() {}
    PlayerLoadHandler.prototype.CanProcess = function(message) {
      return message.type === 'LOAD';
    };
    PlayerLoadHandler.prototype.ProcessRecord = function(grid, record) {
      return grid.jqGrid('addRowData', record.Id, record);
    };
    PlayerLoadHandler.prototype.Process = function(message) {
      var grid, record, _i, _len, _ref, _results;
      grid = jQuery('#list');
      _ref = message.PlayerData;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        record = _ref[_i];
        _results.push(this.ProcessRecord(grid, record));
      }
      return _results;
    };
    return PlayerLoadHandler;
  })();
  OwnerRecord = (function() {
    OwnerRecord.Id;
    OwnerRecord.Name;
    OwnerRecord.CurrentFunds;
    OwnerRecord.PlayersLeft;
    OwnerRecord.RequiredPlayers;
    OwnerRecord.NeededPlayers;
    OwnerRecord.Positions;
    OwnerRecord.AuctionRules;
    function OwnerRecord(auctionRules, record) {
      this.AuctionRules = auctionRules;
      this.Id = record.Id;
      this.Name = record.OwnerRow.Name;
      this.CurrentFunds = auctionRules.StartingFunds;
      this.PlayersLeft = auctionRules.MinPlayerCount;
      this.Positions = auctionRules.Positions.slice(0, auctionRules.Positions.length);
      this.RequiredPlayers = this.CalculateRequiredPlayers();
      this.NeededPlayers = this.CalculateNeededPlayers();
    }
    OwnerRecord.prototype.CalculateRequiredPlayers = function() {
      var count, record, _i, _len, _ref;
      count = 0;
      _ref = this.Positions;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        record = _ref[_i];
        if (record.Count > 0) {
          count = count + record.Count;
        }
      }
      return count;
    };
    OwnerRecord.prototype.CalculateNeededPlayers = function() {
      var neededPlayers, position, _i, _len, _ref;
      neededPlayers = '';
      _ref = this.AuctionRules.Positions;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        position = _ref[_i];
        if (position.Count > 0) {
          if (neededPlayers.length > 0) {
            neededPlayers += ', ';
          }
          neededPlayers += position.Count + ' ' + position.Position;
        }
      }
      if (neededPlayers === '') {
        neededPlayers = '<< All Required Positions Filled >>';
      }
      return neededPlayers;
    };
    OwnerRecord.prototype.ProcessBid = function(message) {
      return this.CurrentFunds -= message.BidAmount;
    };
    return OwnerRecord;
  })();
  OwnerLoadHandler = (function() {
    function OwnerLoadHandler() {}
    OwnerLoadHandler.OwnerData = [];
    OwnerLoadHandler.AuctionRules;
    OwnerLoadHandler.prototype.CanProcess = function(message) {
      return message.type === 'LOAD';
    };
    OwnerLoadHandler.prototype.ProcessRecord = function(grid, record) {
      var newRecord;
      newRecord = new OwnerRecord(this.AuctionRules, record);
      this.OwnerData[newRecord.Id] = newRecord;
      return grid.jqGrid('addRowData', newRecord.Id, newRecord);
    };
    OwnerLoadHandler.prototype.Process = function(message) {
      var grid, record, _i, _len, _ref, _results;
      this.AuctionRules = message.AuctionRules;
      this.OwnerData = [];
      grid = jQuery('#ownerlist');
      _ref = message.OwnerData;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        record = _ref[_i];
        _results.push(this.ProcessRecord(grid, record));
      }
      return _results;
    };
    return OwnerLoadHandler;
  })();
  AuctionRuleLoadHandler = (function() {
    function AuctionRuleLoadHandler() {}
    AuctionRuleLoadHandler.AuctionRules;
    AuctionRuleLoadHandler.prototype.CanProcess = function(message) {
      return message.type === 'LOAD';
    };
    AuctionRuleLoadHandler.prototype.Process = function(message) {
      return this.AuctionRules = message.AuctionRules;
    };
    return AuctionRuleLoadHandler;
  })();
  BidLoadHandler = (function() {
    BidLoadHandler.pipeline;
    function BidLoadHandler(pipeline) {
      this.pipeline = pipeline;
    }
    BidLoadHandler.prototype.CanProcess = function(message) {
      return message.type === 'LOAD';
    };
    BidLoadHandler.prototype.Process = function(message) {
      var bid, _i, _len, _ref, _results;
      _ref = message.BidHistory;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        bid = _ref[_i];
        _results.push(this.pipeline.Process(bid));
      }
      return _results;
    };
    return BidLoadHandler;
  })();
  OwnerUpdateHandler = (function() {
    __extends(OwnerUpdateHandler, HandlerBase);
    OwnerUpdateHandler.ownerInfo;
    function OwnerUpdateHandler(ownerInfo) {
      this.ownerInfo = ownerInfo;
    }
    OwnerUpdateHandler.prototype.CanProcess = function(message) {
      return message.type === 'BID';
    };
    OwnerUpdateHandler.prototype.Process = function(message) {
      var ownerData;
      ownerData = this.ownerInfo.OwnerData[message.OwnerId];
      ownerData.ProcessBid(message);
      return this.SaveOwnerData(message.OwnerId, ownerData);
    };
    return OwnerUpdateHandler;
  })();
  BidHandler = (function() {
    __extends(BidHandler, HandlerBase);
    function BidHandler() {
      BidHandler.__super__.constructor.apply(this, arguments);
    }
    BidHandler.prototype.CanProcess = function(message) {
      return message.type === 'BID';
    };
    BidHandler.prototype.GetOwnerName = function(message) {
      return this.GetOwnerData(message.OwnerId).Name;
    };
    BidHandler.prototype.Process = function(message) {
      var name, ret, _ref;
      name = this.GetOwnerName(message);
      ret = this.GetPlayerData(message.PlayerId);
      ret.Owner = name;
      message.OldBid = ret.BidAmount === '' ? 0 : parseInt((_ref = ret.BidAmount) != null ? _ref : 0);
      ret.BidAmount = message.BidAmount;
      return this.SavePlayerData(message.PlayerId, ret);
    };
    return BidHandler;
  })();
  MessagePipeline = (function() {
    MessagePipeline.messages;
    MessagePipeline.handlers;
    function MessagePipeline() {
      var loadHandler;
      this.messages = [];
      this.handlers = [];
      this.AddHandler(new PlayerLoadHandler());
      loadHandler = this.AddHandler(new OwnerLoadHandler());
      this.AddHandler(new AuctionRuleLoadHandler());
      this.AddHandler(new BidLoadHandler(this));
      this.AddHandler(new BidHandler());
      this.AddHandler(new OwnerUpdateHandler(loadHandler));
    }
    MessagePipeline.prototype.AddHandler = function(handler) {
      this.handlers.push(handler);
      return handler;
    };
    MessagePipeline.prototype.Process = function(message) {
      var handler, _i, _len, _ref, _results;
      _ref = this.handlers;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        handler = _ref[_i];
        if (handler.CanProcess(message)) {
          _results.push(handler.Process(message));
        }
      }
      return _results;
    };
    return MessagePipeline;
  })();
  sam = new MessagePipeline();
  jQuery.ajax({
    url: '/home/AuctionBigGulp',
    dataType: 'json',
    data: 'auctionId=1',
    success: function(data) {
      return sam.Process(data);
    }
  });
}).call(this);
