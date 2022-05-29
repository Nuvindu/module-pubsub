import ballerina/test;

@test:Config {
    groups: ["pubsub"]
}
function testPubSub() returns error? {
    PubSub pubsub = new();
    string expectedValue = "hello";
    stream<any, error?> subscribe = check pubsub.subscribe("topic");
    check pubsub.publish("topic", expectedValue);
    record{|any value;|}? msg = check subscribe.next();
    if msg != () {
        string actualValue = <string>msg.value;
        test:assertEquals(expectedValue, actualValue);
    }
}

@test:Config {
    groups: ["pubsub", "errors"]
}
function testPubSubWithExistingTopics() returns error? {
    PubSub pubsub = new(autoCreateTopics = false);
    string expectedValue = "topic 'events' does not exist.";
    stream<any, error?>|Error subscribe = pubsub.subscribe("events");
    test:assertTrue(subscribe is Error, "Assertion failed: Subscribed to a invalid topic.");
    if subscribe is Error {
        test:assertEquals(expectedValue, subscribe.message());
    }
}

@test:Config {
    groups: ["pubsub", "errors"]
}
function testSubscribingToClosedPubSub() returns error? {
    PubSub pubsub = new(false);
    check pubsub.gracefulShutdown();
    stream<any, error?>|Error subscribe = pubsub.subscribe("topic");
    test:assertTrue(subscribe is Error, "Assertion failed: Subscribed to a invalid topic.");
    string expectedValue = "Users cannot subscribe to a closed PubSub.";
    if subscribe is Error {
        test:assertEquals(expectedValue, subscribe.message());
    }
}

@test:Config {
    groups: ["pubsub", "errors"]
}
function testClosingStreams() returns error? {
    PubSub pubsub = new ();
    stream<any, error?> newStream1 = check pubsub.subscribe("topic");
    stream<any, error?> newStream2 = check pubsub.subscribe("topic");
    check newStream2.close();
    check pubsub.publish("topic", "data");
    string expectedValue = "Data cannot be consumed after the stream is closed";
    record {|any value;|}|error? next = newStream2.next();
    test:assertTrue(next is error, "Assertion failed: Data is produced by a closed stream.");
    if next is error {
        test:assertEquals(expectedValue, next.message());
    }
    record {|any value;|}? message = check newStream1.next();
    expectedValue = "data";
    if message != () {
        string actualValue = <string>message.value;
        test:assertEquals(expectedValue, actualValue);
    }
}
