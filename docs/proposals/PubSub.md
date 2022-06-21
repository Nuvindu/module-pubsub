# Proposal: Pub/Sub Package for Ballerina

_Owners_: @Nuvindu  
_Reviewers_: @shafreenAnfar @ThisaruGuruge  
_Created_: 2021/05/09  
_Updated_: 2022/05/26  
_Issue_: [#2907](https://github.com/ballerina-platform/ballerina-standard-library/issues/2907)

## Summary

The publish/subscribe model (a.k.a. pub/sub) is a message communication model which decouples the message senders from the receivers. This proposal is to introduce a Pub/Sub package for Ballerina.

## Goals

- Create a new package for Ballerina using the Publish/Subscribe pattern.
- Include the Pub/Sub package into Ballerina standard library packages.

## Motivation

In Ballerina services, there can be some cases where data has to be published over multiple clients when an event is triggered. Each time, it requires some redundant coding and error handling to properly implement this event-driven architecture. The Pub/Sub model can provide an interface to hide the complexities in message distribution and provide APIs for the users to reduce the redundancy of the code and optimize the error handling.

## Description

Pub/Sub is a messaging pattern that consists of `publishers` sending data and `subscribers` receiving data. A logical channel called `topic` is used as the medium for publishers and subscribers to communicate. Users can subscribe to these topics. When data is published to one of the topics, it will broadcast that data to all the subscribers of the topic. In this approach, the senders and receivers are not directly connected. </br>

A `pubsub:PubSub` instance can be created as follows. It has a parameter to enable auto creation of the non-existing topics when publishing/subscribing. The default value is set as `true`.

```ballerina
 pubsub:PubSub pubsub = new(autoCreateTopics = true);
```

### APIs associated with PubSub

- <b> publish </b>: Publishes data into a topic. Data will be broadcast to all the subscribers of that topic.
- <b> subscribe </b>: Subscribes to a topic in the PubSub. Subscriber will receive the data published into that topic.
- <b> createTopic </b>: Creates a new topic in the PubSub.
- <b> forceShutdown </b>: Closes the PubSub instantly. All the pipes will be immediately closed.
- <b> gracefulShutdown </b>: Closes the PubSub gracefully. Waits for the provided grace period before closing all the pipes in PubSub.

In the proposed model, `Pipes` are used to transfer data from publishers to subscribers. PubSub creates a new `Pipe` instance for each subscriber in a topic. In the `subscribe` method it returns a stream so that clients can receive data through that stream whenever an event occurs. The event is triggered when data is published on a topic. Then, The `publish` method, produces the given data to all the pipes of that topic. Since the pipes have producer-consumer architecture, data can be produced and consumed in parallel processes. Topics can either sets to automatically create when publishing/subscribing or users can use the `createTopic` method to create them. </br>

Although the Pub/Sub model is for message communication purposes, it allows `any` type of data to be published.

### Shutdown

If a Pub/Sub model is shut down, users may no longer be able to use its APIs. But it has some considerations when it comes to graceful shutdown. Because there can be pipes in the middle of data transferring when the shutdown method is called. Therefore in the `gracefulShutdown` method, first it must gracefully close all the pipes in the Pub/Sub instance. Then the rest of the attributes in the Pub/Sub must be cleared and kept until the garbage collector handles them. There is a `forceShutdown` method to immediately shut down the Pub/Sub. There, it closes all the pipes using the `immediateClose` method. And the rest of the function is the same as in graceful shutdown.
