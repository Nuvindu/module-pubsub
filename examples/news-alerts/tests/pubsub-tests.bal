import nuvindu/pubsub;
import ballerina/test;

@test:Config {
    groups: ["pubsub"]
}
function testPubSub() returns error? {
    pubsub:PubSub pubsub = new();
    stream<any, error?>|error subscribe = pubsub.subscribe("testTopic");
    if subscribe is error {
        return subscribe;
    }
    string expectedValue = "data";
    error? publish = pubsub.publish("testTopic", expectedValue);
    if publish is error {
        return publish;
    }
    record{|any value;|}|error? 'record = subscribe.next();
    if 'record is error? {
        return 'record;
    }
    test:assertEquals(expectedValue, <string>'record.value);
}

@test:Config {
    groups: ["pubsub"]
}
function testGracefulCloseInPubSub() returns error? {
    pubsub:PubSub pubsub = new();
    error? gracefulShutDown = pubsub.gracefulShutdown();
    if gracefulShutDown is error {
        return gracefulShutDown;
    }
    string expectedValue = "Data cannot be published to a closed PubSub.";
    error? publish = pubsub.publish("topic", "data");
    if publish is error {
        test:assertEquals(expectedValue, publish.message().toString());
    }
    
}
