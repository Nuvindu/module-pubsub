## Package Overview

This package provides a message communication model with publish/subscribe APIs.

### Pub/Sub

Pub/Sub is a message communication model that consists of `publishers` sending data and `subscribers` receiving data. A logical channel called `topic` is used as the medium for publishers and subscribers to communicate. Users can subscribe to these topics. When data is published to one of the topics, it will broadcast that data to all the subscribers of the topic. In this approach, the senders and receivers are not directly connected.

#### Create a `pubsub:PubSub` instance

A `pubsub:PubSub` instance can be created as follows. It has a parameter to enable auto creation of the non-existing topics when publishing/subscribing. The default value is set as `true`.

```ballerina
import nuvindu/pubsub;

pubsub:PubSub pubsub = new(autoCreateTopics = true);
```

#### Publish

Events can be published into a topic using this method. Once an event is published, it will be broadcast to all the subscribers of that topic.

```ballerina
pubsub:Error publish = pubsub.publish(topicName = "topic");
```

#### Subscribe

A new subscriber will be created for a particular topic in the PubSub. The subscriber can receive the data published to that topic.

```ballerina
stream<string, error?>|pubsub:Error subscribe = pubsub.subscribe("topic");
```

#### Create Topics

This method creates a new topic in the PubSub.

```ballerina
Error? topic = pubsub.createTopic("topic");
```

#### Shutdown

After a PubSub model is shut down, users may no longer be able to use its APIs. Invoking APIs in a closed PubSub will always return a `pubsub:Error`. There are two approaches to close a PubSub.

##### Force Shutdown

This method is to immediately shut down the PubSub. It closes all the pipes in the PubSub using the `immediateClose` method. After that it will remove all the topics from the PubSub.

```ballerina
Error? forceShutdown = pubsub.forceShutdown();
```

##### Graceful Shutdown

There can be pipes in the middle of data transferring when the shutdown method is called. Therefore in this method, even the PubSub is closed, the subscribers can retrieve available data in the pipes for a certain period (which can be manually set). After the timeout elapses, it will close the PubSub using the `forceShutdown` method. The default timeout is 30 seconds.

```ballerina
Error? gracefulShutdown = pubsub.gracefulShutdown(timeout = 30);
```

### Errors

Any error related to the `PubSub` module can be represented by `pubsub:Error`.
