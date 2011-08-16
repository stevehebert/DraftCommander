(function() {
  var BidHandler, MessagePipeline, sam;
  BidHandler = (function() {
    function BidHandler() {}
    BidHandler.prototype.CanProcess = function(message) {
      return message.type === 'BID';
    };
    BidHandler.prototype.GetOwnerName = function(message) {
      var list, ret;
      list = jQuery('#ownerlist');
      ret = list.jqGrid('getRowData', message.OwnerId);
      alert(ret.Name);
      return ret.Name;
    };
    BidHandler.prototype.Process = function(message) {
      var list, name, ret;
      name = this.GetOwnerName(message);
      list = jQuery('#list');
      alert(message.PlayerId);
      ret = list.jqGrid('getRowData', message.PlayerId);
      ret.Owner = name;
      ret.BidAmount = message.BidAmount;
      return list.jqGrid('setRowData', message.PlayerId, ret);
    };
    return BidHandler;
  })();
  MessagePipeline = (function() {
    MessagePipeline.messages;
    MessagePipeline.handlers;
    function MessagePipeline() {
      var bidHandler;
      this.messages = [];
      this.handlers = [];
      bidHandler = new BidHandler();
      this.handlers.push(bidHandler);
    }
    MessagePipeline.prototype.Process = function(message) {
      var handler, _i, _len, _ref, _results;
      alert('bid came in');
      alert(message.type);
      if (message.type === 'BID') {
        _ref = this.handlers;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          handler = _ref[_i];
          if (handler.CanProcess(message)) {
            _results.push(handler.Process(message));
          }
        }
        return _results;
      }
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
    url: '/home/BidDetail',
    dataType: 'json',
    data: 'auctionId=1',
    success: function(data) {
      var record, _i, _len, _ref, _results;
      _ref = data.records;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        record = _ref[_i];
        if (record.type === 'BID') {
          _results.push(sam.Process(record));
        }
      }
      return _results;
    }
  });
}).call(this);
