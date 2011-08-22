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

class PlayerLoadHandler
  CanProcess: (message) ->
    message.type == 'LOAD'

  ProcessRecord: (grid, record) ->
    grid.jqGrid 'addRowData', record.Id, record

  Process: (message) ->
    grid = jQuery '#list'
    @ProcessRecord(grid, record) for record in message.PlayerData


class OwnerRecord
  @Id
  @Name
  @CurrentFunds
  @PlayersLeft
  @RequiredPlayers
  @NeededPlayers
  @Positions

  @AuctionRules

  constructor: (auctionRules, record) ->
    @AuctionRules = auctionRules
    @Id = record.Id
    @Name = record.OwnerRow.Name
    @CurrentFunds = auctionRules.StartingFunds
    @PlayersLeft = auctionRules.MinPlayerCount
    @Positions = auctionRules.Positions.slice(0, auctionRules.Positions.length)

    @RequiredPlayers = @CalculateRequiredPlayers()
    @NeededPlayers = @CalculateNeededPlayers()

  CalculateRequiredPlayers: () ->
    count = 0
    for record in @Positions when record.Count > 0
      count = count + record.Count

    return count

  CalculateNeededPlayers: () ->
    neededPlayers = ''
    for position in @AuctionRules.Positions when position.Count > 0
      if neededPlayers.length > 0
        neededPlayers += ', '
      neededPlayers += position.Count + ' ' + position.Position
      
    if neededPlayers == ''
      neededPlayers = '<< All Required Positions Filled >>'
      
    return neededPlayers
  
  ProcessBid: (message) ->
    @CurrentFunds -= message.BidAmount
    # record other stuff here

class OwnerLoadHandler
  @OwnerData = []
  @AuctionRules

  CanProcess: (message) ->
    message.type == 'LOAD'

  ProcessRecord: (grid, record) ->
    newRecord = new OwnerRecord(@AuctionRules, record)
    @OwnerData[newRecord.Id] = newRecord
      
    grid.jqGrid 'addRowData', newRecord.Id, newRecord

  Process: (message) ->
    @AuctionRules = message.AuctionRules
    @OwnerData = []
    
    grid = jQuery '#ownerlist'
    @ProcessRecord(grid, record) for record in message.OwnerData

class AuctionRuleLoadHandler
  @AuctionRules

  CanProcess: (message) ->
    message.type == 'LOAD'

  Process: (message) ->
    @AuctionRules = message.AuctionRules

class BidLoadHandler
  @pipeline

  constructor: (pipeline) ->
    @pipeline = pipeline

  CanProcess: (message) ->
    message.type == 'LOAD'

  Process: (message) ->
    @pipeline.Process(bid) for bid in message.BidHistory


class OwnerUpdateHandler extends HandlerBase
  @ownerInfo

  constructor: (ownerInfo) ->
    @ownerInfo = ownerInfo

  CanProcess: (message) ->
    message.type == 'BID'

  Process: (message) ->
    ownerData = @ownerInfo.OwnerData[message.OwnerId]
    ownerData.ProcessBid(message)

    @SaveOwnerData(message.OwnerId, ownerData)

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
    @AddHandler new PlayerLoadHandler()
    loadHandler = @AddHandler( new OwnerLoadHandler() )
    @AddHandler new AuctionRuleLoadHandler()
    @AddHandler new BidLoadHandler(this)
    @AddHandler new BidHandler()
    @AddHandler new OwnerUpdateHandler(loadHandler)

  AddHandler: (handler) ->
    @handlers.push handler
    return handler

  Process: (message) ->
    handler.Process(message) for handler in @handlers when handler.CanProcess(message)

sam = new MessagePipeline()

jQuery.ajax url:'/home/AuctionBigGulp', dataType:'json', data:'auctionId=1', success: (data) ->
  sam.Process data

#jQuery.ajax url:'/home/BidDetail', dataType: 'json', data: 'auctionId=1', success: (data) ->
#  sam.Process record for record in data.records
