
class Group
  constructor: (@robot, @config) ->
    @cache = {}

    @robot.brain.on "loaded", @load
    if @robot.brain.data.users.length
      @load()
    @sorted = (arr) ->
      copy = (i for i in arr)
      copy.sort()

  load: =>
    if @robot.brain.data.group
      @cache = @robot.brain.data.group
    else
      @robot.brain.data.group = @cache

  members: (group) =>
    @sorted(@cache[group] or [])

  groups: =>
    @sorted(Object.keys(@cache))

  exists: (group) =>
    return @cache[group]?

  create: (group) =>
    if @exists group
      return false
    else
      @cache[group] = []
      return true

  destroy: (group) =>
    if @exists group
      mem = @members group
      delete @cache[group]
      return mem
    else
      return null

  rename: (from, to) =>
    if (not @exists from) or (@exists to)
      return false
    else
      @cache[to] = @cache[from]
      delete @cache[from]
      return true

  add: (group, name) =>
    if not @exists group
      return false
    if name in @cache[group]
      return false
    else
      @cache[group].push name
      return true

  remove: (group, name) =>
    if not @exists group
      return false
    if name in @cache[group]
      idx = @cache[group].indexOf name
      @cache[group].splice idx, 1
      return true
    else
      return false

  membership: (name) =>
    groups = []
    for own group, names of @cache
      if name in names
        groups.push group
    return groups

  objectify: ( grps = [] )=> 
    # simple setup to output an object
    output = {}
    grps = grps.split ' ' if typeof grps == "string" #create as an array if we forget and give a string.
    if grps.length == 0
      #get all groups
      grps = @groups()
    for g in grps
      output[g] = @members(g)
    return output

  dump: =>
    response = []
    for g in @groups()
      response.push "*@#{g}*: #{@members(g).join ", "}"  
    return response

  tag: (text) =>
    console.log "tag text", text
    # return array of groups found in a string
    tagged = []
    for g in @groups()
      if ///(^|\s)@#{g}(\s|$)///.test text
        tagged.push g
    console.log "tagged", tagged
    return tagged

  print: (res) => 
    # needs res.message.text and (now) optionally res.message.user.name, possibly could parse groups before hand? or in different function
    # import config 
    config = @config
    #decorate function requires config
    decorate = (name) ->
      # @name is the default
      switch config('decorator', '')
        when "<" then "<@#{name}>"
        when "(" then "(@#{name})"
        when "[" then "[@#{name}]"
        when "{" then "{@#{name}}"
        else "@#{name}"

    #main bit from script
    response = []

    tagged = @tag(res.message.text) 
    if config('recurse') != 'false'
      process = (i for i in tagged)
      while process.length > 0
        g = process.shift()
        for mem in @members g
          if mem[0] == '&'
            mem = mem.substring 1
            # it's a group
            if mem not in process and mem not in tagged
              tagged.push mem
              process.push mem
    # output results
    decorated = {}
    decorateOnce = (name) ->
      if name[0] == '&' or decorated[name]
        name
      else
        decorated[name] = true
        decorate name

    for g in tagged
      mem = @members g
      console.log "g", g, "mem", mem.join(" ~")
      if mem.length > 0
        r = "*@#{g}*: #{(decorateOnce name for name in mem).join ", "}"
        # console.log "r", r
        response.push r
    if response.length > 0 and res.message.user.name
      prepend = []
      
      if config('prepend.username', 'true') == 'true'
        prepend.push "_#{res.message.user.name}_"
      
      if config('prepend.text', 'false') == 'true' 
        truncate = parseInt config('prepend.text.truncate', '50')
        text = res.message.text
        message = if truncate > 0 and text.length > truncate \
          then text.substring(0, truncate) + " [...]" else text
        prepend.push "\"#{message}\""
      response.unshift prepend.join(": ") if prepend.length > 0

    return response
module.exports = Group
