describe 'State Load Handler', ->
  describe 'declares itself ready to process LOAD message types, ->
    stateHandler = new StateLoadHandler(null)
    (expectstateHandler.CanProcess(type: 'LOAD')).toBe true