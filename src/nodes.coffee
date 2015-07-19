class exports.Document
    constructor: (sections = []) ->
        @type = 'Document'
        @sections = sections
        @filename = null

class exports.Raw
    constructor: (text) ->
        @type = 'Raw'
        @text = text

class exports.Script
    constructor: (body) ->
        @type = 'Script'
        @body = body