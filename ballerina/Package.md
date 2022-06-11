## Package Overview

This package provides a message communication model with publish/subscribe APIs.

### PubSub

PubSub is a message communication model that consists of `publishers` sending data and `subscribers` receiving data. A logical channel called `topic` is used as the medium for publishers and subscribers to communicate. Users can subscribe to these topics. When data is published to one of the topics, it will broadcast that data to all the subscribers of the topic. In this approach, the senders and receivers are not directly connected.

#### Create a `pubsub:PubSub` instance

A `pubsub:PubSub` instance can be created as follows. It has a parameter to enable auto creation of the non-existing topics when publishing/subscribing. The default value is set as `true`.

```ballerina
import nuvindu/pubsub;

pubsub:PubSub pubsub = new(autoCreateTopics = true);
```
### APIs associated with PubSub

- <b> publish </b>: Publishes data into a topic. Data will be broadcast to all the subscribers of that topic.
- <b> subscribe </b>: Subscribes to a topic in the PubSub. Subscriber will receive the data published into that topic.
- <b> createTopic </b>: Creates a new topic in the PubSub.
- <b> forceShutdown </b>: Closes the PubSub instantly. All the pipes will be immediately closed.
- <b> gracefulShutdown </b>: Closes the PubSub gracefully. Waits for the provided grace period before closing all the pipes in PubSub.

#### Create Topics

This method creates a new topic in the PubSub. There is a parameter called `autoCreateTopics` in the `pubsub` constructor which is set to `true` by default. That means it automatically creates necessary topics when the users are publishing/subscribing to a non-existing topics.
If it is set to false, topics have to be manually created as below.

```ballerina
import nuvindu/pubsub;

public function main() returns error? {
    pubsub:PubSub pubsub = new(autoCreateTopics = false);
    check pubsub.createTopic("topic");
}
```

Creating existing topics or creating topics in a closed PubSub will return a `pubsub:Error`.

#### Publish Data to a Topic

Events can be published into a topic using this method. Once an event is published, it will be broadcast to all the current subscribers of that topic.

```ballerina
import nuvindu/pubsub;

public function main() returns error? {
    pubsub:PubSub pubsub = new();
    check pubsub.publish("topic", "event");
}
```

When `autoCreateTopics` is not enabled, publishing events to a non-existing topics or publishing events to a closed PubSub will return a `pubsub:Error`.

#### Subscribe to a Topic

A new subscriber will be created for a particular topic in the PubSub. The subscriber can receive the events published to that topic.

Each subscriber will receive a `stream` which can be iterated by invoking `next` method and it returns the published event wrapped in a `record`.

```ballerina
import ballerina/io;
import nuvindu/pubsub;

public function main() returns error? {
    pubsub:PubSub pubsub = new();
    stream<string, error?> subscriberStream = check pubsub.subscribe("topic");
    check pubsub.publish("topic", "event");

    record {|string value;|}? nextEvent = check subscriberStream.next();
    if nextEvent != () { string event = nextEvent.value; io:println(event);}
}
```

When `autoCreateTopics` is not enabled, subscribing to a non-existing topics or subscribing to a closed Pubsub will return a `pubsub:Error`.

#### Shutdown

After a PubSub is shut down, users may no longer be able to use its APIs. And all the subscribers will be removed from the PubSub. And closing of a closed PubSub will always return a `pubsub:Error`.

There are two approaches to close a PubSub. 

##### Force Shutdown

This method is to immediately shut down the PubSub. It closes all the pipes in the PubSub using the `immediateClose` method. After that it will remove all the topics from the PubSub.

```ballerina
import nuvindu/pubsub;

public function main() returns error? {
    pubsub:PubSub pubsub = new();
    check pubsub.forceShutdown();

    check pubsub.publish("topic", "event"); // This will produce an error
}
```

##### Graceful Shutdown

In the PubSub model, pipes are the intermediator for publishers and subscribers. Therefore these pipes can be in the middle of data transferring when the shutdown method is called. To prevent any unexpected behaviours, in the `gracefulShutdown` method, all the subscribers are granted a grace period (timeout which can be manually set) to retrieve events from the their streams. During this period publishing events to the PubSub is not allowed. After the timeout elapses, it will close the PubSub using the `forceShutdown` method. The default timeout is 30 seconds.

```ballerina
import ballerina/io;
import ballerina/lang.runtime;
import nuvindu/pubsub;

public function main() returns error? {
    pubsub:PubSub pubsub = new();
    stream<string, error?> subscriberStream = check pubsub.subscribe("topic");
    check pubsub.publish("topic", "event");
    
    worker A {
        pubsub:Error? close = pubsub.gracefulShutdown(timeout = 10);
        pubsub:Error? publish = pubsub.publish("topic", "event_2"); // This will produce an error
        io:println(publish);
    }

    @strand {
        thread: "any"
    }
    worker B {
        runtime:sleep(5);
        record {|string value;|}|error? nextEvent = subscriberStream.next();
        if nextEvent !is error? { string event = nextEvent.value; io:println(event); }
    }
}
```
