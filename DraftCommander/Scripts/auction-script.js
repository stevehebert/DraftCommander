(function() {
  var AuctionState, BidHandler, BidLoadHandler, BidSetHandler, HandlerBase, MessagePipeline, OwnerLoadHandler, OwnerRecord, OwnerUpdateHandler, PlayerDropListLoader, PlayerLoadHandler, StateLoadHandler, sam;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  AuctionState = (function() {
    function AuctionState() {}
    AuctionState.OwnerList = [];
    AuctionState.PlayerList = [];
    AuctionState.AuctionRules;
    AuctionState.Bids = [];
    AuctionState.OwnerData = [];
    AuctionState.prototype.Process = function(message) {
      var bid, record, _i, _j, _k, _len, _len2, _len3, _ref, _ref2, _ref3, _results;
      this.OwnerData = [];
      this.AuctionRules = message.AuctionRules;
      this.OwnerList = [];
      _ref = message.OwnerData;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        record = _ref[_i];
        this.OwnerList[record.Id] = record;
      }
      this.PlayerList = {};
      _ref2 = message.PlayerData;
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        record = _ref2[_j];
        this.PlayerList[record.Id] = record;
      }
      this.Bids = [];
      _ref3 = message.BidHistory;
      _results = [];
      for (_k = 0, _len3 = _ref3.length; _k < _len3; _k++) {
        bid = _ref3[_k];
        _results.push(this.Bids.push(bid));
      }
      return _results;
    };
    return AuctionState;
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
  StateLoadHandler = (function() {
    StateLoadHandler.AuctionState;
    function StateLoadHandler(auctionState) {
      this.AuctionState = auctionState;
    }
    StateLoadHandler.prototype.CanProcess = function(message) {
      return message.type === 'LOAD';
    };
    StateLoadHandler.prototype.Process = function(message) {
      return this.AuctionState.Process(message);
    };
    return StateLoadHandler;
  })();
  PlayerLoadHandler = (function() {
    function PlayerLoadHandler(AuctionState) {
      this.AuctionState = AuctionState;
    }
    PlayerLoadHandler.prototype.CanProcess = function(message) {
      return message.type === 'LOAD';
    };
    PlayerLoadHandler.prototype.ProcessRecord = function(grid, record) {
      return grid.jqGrid('addRowData', record.Id, record);
    };
    PlayerLoadHandler.prototype.Process = function(message) {
      var grid, id, record, _ref, _results;
      grid = jQuery('#list');
      _ref = this.AuctionState.PlayerList;
      _results = [];
      for (id in _ref) {
        record = _ref[id];
        _results.push(this.ProcessRecord(grid, record));
      }
      return _results;
    };
    return PlayerLoadHandler;
  })();
  PlayerDropListLoader = (function() {
    function PlayerDropListLoader(AuctionState) {
      this.AuctionState = AuctionState;
    }
    PlayerDropListLoader.prototype.CanProcess = function(message) {
      return message.type === 'LOAD';
    };
    PlayerDropListLoader.prototype.ProcessRecord = function(id, value) {
      return jQuery('#admin-select').append(jQuery("<option></option>").attr("value", id).text(value.Name));
    };
    PlayerDropListLoader.prototype.Process = function(message) {
      var id, value, _ref;
      _ref = this.AuctionState.PlayerList;
      for (id in _ref) {
        value = _ref[id];
        this.ProcessRecord(id, value);
      }
      return jQuery('.chzn-select').chosen();
    };
    return PlayerDropListLoader;
  })();
  OwnerRecord = (function() {
    OwnerRecord.Id;
    OwnerRecord.Name;
    OwnerRecord.CurrentFunds;
    OwnerRecord.PlayersLeft;
    OwnerRecord.RequiredPlayers;
    OwnerRecord.NeededPlayers;
    OwnerRecord.Positions;
    OwnerRecord.MaxBix;
    function OwnerRecord(record, AuctionState) {
      var position, _i, _len, _ref;
      this.AuctionState = AuctionState;
      this.RecalcMaxBid = __bind(this.RecalcMaxBid, this);
      this.Id = record.Id;
      this.Name = record.OwnerRow.Name;
      this.CurrentFunds = this.AuctionState.AuctionRules.StartingFunds;
      this.PlayersLeft = this.AuctionState.AuctionRules.MinPlayerCount;
      this.Positions = [];
      _ref = this.AuctionState.AuctionRules.Positions;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        position = _ref[_i];
        this.Positions[position.Position] = position.Count;
      }
      this.AssignedPlayers = [];
      this.RequiredPlayers = this.CalculateRequiredPlayers();
      this.NeededPlayers = this.CalculateNeededPlayers();
      this.RecalcMaxBid();
    }
    OwnerRecord.prototype.RecalcMaxBid = function() {
      return this.MaxBid = this.CurrentFunds - ((this.PlayersLeft - 1) * this.AuctionState.AuctionRules.MinBid);
    };
    OwnerRecord.prototype.CalculateRequiredPlayers = function() {
      var amount, count, id, _ref;
      count = 0;
      _ref = this.Positions;
      for (id in _ref) {
        amount = _ref[id];
        if (amount > 0) {
          count = count + amount;
        }
      }
      return count;
    };
    OwnerRecord.prototype.CalculateNeededPlayers = function() {
      var count, neededPlayers, position, _ref;
      neededPlayers = '';
      _ref = this.Positions;
      for (position in _ref) {
        count = _ref[position];
        if (count > 0) {
          if (neededPlayers.length > 0) {
            neededPlayers += ', ';
          }
          neededPlayers += count + ' ' + position;
        }
      }
      if (neededPlayers === '') {
        neededPlayers = '<< All Required Positions Filled >>';
      }
      neededPlayers = '  ' + neededPlayers;
      return neededPlayers;
    };
    OwnerRecord.prototype.ProcessBid = function(message) {
      var player;
      this.CurrentFunds -= message.BidAmount;
      player = this.AuctionState.PlayerList[message.PlayerId];
      this.AssignedPlayers[message.PlayerId] = player;
      this.PlayersLeft -= 1;
      this.Positions[player.Position] -= 1;
      this.NeededPlayers = this.CalculateNeededPlayers();
      this.RequiredPlayers = this.CalculateRequiredPlayers();
      return this.RecalcMaxBid();
    };
    return OwnerRecord;
  })();
  OwnerLoadHandler = (function() {
    function OwnerLoadHandler(AuctionState) {
      this.AuctionState = AuctionState;
    }
    OwnerLoadHandler.prototype.CanProcess = function(message) {
      return message.type === 'LOAD';
    };
    OwnerLoadHandler.prototype.ProcessRecord = function(grid, record) {
      var newRecord;
      newRecord = new OwnerRecord(record, this.AuctionState);
      this.AuctionState.OwnerData[newRecord.Id] = newRecord;
      return grid.jqGrid('addRowData', newRecord.Id, newRecord);
    };
    OwnerLoadHandler.prototype.Process = function(message) {
      var grid, id, record, _ref, _results;
      grid = jQuery('#ownerlist');
      _ref = this.AuctionState.OwnerList;
      _results = [];
      for (id in _ref) {
        record = _ref[id];
        _results.push(this.ProcessRecord(grid, record));
      }
      return _results;
    };
    return OwnerLoadHandler;
  })();
  BidLoadHandler = (function() {
    BidLoadHandler.pipeline;
    function BidLoadHandler(pipeline, AuctionState) {
      this.AuctionState = AuctionState;
      this.pipeline = pipeline;
    }
    BidLoadHandler.prototype.CanProcess = function(message) {
      return message.type === 'LOAD';
    };
    BidLoadHandler.prototype.Process = function(message) {
      var bid, id, _ref, _results;
      _ref = this.AuctionState.Bids;
      _results = [];
      for (id in _ref) {
        bid = _ref[id];
        _results.push(this.pipeline.Process(bid));
      }
      return _results;
    };
    return BidLoadHandler;
  })();
  OwnerUpdateHandler = (function() {
    __extends(OwnerUpdateHandler, HandlerBase);
    function OwnerUpdateHandler(AuctionState) {
      this.AuctionState = AuctionState;
    }
    OwnerUpdateHandler.prototype.CanProcess = function(message) {
      return message.type === 'BID';
    };
    OwnerUpdateHandler.prototype.Process = function(message) {
      var ownerData;
      ownerData = this.AuctionState.OwnerData[message.OwnerId];
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
      this.SavePlayerData(message.PlayerId, ret);
      jQuery('#active-bid-panel').slideUp('slow');
      alert(message.PlayerId);
      jQuery('#admin-select option[value="' + message.PlayerId + '"]').remove();
      jQuery('#admin-select').trigger('liszt:updated');
      return alert(message.PlayerId);
    };
    return BidHandler;
  })();
  BidSetHandler = (function() {
    __extends(BidSetHandler, HandlerBase);
    function BidSetHandler(AuctionState) {
      this.AuctionState = AuctionState;
    }
    BidSetHandler.prototype.CanProcess = function(message) {
      return message.type === 'BID-SET';
    };
    BidSetHandler.prototype.Process = function(message) {
      var player;
      jQuery('#active-bid-panel').slideDown('slow');
      player = this.AuctionState.PlayerList[message.player];
      jQuery('#player-under-bid').html(player.Name);
      return jQuery('#player-bid').html(message.value);
    };
    return BidSetHandler;
  })();
  MessagePipeline = (function() {
    MessagePipeline.messages;
    MessagePipeline.handlers;
    function MessagePipeline() {
      var auctionState;
      this.messages = [];
      this.handlers = [];
      auctionState = new AuctionState();
      this.AddHandler(new StateLoadHandler(auctionState));
      this.AddHandler(new PlayerLoadHandler(auctionState));
      this.AddHandler(new PlayerDropListLoader(auctionState));
      this.AddHandler(new OwnerLoadHandler(auctionState));
      this.AddHandler(new BidLoadHandler(this, auctionState));
      this.AddHandler(new BidHandler());
      this.AddHandler(new OwnerUpdateHandler(auctionState));
      this.AddHandler(new BidSetHandler(auctionState));
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
  $(function() {
    jQuery('#active-bid-panel').hide();
    return jQuery('#bid-setter').click(function() {
      var message;
      message = {
        channel: 'activity',
        message: {
          type: 'BID-SET',
          value: jQuery('#bid-value').val(),
          player: jQuery('#admin-select').val()
        }
      };
      return PUBNUB.publish(message);
    });
  });
  PUBNUB.subscribe({
    channel: 'activity',
    callback: function(message) {
      return sam.Process(message);
    }
  });
  jQuery.ajax({
    url: '/home/AuctionBigGulp',
    dataType: 'json',
    data: 'auctionId=1',
    success: function(data) {
      return sam.Process(data);
    }
  });
}).call(this);
