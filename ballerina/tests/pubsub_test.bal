import ballerina/test;

@test:Config {
    groups: ["pubsub"]
}
function testPubSub() returns error? {
    PubSub pubsub = new();
    string expectedValue = "hello";
    stream<any, error?> subscribe = check pubsub.subscribe("topic");
    check pubsub.publish("topic", expectedValue);
    record {|any value;|}? msg = check subscribe.next();
    string actualValue = <string>((<record {|any value;|}>msg).value);
    test:assertEquals(expectedValue, actualValue);
}

@test:Config {
    groups: ["pubsub", "errors"]
}
function testSubscribingToNonExistingTopic() returns error? {
    PubSub pubsub = new(autoCreateTopics = false);
    string expectedValue = "topic 'events' does not exist.";
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
