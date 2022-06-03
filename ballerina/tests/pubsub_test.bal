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
    groups: ["pubsub"]
}
function testGracefulShutdown() returns error? {
    PubSub pubsub = new();
    string expectedValue = "No any event is available in the closed pipe.";
    stream<any, error?> subscribe = check pubsub.subscribe("topic");
    check pubsub.gracefulShutdown();
    record {| any value; |}|error? msg = subscribe.next();
    test:assertTrue(msg is error);
    string actualValue = (<error>msg).message();
    test:assertEquals(expectedValue, actualValue);

    expectedValue = "Users cannot subscribe to a closed PubSub.";
    stream<any, error?>|Error new_subscriber = pubsub.subscribe("topic");
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
    stream<any, error?> subscribe = check pubsub.subscribe("topic");
    check pubsub.forceShutdown();
    record {| any value; |}|error? msg = subscribe.next();
    test:assertTrue(msg is error);
    string actualValue = (<error>msg).message();
    test:assertEquals(expectedValue, actualValue);

    expectedValue = "Users cannot subscribe to a closed PubSub.";
    stream<any, error?>|Error new_subscriber = pubsub.subscribe("topic");
    test:assertTrue(new_subscriber is Error);
    test:assertEquals(expectedValue, (<Error>new_subscriber).message());

    expectedValue = "Events cannot be published to a closed PubSub.";
    Error? publish = pubsub.publish("topic", expectedValue);
    test:assertTrue(publish is Error);
    test:assertEquals(expectedValue, (<Error>publish).message());
}
