import ballerina/test;

@test:Config {
    groups: ["pubsub"]
}
function testPubSub() returns error? {
    PubSub pubsub = new();
    stream<any, error?> subscribe = check pubsub.subscribe("topic");
    check pubsub.publish("topic", "hello");
    string expectedValue = "hello";
    record {| any value; |}|error? msg = subscribe.next();
    if msg !is error? {
        string actualValue = <string> msg.value;
        test:assertEquals(expectedValue, actualValue);
    }   
}

@test:Config {
    groups: ["pubsub", "errors"]
}
function testPubSubWithExistingTopics() returns error? {
    PubSub pubsub = new(false);
    string expectedValue = "events : topic does not exist.";
    stream<any, error?>|Error subscribe = pubsub.subscribe("events");
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
    stream<any, error?>|Error publish = pubsub.subscribe("topic");
    string expectedValue = "Users cannot subscribe to a closed PubSub.";
    if publish is Error {
        test:assertEquals(expectedValue, publish.message());
    }
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
    string expectedValue = "Data cannot be consumed after the stream is closed";
    record {| any value; |}|error? next = newStream2.next();
    if next is error {
        test:assertEquals(expectedValue, next.message());
    }
    record {| any value; |}|error? message = newStream1.next();
    expectedValue = "data";
    if message !is error? {
        string actualValue = <string> message.value;
        test:assertEquals(expectedValue, actualValue);
    }   
}
