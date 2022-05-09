# Pub/Sub Package for Ballerina

## Summary

The publish/subscribe model a.k.a. pub/sub is a message communication model which decouples the message senders from the receivers. And they are linked through communication channels in which publishers and subscribers share data. This proposal is to introduce a Pub/Sub package for Ballerina using this concept.

## Goals

* Hide the complexities in message distribution and provide APIs for the users to simplify the code.

## Non Goals

* Include the Pub/Sub package into Ballerina standard library packages.

## Motivation

In GraphQL subscriptions, pipes are used to hold messages and return them to the clients. But having multiple subscriptions can be complicated because it needs to be maintained to implement as above. And also there may be redundant code segments. Pub/Sub model can be used to address these issues, it can hide all the complexities and the clients only have to use publish, subscribe APIs to implement their requirements. 

## Description

### Overview

Pub/Sub is a messaging pattern that follows a concept similar to the observer design pattern. The idea is to decouple the message senders(publishers) from the receivers(subscribers). A logical channel called topic is used as the medium for publishers and subscribers to communicate. Here, the publishers publish the data into a topic and the data will be broadcast to all the subscribers of that topic.

### Pipe

The pipe model has a producer-consumer architecture. Therefore data can be produced and consumed in parallel processes. Here, the produced data will be stored in a queue until the data is consumed by the user. Also, the data can be consumed via a stream. Therefore in GraphQL subscriptions, pipes are used as triggers as they will immediately return data when the data is published.
In the Pub/Sub model, pipes are used to broadcast the published data.


### Methods

#### Subscribe

If a user needs to receive messages published to a topic, he should subscribe to that topic. In the proposed Pub/Sub model, pipe instances represent the subscribers. Hence there will be a separate pipe for each client who subscribed to a Pub/Sub topic. And each topic will hold an array of pipes. If a client needs to subscribe to a topic, a new pipe will be added to that array.


The method returns a stream that users can use to receive all the published data.

#### Publish

When data is published, it must be broadcast to all the subscribers of the topic. In the implementation, the published data will be produced for each pipe in the pipe array of the topic. 
In the proposed model, any type of data is allowed.
If an error occurs it returns a panic.
When publishing data into the pipes, it explicitly checks whether the pipe is closed. If the pipe is closed it must be removed from the array. This removing process is implemented in the unsubscribe method.

#### Unsubscribe

This method is to unsubscribe a client from a specific topic. The approach is removing the relevant client's pipe instance from the array related to the topic.

#### Shutdown

The shutdown of a Pub/Sub system has two approaches. In both ways it requires closing all the pipes of the pubsub. When one of the shutting down methods is called, no other APIs can be run on the pub sub. And also the pipes have to be closed too.
##### Force Shutdown

##### Graceful Shutdown

