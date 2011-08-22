class TeamRulesProcessor
  @rules

  GetOwnerList: ->
    list = jQuery '#ownerlist'
    list.jqGrid 'getDataIDs'


  constructor: (rules) ->
    @rules = rules
    
    owners = @GetOwnerList()
    alert owners.length 

    for owner in owners
      @rules[owner] = @rules.Positions.slice(0, rules.Positions.Length) for owner in owners
      owner.CurrentFunds = @rules.StartingFunds
      owner.NeededPlayerCount = @rules.MinPlayerCount
      # gotta watch this next line
      owner.MaxBid => @CurrentFunds - (@NeededPlayerCount -1) * @rules.MinBid


  ProcessBid: (ownerId, bidAmount, position) ->
    ownerInfo = @rules[ownerId]
    ownerInfo.CurrentFunds -= bidAmount
    ownerInfo.NeededPlayerCount -= 1
    positionInfo.Count -= 1 for positionInfo in ownerInfo.Positions when positionInfo.Position == position
    summary = @CreateSummary rules[ownerId]
    
    set =
      CurrentFunds: ownerInfo.CurrentFunds
      NeededPlayerCount: ownerInfo.NeededPlayerCount
      MaxBix: ownerInfo.MaxBid

  CreateSummary: (ownerInfo) ->
    if ownerInfo.NeededPlayerCount < 1
      return '<< Auction Complete >>'
    
    positionSummary = ''
    for position in ownerInfo.Positions when positionInfo.Count > 0
      if positionSummary.length > 0
        positionSummary += ', '
      positionSummary += position.Count + ' ' + position.Position

      if positionSummary.Length == 0
        positionSummary = '<< All Required Positions Filled >>'
    
    return positionSummary;

class HandlerBase
  GetOwnerData: (ownerId) ->
    list = jQuery '#ownerlist'
    list.jqGrid 'getRowData', ownerId

  SaveOwnerData: (ownerId, data) ->
    list = jQuery '#ownerlist'
    list.jqGrid 'setRowData', ownerId, data

  GetPlayerData: (playerId) ->
    list = jQuery '#list'
    list.jqGrid 'getRowData', playerId

  SavePlayerData: (playerId, data) ->
    list = jQuery '#list'
    list.jqGrid 'setRowData', playerId, data

class OwnerUpdateHandler extends HandlerBase
  @teamRules

  constructor: (rules) ->
    @teamRules = rules

  CanProcess: (message) ->
    message.type == 'BID'

  Process: (message) ->
    ret = @GetOwnerData(message.OwnerId)
    ret.CurrentFunds = ret.CurrentFunds - message.BidAmount

    if message.BidAmount == 0
      ret.PlayersLeft += 1
    else
      ret.PlayersLeft -= 1

    @SaveOwnerData(message.OwnerId, ret)

class BidHandler extends HandlerBase
  CanProcess: (message) ->
    message.type == 'BID'
	
  GetOwnerName: (message) ->
    @GetOwnerData(message.OwnerId).Name
	 
  Process: (message) ->
    name = @GetOwnerName message
    ret = @GetPlayerData(message.PlayerId)
    ret.Owner = name
    message.OldBid = if ret.BidAmount == '' then 0 else parseInt(ret.BidAmount ? 0)
    ret.BidAmount = message.BidAmount
    @SavePlayerData(message.PlayerId, ret)

class MessagePipeline
  @messages
  @handlers

  constructor: ->
    @messages = []
    @handlers = []
    @AddHandler new BidHandler()
    @AddHandler new OwnerUpdateHandler()

  AddHandler: (handler) ->
    @handlers.push handler

  Process: (message) ->
    handler.Process(message) for handler in @handlers when handler.CanProcess(message)

  GetHistory: ->	
    jQuery.ajax url:'/home/BidDetail', dataType: 'json', data: 'auctionId=1', context:this, success: (data) ->
      @Process record for record in data.records when record.type == 'BID'

sam = new MessagePipeline()

jQuery.ajax url:'/home/BidDetail', dataType: 'json', data: 'auctionId=1', success: (data) ->
  sam.Process record for record in data.records


jQuery.ajax url:'/home/AuctionRules', dataType: 'json', data: 'auctionId=1', success: (data) ->
  sam.AddHandler new OwnerUpdateHandler( new TeamRulesProcessor(data))


$.ajax url:'/home/BigGulp', dataType:json, data:'auctionId=1', success: (data) ->
  

