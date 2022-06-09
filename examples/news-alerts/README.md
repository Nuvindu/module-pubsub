# News Alert System

## Overview

This application delivers news alerts to the users who subscribed to the system.

## Implementation

To explain the functionality of the system, first, there must be a Pub/Sub model to communicate data between publisher and subscribers. Then the mock subscribers are added to the PubSub. When subscribing, each subscriber will receive a stream to get news data. </br>
There is mock news data and each news item is published to the PubSub with a certain time gap. Once they are published subscribers can receive those data through their streams. </br>
If a subscriber needs to unsubscribe from news alerts, the subscriber can close the stream.

## Run the Example

```ballerina
cd .\examples\news-alerts
bal run
```
