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
#   hubot login <group> - add yourself to group
#   hubot logout <group> - remove yourself from group
#   hubot logout - remove yourself from all groups. 
#
# Author:
#   anishathalye
#   tweaks by defenestration

IDENTIFIER = "[-._a-zA-Z0-9]+"

Group = require( "../lib/group-class.coffee")

module.exports = (robot) ->
  config = require('hubot-conf')('group', robot)
  group = new Group robot, config

  robot.brain.on "loaded", (res) ->
    console.log "groups on load", group.dump()

  robot.hear ///@#{IDENTIFIER}///, (res) ->
    # actual matching done in group.tag
    if res.envelope.user.name != robot.name
      response = group.print(res)
      # console.log "group heard", response, res.envelope.user.name
      if response.length > 0
        res.send response.join config('separator', '\n')

  robot.respond ///group\s+list///, (res) ->
    res.send "Groups: #{group.groups().join ", "}"

  robot.respond ///group\s+dump///, (res) ->
    response = group.dump()
    if response.length > 0 
      res.send response.join "\n"
    else
      res.send "No groups found!"

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
    for name in names
      if group.add g, name
        response.push "#{name} added to group #{g}."
      else
        response.push "#{name} is already in group #{g}!"
    res.send response.join "\n"

  # add self to a group
  robot.respond ///login\s+(#{IDENTIFIER})///, (res) ->
    user = res.envelope.user.name
    g = res.match[1]
    if not group.exists g
      res.send "Group #{g} does not exist!"
      return
    if group.add g, user
      res.send "#{user} punched in to #{g}!"
    else
      res.send "#{user} is already in group #{g}!"

  # remove self from a group
  robot.respond ///logout\s+(#{IDENTIFIER})///, (res) ->
    user = res.envelope.user.name
    g = res.match[1]
    if not group.exists g
      res.send "Group #{g} does not exist!"
      return
    if group.remove g, user
      res.send "#{user} punched out of #{g}! :wave:"
    else
      res.send "#{user} was not in #{g}!"

  # log self out of all groups
  robot.respond /logout$/, (res) ->
    user = res.envelope.user.name
    groups = group.membership user
    if groups
      group.remove(g, user) for g in groups
      res.send "#{user} logged out of #{groups.join ", "}! :wave:"
    else
      res.send "#{user} was not in any groups!"


  robot.respond ///group\s+remove\s+(#{IDENTIFIER})\s+(&?#{IDENTIFIER}(?:\s+&?#{IDENTIFIER})*)///, (res) ->
    g = res.match[1]
    names = res.match[2]
    names = names.split /\s+/
    if not group.exists g
      res.send "Group #{g} does not exist!"
      return
    response = []
    for name in names
      if group.remove g, name
        response.push "#{name} removed from group #{g}."
      else
        response.push "#{name} is not in group #{g}!"
    res.send response.join "\n"

  robot.respond ///group\s+info\s+(#{IDENTIFIER})///, (res) ->
    name = res.match[1]
    if not group.exists name
      res.send "Group #{name} does not exist!"
      return
    res.send "*@#{name}*: #{(group.members name).join ", "}"

  robot.respond ///group\s+membership\s+(&?#{IDENTIFIER})///, (res) ->
    name = res.match[1]
    groups = group.membership name
    if groups.length > 0
      res.send "#{name} is in #{group.membership(name).join ", "}."
    else
      res.send "#{name} is not in any groups!"

  robot.on "group ping", (g, room, messageObj = {} ) ->
    #messageobj is intended to be a slack message object, see https://api.slack.com/docs/message-formatting#message_formatting
    console.log "on group ping!", g, room
    if g and room
      res = { message: { user: {}}}
      res.message.text = "@#{g}"
      response = group.print(res)
      messageObj.text += "\n" + response.join config('separator', '\n')
      robot.messageRoom room, messageObj
    else
      #group doesn't exist, treat the sent group a normal slack group/user
      robot.messageRoom room, messageObj.text += "\n @#{g}"

  # example for robot.on 'group ping'
  # robot.respond /ping group (.*)/i, (res) ->
  #   robot.emit "group ping", res.match[1], res.message.room, { text: " pinging!" }

  robot.on "group fn", ( fn ) =>
    # send a function to this script that has access to group
    console.log "on group fn!", fn
    fn(group)

  # example (to putin another script)
  # robot.respond /logout all/i, (res) ->
  #   robot.emit "group fn", (group) ->
  #     user = res.envelope.user.name
  #     groups = group.membership user
  #     console.log user, groups
  #     for g in groups
  #       group.remove g, user
  #       res.send "#{user} removed from group #{g}!"


  # list groups membership over http, pretty & json'd
  robot.router.get ////hubot/groups?/dump///, (req,res) ->
    console.log "group/dump req.ip", req.ip, "res.ip", res.ip
    gd = group.objectify()
    str = JSON.stringify(gd)
    res.type('json').send(str)


  robot.router.get '/hubot/group/info/:g', (req,res) ->
    console.log "group/info", req.params.g, req.ip
    gd = group.objectify(req.params.g)
    str = JSON.stringify(gd)
    res.type('json').send(str)