import nuvindu/pubsub;
import ballerina/test;

@test:Config {
    groups: ["pubsub"]
}
function testPubSub() returns error? {
    pubsub:PubSub pubsub = new();
    stream<any, error?> subscribe = check pubsub.subscribe("testTopic");
    string expectedValue = "data";
    check pubsub.publish("testTopic", expectedValue);
    record {|any value;|}? 'record = check subscribe.next();
    if 'record != () {
        test:assertEquals(expectedValue, <string>'record.value);
    }
}

@test:Config {
    groups: ["pubsub"]
}
function testGracefulCloseInPubSub() returns error? {
    pubsub:PubSub pubsub = new();
    check pubsub.gracefulShutdown();
    string expectedValue = "Events cannot be published to a closed PubSub.";
    error? publish = pubsub.publish("topic", "data");
    test:assertTrue(publish is error, "Assertion failed: Data is published to a closed PubSub.");
    if publish is error {
        test:assertEquals(expectedValue, publish.message());
    }
}
