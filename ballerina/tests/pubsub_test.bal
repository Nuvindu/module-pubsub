import ballerina/test;

@test:Config {
    groups: ["pubsub"]
}
function testPubSub() returns error? {
    PubSub pubsub = new();
    string expectedValue = "hello";
    stream<string, error?> subscribe = check pubsub.subscribe("topic");
    check pubsub.publish("topic", expectedValue);
    record {|string value;|}? msg = check subscribe.next();
    string actualValue = <string>((<record {|string value;|}>msg).value);
    test:assertEquals(expectedValue, actualValue);
}

@test:Config {
    groups: ["pubsub"]
}
function testGracefulShutdown() returns error? {
    PubSub pubsub = new();
    string expectedValue = "No any event is available in the closed pipe.";
    stream<string, error?> subscribe = check pubsub.subscribe("topic");
    check pubsub.gracefulShutdown();
    record {|string value;|}|error? msg = subscribe.next();
    test:assertTrue(msg is error);
    string actualValue = (<error>msg).message();
    test:assertEquals(expectedValue, actualValue);

    expectedValue = "Users cannot subscribe to a closed PubSub.";
    stream<string, error?>|Error new_subscriber = pubsub.subscribe("topic");
    test:assertTrue(new_subscriber is Error);
    test:assertEquals(expectedValue, (<Error>new_subscriber).message());

    expectedValue = "Events cannot be published to a closed PubSub.";
    Error? publish = pubsub.publish("topic", expectedValue);
    test:assertTrue(publish is Error);
    test:assertEquals(expectedValue, (<Error>publish).message());
}

@test:Config {
    groups: ["pubsub"]
}
function testForceShutdown() returns error? {
    PubSub pubsub = new();
    string expectedValue = "No any event is available in the closed pipe.";
    stream<string, error?> subscribe = check pubsub.subscribe("topic");
    check pubsub.forceShutdown();
    record {|string value;|}|error? msg = subscribe.next();
    test:assertTrue(msg is error);
    string actualValue = (<error>msg).message();
    test:assertEquals(expectedValue, actualValue);

    expectedValue = "Users cannot subscribe to a closed PubSub.";
    stream<string, error?>|Error new_subscriber = pubsub.subscribe("topic");
    test:assertTrue(new_subscriber is Error);
    test:assertEquals(expectedValue, (<Error>new_subscriber).message());

    expectedValue = "Events cannot be published to a closed PubSub.";
    Error? publish = pubsub.publish("topic", expectedValue);
    test:assertTrue(publish is Error);
    test:assertEquals(expectedValue, (<Error>publish).message());
}

@test:Config {
    groups: ["pubsub"]
}
function testCreatingTopics() returns error? {
    PubSub pubsub = new(false);
    string topicName = "topic";
    Error? topic = pubsub.createTopic(topicName);
    test:assertTrue(topic !is Error);
    stream<string, error?> subscribe = check pubsub.subscribe(topicName);
    string expectedValue = "data";
    check pubsub.publish(topicName, expectedValue);
    record {|string value;|}? msg = check subscribe.next();
    string actualValue = <string>((<record {|string value;|}>msg).value);
    test:assertEquals(expectedValue, actualValue);
}

@test:Config {
    groups: ["pubsub"]
}
function testAutoCreationTopicInPublishing() returns error? {
    PubSub pubsub = new(autoCreateTopics = true);
    string topicName = "topic";
    Error? publish = pubsub.publish(topicName, "data");
    test:assertTrue(publish !is Error);
    Error? topic = pubsub.createTopic(topicName);
    test:assertTrue(topic is Error);
    string expectedValue = "Topic name '" + topicName + "' already exists.";
    test:assertEquals(expectedValue, (<Error>topic).message());
}
