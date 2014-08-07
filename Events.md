Events
======

This is a list of events that are emitted by the Blur framework.

Each event name is based on the name of which entity is the cause of the event,
followed by a verb describing the event.

# Events

## Client events

### `:client_loaded`
  Called when the client is loaded.

  No arguments.

### `:client_quit`
  Called when the client is expected to quit.

  No arguments.

## User events

### `:user_join`
  Called when a user joins a channel.

  Arguments: channel (Network::Channel), user (Network::User)

### `:user_leave`
  Called when a user leaves a channel.

  Arguments: channel (Network::Channel), user (Network::User)

### `:user_quit`
  Called when a user quits a network.

  Arguments: channel (Network::Channel), user (Network::User)

### `:user_rename`
  Called when a user changes nickname.

  Arguments: channel (Network::Channel), user (Network::User), new_nick (String)

### `:private_message`
  Called when a user sends a private message.

  Arguments: user (Network::User), message (String)

## Channel events

### `:channel_create` 
  Called when a new channel instance is created.

  Arguments: channel (Network::Channel)

### `:channel_join` 
  Called when the client joins a new channel (mostly the same as :channel_create).

  Arguments: channel (Network::Channel)

### `:channel_who_reply`
  Called when a list of users is received (note: this  list can be split into
  multiple events.)

  Arguments: channel (Network::Channel)

### `:channel_topic`
  Called when the channel changes topic.

  Arguments: channel (Network::Channel), new_topic (String)

### `:message`
  Called when a channel-wide message was sent.

  Arguments: sender (Network::User), channel (Network::Channel), message (String)

## Network events

### `:network_ping`
  Called when a PING message is received.

  Arguments: whatever was sent by the server.

## Script events

### `:script_load`
  Called when a script is loaded.

  Arguments: script (Script)

### `:script_unload`
  Called when a script is unloaded.

  Arguments: script (Script)
