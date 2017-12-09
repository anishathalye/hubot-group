# Description:
#   A script that expands mentions of groups. Groups themselves can be used as
#   members if prepended with '&', and mentions will be expanded recursively.
#
# Configuration:
#   HUBOT_GROUP_DECORATOR - a character indicating how to decorate usernames.
#     Valid settings are '<', '(', '[', and '{'. This variable can also be left
#     unset. This setting defaults to '<'.
#   HUBOT_GROUP_PREPEND - set to 'false' to disable prepending the original
#     message to the response. This variable can also be left unset. This
#     setting defaults to 'true'.
#   HUBOT_GROUP_PREPEND_USERNAME - set to 'false' to disable prepending the
#     original username to the prepended message. This variable can also be
#     left unset. This setting defaults to 'true'.
#   HUBOT_GROUP_TRUNCATE - number of characters from the original message to
#     display when HUBOT_GROUP_PREPEND is set. Set to a value less than or
#     equal to zero to disable truncating. This setting defaults to '50'.
#   HUBOT_GROUP_RECURSE - set to 'false' to disable recursive group expansion.
#     The setting defaults to 'true'.
#
# Commands:
#   hubot group list - list all group names
#   hubot group dump - list all group names and members
#   hubot group create <group> - create a new group
#   hubot group destroy <group> - destroy a group
#   hubot group rename <old> <new> - rename a group
#   hubot group add <group> <name> - add name to a group
#   hubot group remove <group> <name> - remove name from a group
#   hubot group info <group> - list members in group
#   hubot group membership <name> - list groups that name is in
#
# Author:
#   anishathalye

IDENTIFIER = "[-._a-zA-Z0-9]+"

sorted = (arr) ->
  copy = (i for i in arr)
  copy.sort()

class Group
  constructor: (@robot) ->
    @cache = {}

    @robot.brain.on "loaded", @load
    if @robot.brain.data.users.length
      @load()

  load: =>
    if @robot.brain.data.group
      @cache = @robot.brain.data.group
    else
      @robot.brain.data.group = @cache

  members: (group) =>
    sorted(@cache[group] or [])

  info: (group) =>
    if @cache[group].length > 0
      arr = []
      for m in @cache[group]
        try
          arr.push @robot.brain.data.users[m].name
        catch err
          arr.push m
      return sorted(arr)
    else
      return []

  groups: =>
    sorted(Object.keys(@cache))

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

module.exports = (robot) ->
  config = require('hubot-conf')('group', robot)
  group = new Group robot

  decorate = (name) ->
    switch config('decorator', '<')
      when "<" then "<@#{name}>"
      when "(" then "(@#{name})"
      when "[" then "[@#{name}]"
      when "{" then "{@#{name}}"
      else "@#{name}"

  robot.hear ///@#{IDENTIFIER}///, (res) ->
    response = []
    tagged = []
    for g in group.groups()
      if ///(^|\s)@#{g}\b///.test res.message.text
        tagged.push g
    if config('recurse') != 'false'
      process = (i for i in tagged)
      while process.length > 0
        g = process.shift()
        for mem in group.members g
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
      mem = group.members g
      if mem.length > 0
        response.push "*@#{g}*: #{(decorateOnce name for name in mem).join ", "}"
    if response.length > 0
      if config('prepend', 'true') == 'true'
        truncate = parseInt config('truncate', '50')
        text = res.message.text
        message = if truncate > 0 and text.length > truncate \
          then text.substring(0, truncate) + " [...]" else text
        if config('prepend.username', 'true') == 'true'
          message = "#{res.message.user.name}: #{message}"
        response.unshift message
      res.send response.join "\n"

  robot.respond ///group\s+list///, (res) ->
    res.send "Groups: #{group.groups().join ", "}"

  robot.respond ///group\s+dump///, (res) ->
    response = []
    for g in group.groups()
      response.push "*@#{g}*: #{group.members(g).join ", "}"
    if response.length > 0
      res.send response.join "\n"

  robot.respond ///group\s+create\s+(#{IDENTIFIER})///, (res) ->
    name = res.match[1]
    if group.create name
      res.send "Created group #{name}."
    else
      res.send "Group #{name} already exists!"

  robot.respond ///group\s+destroy\s+(#{IDENTIFIER})///, (res) ->
    name = res.match[1]
    old = group.destroy name
    if old isnt null
      res.send "Destroyed group #{name} (#{old.join ", "})."
    else
      res.send "Group #{name} does not exist!"

  robot.respond ///group\s+rename\s+(#{IDENTIFIER})\s+(#{IDENTIFIER})///, (res) ->
    from = res.match[1]
    to = res.match[2]
    if group.rename from, to
      res.send "Renamed group #{from} to #{to}."
    else
      res.send "Either group #{from} does not exist or #{to} already exists!"
      
  robot.respond ///group\s+add\s+(#{IDENTIFIER})\s+(&?#{IDENTIFIER}(?:\s+&?#{IDENTIFIER})*)///, (res) ->
    g = res.match[1]
    names = res.match[2]
    names = names.split /\s+/
    if not group.exists g
      res.send "Group #{g} does not exist!"
      return
    response = []
    for n in names
      for k, u of robot.brain.data.users
        if u.name==n
          if group.add g, u.id
            response.push "#{n} added to group #{g}."
            break
          else
            response.push "#{n} is already in group #{g}!"
            break
    res.send response.join "\n"
    
  robot.respond ///group\s+remove\s+(#{IDENTIFIER})\s+(&?#{IDENTIFIER}(?:\s+&?#{IDENTIFIER})*)///, (res) ->
    g = res.match[1]
    names = res.match[2]
    names = names.split /\s+/
    if not group.exists g
      res.send "Group #{g} does not exist!"
      return
    response = []
    for name in names
      for k, u of robot.brain.data.users
        if u.name == name
          if group.remove g, u.id
            response.push "#{name} removed from group #{g}."
          else if group.remove g, name
            response.push "#{name} removed from group #{g}."
          else
            response.push "#{name} is not in group #{g}!"
    res.send response.join "\n"

  robot.respond ///group\s+info\s+(#{IDENTIFIER})///, (res) ->
    name = res.match[1]
    if not group.exists name
      res.send "Group #{name} does not exist!"
      return
    res.send "*@#{name}*: #{(group.info name).join ", "}"

  robot.respond ///group\s+membership\s+(&?#{IDENTIFIER})///, (res) ->
    name = res.match[1]
    groups = group.membership name
    if groups.length > 0
      res.send "#{name} is in #{group.membership(name).join ", "}."
    else
      res.send "#{name} is not in any groups!"
