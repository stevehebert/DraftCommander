(function() {
  var BidHandler, HandlerBase, MessagePipeline, OwnerUpdateHandler, PlayerLoadHandler, TeamRulesProcessor, sam;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  TeamRulesProcessor = (function() {
    TeamRulesProcessor.rules;
    TeamRulesProcessor.prototype.GetOwnerList = function() {
      var list;
      list = jQuery('#ownerlist');
      return list.jqGrid('getDataIDs');
    };
    function TeamRulesProcessor(rules) {
      var owner, owners, _i, _j, _len, _len2;
      this.rules = rules;
      owners = this.GetOwnerList();
      alert(owners.length);
      for (_i = 0, _len = owners.length; _i < _len; _i++) {
        owner = owners[_i];
        for (_j = 0, _len2 = owners.length; _j < _len2; _j++) {
          owner = owners[_j];
          this.rules[owner] = this.rules.Positions.slice(0, rules.Positions.Length);
        }
        owner.CurrentFunds = this.rules.StartingFunds;
        owner.NeededPlayerCount = this.rules.MinPlayerCount;
        owner.MaxBid(__bind(function() {
          return this.CurrentFunds - (this.NeededPlayerCount(-1)) * this.rules.MinBid;
        }, this));
      }
    }
    TeamRulesProcessor.prototype.ProcessBid = function(ownerId, bidAmount, position) {
      var ownerInfo, positionInfo, set, summary, _i, _len, _ref;
      ownerInfo = this.rules[ownerId];
      ownerInfo.CurrentFunds -= bidAmount;
      ownerInfo.NeededPlayerCount -= 1;
      _ref = ownerInfo.Positions;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        positionInfo = _ref[_i];
        if (positionInfo.Position === position) {
          positionInfo.Count -= 1;
        }
      }
      summary = this.CreateSummary(rules[ownerId]);
      return set = {
        CurrentFunds: ownerInfo.CurrentFunds,
        NeededPlayerCount: ownerInfo.NeededPlayerCount,
        MaxBix: ownerInfo.MaxBid
      };
    };
    TeamRulesProcessor.prototype.CreateSummary = function(ownerInfo) {
      var position, positionSummary, _i, _len, _ref;
      if (ownerInfo.NeededPlayerCount < 1) {
        return '<< Auction Complete >>';
      }
      positionSummary = '';
      _ref = ownerInfo.Positions;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        position = _ref[_i];
        if (positionInfo.Count > 0) {
          if (positionSummary.length > 0) {
            positionSummary += ', ';
          }
          positionSummary += position.Count + ' ' + position.Position;
          if (positionSummary.Length === 0) {
            positionSummary = '<< All Required Positions Filled >>';
          }
        }
      }
      return positionSummary;
    };
    return TeamRulesProcessor;
  })();
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
  OwnerUpdateHandler = (function() {
    __extends(OwnerUpdateHandler, HandlerBase);
    OwnerUpdateHandler.teamRules;
    function OwnerUpdateHandler(rules) {
      this.teamRules = rules;
    }
    OwnerUpdateHandler.prototype.CanProcess = function(message) {
      return message.type === 'BID';
    };
    OwnerUpdateHandler.prototype.Process = function(message) {
      var ret;
      ret = this.GetOwnerData(message.OwnerId);
      ret.CurrentFunds = ret.CurrentFunds - message.BidAmount;
      if (message.BidAmount === 0) {
        ret.PlayersLeft += 1;
      } else {
        ret.PlayersLeft -= 1;
      }
      return this.SaveOwnerData(message.OwnerId, ret);
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
      this.messages = [];
      this.handlers = [];
      this.AddHandler(new PlayerLoadHandler());
      this.AddHandler(new BidHandler());
      this.AddHandler(new OwnerUpdateHandler());
    }
    MessagePipeline.prototype.AddHandler = function(handler) {
      return this.handlers.push(handler);
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
    MessagePipeline.prototype.GetHistory = function() {
      return jQuery.ajax({
        url: '/home/BidDetail',
        dataType: 'json',
        data: 'auctionId=1',
        context: this,
        success: function(data) {
          var record, _i, _len, _ref, _results;
          _ref = data.records;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            record = _ref[_i];
            if (record.type === 'BID') {
              _results.push(this.Process(record));
            }
          }
          return _results;
        }
      });
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
  jQuery.ajax({
    url: '/home/BidDetail',
    dataType: 'json',
    data: 'auctionId=1',
    success: function(data) {
      var record, _i, _len, _ref, _results;
      _ref = data.records;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        record = _ref[_i];
        _results.push(sam.Process(record));
      }
      return _results;
    }
  });
  jQuery.ajax({
    url: '/home/AuctionRules',
    dataType: 'json',
    data: 'auctionId=1',
    success: function(data) {
      return sam.AddHandler(new OwnerUpdateHandler(new TeamRulesProcessor(data)));
    }
  });
}).call(this);
