# hubot-group

A script that expands mentions of groups, making it easy to ping groups of
people without manually typing out a bunch of names. hubot-group is fully
configurable via chat.

## Demo

![Demo](https://raw.githubusercontent.com/anishathalye/hubot-group/docs/demo.png)

```
me [12:28 PM] 
@bot group create workbusiness-onshift


bot [12:28 PM] 
Created group workbusiness-onshift.


me [12:28 PM] 
@bot group add workbusiness-onshift bakedslug boarsproduct glitteringunderline


bot [12:28 PM] 
bakedslug added to group workbusiness-onshift.
boarsproduct added to group workbusiness-onshift.
glitteringunderline added to group workbusiness-onshift.


me [12:28 PM] 
@workbusiness-onshift


bot [12:28 PM] 
_me_ | *@workbusiness-onshift*: @bakedslug, @boarsproduct, @glitteringunderline


boarsproduct [12:28 PM] 
Neat.


me [12:28 PM] 
help me @workbusiness-onshift you're my only hope


bot [12:28 PM] 
_me_ | *@workbusiness-onshift*: @bakedslug, @boarsproduct, @glitteringunderline


me [12:29 PM] 
@bot login workbusiness-onshift


bot [12:29 PM] 
me punched in to workbusiness-onshift!


me [12:29 PM] 
@workbusiness-onshift blah


bot [12:29 PM] 
_me_ | *@workbusiness-onshift*: @me, @bakedslug, @boarsproduct, @glitteringunderline


me [12:29 PM] 
@bot logout


bot [12:29 PM] 
me logged out of workbusiness-onshift! :wave:
```

## Installation

In hubot project repo, run:

`npm install defenestration/hubot-group --save`

Then add **hubot-group** to your `external-scripts.json`:

```json
[
  "hubot-group"
]
```

**If you want to be able to change configuration settings from the chat without
having to use environment variables, you should also install
[hubot-conf][hubot-conf].**

## Usage

hubot-group is pretty intuitive to use. Run the help command (`{botname} help
group`) in your chat to see help documentation.

* Use `@bot login $group` to log yourself into that group. You may have to omit automatically added @ prefixed to the group name (for now).
* Use `@bot logout` to log yourself out of all groups, or `@bot logout $group` to logout of a specific one.

## Tips

* You can add groups to other groups by referring to a group as `&groupname`.
  For example, you can create a `frontend` group that contains a bunch of
  members, and then you can create a `dev` group that includes `&frontend`.
* For slack, the groups this creats exist outside of slack.  I suggest creating the same named slack group (with no users actually in it!) for   autocompletion purposes.


## Access from other scripts

Some `robot.on` functionality has been implemented to allow other scripts to intergrate with hubot-group. This expects a group name, room name, and an slack message object. An example is in src/group.coffee.

```coffeescript
robot.emit "group ping", "myGroup", "myRoom", { text: "pinging!" }
```

## Http

Groups can be viewed over http at /hubot/group/dump.
Individual groups can be seen at /hubot/group/info/`groupName`.

## Configuration

hubot-group can be configured either using [hubot-conf][hubot-conf] or
environment variables. hubot-conf settings override environment variables.

For all of the settings below like `HUBOT_SETTING_NAME`, you can change the
setting via chat by saying `{botname} conf set setting.name "{new value}"` (the
setting name is mapped by skipping the `HUBOT_` part, changing to lowercase,
and replacing `_` with `.`).

* `HUBOT_GROUP_DECORATOR` - a character indicating how to decorate usernames.
  Valid settings are `<`, `(`, `[`, and `{`. This variable can also be left
  unset. This seting defaults to `<`, which is appropriate for Slack.

* `HUBOT_GROUP_PREPEND` - set to `false` to disable prepending the original
  message to the response. This variable can also be left unset. This setting
  defaults to `true`.

* `HUBOT_GROUP_PREPEND_USERNAME` - set to `false` to disable prepending the
  original username to the prepended message. This variable can also be left
  unset. This setting defaults to `true`.

* `HUBOT_GROUP_TRUNCATE` - number of characters from the original message to
  display when `HUBOT_GROUP_PREPEND` is set. Set to a value less than or equal
  to zero to disable truncating. This setting defaults to `50`.

* `HUBOT_GROUP_RECURSE` - set to `false` to disable recursive group expansion.
  This setting defaults to `true`.

* `HUBOT_GROUP_SEPARATOR` - a string to separate the returned groups with, defaults to `\n` newline. Suggest to use a   space if you groups grow too large.

## License

Copyright (c) 2015-2017 Anish Athalye. Released under the MIT License. See
[LICENSE.md][license] for details.

[license]: LICENSE.md
[hubot-conf]: https://github.com/anishathalye/hubot-conf
