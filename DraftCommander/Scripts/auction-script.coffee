class AuctionState
  @OwnerList = []
  @PlayerList = []
  @AuctionRules
  @Bids = []
  @OwnerData = []

  Process: (message) ->
    @OwnerData = []
    @AuctionRules = message.AuctionRules

    @OwnerList = []
    @OwnerList[record.Id] = record for record in message.OwnerData

    @PlayerList = {}
    @PlayerList[record.Id] = record for record in message.PlayerData

    @Bids = []
    @Bids.push(bid) for bid in message.BidHistory

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

class StateLoadHandler
  @AuctionState

  constructor: (auctionState) ->
    @AuctionState = auctionState

  CanProcess: (message) -> 
    message.type == 'LOAD'

  Process: (message) ->
    @AuctionState.Process(message)
    

class PlayerLoadHandler

  constructor: (@AuctionState) ->

  CanProcess: (message) ->
    message.type == 'LOAD'

  ProcessRecord: (grid, record) ->
   grid.jqGrid 'addRowData', record.Id, record

  Process: (message) ->
    grid = jQuery '#list'
    
    for id, record of @AuctionState.PlayerList
      @ProcessRecord grid, record

class PlayerDropListLoader
  constructor: (@AuctionState) ->

  CanProcess: (message) ->
    message.type == 'LOAD'

  ProcessRecord: (id, value) ->
    jQuery('#admin-select').append(jQuery("<option></option>").attr("value", id).text(value.Name))

  Process: (message) ->
    for id,  value of @AuctionState.PlayerList
      @ProcessRecord id, value
    jQuery('.chzn-select').chosen()




class OwnerRecord
  @Id
  @Name
  @CurrentFunds
  @PlayersLeft
  @RequiredPlayers
  @NeededPlayers
  @Positions
  @MaxBix

  constructor: ( record, @AuctionState) ->
    @Id = record.Id
    @Name = record.OwnerRow.Name
    @CurrentFunds = @AuctionState.AuctionRules.StartingFunds
    @PlayersLeft = @AuctionState.AuctionRules.MinPlayerCount

    @Positions = []

    for position in @AuctionState.AuctionRules.Positions
      @Positions[position.Position] = position.Count

    @AssignedPlayers = []

    @RequiredPlayers = @CalculateRequiredPlayers()
    @NeededPlayers = @CalculateNeededPlayers()
    @RecalcMaxBid()

  RecalcMaxBid: () =>
    @MaxBid = @CurrentFunds - ((@PlayersLeft - 1) * @AuctionState.AuctionRules.MinBid)

  CalculateRequiredPlayers: () ->
    count = 0
    for id, amount of @Positions when amount > 0
      count = count + amount

    return count

  CalculateNeededPlayers: () ->
    neededPlayers = ''
    for position, count of @Positions when count > 0
      if neededPlayers.length > 0
        neededPlayers += ', '
      neededPlayers += count + ' ' + position
      
    if neededPlayers == ''
      neededPlayers = '<< All Required Positions Filled >>'

    neededPlayers = '  ' + neededPlayers         
    return neededPlayers
  
  ProcessBid: (message) ->
    @CurrentFunds -= message.BidAmount
    player = @AuctionState.PlayerList[message.PlayerId]
    @AssignedPlayers[message.PlayerId] = player
    @PlayersLeft -= 1

    @Positions[player.Position] -=1


    @NeededPlayers = @CalculateNeededPlayers()
    @RequiredPlayers = @CalculateRequiredPlayers()
    @RecalcMaxBid()

class OwnerLoadHandler
  constructor: (@AuctionState) ->

  CanProcess: (message) ->
    message.type == 'LOAD'

  ProcessRecord: (grid, record) ->
    newRecord = new OwnerRecord(record, @AuctionState)
    @AuctionState.OwnerData[newRecord.Id] = newRecord
    grid.jqGrid 'addRowData', newRecord.Id, newRecord

  Process: (message) ->
    grid = jQuery '#ownerlist'
    @ProcessRecord(grid, record) for id, record of @AuctionState.OwnerList
 
class OwnerDropListLoader
  constructor: (@AuctionState) ->

  CanProcess: (message) ->
    message.type == 'LOAD'

  ProcessRecord: (id, value) ->
    jQuery('#owner-select').append(jQuery("<option></option>").attr("value", id).text(value.Name))

  Process: (message) ->
    @ProcessRecord(id,value) for id,  value of @AuctionState.OwnerData

    jQuery('#owner-select').trigger('liszt:updated')

class BidLoadHandler
  @pipeline

  constructor: (pipeline, @AuctionState) ->
    @pipeline = pipeline

  CanProcess: (message) ->
    message.type == 'LOAD'

  Process: (message) ->
    @pipeline.Process(bid) for id, bid of @AuctionState.Bids


class OwnerUpdateHandler extends HandlerBase
  constructor: (@AuctionState) ->

  CanProcess: (message) ->
    message.type == 'BID'

  Process: (message) ->
    ownerData = @AuctionState.OwnerData[message.OwnerId]
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

    # here we hide the bid panel
    jQuery('#active-bid-panel').slideUp('slow')

    # here we remove the player from the selection list
    jQuery('#admin-select option[value="'+message.PlayerId+'"]').remove()
    jQuery('#admin-select').trigger('liszt:updated')

class SaleSetVerifier
  constructor: (@AuctionState) ->

  CanProcess: (message) ->
    message.type == 'SALE-SET'

  MessageSet:(message, error) ->
    message.error = error

  Clear: (identifiers) ->
    jQuery(identifier).addClass('field-validation-valid').removeClass('field-validation-error') for identifier in identifiers


  SetError: (identifier) =>
    jQuery(identifier).addClass('field-validation-error').removeClass('field-validation-valid')

  Setup: ->
    @Clear(['#player_validation','#owner_validation','#bid_validation','#bid_validation_less_than_zero','#bid_validation_bid_price_too_high'])

  Process: (message) ->
    @Setup()
    playerId = $('#admin-select').val()
    ownerId = $('#owner-select').val()
    bidValue = parseInt($('#bid-value').val())

    emptyPlayer = playerId == ''
    emptyOwner = ownerId == ''
    badBid = isNaN(bidValue)

    @SetError('#player_validation') if emptyPlayer
    @SetError('#owner_validation') if emptyOwner
    @SetError('#bid_validation') if badBid

    error = emptyPlayer || emptyOwner || badBid

    if error then return @MessageSet(message, true) 
    
    owner = @AuctionState.OwnerData[ownerId]

    if bidValue < @AuctionState.AuctionRules.MinBid
      @SetError('#bid_validation_less_than_zero')
      return @MessageSet(message, true)

    if parseInt(owner.MaxBid) < bidValue
      @SetError('#bid_validation_bid_price_too_high')
      return @MessageSet(message, true)
    
    @MessageSet(message, false)

class SaleSetHandler
  constructor: (@AuctionState) ->

  CanProcess: (message) ->
    message.type == 'SALE-SET'

  Process: (message) ->
    if message.error then return

    playerId = $('#admin-select').val()
    ownerId = $('#owner-select').val()
    bidValue = $('#bid-value').val()

    $('#player-name-confirm').val(@AuctionState.PlayerList[playerId].Name)
    $('#player-owner-confirm').val(@AuctionState.OwnerData[ownerId].Name)
    $('#player-amount-confirm').val(bidValue)

    $('#player-amount-confirm').attr("readonly", true); 
    $('#player-owner-confirm').attr("readonly", true); 
    $('#player-name-confirm').attr("readonly", true); 

    options = 
      autoOpen: false
      height: 270
      width: 300
      modal: true
      buttons: 
        'Verify Sale': -> 
          alert bidValue
          message = 
            channel: 'activity'
            message:
              type: 'BID'
              PlayerId: playerId
              OwnerId: ownerId
              BidAmount: bidValue
          PUBNUB.publish( message)
          jQuery( this ).dialog( "close" )
        'Cancel': ->  jQuery( this ).dialog( "close" )
    jQuery('#confirm-dialog').dialog(options)
    jQuery('#confirm-dialog').dialog("open")

class BidSetHandler extends HandlerBase

  constructor: (@AuctionState) ->

  CanProcess: (message) ->
    message.type == 'BID-SET'

  Process: (message) ->
    jQuery('#active-bid-panel').slideDown('slow')
    player = @AuctionState.PlayerList[message.player]
    jQuery('#player-under-bid').html(player.Name)
    jQuery('#player-bid').html(message.value)

class BidIncrementer
  CanProcess: (message) ->
    message.type == 'BID-INC'

  Process: (message) ->
    message = 
      channel: 'activity'
      message:
        type: 'BID-SET'
        value: jQuery('#bid-value').val()
        player: jQuery('#admin-select').val()

    PUBNUB.publish( message)

class UiInit
  CanProcess: (message) ->
    message.type == 'UI-INIT'

  Process: (message) ->
    jQuery('#active-bid-panel').hide()
    jQuery('#confirm-dialog').hide()

    jQuery('#bid-setter').click ->
      sam.Process type: 'BID-INC'

    jQuery('#sale-setter').click ->
      sam.Process type: 'SALE-SET' 


class MessagePipeline
  @messages
  @handlers

  constructor: ->
    @messages = []
    @handlers = []
    auctionState = new AuctionState()
    @AddHandler new UiInit()
    @AddHandler new BidIncrementer()
    @AddHandler new StateLoadHandler(auctionState)
    @AddHandler new PlayerLoadHandler(auctionState)
    @AddHandler new PlayerDropListLoader(auctionState)
    @AddHandler new OwnerLoadHandler(auctionState)
    @AddHandler new OwnerDropListLoader(auctionState)
    @AddHandler new BidLoadHandler(this, auctionState)
    @AddHandler new BidHandler()
    @AddHandler new OwnerUpdateHandler(auctionState)
    @AddHandler new BidSetHandler(auctionState)
    @AddHandler new SaleSetVerifier(auctionState)
    @AddHandler new SaleSetHandler(auctionState)

  AddHandler: (handler) ->
    @handlers.push handler
    return handler

  Process: (message) ->
    handler.Process(message) for handler in @handlers when handler.CanProcess(message)

sam = new MessagePipeline()

$ ->
  sam.Process type: 'UI-INIT'

  PUBNUB.subscribe channel: 'activity', callback: (message) ->
    sam.Process message 

  jQuery.ajax url:'/home/AuctionBigGulp', dataType:'json', data:'auctionId=1', success: (data) ->
    sam.Process data
