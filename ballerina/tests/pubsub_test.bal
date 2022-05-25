import ballerina/test;

@test:Config {
    groups: ["pubsub"]
}
function testPubSub() returns error? {
    PubSub pubsub = new();
    stream<any, error?> subscribe = check pubsub.subscribe("topic");
    error? publish = pubsub.publish("topic", "hello");
    if publish is error {
        return publish;
    }
    string expectedValue = "hello";
    record {| any value; |}|error? msg = subscribe.next();
    if msg !is error? {
        string actualValue = <string> msg.value;
        test:assertEquals(expectedValue, actualValue);
    }   
}
