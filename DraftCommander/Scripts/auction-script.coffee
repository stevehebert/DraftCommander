class BidHandler
  CanProcess: (message) ->
    message.type == 'BID'
	
  GetOwnerName: (message) ->
    list = jQuery '#ownerlist'
    ret = list.jqGrid 'getRowData', message.OwnerId
    alert ret.Name
    ret.Name
	 
  Process: (message) ->
    name = @GetOwnerName message
    list = jQuery '#list' 
    alert message.PlayerId
    ret = list.jqGrid 'getRowData', message.PlayerId
    ret.Owner = name
    ret.BidAmount = message.BidAmount
    list.jqGrid 'setRowData',  message.PlayerId, ret

class MessagePipeline
  @messages
  @handlers

  constructor: ->
    @messages = []
    @handlers = []
    bidHandler = new BidHandler()
    @handlers.push bidHandler

  Process: (message) ->
    alert 'bid came in'
    alert message.type 
    if message.type == 'BID' 
      handler.Process(message) for handler in @handlers when handler.CanProcess(message)

  GetHistory: ->	
    jQuery.ajax url:'/home/BidDetail', dataType: 'json', data: 'auctionId=1', context:this, success: (data) ->
      @Process record for record in data.records when record.type == 'BID'

sam = new MessagePipeline()

jQuery.ajax url:'/home/BidDetail', dataType: 'json', data: 'auctionId=1', success: (data) ->
  sam.Process record for record in data.records when record.type == 'BID'


