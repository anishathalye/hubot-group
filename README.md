# hubot-group

A script that expands mentions of groups, making it easy to ping groups of
people without manually typing out a bunch of names. hubot-group is fully
configurable via chat.

## Demo

![Demo](https://raw.githubusercontent.com/anishathalye/hubot-group/docs/demo.png)

## Installation

In hubot project repo, run:

`npm install hubot-group --save`

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

## Tips

* You can add groups to other groups by referring to a group as `&groupname`.
  For example, you can create a `frontend` group that contains a bunch of
  members, and then you can create a `dev` group that includes `&frontend`.

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

* `HUBOT_GROUP_PREPEND` - set to `false` to enable prepending the original
  message to the response. This variable can also be left unset. This setting
  defaults to `true`.

* `HUBOT_GROUP_PREPEND_USERNAME` - set to `false` to enable prepending the
  original username to the prepended message. This variable can also be left
  unset. This setting defaults to `true`.

* `HUBOT_GROUP_TRUNCATE` - number of characters from the original message to
  display when `HUBOT_GROUP_PREPEND` is set. Set to a value less than or equal
  to zero to disable truncating. This setting defaults to `50`.

* `HUBOT_GROUP_RECURSE` - set to `false` to disable recursive group expansion.
  This setting defaults to `true`.

## License

Copyright (c) 2015-2016 Anish Athalye. Released under the MIT License. See
[LICENSE.md][license] for details.

[license]: LICENSE.md
[hubot-conf]: https://github.com/anishathalye/hubot-conf
