import ballerina/test;

@test:Config {
    groups: ["pubsub", "errors"]
}
function testPublishingToNonExistingTopic() returns error? {
    PubSub pubsub = new(autoCreateTopics = false);
    string expectedValue = "Topic 'events' does not exist.";
    Error? publish = pubsub.publish("events", "hello");
    test:assertTrue(publish is Error);
    test:assertEquals(expectedValue, (<Error>publish).message());
}


@test:Config {
    groups: ["pubsub", "errors"]
}
function testSubscribingToNonExistingTopic() returns error? {
    PubSub pubsub = new(autoCreateTopics = false);
    string expectedValue = "Topic 'events' does not exist.";
    stream<any, error?>|Error subscribe = pubsub.subscribe("events");
    test:assertTrue(subscribe is Error);
    test:assertEquals(expectedValue, (<Error>subscribe).message());
}

@test:Config {
    groups: ["pubsub", "errors"]
}
function testSubscribingToClosedPubSub() returns error? {
    PubSub pubsub = new(false);
    check pubsub.gracefulShutdown();
    stream<any, error?>|Error subscribe = pubsub.subscribe("topic");
    test:assertTrue(subscribe is Error);
    string expectedValue = "Users cannot subscribe to a closed PubSub.";
    test:assertEquals(expectedValue, (<Error>subscribe).message());
}

@test:Config {
    groups: ["pubsub", "errors"]
}
function testClosingStreams() returns error? {
    PubSub pubsub = new();
    stream<any, error?> newStream1 = check pubsub.subscribe("topic");
    stream<any, error?> newStream2 = check pubsub.subscribe("topic");
    check newStream2.close();
    check pubsub.publish("topic", "data");
    string expectedValue = "Events cannot be consumed after the stream is closed";
    record {|any value;|}|error? next = newStream2.next();
    test:assertTrue(next is error);
    test:assertEquals(expectedValue, (<error>next).message());
    record {|any value;|}? message = check newStream1.next();
    expectedValue = "data";
    string actualValue = <string>((<record {|any value;|}>message).value);
    test:assertEquals(expectedValue, actualValue);
}
