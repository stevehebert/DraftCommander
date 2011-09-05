class AuctionState
  @OwnerList
  @PlayerList
  @AuctionRules
  @Bids
  @OwnerData

  Process: (message) ->
    @OwnerData = []
    @AuctionRules = message.AuctionRules

    @OwnerList = []
    @OwnerList[record.Id] = record for record in message.OwnerData

    @PlayerList = {}
    @PlayerList[record.Id] = record for record in message.PlayerData
    
    @Bids = []
    @Bids[bid.Id] = bid for bid in message.BidHistory

  BidsLength: ->
    length = 0
    length +=1 for key, value in @Bids
    return length
    
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

    @Reset()

    @RequiredPlayers = @CalculateRequiredPlayers()
    @NeededPlayers = @CalculateNeededPlayers()
    @RecalcMaxBid()

  Recalc: ->
    @Reset()

    @RequiredPlayers = @CalculateRequiredPlayers()
    @NeededPlayers = @CalculateNeededPlayers()
    @RecalcMaxBid()

  Reset: ->
    @CurrentFunds = @AuctionState.AuctionRules.StartingFunds
    @PlayersLeft = @AuctionState.AuctionRules.MinPlayerCount

    @Positions = []
    (@Positions[position.Position] = position.Count) for position in @AuctionState.AuctionRules.Positions

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

  GetOwnedPlayerInfo: () ->
    playerInfo = []

    for id, value of @AuctionState.Bids when parseInt(value.OwnerId) == parseInt(@Id)
      player = @AuctionState.PlayerList[value.PlayerId]
      item = 
        Id: player.Id
        Name: player.Name
        Position: player.Position
        BidAmount: value.BidAmount 
        Team: player.Team
      playerInfo.push item
    return playerInfo
  
  ProcessBid: (message) ->
    @Reset()
    for id, value of @AuctionState.Bids when parseInt(value.OwnerId) == parseInt(@Id)
      @CurrentFunds -= value.BidAmount
      @PlayersLeft -= 1
      player = @AuctionState.PlayerList[value.PlayerId]
      @Positions[player.Position] -= 1

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
  constructor: (@AuctionState) ->

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

    #store the bid if it is not local

    (@AuctionState.Bids[message.Id] = message) if ! @AuctionState.Bids.hasOwnProperty(message.Id)

class BidHistoryHandler
  @bidList
  @AuctionState
  constructor: (auctionState) ->
    @bidList = null
    @AuctionState = auctionState

  CanProcess: (message) ->
    message.type == 'BID'

  Process: (message) ->
    player = @AuctionState.PlayerList[message.PlayerId]
    owner = @AuctionState.OwnerData[message.OwnerId]
    item =
      Id: message.Id
      Name: player.Name
      Position: player.Position
      Team: player.Team
      Owner: owner.Name
      BidAmount: message.BidAmount
    #lets move this into a jsLazy implementation
    if @bidList == null
      @bidList = jQuery '#bidlist'
    @bidList.jqGrid 'addRowData', message.Id, item

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
        'Verify Sale': => 
          message = 
            channel: 'activity'
            message:
              type: 'BID'
              PlayerId: playerId
              OwnerId: ownerId
              BidAmount: bidValue
              AuctionId: 1
              Id: @AuctionState.BidsLength()
          PUBNUB.publish( message)
          jQuery.ajax url:'/home/AddBid', dataType:'json', type:'POST', data:message.message, error: (a,b,c) -> alert b
          (jQuery '#confirm-dialog' ).dialog "close" 
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
    (jQuery '#player-under-bid').html(player.Name)
    (jQuery '#player-bid').html(message.value)
    (jQuery '#player-position').html(player.Position)
    (jQuery '#player-team').html(player.Team)
    (jQuery '#player-rank').html(player.Rank)
    (jQuery '#player-estimate').html(player.Estimate)

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

class BidDeleteRequestHandler
  constructor: (@AuctionState) ->
  
  CanProcess: (message) ->
    message.type == 'BID-DELETE-REQUEST'

  Process: (message) ->
    (jQuery '#bid-delete-field').html @AuctionState.BidHistorySelect
    options = 
      autoOpen: false
      height: 270
      width: 300
      modal: true
      buttons: 
        'Yes': => 
          message = 
            channel: 'activity'
            message:
              type: 'BIDDELETE'
              Id: @AuctionState.BidHistorySelect
          PUBNUB.publish( message)
          jQuery.ajax url:'/home/DeleteBid', dataType:'json', type:'POST', data:message.message, error: (a,b,c) ->alert b
          (jQuery '#confirm-biddelete-dialog' ).dialog "close" 
        'Cancel': ->  jQuery( '#confirm-biddelete-dialog' ).dialog( "close" )
    jQuery('#confirm-biddelete-dialog').dialog(options)
    jQuery('#confirm-biddelete-dialog').dialog("open")     

class UiInit
  CanProcess: (message) ->
    message.type == 'UI-INIT'

  Process: (message) ->
    (jQuery '#active-bid-panel').hide()
    (jQuery '#confirm-dialog').hide() 
    (jQuery '#confirm-biddelete-dialog').hide()

    (jQuery '#bid-setter').click ->
      sam.Process type: 'BID-INC'

    (jQuery '#sale-setter').click ->
      sam.Process type: 'SALE-SET' 
    (jQuery '#bidselect').hide() 
    

    (jQuery '#bidselect').click ->
      sam.Process type: 'BID-DELETE-REQUEST'

    opts =
      lines: 12 
      length: 7 
      width: 5 
      radius: 10 
      color: '#000' 
      speed: 1 
      trail: 100 
      shadow: true 

    (jQuery "#waiting" ).spin(opts)
			
		
class BidListSelectHandler
  constructor: (@AuctionState) ->
    @commander = null
    @bidbutton = null

  CanProcess: (message) ->
    message.type == 'BIDSELECT'
  
  IsCommander: ->
    if @commander == null
      @commander = (jQuery '#commander-decl').val() != 'False'
    return @commander

  ActivateBidButton: ->
    if @bidbutton == null
      @bidbutton = jQuery '#bidselect'
    @bidbutton.show()

  Process: (message) ->
    @AuctionState.BidHistorySelect = message.Id
    @ActivateBidButton() if @IsCommander()

class StopInitDialog
  CanProcess: (message) ->
    message.type == 'LOAD'

  Process: (message) ->
    (jQuery '#waiting').hide()
    (jQuery '#main-app').slideDown("slow")

class SubGridLoader
  constructor: (@AuctionState) ->

  CanProcess: (message) ->
    message.type == 'SUBGRID'
  
  AddRow: (record, grid) ->
    grid.jqGrid 'addRowData', record.Id, record

  Process: (message) ->
    grid = jQuery "#"+message.SubGridId
    (@AddRow item, grid) for id, item of @AuctionState.OwnerData[message.Id].GetOwnedPlayerInfo()

class SubGridCreator
  constructor: (@AuctionState) ->

  CanProcess: (message) ->
    message.type == 'SUBGRID'
  
  Process: (message) ->
    subgrid_table_id = message.GridId + "_t"
    message.SubGridId = subgrid_table_id
    (jQuery '#' + message.GridId).html "<table id='"+subgrid_table_id+"' class='scroll'></table>"
    (jQuery '#' + subgrid_table_id).jqGrid
      datatype: 'local'
      colNames: ['Position', 'Name', 'Team', 'Bid Amount']
      colModel: [ value =
                    name: 'Position' 
                    index: 'Position'
                    width: 60
                    align: 'left',
                  value =
                    name: 'Name'
                    index: 'Name'
                    width: 200
                    align: 'left',
                  value =
                    name: 'Team'
                    index: 'Team'
                    width: 60
                    align: 'left',
                  value =  
                    name: 'BidAmount'
                    index: 'BidAmount'
                    width: 90
                    align: 'right'
                ]
      loadonce: true
      rowNum: 1000
      width:750
      imgpath: '/Content/themes/sunny/images' 

class BidDeletePlayerHandler extends HandlerBase
  constructor: (@AuctionState) ->
  
  CanProcess: (message) ->
    message.type == 'BIDDELETE'

  Process: (message) ->
    bid = @AuctionState.Bids[message.Id]
    player = @GetPlayerData(bid.PlayerId)
    player.Owner = ''
    player.BidAmount = ''
    @SavePlayerData bid.PlayerId, player

class BidDeleteDropListHandler
  constructor: (@AuctionState) ->

  CanProcess: (message) ->
    message.type == 'BIDDELETE'

  ProcessRecord: (id, value) ->
    jQuery('#owner-select').append(jQuery("<option></option>").attr("value", id).text(value.Name))

  Process: (message) ->
    bid = @AuctionState.Bids[message.Id]
    player = @AuctionState.PlayerList[bid.PlayerId];
    alert player.Name
    @ProcessRecord player.Id, player
    jQuery('#owner-select').trigger('liszt:updated')



class BidDeleteBidHistoryHandler
  constructor: (@AuctionState) ->

  CanProcess: (message) ->
    message.type == 'BIDDELETE'

  Process: (message) ->
    (jQuery "#bidlist").jqGrid 'delRowData', message.Id


class BidDeleteOwnerHandler extends HandlerBase
  constructor: (@AuctionState) -> 

  CanProcess: (message) ->
    message.type == 'BIDDELETE'

  Process: (message) ->
    bid=@AuctionState.Bids[message.Id]
    ownerData = @AuctionState.OwnerData[bid.OwnerId]
    ownerData.Recalc()
    @SaveOwnerData bid.OwnerId, ownerData

class MessagePipeline
  @messages
  @handlers
  @AuctionState
  constructor: ->
    @messages = []
    @handlers = []
    auctionState = new AuctionState()
    @AddHandler new UiInit()
    @AddHandler new BidListSelectHandler(auctionState)
    @AddHandler new BidIncrementer()
    @AddHandler new StateLoadHandler(auctionState)
    @AddHandler new StopInitDialog()
    @AddHandler new PlayerLoadHandler(auctionState)
    @AddHandler new PlayerDropListLoader(auctionState)
    @AddHandler new OwnerLoadHandler(auctionState)
    @AddHandler new OwnerDropListLoader(auctionState)
    @AddHandler new BidLoadHandler(this, auctionState)
    @AddHandler new BidHandler(auctionState)
    @AddHandler new BidHistoryHandler(auctionState)
    @AddHandler new OwnerUpdateHandler(auctionState)
    @AddHandler new BidSetHandler(auctionState)
    @AddHandler new SaleSetVerifier(auctionState)
    @AddHandler new SaleSetHandler(auctionState)
    @AddHandler new SubGridCreator(auctionState)
    @AddHandler new SubGridLoader(auctionState) 
    @AddHandler new BidDeleteRequestHandler(auctionState)

    @AddHandler new BidDeletePlayerHandler(auctionState)
    @AddHandler new BidDeleteBidHistoryHandler(auctionState)
    @AddHandler new BidDeleteOwnerHandler(auctionState)
    @AddHandler new BidDeleteDropListHandler(auctionState)

    @AuctionState = auctionState

  AddHandler: (handler) -> 
    @handlers.push handler
    return handler

  Process: (message) ->
    handler.Process(message) for handler in @handlers when handler.CanProcess(message)

sam = new MessagePipeline()

window.pipeline = sam


$ ->
  sam.Process type: 'UI-INIT'

  PUBNUB.subscribe channel: 'activity', callback: (message) ->
    sam.Process message 

  jQuery.ajax url:'/home/AuctionBigGulp', dataType:'json', data:'auctionId=1', success: (data) ->
    sam.Process data
